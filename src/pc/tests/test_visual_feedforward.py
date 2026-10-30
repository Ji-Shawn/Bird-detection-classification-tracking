"""M47 wire/state/UI contracts; no monitor, live socket or board is opened."""
import importlib
import importlib.util
import struct
import time
from types import SimpleNamespace

import pytest

from av_monitor.network import ReceiverService
from av_monitor.protocol import parse_datagram


DEFAULTS = (0., 0., .3, .3, 5., 4., 120., 1.)


def ff():
    assert importlib.util.find_spec("av_monitor.visual_feedforward") is not None, "M47 independent feedforward support is missing"
    return importlib.import_module("av_monitor.visual_feedforward")


def status(boot=19, revision=1, request=0, ack=0, values=DEFAULTS, *,
           flags=0, compatible=True, age=0xffffffff, diagnostics=(0., 0., 0., 0.)):
    payload = bytearray(1384)
    struct.pack_into("!11IHH", payload, 0, 1, 0x1000a, 47, boot, 100, 7, 0, 0, 0, 0, 0, 70, 0)
    struct.pack_into("!10I", payload, 256, 0x53525631, int(compatible), 1, 0, 1140, 0, 0, 0, 1, 0)
    struct.pack_into("!12I", payload, 792, 0x53525638, 1, 1, 1440, 1440, 540, 2480, 180000, 0, 10, 100, 2)
    struct.pack_into("!6I8f2I", payload, 840, 0x53525639, 1, 1, 0, 0, boot,
                     105., 85., 20., 15., .04, .06, .025, .045, 0, 0)
    struct.pack_into("!6I8f2I4f4I4f4I", payload, 1256,
                     0x56464631, 1, revision, request, ack, boot, *values,
                     revision-1, flags, *diagnostics, age, 2, 2, 0,
                     2., -1., 3., -2., 37, 0, 0, 0)
    return bytes(payload)


def accepted():
    state = ff().TuningState()
    assert state.accept_status(status(), 1_000_000_000, 19, 1)
    return state


def test_wire_uses_independent_command_and_full_atomic_float32_group():
    module = ff()
    wire = module.encode_request(19, 3, 77, (90., 60., .25, .5, 7., 8., 80., 2.))
    assert module.COMMAND == 27 and len(wire) == 45
    assert wire == struct.pack("!BIII8f", 1, 19, 3, 77, 90., 60., .25, .5, 7., 8., 80., 2.)
    assert module.draft_values(("0", "0", ".3", ".3", "5", "4", "120", "1")) == module.canonical_values(DEFAULTS)
    assert module.display_values(module.canonical_values(DEFAULTS)) == ("0", "0", "0.3", "0.3", "5", "4", "120", "1")


@pytest.mark.parametrize("values", [(0.,0.,0.,0.,0.,0.,20.,0.), (360.,180.,1.,1.,60.,60.,1000.,10.)])
def test_inclusive_parameter_boundaries(values):
    assert len(ff().encode_request(19, 1, 7, values)) == 45


@pytest.mark.parametrize("index,value", [(0,-.01),(0,360.01),(1,180.01),(2,1.01),(3,-.1),
    (4,60.1),(5,-1),(6,19.9),(6,1000.1),(7,10.1),(0,float("nan")),(4,float("inf")),(0,True)])
def test_illegal_parameter_group_is_never_encoded(index, value):
    values = list(DEFAULTS); values[index] = value
    with pytest.raises(ValueError): ff().encode_request(19,1,7,values)


@pytest.mark.parametrize("identity", [(0,1,1),(1,0,1),(1,1,0),(True,1,1),(1,1,0x100000000)])
def test_invalid_identity_is_never_encoded(identity):
    with pytest.raises(ValueError): ff().encode_request(*identity,DEFAULTS)


@pytest.mark.parametrize("texts", [("0",)*7, ("nan",)*8, ("bird",)*8])
def test_bad_drafts_are_rejected(texts):
    with pytest.raises(ValueError): ff().draft_values(texts)


def test_float32_read_display_apply_roundtrip_keeps_exact_bits():
    module = ff(); values = (123.4567, 74.12345, .12345678, .87654321, 5.12345, 4.98765, 123.4567, 1.1234567)
    read = module.decode_readback(status(values=values), packet_boot=19)
    assert module.value_bytes(module.draft_values(module.display_values(read.values))) == struct.pack("!8f", *values)


def test_tiny_positive_float32_gain_survives_display_and_explicit_read_apply():
    module = ff(); values=(90.,60.,1e-30,1e-40,5.,4.,120.,1.)
    read=module.decode_readback(status(values=values))
    shown=module.display_values(read.values)
    assert module.value_bytes(module.draft_values(shown))==struct.pack("!8f",*values)


def test_readback_decodes_full_diagnostics_without_claiming_measurement():
    read = ff().decode_readback(status(flags=127, age=175, diagnostics=(12.,-9.,3.,-2.)),packet_boot=19)
    assert (read.flags,read.pan_velocity,read.tilt_velocity,read.pan_ff,read.tilt_ff) == (127,12.,-9.,3.,-2.)
    assert (read.observation_age_ms,read.pan_pairs,read.tilt_pairs,read.reset_reason) == (175,2,2,0)
    assert (read.pan_p_rate,read.tilt_p_rate,read.pan_total_rate,read.tilt_total_rate,read.source_sequence) == (2.,-1.,3.,-2.,37)


@pytest.mark.parametrize("size", [48,840,904,1256,1383])
def test_old_or_short_status_cannot_enable_feedforward(size):
    assert ff().decode_readback(status()[:size]) is None
    state = ff().TuningState(); state.accept_status(status()[:size],1_000_000_000,19,1)
    assert not state.snapshot(1_000_000_001)["ready"]


@pytest.mark.parametrize("word,value", [(0,0),(1,2),(2,0),(4,9),(5,0),(15,128),(23,8),(29,1),(30,1),(31,1)])
def test_malformed_extension_is_rejected(word,value):
    payload = bytearray(status()); struct.pack_into("!I",payload,1256+word*4,value)
    assert ff().decode_readback(payload,packet_boot=19) is None


@pytest.mark.parametrize("word", [16,17,18,19,24,25,26,27])
def test_nonfinite_diagnostic_is_rejected(word):
    payload = bytearray(status()); struct.pack_into("!f",payload,1256+word*4,float("nan"))
    assert ff().decode_readback(payload) is None


def test_success_needs_matching_boot_revision_request_and_exact_values():
    state = accepted(); values=(90.,60.,.25,.5,7.,8.,80.,2.)
    state.begin(values,77,1_010_000_000)
    state.accept_status(status(revision=2,request=77,ack=1,values=values),1_020_000_000,19,2)
    view=state.snapshot(1_020_000_001)
    assert not view["pending"] and view["revision"]==2 and "已应用并回读一致" in view["message"]
    assert view["values"]==values and view["apply_count"]==1
    state.accept_status(status(revision=3,request=999,ack=1),1_030_000_000,19,3)
    assert "已应用并回读一致" not in state.snapshot(1_030_000_001)["message"]


def test_reboot_after_success_without_pending_clears_previous_session_success():
    state=accepted(); values=(90.,60.,.25,.5,7.,8.,80.,2.)
    state.begin(values,77,1_010_000_000)
    state.accept_status(status(revision=2,request=77,ack=1,values=values),1_020_000_000,19,2)
    assert not state.pending and "已应用并回读一致" in state.snapshot(1_020_000_001)["message"]
    assert state.accept_status(status(boot=20),1_030_000_000,20,1)
    view=state.snapshot(1_030_000_001)
    assert view["ready"] and view["boot_id"]==20 and view["revision"]==1
    assert struct.pack("!8f",*view["values"])==struct.pack("!8f",*DEFAULTS)
    assert "已应用并回读一致" not in view["message"]
    assert "重新启动" in view["message"] and "新启动" in view["message"] and "修订 1" in view["message"]


@pytest.mark.parametrize("ack", [2,3,4,5,6,8])
def test_rejection_cannot_claim_success(ack):
    state=accepted(); state.begin(DEFAULTS,77,1_010_000_000)
    state.accept_status(status(request=77,ack=ack),1_020_000_000,19,2)
    assert not state.pending and "拒绝" in state.message


def test_mismatched_echo_and_foreign_revision_report_unknown():
    state=accepted(); state.begin((90.,*DEFAULTS[1:]),77,1_010_000_000)
    state.accept_status(status(revision=2,request=77,ack=7),1_020_000_000,19,2)
    assert "不同" in state.message and not state.pending
    state.begin(DEFAULTS,78,1_020_000_001)
    state.accept_status(status(revision=3,request=999,ack=1),1_030_000_000,19,3)
    assert "其他请求" in state.message and not state.pending


def test_freshness_reorder_sequence_wrap_restart_and_resync_do_not_retry():
    state=accepted(); state.begin(DEFAULTS,77,1_010_000_000)
    assert not state.accept_status(status(),1_100_000_000,19,1)
    assert not state.accept_status(status(values=(90.,*DEFAULTS[1:])),1_100_000_000,19,2)
    assert state.accept_status(status(),3_100_000_000,19,3)
    assert "未自动重发" in state.snapshot(3_100_000_001)["message"]
    state.read_current(3_100_000_001);state.begin(DEFAULTS,78,3_100_000_002)
    state.accept_status(status(boot=20),3_200_000_000,20,0xffffffff)
    assert not state.pending and "重新启动" in state.message
    assert not state.accept_status(status(revision=9),3_210_000_000,19,9)
    assert state.accept_status(status(boot=20),3_300_000_000,20,0)
    assert not state.ready(4_300_000_001)
    state.resync();assert "未重发" in state.message and not state.ready(4_300_000_002)


def test_revision_rollback_wrong_packet_boot_and_incompatible_pwm_do_not_enable():
    state=accepted()
    assert not state.accept_status(status(),1_100_000_000,20,2)
    state.accept_status(status(revision=3),1_100_000_000,19,2)
    assert not state.accept_status(status(revision=2),1_200_000_000,19,3)
    state.accept_status(status(revision=3),1_200_000_000,19,3,compatible=False)
    assert not state.snapshot(1_200_000_001)["ready"]
    with pytest.raises(RuntimeError):state.begin(DEFAULTS,1,1_200_000_002)


class FakeSocket:
    def __init__(self):self.sent=[];self.fail=False
    def sendto(self,data,address):
        if self.fail:raise OSError("offline")
        self.sent.append((data,address))


def test_receiver_only_explicit_feedforward_apply_sends_and_original_group_is_independent(monkeypatch):
    ff();monkeypatch.setattr(time,"monotonic_ns",lambda:1_000_000_000)
    service=ReceiverService(port_types={});service._control_socket=sock=FakeSocket()
    service._accept_status(status(),1_000_000_000,19,1)
    assert service.snapshots()[1]["visual_feedforward"]["ready"] and sock.sent==[]
    service.send_visual_feedforward((90.,*DEFAULTS[1:]))
    packet=parse_datagram(sock.sent[0][0]);command,length,_=struct.unpack_from("!HHI",packet.payload)
    assert (command,length)==(27,45)
    assert struct.unpack("!BIII8f",packet.payload[8:])[1:3]==(19,1)
    original=service.snapshots()[1]["visual_tuning"]
    assert not original["pending"] and original["revision"]==1
    assert struct.pack("!8f",*original["values"])==struct.pack("!8f",105.,85.,20.,15.,.04,.06,.025,.045)
    service.read_visual_feedforward();service.resync_visual_feedforward()
    assert len(sock.sent)==1 and not service.snapshots()[1]["visual_feedforward"]["ready"]


def test_receiver_send_failure_missing_control_and_polling_never_retry(monkeypatch):
    ff();service=ReceiverService(port_types={})
    for action in (lambda:service.send_visual_feedforward(DEFAULTS),service.read_visual_feedforward,service.resync_visual_feedforward):
        with pytest.raises(RuntimeError):action()
    monkeypatch.setattr(time,"monotonic_ns",lambda:1_000_000_000)
    service._control_socket=sock=FakeSocket();service._accept_status(status(),1_000_000_000,19,1)
    sock.fail=True
    with pytest.raises(OSError):service.send_visual_feedforward(DEFAULTS)
    assert "结果未知" in service.snapshots()[1]["visual_feedforward"]["message"]
    sock.fail=False
    for _ in range(3):service.snapshots()
    with pytest.raises(RuntimeError):service.send_visual_feedforward(DEFAULTS)
    assert sock.sent==[]


class FakeVar:
    def __init__(self,value):self.value=value;self.callbacks=[]
    def get(self):return self.value
    def set(self,value):
        self.value=value
        for callback in self.callbacks:callback()
    def trace_add(self,_mode,callback):self.callbacks.append(callback)


class FakeWidget:
    def __init__(self,*args,**kwargs):self.attrs=dict(kwargs);self.tabs=[]
    def configure(self,**kwargs):self.attrs.update(kwargs)
    def grid(self,*args,**kwargs):pass
    def pack(self,*args,**kwargs):pass
    def add(self,child,**kwargs):self.tabs.append((child,kwargs))


def panel(monkeypatch):
    ff();module=importlib.import_module("av_monitor.visual_feedforward_panel")
    monkeypatch.setattr(module.tk,"StringVar",lambda value:FakeVar(value))
    for name in ("Frame","Label","Spinbox","Button","Notebook","Entry"):
        monkeypatch.setattr(module.ttk,name,FakeWidget)
    service=SimpleNamespace(sent=[],read=ff().canonical_values(DEFAULTS),resynced=[])
    service.send_visual_feedforward=lambda values:service.sent.append(values)
    service.read_visual_feedforward=lambda:service.read
    service.resync_visual_feedforward=lambda:service.resynced.append(True)
    return module.VisualFeedforwardPanel(FakeWidget(),service),service


def panel_status(values=DEFAULTS,revision=1,ready=True,pending=False,boot=19):
    state=ff().TuningState();state.accept_status(status(values=values,revision=revision,boot=boot),1_000_000_000,boot,1)
    snapshot=state.snapshot(1_000_000_001);snapshot.update(ready=ready,pending=pending)
    return {"visual_feedforward":snapshot}


def test_panel_open_edit_step_defaults_read_disable_and_resync_never_send(monkeypatch):
    view,service=panel(monkeypatch)
    assert service.sent==[] and view.apply_button.attrs["state"]=="disabled"
    view.update(panel_status());view._step(0,1)
    assert view.variables[0].get()=="1" and service.sent==[]
    view._step(0,-1);assert view.variables[0].get()=="0"
    view._defaults();view._read();view._disable();view._resync()
    assert view._values()[2:4]==(0.,0.) and service.sent==[] and service.resynced==[True]


def test_panel_protects_draft_across_reboot_and_displays_board_calibration_and_diagnostics(monkeypatch):
    view,service=panel(monkeypatch);view.update(panel_status())
    assert "需设置换算系数" in view.calibration.attrs["text"]
    view.variables[0].set("91")
    view.update(panel_status(values=(80.,60.,.25,.5,7.,8.,80.,2.),revision=2,boot=20))
    assert view.variables[0].get()=="91" and "80" in view.actual.attrs["text"]
    assert "未应用" in view.status.attrs["text"] and service.sent==[]
    assert "估计" in view.feedback.attrs["text"] and "编码器" in view.feedback.attrs["text"]


def test_panel_only_valid_explicit_atomic_apply_sends_and_disables_pending_stale(monkeypatch):
    view,service=panel(monkeypatch);view.update(panel_status())
    view.variables[0].set("90");view.update(panel_status())
    assert view.apply_button.attrs["state"]=="normal"
    view._apply();assert len(service.sent)==1 and len(service.sent[0])==8
    view.variables[6].set("10");view._apply();assert len(service.sent)==1 and view._local_error
    view.update(panel_status(pending=True));assert view.apply_button.attrs["state"]=="disabled"
    view.update(panel_status(ready=False));assert view.fields[0].attrs["state"]=="disabled"


def test_original_visual_window_contains_two_independent_groups(monkeypatch):
    _,service=panel(monkeypatch)
    module=importlib.import_module("av_monitor.visual_tuning_panel")
    view=module.VisualTuningPanel(FakeWidget(),service)
    assert [tab[1]["text"] for tab in view.notebook.tabs]==["比例与死区","运动前馈"]
    assert len(view.variables)==8 and len(view.feedforward_panel.variables)==8
    view.update(panel_status())
    assert "需设置换算系数" in view.feedforward_panel.calibration.attrs["text"] and service.sent==[]
