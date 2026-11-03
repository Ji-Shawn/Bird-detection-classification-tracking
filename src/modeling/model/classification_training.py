"""Train/evaluate the active audio and image MobileNetV2 recipes explicitly.

Adapted from mobilenet_v2_v1.0.0_torch.py and image_classifier_v1.0.0_torch.py.
Retains their optimizer, learning-rate schedules, seed and train-loss selection.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import random

import numpy as np
import torch
from torch import nn
from torch.utils.data import DataLoader
from torchvision import models

from classification_data import ClassificationDataset, classification_records

OUTPUT_ROOT = Path(__file__).resolve().parents[3] / 'build/out/modeling'


def build_model(num_classes, pretrained=False):
    if num_classes < 1:
        raise ValueError('num_classes must be positive')
    weights = models.MobileNet_V2_Weights.IMAGENET1K_V1 if pretrained else None
    model = models.mobilenet_v2(weights=weights)
    model.classifier[1] = nn.Linear(model.classifier[1].in_features, num_classes)
    return model


def learning_rate(task, epoch):
    if task == 'audio':
        return 0.0003 if epoch < 10 else 0.0001 if epoch < 20 else 0.00001
    return 0.001 if epoch < 3 else 0.0003 if epoch < 10 else 0.0001 if epoch < 20 else 0.00001


def epoch_result(model, loader, device, optimizer=None):
    model.train(optimizer is not None)
    loss_sum = correct = count = 0
    criterion = nn.CrossEntropyLoss()
    with torch.set_grad_enabled(optimizer is not None):
        for inputs, labels in loader:
            inputs, labels = inputs.to(device), labels.to(device)
            if optimizer is not None:
                optimizer.zero_grad()
            logits = model(inputs)
            loss = criterion(logits, labels)
            if not torch.isfinite(loss):
                raise FloatingPointError('Non-finite classification loss')
            if optimizer is not None:
                loss.backward()
                optimizer.step()
            loss_sum += loss.item() * len(labels)
            correct += (logits.argmax(1) == labels).sum().item()
            count += len(labels)
    if not count:
        raise ValueError('No samples evaluated')
    return {'samples': count, 'loss': loss_sum / count, 'accuracy': correct / count}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['train', 'evaluate'])
    parser.add_argument('--task', required=True, choices=['audio', 'image'])
    parser.add_argument('--workdir', type=Path, required=True, help='Prepared data root containing mels/images and config')
    parser.add_argument('--output', type=Path, help='Default: build/out/modeling/<task>')
    parser.add_argument('--weights', type=Path, help='Trusted state_dict; train uses weight-only warm start, not full resume')
    parser.add_argument('--classes', type=Path, help='Required with weights: exact ordered class names, one per line')
    parser.add_argument('--epochs', type=int, help='Original defaults: audio 30, image 40')
    parser.add_argument('--batch-size', type=int, default=32)
    parser.add_argument('--workers', type=int, default=4)
    parser.add_argument('--seed', type=int, default=2276)
    parser.add_argument('--device', default='cuda' if torch.cuda.is_available() else 'cpu')
    parser.add_argument('--pretrained', action=argparse.BooleanOptionalAction, default=True,
                        help='Training only: ImageNet V1; may download. Selftest never enables this')
    args = parser.parse_args()
    if args.epochs is None:
        args.epochs = 30 if args.task == 'audio' else 40
    if args.epochs < 1 or args.batch_size < 1 or args.workers < 0:
        parser.error('epochs/batch-size must be positive and workers non-negative')
    if bool(args.weights) != bool(args.classes):
        parser.error('--weights and --classes must be provided together')
    if args.command == 'evaluate' and not args.weights:
        parser.error('evaluate requires --weights and --classes')
    output = args.output or OUTPUT_ROOT / args.task
    if args.command == 'train' and (output / 'run_config.json').exists():
        parser.error('Output run already exists; choose a new --output; --weights performs an explicit warm start')
    classes, records = classification_records(args.workdir, args.task, args.seed)
    if args.classes and args.classes.read_text(encoding='utf8').splitlines() != classes:
        raise ValueError('Checkpoint class order differs from prepared data')
    random.seed(args.seed)
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)
    os.environ['PYTHONHASHSEED'] = str(args.seed)
    model = build_model(len(classes), pretrained=args.command == 'train' and args.pretrained and not args.weights)
    if args.weights:
        model.load_state_dict(torch.load(args.weights, map_location='cpu', weights_only=True), strict=True)
    model.to(args.device)
    val = DataLoader(ClassificationDataset(records['val'], args.task),
                     batch_size=args.batch_size, shuffle=False, num_workers=args.workers)
    output.mkdir(parents=True, exist_ok=True)
    if args.command == 'evaluate':
        result = {'task': args.task, 'scope': 'Prepared validation split only; not FPGA inference',
                  'weights_sha256': hashlib.sha256(args.weights.read_bytes()).hexdigest(),
                  'classes': classes, 'validation': epoch_result(model, val, args.device)}
        (output / 'evaluation.json').write_text(json.dumps(result, indent=2), encoding='utf8')
        print(json.dumps(result, indent=2))
        return
    train = DataLoader(ClassificationDataset(records['train'], args.task, True),
                       batch_size=args.batch_size, shuffle=True, num_workers=args.workers)
    decay, no_decay = [], []
    for name, parameter in model.named_parameters():
        (decay if name.endswith('weight') and 'conv' in name else no_decay).append(parameter)
    optimizer = torch.optim.Adam([{'params': decay, 'weight_decay': 0.0001},
                                  {'params': no_decay, 'weight_decay': 0.0}], lr=learning_rate(args.task, 0))
    metadata = {'args': {k: str(v) if isinstance(v, Path) else v for k, v in vars(args).items()},
                'architecture': 'mobilenet_v2_1_0', 'classes': classes,
                'torch_version': str(torch.__version__), 'selection': 'minimum_training_loss_as_original',
                'sample_counts': {k: len(v) for k, v in records.items()},
                'split_scope': 'Internal validation; see preparation metadata for official-vs-recording split'}
    (output / 'run_config.json').write_text(json.dumps(metadata, indent=2), encoding='utf8')
    (output / 'classes.txt').write_text('\n'.join(classes) + '\n', encoding='utf8')
    (output / 'split_manifest.json').write_text(json.dumps(records, indent=2), encoding='utf8')
    torch.save(model.state_dict(), output / 'initial_weights.pt')
    best = float('inf')
    for epoch in range(args.epochs):
        lr = learning_rate(args.task, epoch)
        for group in optimizer.param_groups:
            group['lr'] = lr
        train_result = epoch_result(model, train, args.device, optimizer)
        val_result = epoch_result(model, val, args.device)
        if train_result['loss'] < best:
            best = train_result['loss']
            torch.save(model.state_dict(), output / 'best_weights.pt')
        result = {'epoch': epoch + 1, 'lr': lr, 'train': train_result, 'val': val_result}
        with (output / 'history.jsonl').open('a', encoding='utf8') as stream:
            stream.write(json.dumps(result) + '\n')
        print(json.dumps(result), flush=True)


if __name__ == '__main__':
    main()
