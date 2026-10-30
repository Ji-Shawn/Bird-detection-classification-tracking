#include "network_service.h"
#include "av_protocol.h"
#include "fusion_bridge.h"

#include <string.h>

static uint8_t packet_buffer[AV_HEADER_BYTES + NETWORK_JUMBO_PAYLOAD + 16u];

static void be16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
static void be32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16); p[2] = (uint8_t)(v >> 8); p[3] = (uint8_t)v;
}
static void be64(uint8_t *p, uint64_t v) { be32(p, (uint32_t)(v >> 32)); be32(p + 4, (uint32_t)v); }

static void make_header(uint8_t *header, uint8_t type, uint32_t boot_id, uint32_t sequence,
                            uint64_t timestamp_us, uint16_t fragment_index,
                            uint16_t fragment_count, const void *payload, uint16_t bytes) {
    memset(header, 0, AV_HEADER_BYTES);
    memcpy(header, "AVP1", 4);
    header[4] = AV_PROTOCOL_MAJOR;
    header[5] = AV_PROTOCOL_MINOR;
    header[6] = type;
    be16(header + 8, AV_HEADER_BYTES);
    be16(header + 10, bytes);
    be32(header + 12, boot_id);
    be32(header + 16, sequence);
    be64(header + 20, timestamp_us);
    be16(header + 28, fragment_index);
    be16(header + 30, fragment_count);
    be32(header + 32, av_crc32(payload, bytes));
    be32(header + 36, av_crc32(header, 36));
}

static uint32_t make_packet(uint8_t type, uint32_t boot_id, uint32_t sequence,
                            uint64_t timestamp_us, uint16_t fragment_index,
                            uint16_t fragment_count, const void *payload, uint16_t bytes) {
    make_header(packet_buffer, type, boot_id, sequence, timestamp_us,
                fragment_index, fragment_count, payload, bytes);
    memcpy(packet_buffer + AV_HEADER_BYTES, payload, bytes);
    return AV_HEADER_BYTES + bytes;
}

int udp_send_video_fragment(network_service_t *service, const video_frame_t *frame,
                            uint16_t index, uint16_t count) {
    uint8_t header[AV_HEADER_BYTES];
    if ((service->mtu_payload != NETWORK_COMPAT_PAYLOAD &&
         service->mtu_payload != NETWORK_JUMBO_PAYLOAD) ||
        count != (AV_VIDEO_FRAME_BYTES+service->mtu_payload-1u)/service->mtu_payload ||
        index >= count || frame->buffer_index >= AV_VIDEO_TX_BUFFER_COUNT) return -1;
    uint32_t offset = (uint32_t)index * service->mtu_payload;
    uint32_t remaining = AV_VIDEO_FRAME_BYTES - offset;
    uint16_t bytes = (uint16_t)(remaining < service->mtu_payload ? remaining : service->mtu_payload);
    const uint8_t *base = (const uint8_t *)(uintptr_t)(AV_VIDEO_TX_BUFFER_BASE +
                           frame->buffer_index * AV_VIDEO_FRAME_BYTES + offset);
    uint32_t packet_bytes;
    /* Core0 produced this immutable staging frame. Do not invalidate its
     * dirty cache lines: the Ethernet driver owns a separate pbuf copy. */
    make_header(header, AV_PACKET_VIDEO, service->boot_id, frame->frame_id,
                frame->timestamp_us, index, count, base, bytes);
    packet_bytes = AV_HEADER_BYTES + bytes;
    int rc=platform_udp_send_parts(AV_UDP_VIDEO_PORT, header, AV_HEADER_BYTES, base, bytes);
    if (rc != 0) return rc;
    service->bytes_sent += packet_bytes; service->packets_sent++;
    return 0;
}

int udp_send_audio_result(network_service_t *service, uint32_t index) {
    av_shared_desc_t *desc = (av_shared_desc_t *)(uintptr_t)(AV_RESULT_DESC_BASE + index * sizeof(*desc));
    av_audio_result_payload_t *result = (av_audio_result_payload_t *)(uintptr_t)(AV_RESULT_PAYLOAD_BASE + index * AV_RESULT_SLOT_BYTES);
    uint8_t payload[8u + 128u * 2u];
    uint32_t packet_bytes, i;
    platform_cache_invalidate(desc, sizeof(*desc));
    platform_cache_invalidate(result, sizeof(*result));
    packet_bytes = make_packet(AV_PACKET_PCM, service->boot_id, desc->sequence, desc->timestamp_us,
                               0, 1, result->enhanced_pcm, sizeof(result->enhanced_pcm));
    if (platform_udp_send(AV_UDP_PCM_PORT, packet_buffer, packet_bytes) != 0) return -1;
    fusion_direction_sample direction;
    int valid=fusion_direction_read(&direction);
    be16(payload, (uint16_t)direction.angle_q9_7);
    be16(payload + 2, direction.confidence_q0_15);
    be16(payload + 4, 128u); payload[6] = (uint8_t)valid; payload[7] = 1; /* bird-gated, historical direction */
    for (i = 0; i < 128u; ++i) be16(payload + 8u + i * 2u, result->mel[i]);
    packet_bytes = make_packet(AV_PACKET_FEATURE, service->boot_id, desc->sequence, desc->timestamp_us,
                               0, 1, payload, sizeof(payload));
    if (platform_udp_send(AV_UDP_FEATURE_PORT, packet_buffer, packet_bytes) != 0) return -2;
    service->packets_sent += 2u;
    service->bytes_sent += AV_HEADER_BYTES * 2u + sizeof(result->enhanced_pcm) + sizeof(payload);
    av_memory_barrier(); desc->state = AV_DESC_FREE; platform_cache_flush(desc, sizeof(*desc));
    return 0;
}

int udp_send_status_payload(network_service_t *service, uint32_t sequence,
                            const void *payload, uint16_t bytes) {
    uint32_t packet_bytes;
    if (bytes > NETWORK_STATUS_PAYLOAD_MAX) return -1;
    packet_bytes = make_packet(AV_PACKET_STATUS, service->boot_id, sequence, 0,
                               0, 1, payload, bytes);
    if (platform_udp_send(AV_UDP_STATUS_PORT, packet_buffer, packet_bytes) != 0) return -2;
    service->packets_sent++; service->bytes_sent += packet_bytes;
    return 0;
}

int udp_send_control_reply(network_service_t *service, uint32_t sequence,
                           control_result_t result) {
    uint8_t payload[8] = {0};
    uint32_t packet_bytes;
    be32(payload, sequence);
    payload[4] = (uint8_t)result;
    packet_bytes = make_packet(AV_PACKET_CONTROL_REPLY, service->boot_id, sequence, 0,
                               0, 1, payload, sizeof(payload));
    if (platform_udp_send(AV_UDP_CONTROL_PORT, packet_buffer, packet_bytes) != 0) return -1;
    service->packets_sent++;
    service->bytes_sent += packet_bytes;
    return 0;
}
