"""Fixed-memory Log-Mel and direction history."""

from __future__ import annotations

from dataclasses import dataclass
import struct
import threading
import time
import numpy as np

from .protocol import Packet


@dataclass(frozen=True, slots=True)
class DirectionState:
    angle_deg: float
    confidence: float
    valid: bool
    age_ms: float


class FeatureHistory:
    def __init__(self, columns: int = 1000) -> None:
        self._data = np.zeros((128, columns), dtype=np.uint16)
        self._write = 0
        self._count = 0
        self._boot: int | None = None
        self._expected: int | None = None
        self._angle = 0.0
        self._confidence = 0.0
        self._valid = False
        self._last_valid_ns = 0
        self.gaps = 0
        self._lock = threading.Lock()

    def push(self, packet: Packet, now_ns: int | None = None) -> None:
        if len(packet.payload) != 264:
            raise ValueError("feature payload must contain 128 bins")
        now_ns = time.monotonic_ns() if now_ns is None else now_ns
        angle_q, confidence, bins, valid, flags = struct.unpack_from("!hHHBB", packet.payload)
        if bins != 128:
            raise ValueError("unsupported Mel bin count")
        mel = np.frombuffer(packet.payload, dtype=">u2", offset=8, count=128).astype(np.uint16)
        with self._lock:
            if self._boot == packet.header.boot_id and self._expected is not None and packet.header.sequence < self._expected:
                return  # Late UDP must not resurrect a previously valid angle.
            if self._boot != packet.header.boot_id:
                self._boot = packet.header.boot_id
                self._expected = packet.header.sequence
                self._write = self._count = 0
                self._data.fill(0)
            if self._expected is not None and packet.header.sequence > self._expected:
                missing = min(packet.header.sequence - self._expected, self._data.shape[1])
                for _ in range(missing):
                    self._append(np.zeros(128, dtype=np.uint16))
                self.gaps += missing
            self._append(mel)
            self._expected = packet.header.sequence + 1
            # Ungated legacy firmware must not expose raw noise directions.
            self._valid = bool(valid and flags & 1 and 0 < confidence <= 32767)
            self._confidence = confidence / 32767.0 if self._valid else 0.0
            self._angle = angle_q / 128.0 if self._valid else 0.0
            self._last_valid_ns = now_ns if self._valid else 0

    def _append(self, column: np.ndarray) -> None:
        self._data[:, self._write] = column
        self._write = (self._write + 1) % self._data.shape[1]
        self._count = min(self._count + 1, self._data.shape[1])

    def snapshot(self, now_ns: int | None = None) -> tuple[np.ndarray, DirectionState]:
        now_ns = time.monotonic_ns() if now_ns is None else now_ns
        with self._lock:
            start = (self._write - self._count) % self._data.shape[1]
            if self._count == 0:
                data = np.zeros((128, 1), dtype=np.uint16)
            elif start < self._write:
                data = self._data[:, start:self._write].copy()
            else:
                data = np.concatenate((self._data[:, start:], self._data[:, :self._write]), axis=1)
            age = (now_ns - self._last_valid_ns) / 1_000_000 if self._last_valid_ns else float("inf")
            valid = self._valid and age <= 500
            state = DirectionState(self._angle if valid else 0.0,
                                   self._confidence if valid else 0.0, valid, age)
        return data, state
