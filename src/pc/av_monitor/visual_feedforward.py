"""M47 independent RAM-only motion feedforward transaction and estimate readback.

Angle scales are online conversion settings, not a measured camera field of view.
All positions and velocities are software estimates without encoder feedback.
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
import math
import struct

COMMAND = 27
SCHEMA = 1
MAGIC = 0x56464631
OFFSET = 1256
EXTENSION_BYTES = 128
STATUS_BYTES = 1384
FRESH_NS = 1_000_000_000
ACK_TIMEOUT_NS = 2_000_000_000
DEFAULTS = (0., 55., .3, .3, 5., 3., 120., 1.)
NAMES = ("水平角度换算系数", "竖直角度换算系数", "水平前馈增益", "竖直前馈增益",
         "水平前馈上限", "竖直前馈上限", "速度滤波时间常数", "速度死区")
BOUNDS = ((0.,360.), (0.,180.), (0.,1.), (0.,1.), (0.,60.), (0.,60.), (20.,1000.), (0.,10.))
ACK_NAMES = {2:"协议版本不匹配", 3:"板卡已重新启动", 4:"参数修订冲突",
             5:"参数数值不合法", 6:"请求编号冲突", 8:"PL PWM 接口不兼容"}
RESET_NAMES = ("无", "初始化或历史不足", "时钟或时间异常", "间隔过大或过期",
               "目标框或尺度跳变", "方向反转", "目标丢失或控制重置", "新参数")


def _f32(value):
    return struct.unpack("!f", struct.pack("!f", value))[0]


def canonical_values(values, *, from_wire=False):
    if len(values) != 8:
        raise ValueError("需要同时填写运动前馈共 8 个参数")
    result = []
    for name, value, (low, high) in zip(NAMES, values, BOUNDS):
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
            raise ValueError(name+"须为有限数值")
        if not low <= value <= high:
            raise ValueError(f"{name}范围为 {low:g}～{high:g}")
        result.append(_f32(value))
    return tuple(result)


def value_bytes(values):
    return struct.pack("!8f", *canonical_values(values, from_wire=True))


def draft_values(texts):
    if len(texts) != 8:
        raise ValueError("需要填写 8 个运动前馈参数")
    try:
        values = tuple(float(text) for text in texts)
    except (TypeError, ValueError, OverflowError) as exc:
        raise ValueError("前馈参数须填写有限数字") from exc
    return canonical_values(values)


def display_values(values):
    result = []
    for value in values:
        for precision in range(1, 11):
            text = format(value, f".{precision}g")
            if "e" in text.lower() and abs(value) >= .0001:
                text = format(Decimal(text), "f")
            if _f32(float(text)) == _f32(value):
                break
        result.append(text)
    return tuple(result)


def encode_request(boot_id, revision, request_id, values):
    if any(type(value) is not int or not 1 <= value <= 0xffffffff
           for value in (boot_id, revision, request_id)):
        raise ValueError("启动号、修订号或请求号不合法")
    return struct.pack("!BIII8f", SCHEMA, boot_id, revision, request_id,
                       *canonical_values(values, from_wire=True))


@dataclass(frozen=True)
class Readback:
    boot_id: int
    revision: int
    ack_request: int
    ack_status: int
    values: tuple[float, ...]
    apply_count: int
    flags: int
    pan_velocity: float
    tilt_velocity: float
    pan_ff: float
    tilt_ff: float
    observation_age_ms: int
    pan_pairs: int
    tilt_pairs: int
    reset_reason: int
    pan_p_rate: float
    tilt_p_rate: float
    pan_total_rate: float
    tilt_total_rate: float
    source_sequence: int


def decode_readback(payload, *, packet_boot=None):
    if len(payload) < STATUS_BYTES:
        return None
    words = struct.unpack_from("!6I8f2I4f4I4f4I", payload, OFFSET)
    magic, version, revision, request, status, boot = words[:6]
    if (magic != MAGIC or version != SCHEMA or not boot or not revision or status > 8 or
            words[15] & ~127 or words[23] > 7 or any(words[29:32]) or
            (packet_boot is not None and boot != packet_boot) or
            not all(math.isfinite(value) for value in (*words[16:20], *words[24:28]))):
        return None
    try:
        values = canonical_values(words[6:14], from_wire=True)
    except ValueError:
        return None
    return Readback(boot, revision, request, status, values, *words[14:29])


@dataclass(frozen=True)
class Pending:
    boot_id: int
    expected_revision: int
    request_id: int
    values: tuple[float, ...]
    sent_ns: int


class TuningState:
    """Ordered independent transaction. Caller serializes access with a lock."""
    def __init__(self):
        self.current = None
        self.received_ns = None
        self.boot_id = None
        self.packet_sequence = None
        self.retired_boots = set()
        self.pending = None
        self.message = "等待支持 M47 运动前馈的板端状态"
        self._supported = False
        self._compatible = False
        self._verified_revision = None

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
        if current and self.current and boot == self.boot_id:
            if current.revision < self.current.revision:
                return False
            if (current.revision == self.current.revision and
                    value_bytes(current.values) != value_bytes(self.current.values)):
                return False
        changed_boot = self.boot_id is not None and boot != self.boot_id
        if changed_boot:
            self.retired_boots.add(self.boot_id)
            self._verified_revision = None
            self.message = "板卡已重新启动；"
            if self.pending:
                self.message += "先前请求不再沿用；"
            self.pending = None
            if current:
                self.message += f"已读取新启动前馈参数 · 启动 {boot} · 修订 {current.revision}"
        self.boot_id = boot
        self.packet_sequence = packet_sequence
        self.current = current
        self.received_ns = now_ns
        self._supported = current is not None
        self._compatible = compatible
        if not current:
            self.pending = None
            self._verified_revision = None
            self.message = ("板卡已重新启动；" if changed_boot else "")+"当前固件未提供 M47 运动前馈完整参数"
            return True
        if self._verified_revision is not None and self._verified_revision != current.revision:
            self._verified_revision = None
            self.message = "板端已由其他请求更新；请读取当前参数"
        pending = self.pending
        if pending and current.ack_request == pending.request_id:
            if current.ack_status in (1, 7):
                if (current.revision == pending.expected_revision + 1 and
                        value_bytes(current.values) == value_bytes(pending.values)):
                    self._verified_revision = current.revision
                    self.message = f"板端已应用并回读一致 · 前馈修订 {current.revision}"
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
            self.message = f"已读取板端前馈参数 · 修订 {current.revision}"
        return True

    def ready(self, now_ns):
        return bool(self._supported and self._compatible and self.current and self.received_ns is not None and
                    0 <= now_ns - self.received_ns <= FRESH_NS)

    def begin(self, values, request_id, now_ns):
        values = canonical_values(values, from_wire=True)
        if not self.ready(now_ns):
            raise RuntimeError("板端状态过期或固件不支持前馈在线调参")
        if self.pending:
            raise RuntimeError("上次请求尚未确认；请等待或点击读取当前参数")
        current = self.current
        wire = encode_request(current.boot_id, current.revision, request_id, values)
        self._verified_revision = None
        self.pending = Pending(current.boot_id, current.revision, request_id, values, now_ns)
        self.message = "已发送一次前馈请求，等待板端确认及参数回读"
        return wire

    def send_failed(self, request_id):
        if self.pending and self.pending.request_id == request_id:
            self.message = "发送未完成，结果未知；请读取当前参数后再决定是否应用"

    def read_current(self, now_ns):
        if not self.ready(now_ns):
            raise RuntimeError("没有新鲜的板端前馈参数回读")
        self.pending = None
        self.message = f"已读取当前前馈参数 · 修订 {self.current.revision}"
        return self.current.values

    def resync(self):
        self.__init__()
        self.message = "等待重新同步后的板端状态；此前未确认请求的结果未知，未重发参数"

    def snapshot(self, now_ns, *, control_open=True):
        ready = self.ready(now_ns) and control_open
        message = self.message
        if not control_open:
            message = "控制端口未打开，前馈在线调参不可用"
        elif self._supported and not self._compatible:
            message = "PL PWM 接口未就绪，禁止应用；需要配套硬件与固件"
        elif not self.ready(now_ns) and self._supported:
            message = "板端前馈参数回读已过期，暂停应用；等待重新连接"
        elif (self.pending and now_ns - self.pending.sent_ns > ACK_TIMEOUT_NS and
              message.startswith("已发送")):
            message = "确认等待超过 2 秒，结果未知；请读取当前参数，未自动重发"
        current = self.current
        view = dict(current.__dict__) if current else dict(boot_id=self.boot_id, revision=None,
                                                          values=None, apply_count=None)
        view.update(supported=self._supported, ready=ready, control_open=control_open, message=message,
                    pending=self.pending is not None,
                    age_s=(now_ns-self.received_ns)/1e9 if self.received_ns is not None else float("inf"))
        return view
