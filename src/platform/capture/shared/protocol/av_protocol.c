#include "av_protocol.h"

#include <string.h>
#include "crc32_table.inc"

static uint16_t read_be16(const uint8_t *p) {
    return (uint16_t)(((uint16_t)p[0] << 8) | p[1]);
}

static uint32_t read_be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) | p[3];
}

static uint64_t read_be64(const uint8_t *p) {
    return ((uint64_t)read_be32(p) << 32) | read_be32(p + 4);
}

uint32_t av_crc32(const void *data, uint32_t bytes) {
    /* Exact IEEE CRC32 with eight independent lookups per 64-bit block.
     * Explicit byte assembly supports unaligned inputs on either endian. */
    const uint8_t *p = (const uint8_t *)data;
    uint32_t crc = 0xFFFFFFFFu;
    while (bytes >= 8u) {
        crc ^= (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
               ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
        crc = crc_table[7][crc & 255u] ^ crc_table[6][(crc >> 8) & 255u] ^
              crc_table[5][(crc >> 16) & 255u] ^ crc_table[4][crc >> 24] ^
              crc_table[3][p[4]] ^ crc_table[2][p[5]] ^
              crc_table[1][p[6]] ^ crc_table[0][p[7]];
        p += 8; bytes -= 8;
    }
    while (bytes >= 4u) {
        crc ^= (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
               ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
        crc = crc_table[3][crc & 255u] ^ crc_table[2][(crc >> 8) & 255u] ^
              crc_table[1][(crc >> 16) & 255u] ^ crc_table[0][crc >> 24];
        p += 4; bytes -= 4;
    }
    while (bytes--) crc=(crc>>8)^crc_table[0][(crc^*p++)&255u];
    return ~crc;
}

av_decode_result_t av_decode_packet(const uint8_t *data, uint32_t bytes,
                                    av_packet_decoded_t *out) {
    uint16_t payload_bytes;
    uint16_t fragment_index;
    uint16_t fragment_count;
    uint8_t type;
    if (data == 0 || out == 0 || bytes < AV_HEADER_BYTES) return AV_DECODE_SHORT;
    if (memcmp(data, "AVP1", 4) != 0) return AV_DECODE_MAGIC;
    if (data[4] != AV_PROTOCOL_MAJOR || data[5] > AV_PROTOCOL_MINOR)
        return AV_DECODE_VERSION;
    if (read_be16(data + 8) != AV_HEADER_BYTES) return AV_DECODE_HEADER;
    if (av_crc32(data, 36u) != read_be32(data + 36)) return AV_DECODE_CRC;
    type = data[6];
    if (type < AV_PACKET_VIDEO || type > AV_PACKET_CONTROL_REPLY)
        return AV_DECODE_TYPE;
    payload_bytes = read_be16(data + 10);
    if (bytes != AV_HEADER_BYTES + payload_bytes) return AV_DECODE_LENGTH;
    fragment_index = read_be16(data + 28);
    fragment_count = read_be16(data + 30);
    if (fragment_count == 0u || fragment_count > AV_MAX_FRAGMENT_COUNT ||
        fragment_index >= fragment_count)
        return AV_DECODE_FRAGMENT;
    if (type != AV_PACKET_VIDEO && (fragment_index != 0u || fragment_count != 1u))
        return AV_DECODE_FRAGMENT;
    if (av_crc32(data + AV_HEADER_BYTES, payload_bytes) != read_be32(data + 32))
        return AV_DECODE_CRC;
    out->packet_type = type;
    out->flags = data[7];
    out->payload_bytes = payload_bytes;
    out->boot_id = read_be32(data + 12);
    out->sequence = read_be32(data + 16);
    out->timestamp_us = read_be64(data + 20);
    out->fragment_index = fragment_index;
    out->fragment_count = fragment_count;
    out->payload = data + AV_HEADER_BYTES;
    return AV_DECODE_OK;
}
