#ifndef LOGMEL_PL_H
#define LOGMEL_PL_H
#include <stdint.h>
/* This driver MUST only run with the m13 bitstream. No speculative MMIO probe
 * of an old bitstream is safe on this system. Single owner: Cortex-A9 core1. */
typedef struct {
    uint32_t frames, failures, disabled, last_mm2s_status, last_s2mm_status;
    uint32_t last_ticks, max_ticks;
} logmel_pl_stats_t;
extern volatile logmel_pl_stats_t logmel_pl_stats;
int logmel_pl_frame(const int32_t pcm[1024], float db[128]);
#endif
