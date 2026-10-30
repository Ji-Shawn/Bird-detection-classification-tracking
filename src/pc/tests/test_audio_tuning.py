"""Offline audio tuning tests: no hardware, real sockets or monitor is opened."""
from types import SimpleNamespace
import struct
import time

import pytest

from av_monitor import audio_tuning as at
from av_monitor import visual_tuning as vt
from av_monitor.audio_tuning_panel import AudioTuningPanel
from av_monitor.network import ReceiverService
from av_monitor.protocol import PacketType, parse_datagram
from av_monitor.ui import MonitorWindow


def status(boot=19, revision=1, request=0, ack=0, values=at.DEFAULTS,
           *, compatible=True, visual_revision=1):
    payload = bytearray(at.STATUS_BYTES)
    struct.pack_into("!11IHH", payload, 0, 1, 0x1000a, 43, boot, 100, 7, 0, 0, 0, 0, 0, 70, 0)
    struct.pack_into("!10I", payload, 256, 0x53525631, int(compatible), 0, 0, 1140, 0, 0, 0, 1, 0)
    struct.pack_into("!12I", payload, 792, 0x53525638, 1, 1, 1440, 1440, 540, 2480, 180000, 0, 10, 100, 2)
    struct.pack_into("!6I8f2I", payload, 840, vt.MAGIC, 1, visual_revision, 0, 0, boot,
                     *vt.DEFAULTS, 0, 0)
    struct.pack_into("!6I8f2I", payload, at.OFFSET, at.MAGIC, 1, revision, request, ack, boot,
                     *values, revision-1, 0)
    return bytes(payload)


def accepted():
    state = at.TuningState()
    assert state.accept_status(status(), 1_000_000_000, 19, 1)
    return state


def test_m45_screenshot_defaults_match_float32_wire():
    assert at.DEFAULTS == (80., 4., 1024., 12., 300., 600., 15., 100.)
    wire = at.encode_request(19, 3, 77, at.DEFAULTS)
    assert len(wire) == 45 and at.COMMAND == 24
    assert b"\x18"+wire == struct.pack("!BBIII8f", 24, 1, 19, 3, 77, *at.DEFAULTS)
    assert at.decode_readback(status(), packet_boot=19).values == at.canonical_values(at.DEFAULTS)
    assert at.display_values(at.canonical_values(at.DEFAULTS)) == ("80","4","1024","12","300","600","15","100")


@pytest.mark.parametrize("values", [
    (1., 2., 513., 2., 300., 600., 3., 5.),
    (99., 16., 16384., 30., 1500., 1500., 45., 120.),
    (71., 4.1234567, 1100., 9.456789, 700., 1200., 16.34567, 90.23456)])
def test_all_bounds_and_display_float32_roundtrip(values):
    canonical = at.canonical_values(values)
    assert at.value_bytes(at.draft_values(at.display_values(canonical))) == at.value_bytes(canonical)
    assert at.decode_readback(status(values=values)).values == canonical


@pytest.mark.parametrize("index,value", [
    (0,0),(0,100),(0,70.5),(1,1.99),(1,16.01),(2,512),(2,16385),(2,1024.5),
    (3,1.9),(3,30.1),(4,299),(4,1501),(4,600.1),(5,599),(5,1501),(5,1000.1),
    (6,2.9),(6,45.1),(7,4.9),(7,120.1),(0,True),(1,"4"),(3,float("nan")),(7,float("inf"))])
def test_invalid_group_never_encodes(index, value):
    values = list(at.DEFAULTS); values[index] = value
    with pytest.raises(ValueError): at.encode_request(19, 1, 9, values)


def test_reaim_cannot_precede_acquisition_and_wrong_field_count_rejects():
    values = list(at.DEFAULTS); values[4] = 1100
    with pytest.raises(ValueError, match="重定向"): at.canonical_values(values)
    for values in (at.DEFAULTS[:7], (*at.DEFAULTS, 0)):
        with pytest.raises(ValueError): at.canonical_values(values)
    for value in ("NaN", "inf", "", "bird"):
        draft = list(at.display_values(at.DEFAULTS)); draft[0] = value
        with pytest.raises(ValueError): at.draft_values(draft)


@pytest.mark.parametrize("identity", [(0,1,1),(1,0,1),(1,1,0),(-1,1,1),(1,1,0x100000000),(True,1,1)])
def test_invalid_request_identity_never_encodes(identity):
    with pytest.raises(ValueError): at.encode_request(*identity, at.DEFAULTS)


def test_complete_extension_schema_boot_and_reserved_are_required():
    assert at.decode_readback(status()[:-1]) is None
    assert at.decode_readback(status(), packet_boot=20) is None
    for relative, value in ((0,0),(4,2),(8,0),(16,9),(20,0),(60,1)):
        payload = bytearray(status()); struct.pack_into("!I", payload, at.OFFSET+relative, value)
        assert at.decode_readback(payload, packet_boot=19) is None


@pytest.mark.parametrize("ack", [1,7])
def test_only_exact_ack_request_revision_and_values_confirm_success(ack):
    state = accepted(); values = list(at.DEFAULTS); values[1] = 5
    state.begin(values, 100, 1_010_000_000)
    state.accept_status(status(request=99, ack=ack), 1_020_000_000, 19, 2)
    assert state.pending
    state.accept_status(status(revision=2, request=100, ack=ack, values=values), 1_030_000_000, 19, 3)
    assert state.pending is None and "已应用并回读一致" in state.message


def test_mismatched_echo_does_not_claim_success_or_reapply():
    state = accepted(); values = list(at.DEFAULTS); values[7] = 90
    state.begin(values, 100, 1_010_000_000)
    state.accept_status(status(revision=2, request=100, ack=1), 1_020_000_000, 19, 2)
    assert state.pending is None and "不同" in state.message
    assert "已应用并回读一致" not in state.message


@pytest.mark.parametrize("ack", range(2,7))
def test_board_rejections_clear_pending_and_report_reason(ack):
    state = accepted(); state.begin(at.DEFAULTS, 100, 1_010_000_000)
    state.accept_status(status(request=100, ack=ack), 1_020_000_000, 19, 2)
    assert not state.pending and "板端拒绝" in state.message


def test_ordered_state_rejects_duplicate_old_sequence_old_revision_and_changed_same_revision():
    state = accepted(); values = list(at.DEFAULTS); values[0] = 71
    assert not state.accept_status(status(request=100, ack=1), 1_900_000_000, 19, 1)
    assert not state.accept_status(status(values=values), 1_100_000_000, 19, 2)
    assert state.received_ns == 1_000_000_000
    assert not state.ready(2_000_000_001)
    assert state.accept_status(status(revision=3), 2_100_000_000, 19, 5)
    assert not state.accept_status(status(revision=2), 2_200_000_000, 19, 6)
    assert not state.accept_status(status(revision=4), 2_200_000_000, 19, 4)
    assert state.current.revision == 3


def test_reboot_cancels_pending_old_boot_and_supports_sequence_wrap():
    state = accepted(); state.begin(at.DEFAULTS, 100, 1_010_000_000)
    assert state.accept_status(status(boot=20), 1_100_000_000, 20, 0xffffffff)
    assert not state.pending and "重新启动" in state.message
    assert not state.accept_status(status(revision=9), 1_200_000_000, 19, 99)
    assert state.accept_status(status(boot=20), 1_200_000_000, 20, 0)
    assert state.current.boot_id == 20


def test_expired_clock_rollback_unsupported_or_incompatible_status_blocks_write():
    state = accepted()
    for now in (999_999_999, 2_000_000_001):
        with pytest.raises(RuntimeError): state.begin(at.DEFAULTS, 100, now)
    state.accept_status(status(), 2_100_000_000, 19, 2, compatible=False)
    with pytest.raises(RuntimeError): state.begin(at.DEFAULTS, 100, 2_100_000_001)
    state.accept_status(status()[:904], 2_200_000_000, 19, 3)
    assert not state.snapshot(2_200_000_001)["ready"] and "未提供 M43" in state.message


def test_timeout_other_client_revision_and_manual_read_never_retry():
    state = accepted(); state.begin(at.DEFAULTS, 100, 1_010_000_000)
    with pytest.raises(RuntimeError): state.begin(at.DEFAULTS, 101, 1_020_000_000)
    state.accept_status(status(), 3_100_000_000, 19, 2)
    assert "未自动重发" in state.snapshot(3_110_000_000)["message"]
    assert state.read_current(3_110_000_000) == at.canonical_values(at.DEFAULTS)
    assert not state.pending
    state.begin(at.DEFAULTS, 101, 3_120_000_000)
    state.accept_status(status(revision=2, request=999, ack=1), 3_130_000_000, 19, 3)
    assert not state.pending and "其他请求" in state.message


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


def test_receiver_sends_only_explicit_atomic_audio_write_and_verifies_independent_echo(monkeypatch):
    service, sock = receiver(monkeypatch)
    assert sock.sent == [] and service.snapshots()[1]["audio_tuning"]["ready"]
    values = list(at.DEFAULTS); values[0] = 72
    service.send_audio_tuning(values)
    assert len(sock.sent) == 1
    packet = parse_datagram(sock.sent[0][0])
    assert packet.header.packet_type == PacketType.CONTROL
    command, length, _ = struct.unpack_from("!HHI", packet.payload)
    assert (command, length) == (24,45) and sock.sent[0][1] == ("192.168.7.20",15004)
    schema, boot, revision, request, *wire = struct.unpack("!BIII8f", packet.payload[8:])
    assert (schema, boot, revision) == (1,19,1) and wire[0] == 72
    assert service.snapshots()[1]["audio_tuning"]["pending"]
    assert not service.snapshots()[1]["visual_tuning"]["pending"]
    service._accept_status(status(revision=2, request=request, ack=1, values=values), 1_000_000_000, 19, 2)
    view = service.snapshots()[1]["audio_tuning"]
    assert not view["pending"] and "回读一致" in view["message"]
    assert service.read_audio_tuning()[0] == 72 and len(sock.sent) == 1


def test_receiver_missing_port_invalid_group_incompatible_and_send_error(monkeypatch):
    service = ReceiverService(port_types={})
    for method in (lambda:service.send_audio_tuning(at.DEFAULTS), service.read_audio_tuning, service.resync_audio_tuning):
        with pytest.raises(RuntimeError): method()
    service, sock = receiver(monkeypatch)
    values = list(at.DEFAULTS); values[0] = 70.5
    with pytest.raises(ValueError): service.send_audio_tuning(values)
    assert sock.sent == []
    service._accept_status(status(compatible=False), 1_000_000_000, 19, 2)
    with pytest.raises(RuntimeError): service.send_audio_tuning(at.DEFAULTS)
    service._accept_status(status(), 1_000_000_000, 19, 3)
    sock.fail = True
    with pytest.raises(OSError): service.send_audio_tuning(at.DEFAULTS)
    assert "结果未知" in service.snapshots()[1]["audio_tuning"]["message"]
    assert sock.sent == []


def test_ordered_audio_feedback_and_readonly_resync_never_send(monkeypatch):
    service, sock = receiver(monkeypatch)
    newest = bytearray(status()); struct.pack_into("!I", newest, 804, 1600)
    struct.pack_into("!I", newest, 820, 212000)
    struct.pack_into("!I", newest, 268, 32000)
    service._accept_status(newest, 1_000_000_000, 19, 3)
    service._accept_status(status(), 1_000_000_000, 19, 2)
    telemetry = service.snapshots()[1]
    assert telemetry["audio_tuning_feedback"]["servo_pan_us"] == 1600
    assert "1600 μs" in at.feedback_text(telemetry["audio_tuning_feedback"], telemetry["audio_tuning"])
    service.resync_audio_tuning()
    telemetry = service.snapshots()[1]
    assert not telemetry["audio_tuning"]["ready"]
    assert telemetry["audio_tuning_feedback"]["telemetry_age_s"] == float("inf") and sock.sent == []


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
    def add(self, *args, **kwargs): pass
    def destroy(self): self.destroyed = True
    def title(self, *args): pass
    def protocol(self, *args): pass
    def lift(self): pass


def panel(monkeypatch):
    import av_monitor.audio_tuning_panel as module
    monkeypatch.setattr(module.tk, "StringVar", lambda value: FakeVar(value))
    for name in ("Frame", "Label", "Entry", "Spinbox", "Button", "Notebook"):
        monkeypatch.setattr(module.ttk, name, FakeWidget)
    service = SimpleNamespace(sent=[], read=at.canonical_values(at.DEFAULTS), resynced=[])
    service.send_audio_tuning = lambda values: service.sent.append(values)
    service.read_audio_tuning = lambda: service.read
    service.resync_audio_tuning = lambda: service.resynced.append(True)
    return AudioTuningPanel(FakeWidget(), service), service


def panel_telemetry(values=at.DEFAULTS, revision=1, boot=19, ready=True, pending=False):
    return {"audio_tuning":{"ready":ready,"control_open":True,"values":at.canonical_values(values),
                             "boot_id":boot,"revision":revision,"apply_count":revision-1,
                             "pending":pending,"message":"板端当前值"}}


def test_panel_open_edit_default_read_resync_never_write_and_preserve_dirty_draft(monkeypatch):
    view, service = panel(monkeypatch)
    assert service.sent == [] and view.apply_button.attrs["state"] == "disabled"
    view.update(panel_telemetry())
    view.variables[0].set("72"); view._draft_changed()
    values = list(at.DEFAULTS); values[0] = 75
    view.update(panel_telemetry(values, boot=20))
    assert view.variables[0].get() == "72" and ">75%" in view.actual.attrs["text"]
    assert "未应用" in view.status.attrs["text"]
    view._defaults(); view._read(); view._resync()
    assert service.sent == [] and service.resynced == [True]
    assert view._values() == at.canonical_values(at.DEFAULTS)


def test_panel_only_explicit_apply_sends_complete_group_and_rejects_invalid_input(monkeypatch):
    view, service = panel(monkeypatch); view.update(panel_telemetry())
    view.variables[0].set("72"); view._draft_changed(); view.update(panel_telemetry())
    assert view.apply_button.attrs["state"] == "normal"
    view._apply()
    assert service.sent == [(72., *at.canonical_values(at.DEFAULTS)[1:])]
    view.variables[4].set("1100"); view._apply()
    assert len(service.sent) == 1 and "重定向" in view._local_error
    view.update(panel_telemetry(pending=True))
    assert view.apply_button.attrs["state"] == "disabled"
    view.update(panel_telemetry(ready=False))
    assert view.apply_button.attrs["state"] == view.fields[0].attrs["state"] == "disabled"
    assert view.resync_button.attrs["state"] == "normal"


def test_audio_window_is_modeless_reuses_window_and_never_starts_tracking(monkeypatch):
    import av_monitor.ui as module
    view, service = panel(monkeypatch); windows = []
    def create(*args):
        window = FakeWidget(); windows.append(window); return window
    monkeypatch.setattr(module.tk, "Toplevel", create)
    monkeypatch.setattr(module, "AudioTuningPanel", lambda parent, receiver: view)
    monitor = MonitorWindow.__new__(MonitorWindow)
    monitor.root = object(); monitor.receiver = service
    monitor._audio_tuning_window = None; monitor._audio_tuning_panel = None
    monitor._last_telemetry = panel_telemetry()
    monitor._open_audio_tuning(); monitor._open_audio_tuning()
    assert len(windows) == 1 and service.sent == []
    monitor._close_audio_tuning()
    assert windows[0].destroyed and service.sent == []


def test_feedback_distinguishes_instruction_from_actual_motion_and_checks_fresh_session():
    tuning = panel_telemetry()["audio_tuning"]
    telemetry = dict(boot_id=19, telemetry_age_s=0, servo_pan_us=1440, servo_tilt_us=1140,
                     sound_tracking_state=7, sound_tracking_angle_deg=-45,
                     mic_rms=(.001,.002,.003,.004), direction_bird_confidence=.8)
    text = at.feedback_text(telemetry, tuning)
    assert "指令 -45.0°" in text and "无编码器" in text and "RMS" in text and "80.0%" in text
    telemetry["telemetry_age_s"] = 1.01
    assert "等待同一启动会话" in at.feedback_text(telemetry, tuning)


def test_direction_display_uses_existing_gate_validity_and_does_not_send(monkeypatch):
    view, service = panel(monkeypatch)
    direction = SimpleNamespace(angle_deg=-25., confidence=.5, age_ms=28, valid=True)
    view.update_direction(direction, True, "")
    assert "基座方位 -25.0°" in view.direction.attrs["text"]
    assert "16384 Q15" in view.direction.attrs["text"] and "28 ms" in view.direction.attrs["text"]
    view.update_direction(direction, False, "视觉接管追踪")
    assert "视觉接管追踪" in view.direction.attrs["text"] and "基座方位" not in view.direction.attrs["text"]
    assert service.sent == []
