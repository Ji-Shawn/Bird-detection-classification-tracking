"""Build the M50 SD loader/image from the same sealed application pair as JTAG.

No hardware access and no SD-card writes. Run --build after release.py passes.
The image is independently checked by verify_image.py after packaging.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import struct
import subprocess
import sys
import zipfile

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = HERE / 'image'
TOOLS = ROOT / 'application/tools'
sys.path.insert(0, str(TOOLS))
from local_tools import arm_bin, vivado_bin

CORE0 = ROOT / 'application/build/software/core0_hdmi.elf'
CORE1 = ROOT / 'services/core1/build/core1_logmel.elf'
BIT = ROOT / 'verification/j11_adapter_20261016/adapter_system.bit'
XSA = ROOT / 'verification/j11_adapter_20261016/adapter_system.xsa'
ASSETS = ROOT / 'dist/ax7020_bird_minimal_v1'
FSBL_SOURCE = ROOT / 'application/build/fsbl'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def record(path):
    p = Path(path).resolve()
    return {'path': str(p), 'bytes': p.stat().st_size, 'sha256': sha(p)}


def run(args, log=None):
    result = subprocess.run([str(x) for x in args], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT)
    text = result.stdout.decode('utf-8', errors='replace')
    if log:
        with Path(log).open('a', encoding='utf-8') as f:
            f.write(' '.join(str(x) for x in args) + '\n' + text)
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {args[0]}\n{text}')
    return text


def release_gate():
    gate = HERE / 'release.py'
    assert gate.is_file(), 'M50 release verification is required before packaging'
    print(run([sys.executable, '-B', '-X', 'utf8', gate]), end='', flush=True)


def elf_loads(path):
    data = Path(path).read_bytes()
    assert data[:7] == b'\x7fELF\x01\x01\x01', path
    h = struct.unpack_from('<16sHHIIIIIHHHHHH', data)
    assert h[1] == 2 and h[2] == 40 and h[9] == 32, path
    segments = []
    for i in range(h[10]):
        p = struct.unpack_from('<8I', data, h[5] + i * h[9])
        if p[0] == 1:
            assert p[2] == p[3] and p[4] <= p[5] and p[1] + p[4] <= len(data)
            segments.append((p[2], p[5], data[p[1]:p[1] + p[4]]))
    return h[4], segments


def symbols(path):
    text = run([arm_bin() / 'arm-none-eabi-nm.exe', '-n', path])
    return {m[3]: (int(m[1], 16), m[2]) for line in text.splitlines()
            if (m := re.fullmatch(r'([0-9a-fA-F]+)\s+(\S)\s+(\S+)', line))}


def check_fsbl_startup(elf, map_file):
    syms = symbols(elf)
    assert '_mainCRTStartup' not in syms, 'Generic newlib startup can move the SYS stack outside OCM'
    link_map = Path(map_file).read_text(encoding='utf-8', errors='strict')
    assert 'libxil.a(xil-crt0.o)' in link_map, 'FSBL must use Xilinx xil-crt0'
    assert '_start' in syms and 0 <= syms['_start'][0] < 0x30000
    stacks = {}
    for name in ('_stack', '__irq_stack', '__supervisor_stack', '__abort_stack', '__fiq_stack', '__undef_stack'):
        address = syms[name][0]
        assert 0xffff0000 < address < 0xfffffe00 and address % 16 == 0, (name, hex(address))
        stacks[name] = hex(address)
    entry, loads = elf_loads(elf)
    assert entry == 0
    for address, memory_size, blob in loads:
        assert ((0 <= address and address + memory_size <= 0x30000) or
                (0xffff0000 <= address and address + memory_size <= 0xfffffe00)), hex(address)
    return {'runtime': 'Xilinx libxil xil-crt0', 'generic_crt_absent': True,
            'all_load_ranges_in_ocm': True, 'stack_addresses': stacks}


def build_fsbl():
    out = OUT / 'fsbl'
    out.mkdir(parents=True, exist_ok=True)
    bsp = FSBL_SOURCE / 'zynq_fsbl_bsp/ps7_cortexa9_0'
    gcc = arm_bin() / 'arm-none-eabi-gcc.exe'
    sdk = vivado_bin().parent / 'data/embeddedsw'
    spec = sdk / 'scripts/specs/arm/Xilinx.spec'
    handoff = sdk / 'lib/sw_apps/zynq_fsbl/src/fsbl_handoff.S'
    assert spec.is_file() and handoff.is_file()
    # Use the exact PS init emitted with the unchanged M48 adapter bitstream.
    with zipfile.ZipFile(XSA) as z:
        for name in ('ps7_init.c', 'ps7_init.h'):
            entries = [n for n in z.namelist() if n.endswith('/' + name) or n == name]
            assert len(entries) == 1, name
            blob = z.read(entries[0])
            assert blob == (FSBL_SOURCE / name).read_bytes(), ('FSBL PS init differs from adapter XSA', name)
            (out / name).write_bytes(blob)
    gap, kind = symbols(CORE0)['network_video_gap_us']
    assert kind in ('D', 'd') and 0x100000 <= gap < 0x08000000
    (out / 'm50_handoff_config.h').write_text(
        f'#define M50_NETWORK_VIDEO_GAP_ADDRESS 0x{gap:08x}U\n', encoding='ascii')
    srcs = []
    for source in sorted(FSBL_SOURCE.glob('*.c')):
        if source.name in ('fsbl_hooks.c', 'ps7_init.c'):
            continue
        srcs.append(source)
    srcs += [out / 'ps7_init.c', HERE / 'fsbl_hooks.c', handoff]
    flags = ['-mcpu=cortex-a9', '-mfpu=vfpv3', '-mfloat-abi=hard', '-O2', '-g',
             '-DFSBL_DEBUG_INFO', '-I' + str(out), '-I' + str(FSBL_SOURCE), '-I' + str(bsp / 'include')]
    log = out / 'build.log'
    log.write_text('', encoding='utf-8')
    objects = []
    for source in srcs:
        obj = out / (source.stem + '.o')
        run([gcc, *flags, '-c', source, '-o', obj], log)
        objects.append(obj)
    elf = out / 'fsbl_m50.elf'
    link_map = out / 'fsbl.map'
    run([gcc, *flags, '-specs=' + str(spec), '-Wl,--build-id=none',
         '-Wl,-T,' + str(FSBL_SOURCE / 'lscript.ld'), '-Wl,-Map,' + str(link_map),
         '-L' + str(bsp / 'lib'), *objects, '-Wl,--start-group', '-lxilffs', '-lrsa',
         '-lxil', '-lc', '-lm', '-lgcc', '-Wl,--end-group', '-o', elf], log)
    startup = check_fsbl_startup(elf, link_map)
    startup.update({'spec': record(spec), 'network_video_gap_address': hex(gap)})
    inputs = [*srcs, FSBL_SOURCE / 'lscript.ld', out / 'm50_handoff_config.h', spec]
    inputs += sorted(FSBL_SOURCE.glob('*.h')) + sorted((bsp / 'include').glob('*.h'))
    inputs += [bsp / 'lib' / n for n in ('libxil.a', 'libxilffs.a', 'librsa.a')]
    compile_report = {'elf': record(elf), 'compiler': record(gcc),
                      'inputs': [record(x) for x in sorted(set(inputs))], 'startup': startup}
    (out / 'compile_inputs.json').write_text(json.dumps(compile_report, indent=2), encoding='utf-8')
    return elf, startup


def prepare_core1():
    dest = OUT / 'core1_sd.elf'
    run([arm_bin() / 'arm-none-eabi-objcopy.exe', '--remove-section=.note.gnu.build-id', CORE1, dest])
    data = bytearray(dest.read_bytes())
    h = struct.unpack_from('<16sHHIIIIIHHHHHH', data)
    for i in range(h[10]):
        offset = h[5] + i * h[9]
        p = struct.unpack_from('<8I', data, offset)
        if p[0] == 1 and p[4] == p[5] == 0:
            struct.pack_into('<I', data, offset, 0)
    dest.write_bytes(data)
    old_entry, old_loads = elf_loads(CORE1)
    new_entry, new_loads = elf_loads(dest)
    assert old_entry == new_entry == 0x08000000
    assert new_loads == [s for s in old_loads if s[0] != 0], 'Core1 executable load bytes changed'
    assert all(address >= 0x08000000 for address, _, _ in new_loads)
    # No non-note runtime content may be discarded at address zero.
    for address, memory_size, blob in old_loads:
        if address == 0:
            assert memory_size == len(blob) and len(blob) <= 128 and b'GNU\0' in blob
    return dest


def model_groups():
    items = json.loads((ASSETS / 'assets_manifest.json').read_text(encoding='utf-8'))
    assert len(items) == 391
    items = [x for x in items if not x['path'].startswith('samples/')]
    assert len(items) == 388
    groups = []
    for lo, hi in ((0x31000000, 0x32000000), (0x32000000, 0x33000000), (0x33000000, 0x34000000)):
        group = [x for x in items if lo <= x['address'] < hi]
        assert group
        start = min(x['address'] for x in group)
        end = max(x['address'] + x['bytes'] for x in group)
        assert end <= hi
        data = bytearray(end - start)
        occupied = []
        for item in group:
            source = (ASSETS / item['path']).resolve()
            assert source.is_relative_to(ASSETS.resolve())
            blob = source.read_bytes()
            assert len(blob) == item['bytes'] and sha(source) == item['sha256'], item['path']
            a, b = item['address'], item['address'] + len(blob)
            assert all(b <= c or a >= d for c, d in occupied), (item['path'], 'overlap')
            occupied.append((a, b))
            data[a - start:b - start] = blob
        dest = OUT / f'model_{lo:08x}.bin'
        dest.write_bytes(data)
        groups.append({'path': str(dest), 'load': start, 'bytes': len(data),
                       'sha256': sha(dest), 'asset_count': len(group)})
    assert sum(g['asset_count'] for g in groups) == 388
    return groups, items


def build():
    release_gate()
    OUT.mkdir(parents=True, exist_ok=True)
    before = {str(p): sha(p) for p in (CORE0, CORE1, BIT, XSA, ASSETS / 'assets_manifest.json')}
    fsbl, startup = build_fsbl()
    core1_sd = prepare_core1()
    groups, assets = model_groups()
    seed = [0x53525032, 170000, 170000, 0, 1140, 0, 0]
    checksum = 0xa5a55a5a
    for value in seed:
        checksum ^= value
    ready = bytearray(0x120)
    struct.pack_into('<III', ready, 0, 0x4d313157, 0x4d323842, 0x4d343846)
    struct.pack_into('<8I', ready, 0x100, *seed, checksum)
    (OUT / 'ready.bin').write_bytes(ready)
    paths = [fsbl, BIT, CORE0, core1_sd]
    lines = ['the_ROM_image:', '{', f' [bootloader] {fsbl.as_posix()}']
    lines += [' ' + p.as_posix() for p in paths[1:]]
    lines += [f' [load=0x{g["load"]:08x}] {Path(g["path"]).as_posix()}' for g in groups]
    lines += [f' [load=0x30f01000] {(OUT / "ready.bin").as_posix()}', '}']
    bif = OUT / 'boot.bif'
    bif.write_text('\n'.join(lines) + '\n', encoding='ascii')
    bootgen = vivado_bin() / 'bootgen.bat'
    run([bootgen, '-arch', 'zynq', '-image', bif, '-o', OUT / 'BOOT.bin', '-w', 'on'], OUT / 'bootgen.log')
    assert before == {str(p): sha(p) for p in (CORE0, CORE1, BIT, XSA, ASSETS / 'assets_manifest.json')}
    report = {'project_revision': 'M51', 'profile': 'M51 bird_class species/date archive; retained M50 four-key PL; shared JTAG/SD applications',
              'boot_bin_sha256': sha(OUT / 'BOOT.bin'), 'bytes': (OUT / 'BOOT.bin').stat().st_size,
              'assets': len(assets), 'groups': groups, 'fsbl_startup': startup,
              'inputs': [record(p) for p in paths + [CORE1, XSA, ASSETS / 'assets_manifest.json',
                        HERE / 'package_sd.py', HERE / 'verify_image.py', HERE / 'fsbl_hooks.c',
                        OUT / 'ready.bin', bif, OUT / 'fsbl/compile_inputs.json']],
              'core0_same_file_as_jtag': record(CORE0), 'core1_same_runtime_as_jtag': record(CORE1),
              'core1_sd_metadata_only': record(core1_sd), 'automatic_mode': 'audio_visual_fusion',
              'startup_tilt_us': 1140, 'power_cycle_verified': False, 'sd_card_written': False}
    (OUT / 'manifest.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    release_gate()
    print(run([sys.executable, '-B', '-X', 'utf8', HERE / 'verify_image.py']), end='')
    print('M51_SD_IMAGE_CREATED', report['boot_bin_sha256'], flush=True)


if __name__ == '__main__':
    raise SystemExit('Use python build/build_boot.py')
