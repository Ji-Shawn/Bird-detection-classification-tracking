"""Read-only video freshness and VH01 diagnostics; never substitutes old frames."""
from __future__ import annotations

import math
import struct

OFFSET = 1032
STATUS_BYTES = OFFSET + 32 * 4
MAGIC = 0x56483031
STATES = {0: '正常', 1: '停帧观察', 2: '恢复摄像头', 3: '停止 DMA',
          4: '复位 DMA', 5: '配置 DMA', 6: '等待新帧', 7: '恢复冷却',
          8: '恢复失败', 9: '诊断模式暂停恢复'}
FIELDS = ('state', 'reason', 'flags', 'pl_valid_frames', 's2mm_status',
          'mm2s_status', 'write_store', 'read_store', 'last_error',
          'stall_events', 'dma_attempts', 'sensor_attempts', 'recoveries',
          'failures', 'capture_age_ms', 'copy_age_ms', 'source_age_ms',
          'current_stall_ms', 'last_recovery_ms', 'max_stall_ms', 'copy_aborts',
          'discarded_previews', 'sensor_generation', 'copy_offset',
          'video_sequence', 'startup_grace_ms', 'fault_s2mm_status',
          'fault_mm2s_status', 'round_attempts', 'suppressed_events')


def decode_health(payload):
    if len(payload) < STATUS_BYTES:
        return None
    words = struct.unpack_from('!32I', payload, OFFSET)
    if words[:2] != (MAGIC, 1) or words[2] not in STATES or words[3] > 5 or words[4] & ~0x7f:
        return None
    return dict(zip(FIELDS, words[2:]))


def decode_capture_evidence(payload):
    """VC01 GPIO probe is raw evidence; sticky seen bits are not liveness."""
    if len(payload) < STATUS_BYTES+32:
        return None
    words = struct.unpack_from('!8I', payload, STATUS_BYTES)
    if words[:2] != (0x56433031, 1):
        return None
    return dict(zip(('probe_raw', 'probe_at_observed_stall', 'service_max_us',
                     'service_calls', 'service_total_us', 'focus_state'), words[2:]))


def preview_stale_after_s(telemetry):
    """Presentation-only allowance for a verified 1--4 FPS publication limit.

    This does not extend NCC validity or change any board control decision.
    Missing or stale readback uses the established one-second default.
    """
    tuning = telemetry.get('scan_preview_tuning', {})
    values = tuning.get('values')
    if not tuning.get('ready') or not isinstance(values, (tuple, list)) or len(values) != 2:
        return 1.
    fps = values[1]
    if isinstance(fps, bool) or not isinstance(fps, (float, int)) or not math.isfinite(fps) or not 1 <= fps <= 4:
        return 1.
    return max(1., 1.5 / fps + .25)


class VideoHealth:
    def __init__(self):
        self.started_ns = None
        self.last_packet_ns = None
        self.last_complete_ns = None
        self.last_gap_ns = 0
        self.max_gap_ns = 0
        self.interruptions = 0
        self._interrupted = False

    def packet(self, now_ns):
        if self.started_ns is None:
            self.started_ns = now_ns
        self.last_packet_ns = now_ns

    def tick(self, now_ns, threshold_s):
        anchor = self.last_complete_ns if self.last_complete_ns is not None else self.started_ns
        stopped = anchor is not None and now_ns - anchor > threshold_s * 1e9
        if stopped and not self._interrupted:
            self.interruptions += 1
            self._interrupted = True
        return stopped

    def complete(self, now_ns, threshold_s):
        # Account for an interruption even if the UI was paused until recovery.
        self.tick(now_ns, threshold_s)
        if self.last_complete_ns is not None:
            self.last_gap_ns = max(0, now_ns - self.last_complete_ns)
            self.max_gap_ns = max(self.max_gap_ns, self.last_gap_ns)
        self.last_complete_ns = now_ns
        if self.started_ns is None:
            self.started_ns = now_ns
        self._interrupted = False

    def snapshot(self, now_ns, threshold_s):
        stopped = self.tick(now_ns, threshold_s)
        age = None if self.last_complete_ns is None else max(0, now_ns - self.last_complete_ns) / 1e9
        packet_age = None if self.last_packet_ns is None else max(0, now_ns - self.last_packet_ns) / 1e9
        return dict(video_last_frame_age_s=age, video_last_packet_age_s=packet_age,
                    video_stalled=stopped, video_waiting=self.last_complete_ns is None,
                    video_stale_after_s=threshold_s, video_interruptions=self.interruptions,
                    video_last_gap_s=self.last_gap_ns / 1e9,
                    video_max_gap_s=max(self.max_gap_ns / 1e9, age or 0),
                    video_no_frame_1s=age is None or age >= 1.)


def health_text(telemetry):
    age = telemetry.get('video_last_frame_age_s')
    age_text = '尚无完整帧' if age is None else f'新帧距今 {age:.2f}s'
    state = '停更' if telemetry.get('video_stalled') else '等待画面' if telemetry.get('video_waiting') else '接收中'
    text = f"视频{state} · {age_text} · 最大间隔 {telemetry.get('video_max_gap_s', 0):.2f}s"
    board = telemetry.get('video_health')
    if board:
        text += f" · 板端{STATES.get(board.get('state'), '未知')} / 恢复 {board.get('recoveries', 0)} 次"
    if telemetry.get('diagnostic_io_dropped') or telemetry.get('diagnostic_io_errors'):
        text += f" · 日志异常 {telemetry.get('diagnostic_io_errors', 0)} / 队列丢弃 {telemetry.get('diagnostic_io_dropped', 0)}"
    return text
