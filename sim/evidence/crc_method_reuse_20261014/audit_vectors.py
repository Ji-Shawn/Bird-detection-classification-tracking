"""Read-only CRC stimulus/golden audit; does not simulate RTL or access hardware."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import zlib


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def audit(folder):
    expected_path = folder / 'expected.hex'
    expected = [int(line, 16) for line in expected_path.read_text().splitlines()]
    configuration = (folder / 'vector_config.vh').read_text()
    declared_words = int(re.search(r'`define WORDS (\d+)', configuration).group(1))
    declared_packets = int(re.search(r'`define PACKETS (\d+)', configuration).group(1))
    metadata = json.loads((folder / 'vectors.json').read_text())
    if len(expected) != declared_packets or metadata['packets'] != declared_packets:
        raise ValueError('Inconsistent expected packet count')
    packet = bytearray()
    lengths = []
    words = 0
    with (folder / 'input.hex').open() as stream:
        for line in stream:
            token = line.strip()
            if not re.fullmatch(r'[0-9a-fA-F]{5}', token):
                raise ValueError('Malformed input word at line ' + str(words + 1))
            value = int(token, 16)
            if value >= (1 << 19):
                raise ValueError('Input word exceeds 19 bits')
            keep, last = (value >> 16) & 3, bool(value & (1 << 18))
            if keep not in (0, 1, 3) or (keep == 0 and (not last or packet)):
                raise ValueError('Invalid byte-enable/empty-packet encoding')
            if keep & 1:
                packet.append(value & 255)
            if keep & 2:
                packet.append((value >> 8) & 255)
            words += 1
            if last:
                index = len(lengths)
                if index >= len(expected) or zlib.crc32(packet) != expected[index]:
                    raise ValueError('CRC mismatch at packet ' + str(index))
                if index == 0 and packet != b'':
                    raise ValueError('First packet is not the declared empty input')
                if index == 1 and packet != b'123456789':
                    raise ValueError('Second packet is not the standard check string')
                lengths.append(len(packet))
                packet.clear()
    if packet or words != declared_words or words != metadata['words']:
        raise ValueError('Truncated input or incorrect word count')
    if len(lengths) != declared_packets:
        raise ValueError('Incorrect compared packet count')
    if expected[:2] != [0, 0xcbf43926]:
        raise ValueError('Standard CRC32 check values differ')
    return {
        'status': 'pass', 'scope': 'Offline parsing of input.hex and zlib CRC32 comparison; not an RTL rerun',
        'packets_compared': len(lengths), 'input_words': words,
        'crc_mismatches': 0, 'payload_bytes': sum(lengths),
        'empty_packets': lengths.count(0), 'odd_length_packets': sum(n % 2 for n in lengths),
        'maximum_packet_bytes': max(lengths),
        'standard_checks': {'empty': '00000000', '123456789': 'cbf43926'},
        'input_files_sha256': {name: sha(folder / name) for name in ('input.hex', 'expected.hex', 'vector_config.vh', 'vectors.json')},
        'rtl_simulator_started': False, 'vivado_started': False,
        'board_accessed': False, 'physical_sd_card_accessed': False,
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--vectors-dir', type=Path, required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(audit(args.vectors_dir), indent=2))
    except (ValueError, OSError, KeyError, AttributeError) as error:
        raise SystemExit('VECTOR_AUDIT_FAIL: ' + str(error))
