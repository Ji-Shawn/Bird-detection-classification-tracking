import os
import pathlib
import random

import pytest

from av_monitor.protocol import PacketError, PacketType, build_datagram, parse_datagram


def test_sdk_golden_vectors():
    vectors = pathlib.Path(__file__).parents[2] / "sdk" / "tests" / "vectors"
    packet = parse_datagram((vectors / "valid_video.bin").read_bytes())
    assert packet.header.packet_type == PacketType.VIDEO
    assert packet.payload == b"rgb565"
    for path in vectors.glob("bad_*.bin"):
        with pytest.raises(PacketError):
            parse_datagram(path.read_bytes())
    with pytest.raises(PacketError):
        parse_datagram((vectors / "truncated.bin").read_bytes())


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
