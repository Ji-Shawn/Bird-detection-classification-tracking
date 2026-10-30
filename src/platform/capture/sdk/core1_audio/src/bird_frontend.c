#include "bird_frontend.h"

#include <stddef.h>
#include <string.h>

#include "bird_filter_coeffs.h"

#define PCM24_MAX 8388607
#define PCM24_MIN (-8388607 - 1)
#define VAD_WARMUP_HOPS 20U
#define VAD_ONSET_HOPS 2U
#define VAD_HANGOVER_HOPS 15U
#define VAD_SILENCE_FLOOR 256ULL

static int32_t saturate_pcm24(int64_t value) {
    if (value > PCM24_MAX) {
        return PCM24_MAX;
    }
    if (value < PCM24_MIN) {
        return PCM24_MIN;
    }
    return (int32_t)value;
}

static int64_t round_shift_q30(int64_t value) {
    const int64_t half = (int64_t)1 << 29;
    if (value >= 0) {
        return (value + half) >> 30;
    }
    return -(((-value) + half) >> 30);
}

static int32_t biquad_step(
    bird_biquad_state_t *state,
    const int32_t coeffs[5],
    int32_t sample) {
    const int64_t accumulator = (int64_t)coeffs[0] * sample + state->z1;
    const int32_t output = saturate_pcm24(round_shift_q30(accumulator));
    const int64_t next_z1 = (int64_t)coeffs[1] * sample
                          - (int64_t)coeffs[3] * output + state->z2;
    const int64_t next_z2 = (int64_t)coeffs[2] * sample
                          - (int64_t)coeffs[4] * output;
    state->z1 = next_z1;
    state->z2 = next_z2;
    return output;
}

void bird_frontend_reset(bird_frontend_state_t *state) {
    if (state != NULL) {
        memset(state, 0, sizeof(*state));
    }
}

static void update_noise(uint64_t *noise, uint64_t energy) {
    if (energy > *noise) {
        *noise += (energy - *noise) >> 8;
    } else {
        *noise -= (*noise - energy) >> 8;
    }
}

static void update_vad(
    bird_frontend_state_t *state,
    bird_vad_result_t *vad,
    uint8_t saturated) {
    unsigned channel;
    unsigned trigger_count = 0U;
    unsigned sustain_count = 0U;

    if (saturated != 0U) {
        state->onset_hops = 0U;
        state->hangover_hops = 0U;
        state->active = 0U;
        vad->active = 0U;
        vad->warming_up = state->warmup_hops < VAD_WARMUP_HOPS ? 1U : 0U;
        return;
    }

    if (state->warmup_hops < VAD_WARMUP_HOPS) {
        const uint64_t count = state->warmup_hops;
        for (channel = 0U; channel < BIRD_CHANNELS; ++channel) {
            state->noise_energy[channel] =
                (state->noise_energy[channel] * count + vad->energy[channel]) / (count + 1U);
        }
        ++state->warmup_hops;
        state->active = 0U;
        vad->active = 0U;
        vad->warming_up = 1U;
        return;
    }

    vad->warming_up = 0U;
    for (channel = 0U; channel < BIRD_CHANNELS; ++channel) {
        const uint64_t energy = vad->energy[channel];
        const uint64_t noise = state->noise_energy[channel] != 0U
                             ? state->noise_energy[channel] : 1U;
        if ((energy >= VAD_SILENCE_FLOOR) && (2U * energy >= 5U * noise)) {
            ++trigger_count;
        }
        if ((energy >= VAD_SILENCE_FLOOR) && (2U * energy >= 3U * noise)) {
            ++sustain_count;
        }
    }

    if (state->active != 0U) {
        if (sustain_count >= 2U) {
            state->hangover_hops = VAD_HANGOVER_HOPS;
        } else if (state->hangover_hops != 0U) {
            --state->hangover_hops;
        }
        if (state->hangover_hops == 0U) {
            state->active = 0U;
        }
    } else {
        state->onset_hops = trigger_count >= 2U ? state->onset_hops + 1U : 0U;
        if (state->onset_hops >= VAD_ONSET_HOPS) {
            state->active = 1U;
            state->hangover_hops = VAD_HANGOVER_HOPS;
            state->onset_hops = 0U;
        }
        for (channel = 0U; channel < BIRD_CHANNELS; ++channel) {
            update_noise(&state->noise_energy[channel], vad->energy[channel]);
        }
    }
    vad->active = state->active;
}

int bird_frontend_process_hop(
    bird_frontend_state_t *state,
    const int32_t input[BIRD_HOP_SAMPLES][BIRD_CHANNELS],
    int32_t filtered[BIRD_CHANNELS][BIRD_HOP_SAMPLES],
    bird_vad_result_t *vad) {
    unsigned sample_index;
    unsigned channel;
    uint8_t saturated = 0U;

    if ((state == NULL) || (input == NULL) || (filtered == NULL) || (vad == NULL)) {
        return -1;
    }
    memset(vad, 0, sizeof(*vad));
    for (sample_index = 0U; sample_index < BIRD_HOP_SAMPLES; ++sample_index) {
        for (channel = 0U; channel < BIRD_CHANNELS; ++channel) {
            const int32_t raw = input[sample_index][channel];
            int32_t value;
            if ((raw >= PCM24_MAX) || (raw <= PCM24_MIN)) {
                saturated = 1U;
            }
            value = biquad_step(&state->hp[channel], BIRD_HP_Q30, raw);
            value = biquad_step(&state->lp[channel], BIRD_LP_Q30, value);
            filtered[channel][sample_index] = value;
            vad->energy[channel] += (uint64_t)((int64_t)value * value);
        }
    }
    for (channel = 0U; channel < BIRD_CHANNELS; ++channel) {
        vad->energy[channel] /= BIRD_HOP_SAMPLES;
    }
    if (saturated != 0U) {
        memset(state->hp, 0, sizeof(state->hp));
        memset(state->lp, 0, sizeof(state->lp));
    }
    update_vad(state, vad, saturated);
    return 0;
}
