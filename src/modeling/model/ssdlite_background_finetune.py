"""Fine-tune the deployed V2 bird detector with explicitly reviewed empty images.

Background root must contain train/ and val/ (optional test/), split by scene
or recording, not adjacent frames. Default command audits only; train is explicit.
"""
import argparse
import hashlib
import json
import random
from pathlib import Path

import torch
from PIL import Image
from torch.utils.data import DataLoader

from bird_detection_data import BirdDataset, collate, load_manifest, manifest_hash
from ssdlite_mobilenet_v2 import attach_background_loss, empty_background_loss, load_detector
from train_bird_detector import atomic_save, background_metrics, evaluate, package

ROOT = Path (__file__).resolve().parents[1]
BASE = ROOT.parents[1] / 'build/out/modeling/detector'


def background_records (root):
    records, seen = [], {}
    for split in ('train', 'val', 'test'):
        for path in sorted ((Path (root) / split).rglob ('*')):
            if path.suffix.lower() not in ('.jpg', '.jpeg', '.png', '.bmp'):
                continue
            with Image.open (path) as source:
                rgb = source.convert ('RGB')
                digest = hashlib.sha256 (str (rgb.size).encode() + rgb.tobytes()).hexdigest()
                width, height = rgb.size
            if digest in seen:
                raise ValueError (f'Duplicate background image: {path}; first: {seen[digest]}')
            seen[digest] = str (path)
            records.append (dict (id='background_' + digest, path=str (path.resolve()),
                                  boxes=[], split=split, width=width, height=height,
                                  species='background', pixel_sha256=digest))
    if any (not any (r['split'] == split for r in records) for split in ('train', 'val')):
        raise ValueError ('Background train/ and val/ must both contain reviewed images')
    return records


def main ():
    parser = argparse.ArgumentParser (description=__doc__)
    parser.add_argument ('command', choices=['audit', 'train'])
    parser.add_argument ('--background-root', required=True)
    parser.add_argument ('--manifest', default=str (BASE / 'manifest.json'))
    parser.add_argument ('--weights', default=str (BASE / 'best_weights.pt'))
    parser.add_argument ('--output', default=str (ROOT.parents[1] / 'build/out/modeling/background'))
    parser.add_argument ('--epochs', type=int, default=5)
    parser.add_argument ('--batch-size', type=int, default=8)
    parser.add_argument ('--negative-fraction', type=float, default=0.25)
    parser.add_argument ('--lr', type=float, default=1e-4)
    parser.add_argument ('--background-topk', type=int, default=64)
    parser.add_argument ('--background-weight', type=float, default=1.0)
    parser.add_argument ('--score-threshold', type=float, default=0.3)
    parser.add_argument ('--max-recall-drop', type=float, default=0.02)
    parser.add_argument ('--device', default='cuda' if torch.cuda.is_available() else 'cpu')
    parser.add_argument ('--seed', type=int, default=2276)
    args = parser.parse_args()
    if not (args.epochs > 0 and args.batch_size >= 2 and 0 < args.negative_fraction < 1
            and args.lr > 0 and args.background_topk > 0 and args.background_weight > 0
            and 0.01 <= args.score_threshold <= 1 and 0 <= args.max_recall_drop <= 1):
        parser.error ('Invalid training/threshold arguments')
    torch.set_num_threads (4)
    random.seed (args.seed)
    torch.manual_seed (args.seed)
    positives = load_manifest (args.manifest)['records']
    negatives = background_records (args.background_root)
    for row in positives:
        if not row['boxes'] or not Path (row['path']).is_file():
            raise ValueError (f'Missing positive image or annotation: {row["path"]}')
    splits = {s: [r for r in positives if r['split'] == s] for s in ('train', 'val')}
    neg = {s: [r for r in negatives if r['split'] == s] for s in ('train', 'val')}
    if not all (splits.values()):
        raise ValueError ('Positive train/val splits must both be populated')
    audit = dict (positive_counts={s: len (r) for s, r in splits.items()},
                  background_counts={s: len (r) for s, r in neg.items()},
                  manifest_sha256=manifest_hash (positives + negatives), args=vars (args))
    print (json.dumps (audit, indent=2), flush=True)
    if args.command == 'audit':
        return
    output = Path (args.output)
    output.mkdir (parents=True, exist_ok=False)
    (output / 'audit.json').write_text (json.dumps (audit, indent=2), encoding='utf-8')
    (output / 'background_manifest.json').write_text (json.dumps (negatives, indent=2), encoding='utf-8')
    model = load_detector (args.weights, args.device)
    val = DataLoader (BirdDataset (splits['val']), batch_size=args.batch_size, collate_fn=collate)

    def measure ():
        return dict (bird=evaluate (model, val, args.device, args.score_threshold),
                     background=background_metrics (model, neg['val'], args.device, args.score_threshold))

    baseline = measure()
    (output / 'baseline.json').write_text (json.dumps (baseline, indent=2), encoding='utf-8')
    attach_background_loss (model, args.background_topk, args.background_weight)
    optimizer = torch.optim.AdamW ([
        {'params': model.backbone.parameters(), 'lr': args.lr * 0.1},
        {'params': model.head.parameters(), 'lr': args.lr}], weight_decay=1e-4)
    n_negative = max (1, min (args.batch_size - 1, round (args.batch_size * args.negative_fraction)))
    positive_loader = DataLoader (BirdDataset (splits['train'], True),
                                 batch_size=args.batch_size - n_negative, shuffle=True, collate_fn=collate)
    negative_dataset = BirdDataset (neg['train'], True)
    best = (baseline['background']['false_positive_image_rate'],
            baseline['background']['false_boxes_per_image'])
    accepted = False
    for epoch in range (args.epochs):
        model.train()
        # Preserve existing BN calibration while fitting the background domain.
        for module in model.modules():
            if isinstance (module, torch.nn.BatchNorm2d):
                module.eval()
        for images, targets in positive_loader:
            batch = list (zip (images, targets))
            batch += [negative_dataset[random.randrange (len (negative_dataset))] for _ in range (n_negative)]
            images, targets = collate (batch)
            optimizer.zero_grad (set_to_none=True)
            losses = model ([x.to (args.device) for x in images],
                            [{k: v.to (args.device) for k, v in t.items()} for t in targets])
            loss = sum (losses.values())
            if not torch.isfinite (loss):
                raise FloatingPointError (str (losses))
            loss.backward()
            torch.nn.utils.clip_grad_norm_ (model.parameters(), 10)
            optimizer.step()
        metrics = measure()
        candidate = (metrics['background']['false_positive_image_rate'],
                     metrics['background']['false_boxes_per_image'])
        passes = metrics['bird']['recall_at_score'] >= baseline['bird']['recall_at_score'] - args.max_recall_drop
        payload = package (model, epoch, metrics, audit['manifest_sha256'])
        payload['background_finetune'] = vars (args)
        atomic_save (payload, output / 'last_weights.pt')
        if passes and candidate < best:
            best, accepted = candidate, True
            atomic_save (payload, output / 'best_weights.pt')
        report = dict (epoch=epoch + 1, metrics=metrics, recall_gate_passed=passes,
                       best_background_metrics=best)
        with (output / 'history.jsonl').open ('a', encoding='utf-8') as stream:
            stream.write (json.dumps (report) + '\n')
        print (json.dumps (report), flush=True)
    print ('Accepted candidate saved.' if accepted else 'No improvement met the recall gate; retain original weights.')


if __name__ == '__main__':
    main()
