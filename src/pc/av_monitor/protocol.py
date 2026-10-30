"""Strict, allocation-bounded AVP1 datagram decoder."""

from __future__ import annotations

from dataclasses import dataclass
from enum import IntEnum
import struct
import zlib

MAGIC = b"AVP1"
HEADER_BYTES = 40
MAX_DATAGRAM_BYTES = HEADER_BYTES + 8192
MAX_FRAGMENT_COUNT = 4096
_HEADER = struct.Struct("!4sBBBBHHIIQHHII")


class PacketType(IntEnum):
    VIDEO = 1
    PCM = 2
    FEATURE = 3
    STATUS = 4
    CONTROL = 5
    CONTROL_REPLY = 6


class PacketError(ValueError):
    pass


@dataclass(frozen=True, slots=True)
class PacketHeader:
    packet_type: PacketType
    flags: int
    payload_length: int
    boot_id: int
    sequence: int
    timestamp_us: int
    fragment_index: int
    fragment_count: int


@dataclass(frozen=True, slots=True)
class Packet:
    header: PacketHeader
    payload: bytes


def parse_datagram(data: bytes | bytearray | memoryview) -> Packet:
    view = memoryview(data).cast("B")
    if len(view) < HEADER_BYTES or len(view) > MAX_DATAGRAM_BYTES:
        raise PacketError("invalid datagram size")
    fields = _HEADER.unpack_from(view)
    magic, major, minor, kind, flags, header_bytes, payload_bytes = fields[:7]
    boot_id, sequence, timestamp_us, frag_idx, frag_count, payload_crc, header_crc = fields[7:]
    if magic != MAGIC or major != 1 or minor > 0:
        raise PacketError("unsupported protocol identity")
    if header_bytes != HEADER_BYTES or len(view) != HEADER_BYTES + payload_bytes:
        raise PacketError("length mismatch")
    if zlib.crc32(view[:36]) & 0xFFFFFFFF != header_crc:
        raise PacketError("header CRC mismatch")
    try:
        packet_type = PacketType(kind)
    except ValueError as exc:
        raise PacketError("unknown packet type") from exc
    if not 1 <= frag_count <= MAX_FRAGMENT_COUNT or frag_idx >= frag_count:
        raise PacketError("bad fragment metadata")
    if packet_type != PacketType.VIDEO and (frag_idx != 0 or frag_count != 1):
        raise PacketError("non-video packet is fragmented")
    payload_view = view[HEADER_BYTES:]
    if zlib.crc32(payload_view) & 0xFFFFFFFF != payload_crc:
        raise PacketError("payload CRC mismatch")
    return Packet(PacketHeader(packet_type, flags, payload_bytes, boot_id, sequence,
                               timestamp_us, frag_idx, frag_count), bytes(payload_view))


def build_datagram(packet_type: PacketType, boot_id: int, sequence: int,
                   timestamp_us: int, payload: bytes, *, fragment_index: int = 0,
                   fragment_count: int = 1, flags: int = 0) -> bytes:
    payload = bytes(payload)
    if len(payload) > 8192 or not 1 <= fragment_count <= MAX_FRAGMENT_COUNT:
        raise ValueError("payload or fragment count out of range")
    if not 0 <= fragment_index < fragment_count:
        raise ValueError("fragment index out of range")
    if packet_type != PacketType.VIDEO and (fragment_index or fragment_count != 1):
        raise ValueError("only video may be fragmented")
    payload_crc = zlib.crc32(payload) & 0xFFFFFFFF
    header = bytearray(_HEADER.pack(MAGIC, 1, 0, int(packet_type), flags,
                                    HEADER_BYTES, len(payload), boot_id, sequence,
                                    timestamp_us, fragment_index, fragment_count,
                                    payload_crc, 0))
    struct.pack_into("!I", header, 36, zlib.crc32(header[:36]) & 0xFFFFFFFF)
    return bytes(header) + payload
