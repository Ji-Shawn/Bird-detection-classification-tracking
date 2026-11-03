"""CPU synthetic model/data tests. No pretrained downloads, dataset training or FPGA tools."""
import argparse
import contextlib
import importlib.metadata
import io
import json
from pathlib import Path
import socket
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT.parents[1] / 'build/out/modeling/selftest')
    args = parser.parse_args()
    sys.path.insert(0, str(ROOT / 'model'))
    import torch
    torch.set_num_threads(2)
    suite = unittest.defaultTestLoader.discover(str(ROOT / 'tests'))
    stream = io.StringIO()
    with patch.object(socket.socket, 'connect', side_effect=AssertionError('Network is forbidden in selftest')):
        result = unittest.TextTestRunner(stream=stream, verbosity=2).run(suite)
    log = stream.getvalue()
    print(log, end='')
    versions = {name: importlib.metadata.version(name) for name in
                ('torch', 'torchvision', 'numpy', 'pandas', 'scikit-learn', 'Pillow', 'lxml')}
    report = {'status': 'pass' if result.wasSuccessful() else 'fail',
              'tests': result.testsRun, 'failures': len(result.failures), 'errors': len(result.errors),
              'skipped': len(result.skipped), 'python': sys.version, 'packages': versions,
              'scope': 'CPU synthetic topology, forward/backward, metrics, data audit and checkpoint tests',
              'pretrained_downloaded': False, 'dataset_training_started': False,
              'board_accessed': False, 'full_accuracy_evaluated': False}
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'results.json').write_text(json.dumps(report, indent=2), encoding='utf8')
    (args.output / 'tests.txt').write_text(log, encoding='utf8')
    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    raise SystemExit(main())
