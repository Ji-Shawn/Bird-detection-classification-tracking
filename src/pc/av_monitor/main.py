from __future__ import annotations

import argparse
from pathlib import Path
import tkinter as tk

from .network import ReceiverService
from .ui import MonitorWindow


def main() -> None:
    parser = argparse.ArgumentParser(description="AX7020 AVP1 UDP monitor")
    parser.add_argument("--bind", default="0.0.0.0", help="local IPv4 address")
    parser.add_argument('--sd-attach',action='store_true',
                        help='attach to a running SD application; closing only disconnects the monitor')
    parser.add_argument("--camera-snapshot", type=Path,
                        help="atomically save the latest complete RGB565 frame once per minute")
    parser.add_argument('--snapshot-interval',type=float,default=60,
                        help='seconds between optional raw camera snapshots (default 60)')
    parser.add_argument('--result-log', type=Path, help='append real board recognition results as JSONL')
    parser.add_argument('--metrics-file', type=Path, help='write live diagnostic counters once per second')
    args = parser.parse_args()
    receiver = ReceiverService(args.bind, snapshot_path=args.camera_snapshot,
        snapshot_interval_s=args.snapshot_interval,result_log=args.result_log)
    receiver.start()
    root = tk.Tk()
    MonitorWindow(root, receiver,metrics_file=args.metrics_file,sd_attach=args.sd_attach)
    root.mainloop()


if __name__ == "__main__":
    main()
