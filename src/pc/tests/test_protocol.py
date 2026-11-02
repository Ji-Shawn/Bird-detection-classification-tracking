import os
import pathlib
import random

import pytest

from av_monitor.protocol import PacketError, PacketType, build_datagram, parse_datagram


def test_sdk_golden_vectors():
    vectors = pathlib.Path(__file__).resolve().parents[3] / "sim" / "fixtures" / "protocol"
    # These fixed packets came from the original SDK fixture set. Do not build
    # them with build_datagram: that would only compare this implementation to itself.
    rejected = (
        "bad_fragment_count.bin", "bad_fragment_index.bin", "bad_magic.bin",
        "bad_payload_crc.bin", "bad_version.bin", "truncated.bin",
        "bad_fragment_count_crc_valid.bin", "bad_fragment_index_crc_valid.bin",
    )
    assert {p.name for p in vectors.glob("*.bin")} == {"valid_video.bin", *rejected}
    packet = parse_datagram((vectors / "valid_video.bin").read_bytes())
    assert packet.header.packet_type == PacketType.VIDEO
    assert (packet.header.boot_id, packet.header.sequence, packet.header.timestamp_us) == (
        0x10203040, 17, 1234567,
    )
    assert packet.payload == b"rgb565"
    for name in rejected:
        with pytest.raises(PacketError):
            parse_datagram((vectors / name).read_bytes())
    for name in ("bad_fragment_count_crc_valid.bin", "bad_fragment_index_crc_valid.bin"):
        with pytest.raises(PacketError, match="bad fragment metadata"):
            parse_datagram((vectors / name).read_bytes())


def test_round_trip_all_packet_types():
    for kind in PacketType:
        wire = build_datagram(kind, 7, 9, 123, b"abc")
        packet = parse_datagram(wire)
        assert packet.header.boot_id == 7
        assert packet.header.sequence == 9
        assert packet.payload == b"abc"


def test_random_input_never_raises_unexpected_exception():
    random.seed(17)
    for _ in range(3000):
        raw = os.urandom(random.randrange(0, 8300))
        try:
            parse_datagram(raw)
        except PacketError:
            pass
