"""M46 independent, atomic RAM timing group with ordered board readback."""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
import struct

COMMAND = 26
SCHEMA = 1
MAGIC = 0x53525432
OFFSET = 1192
EXTENSION_BYTES = 64
STATUS_BYTES = 1256
FRESH_NS = 1_000_000_000
ACK_TIMEOUT_NS = 2_000_000_000
DEFAULTS = (3000, 3000, 8000, 5000)
NAMES = ("有效采样时长", "两次结果最小结束间隔", "结果间断重置间隔", "定位成功后暂停采样")
BOUNDS = ((1000, 5000), (1000, 10000), (2000, 30000), (0, 30000))
ACK_NAMES = {2: "协议版本不匹配", 3: "板卡已重新启动", 4: "参数修订冲突",
             5: "参数数值不合法", 6: "请求编号冲突"}


def canonical_values(values):
    if len(values) != 4:
        raise ValueError("需要同时填写采样与确认时序共 4 个参数")
    for name, value, (low, high) in zip(NAMES, values, BOUNDS):
        if type(value) is not int or not low <= value <= high:
            raise ValueError(f"{name}须为整数毫秒，范围 {low}～{high} ms")
    if values[1] < values[0]:
        raise ValueError("声音轮次最小结束间隔必须大于或等于有效采样时长")
    if values[2] <= values[1]:
        raise ValueError("声音轮次重置间隔必须严格大于最小结束间隔")
    return tuple(values)


def draft_values(texts):
    if len(texts) != 4:
        raise ValueError("需要填写 4 个时序参数")
    try:
        values = tuple(Decimal(text) * 1000 for text in texts)
        if any(not value.is_finite() or value != value.to_integral_value() for value in values):
            raise ValueError("秒数须为有限数字，最多保留 3 位小数（1 ms）")
        return canonical_values(tuple(int(value) for value in values))
    except (InvalidOperation, TypeError, OverflowError) as exc:
        raise ValueError("时序参数须填写秒数，最多保留 3 位小数（1 ms）") from exc


def display_values(values):
    return tuple(format(Decimal(value) / 1000, "f").rstrip("0").rstrip(".")
                 if value % 1000 else str(value // 1000) for value in values)


def value_bytes(values):
    return struct.pack("!4I", *canonical_values(values))


def encode_request(boot_id, revision, request_id, values):
    if any(type(value) is not int or not 1 <= value <= 0xffffffff
           for value in (boot_id, revision, request_id)):
        raise ValueError("启动号、修订号或请求号不合法")
    # AVP1 carries command 26 outside these 29 bytes; native dispatch prepends it.
    return struct.pack("!B7I", SCHEMA, boot_id, revision, request_id, *canonical_values(values))


@dataclass(frozen=True)
class Readback:
    boot_id: int
    revision: int
    ack_request: int
    ack_status: int
    values: tuple[int, ...]
    apply_count: int
    core1_observed_revision: int
    capture_samples: int
    silence_samples: int
    pause_remaining_ms: int


def decode_readback(payload, *, packet_boot=None):
    if len(payload) < STATUS_BYTES:
        return None
    magic, version, revision, request, status, boot, *tail = struct.unpack_from("!16I", payload, OFFSET)
    if (magic != MAGIC or version != SCHEMA or not boot or not revision or status > 7 or
            tail[9] != 0 or tail[5] > revision or
            (packet_boot is not None and boot != packet_boot)):
        return None
    try:
        values = canonical_values(tail[:4])
    except ValueError:
        return None
    if (not 32000 <= tail[6] <= 160000 or tail[6] % 32 or
            tail[6] + tail[7] != 160000 or
            (tail[5] == revision and tail[6] != values[0] * 32)):
        return None
    return Readback(boot, revision, request, status, values, *tail[4:9])


@dataclass(frozen=True)
class Pending:
    boot_id: int
    expected_revision: int
    request_id: int
    values: tuple[int, ...]
    sent_ns: int


class TuningState:
    """Caller holds a lock. Status can confirm Core0 before Core1 adopts it."""
    def __init__(self):
        self.current = None
        self.received_ns = None
        self.boot_id = None
        self.packet_sequence = None
        self.retired_boots = set()
        self.pending = None
        self.message = "等待支持 M46 采样与确认时序的板端状态"
        self._supported = False
        self._verified_revision = None

    def accept_status(self, payload, now_ns, packet_boot=None, packet_sequence=None):
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
            if current.revision == self.current.revision and current.values != self.current.values:
                return False
            if current.core1_observed_revision < self.current.core1_observed_revision:
                return False
        if self.boot_id is not None and boot != self.boot_id:
            self.retired_boots.add(self.boot_id)
            self._verified_revision = None
            if self.pending:
                self.message = "板卡已重新启动，先前请求不再沿用；请读取当前参数"
                self.pending = None
        self.boot_id = boot
        self.packet_sequence = packet_sequence
        self.current = current
        self.received_ns = now_ns
        self._supported = current is not None
        if not current:
            self.pending = None
            self._verified_revision = None
            self.message = "当前固件未提供 M46 采样与确认时序参数"
            return True
        if self._verified_revision is not None and self._verified_revision != current.revision:
            self._verified_revision = None
            self.message = f"板端已由其他请求更新 · 当前修订 {current.revision}；请读取当前参数"
        pending = self.pending
        if pending and current.ack_request == pending.request_id:
            if current.ack_status in (1, 7):
                if current.revision == pending.expected_revision + 1 and current.values == pending.values:
                    self._verified_revision = current.revision
                    self.message = f"Core0 已确认并回读一致 · 修订 {current.revision}"
                else:
                    self.message = "请求已处理，但当前参数与本次请求不同；请读取当前参数"
                self.pending = None
            elif current.ack_status in ACK_NAMES:
                self.message = "板端拒绝：" + ACK_NAMES[current.ack_status] + "；请读取当前参数"
                self.pending = None
        elif pending and current.revision > pending.expected_revision:
            self.message = "板端已由其他请求更新；本次结果未知，请读取当前参数"
            self.pending = None
        elif not pending and self.message.startswith("等待"):
            self.message = f"已读取板端参数 · 修订 {current.revision}"
        if (self._verified_revision == current.revision and
                current.core1_observed_revision == current.revision):
            self.message = f"板端已应用并回读一致 · Core1 已同步 · 修订 {current.revision}"
        return True

    def ready(self, now_ns):
        return bool(self._supported and self.current and self.received_ns is not None and
                    0 <= now_ns - self.received_ns <= FRESH_NS)

    def begin(self, values, request_id, now_ns):
        values = canonical_values(values)
        if not self.ready(now_ns):
            raise RuntimeError("板端状态过期或固件不支持时序在线调参")
        if self.pending:
            raise RuntimeError("上次请求尚未确认；请等待或点击读取当前参数")
        current = self.current
        wire = encode_request(current.boot_id, current.revision, request_id, values)
        self._verified_revision = None
        self.pending = Pending(current.boot_id, current.revision, request_id, values, now_ns)
        self.message = "已发送一次请求，等待板端确认及 Core1 同步"
        return wire

    def send_failed(self, request_id):
        if self.pending and self.pending.request_id == request_id:
            self.message = "发送未完成，结果未知；请读取当前参数后再决定是否应用"

    def read_current(self, now_ns):
        if not self.ready(now_ns):
            raise RuntimeError("没有新鲜的板端时序参数回读")
        self.pending = None
        self.message = f"已读取当前参数 · 修订 {self.current.revision}"
        return self.current.values

    def resync(self):
        self.__init__()
        self.message = "等待重新同步后的板端状态；此前未确认请求的结果未知，未重发参数"

    def snapshot(self, now_ns, *, control_open=True):
        ready = self.ready(now_ns) and control_open
        current = self.current
        fully_applied = bool(current and current.revision == current.core1_observed_revision)
        message = self.message
        if not control_open:
            message = "控制端口未打开，时序在线调参不可用"
        elif not self.ready(now_ns) and self._supported:
            message = "板端时序参数回读已过期，暂停应用；等待重新连接"
        elif self.pending and now_ns - self.pending.sent_ns > ACK_TIMEOUT_NS and message.startswith("已发送"):
            message = "确认等待超过 2 秒，结果未知；请读取当前参数，未自动重发"
        elif current and not fully_applied:
            message += (f" · Core1 同步中（Core0 修订 {current.revision} / "
                        f"Core1 已观测 {current.core1_observed_revision}）")
        return dict(supported=self._supported, ready=ready, control_open=control_open, message=message,
                    pending=self.pending is not None, fully_applied=fully_applied,
                    boot_id=current.boot_id if current else self.boot_id,
                    revision=current.revision if current else None,
                    values=current.values if current else None,
                    apply_count=current.apply_count if current else None,
                    core1_observed_revision=current.core1_observed_revision if current else None,
                    capture_samples=current.capture_samples if current else None,
                    silence_samples=current.silence_samples if current else None,
                    pause_remaining_ms=current.pause_remaining_ms if current else None,
                    age_s=(now_ns-self.received_ns)/1e9 if self.received_ns is not None else float("inf"))
