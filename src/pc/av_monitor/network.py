"""Deterministically stoppable UDP receivers for ports 15000--15003."""

from __future__ import annotations
from .sd_record_status import decode as decode_sd_record_status

from dataclasses import dataclass, field
from collections import deque
import os
import json
from pathlib import Path
import queue
import secrets
import socket
import struct
import threading
import time
import warnings
from typing import Any

from .features import FeatureHistory
from .protocol import MAX_DATAGRAM_BYTES, PacketError, PacketType, parse_datagram, build_datagram
from .video import CompletedFrame, VideoAssembler
from .recognition import decode_result, load_classes
from .ssd_preview import decode_preview, decode_class_metadata
from .visual_policy import VISUAL_BIRD_MIN_SCORE_Q6
from .visual_tuning import TuningState, COMMAND as VISUAL_TUNING_COMMAND
from .visual_feedforward import TuningState as VisualFeedforwardState, COMMAND as VISUAL_FEEDFORWARD_COMMAND
from .audio_tuning import TuningState as AudioTuningState, COMMAND as AUDIO_TUNING_COMMAND
from .audio_round_tuning import TuningState as AudioRoundTuningState, COMMAND as AUDIO_ROUND_TUNING_COMMAND
from .scan_preview_tuning import TuningState as ScanPreviewTuningState, COMMAND as SCAN_PREVIEW_TUNING_COMMAND
from .video_health import VideoHealth, decode_health, decode_capture_evidence, preview_stale_after_s


@dataclass(slots=True)
class ReceiverStats:
    packets: int = 0
    malformed: int = 0
    wrong_type: int = 0
    pcm_gaps: int = 0
    last_packet_ns: int = 0
    socket_buffer_bytes: dict[int, int] = field(default_factory=dict)
    snapshot_errors: int = 0
    fusion_packets: int = 0
    fusion_errors: int = 0
    video_frames: int = 0
    port_packets: dict[int, int] = field(default_factory=dict)
    port_last_packet_ns: dict[int, int] = field(default_factory=dict)
    io_dropped: int = 0


class ReceiverService:
    PORT_TYPES = {15000: PacketType.VIDEO, 15001: PacketType.PCM,
                  15002: PacketType.FEATURE, 15003: PacketType.STATUS,
                  15004: PacketType.CONTROL_REPLY, 15005: None}

    def __init__(self, bind_ip: str = "0.0.0.0",
                 port_types: dict[int, PacketType] | None = None,
                 snapshot_path: str | Path | None = None,
                 snapshot_interval_s: float = 60.0,
                 result_log: str | Path | None = None) -> None:
        if snapshot_interval_s <= 0:
            raise ValueError("snapshot interval must be positive")
        self.bind_ip = bind_ip
        self.port_types = dict(self.PORT_TYPES if port_types is None else port_types)
        self.video = VideoAssembler()
        self.features = FeatureHistory()
        self.stats = ReceiverStats()
        self._stop = threading.Event()
        self._threads: list[threading.Thread] = []
        self._sockets: list[socket.socket] = []
        self._lock = threading.Lock()
        self._latest_frame: CompletedFrame | None = None
        self._last_complete_frame = None
        self._frame_times = deque(maxlen=120)
        self._video_health = VideoHealth()
        self._io_queue: queue.Queue = queue.Queue(maxsize=8)
        self._io_thread = None
        self._io_stop = threading.Event()
        self._io_active = False
        self._control_socket = None
        self._control_sequence = int(time.monotonic_ns()) & 0xffffffff
        self._control_pending = {}
        self._control_message = '未发送控制命令'
        self._visual_tuning = TuningState()
        self._visual_tuning_request = secrets.randbits(32)
        self._visual_tuning_feedback = {}
        self._visual_tuning_feedback_ns = None
        self._visual_feedforward = VisualFeedforwardState()
        self._visual_feedforward_request = secrets.randbits(32)
        self._audio_tuning = AudioTuningState()
        self._audio_tuning_request = secrets.randbits(32)
        self._audio_round_tuning = AudioRoundTuningState()
        self._audio_round_tuning_request = secrets.randbits(32)
        self._audio_tuning_feedback = {}
        self._audio_tuning_feedback_ns = None
        self._scan_preview_tuning = ScanPreviewTuningState()
        self._scan_preview_tuning_request = secrets.randbits(32)
        self._latest_pcm: bytes | None = None
        self._pcm_boot: int | None = None
        self._pcm_sequence: int | None = None
        self._telemetry: dict[str, Any] = {}
        self._telemetry_ns = 0
        self.classes = load_classes()
        self._recognition = None
        self._recognition_ns = 0
        self._ssd_preview = None
        self._ssd_preview_ns = 0
        self._ssd_class_metadata = None
        self._result_log = Path(result_log) if result_log else None
        if self._result_log:
            self._result_log.parent.mkdir(parents=True, exist_ok=True)
        self._snapshot_path = Path(snapshot_path) if snapshot_path is not None else None
        self._snapshot_interval_ns = int(snapshot_interval_s * 1_000_000_000)
        self._last_snapshot_ns: int | None = None
        self.audio_queue: queue.Queue[bytes] = queue.Queue(maxsize=8)

    def start(self) -> None:
        if self._threads:
            return
        self._stop.clear()
        with self._lock:
            self._video_health.started_ns = time.monotonic_ns()
        try:
            for port, expected in self.port_types.items():
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 64 * 1024 * 1024)
                sock.settimeout(0.2)
                sock.bind((self.bind_ip, port))
                self.stats.socket_buffer_bytes[port] = sock.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF)
                thread = threading.Thread(target=self._worker, args=(sock, expected),
                                          name=f"avp1-udp-{port}", daemon=True)
                self._sockets.append(sock)
                if expected==PacketType.CONTROL_REPLY:self._control_socket=sock
                self._threads.append(thread)
                thread.start()
        except Exception:
            self.stop()
            raise

    def stop(self, timeout_s: float = 2.0) -> None:
        self._stop.set()
        for sock in self._sockets:
            sock.close()
        deadline = time.monotonic() + timeout_s
        for thread in self._threads:
            thread.join(max(0.0, deadline - time.monotonic()))
        self._threads.clear()
        self._sockets.clear()
        self._control_socket = None
        self._io_stop.set()
        if self._io_thread is not None:
            self._io_thread.join(max(0., deadline-time.monotonic()))
            if self._io_thread.is_alive():
                warnings.warn('诊断文件尚未保存完成；退出进程可能丢失待保存记录。', RuntimeWarning)

    def _worker(self, sock: socket.socket, expected: PacketType) -> None:
        buffer = bytearray(MAX_DATAGRAM_BYTES)
        port = sock.getsockname()[1]
        while not self._stop.is_set():
            try:
                count, _ = sock.recvfrom_into(buffer)
            except socket.timeout:
                if expected == PacketType.VIDEO:
                    with self._lock:
                        self.video.expire(time.monotonic_ns())
                continue
            except OSError:
                break
            now = time.monotonic_ns()
            with self._lock:
                self.stats.port_packets[port] = self.stats.port_packets.get(port, 0) + 1
                self.stats.port_last_packet_ns[port] = now
                if expected == PacketType.VIDEO:
                    self._video_health.packet(now)
            if expected is None:
                self._accept_recognition(bytes(memoryview(buffer)[:count]), now)
                continue
            try:
                packet = parse_datagram(memoryview(buffer)[:count])
            except PacketError:
                with self._lock:
                    self.stats.malformed += 1
                continue
            if packet.header.packet_type != expected:
                with self._lock:
                    self.stats.wrong_type += 1
                continue
            with self._lock:
                self.stats.packets += 1
                self.stats.last_packet_ns = now
            if expected == PacketType.VIDEO:
                with self._lock:
                    boot = self._telemetry.get('boot_id')
                    if boot and packet.header.boot_id != boot:
                        self.video.rejected += 1
                        continue
                    frame = self.video.push(packet, now)
                if frame is not None:
                    self._accept_video_frame(frame, now)
            elif expected == PacketType.FEATURE:
                try:
                    self.features.push(packet, now)
                except ValueError:
                    with self._lock:
                        self.stats.malformed += 1
            elif expected == PacketType.PCM:
                self._accept_pcm(packet.header.boot_id, packet.header.sequence, packet.payload)
            elif expected == PacketType.CONTROL_REPLY:
                if len(packet.payload)==8:
                    sequence,code=struct.unpack_from('!IB',packet.payload)
                    with self._lock:
                        command=self._control_pending.pop(sequence,None)
                        if command:self._control_message=f'{command}: '+{0:'板端已接受',1:'拒绝',2:'不支持'}.get(code,'未知响应')
            else:
                self._accept_status(packet.payload, now, packet.header.boot_id,
                                    packet.header.sequence)

    def _accept_recognition(self, data: bytes, now_ns: int) -> None:
        if data[:4]==b'SVP1':
            self._accept_ssd_preview(data,now_ns)
            return
        if data[:4]==b'SVC1':
            try:p=decode_class_metadata(data)
            except ValueError:
                with self._lock:self.stats.fusion_errors+=1
                return
            with self._lock:
                old=self._ssd_class_metadata
                if p['boot_id']!=self._telemetry.get('boot_id'):return
                if old and old['boot_id']==p['boot_id']:
                    delta=(p['message_sequence']-old['message_sequence'])&0xffffffff
                    if not 0<delta<0x80000000:return
                self._ssd_class_metadata=p
            return
        try:
            result = decode_result(data, self.classes)
        except ValueError:
            with self._lock:
                self.stats.fusion_errors += 1
            return
        with self._lock:
            if (result['status']==8 and self._recognition and
                result['sequence']==self._recognition['sequence'] and
                result['audio_timestamp_us']==self._recognition['audio_timestamp_us'] and
                self._recognition['status']!=8):
                return  # A delayed provisional UDP cannot replace its final answer.
            self._recognition = result
            self._recognition_ns = now_ns
            self.stats.fusion_packets += 1
        if self._result_log:
            self._queue_io('result', dict(result, received_unix=time.time()))

    def _accept_ssd_preview(self,data,now_ns):
        try:p=decode_preview(data)
        except ValueError:
            with self._lock:self.stats.fusion_errors+=1
            return
        with self._lock:
            # A delayed packet from another boot cannot replace the current one.
            if p['boot_id']!=self._telemetry.get('boot_id'):return
            old=self._ssd_preview
            if old and old['boot_id']==p['boot_id']:
                delta=(p['message_sequence']-old['message_sequence'])&0xffffffff
                if not 0<delta<0x80000000:return
            self._ssd_preview=p;self._ssd_preview_ns=now_ns

    def recognition_snapshot(self):
        with self._lock:
            result = dict(self._recognition) if self._recognition else None
            meta=self._ssd_class_metadata
            if (result and meta and meta['boot_id']==self._telemetry.get('boot_id') and
                result['video_sequence']==meta['video_sequence'] and result['video_timestamp_us']==meta['video_timestamp_us']):
                result['classification_source']=dict(meta)
            age = (time.monotonic_ns()-self._recognition_ns)/1e9 if result else 0
        return result, age

    def _accept_video_frame(self, frame: CompletedFrame, now_ns: int) -> None:
        with self._lock:
            previous = self._last_complete_frame
            if previous and frame.boot_id == previous.boot_id:
                delta = (frame.frame_id-previous.frame_id) & 0xffffffff
                if not 0 < delta < 0x80000000 or frame.timestamp_us <= previous.timestamp_us:
                    return
            self._video_health.complete(now_ns, preview_stale_after_s({
                'scan_preview_tuning': self._scan_preview_tuning.snapshot(now_ns)}))
            self._latest_frame = frame
            self._last_complete_frame = frame
            self._frame_times.append(now_ns)
            self.stats.video_frames += 1
        path = self._snapshot_path
        if path is None or (self._last_snapshot_ns is not None and
                            now_ns - self._last_snapshot_ns < self._snapshot_interval_ns):
            return
        self._last_snapshot_ns = now_ns
        self._queue_io('frame', frame.rgb565)

    def _queue_io(self, kind, value):
        # File writes and JSON serialization never run on a UDP receive thread.
        with self._lock:
            if self._io_thread is None or not self._io_thread.is_alive():
                self._io_stop.clear()
                self._io_thread = threading.Thread(target=self._io_worker,
                    name='avp1-diagnostic-files', daemon=True)
                self._io_thread.start()
        try:
            self._io_queue.put_nowait((kind, value))
        except queue.Full:
            with self._lock:
                self.stats.io_dropped += 1

    def _io_worker(self):
        while not self._io_stop.is_set() or not self._io_queue.empty():
            try:
                kind, value = self._io_queue.get(timeout=.1)
            except queue.Empty:
                continue
            try:
                self._io_active = True
                if kind == 'frame':
                    path = self._snapshot_path
                    temporary = path.with_name(path.name + '.tmp')
                    path.parent.mkdir(parents=True, exist_ok=True)
                    temporary.write_bytes(value)
                    os.replace(temporary, path)
                else:
                    with self._result_log.open('a', encoding='utf-8') as stream:
                        stream.write(json.dumps(value, ensure_ascii=False)+'\n')
            except OSError:
                with self._lock:
                    self.stats.snapshot_errors += 1
            finally:
                self._io_active = False
                self._io_queue.task_done()

    def _accept_pcm(self, boot_id: int, sequence: int, payload: bytes) -> None:
        if len(payload) != 960:
            with self._lock:
                self.stats.malformed += 1
            return
        with self._lock:
            if self._pcm_boot != boot_id:
                self._pcm_boot, self._pcm_sequence = boot_id, sequence
            elif self._pcm_sequence is not None and sequence > self._pcm_sequence + 1:
                self.stats.pcm_gaps += sequence - self._pcm_sequence - 1
            self._pcm_sequence = sequence
            self._latest_pcm = payload
        try:
            self.audio_queue.put_nowait(payload)
        except queue.Full:
            try:
                self.audio_queue.get_nowait()
                self.audio_queue.put_nowait(payload)
            except queue.Empty:
                pass

    def _accept_status(self, payload: bytes, now_ns: int,
                       packet_boot=None, packet_sequence=None) -> None:
        if len(payload) < 48:
            with self._lock:
                self.stats.malformed += 1
            return
        values = struct.unpack_from("!11IHH", payload)
        names = ("protocol_version", "register_version", "build_id", "boot_id",
                 "uptime_ms", "frame_count", "video_drop_old", "video_drop_tx",
                 "model_mel_drop", "audio_deadline_miss", "status_flags",
                 "mean_y", "dark_ratio_q15")
        with self._lock:
            self._telemetry = dict(zip(names, values))
            health = decode_health(payload)
            if health is not None:
                self._telemetry['video_health'] = health
            capture_evidence = decode_capture_evidence(payload)
            if capture_evidence is not None:
                self._telemetry['video_capture_evidence'] = capture_evidence
            if len(payload)>=56:
                self._telemetry['fusion_mode'],self._telemetry['capture_state']=struct.unpack_from('!2I',payload,48)
            if len(payload)>=120:
                h=struct.unpack_from('!16I',payload,56)
                self._telemetry['mic_mask']=h[1];self._telemetry['audio_activity']=h[2]
                self._telemetry['mic_rms']=struct.unpack_from('!4f',payload,72)
                self._telemetry['mic_clips']=h[8:12];self._telemetry['mic_invalid']=h[12:16]
            if len(payload)>=136:
                percent,bird,score,age=struct.unpack_from('!IIfI',payload,120)
                self._telemetry.update(direction_threshold_percent=percent,
                    direction_bird_class=bird,direction_bird_confidence=score,
                    direction_age_ms=None if age==0xffffffff else age)
            if len(payload)>=200:
                f=struct.unpack_from('!16I',payload,136)
                if f[0]==0x41465a31:
                    self._telemetry.update(focus_enabled=bool(f[1]),focus_state=f[2],
                        focus_error=f[3] if f[3]<0x80000000 else f[3]-0x100000000,
                        bird_zoom_active=bool(f[4]),bird_zoom_sequence=f[5],
                        bird_zoom_age_ms=f[6],bird_zoom_score=f[7]/32767,
                        bird_zoom_box=list(f[8:12]),focus_center=list(f[12:14]),
                        focus_requests=f[14],focus_completed=f[15])
            if len(payload)>=232:
                self._telemetry['focus_diagnostic']=list(struct.unpack_from('!8I',payload,200))
            if len(payload)>=256:
                m=struct.unpack_from('!6I',payload,232)
                if m[0]==0x4d463031 and m[1] in (0,1) and m[2]<=1023 and (m[3]<=1023 or m[3]==0xffffffff) and m[4] in (0,1):
                    self._telemetry.update(manual_focus_supported=True,manual_focus_mode=bool(m[1]),
                        manual_focus_target=m[2],manual_focus_readback=None if m[3]==0xffffffff else m[3],
                        manual_focus_busy=bool(m[4]),manual_focus_sequence=m[5])
            if len(payload)>=296:
                s=struct.unpack_from('!10I',payload,256)
                if s[0]==0x53525631 and s[1] in (0,1) and s[2] in (0,1) and 540<=s[4]<=2281:
                    self._telemetry.update(servo_supported=bool(s[1]),servo_auto=bool(s[2]),
                        servo_estimated_pan=(s[3] if s[3]<0x80000000 else s[3]-0x100000000)/1000,
                        servo_tilt_us=s[4],servo_left_budget=s[5]/1000,servo_right_budget=s[6]/1000,
                        servo_busy=bool(s[7]&0x1fff),servo_sequence=s[8],servo_limits=s[9],
                        servo_remaining_frames=(s[7]>>3)&15,servo_cooldown_frames=(s[7]>>7)&63)
            if len(payload)>=336:
                d=struct.unpack_from('!10I',payload,296)
                if d[0]==0x54524b31 and d[3] in (0,1) and d[4]<=1000000:
                    self._telemetry.update(detection_supported=True,detection_sequence=d[1],
                        detection_age_ms=d[2],detection_valid=bool(d[3]),detection_score=d[4]/1000000,
                        detection_box=[v/1000 for v in d[5:9]],detection_motion_sequence=d[9])
            if len(payload)>=376:
                d=struct.unpack_from('!10I',payload,336)
                maximum_frames=15 if self._telemetry.get('register_version',0)>=0x10007 else 6
                pulse_valid=(d[1:4] in ((1620,1360,1500),(1620,1330,1500)))
                if self._telemetry.get('register_version',0)>=0x10008:
                    pulse_valid=(1500<d[1]<=2000 and 1000<=d[2]<1500 and d[3]==1500 and
                        d[4]==(58404 if d[1]==1620 else 0) and d[5]==(57748 if d[2]==1330 else 0))
                if self._telemetry.get('register_version')==0x1000a:
                    pulse_valid=d[1:6]==(1410,1470,1440,0,0)
                if d[0]==0x53525632 and pulse_valid and d[6]<=maximum_frames and d[9]<=(10 if self._telemetry.get('register_version')==0x1000a else 8):
                    self._telemetry.update(servo_diagnostic_supported=True,servo_left_us=d[1],
                        servo_right_us=d[2],servo_stop_us=d[3],servo_left_rate=d[4]/1000,
                        servo_right_rate=d[5]/1000,servo_last_burst_ms=d[6]*20,
                        servo_left_frames=d[7],servo_right_frames=d[8],servo_tracking_reason=d[9])
            if len(payload)>=408:
                g=struct.unpack_from('!8I',payload,376)
                if (g[0]==0x53525633 and 0<g[1]<=180000 and 0<g[2]<=10000 and
                        0<g[3]<=10000 and g[4]==(1 if self._telemetry.get('register_version',0)>=0x10009 else 3) and
                        g[5] in ((5,6) if self._telemetry.get('register_version',0)>=0x10009 else (6,)) and
                        g[6]==20000 and g[7]==1):
                    self._telemetry.update(servo_guard_supported=True,servo_limit_deg=g[1]/1000,
                        servo_left_guard_deg_per_frame=g[2]/1000,servo_right_guard_deg_per_frame=g[3]/1000,
                        servo_min_tracking_frames=g[4],servo_manual_frames=g[5],
                        servo_frame_us=g[6],servo_rate_basis=g[7])
            if len(payload)>=448:
                v=struct.unpack_from('!10I',payload,408)
                if (v[0]==0x54524b32 and v[1]==1 and v[2] in (0,1) and v[3]==1 and
                        v[7]<=1000000 and v[9] in (0,1)):
                    self._telemetry.update(visual_tracker_supported=True,visual_tracker_active=bool(v[2]),
                        visual_tracker_source='board_ncc',visual_tracker_frames=v[4],visual_tracker_losses=v[5],
                        visual_tracker_ssd_age_ms=v[6],visual_tracker_quality=v[7]/1000000,
                        visual_tracker_sequence=v[8],visual_tracker_searching=bool(v[9]))
                    if len(payload)>=472:
                        b=struct.unpack_from('!6I',payload,448)
                        if b[0]<=1000000:
                            self._telemetry.update(visual_tracker_target_valid=b[0]>VISUAL_BIRD_MIN_SCORE_Q6,
                                visual_tracker_bird_score=b[0]/1000000,visual_tracker_frame_age_ms=b[1],
                                visual_tracker_box=[x/1000 for x in b[2:]])
            if len(payload)>=504:
                a=struct.unpack_from('!8I',payload,472)
                angle=a[4] if a[4]<0x80000000 else a[4]-0x100000000
                if (a[0]==0x534e4431 and a[1] in (0,1) and a[2] in (0,1) and
                        a[3]<=(11 if self._telemetry.get('register_version')==0x1000a else 8) and -180000<=angle<=180000 and a[7] in (0,1)):
                    self._telemetry.update(sound_tracking_supported=bool(a[1]),
                        sound_tracking_enabled=bool(a[2]),sound_tracking_state=a[3],
                        sound_tracking_angle_deg=angle/1000,
                        sound_tracking_age_ms=None if a[5]==0xffffffff else a[5],
                        sound_tracking_steps=a[6],sound_tracking_mount='base' if a[7]==0 else 'camera')
            if len(payload)>=552:
                q=struct.unpack_from('!4I',payload,536)
                if q[0]==0x53525635 and q[1] in (0,1) and q[2] in (0,1) and q[3]==0:
                    self._telemetry.update(servo_pan_limit_toggle_supported=bool(q[1]),
                        servo_pan_limit_enabled=bool(q[2]),servo_angle_source='pwm_period_estimate')
            if len(payload)>=536:
                p=struct.unpack_from('!8I',payload,504)
                signed=lambda v:v if v<0x80000000 else v-0x100000000
                lower,upper,position=signed(p[3]),signed(p[4]),signed(p[5])
                if (p[0]==0x53525634 and p[1] in (0,1) and p[2] in (0,1) and
                        -180000<=lower<0<upper<=180000 and 0<p[6]<=30000 and 0<p[7]<=30000 and
                        (p[1]==0 or p[2]==0 or lower<=position<=upper or
                         (self._telemetry.get('servo_pan_limit_toggle_supported') and
                          not self._telemetry.get('servo_pan_limit_enabled',True)))):
                    self._telemetry.update(servo_limit_policy_supported=True,
                        servo_limit_policy='relative_position' if p[1] else 'cumulative',
                        servo_reference_valid=bool(p[2]),servo_position_min_deg=lower/1000,
                        servo_position_max_deg=upper/1000,servo_limit_position_deg=position/1000,
                        servo_min_left_guard_deg=p[6]/1000,servo_min_right_guard_deg=p[7]/1000)
            if len(payload)>=616 and self._telemetry.get('visual_tracker_supported'):
                q=struct.unpack_from('!16I',payload,552)
                box=q[11:15]
                active=self._telemetry.get('visual_tracker_active',False)
                if (q[0]==0x54524b33 and q[1]==1 and q[2] in (0,1,2) and q[3]<3 and
                        q[4]<=13 and q[5]<=13 and q[6]==8000 and q[7]==750 and q[9]<=1000000 and
                        q[15]==3 and bool(q[2])==active and
                        ((q[2]==2 and q[3]>0) or (q[2]!=2 and q[3]==0)) and
                        (not active or (q[9]>VISUAL_BIRD_MIN_SCORE_Q6 and 0<=box[0]<box[2]<=1920000 and
                                        0<=box[1]<box[3]<=1080000))):
                    self._telemetry.update(visual_tracker_reacquire_supported=True,
                        visual_tracker_state=q[2],visual_tracker_misses=q[3],
                        visual_tracker_current_reason=q[4],visual_tracker_last_loss_reason=q[5],
                        visual_tracker_confirm_ms=q[6],visual_tracker_reacquire_ms=q[7],
                        visual_tracker_recovered=q[8],visual_tracker_held_score=q[9]/1000000,
                        visual_tracker_held_age_ms=q[10],visual_tracker_held_box=[v/1000 for v in box],
                        visual_tracker_max_misses=q[15])
            if len(payload)>=680 and self._telemetry.get('servo_supported') and self._telemetry.get('register_version') in (0x10008,0x10009):
                q=struct.unpack_from('!16I',payload,616)
                minimum=20 if self._telemetry['register_version']==0x10009 else 60
                if (q[0:3]==(0x53525636,1,1) and 1500<q[4]<=2000 and 1000<=q[5]<1500 and
                    all(minimum<=v<=300 and v%20==0 for v in q[6:8]) and
                    q[8:13]==(1000,2000,minimum,300,20) and q[13] in (0,1) and q[14] in (0,1) and q[15]==3 and
                    bool(q[13])==(q[4:6]==(1620,1330)) and
                    q[4]==self._telemetry.get('servo_left_us') and q[5]==self._telemetry.get('servo_right_us')):
                    self._telemetry.update(servo_config_supported=True,servo_config_sequence=q[3],
                        servo_left_burst_ms=q[6],servo_right_burst_ms=q[7],
                        servo_min_burst_ms=minimum,
                        servo_pwm_calibrated=bool(q[13]),servo_angle_estimate_valid=bool(q[14]))
            if len(payload)>=744 and self._telemetry.get('servo_config_supported') and self._telemetry.get('register_version')==0x10009:
                q=struct.unpack_from('!16I',payload,680)
                if (q[:3]==(0x53525637,1,1) and q[3]==self._telemetry['servo_config_sequence'] and
                    q[4] in (0,1) and 60<=q[5]<=960 and all(20<=v<=300 and v%20==0 for v in q[6:8]) and
                    q[8:12]==(48,20,300,20) and q[12]<=2 and q[15]==0 and
                    q[13]==self._telemetry['servo_left_burst_ms'] and q[14]==self._telemetry['servo_right_burst_ms'] and
                    (not q[4] or (q[6]<=q[13] and q[7]<=q[14]))):
                    self._telemetry.update(servo_visual_config_supported=True,servo_near_enabled=bool(q[4]),
                        servo_near_threshold_px=q[5],servo_near_left_ms=q[6],servo_near_right_ms=q[7],
                        servo_center_deadband_px=q[8],servo_visual_last_band=q[12])
            if self._telemetry.get('register_version')==0x10009 and not self._telemetry.get('servo_visual_config_supported'):
                self._telemetry.pop('servo_config_supported',None)
            if len(payload)>=792 and self._telemetry.get('visual_tracker_supported'):
                q=struct.unpack_from('!12I',payload,744)
                if (q[:2]==(0x54524b34,1) and q[2]<=100 and q[3]<=3 and q[4]<=3 and
                    q[5]<=100 and q[6]<=7 and q[9:11]==(2,3)):
                    self._telemetry.update(visual_target_selection_supported=True,
                        visual_target_candidates=q[2],visual_target_pending_hits=q[3],
                        visual_target_unsupported=q[4],visual_target_selected=q[5],
                        visual_target_decision=q[6],visual_target_switches=q[7],
                        visual_target_rejected=q[8],visual_target_batch_sequence=q[11])
            if self._telemetry.get('register_version')==0x1000a:
                position_valid=False
                if len(payload)>=840 and self._telemetry.get('servo_supported'):
                    q=struct.unpack_from('!12I',payload,792)
                    position_valid=(q[:3]==(0x53525638,1,1) and 540<=q[3]<=2480 and
                        q[4:7]==(1440,540,2480) and 0<=q[7]<=360000 and q[8] in (0,1) and
                        q[9:12]==(10,100,2) and
                        abs(q[7]/1000-180-self._telemetry.get('servo_estimated_pan',1000))<.002)
                    if position_valid:
                        self._telemetry.update(servo_position_supported=True,servo_pan_us=q[3],
                            servo_pan_center_us=q[4],servo_pan_min_us=q[5],servo_pan_max_us=q[6],
                            servo_camera_angle_deg=q[7]/1000,servo_homing=bool(q[8]),
                            servo_home_step_us=q[9],servo_home_interval_ms=q[10],servo_pan_angle_ratio=q[11],
                            servo_angle_source='commanded_position',servo_pwm_calibrated=True,
                            servo_angle_estimate_valid=True,servo_reference_valid=True,
                            servo_limit_policy='positional',servo_position_min_deg=-180,
                            servo_position_max_deg=180)
                if not position_valid:
                    self._telemetry.update(servo_supported=False,sound_tracking_supported=False)
            self._telemetry['sd_record']=decode_sd_record_status(payload)
            self._telemetry_ns = now_ns
            # Only the M39 tuning state is ordered here; existing video/result
            # presentation retains its established independent data paths.
            accepted_tuning_status = self._visual_tuning.accept_status(
                payload, now_ns, packet_boot, packet_sequence,
                compatible=bool(self._telemetry.get('servo_supported') and
                                self._telemetry.get('servo_position_supported')))
            if accepted_tuning_status:
                self._visual_tuning_feedback = dict(self._telemetry)
                self._visual_tuning_feedback_ns = now_ns
            self._visual_feedforward.accept_status(
                payload, now_ns, packet_boot, packet_sequence,
                compatible=bool(self._telemetry.get('servo_supported') and
                                self._telemetry.get('servo_position_supported')))
            accepted_audio_status = self._audio_tuning.accept_status(
                payload, now_ns, packet_boot, packet_sequence,
                compatible=bool(self._telemetry.get('servo_supported') and
                                self._telemetry.get('servo_position_supported')))
            if accepted_audio_status:
                self._audio_tuning_feedback = dict(self._telemetry)
                self._audio_tuning_feedback_ns = now_ns
            self._scan_preview_tuning.accept_status(
                payload, now_ns, packet_boot, packet_sequence,
                compatible=bool(self._telemetry.get('servo_supported') and
                                self._telemetry.get('servo_position_supported')))
            # Timing is independent of the PL PWM/servo capability gate.
            self._audio_round_tuning.accept_status(payload, now_ns, packet_boot, packet_sequence)

    def send_visual_feedforward(self, values) -> None:
        if self._control_socket is None:
            raise RuntimeError('控制端口未打开')
        with self._lock:
            self._visual_feedforward_request = (self._visual_feedforward_request + 1) & 0xffffffff or 1
            request = self._visual_feedforward_request
            payload = self._visual_feedforward.begin(values, request, time.monotonic_ns())
        try:
            self._send_control_payload(VISUAL_FEEDFORWARD_COMMAND, payload, None)
        except (RuntimeError, OSError):
            with self._lock:
                self._visual_feedforward.send_failed(request)
            raise

    def read_visual_feedforward(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            return self._visual_feedforward.read_current(time.monotonic_ns())

    def resync_visual_feedforward(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            self._visual_feedforward.resync()

    def send_audio_round_tuning(self, values) -> None:
        if self._control_socket is None:
            raise RuntimeError('控制端口未打开')
        with self._lock:
            self._audio_round_tuning_request = (self._audio_round_tuning_request + 1) & 0xffffffff or 1
            request = self._audio_round_tuning_request
            payload = self._audio_round_tuning.begin(values, request, time.monotonic_ns())
        try:
            self._send_control_payload(AUDIO_ROUND_TUNING_COMMAND, payload, None)
        except (RuntimeError, OSError):
            with self._lock:
                self._audio_round_tuning.send_failed(request)
            raise

    def read_audio_round_tuning(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            return self._audio_round_tuning.read_current(time.monotonic_ns())

    def resync_audio_round_tuning(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            self._audio_round_tuning.resync()

    def send_scan_preview_tuning(self, values) -> None:
        if self._control_socket is None:
            raise RuntimeError('控制端口未打开')
        with self._lock:
            self._scan_preview_tuning_request = (self._scan_preview_tuning_request + 1) & 0xffffffff or 1
            request = self._scan_preview_tuning_request
            payload = self._scan_preview_tuning.begin(values, request, time.monotonic_ns())
        try:
            self._send_control_payload(SCAN_PREVIEW_TUNING_COMMAND, payload, None)
        except (RuntimeError, OSError):
            with self._lock:
                self._scan_preview_tuning.send_failed(request)
            raise

    def read_scan_preview_tuning(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            return self._scan_preview_tuning.read_current(time.monotonic_ns())

    def resync_scan_preview_tuning(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            self._scan_preview_tuning.resync()

    def send_audio_tuning(self, values) -> None:
        if self._control_socket is None:
            raise RuntimeError('控制端口未打开')
        with self._lock:
            self._audio_tuning_request = (self._audio_tuning_request + 1) & 0xffffffff or 1
            request = self._audio_tuning_request
            payload = self._audio_tuning.begin(values, request, time.monotonic_ns())
        try:
            self._send_control_payload(AUDIO_TUNING_COMMAND, payload, None)
        except (RuntimeError, OSError):
            with self._lock:
                self._audio_tuning.send_failed(request)
            raise

    def read_audio_tuning(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            return self._audio_tuning.read_current(time.monotonic_ns())

    def resync_audio_tuning(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            self._audio_tuning.resync()
            self._audio_tuning_feedback = {}
            self._audio_tuning_feedback_ns = None

    def send_visual_tuning(self, values) -> None:
        if self._control_socket is None:
            raise RuntimeError('控制端口未打开')
        with self._lock:
            self._visual_tuning_request = (self._visual_tuning_request + 1) & 0xffffffff or 1
            request = self._visual_tuning_request
            payload = self._visual_tuning.begin(values, request, time.monotonic_ns())
        try:
            # Generic CONTROL_REPLY only confirms receipt. The panel waits for
            # SRV9 request identity, applied revision AND exact parameter echo.
            self._send_control_payload(VISUAL_TUNING_COMMAND, payload, None)
        except (RuntimeError, OSError):
            with self._lock:
                self._visual_tuning.send_failed(request)
            raise

    def read_visual_tuning(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            return self._visual_tuning.read_current(time.monotonic_ns())

    def resync_visual_tuning(self):
        with self._lock:
            if self._control_socket is None:
                raise RuntimeError('控制端口未打开')
            self._visual_tuning.resync()
            self._visual_tuning_feedback = {}
            self._visual_tuning_feedback_ns = None

    def send_control(self, command: int, value: int, label: str) -> None:
        self._send_control_payload(command,struct.pack('!B',value),label)

    def send_manual_focus(self, position: int) -> None:
        if not isinstance(position,int) or isinstance(position,bool) or not 0<=position<=1023:
            raise ValueError('镜头码值必须是0–1023的整数，不是距离')
        self._send_control_payload(12,struct.pack('!H',position),f'手动调焦 {position}')

    def send_servo_tilt(self, pulse_us: int) -> None:
        if not isinstance(pulse_us,int) or isinstance(pulse_us,bool) or not 540<=pulse_us<=2281:
            raise ValueError('俯仰脉宽须在540–2281 µs内，每次最多改变20 µs')
        self._send_control_payload(14,struct.pack('!H',pulse_us),f'俯仰 {pulse_us} µs')

    def send_servo_keepalive(self) -> None:
        self._send_control_payload(16,b'\x01',None)

    def send_servo_config(self,left_us:int,right_us:int,left_ms:int,right_ms:int) -> None:
        values=(left_us,right_us,left_ms,right_ms)
        if any(not isinstance(v,int) or isinstance(v,bool) for v in values):
            raise ValueError('PWM和时长必须填写整数')
        if not (1500<left_us<=2000 and 1000<=right_us<1500):
            raise ValueError('左PWM范围1501–2000 µs，右PWM范围1000–1499 µs')
        if any(v<20 or v>300 or v%20 for v in (left_ms,right_ms)):
            raise ValueError('持续时间须为20–300 ms，且是20 ms的整数倍')
        self._send_control_payload(18,struct.pack('!4H',*values),'应用左右PWM与时长（停止追踪）')

    def send_servo_visual_config(self,left_us,right_us,left_ms,right_ms,enabled,threshold_px,left_near_ms,right_near_ms):
        values=(left_us,right_us,left_ms,right_ms,enabled,threshold_px,left_near_ms,right_near_ms)
        if any(type(v) is not int for v in values):raise ValueError('参数必须填写整数')
        if not (1500<left_us<=2000 and 1000<=right_us<1500):raise ValueError('左右PWM范围不合法')
        if enabled not in (0,1) or not 60<=threshold_px<=960:raise ValueError('分档开关或阈值不合法（60–960原图像素）')
        if any(v<20 or v>300 or v%20 for v in (left_ms,right_ms,left_near_ms,right_near_ms)):
            raise ValueError('持续时间须为20–300 ms，且是20 ms的整数倍')
        if enabled and (left_near_ms>left_ms or right_near_ms>right_ms):raise ValueError('近档时长不能大于对应远档时长')
        self._send_control_payload(19,struct.pack('!8H',*values),'应用左右PWM与时长（停止追踪）')

    def send_image_policy(self, policy: int, box=None) -> None:
        if policy not in range(4):raise ValueError('无效裁剪模式')
        box=tuple(box or (0,0,0,0))
        if len(box)!=4 or (policy>=2 and not (0<=box[0]<box[2]<=1920 and 0<=box[1]<box[3]<=1080 and box[2]-box[0]>=16 and box[3]-box[1]>=16)):
            raise ValueError('请在视频中框选完整鸟身，宽高至少16个原始像素')
        label=['整图分类','自动小鸟裁剪','手动鸟框（独立视觉）','同帧整图/鸟框对照（独立视觉）'][policy]
        self._send_control_payload(8,struct.pack('!B4H',policy,*box),label)

    def _send_control_payload(self,command:int,value:bytes,label:str) -> None:
        if self._control_socket is None:raise RuntimeError('控制端口未打开')
        with self._lock:
            self._control_sequence=(self._control_sequence+1)&0xffffffff
            sequence=self._control_sequence
            self._control_pending[sequence]=label
            while len(self._control_pending)>16:self._control_pending.pop(next(iter(self._control_pending)))
            if label:self._control_message=f'{label}: 等待板端确认'
        payload=struct.pack('!HHI',command,len(value),sequence)+value
        self._control_socket.sendto(build_datagram(PacketType.CONTROL,0,sequence,0,payload),('192.168.7.20',15004))

    def save_frame(self, directory: Path) -> Path:
        from PIL import Image
        from .video import rgb565_to_rgb888
        with self._lock:frame=self._last_complete_frame
        if frame is None:raise RuntimeError('尚无完整图像')
        directory.mkdir(parents=True,exist_ok=True)
        base=directory/f'frame_{frame.boot_id:08x}_{frame.frame_id}_{time.time_ns()}'
        base.with_suffix('.rgb565').write_bytes(frame.rgb565)
        Image.fromarray(rgb565_to_rgb888(frame.rgb565)).save(base.with_suffix('.png'))
        base.with_suffix('.json').write_text(json.dumps(dict(boot_id=frame.boot_id,frame_id=frame.frame_id,timestamp_us=frame.timestamp_us)),encoding='utf-8')
        return base.with_suffix('.png')

    def snapshots(self) -> tuple[CompletedFrame | None, dict[str, Any], ReceiverStats]:
        with self._lock:
            frame = self._latest_frame
            self._latest_frame = None
            telemetry = dict(self._telemetry)
            telemetry['ssd_preview']=dict(self._ssd_preview) if self._ssd_preview else None
            telemetry['ssd_preview_age_s']=(time.monotonic_ns()-self._ssd_preview_ns)/1e9 if self._ssd_preview_ns else float('inf')
            telemetry["online"] = bool(self.stats.last_packet_ns and
                                       time.monotonic_ns() - self.stats.last_packet_ns < 1_000_000_000)
            telemetry['telemetry_age_s']=(time.monotonic_ns()-self._telemetry_ns)/1e9 if self._telemetry_ns else float('inf')
            now=time.monotonic_ns()
            recent=[t for t in self._frame_times if now-t<3_000_000_000]
            telemetry['received_fps']=(len(recent)-1)*1e9/(recent[-1]-recent[0]) if len(recent)>1 else 0.
            telemetry['video_last_second_frames'] = sum(0 <= now-t < 1_000_000_000 for t in self._frame_times)
            telemetry['video_assembly_progress'] = self.video.progress(now)
            telemetry['port_packets'] = dict(self.stats.port_packets)
            telemetry['port_last_packet_age_s'] = {
                port: max(0, now-last)/1e9 for port, last in self.stats.port_last_packet_ns.items()}
            telemetry['diagnostic_io_dropped'] = self.stats.io_dropped
            telemetry['diagnostic_io_errors'] = self.stats.snapshot_errors
            telemetry['diagnostic_io_pending'] = self._io_queue.qsize()+int(self._io_active)
            complete = self._last_complete_frame
            telemetry['video_frame_identity'] = (dict(boot_id=complete.boot_id,
                frame_id=complete.frame_id, timestamp_us=complete.timestamp_us)
                if complete else None)
            telemetry['video_assembly_loss']=self.video.network_loss
            telemetry['video_duplicate_fragments']=self.video.duplicates
            telemetry['video_rejected_fragments']=self.video.rejected
            telemetry['control_message']=self._control_message
            telemetry['visual_tuning']=self._visual_tuning.snapshot(
                now, control_open=self._control_socket is not None)
            telemetry['visual_feedforward']=self._visual_feedforward.snapshot(
                now, control_open=self._control_socket is not None)
            telemetry['visual_tuning_feedback']=dict(self._visual_tuning_feedback)
            telemetry['visual_tuning_feedback']['telemetry_age_s']=(
                (now-self._visual_tuning_feedback_ns)/1e9
                if self._visual_tuning_feedback_ns is not None else float('inf'))
            telemetry['audio_tuning']=self._audio_tuning.snapshot(
                now, control_open=self._control_socket is not None)
            telemetry['audio_round_tuning']=self._audio_round_tuning.snapshot(
                now, control_open=self._control_socket is not None)
            telemetry['scan_preview_tuning']=self._scan_preview_tuning.snapshot(
                now, control_open=self._control_socket is not None)
            telemetry.update(self._video_health.snapshot(now, preview_stale_after_s(telemetry)))
            telemetry['audio_tuning_feedback']=dict(self._audio_tuning_feedback)
            telemetry['audio_tuning_feedback']['telemetry_age_s']=(
                (now-self._audio_tuning_feedback_ns)/1e9
                if self._audio_tuning_feedback_ns is not None else float('inf'))
            stats = ReceiverStats(self.stats.packets, self.stats.malformed,
                                  self.stats.wrong_type, self.stats.pcm_gaps,
                                  self.stats.last_packet_ns,
                                  dict(self.stats.socket_buffer_bytes),
                                  self.stats.snapshot_errors, self.stats.fusion_packets,
                                  self.stats.fusion_errors, self.stats.video_frames,
                                  dict(self.stats.port_packets), dict(self.stats.port_last_packet_ns),
                                  self.stats.io_dropped)
        return frame, telemetry, stats
