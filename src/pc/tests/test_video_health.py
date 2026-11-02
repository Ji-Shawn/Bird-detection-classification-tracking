"""Real loopback UDP and read-only stale/recovery evidence, without a board."""
import math
import socket
import struct
import threading
import time

import pytest

from av_monitor.frame_flow import FrameFlow
from av_monitor.network import ReceiverService
from av_monitor.protocol import PacketType, build_datagram, parse_datagram
from av_monitor.video import CompletedFrame, FRAME_BYTES, VideoAssembler
from av_monitor.video_health import (MAGIC, OFFSET, STATUS_BYTES, VideoHealth,
                                     decode_health, decode_capture_evidence,
                                     preview_stale_after_s, health_text)


def wait_until(predicate, timeout=2.):
    deadline = time.monotonic()+timeout
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(.01)
    assert predicate()


def free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(('127.0.0.1', 0))
        return probe.getsockname()[1]


def fragments(frame_id=1, timestamp=100, boot=7):
    chunk = 8192
    count = math.ceil(FRAME_BYTES/chunk)
    raw = bytes(chunk)
    for i in range(count):
        yield build_datagram(PacketType.VIDEO, boot, frame_id, timestamp,
            raw[:min(chunk, FRAME_BYTES-i*chunk)], fragment_index=i, fragment_count=count)


def test_udp_partial_frame_expires_without_any_following_packet():
    port = free_port()
    receiver = ReceiverService('127.0.0.1', {port: PacketType.VIDEO})
    # The UDP worker records port_packets before it pushes a packet into the
    # assembler. Wait for the actual assembly, not the earlier receive counter.
    # Keep it alive while the test thread is scheduled, then arm the short expiry.
    receiver.video.timeout_ns = 5_000_000_000
    receiver.start()
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sender:
            sender.sendto(next(fragments()), ('127.0.0.1', port))
        wait_until(lambda: bool(receiver.snapshots()[1]['video_assembly_progress']))
        progress = receiver.snapshots()[1]['video_assembly_progress']
        assert len(progress) == 1 and progress[0]['received'] == 1
        with receiver._lock:
            receiver.video.timeout_ns = 80_000_000
        wait_until(lambda: receiver.snapshots()[1]['video_assembly_loss'] == 1)
        _, telemetry, stats = receiver.snapshots()
        assert telemetry['video_assembly_progress'] == []
        assert stats.video_frames == 0 and stats.port_packets[port] == 1
        assert telemetry['video_last_frame_age_s'] is None
        assert telemetry['video_last_packet_age_s'] > .08
    finally:
        receiver.stop()


def test_udp_full_frames_stall_and_recovery_are_real_not_replayed():
    port = free_port()
    receiver = ReceiverService('127.0.0.1', {port: PacketType.VIDEO})
    receiver.start()
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sender:
            packets = list(fragments())
            for i, packet in enumerate(packets):
                sender.sendto(packet, ('127.0.0.1', port))
                if i % 16 == 0:
                    time.sleep(.001)
            wait_until(lambda: receiver.stats.video_frames == 1)
            first, telemetry, _ = receiver.snapshots()
            assert (first.boot_id, first.frame_id, first.timestamp_us) == (7, 1, 100)
            assert telemetry['video_last_second_frames'] == 1
            wait_until(lambda: receiver.snapshots()[1]['video_stalled'], 2.)
            telemetry = receiver.snapshots()[1]
            assert telemetry['video_last_second_frames'] == 0
            assert telemetry['received_fps'] == 0
            assert telemetry['video_interruptions'] == 1
            assert receiver.snapshots()[0] is None
            # Replaying the entire identical image does not generate FPS or recovery.
            for i, packet in enumerate(packets):
                sender.sendto(packet, ('127.0.0.1', port))
                if i % 16 == 0:
                    time.sleep(.001)
            time.sleep(.1)
            assert receiver.stats.video_frames == 1
            assert receiver.snapshots()[1]['video_stalled']
            for i, packet in enumerate(fragments(2, 200)):
                sender.sendto(packet, ('127.0.0.1', port))
                if i % 16 == 0:
                    time.sleep(.001)
            wait_until(lambda: receiver.stats.video_frames == 2)
            recovered, telemetry, _ = receiver.snapshots()
            assert recovered.frame_id == 2
            assert not telemetry['video_stalled'] and telemetry['video_interruptions'] == 1
            assert telemetry['video_last_gap_s'] > 1
    finally:
        receiver.stop()


def test_delayed_foreign_boot_udp_cannot_clear_current_boot_assembly():
    port = free_port()
    receiver = ReceiverService('127.0.0.1', {port: PacketType.VIDEO})
    status = struct.pack('!11IHH', 1, 0x1000a, 44, 9, 100, 1, 0, 0, 0, 0, 0, 40, 0)
    receiver._accept_status(status, time.monotonic_ns(), 9, 1)
    receiver.start()
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sender:
            sender.sendto(next(fragments(1, 100, boot=9)), ('127.0.0.1', port))
            wait_until(lambda: len(receiver.snapshots()[1]['video_assembly_progress']) == 1)
            sender.sendto(next(fragments(50, 1000, boot=8)), ('127.0.0.1', port))
            wait_until(lambda: receiver.snapshots()[1]['video_rejected_fragments'] == 1)
            telemetry = receiver.snapshots()[1]
            assert telemetry['video_assembly_progress'][0]['boot_id'] == 9
            assert telemetry['video_assembly_progress'][0]['received'] == 1
            assert telemetry['port_packets'][port] == 2
    finally:
        receiver.stop()


def test_two_second_low_rate_gap_is_visible_even_with_nonzero_historical_fps():
    health = VideoHealth()
    health.complete(1_000_000_000, 1.75)
    state = health.snapshot(2_100_000_000, 1.75)
    assert state['video_no_frame_1s'] and not state['video_stalled']
    state = health.snapshot(3_000_000_000, 1.75)
    assert state['video_stalled'] and state['video_interruptions'] == 1
    health.complete(3_010_000_000, 1.75)
    state = health.snapshot(3_020_000_000, 1.75)
    assert not state['video_stalled'] and state['video_max_gap_s'] == 2.01
    assert state['video_interruptions'] == 1


@pytest.mark.parametrize('fps,threshold', [(1., 1.75), (2., 1.), (3., 1.), (4., 1.)])
def test_display_timeout_uses_only_verified_readback(fps, threshold):
    telemetry = {'scan_preview_tuning': {'ready': True, 'values': (5., fps)}}
    assert preview_stale_after_s(telemetry) == threshold
    telemetry['scan_preview_tuning']['ready'] = False
    assert preview_stale_after_s(telemetry) == 1.
    assert '500' not in health_text(telemetry)  # No extension of NCC freshness is advertised.


def health_status(**changes):
    words = [MAGIC, 1, 6, 1, 0x61, 345, 2, 2, 0, 0, 0, 2, 2, 1, 1, 0,
             200, 220, 240, 2000, 2001, 4500, 3, 4, 1, 0, 123, 0, 0, 0, 1, 0]
    for index, value in changes.items():
        words[int(index)] = value
    prefix = bytearray(OFFSET)
    struct.pack_into('!11IHH', prefix, 0, 1, 0x1000a, 44, 7, 100, 345, 0, 0, 0, 0, 0, 40, 0)
    return bytes(prefix)+struct.pack('!32I', *words)


def test_new_health_wire_and_legacy_status_compatibility():
    payload = health_status()
    assert len(payload) == STATUS_BYTES == 1160
    assert len(build_datagram(PacketType.STATUS, 7, 1, 1, payload)) == 1200
    health = decode_health(payload)
    assert health['state'] == 6 and health['pl_valid_frames'] == 345
    assert health['capture_age_ms'] == 200 and health['max_stall_ms'] == 4500
    receiver = ReceiverService(port_types={})
    receiver._accept_status(payload, time.monotonic_ns(), 7, 1)
    telemetry = receiver.snapshots()[1]
    assert telemetry['video_health'] == health
    assert '板端等待新帧' in health_text(telemetry)
    receiver._accept_status(payload[:OFFSET], time.monotonic_ns(), 7, 2)
    assert 'video_health' not in receiver.snapshots()[1]


def test_optional_raw_capture_evidence_preserves_1160_legacy_health_layout():
    payload = health_status()+struct.pack('!8I', 0x56433031, 1, 0x1234,
                                          0x5678, 2300, 456, 7890, 4)
    assert len(payload) == 1192
    assert len(build_datagram(PacketType.STATUS, 7, 1, 1, payload)) == 1232
    assert decode_health(payload) == decode_health(payload[:1160])
    evidence = decode_capture_evidence(payload)
    assert evidence == dict(probe_raw=0x1234, probe_at_observed_stall=0x5678,
        service_max_us=2300, service_calls=456, service_total_us=7890, focus_state=4)
    assert decode_capture_evidence(payload[:1160]) is None
    assert decode_capture_evidence(payload[:-1]) is None
    receiver = ReceiverService(port_types={})
    receiver._accept_status(payload, time.monotonic_ns(), 7, 1)
    assert receiver.snapshots()[1]['video_capture_evidence'] == evidence
    receiver._accept_status(payload[:1160], time.monotonic_ns(), 7, 2)
    assert 'video_capture_evidence' not in receiver.snapshots()[1]


@pytest.mark.parametrize('index,value', [('0', 0), ('1', 2), ('2', 10), ('3', 6), ('4', 128)])
def test_health_wire_rejects_unknown_schema_state_or_flags(index, value):
    assert decode_health(health_status(**{index: value})) is None
    assert decode_health(health_status()[:-1]) is None


def test_fragment_timestamp_cannot_be_mixed_with_same_sequence():
    assembler = VideoAssembler()
    packets = list(fragments())
    assert assembler.push(parse_datagram(packets[0]), 1) is None
    changed = list(fragments(timestamp=200))[1]
    assert assembler.push(parse_datagram(changed), 2) is None
    assert assembler.rejected == 1
    for packet in packets[1:]:
        frame = assembler.push(parse_datagram(packet), 3)
    assert frame.timestamp_us == 100


def test_old_frame_boot_and_replayed_identity_do_not_create_fps():
    assembler = VideoAssembler()
    for packet in fragments(frame_id=0xffffffff, timestamp=100):
        complete = assembler.push(parse_datagram(packet), 1)
    assert complete is not None
    for packet in fragments(frame_id=0, timestamp=200):
        complete = assembler.push(parse_datagram(packet), 2)
    assert complete.frame_id == 0  # Sequence rollover is valid.
    assert assembler.push(parse_datagram(next(fragments(0xffffffff, 100))), 3) is None
    for packet in fragments(frame_id=1, timestamp=1, boot=8):
        complete = assembler.push(parse_datagram(packet), 4)
    assert complete.boot_id == 8
    assert assembler.push(parse_datagram(next(fragments(1, 500, boot=7))), 5) is None
    assert assembler.progress(5) == []


def test_frame_flow_keeps_fault_evidence_when_status_goes_stale():
    telemetry = dict(online=False, video_stalled=True, port_packets={15000: 3},
                     video_last_frame_age_s=2., video_interruptions=1,
                     video_health=decode_health(health_status()),
                     video_assembly_progress=[])
    row = FrameFlow().sample(telemetry, 0, 10)
    assert not row['valid'] and row['reason'] == 'offline_or_stale'
    assert row['video_stalled'] and row['port_packets'] == {15000: 3}
    assert row['video_health']['max_stall_ms'] == 4500


def test_slow_disk_does_not_block_accepting_new_complete_frames(tmp_path, monkeypatch):
    receiver = ReceiverService(port_types={}, snapshot_path=tmp_path/'frame.rgb565',
                               snapshot_interval_s=.001)
    entered = threading.Event()
    release = threading.Event()
    from pathlib import Path
    original = Path.write_bytes
    def slow_write(path, value):
        entered.set()
        assert release.wait(2.)
        return original(path, value)
    monkeypatch.setattr(Path, 'write_bytes', slow_write)
    try:
        receiver._accept_video_frame(CompletedFrame(7, 1, 100, b'first'), 1_000_000_000)
        assert entered.wait(1.)
        start = time.monotonic()
        receiver._accept_video_frame(CompletedFrame(7, 2, 200, b'new'), 1_010_000_000)
        assert time.monotonic()-start < .2
        frame, telemetry, stats = receiver.snapshots()
        assert frame.frame_id == 2 and stats.video_frames == 2
        assert telemetry['video_frame_identity']['timestamp_us'] == 200
    finally:
        release.set()
        receiver.stop()
