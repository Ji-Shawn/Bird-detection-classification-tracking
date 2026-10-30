#ifndef AV_SHARED_H
#define AV_SHARED_H

#include <stdint.h>

#define AV_CACHE_LINE_BYTES 64u
#define AV_PCM_RING_SLOTS 20u
#define AV_RESULT_RING_SLOTS 20u
#define AV_PCM_SAMPLES_PER_HOP 480u
#define AV_MIC_CHANNELS 4u
#define AV_MEL_BINS 128u
#define AV_SHARED_BASE 0x30000000u
#define AV_PCM_DESC_BASE (AV_SHARED_BASE + 0x0000u)
#define AV_RESULT_DESC_BASE (AV_SHARED_BASE + 0x0800u)
#define AV_PCM_PAYLOAD_BASE (AV_SHARED_BASE + 0x1000u)
#define AV_PCM_SLOT_BYTES 0x2000u
#define AV_RESULT_PAYLOAD_BASE (AV_SHARED_BASE + 0x29000u)
#define AV_RESULT_SLOT_BYTES 0x0800u
#define AV_SHARED_READY_ADDR (AV_SHARED_BASE + 0x3F000u)
#define AV_SHARED_BOOT_ID_ADDR (AV_SHARED_BASE + 0x3F040u)
#define AV_SHARED_AUDIO_DEADLINE_ADDR (AV_SHARED_BASE + 0x3F080u)
#define AV_SHARED_BOOT_COUNTER_ADDR (AV_SHARED_BASE + 0x3F0C0u)
#define AV_SHARED_READY_MAGIC 0x41565244u
#define AV_VIDEO_WIDTH 1920u
#define AV_VIDEO_HEIGHT 1080u
#define AV_VIDEO_STRIDE (AV_VIDEO_WIDTH * 2u)
#define AV_VIDEO_FRAME_BYTES (AV_VIDEO_STRIDE * AV_VIDEO_HEIGHT)
#define AV_VIDEO_BUFFER_BASE 0x35000000u
#define AV_VIDEO_BUFFER_COUNT 3u
#define AV_VIDEO_TX_BUFFER_BASE 0x35C00000u
#define AV_VIDEO_TX_BUFFER_COUNT 2u

typedef enum {
    AV_DESC_FREE = 0,
    AV_DESC_WRITING = 1,
    AV_DESC_READY = 2,
    AV_DESC_READING = 3
} av_desc_state_t;

typedef struct __attribute__((aligned(AV_CACHE_LINE_BYTES))) {
    volatile uint32_t state;
    uint32_t boot_id;
    uint32_t sequence;
    uint32_t payload_bytes;
    uint64_t timestamp_us;
    uint32_t error_flags;
    uint32_t reserved[9];
} av_shared_desc_t;

typedef struct __attribute__((aligned(AV_CACHE_LINE_BYTES))) {
    int32_t sample[AV_PCM_SAMPLES_PER_HOP][AV_MIC_CHANNELS];
} av_pcm_payload_t;

typedef struct __attribute__((aligned(AV_CACHE_LINE_BYTES))) {
    int16_t enhanced_pcm[AV_PCM_SAMPLES_PER_HOP];
    uint16_t mel[AV_MEL_BINS];
    int16_t direction_q9_7;
    uint16_t confidence_q0_15;
    uint8_t direction_valid;
    uint8_t reserved[59];
} av_audio_result_payload_t;

_Static_assert(sizeof(av_shared_desc_t) == AV_CACHE_LINE_BYTES,
               "descriptor must occupy exactly one cache line");

/* Ownership contract:
 * producer: FREE -> WRITING, fill/flush payload, DMB, fill/flush descriptor,
 *           DMB, publish READY;
 * consumer: observe READY, claim READING, invalidate descriptor and payload,
 *           consume, DMB, publish FREE.
 * A producer must never overwrite READY/READING; a consumer must never silently
 * skip a boot_id or sequence discontinuity. */
static inline void av_memory_barrier(void) {
#if defined(__arm__) || defined(__aarch64__)
    __asm__ volatile("dmb sy" ::: "memory");
#else
    __sync_synchronize();
#endif
}

#endif
