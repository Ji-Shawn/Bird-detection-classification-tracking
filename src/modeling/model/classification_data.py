"""Adapted from CoordinateNet's active MobileNetV2 audio/image data loaders.

Keep the original mel normalization and numpy.resize ordering (not interpolation).
No file loading, weight downloads, directory changes or training on import.
"""
from pathlib import Path

import numpy as np
import pandas as pd
from PIL import Image
from sklearn.model_selection import train_test_split
import torch
from torch.utils.data import Dataset
from torchvision import transforms

IMAGE_EXTENSIONS = ('.jpg', '.jpeg', '.png', '.bmp', '.webp')
IMAGE_SIZE = 128


def mel_tensor(spec):
    spec = np.asarray(spec)
    if spec.ndim != 2 or spec.shape[0] != 128 or not spec.shape[1] or not np.isfinite(spec).all():
        raise ValueError('Mel input must be a finite numeric 128-by-time array')
    spec = np.abs(spec + 80)
    maximum = np.amax(spec)
    # Historical code divided by zero for an all -80 dB input.
    spec = spec / maximum if maximum > 0 else np.zeros_like(spec)
    spec = np.resize(spec, (128, 400))
    return torch.from_numpy(np.asarray(spec, dtype=np.float32)).repeat(3, 1, 1)


def image_transform(training=False):
    steps = ([transforms.RandomResizedCrop(IMAGE_SIZE, scale=(0.6, 1.0)),
              transforms.RandomHorizontalFlip(),
              transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.1)]
             if training else [transforms.Resize(int(IMAGE_SIZE * 1.15)), transforms.CenterCrop(IMAGE_SIZE)])
    return transforms.Compose([*steps, transforms.ToTensor(),
                               transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])])


class ClassificationDataset(Dataset):
    def __init__(self, records, task, training=False):
        self.records, self.task = records, task
        self.transform = image_transform(training) if task == 'image' else None

    def __len__(self):
        return len(self.records)

    def __getitem__(self, index):
        path, label = self.records[index]
        if self.task == 'audio':
            tensor = mel_tensor(np.load(path, allow_pickle=False))
        else:
            with Image.open(path) as image:
                tensor = self.transform(image.convert('RGB'))
        return tensor, label


def classification_records(workdir, task, seed=2276):
    root = Path(workdir).resolve()
    data = root / ('mels' if task == 'audio' else 'images')
    if not data.is_dir():
        raise ValueError('Missing prepared data directory: ' + str(data))
    classes = sorted(p.name for p in data.iterdir() if p.is_dir())
    if task == 'image' and (root / 'config/birds50.html').is_file():
        keep = pd.read_html(root / 'config/birds50.html', encoding='utf8')[0].bird.tolist()
        classes = [name for name in classes if name in keep]
    if not classes:
        raise ValueError('No class directories found')
    class_to_idx = {name: index for index, name in enumerate(classes)}
    records = {'train': [], 'val': []}
    if task == 'audio':
        frame = pd.read_html(root / 'config/registry_mels.html', encoding='utf8')[0]
        for row in frame.itertuples():
            path = Path(str(row.sname).replace('\\', '/'))
            path = path if path.is_absolute() else root / path
            if row.split not in ('TRN', 'VAL'):
                raise ValueError('Unknown audio split: ' + str(row.split))
            if not path.is_file() or path.parent.name not in class_to_idx:
                raise ValueError('Missing audio sample or unknown class: ' + str(path))
            records['train' if row.split == 'TRN' else 'val'].append((str(path.resolve()), class_to_idx[path.parent.name]))
    else:
        for name in classes:
            paths = sorted(p for p in (data / name).iterdir() if p.suffix.lower() in IMAGE_EXTENSIONS)
            if len(paths) < 2:
                raise ValueError('At least two images per class required: ' + name)
            items = [(str(path.resolve()), class_to_idx[name]) for path in paths]
            train, val = train_test_split(items, test_size=0.1, random_state=seed)
            records['train'].extend(train)
            records['val'].extend(val)
    if not all(records.values()):
        raise ValueError('Both train and validation must contain samples')
    if {x[0] for x in records['train']} & {x[0] for x in records['val']}:
        raise ValueError('The same sample occurs in train and validation')
    return classes, records
