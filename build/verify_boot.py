"""Independently check the eight Zynq BOOT partitions without hardware access."""
from pathlib import Path
import argparse
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / 'build/out/boot_verify.json'


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def read_u32(blob, offset):
    assert 0 <= offset <= len(blob) - 4, 'Truncated word'
    return struct.unpack_from('<I', blob, offset)[0]


def partition_headers(blob):
    assert len(blob) >= 0xa0, 'Truncated BOOT header'
    assert read_u32(blob, 0x20) == 0xaa995566
    assert read_u32(blob, 0x24) == 0x584c4e58
    assert sum(struct.unpack_from('<11I', blob, 0x20)) & 0xffffffff == 0xffffffff, 'BOOT header checksum'
    table = read_u32(blob, 0x9c)
    assert table >= 0xa0 and table % 4 == 0 and table + 9 * 64 <= len(blob), 'Partition table boundary'
    spans, result = [], []
    for index in range(8):
        words = struct.unpack_from('<16I', blob, table + index * 64)
        assert sum(words) & 0xffffffff == 0xffffffff, ('Partition header checksum', index)
        image_words, data_words, total_words, load, entry, offset, attrs = words[:7]
        assert 0 < image_words == data_words <= total_words, ('Partition size', index)
        assert attrs & 0x00030000 == 0, ('Partition must be owned by FSBL', index)
        start, end = offset * 4, (offset + total_words) * 4
        assert start >= table + 9 * 64 and end <= len(blob), ('Partition range', index)
        assert all(end <= a or start >= b for a, b in spans), ('Partition overlap', index)
        spans.append((start, end))
        result.append({'index': index, 'load': load, 'entry': entry, 'attrs': attrs,
                       'offset': start, 'bytes': blob[start:start + data_words * 4]})
    terminator = struct.unpack_from('<16I', blob, table + 8 * 64)
    assert not any(terminator[:15]), 'Unexpected additional partition'
    first = result[0]
    assert read_u32(blob, 0x30) == first['offset'], 'BootROM FSBL offset'
    assert read_u32(blob, 0x34) == read_u32(blob, 0x40) == len(first['bytes']), 'BootROM FSBL size'
    assert read_u32(blob, 0x38) == first['load'] == 0, 'FSBL load address'
    assert read_u32(blob, 0x3c) == first['entry'] == 0, 'FSBL entry'
    assert len(first['bytes']) <= 0x30000, 'FSBL payload outside low OCM'
    return result


def elf_runtime(partition, path, core1=False):
    data = Path(path).read_bytes()
    assert data[:7] == b'\x7fELF\x01\x01\x01', ('Expected 32-bit little-endian ELF', str(path))
    assert len(data) >= 52
    header = struct.unpack_from('<16sHHIIIIIHHHHHH', data)
    assert header[1] == 2 and header[2] == 40 and header[9] == 32, 'Expected executable ARM ELF'
    assert partition['entry'] == header[4], ('ELF entry mismatch', str(path))
    assert header[5] + header[10] * 32 <= len(data), 'ELF program header boundary'
    loads = []
    for index in range(header[10]):
        item = struct.unpack_from('<8I', data, header[5] + index * 32)
        if item[0] != 1 or item[4] == 0:
            continue
        assert item[2] == item[3] and item[4] <= item[5], 'ELF address/size contract'
        assert item[1] + item[4] <= len(data), 'ELF payload boundary'
        payload = data[item[1]:item[1] + item[4]]
        if core1 and item[3] == 0:
            # The retained JTAG ELF has one GNU build-id metadata segment at
            # address zero. The SD wrapper removes only this non-runtime note.
            assert item[4] == item[5] <= 128 and b'GNU\0' in payload, 'Unexpected Core1 content at zero'
            continue
        if core1:
            assert item[3] >= 0x08000000, 'Core1 runtime outside its region'
        offset = item[3] - partition['load']
        assert offset >= 0 and offset + len(payload) <= len(partition['bytes']), ('ELF load range', str(path))
        assert partition['bytes'][offset:offset + len(payload)] == payload, ('ELF runtime bytes differ', str(path))
        loads.append((item[3], len(payload)))
    assert loads and partition['load'] == min(address for address, _ in loads), 'ELF lowest load mismatch'
    return len(loads)


def bitstream_payload(path):
    blob = Path(path).read_bytes()
    assert len(blob) >= 4, 'Truncated bitstream'
    offset = 2 + struct.unpack_from('>H', blob, 0)[0]
    assert offset + 2 <= len(blob) and struct.unpack_from('>H', blob, offset)[0] == 1
    offset += 2
    for tag in b'abcd':
        assert offset + 3 <= len(blob) and blob[offset] == tag, 'Bitstream header'
        count = struct.unpack_from('>H', blob, offset + 1)[0]
        offset += 3 + count
    assert offset + 5 <= len(blob) and blob[offset] == ord('e'), 'Bitstream payload tag'
    count = struct.unpack_from('>I', blob, offset + 1)[0]
    payload = blob[offset + 5:offset + 5 + count]
    assert len(payload) == count and offset + 5 + count == len(blob) and count % 4 == 0
    converted = bytearray(count)
    for index in range(4):
        converted[index::4] = payload[3 - index::4]
    return bytes(converted)


def model_payloads(root):
    root = Path(root).resolve()
    rows = json.loads((root / 'assets_manifest.json').read_text(encoding='utf8'))
    assert len(rows) == 391, 'Unexpected model manifest size'
    assets = [row for row in rows if not row['path'].startswith('samples/')]
    assert len(assets) == 388, 'Expected 388 deployed assets'
    grouped, covered = [], 0
    for low in (0x31000000, 0x32000000, 0x33000000):
        high = low + 0x01000000
        group = [row for row in assets if low <= row['address'] < high]
        assert group, ('Empty model group', hex(low))
        start = min(row['address'] for row in group)
        end = max(row['address'] + row['bytes'] for row in group)
        assert end <= high, 'Model address outside group'
        image, spans = bytearray(end - start), []
        for row in group:
            path = (root / row['path']).resolve()
            assert path.is_relative_to(root) and path.is_file(), 'Model path outside package'
            payload = path.read_bytes()
            assert len(payload) == row['bytes'] and digest(payload) == row['sha256'], row['path']
            a, b = row['address'], row['address'] + len(payload)
            assert all(b <= c or a >= d for c, d in spans), ('Model overlap', row['path'])
            spans.append((a, b))
            image[a - start:b - start] = payload
        covered += len(group)
        grouped.append((start, bytes(image), len(group)))
    assert covered == 388, 'Asset outside the three model groups'
    return grouped


def verify(image=None, core0=None, core1=None, bit=None, fsbl=None, models=None, output=DEFAULT_OUTPUT):
    image = Path(image or ROOT / 'board/firmware/boot.bin').resolve()
    core0 = Path(core0 or ROOT / 'board/firmware/core0.elf').resolve()
    core1 = Path(core1 or ROOT / 'board/firmware/core1.elf').resolve()
    bit = Path(bit or ROOT / 'board/firmware/system.bit').resolve()
    data = image.read_bytes()
    partitions = partition_headers(data)
    groups = model_payloads(models or ROOT / 'data/models')
    expected = [0, 0, 0x00100000, 0x08000000] + [group[0] for group in groups] + [0x30f01000]
    assert [part['load'] for part in partitions] == expected, 'Eight partition load addresses differ'
    core0_loads = elf_runtime(partitions[2], core0)
    core1_loads = elf_runtime(partitions[3], core1, core1=True)
    assert partitions[2]['entry'] == 0x00100000 and partitions[3]['entry'] == 0x08000000
    fsbl_loads = elf_runtime(partitions[0], fsbl) if fsbl else None
    pl = bitstream_payload(bit)
    assert partitions[1]['bytes'][:len(pl)] == pl, 'PL differs from paired bitstream'
    padding = partitions[1]['bytes'][len(pl):]
    assert len(padding) < 64 and len(padding) % 4 == 0
    assert padding == struct.pack('<I', 0x20000000) * (len(padding) // 4), 'Unexpected PL padding'
    for part, (load, payload, _) in zip(partitions[4:7], groups):
        assert part['load'] == load and part['bytes'][:len(payload)] == payload, 'Model partition bytes differ'
        tail = part['bytes'][len(payload):]
        assert len(tail) < 64 and not any(tail), 'Unexpected model padding'
    ready = partitions[7]['bytes']
    assert 0x120 <= len(ready) < 0x160, 'Ready partition size'
    assert struct.unpack_from('<III', ready) == (0x4d313157, 0x4d323842, 0x4d343846), 'Ready boot magic'
    assert not any(ready[12:0x100]), 'Unexpected ready header data'
    seed = struct.unpack_from('<8I', ready, 0x100)
    assert seed[:7] == (0x53525032, 170000, 170000, 0, 1140, 0, 0), 'Servo startup seed'
    checksum = 0xa5a55a5a
    for value in seed[:7]:
        checksum ^= value
    assert checksum == seed[7] and not any(ready[0x120:]), 'Ready checksum/padding'
    report = {'status': 'pass', 'sha256': digest(data), 'bytes': len(data),
              'partitions': 8, 'model_assets': 388,
              'core0_sha256': digest(core0.read_bytes()), 'core1_sha256': digest(core1.read_bytes()),
              'bit_sha256': digest(bit.read_bytes()), 'core0_runtime_segments': core0_loads,
              'core1_runtime_segments': core1_loads, 'fsbl_runtime_segments': fsbl_loads,
              'core1_gnu_note_only_exclusion': True, 'pl_runtime_equal': True,
              'model_groups_equal': True, 'ready_seed_verified': True,
              'fsbl_entry_and_rom_header_verified': True,
              'fsbl_stack_startup_check': 'Performed separately by build_fsbl on rebuilt images; not inferred from BOOT header',
              'board_accessed': False, 'sd_card_written': False}
    if output is not None:
        output = Path(output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print('M51_PORTABLE_BOOT_PASS 8 partitions, 388 assets, paired ELF/PL runtime, ready seed', flush=True)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', type=Path)
    parser.add_argument('--core0', type=Path)
    parser.add_argument('--core1', type=Path)
    parser.add_argument('--bit', type=Path)
    parser.add_argument('--fsbl', type=Path, help='Also compare rebuilt FSBL PT_LOAD bytes')
    parser.add_argument('--models', type=Path)
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    verify(**vars(parser.parse_args()))


if __name__ == '__main__':
    main()
