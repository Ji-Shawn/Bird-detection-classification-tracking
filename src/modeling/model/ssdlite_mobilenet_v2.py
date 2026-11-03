"""Two-class SSDlite320: MobileNetV2 + DW/PW/ReLU6 detection heads.

No MobileNetV3, SE, hard-swish or 5x5 kernels. RGB input tensors are in
[0, 1]; SSD applies ImageNet normalization and resizes to 320x320.
"""
from collections import OrderedDict
from pathlib import Path
from types import MethodType

import torch
from torch import nn
from torch.nn import functional as F
from torchvision.models import mobilenet_v2, MobileNet_V2_Weights
from torchvision.models.detection.anchor_utils import DefaultBoxGenerator
from torchvision.models.detection.ssd import SSD
from torchvision.models.detection.ssdlite import SSDLiteHead
from torchvision.ops.misc import Conv2dNormActivation

ARCHITECTURE = "ssdlite320_mobilenet_v2_bird_v1"
BIRD_LABEL = 1
CLASSES = ["background", "bird"]


def conv(cin, cout, kernel=1, stride=1, groups=1):
    return Conv2dNormActivation(cin, cout, kernel_size=kernel, stride=stride,
                               groups=groups, activation_layer=nn.ReLU6)


class MobileNetV2Features(nn.Module):
    out_channels = [576, 1280, 512, 256, 256, 128]

    def __init__(self, pretrained=False):
        super().__init__()
        weights = MobileNet_V2_Weights.IMAGENET1K_V1 if pretrained else None
        features = mobilenet_v2(weights=weights).features
        # Tap the expansion BEFORE block 14's stride-2 depthwise convolution.
        # This block has no residual, so splitting it preserves the backbone.
        assert not features[14].use_res_connect
        self.stage16 = nn.Sequential(*features[:14], features[14].conv[0])
        self.stage32 = nn.Sequential(*features[14].conv[1:], *features[15:])
        self.extra = nn.ModuleList()
        for cin, cout in zip(self.out_channels[1:-1], self.out_channels[2:]):
            mid = cout // 2
            self.extra.append(nn.Sequential(conv(cin, mid),
                                            conv(mid, mid, 3, 2, mid),
                                            conv(mid, cout)))
        for module in self.extra.modules():
            if isinstance(module, nn.Conv2d):
                nn.init.normal_(module.weight, std=0.03)

    def forward(self, x):
        result = OrderedDict()
        x = self.stage16(x)
        result["0"] = x
        x = self.stage32(x)
        result["1"] = x
        for index, layer in enumerate(self.extra, 2):
            x = layer(x)
            result[str(index)] = x
        return result


def build_detector(pretrained=False):
    backbone = MobileNetV2Features(pretrained)
    anchors = DefaultBoxGenerator([[2, 3]] * 6, min_ratio=0.2, max_ratio=0.95)
    head = SSDLiteHead(backbone.out_channels, anchors.num_anchors_per_location(),
                       len(CLASSES), nn.BatchNorm2d)
    return SSD(backbone, anchors, (320, 320), len(CLASSES), head=head,
               image_mean=[0.485, 0.456, 0.406], image_std=[0.229, 0.224, 0.225],
               score_thresh=0.01, nms_thresh=0.45, detections_per_img=100,
               topk_candidates=300)


def empty_background_loss(logits, targets, topk=64):
    """Mean hard-anchor CE per empty image, averaged over the whole batch.

    The stock SSD loss assigns zero classification loss to images without
    ground-truth boxes. This term keeps empty (bird-free) images contributing
    background gradients. Original SSD loss is retained for positive images;
    empty images must never be assigned a fabricated background box.
    """
    terms = []
    for prediction, target in zip(logits, targets):
        if len(target["boxes"]) == 0:
            labels = torch.zeros(len(prediction), dtype=torch.long, device=prediction.device)
            losses = F.cross_entropy(prediction, labels, reduction="none")
            terms.append(losses.topk(min(topk, len(losses))).values.mean())
    return torch.stack(terms).sum() / len(targets) if terms else logits.sum() * 0


def attach_background_loss(model, topk=64, weight=1.0):
    """Extend model.compute_loss with an empty-image background term, in place."""
    original = model.compute_loss

    def compute(self, targets, outputs, anchors, matches):
        losses = original(targets, outputs, anchors, matches)
        losses["empty_background"] = weight * empty_background_loss(
            outputs["cls_logits"], targets, topk)
        return losses

    model.compute_loss = MethodType(compute, model)


def load_detector(checkpoint, device="cpu"):
    """Load a portable weights package, never silently accept V3/COCO weights."""
    package = torch.load(Path(checkpoint), map_location="cpu", weights_only=True)
    if package.get("architecture") != ARCHITECTURE or package.get("classes") != CLASSES:
        raise ValueError("Expected a two-class MobileNetV2 SSDlite weights package")
    model = build_detector()
    model.load_state_dict(package["model"], strict=True)
    return model.to(device).eval()
