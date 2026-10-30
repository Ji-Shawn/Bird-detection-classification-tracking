"""Bounded complete-frame assembly and RGB565 conversion."""

from __future__ import annotations

from dataclasses import dataclass
import math
import time
import numpy as np

from .protocol import Packet

WIDTH = 1920
HEIGHT = 1080
FRAME_BYTES = WIDTH * HEIGHT * 2
PAYLOAD_MODES = (8192, 1400)


@dataclass(frozen=True, slots=True)
class CompletedFrame:
    boot_id: int
    frame_id: int
    timestamp_us: int
    rgb565: bytes


@dataclass(slots=True)
class _Slot:
    boot_id: int
    frame_id: int
    timestamp_us: int
    started_ns: int
    chunk_bytes: int
    fragment_count: int
    buffer: bytearray
    received: bytearray
    received_count: int = 0


class VideoAssembler:
    def __init__(self, timeout_ms: int = 500) -> None:
        self.timeout_ns = timeout_ms * 1_000_000
        self._boot_id: int | None = None
        self._slots: dict[int, _Slot] = {}
        self.network_loss = 0
        self.duplicates = 0
        self.rejected = 0
        self._retired_boots: set[int] = set()
        self._last_complete_sequence: int | None = None
        self._last_complete_timestamp: int | None = None

    @staticmethod
    def _chunk_size(count: int) -> int:
        for size in PAYLOAD_MODES:
            if math.ceil(FRAME_BYTES / size) == count:
                return size
        raise ValueError("unsupported video fragmentation")

    def _expire(self, now_ns: int) -> None:
        expired = [key for key, slot in self._slots.items()
                   if now_ns - slot.started_ns > self.timeout_ns]
        for key in expired:
            self.network_loss += 1
            del self._slots[key]

    def expire(self, now_ns: int | None = None) -> None:
        """Settle incomplete frames even when the sender sends no more UDP."""
        self._expire(time.monotonic_ns() if now_ns is None else now_ns)

    def progress(self, now_ns: int) -> list[dict]:
        return [dict(boot_id=s.boot_id, frame_id=s.frame_id,
                     timestamp_us=s.timestamp_us, received=s.received_count,
                     expected=s.fragment_count, age_ms=max(0, now_ns-s.started_ns)/1e6)
                for s in self._slots.values()]

    def push(self, packet: Packet, now_ns: int | None = None) -> CompletedFrame | None:
        now_ns = time.monotonic_ns() if now_ns is None else now_ns
        h = packet.header
        if self._boot_id != h.boot_id:
            if h.boot_id in self._retired_boots:
                self.rejected += 1
                return None
            if self._boot_id is not None:
                self._retired_boots.add(self._boot_id)
            self._boot_id = h.boot_id
            self._slots.clear()
            self._last_complete_sequence = None
            self._last_complete_timestamp = None
        self._expire(now_ns)
        if self._last_complete_sequence is not None:
            delta = (h.sequence-self._last_complete_sequence) & 0xffffffff
            if not 0 < delta < 0x80000000 or h.timestamp_us <= self._last_complete_timestamp:
                self.duplicates += 1
                return None
        try:
            chunk = self._chunk_size(h.fragment_count)
        except ValueError:
            self.rejected += 1
            return None
        expected = min(chunk, FRAME_BYTES - h.fragment_index * chunk)
        if expected <= 0 or len(packet.payload) != expected:
            self.rejected += 1
            return None
        slot = self._slots.get(h.sequence)
        if slot is None:
            if len(self._slots) >= 2:
                oldest = min(self._slots, key=lambda k: self._slots[k].started_ns)
                del self._slots[oldest]
                self.network_loss += 1
            slot = _Slot(h.boot_id, h.sequence, h.timestamp_us, now_ns, chunk,
                         h.fragment_count, bytearray(FRAME_BYTES),
                         bytearray(h.fragment_count))
            self._slots[h.sequence] = slot
        if (slot.chunk_bytes != chunk or slot.fragment_count != h.fragment_count or
                slot.timestamp_us != h.timestamp_us):
            self.rejected += 1
            return None
        if slot.received[h.fragment_index]:
            self.duplicates += 1
            return None
        offset = h.fragment_index * chunk
        slot.buffer[offset:offset + expected] = packet.payload
        slot.received[h.fragment_index] = 1
        slot.received_count += 1
        if slot.received_count != slot.fragment_count:
            return None
        del self._slots[h.sequence]
        self._last_complete_sequence = slot.frame_id
        self._last_complete_timestamp = slot.timestamp_us
        # An older in-flight frame cannot be published after a newer complete one.
        previous_slots = len(self._slots)
        self._slots = {key: value for key, value in self._slots.items()
                       if 0 < ((key-slot.frame_id) & 0xffffffff) < 0x80000000 and
                       value.timestamp_us > slot.timestamp_us}
        self.network_loss += previous_slots-len(self._slots)
        return CompletedFrame(slot.boot_id, slot.frame_id, slot.timestamp_us,
                              bytes(slot.buffer))


def rgb565_to_rgb888(raw: bytes, *, downsample: int = 1) -> np.ndarray:
    pixels = np.frombuffer(raw, dtype="<u2").reshape(HEIGHT, WIDTH)
    if downsample > 1:
        pixels = pixels[::downsample, ::downsample]
    r = ((pixels >> 11) & 0x1F).astype(np.uint8)
    g = ((pixels >> 5) & 0x3F).astype(np.uint8)
    b = (pixels & 0x1F).astype(np.uint8)
    return np.stack(((r << 3) | (r >> 2), (g << 2) | (g >> 4),
                     (b << 3) | (b >> 2)), axis=-1)
