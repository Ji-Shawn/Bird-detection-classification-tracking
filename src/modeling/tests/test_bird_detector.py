"""Run with: python -m unittest discover -s tests -v"""
import json
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path

import torch
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "model"))
from ssdlite_mobilenet_v2 import ARCHITECTURE, CLASSES, build_detector, load_detector
from bird_detection_data import prepare_manifest, load_manifest, BirdDataset
from train_bird_detector import detection_metrics

torch.set_num_threads(2)


class DetectorTests(unittest.TestCase):
    def test_topology_and_original_coordinate_predictions(self):
        model = build_detector().eval()
        with torch.no_grad():
            feats = model.backbone(torch.rand(2, 3, 320, 320))
            self.assertEqual([tuple(x.shape[1:]) for x in feats.values()],
                             [(576,20,20), (1280,10,10), (512,5,5),
                              (256,3,3), (256,2,2), (128,1,1)])
            head = model.head(list(feats.values()))
            self.assertEqual(tuple(head['cls_logits'].shape), (2,3234,2))
            self.assertEqual(tuple(head['bbox_regression'].shape), (2,3234,4))
            result = model([torch.rand(3, 120, 200)])[0]
        self.assertTrue((result['labels'] == 1).all())
        self.assertTrue((result['boxes'][:, [0,2]] <= 200).all())
        self.assertTrue((result['boxes'][:, [1,3]] <= 120).all())
        self.assertFalse(any(isinstance(m, (torch.nn.Hardswish, torch.nn.Hardsigmoid))
                             for m in model.modules()))
        for m in model.modules():
            if isinstance(m, torch.nn.Conv2d):
                self.assertIn(m.kernel_size, [(1,1), (3,3)])
                self.assertIn(m.groups, [1, m.in_channels])

    def test_loss_and_weight_package_roundtrip(self):
        model = build_detector().train()
        images = [torch.rand(3,320,320) for _ in range(2)]
        targets = [{'boxes': torch.tensor([[30.,40.,220.,250.]]),
                    'labels': torch.ones(1, dtype=torch.int64)} for _ in range(2)]
        loss = sum(model(images, targets).values())
        self.assertTrue(torch.isfinite(loss))
        loss.backward()
        self.assertIsNotNone(next(model.backbone.parameters()).grad)
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'weights.pt'
            torch.save({'architecture': ARCHITECTURE, 'classes': CLASSES,
                        'model': model.state_dict()}, path)
            restored = load_detector(path)
            self.assertTrue(torch.equal(next(model.parameters()), next(restored.parameters())))
            torch.save({'architecture': 'mobilenet_v3'}, path)
            with self.assertRaises(ValueError):
                load_detector(path)

    def test_one_to_one_metrics_and_missing_predictions(self):
        target = {'boxes': torch.tensor([[0.,0.,10.,10.]])}
        pred = {'boxes': torch.tensor([[0.,0.,10.,10.], [0.,0.,10.,10.]]),
                'scores': torch.tensor([.9,.8]), 'labels': torch.tensor([1,1])}
        report = detection_metrics([pred], [target])
        self.assertAlmostEqual(report['ap50'], 1.)
        self.assertAlmostEqual(report['precision_at_score'], .5)
        self.assertAlmostEqual(report['recall_at_score'], 1.)
        empty = {'boxes': torch.empty(0,4), 'scores': torch.empty(0),
                 'labels': torch.empty(0, dtype=torch.int64)}
        report = detection_metrics([empty], [target])
        self.assertEqual(report['ap50'], 0.)
        self.assertEqual(report['mean_best_iou_at_score'], 0.)

    def test_manifest_with_background(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            csv = 'asset_id,label,split,width,height\n'
            annotations = ''
            for index in range(8):
                key = f'{index:032x}'
                Image.new('RGB', (100,50)).save(root / (key + '.jpg'))
                split = 'train' if index < 6 else 'test'
                csv += f'{key},0,{split},100,50\n'
                annotations += f'{key} 10 5 80 40\n'
            (root / 'images.csv').write_text(csv)
            (root / 'boxes.txt').write_text(annotations)
            background = root / 'background'
            for source, count in [('body', 4), ('face', 6)]:
                (background / source).mkdir(parents=True)
                for i in range(count):
                    Image.new('RGB', (30,20)).save(background / source / f'{i}.png')
            args = (root/'images.csv', root/'boxes.txt', root, root/'out')
            bird_only = prepare_manifest(*args)
            first = prepare_manifest(*args, background_root=background)
            second = prepare_manifest(*args, background_root=background)
            self.assertEqual(first['manifest_sha256'], second['manifest_sha256'])
            self.assertNotEqual(first['manifest_sha256'], bird_only['manifest_sha256'])
            self.assertEqual(first['background_images'], 10)
            data = load_manifest(root/'out/manifest.json')
            rows = [r for r in data['records'] if not r['boxes']]
            self.assertEqual(len(rows), 10)
            self.assertEqual({r['split'] for r in rows}, {'train','val','test'})
            counts = Counter((r['id'].split(':')[1].split('/')[0], r['split']) for r in rows)
            self.assertEqual(counts, {('face','train'):4, ('face','val'):1, ('face','test'):1,
                                      ('body','train'):2, ('body','val'):1, ('body','test'):1})
            image, target = BirdDataset(rows, True)[0]
            self.assertEqual(tuple(image.shape), (3,320,320))
            self.assertEqual(tuple(target['boxes'].shape), (0,4))
            self.assertEqual(target['labels'].numel(), 0)
            with self.assertRaises(ValueError):
                prepare_manifest(*args, background_root=root / 'missing')

    def test_manifest_split_audit_and_box_resize(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            csv = 'asset_id,label,split,width,height\n'
            annotations = ''
            for index in range(8):
                key = f'{index:032x}'
                Image.new('RGB', (100,50)).save(root / (key + '.jpg'))
                split = 'train' if index < 6 else 'test'
                csv += f'{key},0,{split},100,50\n'
                annotations += f'{key} 10 5 80 40\n'
            (root / 'images.csv').write_text(csv)
            (root / 'boxes.txt').write_text(annotations)
            args = (root/'images.csv', root/'boxes.txt', root, root/'out')
            first = prepare_manifest(*args)
            second = prepare_manifest(*args)
            self.assertEqual(first['manifest_sha256'], second['manifest_sha256'])
            data = load_manifest(root/'out/manifest.json')
            self.assertEqual(first['splits'], {'train':5,'val':1,'test':2})
            for row in data['records']:
                self.assertEqual(row['official_split'] == 'test', row['split'] == 'test')
            image, target = BirdDataset(data['records'])[0]
            self.assertEqual(tuple(image.shape), (3,320,320))
            torch.testing.assert_close(target['boxes'], torch.tensor([[32.,32.,288.,288.]]))
            path = root/'out/manifest.json'
            data['records'][0]['split'] = 'test'
            path.write_text(json.dumps(data))
            with self.assertRaises(ValueError):
                load_manifest(path)


if __name__ == '__main__':
    unittest.main()
