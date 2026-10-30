"""M43 atomic RAM-only sound tuning and ordered, verified board readback.

Opening a panel and editing a draft are read-only. These values preserve the
M42 defaults; application itself neither moves a servo nor renews its lease.
"""
from __future__ import annotations

from dataclasses import dataclass
import math
import struct

COMMAND = 24
SCHEMA = 1
MAGIC = 0x534e4432
OFFSET = 904
EXTENSION_BYTES = 64
STATUS_BYTES = OFFSET + EXTENSION_BYTES
FRESH_NS = 1_000_000_000
ACK_TIMEOUT_NS = 2_000_000_000
DEFAULTS = (80., 4., 1024., 12., 300., 600., 15., 100.)
NAMES = ("鸟声置信度门槛", "能量与底噪比", "最低定位质量", "方向允许抖动",
         "首次稳定时间", "重定向稳定时间", "重定向最小角差", "寻向指令变化率")
BOUNDS = ((1.,99.), (2.,16.), (513.,16384.), (2.,30.),
          (300.,1500.), (600.,1500.), (3.,45.), (5.,120.))
INTEGER_INDICES = frozenset((0,2,4,5))
ACK_NAMES = {2:"协议版本不匹配", 3:"板卡已重新启动", 4:"参数修订冲突",
             5:"参数数值不合法", 6:"请求编号冲突", 8:"PL PWM 接口不兼容"}


def _f32(value):
    return struct.unpack("!f", struct.pack("!f", value))[0]


def canonical_values(values, *, from_wire=False):
    """Reject an incomplete/invalid group before producing float32 wire values."""
    if len(values) != 8:
        raise ValueError("需要同时填写声音定位与寻向共 8 个参数")
    result = []
    for index, (name, value, (low, high)) in enumerate(zip(NAMES, values, BOUNDS)):
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError(name+"须为有限数值")
        if from_wire:
            low, high = _f32(low), _f32(high)
        if not math.isfinite(value) or not low <= value <= high:
            raise ValueError(f"{name}范围为 {low:g}～{high:g}")
        if index in INTEGER_INDICES and value != int(value):
            raise ValueError(name+"须填写整数")
        result.append(_f32(value))
    if result[5] < result[4]:
        raise ValueError("重定向稳定时间必须大于或等于首次稳定时间")
    return tuple(result)


def value_bytes(values):
    return struct.pack("!8f", *canonical_values(values, from_wire=True))


def draft_values(texts):
    if len(texts) != 8:
        raise ValueError("需要填写 8 个参数")
    try:
        values = tuple(float(value) for value in texts)
    except (TypeError, ValueError, OverflowError) as exc:
        raise ValueError("参数须填写有限数字；单位按表中标注") from exc
    return canonical_values(values)


def display_values(values):
    # Ordinary values stay readable, arbitrary float32 readbacks round-trip.
    result = []
    for value in values:
        for precision in range(1, 10):
            text = format(value, f".{precision}g")
            if "e" in text.lower():
                text = format(float(text), ".9f").rstrip("0").rstrip(".")
            if _f32(float(text)) == _f32(value):
                break
        result.append(text)
    return tuple(result)


def encode_request(boot_id, revision, request_id, values):
    if any(type(v) is not int or not 0 <= v <= 0xffffffff
           for v in (boot_id, revision, request_id)) or not all((boot_id, revision, request_id)):
        raise ValueError("启动号、修订号或请求号不合法")
    values = canonical_values(values, from_wire=True)
    # The outer AVP1 control header carries command 24. The firmware decoder
    # prepends that command to these 45 bytes for its 46-byte dispatch input.
    return struct.pack("!BIII8f", SCHEMA, boot_id, revision, request_id, *values)


@dataclass(frozen=True)
class Readback:
    boot_id: int
    revision: int
    ack_request: int
    ack_status: int
    values: tuple[float, ...]
    apply_count: int


def decode_readback(payload, *, packet_boot=None):
    if len(payload) < STATUS_BYTES:
        return None
    magic, version, revision, request, status, boot, *tail = struct.unpack_from(
        "!6I8f2I", payload, OFFSET)
    if (magic != MAGIC or version != SCHEMA or not boot or not revision or status > 8 or
            tail[9] != 0 or (packet_boot is not None and boot != packet_boot)):
        return None
    try:
        values = canonical_values(tail[:8], from_wire=True)
    except ValueError:
        return None
    return Readback(boot, revision, request, status, values, tail[8])


@dataclass(frozen=True)
class Pending:
    boot_id: int
    expected_revision: int
    request_id: int
    values: tuple[float, ...]
    sent_ns: int


class TuningState:
    """Ordered, non-retrying state machine. Caller serializes access with a lock."""

    def __init__(self):
        self.current = None
        self.received_ns = None
        self.boot_id = None
        self.packet_sequence = None
        self.retired_boots = set()
        self.pending = None
        self.message = "等待支持在线调参的板端状态"
        self._supported = False
        self._compatible = False

    def accept_status(self, payload, now_ns, packet_boot=None, packet_sequence=None, *, compatible=True):
        if len(payload) < 48:
            return False
        prefix_boot = struct.unpack_from("!I", payload, 12)[0]
        boot = prefix_boot if packet_boot is None else packet_boot
        if boot != prefix_boot or boot in self.retired_boots:
            return False
        if self.boot_id == boot and packet_sequence is not None and self.packet_sequence is not None:
            delta = (packet_sequence - self.packet_sequence) & 0xffffffff
            if not 0 < delta < 0x80000000:
                return False
        current = decode_readback(payload, packet_boot=boot)
        if (current and self.current and boot == self.boot_id and
                current.revision < self.current.revision):
            return False
        if (current and self.current and boot == self.boot_id and
                current.revision == self.current.revision and
                value_bytes(current.values) != value_bytes(self.current.values)):
            return False
        changed_boot = self.boot_id is not None and boot != self.boot_id
        if changed_boot:
            self.retired_boots.add(self.boot_id)
            if self.pending:
                self.message = "板卡已重新启动，先前请求不再沿用；请读取当前参数"
                self.pending = None
        self.boot_id = boot
        self.packet_sequence = packet_sequence
        self.current = current
        self.received_ns = now_ns
        self._supported = current is not None
        self._compatible = compatible
        if not current:
            self.pending = None
            self.message = "当前固件未提供 M43 声音寻向在线参数"
            return True
        pending = self.pending
        if pending and current.ack_request == pending.request_id:
            if current.ack_status in (1, 7):
                if (current.revision == pending.expected_revision + 1 and
                        value_bytes(current.values) == value_bytes(pending.values)):
                    self.message = f"板端已应用并回读一致 · 修订 {current.revision}"
                else:
                    self.message = "请求已处理，但当前参数与本次请求不同；请读取当前参数"
                self.pending = None
            elif current.ack_status in ACK_NAMES:
                self.message = "板端拒绝："+ACK_NAMES[current.ack_status]+"；请读取当前参数"
                self.pending = None
        elif pending and current.revision > pending.expected_revision:
            self.message = "板端已由其他请求更新；本次结果未知，请读取当前参数"
            self.pending = None
        elif not pending and self.message.startswith("等待"):
            self.message = f"已读取板端参数 · 修订 {current.revision}"
        return True

    def ready(self, now_ns):
        return bool(self._supported and self._compatible and self.current and self.received_ns is not None and
                    0 <= now_ns - self.received_ns <= FRESH_NS)

    def begin(self, values, request_id, now_ns):
        values = canonical_values(values, from_wire=True)
        if not self.ready(now_ns):
            raise RuntimeError("板端状态过期或固件不支持在线调参")
        if self.pending:
            raise RuntimeError("上次请求尚未确认；请等待或点击读取当前参数")
        current = self.current
        wire = encode_request(current.boot_id, current.revision, request_id, values)
        self.pending = Pending(current.boot_id, current.revision, request_id, values, now_ns)
        self.message = "已发送一次请求，等待板端确认及参数回读"
        return wire

    def send_failed(self, request_id):
        if self.pending and self.pending.request_id == request_id:
            self.message = "发送未完成，结果未知；请读取当前参数后再决定是否应用"

    def read_current(self, now_ns):
        if not self.ready(now_ns):
            raise RuntimeError("没有新鲜的板端参数回读")
        self.pending = None
        self.message = f"已读取当前参数 · 修订 {self.current.revision}"
        return self.current.values

    def resync(self):
        # Boot IDs are nonces, not chronological counters. Explicitly forget
        # the local boot history if an unseen delayed session displaced it.
        # This performs no write and never replays an unconfirmed request.
        self.__init__()
        self.message = "等待重新同步后的板端状态；此前未确认请求的结果未知，未重发参数"

    def snapshot(self, now_ns, *, control_open=True):
        ready = self.ready(now_ns) and control_open
        message = self.message
        if not control_open:
            message = "控制端口未打开，在线调参不可用"
        elif self._supported and not self._compatible:
            message = "PL PWM 接口未就绪，禁止应用；需要配套硬件与固件"
        elif not self.ready(now_ns) and self._supported:
            message = "板端参数回读已过期，暂停应用；等待重新连接"
        elif (self.pending and now_ns - self.pending.sent_ns > ACK_TIMEOUT_NS and
              message.startswith("已发送")):
            message = "确认等待超过 2 秒，结果未知；请读取当前参数，未自动重发"
        current = self.current
        return dict(supported=self._supported, ready=ready, control_open=control_open, message=message,
                    pending=self.pending is not None,
                    boot_id=current.boot_id if current else self.boot_id,
                    revision=current.revision if current else None,
                    values=current.values if current else None,
                    apply_count=current.apply_count if current else None,
                    age_s=(now_ns-self.received_ns)/1e9 if self.received_ns is not None else float("inf"))


def feedback_text(telemetry, tuning):
    """Describe accepted instructions and gating evidence without encoder claims."""
    if (not tuning.get("ready") or telemetry.get("boot_id") != tuning.get("boot_id") or
            telemetry.get("telemetry_age_s", float("inf")) > 1):
        return "等待同一启动会话的新鲜声音与控制状态。"
    state = {0:"已关闭", 1:"等待有效鸟声方位", 2:"等待转动后重新采集的声音",
             3:"已朝向声源指令方位", 4:"视觉接管", 5:"位置边界", 6:"等待位置调节间隔",
             7:"限速转向声源", 8:"心跳超时", 9:"缓慢归中", 10:"竖直扫描找鸟",
             11:"候选鸟框暂停扫描"}
    text = (f"声音寻向状态：{state.get(telemetry.get('sound_tracking_state'), '等待状态')}；"
            f"目标方位指令 {telemetry.get('sound_tracking_angle_deg', 0):+.1f}°。\n"
            f"已接受位置指令：水平 {telemetry.get('servo_estimated_pan', 0):+.1f}° / "
            f"{telemetry.get('servo_pan_us', '—')} μs；竖直 {telemetry.get('servo_tilt_us', '—')} μs。"
            "无编码器，以上不是实际角度或速度反馈。")
    rms = telemetry.get("mic_rms")
    if rms and len(rms) == 4:
        text += "\n四麦 RMS：" + " / ".join(f"{value:.4g}" for value in rms)
    score = telemetry.get("direction_bird_confidence")
    if score is not None:
        text += f"；最近鸟声置信度 {score:.1%}"
    return text

