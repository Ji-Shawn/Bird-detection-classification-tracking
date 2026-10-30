#ifndef FUSION_BRIDGE_H
#define FUSION_BRIDGE_H
#include <stdint.h>
#include <stddef.h>
#include "direction_gate.h"
#define FUSION_SHARED 0x30040000u
#define FUSION_IMAGE 0x36400000u
#define FUSION_RESULT 0x30F00000u
#define FUSION_ASSETS_READY 0x30F01000u
#define FUSION_ASSETS_MAGIC 0x4D313157u
#define FUSION_SLOT_PCM 0x30D00000u
#define FUSION_USED_PCM 0x30DA0000u
#define FUSION_DIAG 0x30F02000u
#define FUSION_AUDIO_HEALTH 0x30070000u
#define FUSION_LIVE_DIRECTION 0x30070040u
/* Noncacheable single-producer seqlock, separate from health and audio tensor. */
typedef struct {
    volatile uint32_t generation;
    uint32_t mask;
    fusion_direction_sample sample;
    float energy;
    uint32_t reserved[9];
} fusion_live_direction;
_Static_assert(sizeof(fusion_live_direction)==64,"live direction ABI");
typedef struct {
    volatile uint32_t state; /* 0 free, 1 writing, 2 ready, 3 reading */
    uint32_t sequence, dropped, reserved;
    uint64_t timestamp_us;
    fusion_direction_sample direction;
    uint32_t pad[6];
    int8_t input[153600];
} fusion_audio_slot;
_Static_assert(offsetof(fusion_audio_slot,input)==64,"audio input DDR offset unchanged");
typedef struct {
    uint32_t magic, version, sequence, status; /* 1 audio only,2 fused,3 timeout,4 fault */
    uint64_t audio_timestamp_us, video_timestamp_us;
    uint32_t video_sequence, top1, audio_top1, image_top1;
    float confidence, detector_score;
    int32_t error;
    uint32_t max_service_gap_us;
    float probabilities[60];
    float box[4]; /* camera pixels */
    uint32_t image_policy, applied_policy; /* 0 full,1 auto ROI,2 manual,3 manual A/B */
    int32_t roi[4]; /* padded source square; can extend beyond camera edges */
    uint32_t full_top1; /* only populated by same-frame A/B; otherwise UINT32_MAX */
    float full_confidence;
    uint32_t audio_compute_us,ssd_preprocess_us,ssd_compute_us,image_preprocess_us;
    uint32_t image_compute_us,total_us,audio_response_us,capture_wait_us;
} fusion_result;
_Static_assert(sizeof(fusion_result)==384,"FUS1 v3 ABI");
int fusion_set_image_policy(unsigned policy,const uint16_t *box);
void fusion_audio_publish(const float *x,uint64_t timestamp,const fusion_direction_sample *direction);
int fusion_set_direction_threshold(unsigned percent);
int fusion_direction_read(fusion_direction_sample *out);
void fusion_direction_status(uint32_t *percent,uint32_t *bird,float *score,uint32_t *age_ms);
void fusion_init(void *network);
void fusion_poll(void);
void fusion_yield(void);
void fusion_service_idle(void);
int fusion_set_mode(unsigned mode); /* 0 gated fusion, 1 visual, 2 sound/visual tracking */
int fusion_capture_control(unsigned action); /* 1 freeze after next result; 0 resume */
unsigned fusion_mode(void);
unsigned fusion_capture_state(void);
int fusion_video_begin(uint32_t sequence,uint64_t timestamp);
void fusion_video_chunk(const void *p,uint32_t offset,uint32_t bytes);
void fusion_video_abort(void);
void fusion_video_end(void);
#endif
