import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'model'))
from bird_detection_data import manifest_hash
from ssdlite_cub_continue import prepare


class CubRecipeTests(unittest.TestCase):
    def test_audit_keeps_official_test_and_replay_sources(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            cub = root / 'cub'
            (cub / 'images').mkdir(parents=True)
            tables = {name: [] for name in ('images', 'bounding_boxes', 'train_test_split', 'image_class_labels')}
            for index in range(4):
                Image.new('RGB', (20, 20), (index + 1, 10, 20)).save(cub / 'images' / f'{index}.png')
                tables['images'].append(f'{index} {index}.png')
                tables['bounding_boxes'].append(f'{index} 1 1 10 10')
                tables['train_test_split'].append(f'{index} {0 if index == 3 else 1}')
                tables['image_class_labels'].append(f'{index} 1')
            for name, rows in tables.items():
                (cub / (name + '.txt')).write_text('\n'.join(rows))
            old, background = [], []
            for index, split in enumerate(('train', 'val', 'test')):
                for source, rows in (('old', old), ('background', background)):
                    path = root / f'{source}_{index}.png'
                    Image.new('RGB', (20, 20), (50 + index, 60 if source == 'old' else 70, 80)).save(path)
                    rows.append(dict(id=f'{source}_{index}', path=str(path), split=split,
                                     boxes=[[1, 1, 11, 11]] if source == 'old' else [], species='1'))
            manifest = root / 'old.json'
            manifest.write_text(json.dumps(dict(records=old, summary=dict(manifest_sha256=manifest_hash(old)))))
            negatives = root / 'background.json'
            negatives.write_text(json.dumps(background))
            output = root / 'output'
            output.mkdir()
            rows = prepare(argparse.Namespace(cub=str(cub), old_manifest=str(manifest),
                                              background_manifest=str(negatives), output=str(output), seed=2276))
            self.assertEqual(len(rows), 10)
            self.assertEqual({r['source'] for r in rows}, {'cub', 'old', 'background'})
            for row in rows:
                if row['source'] == 'cub':
                    self.assertEqual(row['official_split'] == 'test', row['split'] == 'test')
            audit = json.loads((output / 'audit.json').read_text())
            self.assertFalse(audit['test_used_for_model_selection'])
            self.assertEqual(audit['excluded_images'], [])


if __name__ == '__main__':
    unittest.main()
