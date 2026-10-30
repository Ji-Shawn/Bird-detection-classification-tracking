import socket
import struct
import time

import pytest

from av_monitor.network import ReceiverService
from av_monitor.protocol import PacketType, build_datagram


def test_default_receiver_uses_deployment_ports_and_receives_feature_packet():
    service = ReceiverService("127.0.0.1")
    service.start()
    try:
        payload = struct.pack("!hHHBB", 30 * 128, 24576, 128, 1, 1)
        payload += struct.pack("!128H", *([321] * 128))
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.sendto(build_datagram(PacketType.FEATURE, 7, 1, 1000, payload),
                    ("127.0.0.1", 15002))
        deadline = time.time() + 1
        while service.stats.packets == 0 and time.time() < deadline:
            time.sleep(0.01)
        mel, direction = service.features.snapshot()
        assert service.stats.packets == 1
        assert mel[0, -1] == 321
        assert direction.angle_deg == 30
    finally:
        service.stop()


def test_localhost_feature_receive_and_clean_stop():
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    probe.bind(("127.0.0.1", 0))
    port = probe.getsockname()[1]
    probe.close()
    service = ReceiverService("127.0.0.1", {port: PacketType.FEATURE})
    service.start()
    try:
        payload = struct.pack("!hHHBB", -45 * 128, 30000, 128, 1, 1)
        payload += struct.pack("!128H", *range(128))
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.sendto(build_datagram(PacketType.FEATURE, 2, 8, 99, payload),
                    ("127.0.0.1", port))
        deadline = time.time() + 1
        while service.stats.packets == 0 and time.time() < deadline:
            time.sleep(0.01)
        mel, direction = service.features.snapshot()
        assert mel[127, -1] == 127
        assert direction.angle_deg == -45
    finally:
        service.stop()
    assert not service._threads


def test_start_rolls_back_when_a_later_port_cannot_bind():
    first = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    first.bind(("127.0.0.1", 0))
    first_port = first.getsockname()[1]
    first.close()
    blocker = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    blocker.bind(("127.0.0.1", 0))
    blocked_port = blocker.getsockname()[1]
    service = ReceiverService("127.0.0.1", {
        first_port: PacketType.VIDEO,
        blocked_port: PacketType.FEATURE,
    })
    try:
        with pytest.raises(OSError):
            service.start()
        assert not service._threads
        assert not service._sockets
    finally:
        blocker.close()


def test_direction_telemetry_extension_and_legacy_status():
    service=ReceiverService(port_types={})
    payload=bytes(120)+struct.pack('!IIfI',70,11,.85,1234)
    service._accept_status(payload,time.monotonic_ns())
    t=service.snapshots()[1]
    assert t['direction_threshold_percent']==70 and t['direction_bird_class']==11
    assert t['direction_bird_confidence']==pytest.approx(.85)
    assert t['direction_age_ms']==1234
    service._accept_status(bytes(120),time.monotonic_ns())
    assert 'direction_threshold_percent' not in service.snapshots()[1]


def test_manual_focus_wire_and_validation():
    service=ReceiverService(port_types={});sent=[]
    service._send_control_payload=lambda command,value,label:sent.append((command,value))
    for value in (0,511,1023):service.send_manual_focus(value)
    assert sent==[(12,b'\x00\x00'),(12,b'\x01\xff'),(12,b'\x03\xff')]
    for value in (-1,1024,65535,1.5,'512',True,None):
        with pytest.raises(ValueError):service.send_manual_focus(value)
    assert len(sent)==3


def test_manual_focus_telemetry_and_legacy_capability():
    service=ReceiverService(port_types={})
    prefix=bytes(136)+struct.pack('!16I',0x41465a31,0,8,*([0]*13))+bytes(32)
    extension=struct.pack('!6I',0x4d463031,1,700,700,0,12)
    service._accept_status(prefix+extension,time.monotonic_ns())
    t=service.snapshots()[1]
    assert t['focus_state']==8 and t['manual_focus_supported']
    assert t['manual_focus_target']==t['manual_focus_readback']==700
    assert t['manual_focus_mode'] and not t['manual_focus_busy']
    service._accept_status(prefix+struct.pack('!6I',0x4d463031,1,700,0xffffffff,1,13),time.monotonic_ns())
    assert service.snapshots()[1]['manual_focus_readback'] is None
    for packet in (prefix, prefix+extension[:-1],prefix+struct.pack('!6I',0x4d463031,1,1024,0,0,14)):
        service._accept_status(packet,time.monotonic_ns())
        assert 'manual_focus_supported' not in service.snapshots()[1]
