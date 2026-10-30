"""Portable board actions; no command means help and no hardware access."""
from __future__ import annotations

import argparse
import ctypes
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUT = ROOT / 'build/out/board'
FIRMWARE = ROOT / 'board/firmware'
PUBLISHED = {
    'boot.bin': 'c04337b3943dcd633f29f63af24005de3d8e3f2d749f85e32b83d6a73b6977d9',
    'core0.elf': '4d2391599eeab5adf9ff38790320aeba958dae3c675687977ba4572c47474e33',
    'core1.elf': '7b44dd4dc2767f44fc105e695ad5c1bc9a46d496f8fd7314663dcf21f5576ca9',
    'system.bit': 'e40ca4fa56f394fbb2b5bee504feba79fae2587a027e4db9aeafeeddc4679f26',
    'system.xsa': '42e0182e912797a98795d053550805ace50bc6ffabcccf03c9430d0155519559',
    'ps7_init.tcl': 'ebd0dd81ca8120714e62efd6d69ab9912001d83bfd37e2349f55dc4786a84f85',
}


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def verify() -> None:
    subprocess.run([sys.executable, '-B', '-X', 'utf8', str(ROOT / 'build/verify_package.py')], check=True)
    for name, expected in PUBLISHED.items():
        if sha(FIRMWARE / name) != expected:
            raise RuntimeError('Published M51 firmware does not match: ' + name)


def monitor(bind: str) -> int:
    # SD attachment preserves the existing UI ownership/heartbeat behavior.
    env = os.environ.copy()
    env['PYTHONPATH'] = str(ROOT / 'src/pc')
    OUT.mkdir(parents=True, exist_ok=True)
    return subprocess.call([sys.executable, '-B', '-m', 'av_monitor.main', '--sd-attach', '--bind', bind,
        '--metrics-file', str(OUT / 'monitor_metrics.json'),
        '--result-log', str(OUT / 'recognition_results.jsonl')], cwd=ROOT, env=env)


def xilinx_tools() -> tuple[Path, Path]:
    """Prefer explicit settings, then PATH; never assume an installation drive."""
    configured = os.environ.get('VIVADO_BIN')
    directory = Path(configured) if configured else None
    xsdb = os.environ.get('XSCT')
    debug = Path(xsdb) if xsdb else None
    if debug is None:
        for name in ('xsdb.bat', 'xsct.bat', 'xsdb', 'xsct'):
            found = shutil.which(name)
            if found:
                debug = Path(found)
                break
    if debug is None and directory:
        debug = next((directory / name for name in ('xsdb.bat', 'xsct.bat', 'xsdb', 'xsct')
                      if (directory / name).is_file()), None)
    if not debug or not debug.is_file():
        raise RuntimeError('Set XSCT to xsdb/xsct, or put the Vivado 2023.2 tools on PATH.')
    if directory is None:
        directory = debug.parent
    server = next((directory / name for name in ('hw_server.bat', 'hw_server.exe', 'hw_server')
                   if (directory / name).is_file()), None)
    if server is None:
        found = shutil.which('hw_server') or shutil.which('hw_server.bat')
        server = Path(found) if found else None
    if not server:
        raise RuntimeError('Set VIVADO_BIN to the directory containing hw_server and xsdb.')
    return debug, server


def server_ready() -> bool:
    try:
        with socket.create_connection(('127.0.0.1', 3121), timeout=.3):
            return True
    except OSError:
        return False


def ensure_server(server: Path) -> None:
    if server_ready():
        return
    OUT.mkdir(parents=True, exist_ok=True)
    with (OUT / 'hw_server.log').open('ab') as output:
        subprocess.Popen([str(server), '-s', 'tcp::3121'], stdout=output, stderr=subprocess.STDOUT,
                         creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    for _ in range(30):
        if server_ready():
            return
        time.sleep(.2)
    raise RuntimeError('hw_server did not open TCP 3121; see build/out/board/hw_server.log.')


def tcl_path(path: Path) -> str:
    text = path.resolve().as_posix()
    if any(c in text for c in '{}\n\r'):
        raise ValueError('Move this checkout to a path without braces or line breaks.')
    return '{' + text + '}'


def model_load_script() -> Path:
    assets = ROOT / 'data/models'
    entries = json.loads((assets / 'assets_manifest.json').read_text(encoding='utf-8'))
    entries = [item for item in entries if not item['path'].startswith('samples/')]
    if len(entries) != 388:
        raise RuntimeError('Expected the 388 published runtime model assets.')
    lines = []
    occupied = []
    for row in entries:
        p = (assets / row['path']).resolve()
        if not p.is_relative_to(assets.resolve()) or not p.is_file():
            raise RuntimeError('Missing or escaping model asset: ' + row['path'])
        if p.stat().st_size != row['bytes'] or sha(p) != row['sha256']:
            raise RuntimeError('Model asset hash mismatch: ' + row['path'])
        start, end = row['address'], row['address'] + row['bytes']
        if not 0x31000000 <= start < end <= 0x34000000:
            raise RuntimeError('Model load address outside the published asset region.')
        if any(start < hi and lo < end for lo, hi in occupied):
            raise RuntimeError('Overlapping model load addresses.')
        occupied.append((start, end))
        lines.append(f'dow -data {tcl_path(p)} 0x{start:08x}')
    OUT.mkdir(parents=True, exist_ok=True)
    destination = OUT / 'load_assets.tcl'
    destination.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    return destination


def jtag(action: str, cable: str | None) -> int:
    # Only called by explicit sdcheck or program subcommands, after verification.
    debug, server = xilinx_tools()
    OUT.mkdir(parents=True, exist_ok=True)
    env = {k: v for k, v in os.environ.items()
           if not k.startswith(('RDI_', 'PYTHON')) and k not in ('TCL_LIBRARY', 'TK_LIBRARY')}
    if cable:
        if not re.fullmatch(r'[A-Za-z0-9_-]{1,128}', cable):
            raise ValueError('Cable serial may only contain letters, numbers, underscores and hyphens.')
        env['M51_CABLE'] = cable
    else:
        env.pop('M51_CABLE', None)
    env['M51_PACKAGE_VERIFIED'] = '1'
    env['M51_PACKAGE_ROOT'] = ROOT.as_posix()
    if action == 'program':
        env['M51_ASSET_SCRIPT'] = model_load_script().as_posix()
    ensure_server(server)
    command = [str(debug), str(HERE / ('program.tcl' if action == 'program' else 'read_only_probe.tcl'))]
    completed = subprocess.run(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               timeout=300 if action == 'program' else 20)
    text = completed.stdout.decode('utf-8', errors='replace')
    (OUT / (action + '.log')).write_text(text, encoding='utf-8')
    print(text, end='')
    if completed.returncode:
        raise RuntimeError('JTAG action failed; see build/out/board/' + action + '.log')
    expected = 'M51_PROGRAM_COMPLETE=1' if action == 'program' else 'M51_READ_ONLY_PROBE_COMPLETE=1'
    if expected not in text:
        raise RuntimeError('JTAG action did not report completion.')
    return 0


def removable_identity(card: Path) -> dict:
    """Require a whole removable FAT SD volume, never a supplied subdirectory."""
    if os.name != 'nt':
        raise RuntimeError('The guarded SD writer currently supports Windows removable FAT volumes only. '
                           'For other systems follow board/readme.md and copy BOOT.bin manually.')
    raw = str(card)
    if not re.fullmatch(r'[A-Za-z]:[\\/]*', raw):
        raise ValueError('--sd-root must be a drive root, for example E:/ .')
    letter = raw[0].upper()
    root = Path(letter + ':/').resolve()
    if root != Path(root.anchor) or not root.is_dir():
        raise RuntimeError('The selected SD volume does not exist.')
    if root == Path(os.environ.get('SystemDrive', 'C:') + '/').resolve():
        raise RuntimeError('Refusing the Windows system volume.')
    drive_root = str(root).rstrip('\\/') + '\\'
    if ctypes.windll.kernel32.GetDriveTypeW(drive_root) != 2:
        raise RuntimeError('The target is not a Windows removable drive; nothing was written.')
    command = ("$ErrorActionPreference='Stop'; [Console]::OutputEncoding=[Text.UTF8Encoding]::new($false); "
        f"$v=Get-Volume -DriveLetter {letter}; "
        f"$p=Get-Partition -DriveLetter {letter}; $d=Get-Disk -Number $p.DiskNumber; "
        "[pscustomobject]@{label=$v.FileSystemLabel;fs=$v.FileSystem;type=[string]$v.DriveType;"
        "size=$v.Size;disk=$d.Number;bus=[string]$d.BusType;partition=$p.PartitionNumber;"
        "offset=$p.Offset;unique=$d.UniqueId;boot=$d.IsBoot;system=$d.IsSystem}|ConvertTo-Json -Compress")
    result = subprocess.run(['powershell.exe', '-NoProfile', '-Command', command],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    info = json.loads(result.stdout.decode('utf-8-sig'))
    if info['fs'] not in ('FAT', 'FAT16', 'FAT32') or info['type'] != 'Removable' or info['boot'] or info['system']:
        raise RuntimeError('Expected a removable FAT16/FAT32 SD volume, not a boot/system disk.')
    return info


def picture_inventory(card: Path) -> dict[str, str]:
    result = {}
    for directory in ('BIRDS', 'TRACK', 'bird_class'):
        folder = card / directory
        if folder.is_symlink():
            raise RuntimeError('Refusing a linked photo directory: ' + directory)
        for item in folder.rglob('*'):
            if item.is_symlink():
                raise RuntimeError('Refusing a linked photo/configuration entry.')
            if item.is_file():
                result[item.relative_to(card).as_posix()] = sha(item)
    return result


def copy_new(source: Path, destination: Path) -> None:
    with source.open('rb') as a, destination.open('xb') as b:
        shutil.copyfileobj(a, b, 1024 * 1024)
        b.flush()
        os.fsync(b.fileno())
    if sha(source) != sha(destination):
        raise RuntimeError('Readback hash mismatch: ' + str(destination))


def valid_date(data: bytes) -> None:
    text = data.decode('utf-8-sig').strip()
    if not re.fullmatch(r'\d{4}\.\d{2}\.\d{2}', text):
        raise ValueError('The date template must contain YYYY.MM.DD only.')
    parsed = dt.datetime.strptime(text, '%Y.%m.%d')
    if not 1980 <= parsed.year <= 2107:
        raise ValueError('The configured date is outside the FAT date range.')


def write_sd(root: str, do_write: bool) -> int:
    card = Path(root)
    before_id = removable_identity(card)
    card = card.resolve()
    before_files = picture_inventory(card)
    destination = card / 'BOOT.bin'
    if destination.is_symlink() or (destination.exists() and not destination.is_file()):
        raise RuntimeError('BOOT.bin must be a regular file, if present.')
    old_boot = sha(destination) if destination.exists() else None
    template = ROOT / 'board/sd_card/bird_class/date.txt'
    valid_date(template.read_bytes())
    date = card / 'bird_class/DATE.TXT'
    if date.exists() and not date.is_file():
        raise RuntimeError('Existing bird_class/DATE.TXT is not a file.')
    date_valid = None
    if date.exists():
        try:
            valid_date(date.read_bytes())
            date_valid = True
        except (ValueError, UnicodeError):
            date_valid = False
            print('Existing DATE.TXT is invalid and will be preserved; correct it before a photo-recording boot.')
    report = dict(action='write-sd', sd_root=card.as_posix(), card=before_id,
        old_boot_sha256=old_boot, new_boot_sha256=PUBLISHED['boot.bin'],
        preserved_files=len(before_files), date_template_needed=not date.exists(),
        existing_date_valid=date_valid, written=False)
    if not do_write:
        print(json.dumps(report, ensure_ascii=False, indent=2))
        print('Read-only preview. Add --write to copy the verified image to this volume.')
        return 0
    if shutil.disk_usage(card).free < (FIRMWARE / 'boot.bin').stat().st_size + 4096:
        raise RuntimeError('Not enough space for an atomic BOOT.bin update; no files were changed.')
    OUT.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix='card_backup_', dir=OUT))
    if destination.exists():
        copy_new(destination, backup / 'boot.bin')
    if date.exists():
        copy_new(date, backup / 'date.txt')
    (backup / 'before.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    stage = card / 'M51BOOT.TMP'
    if stage.exists():
        raise RuntimeError('M51BOOT.TMP already exists; inspect the previous update before retrying.')
    copy_new(FIRMWARE / 'boot.bin', stage)
    # Re-identify the card before replacing its boot image.
    if removable_identity(card) != before_id or picture_inventory(card) != before_files:
        raise RuntimeError('Card identity or photos changed during update; BOOT.bin was not replaced.')
    if (sha(destination) if destination.exists() else None) != old_boot:
        raise RuntimeError('The old BOOT.bin changed while preparing the update.')
    os.replace(stage, destination)
    expected = dict(before_files)
    if not date.exists():
        date.parent.mkdir(exist_ok=True)
        copy_new(template, date)
        expected['bird_class/DATE.TXT'] = sha(template)
    if sha(destination) != PUBLISHED['boot.bin'] or picture_inventory(card) != expected:
        raise RuntimeError('Final image/photo/date readback check failed; retain the backup for inspection.')
    report.update(written=True, backup=backup.relative_to(ROOT).as_posix(),
                  date_template_created=report['date_template_needed'],
                  existing_date_overwritten=False, readback_verified=True,
                  photos_preserved=True, formatted=False, board_tested=False)
    (backup / 'receipt.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print('Safely eject the card, insert it with board power off, select SD boot, and power on.')
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_subparsers(dest='action')
    actions.add_parser('verify', help='verify the local package only')
    view = actions.add_parser('monitor', help='attach the unchanged PC UI to an SD-running board')
    view.add_argument('--bind', default='192.168.7.1')
    check = actions.add_parser('sdcheck', help='read-only SD boot/frame status over JTAG')
    check.add_argument('--cable', help='JTAG cable serial; required only when more than one is connected')
    program = actions.add_parser('program', help='explicitly reset and program the board over JTAG')
    program.add_argument('--program', action='store_true', help='required authorization switch')
    program.add_argument('--cable')
    write = actions.add_parser('write-sd', help='preview or update a removable FAT SD card')
    write.add_argument('--sd-root', required=True, help='whole removable drive root, e.g. E:/')
    write.add_argument('--write', action='store_true', help='write BOOT.bin; otherwise read-only preview')
    args = parser.parse_args()
    if not args.action:
        parser.print_help()
        return 0
    if args.action == 'program' and not args.program:
        parser.error('program requires the explicit --program switch; no hardware was accessed')
    verify()
    if args.action == 'monitor':
        return monitor(args.bind)
    if args.action in ('program', 'sdcheck'):
        return jtag(args.action, args.cable)
    if args.action == 'write-sd':
        return write_sd(args.sd_root, args.write)
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print('M51: ' + str(error), file=sys.stderr)
        raise SystemExit(1)
