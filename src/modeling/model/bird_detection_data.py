"""Read-only NABirds audit, background-image audit, and deterministic manifests."""
import csv
import hashlib
import json
import math
import random
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import torch
from PIL import Image
from torch.utils.data import Dataset
from torchvision.transforms import ColorJitter, functional as TF

BACKGROUND_SPECIES = "__background__"
IMAGE_SUFFIXES = (".jpg", ".jpeg", ".png", ".bmp")


def manifest_hash(records):
    data = json.dumps(records, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(data.encode()).hexdigest()


def audit_background(background_root, seed=2276, val_fraction=0.1, test_fraction=0.1):
    """Audit reviewed bird-free images under <root>/<source>/ and split deterministically.

    Every image is fully decoded once. Each source directory needs >=3 images so
    train/val/test can all be populated; background audit failures are hard errors.
    """
    root = Path(background_root)
    if not root.is_dir():
        raise ValueError(f"Background root does not exist: {root}")
    sources = sorted(p for p in root.iterdir() if p.is_dir())
    if not sources:
        raise ValueError(f"Background root has no source directories: {root}")
    records = []
    for source_dir in sources:
        images = sorted(p for p in source_dir.rglob("*")
                        if p.is_file() and p.suffix.lower() in IMAGE_SUFFIXES)
        if len(images) < 3:
            raise ValueError(f"Background source needs at least 3 images: {source_dir}")
        group = []
        for path in images:
            with Image.open(path) as image:
                image.load()  # Decode, not merely check that the header exists.
                width, height = image.size
            group.append({"id": f"background:{source_dir.name}/{path.name}",
                          "path": str(path.resolve()), "species": BACKGROUND_SPECIES,
                          "official_split": "background", "width": width, "height": height,
                          "boxes": [], "clipped_boxes": 0})
        random.Random(f"{seed}:background:{source_dir.name}").shuffle(group)
        n_val = min(max(1, round(len(group) * val_fraction)), len(group) - 2)
        n_test = min(max(1, round(len(group) * test_fraction)), len(group) - 1 - n_val)
        for i, record in enumerate(group):
            record["split"] = "val" if i < n_val else "test" if i < n_val + n_test else "train"
        records.extend(group)
    return sorted(records, key=lambda r: r["id"])


def prepare_manifest(csv_path, boxes_path, image_root, output, seed=2276, val_fraction=0.1,
                     allow_exclusions=False, background_root=None, background_test_fraction=0.1):
    if not 0 < val_fraction < 1:
        raise ValueError("val_fraction must lie in (0,1)")
    boxes = defaultdict(list)
    for line in Path(boxes_path).read_text().splitlines():
        key, x, y, w, h = line.split()
        x, y, w, h = map(float, (x, y, w, h))
        if not all(math.isfinite(v) for v in (x, y, w, h)) or w <= 0 or h <= 0:
            raise ValueError(f"Invalid annotation: {line}")
        boxes[key.replace("-", "")].append([x, y, x + w, y + h])
    with open(csv_path, newline="", encoding="utf-8-sig") as stream:
        rows = list(csv.DictReader(stream))
    if len({r["asset_id"] for r in rows}) != len(rows):
        raise ValueError("Duplicate image IDs in CSV")

    def audit(row):
        key = row["asset_id"]
        path = Path(image_root) / (key + ".jpg")
        if row["split"] not in ("train", "test"):
            return None, {"id": key, "error": "unknown official split"}
        if key not in boxes:
            return None, {"id": key, "error": "missing bounding box"}
        try:
            with Image.open(path) as image:
                width, height = image.size
                image.load()  # Decode, not merely check that the JPEG header exists.
            if (width, height) != (int(row["width"]), int(row["height"])):
                raise ValueError("CSV/image dimensions differ")
            clipped = []
            corrections = 0
            for box in boxes[key]:
                x1, y1, x2, y2 = box
                fixed = [max(0., x1), max(0., y1), min(float(width), x2), min(float(height), y2)]
                if fixed[2] <= fixed[0] or fixed[3] <= fixed[1]:
                    raise ValueError("empty/outside box")
                # A large overrun can indicate a resized image / mismatched annotations.
                if max(abs(a - b) for a, b in zip(box, fixed)) > 1.0:
                    raise ValueError(f"box exceeds image by >1 pixel: {box}")
                corrections += int(fixed != box)
                clipped.append(fixed)
            return {"id": key, "path": str(path.resolve()), "species": row["label"],
                    "official_split": row["split"], "width": width, "height": height,
                    "boxes": clipped, "clipped_boxes": corrections}, None
        except Exception as error:
            return None, {"id": key, "error": str(error)}

    with ThreadPoolExecutor(max_workers=8) as pool:
        checked = list(pool.map(audit, rows))
    records = sorted([r for r, e in checked if r], key=lambda r: r["id"])
    errors = [e for r, e in checked if e]
    train_groups = defaultdict(list)
    for record in records:
        if record["official_split"] == "test":
            record["split"] = "test"
        else:
            train_groups[record["species"]].append(record)
    for species, group in sorted(train_groups.items()):
        if len(group) < 2:
            raise ValueError(f"Species {species} needs at least two training images")
        random.Random(f"{seed}:{species}").shuffle(group)
        count = max(1, round(len(group) * val_fraction))
        count = min(count, len(group) - 1)
        for i, record in enumerate(group):
            record["split"] = "val" if i < count else "train"
    background = []
    if background_root is not None:
        background = audit_background(background_root, seed, val_fraction, background_test_fraction)
        records += background
    summary = {"source_images": len(rows), "valid_images": len(records),
               "splits": dict(Counter(r["split"] for r in records)),
               "species": len({r["species"] for r in records if r["species"] != BACKGROUND_SPECIES}),
               "clipped_boxes": sum(r["clipped_boxes"] for r in records),
               "errors": errors, "excluded_images": len(errors),
               "allow_exclusions": allow_exclusions, "seed": seed, "val_fraction": val_fraction,
               "background_images": len(background),
               "background_by_source": dict(Counter(r["id"].split(":")[1].split("/")[0]
                                                    for r in background)),
               "manifest_sha256": manifest_hash(records)}
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    (output / "audit.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    if errors and not allow_exclusions:
        raise ValueError(f"Audit failed for {len(errors)} images; see {output / 'audit.json'}")
    if set(summary["splits"]) != {"train", "val", "test"}:
        raise ValueError("A required split is empty")
    manifest = {"schema": 1, "summary": summary, "records": records}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return summary


def load_manifest(path):
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if manifest_hash(data["records"]) != data["summary"]["manifest_sha256"]:
        raise ValueError("Manifest checksum mismatch")
    return data


class BirdDataset(Dataset):
    def __init__(self, records, augment=False):
        self.records = records
        self.augment = augment
        self.color = ColorJitter(brightness=0.15, contrast=0.15, saturation=0.1)

    def __len__(self):
        return len(self.records)

    def __getitem__(self, index):
        row = self.records[index]
        with Image.open(row["path"]) as source:
            image = source.convert("RGB")
        boxes = torch.tensor(row["boxes"], dtype=torch.float32).reshape(-1, 4)
        if self.augment:
            if torch.rand(()).item() < 0.5:
                image = TF.hflip(image)
                boxes[:, [0, 2]] = image.width - boxes[:, [2, 0]]
            image = self.color(image)
        # Resize on CPU to bound host/GPU transfer memory. SSD sees 320x320;
        # inference on original images still returns original-coordinate boxes.
        width, height = image.size
        image = TF.resize(image, [320, 320], antialias=True)
        boxes *= torch.tensor([320 / width, 320 / height, 320 / width, 320 / height])
        return TF.to_tensor(image), {"boxes": boxes,
                                    "labels": torch.ones(len(boxes), dtype=torch.int64),
                                    "image_id": torch.tensor(index)}


def collate(batch):
    return tuple(zip(*batch))
