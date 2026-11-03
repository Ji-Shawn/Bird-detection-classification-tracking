import sys
import importlib.util
import tempfile
import unittest
from pathlib import Path

import torch
from PIL import Image

sys.path.insert (0, str (Path (__file__).resolve().parents[1] / 'model'))
from ssdlite_mobilenet_v2 import build_detector
from bird_detection_data import BirdDataset

spec = importlib.util.spec_from_file_location ('background_finetune',
    Path (__file__).resolve().parents[1] / 'model' / 'ssdlite_background_finetune.py')
module = importlib.util.module_from_spec (spec)
spec.loader.exec_module (module)
torch.set_num_threads (2)


class BackgroundTests (unittest.TestCase):
    def test_empty_loss_has_correct_gradient (self):
        logits = torch.tensor ([[[0., 5.], [3., 0.]]], requires_grad=True)
        loss = module.empty_background_loss (logits, [{'boxes': torch.empty (0, 4)}], 1)
        loss.backward()
        self.assertGreater (loss.item(), 0)
        self.assertGreater (logits.grad[0, 0, 1].item(), 0)
        self.assertEqual (logits.grad[0, 1].abs().sum().item(), 0)

    def test_real_ssd_mixed_and_empty_batch (self):
        model = build_detector().train()
        for m in model.modules():
            if isinstance (m, torch.nn.BatchNorm2d):
                m.eval()
        images = [torch.rand (3, 320, 320) for _ in range (2)]
        empty = {'boxes': torch.empty (0, 4), 'labels': torch.empty (0, dtype=torch.long)}
        positive = {'boxes': torch.tensor ([[20., 30., 150., 180.]]), 'labels': torch.ones (1, dtype=torch.long)}
        with torch.no_grad():
            original = model (images, [empty, empty])
        self.assertEqual (original['classification'].item(), 0)
        module.attach_background_loss (model)
        for targets in ([empty, empty], [positive, empty], [positive, positive]):
            model.zero_grad()
            losses = model (images, targets)
            loss = sum (losses.values())
            self.assertTrue (torch.isfinite (loss))
            if all (len (t['boxes']) for t in targets):
                self.assertEqual (losses['empty_background'].item(), 0)
            else:
                self.assertGreater (losses['empty_background'].item(), 0)
            loss.backward()
            self.assertGreater (sum (p.grad.abs().sum().item() for p in model.head.parameters() if p.grad is not None), 0)

    def test_background_shapes_and_duplicate_rejection (self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path (folder)
            for split, color in [('train', 'red'), ('val', 'blue')]:
                (root / split).mkdir()
                Image.new ('RGB', (40, 30), color).save (root / split / 'image.png')
            rows = module.background_records (root)
            _, target = BirdDataset (rows, True)[0]
            self.assertEqual (tuple (target['boxes'].shape), (0, 4))
            self.assertEqual (target['labels'].numel(), 0)
            Image.new ('RGB', (40, 30), 'red').save (root / 'val' / 'duplicate.png')
            with self.assertRaises (ValueError):
                module.background_records (root)
    def test_background_metrics(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path (folder) / 'empty.png'
            Image.new ('RGB', (40, 30), 'gray').save (path)
            rows = [dict (id='background_0', path=str (path), boxes=[])]
            model = build_detector().eval()
            report = module.background_metrics (model, rows, 'cpu', 0.3)
            self.assertEqual (report['images'], 1)
            self.assertEqual (report['score_threshold'], 0.3)
            self.assertGreaterEqual (report['false_positive_image_rate'], 0.)
            self.assertLessEqual (report['false_positive_image_rate'], 1.)
            self.assertGreaterEqual (report['false_boxes_per_image'], 0.)


if __name__ == '__main__':
    unittest.main()
