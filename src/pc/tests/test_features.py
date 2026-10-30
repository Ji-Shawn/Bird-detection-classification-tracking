import struct

from av_monitor.features import FeatureHistory
from av_monitor.protocol import PacketType, build_datagram, parse_datagram


def _feature(sequence: int, value: int, *, valid: int = 1, flags: int = 1):
    payload = struct.pack("!hHHBB", 90 * 128, 16384, 128, valid, flags)
    payload += struct.pack("!128H", *([value] * 128))
    return parse_datagram(build_datagram(PacketType.FEATURE, 1, sequence, sequence * 10_000, payload))


def test_ring_wrap_gap_and_direction():
    history = FeatureHistory(columns=10)
    for seq in range(12):
        history.push(_feature(seq, seq), seq * 1_000_000)
    history.push(_feature(14, 14, valid=0), 14_000_000)
    mel, direction = history.snapshot(15_000_000)
    assert mel.shape == (128, 10)
    assert mel[0, -3:].tolist() == [0, 0, 14]
    assert history.gaps == 2
    assert direction.angle_deg == 0.0
    assert not direction.valid


def test_direction_requires_gated_packet_and_expires_on_disconnect():
    history=FeatureHistory()
    history.push(_feature(0,1,flags=0),1_000_000_000)
    assert not history.snapshot(1_000_000_001)[1].valid
    history.push(_feature(1,1),2_000_000_000)
    assert history.snapshot(2_000_000_001)[1].angle_deg==90
    expired=history.snapshot(2_501_000_000)[1]
    assert not expired.valid and expired.angle_deg==0 and expired.confidence==0


def test_invalid_new_packet_clears_angle_and_late_packet_cannot_restore_it():
    history=FeatureHistory()
    history.push(_feature(3,1),1_000_000_000)
    history.push(_feature(4,1,valid=0),1_010_000_000)
    history.push(_feature(3,1),1_020_000_000)
    state=history.snapshot(1_021_000_000)[1]
    assert not state.valid and state.angle_deg==0
