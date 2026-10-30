#include "av_protocol.h"

#include <stdint.h>
#include <string.h>

static void put_be16(uint8_t *p, uint16_t value) {
    p[0] = (uint8_t)(value >> 8);
    p[1] = (uint8_t)value;
}

static void put_be32(uint8_t *p, uint32_t value) {
    p[0] = (uint8_t)(value >> 24);
    p[1] = (uint8_t)(value >> 16);
    p[2] = (uint8_t)(value >> 8);
    p[3] = (uint8_t)value;
}

static uint32_t make_valid(uint8_t packet[42]) {
    memset(packet, 0, 42);
    memcpy(packet, "AVP1", 4);
    packet[4] = AV_PROTOCOL_MAJOR;
    packet[5] = AV_PROTOCOL_MINOR;
    packet[6] = AV_PACKET_VIDEO;
    put_be16(packet + 8, AV_HEADER_BYTES);
    put_be16(packet + 10, 2);
    put_be32(packet + 12, 7);
    put_be32(packet + 16, 9);
    packet[27] = 1;
    put_be16(packet + 28, 0);
    put_be16(packet + 30, 1);
    packet[40] = 0x12;
    packet[41] = 0x34;
    put_be32(packet + 32, av_crc32(packet + 40, 2));
    put_be32(packet + 36, av_crc32(packet, 36));
    return 42;
}

int main(void) {
    uint8_t packet[42];
    uint8_t bad[42];
    av_packet_decoded_t decoded;
    uint32_t bytes = make_valid(packet);
    if (av_decode_packet(packet, bytes, &decoded) != AV_DECODE_OK) return 1;
    if (decoded.boot_id != 7u || decoded.sequence != 9u ||
        decoded.payload_bytes != 2u || decoded.payload[1] != 0x34u) return 2;

    memcpy(bad, packet, bytes); bad[0] = 'X';
    if (av_decode_packet(bad, bytes, &decoded) == AV_DECODE_OK) return 3;
    memcpy(bad, packet, bytes); bad[4] = 2;
    if (av_decode_packet(bad, bytes, &decoded) == AV_DECODE_OK) return 4;
    if (av_decode_packet(packet, bytes - 1u, &decoded) == AV_DECODE_OK) return 5;
    memcpy(bad, packet, bytes); bad[41] ^= 1u;
    if (av_decode_packet(bad, bytes, &decoded) == AV_DECODE_OK) return 6;
    memcpy(bad, packet, bytes); put_be16(bad + 28, 1); put_be32(bad + 36, av_crc32(bad, 36));
    if (av_decode_packet(bad, bytes, &decoded) == AV_DECODE_OK) return 7;
    memcpy(bad, packet, bytes); put_be16(bad + 30, AV_MAX_FRAGMENT_COUNT + 1u); put_be32(bad + 36, av_crc32(bad, 36));
    if (av_decode_packet(bad, bytes, &decoded) == AV_DECODE_OK) return 8;
    return 0;
}
