import math
import numpy as np

from av_monitor.protocol import PacketType, build_datagram, parse_datagram
from av_monitor.video import FRAME_BYTES, HEIGHT, WIDTH, VideoAssembler, rgb565_to_rgb888


def _packets(raw: bytes, chunk: int, frame_id: int = 3):
    count = math.ceil(len(raw) / chunk)
    return [parse_datagram(build_datagram(PacketType.VIDEO, 1, frame_id, 55,
             raw[i*chunk:(i+1)*chunk], fragment_index=i, fragment_count=count))
            for i in range(count)]


def test_reverse_order_complete_frame_and_duplicate():
    raw = bytes((i & 0xFF for i in range(FRAME_BYTES)))
    packets = _packets(raw, 8192)
    assembler = VideoAssembler()
    assert assembler.push(packets[0], 0) is None
    assert assembler.push(packets[0], 1) is None
    complete = None
    for packet in reversed(packets[1:]):
        complete = assembler.push(packet, 2) or complete
    assert complete is not None and complete.rgb565 == raw
    assert assembler.duplicates == 1


def test_timeout_never_emits_partial_frame():
    raw = bytes(FRAME_BYTES)
    packet = _packets(raw, 1400)[0]
    assembler = VideoAssembler(timeout_ms=1)
    assert assembler.push(packet, 0) is None
    assert assembler.push(packet, 2_000_000) is None
    assert assembler.network_loss == 1


def test_default_timeout_accepts_compat_mtu_frame_sent_over_200_ms():
    raw = bytes(FRAME_BYTES)
    packets = _packets(raw, 1400)
    assembler = VideoAssembler()
    complete = None
    span_ns = 200_000_000
    for index, packet in enumerate(packets):
        now = index * span_ns // (len(packets) - 1)
        complete = assembler.push(packet, now) or complete
    assert complete is not None


def test_rgb565_known_colors():
    pixels = np.zeros((HEIGHT, WIDTH), dtype="<u2")
    pixels[0, :3] = [0xF800, 0x07E0, 0x001F]
    rgb = rgb565_to_rgb888(pixels.tobytes())
    assert rgb[0, :3].tolist() == [[255, 0, 0], [0, 255, 0], [0, 0, 255]]
