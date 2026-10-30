#ifndef AUDIO_WORKER_H
#define AUDIO_WORKER_H

#include <stdint.h>

typedef struct {
    uint32_t boot_id;
    uint32_t expected_sequence;
    uint32_t input_index;
    uint32_t output_index;
    uint32_t sequence_gaps;
    uint32_t stale_boot;
    uint32_t output_overrun;
    uint32_t model_mel_drop;
    uint32_t deadline_miss;
    uint32_t vad_active_hops;
    uint32_t localization_failures;
    uint32_t cycles_min;
    uint32_t cycles_max;
    uint32_t cycles_ema;
} audio_worker_state_t;

void audio_worker_init(audio_worker_state_t *state, uint32_t boot_id);
int audio_worker_poll(audio_worker_state_t *state);

/* BSP port supplied by the platform application. */
void platform_cache_flush(const void *address, uint32_t bytes);
void platform_cache_invalidate(const void *address, uint32_t bytes);
uint32_t platform_cycle_count(void);
void platform_mmio_write(uint32_t address, uint32_t value);
uint32_t platform_mmio_read(uint32_t address);

#endif
