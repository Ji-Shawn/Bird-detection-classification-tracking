"""Full-frame boundary tests: catch stale 720p limits and byte/row truncation."""
import math
import numpy as np
import pytest
from av_monitor.protocol import PacketType, build_datagram, parse_datagram
from av_monitor.video import VideoAssembler, rgb565_to_rgb888


@pytest.mark.parametrize('chunk', [1400, 8192])
def test_full_hd_frame_survives_reverse_order_and_wire_crc(chunk):
    raw = bytes(range(256)) * 16200  # 1920*1080*2, independent of production constants
    count = math.ceil(len(raw) / chunk)
    assembler = VideoAssembler()
    complete = None
    for i in reversed(range(count)):
        packet = parse_datagram(build_datagram(
            PacketType.VIDEO, 42, 9, 1234, raw[i*chunk:(i+1)*chunk],
            fragment_index=i, fragment_count=count))
        complete = assembler.push(packet, 1) or complete
    assert complete is not None
    assert complete.rgb565 == raw
    assert assembler.rejected == 0


def test_full_hd_last_row_rgb565_colors():
    pixels = np.zeros((1080, 1920), dtype='<u2')
    pixels[1079, 1914:] = [0xF800, 0x07E0, 0x001F, 0xFFFF, 0x0000, 0x8410]
    rgb = rgb565_to_rgb888(pixels.tobytes())
    assert rgb.shape == (1080, 1920, 3)
    assert rgb[1079, 1914:].tolist() == [
        [255,0,0], [0,255,0], [0,0,255], [255,255,255], [0,0,0], [132,130,132]]
