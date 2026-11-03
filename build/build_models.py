"""Build, train and evaluate the CPU/GPU models; run without arguments for help."""
from pathlib import Path
import subprocess
import sys


def main():
    root = Path(__file__).resolve().parents[1]
    command = [sys.executable, '-B', str(root / 'src/modeling/run.py'), *sys.argv[1:]]
    return subprocess.call(command, cwd=root)


if __name__ == '__main__':
    raise SystemExit(main())
