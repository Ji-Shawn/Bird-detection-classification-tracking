import json
from pathlib import Path
import sys
import tempfile
import unittest

import numpy as np
import pandas as pd
from PIL import Image
import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'model'))
from classification_data import ClassificationDataset, classification_records, mel_tensor, image_transform
from classification_training import build_model, learning_rate


class ClassificationTests(unittest.TestCase):
    def test_mel_matches_original_preprocessing(self):
        value = np.linspace(-80., 0., 128 * 401).reshape(128, 401)
        expected = np.abs(value + 80)
        expected = np.resize(expected / expected.max(), (128, 400)).astype(np.float32)
        actual = mel_tensor(value)
        self.assertEqual(tuple(actual.shape), (3, 128, 400))
        for channel in actual:
            np.testing.assert_array_equal(channel.numpy(), expected)

    def test_silence_and_invalid_mel_are_explicit(self):
        self.assertTrue(torch.equal(mel_tensor(np.full((128, 401), -80.)), torch.zeros(3, 128, 400)))
        for bad in (np.zeros((127, 401)), np.full((128, 401), np.nan), np.empty((128, 0))):
            with self.assertRaises(ValueError):
                mel_tensor(bad)

    def test_audio_paths_order_and_overlap_rejection(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'config').mkdir()
            rows = []
            for bird in ('zbird', 'abird'):
                (root / 'mels' / bird).mkdir(parents=True)
                for index, split in enumerate(('TRN', 'VAL')):
                    relative = f'mels/{bird}/{index}.npy'
                    np.save(root / relative, np.full((128, 401), -40.))
                    rows.append((relative, bird, split))
            table = pd.DataFrame(rows, columns=['sname', 'bird', 'split'])
            table.to_html(root / 'config/registry_mels.html')
            classes, records = classification_records(root, 'audio')
            self.assertEqual(classes, ['abird', 'zbird'])
            tensor, label = ClassificationDataset(records['train'], 'audio')[0]
            self.assertEqual(tuple(tensor.shape), (3, 128, 400))
            self.assertEqual(label, 1)
            table.loc[1, 'sname'] = table.loc[0, 'sname']
            table.to_html(root / 'config/registry_mels.html')
            with self.assertRaisesRegex(ValueError, 'same sample'):
                classification_records(root, 'audio')

    def test_image_split_and_validation_transform(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for bird in ('zbird', 'abird'):
                (root / 'images' / bird).mkdir(parents=True)
                for index in range(4):
                    Image.new('RGB', (150, 170), (index * 30, 40, 50)).save(root / 'images' / bird / f'{index}.png')
            classes, first = classification_records(root, 'image')
            self.assertEqual((classes, first), classification_records(root, 'image'))
            self.assertEqual(classes, ['abird', 'zbird'])
            self.assertEqual({k: len(v) for k, v in first.items()}, {'train': 6, 'val': 2})
            tensor, _ = ClassificationDataset(first['val'], 'image')[0]
            self.assertEqual(tuple(tensor.shape), (3, 128, 128))
            self.assertTrue(torch.isfinite(tensor).all())

    def test_two_mobilenet_input_contracts_without_pretraining(self):
        model = build_model(60, pretrained=False).eval()
        with torch.inference_mode():
            for shape in ((1, 3, 128, 400), (1, 3, 128, 128)):
                result = model(torch.zeros(shape))
                self.assertEqual(tuple(result.shape), (1, 60))
                self.assertTrue(torch.isfinite(result).all())

    def test_original_learning_rate_boundaries(self):
        self.assertEqual([learning_rate('audio', n) for n in (0, 9, 10, 19, 20)],
                         [0.0003, 0.0003, 0.0001, 0.0001, 0.00001])
        self.assertEqual([learning_rate('image', n) for n in (0, 2, 3, 9, 10, 20)],
                         [0.001, 0.001, 0.0003, 0.0003, 0.0001, 0.00001])


if __name__ == '__main__':
    unittest.main()
