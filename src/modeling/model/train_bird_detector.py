"""Audit, train/resume, evaluate and predict with the two-class V2 detector."""
import argparse
import json
import os
import random
import time
from pathlib import Path

import numpy as np
import torch
from PIL import Image, ImageDraw
from torch.utils.data import DataLoader
from torchvision import __version__ as torchvision_version
from torchvision.ops import box_iou
from torchvision.transforms.functional import to_tensor

from bird_detection_data import BirdDataset, collate, load_manifest, prepare_manifest
from ssdlite_mobilenet_v2 import (ARCHITECTURE, CLASSES, attach_background_loss,
                                  build_detector, load_detector)

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT.parents[1] / "build/out/modeling/detector"


def atomic_save(payload, path):
    path = Path(path)
    temporary = path.with_suffix(path.suffix + ".tmp")
    torch.save(payload, temporary)
    os.replace(temporary, path)


def seed_worker(_):
    seed = torch.initial_seed() % 2**32
    random.seed(seed)
    np.random.seed(seed)


def make_loader(records, args, training=False, generator=None):
    return DataLoader(BirdDataset(records, training), batch_size=args.batch_size,
                      shuffle=training, num_workers=args.workers,
                      pin_memory=args.device.startswith("cuda"), drop_last=False,
                      collate_fn=collate, worker_init_fn=seed_worker, generator=generator)


def detection_metrics(predictions, targets, threshold=0.3):
    """One-class, one-to-one IoU matching; all-points AP50 (not COCO mAP)."""
    ranked = []
    n_gt = 0
    best_ious = []
    for prediction, target in zip(predictions, targets):
        gt = target["boxes"].cpu()
        keep = prediction["labels"].cpu() == 1
        boxes = prediction["boxes"].cpu()[keep]
        scores = prediction["scores"].cpu()[keep]
        order = scores.argsort(descending=True, stable=True)
        boxes, scores = boxes[order], scores[order]
        ious = box_iou(boxes, gt)
        n_gt += len(gt)
        high = scores >= threshold
        if len(gt):
            best_ious.extend((ious[high].max(0).values if high.any()
                              else torch.zeros(len(gt))).tolist())
        matched = torch.zeros(len(gt), dtype=torch.bool)
        for i, score in enumerate(scores.tolist()):
            candidates = ious[i].clone()
            candidates[matched] = -1
            ok = False
            if len(gt):
                value, index = candidates.max(0)
                ok = value.item() >= 0.5
                if ok:
                    matched[index] = True
            ranked.append((score, int(ok)))
    ranked.sort(key=lambda p: -p[0])
    flags = np.asarray([r[1] for r in ranked], dtype=np.float64)
    tp = np.cumsum(flags)
    fp = np.cumsum(1 - flags)
    recall = tp / max(n_gt, 1)
    precision = tp / np.maximum(tp + fp, 1)
    mr = np.r_[0., recall, 1.]
    mp = np.r_[0., precision, 0.]
    mp = np.maximum.accumulate(mp[::-1])[::-1]
    changed = np.where(mr[1:] != mr[:-1])[0]
    ap = float(np.sum((mr[changed + 1] - mr[changed]) * mp[changed + 1]))
    selected = [flag for score, flag in ranked if score >= threshold]
    true = sum(selected)
    return {"ap50": ap, "precision_at_score": true / max(len(selected), 1),
            "recall_at_score": true / max(n_gt, 1), "score_threshold": threshold,
            "mean_best_iou_at_score": float(np.mean(best_ious)) if best_ious else 0.,
            "images": len(targets), "gt_boxes": n_gt, "detections_at_score": len(selected)}


@torch.inference_mode()
def evaluate(model, loader, device, threshold=0.3):
    model.eval()
    predictions, targets = [], []
    for images, batch_targets in loader:
        results = model([x.to(device, non_blocking=True) for x in images])
        predictions.extend([{k: v.cpu() for k, v in r.items()} for r in results])
        targets.extend(batch_targets)
    return detection_metrics(predictions, targets, threshold)


@torch.inference_mode()
def background_metrics(model, rows, device, threshold):
    """False-alarm rates on bird-free records; detections here are false positives."""
    model.eval()
    false_images = boxes = 0
    for images, _ in DataLoader(BirdDataset(rows), batch_size=8, collate_fn=collate):
        for prediction in model([image.to(device) for image in images]):
            count = int(((prediction["labels"] == 1) &
                         (prediction["scores"] >= threshold)).sum())
            false_images += count > 0
            boxes += count
    return {"images": len(rows), "false_positive_images": false_images,
            "false_positive_image_rate": false_images / len(rows),
            "false_boxes_per_image": boxes / len(rows), "score_threshold": threshold}


def package(model, epoch, metric, fingerprint):
    return {"architecture": ARCHITECTURE, "classes": CLASSES,
            "model": model.state_dict(), "epoch": epoch, "val_metrics": metric,
            "manifest_sha256": fingerprint,
            "preprocessing": {"size": [320, 320], "mean": [0.485, 0.456, 0.406],
                              "std": [0.229, 0.224, 0.225]},
            "torch_version": str(torch.__version__), "torchvision_version": str(torchvision_version)}


def train(args):
    if args.epochs < 1 or args.batch_size < 2:
        raise ValueError("epochs >= 1 and batch_size >= 2 are required for training BN")
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    if not args.resume and (output / "last.pt").exists():
        raise ValueError("Run already exists. Use --resume or choose a new --output")
    data = load_manifest(args.manifest)
    fingerprint = data["summary"]["manifest_sha256"]
    train_rows = [r for r in data["records"] if r["split"] == "train"]
    val_rows = [r for r in data["records"] if r["split"] == "val"]
    if args.limit:
        train_rows, val_rows = train_rows[:args.limit], val_rows[:args.limit]
    if not train_rows or not val_rows:
        raise ValueError("Empty train/val split")
    random.seed(args.seed)
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)
    generator = torch.Generator().manual_seed(args.seed)
    loader = make_loader(train_rows, args, True, generator)
    val_loader = make_loader(val_rows, args)
    model = build_detector(pretrained=not args.resume and not args.no_pretrained).to(args.device)
    val_background = [r for r in val_rows if not r["boxes"]]
    if any(not r["boxes"] for r in train_rows):
        attach_background_loss(model, args.background_topk, args.background_weight)
    backbone, new_layers = [], []
    for name, parameter in model.named_parameters():
        (backbone if name.startswith(("backbone.stage16", "backbone.stage32")) else new_layers).append(parameter)
    optimizer = torch.optim.AdamW([{"params": backbone, "lr": args.lr * 0.1},
                                   {"params": new_layers, "lr": args.lr}], weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs)
    scaler = torch.amp.GradScaler("cuda", init_scale=1024.,
                                  enabled=args.amp and args.device.startswith("cuda"))
    start, best = 0, -1.
    if args.resume:
        # Full resume checkpoints contain Python/NumPy RNG state: local trusted files only.
        saved = torch.load(args.resume, map_location="cpu", weights_only=False)
        if saved["architecture"] != ARCHITECTURE or saved["manifest_sha256"] != fingerprint:
            raise ValueError("Resume architecture/dataset mismatch")
        for field in ("epochs", "batch_size", "seed", "limit", "amp", "workers", "lr"):
            if saved["args"][field] != getattr(args, field):
                raise ValueError(f"Resume requires unchanged {field}")
        model.load_state_dict(saved["model"])
        optimizer.load_state_dict(saved["optimizer"])
        scheduler.load_state_dict(saved["scheduler"])
        scaler.load_state_dict(saved["scaler"])
        start, best = saved["epoch"] + 1, saved["best_ap50"]
        random.setstate(saved["rng_python"])
        np.random.set_state(saved["rng_numpy"])
        torch.set_rng_state(saved["rng_torch"])
        generator.set_state(saved["rng_loader"])
        if args.device.startswith("cuda"):
            torch.cuda.set_rng_state_all(saved["rng_cuda"])
    metadata = {"architecture": ARCHITECTURE, "classes": CLASSES, "args": vars(args),
                "parameters": sum(p.numel() for p in model.parameters()),
                "manifest_sha256": fingerprint, "train_images": len(train_rows),
                "val_images": len(val_rows), "test_used_for_training": False}
    (output / "run_config.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(json.dumps(metadata), flush=True)
    for epoch in range(start, args.epochs):
        began = time.perf_counter()
        model.train()
        total, count, skipped = 0., 0, 0
        for step, (images, targets) in enumerate(loader):
            # 1x1 feature-map BN needs >1 sample; freeze running statistics only
            # for a singleton final batch, while keeping its gradients/data.
            if len(images) == 1:
                for module in model.modules():
                    if isinstance(module, torch.nn.BatchNorm2d):
                        module.eval()
            images = [x.to(args.device, non_blocking=True) for x in images]
            targets = [{k: v.to(args.device) for k, v in t.items()} for t in targets]
            optimizer.zero_grad(set_to_none=True)
            with torch.autocast(device_type="cuda" if args.device.startswith("cuda") else "cpu",
                                enabled=scaler.is_enabled()):
                losses = model(images, targets)
                loss = sum(losses.values())
            if not torch.isfinite(loss):
                raise FloatingPointError(f"Non-finite loss: {losses}")
            scaler.scale(loss).backward()
            scaler.unscale_(optimizer)
            torch.nn.utils.clip_grad_norm_(model.parameters(), 10.)
            old_scale = scaler.get_scale()
            scaler.step(optimizer)
            scaler.update()
            skipped += int(scaler.get_scale() < old_scale)
            total += loss.item() * len(images)
            count += len(images)
            if step % 50 == 0:
                print(f"epoch={epoch+1}/{args.epochs} step={step}/{len(loader)} loss={loss.item():.4f}", flush=True)
        metrics = evaluate(model, val_loader, args.device, args.score_threshold)
        if val_background:
            metrics["background"] = background_metrics(model, val_background,
                                                       args.device, args.score_threshold)
        if skipped == len(loader):
            raise FloatingPointError("AMP skipped every optimizer step; lower scale or use --no-amp")
        scheduler.step()
        improved = metrics["ap50"] > best
        best = max(best, metrics["ap50"])
        payload = package(model, epoch, metrics, fingerprint)
        if improved:
            atomic_save(payload, output / "best_weights.pt")
        full = {**payload, "optimizer": optimizer.state_dict(), "scheduler": scheduler.state_dict(),
                "scaler": scaler.state_dict(), "args": vars(args), "best_ap50": best,
                "rng_python": random.getstate(), "rng_numpy": np.random.get_state(),
                "rng_torch": torch.get_rng_state(), "rng_loader": generator.get_state(),
                "rng_cuda": torch.cuda.get_rng_state_all() if args.device.startswith("cuda") else []}
        atomic_save(full, output / "last.pt")
        report = {"epoch": epoch + 1, "loss": total / count, "val": metrics,
                  "best_ap50": best, "seconds": time.perf_counter() - began,
                  "amp_skipped_steps": skipped}
        with (output / "history.jsonl").open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(report) + "\n")
        print(json.dumps(report), flush=True)
    print("TRAINING COMPLETE: " + str(output / "best_weights.pt"), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["prepare", "train", "evaluate", "predict"])
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--manifest", default=str(DEFAULT_OUTPUT / "manifest.json"))
    parser.add_argument("--csv", default=None)
    parser.add_argument("--boxes", default=None)
    parser.add_argument("--images", default=None)
    parser.add_argument("--seed", type=int, default=2276)
    parser.add_argument("--val-fraction", type=float, default=0.1)
    parser.add_argument("--allow-exclusions", action="store_true", help="Keep audit failures in report and exclude them")
    parser.add_argument("--background", default=None,
                        help="Root of reviewed bird-free images, one subdirectory per source")
    parser.add_argument("--background-test-fraction", type=float, default=0.1)
    parser.add_argument("--background-topk", type=int, default=64)
    parser.add_argument("--background-weight", type=float, default=1.0)
    parser.add_argument("--epochs", type=int, default=20)
    parser.add_argument("--batch-size", type=int, default=16)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--lr", type=float, default=0.001)
    parser.add_argument("--device", default="cuda" if torch.cuda.is_available() else "cpu")
    parser.add_argument("--amp", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--no-pretrained", action="store_true")
    parser.add_argument("--resume")
    parser.add_argument("--weights", default=str(DEFAULT_OUTPUT / "best_weights.pt"))
    parser.add_argument("--split", choices=["val", "test"], default="test")
    parser.add_argument("--limit", type=int, default=0, help="Smoke tests only; 0 uses the full split")
    parser.add_argument("--score-threshold", type=float, default=0.3)
    parser.add_argument("--image")
    args = parser.parse_args()
    torch.set_num_threads(4)
    if args.command == "prepare":
        if not all((args.csv, args.boxes, args.images)):
            parser.error("prepare requires --csv, --boxes and --images")
        print(json.dumps(prepare_manifest(args.csv, args.boxes, args.images, args.output,
                                         args.seed, args.val_fraction, args.allow_exclusions,
                                         args.background, args.background_test_fraction), indent=2))
    elif args.command == "train":
        train(args)
    elif args.command == "evaluate":
        data = load_manifest(args.manifest)
        records = [r for r in data["records"] if r["split"] == args.split]
        if args.limit:
            records = records[:args.limit]
        if not records:
            raise ValueError("Evaluation split is empty")
        model = load_detector(args.weights, args.device)
        report = {"split": args.split, "weights": str(Path(args.weights).resolve()),
                  "manifest_sha256": data["summary"]["manifest_sha256"],
                  "metrics": evaluate(model, make_loader(records, args), args.device, args.score_threshold)}
        background = [r for r in records if not r["boxes"]]
        birds = [r for r in records if r["boxes"]]
        if background:
            report["background_metrics"] = background_metrics(model, background,
                                                              args.device, args.score_threshold)
            if birds:
                report["bird_metrics"] = evaluate(model, make_loader(birds, args),
                                                  args.device, args.score_threshold)
        path = Path(args.output)
        path.mkdir(parents=True, exist_ok=True)
        (path / f"evaluation_{args.split}.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(json.dumps(report, indent=2))
    else:
        if not args.image:
            parser.error("predict requires --image")
        model = load_detector(args.weights, args.device)
        with Image.open(args.image) as source:
            image = source.convert("RGB")
        with torch.inference_mode():
            result = model([to_tensor(image).to(args.device)])[0]
        selected = (result["labels"] == 1) & (result["scores"] >= args.score_threshold)
        boxes = result["boxes"][selected].cpu().tolist()
        scores = result["scores"][selected].cpu().tolist()
        draw = ImageDraw.Draw(image)
        for box, score in zip(boxes, scores):
            draw.rectangle(box, outline="lime", width=3)
            draw.text((box[0], box[1]), f"bird {score:.3f}", fill="red")
        out = Path(args.output)
        out.mkdir(parents=True, exist_ok=True)
        image.save(out / "prediction.jpg")
        (out / "prediction.json").write_text(json.dumps({"image": args.image, "boxes": boxes, "scores": scores}, indent=2))
        print(str(out / "prediction.jpg"))


if __name__ == "__main__":
    main()
