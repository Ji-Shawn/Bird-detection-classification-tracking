"""Explicit model-building commands. Help and doctor never import torch or train."""
import argparse
import importlib.metadata
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
COMMANDS = {
    'classify': 'model/classification_training.py',
    'detect': 'model/train_bird_detector.py',
    'background': 'model/ssdlite_background_finetune.py',
    'cub-continue': 'model/ssdlite_cub_continue.py',
    'prepare-ssw60': 'scripts/prepare_ssw60.py',
    'selftest': 'scripts/selftest.py',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', nargs='?', choices=['doctor', *COMMANDS])
    parser.add_argument('arguments', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.command is None:
        parser.print_help()
        return 0
    if args.command == 'doctor':
        versions = {}
        for name in ('torch', 'torchvision', 'numpy', 'pandas', 'scikit-learn',
                     'Pillow', 'lxml', 'librosa', 'soundfile', 'resampy'):
            try:
                versions[name] = importlib.metadata.version(name)
            except importlib.metadata.PackageNotFoundError:
                versions[name] = 'not installed'
        print(json.dumps({'python': sys.version, 'executable': sys.executable,
                          'packages': versions, 'scope': 'Package discovery only; run selftest to verify imports/operators'}, indent=2))
        return 0
    return subprocess.call([sys.executable, '-B', '-X', 'utf8',
                            str(ROOT / COMMANDS[args.command]), *args.arguments])


if __name__ == '__main__':
    raise SystemExit(main())
