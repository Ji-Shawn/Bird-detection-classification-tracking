#ifndef BIRD_FRONTEND_H
#define BIRD_FRONTEND_H

#include <stdint.h>

#define BIRD_CHANNELS 4
#define BIRD_HOP_SAMPLES 480

typedef struct {
    int64_t z1;
    int64_t z2;
} bird_biquad_state_t;

typedef struct {
    bird_biquad_state_t hp[BIRD_CHANNELS];
    bird_biquad_state_t lp[BIRD_CHANNELS];
    uint64_t noise_energy[BIRD_CHANNELS];
    uint16_t warmup_hops;
    uint16_t onset_hops;
    uint16_t hangover_hops;
    uint8_t active;
} bird_frontend_state_t;

typedef struct {
    uint64_t energy[BIRD_CHANNELS];
    uint8_t active;
    uint8_t warming_up;
} bird_vad_result_t;

void bird_frontend_reset(bird_frontend_state_t *state);

int bird_frontend_process_hop(
    bird_frontend_state_t *state,
    const int32_t input[BIRD_HOP_SAMPLES][BIRD_CHANNELS],
    int32_t filtered[BIRD_CHANNELS][BIRD_HOP_SAMPLES],
    bird_vad_result_t *vad);

#endif
