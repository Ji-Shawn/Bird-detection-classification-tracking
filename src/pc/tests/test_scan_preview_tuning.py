"""Offline scan / network-preview tuning: no GUI, board or real socket."""
from types import SimpleNamespace
import struct
import time

import pytest

from av_monitor import audio_tuning as at
from av_monitor import scan_preview_tuning as st
from av_monitor import visual_tuning as vt
from av_monitor.network import ReceiverService
from av_monitor.protocol import PacketType, parse_datagram
from av_monitor.scan_preview_tuning_panel import ScanPreviewTuningPanel
from av_monitor.ui import MonitorWindow


def status(boot=19, revision=1, request=0, ack=0, values=st.DEFAULTS, *, compatible=True):
    payload = bytearray(st.STATUS_BYTES)
    struct.pack_into("!11IHH", payload, 0, 1, 0x1000a, 44, boot, 100, 7, 0, 0, 0, 0, 0, 70, 0)
    struct.pack_into("!10I", payload, 256, 0x53525631, int(compatible), 0, 0, 1140, 0, 0, 0, 1, 0)
    struct.pack_into("!12I", payload, 792, 0x53525638, 1, 1, 1440, 1440, 540, 2480, 180000, 0, 10, 100, 2)
    struct.pack_into("!6I8f2I", payload, 840, vt.MAGIC, 1, 1, 0, 0, boot, *vt.DEFAULTS, 0, 0)
    struct.pack_into("!6I8f2I", payload, 904, at.MAGIC, 1, 1, 0, 0, boot, *at.DEFAULTS, 0, 0)
    struct.pack_into("!6I2f8I", payload, st.OFFSET, st.MAGIC, 1, revision, request, ack, boot,
                     *values, revision-1, 1, 25_000, 400_000, 0, 0, 0, 0)
    return bytes(payload)


def accepted():
    state = st.TuningState()
    assert state.accept_status(status(), 1_000_000_000, 19, 1)
    return state


def test_command_and_status_are_exact_and_old_extensions_stay_readable():
    wire = st.encode_request(19, 3, 77, (4.5, 2.5))
    assert st.COMMAND == 25 and len(wire) == 21
    assert bytes([25])+wire == struct.pack("!BBIII2f", 25, 1, 19, 3, 77, 4.5, 2.5)
    assert st.STATUS_BYTES == 1032 and st.DEFAULTS == (4., 2.5)
    readback = st.decode_readback(status(), packet_boot=19)
    assert (readback.values, readback.scan_step_us, readback.scan_interval_us,
            readback.preview_interval_us) == ((4., 2.5), 1, 25_000, 400_000)
    assert at.decode_readback(status()).values == at.canonical_values(at.DEFAULTS)
    assert vt.decode_readback(status()).values == vt.canonical_values(vt.DEFAULTS)


@pytest.mark.parametrize("values", [(0.5, 1.), (10., 4.), (3.123456789, 2.87654321)])
def test_bounds_and_fractional_values_roundtrip(values):
    canonical = st.canonical_values(values)
    assert st.value_bytes(st.draft_values(st.display_values(canonical))) == st.value_bytes(canonical)
    assert st.decode_readback(status(values=values)).values == canonical


@pytest.mark.parametrize("values", [(.49, 3), (10.01, 3), (5, .99), (5, 4.01),
                                    (float("nan"), 3), (5, float("inf")), (True, 3), ("5", 3),
                                    (5,), (5, 3, 0)])
def test_invalid_complete_group_never_encodes(values):
    with pytest.raises(ValueError): st.encode_request(19, 1, 9, values)


@pytest.mark.parametrize("identity", [(0, 1, 1), (1, 0, 1), (1, 1, 0), (-1, 1, 1),
                                     (1, 1, 0x100000000), (True, 1, 1)])
def test_invalid_request_identity_never_encodes(identity):
    with pytest.raises(ValueError): st.encode_request(*identity, st.DEFAULTS)


@pytest.mark.parametrize("word,value", [(0, 0), (1, 2), (2, 0), (4, 9), (5, 0), (9, 0),
                                      (10, 0), (11, 0), (12, 1), (13, 1), (14, 1), (15, 1)])
def test_reject_bad_schema_identity_reserved_and_schedule(word, value):
    payload = bytearray(status()); struct.pack_into("!I", payload, st.OFFSET+word*4, value)
    assert st.decode_readback(payload, packet_boot=19) is None


def test_incomplete_status_boot_mismatch_and_invalid_wire_value_reject():
    assert st.decode_readback(status()[:-1]) is None
    assert st.decode_readback(status(), packet_boot=20) is None
    assert st.decode_readback(status(values=(5, float("nan")))) is None


@pytest.mark.parametrize("ack", [1, 7])
def test_only_matching_ack_revision_and_exact_echo_confirm(ack):
    state = accepted(); state.begin((4, 2.5), 77, 1_010_000_000)
    state.accept_status(status(request=76, ack=ack), 1_020_000_000, 19, 2)
    assert state.pending
    state.accept_status(status(revision=2, request=77, ack=ack, values=(4, 2.5)), 1_030_000_000, 19, 3)
    assert not state.pending and "已应用并回读一致" in state.message


def test_different_echo_other_client_and_timeout_never_retry():
    state = accepted(); state.begin((3.5, 2.5), 77, 1_010_000_000)
    state.accept_status(status(revision=2, request=77, ack=1), 1_020_000_000, 19, 2)
    assert not state.pending and "不同" in state.message
    state.begin(st.DEFAULTS, 78, 1_030_000_000)
    state.accept_status(status(revision=3, request=79, ack=1), 1_040_000_000, 19, 3)
    assert not state.pending and "其他请求" in state.message
    state.begin(st.DEFAULTS, 80, 1_050_000_000)
    state.accept_status(status(revision=3), 3_100_000_000, 19, 4)
    assert "未自动重发" in state.snapshot(3_110_000_000)["message"]
    assert state.read_current(3_110_000_000) == st.DEFAULTS and not state.pending


@pytest.mark.parametrize("ack", [2, 3, 4, 5, 6, 8])
def test_board_rejection_is_explained(ack):
    state = accepted(); state.begin(st.DEFAULTS, 77, 1_010_000_000)
    state.accept_status(status(request=77, ack=ack), 1_020_000_000, 19, 2)
    assert not state.pending and "板端拒绝" in state.message


def test_order_reboot_duplicate_and_stale_values_cannot_drive_write():
    state = accepted(); state.begin(st.DEFAULTS, 77, 1_010_000_000)
    assert not state.accept_status(status(), 1_900_000_000, 19, 1)
    assert not state.accept_status(status(values=(4, 3)), 1_100_000_000, 19, 2)
    assert not state.ready(2_000_000_001)
    assert state.accept_status(status(boot=20), 2_100_000_000, 20, 0xffffffff)
    assert not state.pending and "重新启动" in state.message
    assert not state.accept_status(status(), 2_200_000_000, 19, 99)
    assert state.accept_status(status(boot=20), 2_200_000_000, 20, 0)
    state.accept_status(status(boot=20, revision=4), 2_300_000_000, 20, 1)
    assert not state.accept_status(status(boot=20, revision=3), 2_400_000_000, 20, 2)
    assert state.current.revision == 4


def test_old_firmware_incompatibility_and_time_anomaly_block_write():
    for now in (999_999_999, 2_000_000_001):
        with pytest.raises(RuntimeError): accepted().begin(st.DEFAULTS, 77, now)
    state = accepted(); state.accept_status(status(), 1_100_000_000, 19, 2, compatible=False)
    with pytest.raises(RuntimeError): state.begin(st.DEFAULTS, 77, 1_100_000_001)
    state.accept_status(status()[:968], 1_200_000_000, 19, 3)
    assert not state.ready(1_200_000_001) and "未提供" in state.message


class FakeSocket:
    def __init__(self): self.sent = []; self.fail = False
    def sendto(self, data, address):
        if self.fail: raise OSError("offline")
        self.sent.append((data, address))


def receiver(monkeypatch):
    monkeypatch.setattr(time, "monotonic_ns", lambda: 1_000_000_000)
    service = ReceiverService(port_types={}); service._control_socket = FakeSocket()
    service._accept_status(status(), 1_000_000_000, 19, 1)
    return service, service._control_socket


def test_receiver_only_explicit_atomic_write_and_independent_ordered_echo(monkeypatch):
    service, sock = receiver(monkeypatch)
    assert sock.sent == [] and service.snapshots()[1]["scan_preview_tuning"]["ready"]
    service.send_scan_preview_tuning((4, 2.5))
    packet = parse_datagram(sock.sent[0][0]); assert packet.header.packet_type == PacketType.CONTROL
    command, length, _ = struct.unpack_from("!HHI", packet.payload)
    assert (command, length) == (25, 21) and sock.sent[0][1] == ("192.168.7.20", 15004)
    schema, boot, revision, request, *wire = struct.unpack("!BIII2f", packet.payload[8:])
    assert (schema, boot, revision, wire) == (1, 19, 1, [4., 2.5])
    assert not service.snapshots()[1]["audio_tuning"]["pending"]
    assert not service.snapshots()[1]["visual_tuning"]["pending"]
    service._accept_status(status(revision=2, request=request, ack=1, values=(4, 2.5)), 1_000_000_000, 19, 2)
    view = service.snapshots()[1]["scan_preview_tuning"]
    assert not view["pending"] and "回读一致" in view["message"]
    assert service.read_scan_preview_tuning() == (4, 2.5)
    service.resync_scan_preview_tuning()
    assert not service.snapshots()[1]["scan_preview_tuning"]["ready"] and len(sock.sent) == 1


def test_receiver_no_port_bad_value_incompatible_and_socket_error(monkeypatch):
    service = ReceiverService(port_types={})
    for method in (lambda: service.send_scan_preview_tuning(st.DEFAULTS),
                   service.read_scan_preview_tuning, service.resync_scan_preview_tuning):
        with pytest.raises(RuntimeError): method()
    service, sock = receiver(monkeypatch)
    with pytest.raises(ValueError): service.send_scan_preview_tuning((5, 5))
    service._accept_status(status(compatible=False), 1_000_000_000, 19, 2)
    with pytest.raises(RuntimeError): service.send_scan_preview_tuning(st.DEFAULTS)
    assert not sock.sent
    service._accept_status(status(), 1_000_000_000, 19, 3); sock.fail = True
    with pytest.raises(OSError): service.send_scan_preview_tuning(st.DEFAULTS)
    assert "结果未知" in service.snapshots()[1]["scan_preview_tuning"]["message"]


class FakeVar:
    def __init__(self, value): self.value = value
    def get(self): return self.value
    def set(self, value): self.value = value
    def trace_add(self, *args): pass


class FakeWidget:
    def __init__(self, *args, **kwargs): self.attrs = dict(kwargs); self.destroyed = False
    def configure(self, **kwargs): self.attrs.update(kwargs)
    def grid(self, *args, **kwargs): pass
    def pack(self, *args, **kwargs): pass
    def destroy(self): self.destroyed = True
    def title(self, *args): pass
    def protocol(self, *args): pass
    def lift(self): pass


def panel(monkeypatch):
    import av_monitor.scan_preview_tuning_panel as module
    monkeypatch.setattr(module.tk, "StringVar", lambda value: FakeVar(value))
    for name in ("Frame", "Label", "Entry", "Button"):
        monkeypatch.setattr(module.ttk, name, FakeWidget)
    service = SimpleNamespace(sent=[], read=st.DEFAULTS, resynced=[])
    service.send_scan_preview_tuning = lambda values: service.sent.append(values)
    service.read_scan_preview_tuning = lambda: service.read
    service.resync_scan_preview_tuning = lambda: service.resynced.append(True)
    return ScanPreviewTuningPanel(FakeWidget(), service), service


def panel_telemetry(values=st.DEFAULTS, revision=1, boot=19, ready=True, pending=False):
    return {"scan_preview_tuning": {"ready": ready, "control_open": True, "values": st.canonical_values(values),
                                  "boot_id": boot, "revision": revision, "apply_count": revision-1,
                                  "pending": pending, "message": "板端当前值", "scan_step_us": 1,
                                  "scan_interval_us": 25_000, "preview_interval_us": 400_000},
            "received_fps": 2.6, "video_assembly_loss": 7}


def test_panel_open_edit_read_default_resync_never_write_and_preserve_draft(monkeypatch):
    view, service = panel(monkeypatch)
    assert not service.sent and view.apply_button.attrs["state"] == "disabled"
    view.update(panel_telemetry()); view.variables[0].set("3.5"); view._draft_changed()
    view.update(panel_telemetry((6, 2), boot=20))
    assert view.variables[0].get() == "3.5" and "6°/s" in view.actual.attrs["text"]
    assert "未应用" in view.status.attrs["text"] and "2.6 FPS" in view.feedback.attrs["text"]
    view._defaults(); view._read(); view._resync()
    assert not service.sent and service.resynced == [True] and view._values() == st.DEFAULTS


def test_panel_only_apply_sends_and_invalid_stale_pending_states_block(monkeypatch):
    view, service = panel(monkeypatch); view.update(panel_telemetry())
    view.variables[0].set("4.5"); view.variables[1].set("2.5"); view._draft_changed()
    view.update(panel_telemetry()); assert view.apply_button.attrs["state"] == "normal"
    view._apply(); assert service.sent == [(4.5, 2.5)]
    view.variables[1].set("5"); view._apply()
    assert len(service.sent) == 1 and "范围" in view._local_error
    view.update(panel_telemetry(pending=True)); assert view.apply_button.attrs["state"] == "disabled"
    view.update(panel_telemetry(ready=False))
    assert view.apply_button.attrs["state"] == view.fields[0].attrs["state"] == "disabled"
    assert view.resync_button.attrs["state"] == "normal"


def test_modeless_window_reuse_open_and_close_never_enable_motion(monkeypatch):
    import av_monitor.ui as module
    view, service = panel(monkeypatch); windows = []
    def create(*args):
        window = FakeWidget(); windows.append(window); return window
    monkeypatch.setattr(module.tk, "Toplevel", create)
    monkeypatch.setattr(module, "ScanPreviewTuningPanel", lambda parent, receiver: view)
    monitor = MonitorWindow.__new__(MonitorWindow)
    monitor.root = object(); monitor.receiver = service
    monitor._scan_preview_tuning_window = monitor._scan_preview_tuning_panel = None
    monitor._last_telemetry = panel_telemetry()
    monitor._open_scan_preview_tuning(); monitor._open_scan_preview_tuning()
    assert len(windows) == 1 and not service.sent
    monitor._close_scan_preview_tuning()
    assert windows[0].destroyed and not service.sent
