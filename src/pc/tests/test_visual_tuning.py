"""Offline behavior tests; no Tk window, device, or live network is opened."""
from types import SimpleNamespace
import struct
import time

import pytest

from av_monitor.network import ReceiverService
from av_monitor.protocol import PacketType, parse_datagram
from av_monitor import visual_tuning as vt
from av_monitor.visual_tuning_panel import VisualTuningPanel
from av_monitor.ui import MonitorWindow


def status(boot=19, revision=1, request=0, ack=0, values=vt.DEFAULTS,
           *, compatible=True, auto=1):
    payload=bytearray(vt.STATUS_BYTES)
    struct.pack_into("!11IHH",payload,0,1,0x1000a,39,boot,100,7,0,0,0,0,0,70,0)
    struct.pack_into("!10I",payload,256,0x53525631,int(compatible),auto,0,1140,0,0,0,1,0)
    struct.pack_into("!12I",payload,792,0x53525638,1,1,1440,1440,540,2480,180000,0,10,100,2)
    struct.pack_into("!6I8f2I",payload,840,vt.MAGIC,1,revision,request,ack,boot,
                     *values,revision-1,0)
    return bytes(payload)


def accepted(state=None, now=1_000_000_000):
    state=state or vt.TuningState()
    assert state.accept_status(status(),now,19,1)
    return state


def test_wire_layout_and_float32_deadband_endpoints():
    values=(1.,240.,1.,60.,.005,.01,.15,.20)
    wire=vt.encode_request(19,3,77,values)
    assert len(wire)==45
    assert struct.unpack_from("!BIII",wire)==(1,19,3,77)
    assert wire[13:]==struct.pack("!8f",*values)
    read=vt.decode_readback(status(values=values),packet_boot=19)
    assert read.values==vt.canonical_values(values)
    assert vt.display_values(read.values)==("1","240","1","60","0.5","1","15","20")


def test_display_roundtrips_arbitrary_board_float32_without_false_dirty_fields():
    values=vt.canonical_values((91.123456,62.345678,21.234567,16.876543,
                                .02345678,.03987654,.04345678,.05987654))
    assert vt.value_bytes(vt.draft_values(vt.display_values(values)))==vt.value_bytes(values)


@pytest.mark.parametrize("identity",[(0,1,1),(1,0,1),(1,1,0),(-1,1,1),(1,1,0x100000000)])
def test_zero_or_invalid_request_session_identity_never_encodes(identity):
    with pytest.raises(ValueError):vt.encode_request(*identity,vt.DEFAULTS)


@pytest.mark.parametrize("index,value",[(0,float("nan")),(1,float("inf")),(0,0),
    (1,241),(2,0),(3,61),(4,.004),(5,.201),(6,.151),(7,.009),(0,True),(0,"80")])
def test_rejects_whole_configuration_before_encoding(index,value):
    values=list(vt.DEFAULTS);values[index]=value
    with pytest.raises(ValueError):vt.encode_request(1,1,9,values)


@pytest.mark.parametrize("values",[(80,60,20,15,.04,.035,.04,.05),
                                  (80,60,20,15,.025,.035,.05,.05)])
def test_hysteresis_must_have_positive_width(values):
    with pytest.raises(ValueError):vt.canonical_values(values)


@pytest.mark.parametrize("text",["NaN","inf","-inf","","bird"])
def test_draft_validation_accepts_percent_units_and_rejects_invalid_numbers(text):
    draft=list(vt.display_values(vt.DEFAULTS))
    assert vt.draft_values(draft)==vt.canonical_values(vt.DEFAULTS)
    draft[4]=text
    with pytest.raises(ValueError):vt.draft_values(draft)


def test_telemetry_requires_complete_valid_extension_and_matching_boot():
    assert vt.decode_readback(status()[:-1]) is None
    assert vt.decode_readback(status(boot=0),packet_boot=0) is None
    assert vt.decode_readback(status(),packet_boot=20) is None
    for offset,value in ((840,0),(844,2),(848,0),(856,9),(900,1)):
        payload=bytearray(status());struct.pack_into("!I",payload,offset,value)
        assert vt.decode_readback(payload,packet_boot=19) is None


def test_ack_requires_request_revision_and_exact_configuration():
    state=accepted();values=list(vt.DEFAULTS);values[0]=90
    state.begin(values,100,1_010_000_000)
    state.accept_status(status(request=99,ack=1),1_020_000_000,19,2)
    assert state.pending
    state.accept_status(status(revision=2,request=100,ack=1,values=values),1_030_000_000,19,3)
    assert not state.pending and "已应用并回读一致" in state.message
    assert state.current.values[0]==90


def test_success_ack_with_different_actual_parameters_is_not_false_success():
    state=accepted();values=list(vt.DEFAULTS);values[0]=90
    state.begin(values,100,1_010_000_000)
    state.accept_status(status(revision=2,request=100,ack=1),1_020_000_000,19,2)
    assert "已应用并回读一致" not in state.message and "不同" in state.message


def test_exact_duplicate_applied_ack_can_confirm_without_reapplying():
    state=accepted();values=list(vt.DEFAULTS);values[2]=22
    state.begin(values,100,1_010_000_000)
    state.accept_status(status(revision=2,request=100,ack=7,values=values),1_020_000_000,19,2)
    assert not state.pending and "已应用并回读一致" in state.message


@pytest.mark.parametrize("ack",range(2,7))
def test_explicit_board_rejections_are_reported(ack):
    state=accepted();state.begin(vt.DEFAULTS,100,1_010_000_000)
    state.accept_status(status(request=100,ack=ack),1_020_000_000,19,2)
    assert state.pending is None and "拒绝" in state.message


def test_unsupported_hardware_ack_and_flag_disable_application():
    state=accepted();state.begin(vt.DEFAULTS,100,1_010_000_000)
    state.accept_status(status(request=100,ack=8),1_020_000_000,19,2,compatible=False)
    assert state.pending is None and "拒绝" in state.message
    assert not state.ready(1_020_000_001)
    with pytest.raises(RuntimeError):state.begin(vt.DEFAULTS,101,1_020_000_001)


def test_status_order_revision_and_packet_boot_cannot_rewind_readback():
    state=accepted()
    state.accept_status(status(revision=3),1_100_000_000,19,5)
    for payload,sequence in ((status(revision=2),4),(status(revision=2),6),
                             (status(revision=4),5)):
        assert not state.accept_status(payload,1_200_000_000,19,sequence)
    assert not state.accept_status(status(boot=20),1_200_000_000,19,6)
    assert state.current.revision==3 and state.received_ns==1_100_000_000


def test_repeated_status_does_not_refresh_freshness_or_confirm_pending():
    state=accepted();state.begin(vt.DEFAULTS,100,1_010_000_000)
    assert not state.accept_status(status(request=100,ack=1),1_900_000_000,19,1)
    assert state.pending and not state.ready(2_000_000_001)


def test_same_revision_cannot_change_parameter_values():
    state=accepted();values=list(vt.DEFAULTS);values[0]=81
    assert not state.accept_status(status(values=values),1_100_000_000,19,2)
    assert state.current.values[0]==vt.DEFAULTS[0] and state.received_ns==1_000_000_000


def test_sequence_wrap_is_supported_but_old_sequence_is_not():
    state=vt.TuningState()
    state.accept_status(status(),1_000_000_000,19,0xffffffff)
    assert state.accept_status(status(),1_100_000_000,19,0)
    assert not state.accept_status(status(),1_200_000_000,19,0xffffffff)


def test_reboot_cancels_old_pending_and_retires_previous_boot():
    state=accepted();state.begin(vt.DEFAULTS,100,1_010_000_000)
    assert state.accept_status(status(boot=20),1_100_000_000,20,1)
    assert state.pending is None and state.current.boot_id==20
    assert "重新启动" in state.message
    assert not state.accept_status(status(revision=9),1_200_000_000,19,99)
    assert state.current.revision==1 and state.current.boot_id==20


def test_expired_or_clock_rollback_status_never_starts_write():
    state=accepted()
    for now in (999_999_999,2_000_000_001):
        with pytest.raises(RuntimeError):state.begin(vt.DEFAULTS,100,now)
    assert state.pending is None


def test_old_firmware_invalidates_writable_capability():
    state=accepted()
    state.accept_status(status()[:840],1_100_000_000,19,2)
    assert not state.snapshot(1_100_000_001)["ready"]
    assert "未提供" in state.message


def test_timeout_is_unknown_not_failure_and_manual_read_reconciles():
    state=accepted();state.begin(vt.DEFAULTS,100,1_010_000_000)
    state.accept_status(status(),3_100_000_000,19,2)
    view=state.snapshot(3_110_000_000)
    assert view["pending"] and "结果未知" in view["message"] and "未自动重发" in view["message"]
    assert state.read_current(3_110_000_000)==vt.canonical_values(vt.DEFAULTS)
    assert not state.pending
    state.begin(vt.DEFAULTS,101,3_120_000_000)


def test_pending_and_other_client_revision_do_not_trigger_resend():
    state=accepted();state.begin(vt.DEFAULTS,100,1_010_000_000)
    with pytest.raises(RuntimeError):state.begin(vt.DEFAULTS,101,1_020_000_000)
    state.accept_status(status(revision=2,request=999,ack=1),1_030_000_000,19,2)
    assert "其他请求" in state.message and "未知" in state.message
    assert state.pending is None


class FakeSocket:
    def __init__(self):self.sent=[];self.fail=False
    def sendto(self,data,address):
        if self.fail:raise OSError("offline")
        self.sent.append((data,address))


def test_receiver_atomic_manual_send_and_echo_without_live_socket(monkeypatch):
    now=1_000_000_000
    monkeypatch.setattr(time,"monotonic_ns",lambda:now)
    service=ReceiverService(port_types={});sock=FakeSocket();service._control_socket=sock
    service._accept_status(status(),now,19,1)
    assert sock.sent==[] and service.snapshots()[1]["visual_tuning"]["ready"]
    values=list(vt.DEFAULTS);values[0]=100
    service.send_visual_tuning(values)
    assert len(sock.sent)==1
    packet=parse_datagram(sock.sent[0][0])
    assert packet.header.packet_type==PacketType.CONTROL
    command,length,sequence=struct.unpack_from("!HHI",packet.payload)
    assert (command,length)==(23,45) and sock.sent[0][1]==("192.168.7.20",15004)
    schema,boot,revision,request,*wire=struct.unpack("!BIII8f",packet.payload[8:])
    assert (schema,boot,revision)==(1,19,1) and wire[0]==100
    # Generic transport replies cannot be mistaken for applied parameter echo.
    assert service.snapshots()[1]["visual_tuning"]["pending"]
    service._accept_status(status(revision=2,request=request,ack=1,values=values),now,19,2)
    view=service.snapshots()[1]["visual_tuning"]
    assert not view["pending"] and "已应用并回读一致" in view["message"]
    assert service.read_visual_tuning()[0]==100 and len(sock.sent)==1


def test_receiver_invalid_values_no_port_or_unsupported_hardware_never_send(monkeypatch):
    monkeypatch.setattr(time,"monotonic_ns",lambda:1_000_000_000)
    service=ReceiverService(port_types={})
    with pytest.raises(RuntimeError):service.send_visual_tuning(vt.DEFAULTS)
    sock=FakeSocket();service._control_socket=sock
    service._accept_status(status(),1_000_000_000,19,1)
    values=list(vt.DEFAULTS);values[5]=values[4]
    with pytest.raises(ValueError):service.send_visual_tuning(values)
    service._accept_status(status(compatible=False),1_000_000_000,19,2)
    assert not service.snapshots()[1]["visual_tuning"]["ready"]
    with pytest.raises(RuntimeError):service.send_visual_tuning(vt.DEFAULTS)
    assert sock.sent==[]


def test_socket_error_does_not_claim_success_or_retry(monkeypatch):
    monkeypatch.setattr(time,"monotonic_ns",lambda:1_000_000_000)
    service=ReceiverService(port_types={});sock=FakeSocket();sock.fail=True
    service._control_socket=sock;service._accept_status(status(),1_000_000_000,19,1)
    with pytest.raises(OSError):service.send_visual_tuning(vt.DEFAULTS)
    view=service.snapshots()[1]["visual_tuning"]
    assert view["pending"] and "结果未知" in view["message"] and sock.sent==[]


def test_ordered_tuning_snapshot_does_not_follow_old_boot_visual_telemetry(monkeypatch):
    monkeypatch.setattr(time,"monotonic_ns",lambda:1_000_000_000)
    service=ReceiverService(port_types={});service._control_socket=FakeSocket()
    for boot,sequence in ((19,1),(20,1),(19,99)):
        service._accept_status(status(boot=boot),1_000_000_000,boot,sequence)
    view=service.snapshots()[1]["visual_tuning"]
    assert view["boot_id"]==20
    assert "等待同一启动会话" in vt.feedback_text(service.snapshots()[1],view)


def test_panel_feedback_keeps_accepted_pwm_and_original_age_after_rejected_status(monkeypatch):
    clock=[1_000_000_000]
    monkeypatch.setattr(time,"monotonic_ns",lambda:clock[0])
    service=ReceiverService(port_types={});service._control_socket=FakeSocket()
    newest=bytearray(status())
    struct.pack_into("!I",newest,268,32000)
    struct.pack_into("!I",newest,804,1600)
    struct.pack_into("!I",newest,820,212000)
    service._accept_status(newest,clock[0],19,2)
    clock[0]+=200_000_000
    service._accept_status(status(),clock[0],19,1)
    telemetry=service.snapshots()[1]
    # Preserve the established main presentation; only the new panel is ordered.
    assert telemetry["servo_pan_us"]==1440
    feedback=telemetry["visual_tuning_feedback"]
    assert feedback["servo_pan_us"]==1600 and feedback["telemetry_age_s"]==pytest.approx(.2)
    assert "1600 μs" in vt.feedback_text(feedback,telemetry["visual_tuning"])
    view,_=panel(monkeypatch);view.update(telemetry)
    assert "1600 μs" in view.feedback.attrs["text"]
    clock[0]+=100_000_000
    service._accept_status(status(),clock[0],19,2)
    assert service.snapshots()[1]["visual_tuning_feedback"]["telemetry_age_s"]==pytest.approx(.3)


def test_readonly_resync_recovers_unseen_old_boot_without_transmitting(monkeypatch):
    monkeypatch.setattr(time,"monotonic_ns",lambda:1_000_000_000)
    service=ReceiverService(port_types={});sock=FakeSocket();service._control_socket=sock
    for boot,sequence in ((20,1),(19,99),(20,2)):
        service._accept_status(status(boot=boot),1_000_000_000,boot,sequence)
    assert service.snapshots()[1]["visual_tuning"]["boot_id"]==19
    service._visual_tuning.begin(vt.DEFAULTS,100,1_000_000_000)
    service.resync_visual_tuning()
    pending_view=service.snapshots()[1]["visual_tuning"]
    assert not pending_view["pending"] and not pending_view["ready"]
    assert "结果未知" in pending_view["message"] and pending_view["control_open"]
    assert service.snapshots()[1]["visual_tuning_feedback"]["telemetry_age_s"]==float("inf")
    service._accept_status(status(boot=20),1_000_000_000,20,3)
    view=service.snapshots()[1]["visual_tuning"]
    assert view["boot_id"]==20 and view["ready"] and not view["pending"]
    assert sock.sent==[]


class FakeVar:
    def __init__(self,value):self.value=value
    def get(self):return self.value
    def set(self,value):self.value=value
    def trace_add(self,*args):pass


class FakeWidget:
    def __init__(self,*args,**kwargs):self.attrs=dict(kwargs);self.destroyed=False
    def configure(self,**kwargs):self.attrs.update(kwargs)
    def grid(self,*args,**kwargs):pass
    def pack(self,*args,**kwargs):pass
    def add(self,*args,**kwargs):pass
    def destroy(self):self.destroyed=True
    def title(self,*args):pass
    def protocol(self,*args):pass
    def lift(self):pass


def panel(monkeypatch):
    import av_monitor.visual_tuning_panel as module
    monkeypatch.setattr(module.tk,"StringVar",lambda value:FakeVar(value))
    for name in ("Frame","Label","Entry","Button","Notebook","Spinbox"):
        monkeypatch.setattr(module.ttk,name,FakeWidget)
    receiver=SimpleNamespace(sent=[],read=vt.canonical_values(vt.DEFAULTS),resynced=[])
    receiver.send_visual_tuning=lambda values:receiver.sent.append(values)
    receiver.read_visual_tuning=lambda:receiver.read
    receiver.resync_visual_tuning=lambda:receiver.resynced.append(True)
    return VisualTuningPanel(FakeWidget(),receiver),receiver


def panel_telemetry(values=vt.DEFAULTS,revision=1,boot=19,ready=True,pending=False):
    return {"boot_id":boot,"telemetry_age_s":0,"servo_estimated_pan":0,
            "servo_pan_us":1440,"servo_tilt_us":1140,
            "visual_tuning":{"ready":ready,"control_open":True,"values":vt.canonical_values(values),
                             "boot_id":boot,"revision":revision,"apply_count":revision-1,
                             "pending":pending,"message":"板端当前值"}}


def test_panel_creation_defaults_editing_and_refresh_never_send(monkeypatch):
    view,receiver=panel(monkeypatch)
    assert receiver.sent==[] and view.apply_button.attrs["state"]=="disabled"
    view.update(panel_telemetry())
    assert view._values()==vt.canonical_values(vt.DEFAULTS) and receiver.sent==[]
    view.variables[0].set("91");view._draft_changed()
    view.update(panel_telemetry(revision=2))
    assert view.variables[0].get()=="91" and receiver.sent==[]
    view._defaults()
    assert receiver.sent==[]


def test_panel_preserves_dirty_draft_on_reboot_and_shows_independent_actual(monkeypatch):
    view,receiver=panel(monkeypatch);view.update(panel_telemetry())
    view.variables[0].set("91");view._draft_changed()
    values=list(vt.DEFAULTS);values[0]=83
    view.update(panel_telemetry(values,boot=20))
    assert view.variables[0].get()=="91"
    assert "Kp 83" in view.actual.attrs["text"]
    assert "未应用" in view.status.attrs["text"] and receiver.sent==[]


def test_panel_only_explicit_apply_sends_complete_valid_group(monkeypatch):
    view,receiver=panel(monkeypatch);view.update(panel_telemetry())
    view.variables[0].set("91");view._draft_changed()
    view._apply()
    assert receiver.sent==[(91.,*vt.canonical_values(vt.DEFAULTS)[1:])]
    view.variables[7].set(view.variables[6].get());view._apply()
    assert len(receiver.sent)==1 and "死区" in view._local_error
    view._read()
    assert view._values()==vt.canonical_values(vt.DEFAULTS) and len(receiver.sent)==1


def test_panel_disables_application_while_pending_or_stale(monkeypatch):
    view,receiver=panel(monkeypatch);view.update(panel_telemetry())
    view.variables[0].set("90");view._draft_changed()
    view.update(panel_telemetry(pending=True))
    assert view.apply_button.attrs["state"]=="disabled"
    view.update(panel_telemetry(ready=False))
    assert view.apply_button.attrs["state"]==view.fields[0].attrs["state"]=="disabled"
    assert receiver.sent==[]


def test_panel_resync_is_available_when_unsupported_and_preserves_draft(monkeypatch):
    view,receiver=panel(monkeypatch)
    view.variables[0].set("93");view._draft_changed()
    view.update(panel_telemetry(ready=False))
    assert view.resync_button.attrs["state"]=="normal"
    view._resync()
    assert receiver.resynced==[True] and receiver.sent==[]
    assert view.variables[0].get()=="93"
    view.update({"visual_tuning":{"ready":False,"control_open":False}})
    assert view.resync_button.attrs["state"]=="disabled"


def test_modeless_open_close_does_not_start_tracking_or_send_commands(monkeypatch):
    import av_monitor.ui as module
    view,receiver=panel(monkeypatch)
    windows=[]
    def create(*args):
        window=FakeWidget();windows.append(window);return window
    monkeypatch.setattr(module.tk,"Toplevel",create)
    monkeypatch.setattr(module,"VisualTuningPanel",lambda parent,service:view)
    monitor=MonitorWindow.__new__(MonitorWindow)
    monitor.root=object();monitor.receiver=receiver
    monitor._visual_tuning_window=None;monitor._visual_tuning_panel=None
    monitor._last_telemetry=panel_telemetry()
    monitor._open_visual_tuning();monitor._open_visual_tuning()
    assert len(windows)==1 and receiver.sent==[]
    monitor._close_visual_tuning()
    assert windows[0].destroyed and receiver.sent==[]


def test_feedback_reports_command_estimate_and_only_fresh_formal_image_error():
    telemetry=panel_telemetry()
    telemetry.update(visual_tracker_active=True,visual_tracker_target_valid=True,
                     visual_tracker_box=[1040,500,1240,700],visual_tracker_frame_age_ms=34)
    text=vt.feedback_text(telemetry,telemetry["visual_tuning"])
    assert "无编码器" in text and "NCC 画面龄期 34 ms" in text
    assert "水平误差 +9.4%" in text and "竖直误差 +5.6%" in text
    telemetry["visual_tracker_frame_age_ms"]=501
    assert "SSD 单步找回仍沿用原流程" in vt.feedback_text(telemetry,telemetry["visual_tuning"])
    telemetry["visual_tracker_frame_age_ms"]=10
    telemetry["visual_tracker_state"]=2;telemetry["visual_tracker_misses"]=1
    assert "NCC 画面龄期" not in vt.feedback_text(telemetry,telemetry["visual_tuning"])

