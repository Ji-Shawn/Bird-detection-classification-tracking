#ifndef AV_PROTOCOL_H
#define AV_PROTOCOL_H

#include <stdint.h>

#define AV_PROTOCOL_MAGIC 0x41565031u /* "AVP1" in network byte order */
#define AV_PROTOCOL_MAJOR 1u
#define AV_PROTOCOL_MINOR 0u
#define AV_HEADER_BYTES 40u
#define AV_MAX_FRAGMENT_COUNT 4096u

#define AV_UDP_VIDEO_PORT 15000u
#define AV_UDP_PCM_PORT 15001u
#define AV_UDP_FEATURE_PORT 15002u
#define AV_UDP_STATUS_PORT 15003u
#define AV_UDP_CONTROL_PORT 15004u

typedef enum {
    AV_PACKET_VIDEO = 1,
    AV_PACKET_PCM = 2,
    AV_PACKET_FEATURE = 3,
    AV_PACKET_STATUS = 4,
    AV_PACKET_CONTROL = 5,
    AV_PACKET_CONTROL_REPLY = 6
} av_packet_type_t;

#if defined(__GNUC__)
#define AV_PACKED __attribute__((packed))
#else
#define AV_PACKED
#endif

/* Wire-only layout. Decode fields with memcpy plus ntoh helpers; never cast a
 * received byte pointer to this packed type. */
typedef struct AV_PACKED {
    uint8_t magic[4];
    uint8_t version_major;
    uint8_t version_minor;
    uint8_t packet_type;
    uint8_t flags;
    uint16_t header_bytes_be;
    uint16_t payload_bytes_be;
    uint32_t boot_id_be;
    uint32_t sequence_be;
    uint64_t timestamp_us_be;
    uint16_t fragment_index_be;
    uint16_t fragment_count_be;
    uint32_t payload_crc32_be;
    uint32_t header_crc32_be;
} av_packet_header_v1_t;

typedef struct AV_PACKED {
    uint16_t width_be;
    uint16_t height_be;
    uint16_t stride_bytes_be;
    uint8_t pixel_format; /* 1 = RGB565 little-endian */
    uint8_t reserved;
} av_video_fragment_v1_t;

typedef struct AV_PACKED {
    uint32_t sample_rate_hz_be;
    uint16_t samples_per_channel_be;
    uint8_t channels;
    uint8_t sample_bits;
    uint8_t layout; /* 1 = sample-interleaved little-endian int16 */
    uint8_t reserved[3];
} av_pcm_meta_v1_t;

typedef struct AV_PACKED {
    int16_t direction_q9_7_be;
    uint16_t confidence_q0_15_be;
    uint16_t mel_bins_be;
    uint8_t direction_valid;
    uint8_t reserved;
    /* Followed by 128 network-order uint16 Log-Mel values. */
} av_feature_v1_t;

typedef struct AV_PACKED {
    uint16_t command_be;
    uint16_t value_bytes_be;
    uint32_t command_sequence_be;
    /* Followed by command-specific bytes. */
} av_control_v1_t;

typedef struct {
    uint8_t packet_type;
    uint8_t flags;
    uint16_t payload_bytes;
    uint32_t boot_id;
    uint32_t sequence;
    uint64_t timestamp_us;
    uint16_t fragment_index;
    uint16_t fragment_count;
    const uint8_t *payload;
} av_packet_decoded_t;

typedef enum {
    AV_DECODE_OK = 0,
    AV_DECODE_SHORT = -1,
    AV_DECODE_MAGIC = -2,
    AV_DECODE_VERSION = -3,
    AV_DECODE_HEADER = -4,
    AV_DECODE_TYPE = -5,
    AV_DECODE_LENGTH = -6,
    AV_DECODE_FRAGMENT = -7,
    AV_DECODE_CRC = -8
} av_decode_result_t;

uint32_t av_crc32(const void *data, uint32_t bytes);
av_decode_result_t av_decode_packet(const uint8_t *data, uint32_t bytes,
                                    av_packet_decoded_t *decoded);

_Static_assert(sizeof(av_packet_header_v1_t) == 40, "AV header ABI changed");
_Static_assert(sizeof(av_video_fragment_v1_t) == 8, "video meta ABI changed");
_Static_assert(sizeof(av_pcm_meta_v1_t) == 12, "PCM meta ABI changed");
_Static_assert(sizeof(av_feature_v1_t) == 8, "feature meta ABI changed");
_Static_assert(sizeof(av_control_v1_t) == 8, "control ABI changed");

#endif
