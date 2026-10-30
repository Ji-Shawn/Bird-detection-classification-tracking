#ifndef NETWORK_SERVICE_H
#define NETWORK_SERVICE_H

#include <stdint.h>

#include "av_shared.h"
#include "av_protocol.h"

#define NETWORK_VIDEO_PENDING 2u
#define NETWORK_JUMBO_PAYLOAD 8192u
#define NETWORK_COMPAT_PAYLOAD 1400u
/* One standard IPv4 STATUS datagram; video fragmentation is unchanged. */
#define NETWORK_STATUS_PAYLOAD_MAX (1500u - 20u - 8u - AV_HEADER_BYTES)
#define NETWORK_SEND_RETRY 1

typedef struct {
    uint32_t frame_id;
    uint64_t timestamp_us;
    uint16_t next_fragment;
    uint8_t buffer_index;
    uint8_t valid;
    uint32_t retry_started_us, retry_after_us;
    uint8_t retry_active;
} video_frame_t;

typedef struct {
    uint32_t boot_id;
    uint32_t mtu_payload;
    uint32_t audio_read_index;
    video_frame_t video[NETWORK_VIDEO_PENDING];
    uint32_t video_drop_old;
    uint32_t video_drop_tx;
    uint32_t audio_drop_deadline;
    uint32_t packet_errors;
    uint32_t bytes_sent;
    uint32_t packets_sent;
    uint8_t status_pending;
} network_service_t;

typedef enum { CONTROL_APPLIED = 0, CONTROL_REJECTED = 1, CONTROL_UNSUPPORTED = 2 } control_result_t;
typedef struct {
    uint32_t sequence;
    uint32_t fingerprint;
    uint8_t result;
    uint8_t valid;
} control_cache_entry_t;
typedef struct {
    uint32_t allowed_ipv4;
    uint32_t window_start_ms;
    uint8_t attempts_in_window;
    uint8_t cache_next;
    uint16_t sound_speed_mps;
    control_cache_entry_t cache[16];
} control_state_t;

void network_service_init(network_service_t *service, uint32_t boot_id, int jumbo);
void network_video_complete(network_service_t *service, uint8_t buffer_index,
                            uint32_t frame_id, uint64_t timestamp_us);
void network_audio_dma_complete(uint32_t slot, uint32_t boot_id,
                                uint32_t sequence, uint64_t timestamp_us);
int network_scheduler_poll(network_service_t *service);
unsigned network_scheduler_burst(network_service_t *service, uint32_t budget_us,
                                 unsigned max_packets);

int udp_send_video_fragment(network_service_t *service, const video_frame_t *frame,
                            uint16_t fragment_index, uint16_t fragment_count);
int udp_send_audio_result(network_service_t *service, uint32_t result_index);
int udp_send_status_payload(network_service_t *service, uint32_t sequence,
                            const void *payload, uint16_t bytes);
control_result_t control_handle(network_service_t *service, control_state_t *control,
                                uint32_t source_ipv4, uint32_t sequence,
                                const uint8_t *payload, uint16_t bytes, uint32_t now_ms);
int telemetry_send(network_service_t *service, uint32_t sequence,
                   uint32_t uptime_ms, uint32_t audio_deadline_miss);
int udp_send_control_reply(network_service_t *service, uint32_t sequence,
                           control_result_t result);

/* 0=accepted; +1=not accepted, transient pressure; negative=permanent error. */
int platform_udp_send(uint16_t destination_port, const void *data, uint32_t bytes);
/* Synchronously copy both spans into a driver-owned pbuf before returning. */
int platform_udp_send_parts(uint16_t destination_port,
                            const void *header, uint32_t header_bytes,
                            const void *payload, uint32_t payload_bytes);
uint32_t platform_time_us(void);
void platform_cache_flush(const void *address, uint32_t bytes);
void platform_cache_invalidate(const void *address, uint32_t bytes);
void platform_mmio_write(uint32_t address, uint32_t value);
uint32_t platform_mmio_read(uint32_t address);
int network_platform_init(uint32_t destination_ipv4, network_service_t *service);
void network_platform_poll(void);
int ov5640_camera_init(void);
int ov5640_camera_prepare(void);
int ov5640_camera_start(void);
int ov5640_diagnostic_pattern(unsigned mode); /* 0 scene, 1 PL bars, 2 sensor bars */
int ov5640_diagnostic_phase(unsigned mode); /* 0 verified 1080p phase, 1 alternate phase */
int dma_service_init(network_service_t *service, uint32_t boot_id);
void dma_service_poll(network_service_t *service);

#endif
