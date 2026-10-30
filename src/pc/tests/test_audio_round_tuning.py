"""M46 timing contract; fake Tk and sockets never launch a monitor or hardware."""
import importlib
import importlib.util
import struct
import time
from types import SimpleNamespace

import pytest

from av_monitor.network import ReceiverService
from av_monitor.protocol import parse_datagram


def timing():
    assert importlib.util.find_spec("av_monitor.audio_round_tuning") is not None, "M46 independent timing support is missing"
    return importlib.import_module("av_monitor.audio_round_tuning")


def status(boot=19, revision=1, request=0, ack=0, values=(3000, 3000, 8000, 5000),
           observed=None, *, samples=None, silence=None, pause=0):
    samples = values[0]*32 if samples is None and (observed is None or observed == revision) else (96000 if samples is None else samples)
    silence = 160000-samples if silence is None else silence
    payload = bytearray(1256)
    struct.pack_into("!11IHH", payload, 0, 1, 0x1000a, 46, boot, 100, 7, 0, 0, 0, 0, 0, 70, 0)
    struct.pack_into("!16I", payload, 1192, 0x53525432, 1, revision, request, ack, boot,
                     *values, revision-1, revision if observed is None else observed,
                     samples, silence, pause, 0)
    return bytes(payload)


def accepted():
    state = timing().TuningState()
    assert state.accept_status(status(), 1_000_000_000, 19, 1)
    return state


def test_request_uses_exact_integer_milliseconds_and_independent_command():
    at = timing()
    wire = at.encode_request(19, 3, 77, (1250, 3000, 8000, 0))
    assert at.COMMAND == 26
    assert wire == b'\x01' + struct.pack("!7I", 19, 3, 77, 1250, 3000, 8000, 0)
    assert len(wire) == 29
    assert at.draft_values(("1.25", "3", "8", "0")) == (1250, 3000, 8000, 0)
    assert at.display_values((1250, 3000, 8000, 0)) == ("1.25", "3", "8", "0")


@pytest.mark.parametrize("values", [(1000,1000,2000,0), (5000,10000,30000,30000)])
def test_inclusive_boundaries_are_valid(values):
    assert timing().canonical_values(values) == values


@pytest.mark.parametrize("values", [(999,3000,8000,5000), (5001,6000,8000,5000),
    (3000,2999,8000,5000), (3000,10001,20000,5000), (1000,1000,1999,5000),
    (3000,3000,3000,5000), (3000,3000,30001,5000), (3000,3000,8000,30001),
    (3000,3000,8000,-1), (3000.1,3000,8000,5000), (True,3000,8000,5000)])
def test_invalid_group_never_encodes(values):
    with pytest.raises(ValueError): timing().encode_request(19,1,77,values)


@pytest.mark.parametrize("identity", [(0,1,1),(1,0,1),(1,1,0),(-1,1,1),(1,1,0x100000000),(True,1,1)])
def test_invalid_request_identity_never_encodes(identity):
    with pytest.raises(ValueError): timing().encode_request(*identity,(3000,3000,8000,5000))


@pytest.mark.parametrize("text", ["NaN", "inf", "", "1.0001", "bird"])
def test_invalid_or_fractional_millisecond_seconds_are_rejected(text):
    with pytest.raises(ValueError): timing().draft_values((text,"3","8","5"))


def test_extension_rejects_short_schema_reserved_boot_and_invalid_values():
    at = timing()
    assert at.decode_readback(status()[:-1]) is None
    assert at.decode_readback(status(), packet_boot=20) is None
    for relative, value in ((0,0),(4,2),(8,0),(16,8),(20,0),(24,0),(44,2),(60,1)):
        payload=bytearray(status()); struct.pack_into("!I",payload,1192+relative,value)
        assert at.decode_readback(payload, packet_boot=19) is None


def test_core0_ack_waits_for_observed_core1_revision_before_success():
    state=accepted(); state.begin((2000,3000,8000,5000),77,1_010_000_000)
    assert state.accept_status(status(revision=2,request=77,ack=1,values=(2000,3000,8000,5000),observed=1),1_020_000_000,19,2)
    view=state.snapshot(1_020_000_001)
    assert not view["pending"] and not view["fully_applied"] and "同步" in view["message"]
    assert "已应用并回读一致" not in view["message"]
    state.accept_status(status(revision=2,request=77,ack=7,values=(2000,3000,8000,5000),observed=2,samples=64000,silence=96000,pause=4123),1_030_000_000,19,3)
    view=state.snapshot(1_030_000_001)
    assert view["fully_applied"] and "已应用并回读一致" in view["message"]
    assert (view["capture_samples"],view["silence_samples"],view["pause_remaining_ms"]) == (64000,96000,4123)


def test_order_freshness_reboot_unknown_result_and_resync_never_retry():
    state=accepted(); state.begin((2000,3000,8000,5000),77,1_010_000_000)
    assert not state.accept_status(status(),1_100_000_000,19,1)
    assert not state.accept_status(status(values=(2000,3000,8000,5000)),1_100_000_000,19,2)
    state.accept_status(status(),3_100_000_000,19,3)
    assert "未自动重发" in state.snapshot(3_100_000_001)["message"]
    assert state.read_current(3_100_000_001) == (3000,3000,8000,5000)
    state.begin((2000,3000,8000,5000),78,3_100_000_002)
    state.accept_status(status(boot=20),3_200_000_000,20,0xffffffff)
    assert not state.pending and "重新启动" in state.message
    assert not state.accept_status(status(revision=9),3_300_000_000,19,8)
    assert state.accept_status(status(boot=20),3_300_000_000,20,0)
    assert not state.ready(4_300_000_001)
    state.resync()
    assert not state.snapshot(4_300_000_002)["ready"] and "未重发" in state.message


@pytest.mark.parametrize("ack", [2,3,4,5,6])
def test_rejected_or_conflicting_request_cannot_claim_success(ack):
    state=accepted(); state.begin((2000,3000,8000,5000),77,1_010_000_000)
    state.accept_status(status(request=77,ack=ack),1_020_000_000,19,2)
    assert not state.pending and "拒绝" in state.message


def test_mismatched_echo_and_other_client_update_do_not_claim_success():
    state=accepted(); state.begin((2000,3000,8000,5000),77,1_010_000_000)
    state.accept_status(status(revision=2,request=77,ack=1),1_020_000_000,19,2)
    assert not state.pending and "不同" in state.message
    state.begin((2000,3000,8000,5000),78,1_020_000_001)
    state.accept_status(status(revision=3,request=999,ack=1),1_030_000_000,19,3)
    assert not state.pending and "其他请求" in state.message


def test_actual_sample_counts_are_validated_without_rejecting_unsynced_adoption():
    at=timing()
    assert at.decode_readback(status(samples=96001)) is None
    assert at.decode_readback(status(silence=0)) is None
    assert at.decode_readback(status(revision=2,values=(2000,3000,8000,5000),observed=1)) is not None
    assert at.decode_readback(status(revision=2,values=(2000,3000,8000,5000),samples=96000)) is None


def test_success_message_cannot_leak_into_later_unsynced_other_client_revision():
    state=accepted(); state.begin((2000,3000,8000,5000),77,1_010_000_000)
    state.accept_status(status(revision=2,request=77,ack=1,values=(2000,3000,8000,5000)),1_020_000_000,19,2)
    assert "已应用并回读一致" in state.snapshot(1_020_000_001)["message"]
    state.accept_status(status(revision=3,request=999,ack=1,observed=2,samples=64000),1_030_000_000,19,3)
    view=state.snapshot(1_030_000_001)
    assert not view["fully_applied"] and "同步" in view["message"]
    assert "已应用并回读一致" not in view["message"]


class FakeSocket:
    def __init__(self): self.sent=[]; self.fail=False
    def sendto(self,data,address):
        if self.fail: raise OSError("offline")
        self.sent.append((data,address))


def test_receiver_accepts_no_pwm_status_and_sends_only_explicit_timing_apply(monkeypatch):
    timing()
    monkeypatch.setattr(time,"monotonic_ns",lambda:1_000_000_000)
    service=ReceiverService(port_types={}); sock=FakeSocket(); service._control_socket=sock
    service._accept_status(status(),1_000_000_000,19,1)
    assert service.snapshots()[1]["audio_round_tuning"]["ready"] and sock.sent == []
    service.send_audio_round_tuning((2000,3000,8000,5000))
    packet=parse_datagram(sock.sent[0][0]); command,length,_=struct.unpack_from("!HHI",packet.payload)
    assert (command,length)==(26,29) and len(sock.sent)==1
    _,boot,revision,request,*values=struct.unpack("!B7I",packet.payload[8:])
    assert (boot,revision,values)==(19,1,[2000,3000,8000,5000])
    assert not service.snapshots()[1]["audio_tuning"]["pending"]
    service._accept_status(status(revision=2,request=request,ack=1,values=values,observed=1),1_000_000_000,19,2)
    assert not service.snapshots()[1]["audio_round_tuning"]["fully_applied"]
    assert service.read_audio_round_tuning()==tuple(values)
    service.resync_audio_round_tuning()
    assert len(sock.sent)==1 and not service.snapshots()[1]["audio_round_tuning"]["ready"]


def test_receiver_missing_port_send_failure_and_polls_never_retry(monkeypatch):
    timing()
    service=ReceiverService(port_types={})
    for action in (lambda:service.send_audio_round_tuning((3000,3000,8000,5000)),
                   service.read_audio_round_tuning,service.resync_audio_round_tuning):
        with pytest.raises(RuntimeError): action()
    monkeypatch.setattr(time,"monotonic_ns",lambda:1_000_000_000)
    service._control_socket=sock=FakeSocket(); service._accept_status(status(),1_000_000_000,19,1)
    sock.fail=True
    with pytest.raises(OSError):service.send_audio_round_tuning((2000,3000,8000,5000))
    assert "结果未知" in service.snapshots()[1]["audio_round_tuning"]["message"]
    sock.fail=False
    for _ in range(3): service.snapshots()
    with pytest.raises(RuntimeError):service.send_audio_round_tuning((2000,3000,8000,5000))
    assert sock.sent==[]


class FakeVar:
    def __init__(self,value): self.value=value; self.callbacks=[]
    def get(self): return self.value
    def set(self,value):
        self.value=value
        for callback in self.callbacks: callback()
    def trace_add(self,_mode,callback): self.callbacks.append(callback)


class FakeWidget:
    def __init__(self,*args,**kwargs): self.attrs=dict(kwargs); self.tabs=[]
    def configure(self,**kwargs): self.attrs.update(kwargs)
    def grid(self,*args,**kwargs): pass
    def pack(self,*args,**kwargs): pass
    def add(self,child,**kwargs): self.tabs.append((child,kwargs))


def panel(monkeypatch):
    timing()
    assert importlib.util.find_spec("av_monitor.audio_round_panel") is not None, "M46 timing UI is missing"
    module=importlib.import_module("av_monitor.audio_round_panel")
    monkeypatch.setattr(module.tk,"StringVar",lambda value:FakeVar(value))
    for name in ("Frame","Label","Spinbox","Button"):
        monkeypatch.setattr(module.ttk,name,FakeWidget)
    service=SimpleNamespace(sent=[],read=(3000,3000,8000,5000),resynced=[])
    service.send_audio_round_tuning=lambda values:service.sent.append(values)
    service.read_audio_round_tuning=lambda:service.read
    service.resync_audio_round_tuning=lambda:service.resynced.append(True)
    return module.AudioRoundPanel(FakeWidget(),service),service


def panel_telemetry(values=(3000,3000,8000,5000),revision=1,ready=True,pending=False,fully_applied=True):
    return {"audio_round_tuning":dict(ready=ready,control_open=True,values=values,boot_id=19,
        revision=revision,apply_count=revision-1,pending=pending,fully_applied=fully_applied,
        core1_observed_revision=revision if fully_applied else revision-1,capture_samples=96000,
        silence_samples=64000,pause_remaining_ms=4123,message="板端当前值")}


def test_timing_panel_edit_defaults_read_resync_do_not_send_and_actual_is_readback(monkeypatch):
    view,service=panel(monkeypatch)
    assert service.sent==[] and view.apply_button.attrs["state"]=="disabled"
    assert [variable.get() for variable in view.variables]==["3","3","8","5"]
    view.update(panel_telemetry()); view.variables[0].set("2")
    view.update(panel_telemetry(values=(1500,3000,8000,5000),revision=2,fully_applied=False))
    assert view.variables[0].get()=="2" and "1500 ms" in view.actual.attrs["text"]
    assert "4123 ms" in view.actual.attrs["text"] and "同步" in view.actual.attrs["text"]
    assert "本组配置采样目标" in view.actual.attrs["text"]
    assert "Core1 已采纳采样目标" not in view.actual.attrs["text"]
    assert "3 秒" in view.silence.attrs["text"]
    view._defaults(); view._read(); view._resync()
    assert service.sent==[] and service.resynced==[True]


def test_timing_panel_only_apply_sends_valid_group_and_enforces_relationships(monkeypatch):
    view,service=panel(monkeypatch); view.update(panel_telemetry())
    view.variables[0].set("2.5"); view.update(panel_telemetry())
    assert view.apply_button.attrs["state"]=="normal"
    view._apply(); assert service.sent==[(2500,3000,8000,5000)]
    view.variables[0].set("4"); view._apply()
    assert len(service.sent)==1 and "间隔" in view._local_error
    view.variables[0].set("2"); view.variables[2].set("3"); view._apply()
    assert len(service.sent)==1 and "重置" in view._local_error
    view.update(panel_telemetry(pending=True)); assert view.apply_button.attrs["state"]=="disabled"
    view.update(panel_telemetry(ready=False)); assert view.fields[0].attrs["state"]=="disabled"


def test_existing_hearing_panel_contains_both_independent_control_groups_in_tabs(monkeypatch):
    import av_monitor.audio_tuning_panel as module
    import av_monitor.audio_round_panel as round_module
    monkeypatch.setattr(module.tk,"StringVar",lambda value:FakeVar(value))
    for name in ("Frame","Label","Entry","Spinbox","Button","Notebook"):
        monkeypatch.setattr(module.ttk,name,FakeWidget)
    service=SimpleNamespace()
    view=module.AudioTuningPanel(FakeWidget(),service)
    assert [tab[1]["text"] for tab in view.notebook.tabs]==["定位与寻向","采样与确认时序"]
    assert len(view.variables)==8 and len(view.round_panel.variables)==4
    view.update(panel_telemetry())
    assert "3000 ms" in view.round_panel.actual.attrs["text"]

