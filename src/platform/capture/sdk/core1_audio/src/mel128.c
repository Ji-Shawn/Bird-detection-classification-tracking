#include "audio_dsp.h"

#include <math.h>
#include <stddef.h>
#include <string.h>

typedef struct { uint16_t start, peak, end, up_q15, down_q15; } mel_band_t;
extern const mel_band_t g_mel128_table[128];

static int16_t history[AUDIO_MEL_FFT_SIZE];
static uint32_t noise_psd[AUDIO_MEL_FFT_SIZE / 2u + 1u];
static uint32_t noise_warmup_hops;
static uint64_t band_noise[128];
static complex_q15_t frame[AUDIO_MEL_FFT_SIZE];
static int16_t hann_q15[AUDIO_MEL_FFT_SIZE];

static uint32_t leading_bit_u64(uint64_t value) {
    uint32_t bit = 0;
    while (value >>= 1) ++bit;
    return bit;
}

static int32_t log2_q8_u64(uint64_t value) {
    uint32_t bit;
    uint64_t base;
    if (value == 0u) return -32768;
    bit = leading_bit_u64(value);
    base = (uint64_t)1u << bit;
    return (int32_t)((bit << 8) + (uint32_t)(((value - base) << 8) / base));
}

void audio_process_reset(void) {
    uint32_t i;
    float cosine_previous = 1.0f;
    float cosine = cosf(6.2831853071795864769f /
                        (float)(AUDIO_MEL_FFT_SIZE - 1u));
    float coefficient = 2.0f * cosine;
    memset(history, 0, sizeof(history));
    memset(noise_psd, 0, sizeof(noise_psd));
    memset(band_noise, 0, sizeof(band_noise));
    noise_warmup_hops = 0u;
    for (i = 0u; i < AUDIO_MEL_FFT_SIZE; ++i) {
        float next;
        hann_q15[i] = (int16_t)(0.5f * (1.0f - cosine_previous) * 32767.0f + 0.5f);
        next = coefficient * cosine - cosine_previous;
        cosine_previous = cosine;
        cosine = next;
    }
}

int audio_process_hop(const int32_t beamformed[480], int16_t pcm_out[480],
                      uint16_t mel_out[128], uint8_t bird_active) {
    uint32_t i, band;
    int64_t dc_sum = 0;
    int32_t dc_mean;
    uint64_t energies[128];
    uint64_t gain_sum = 0;
    if (beamformed == 0 || pcm_out == 0 || mel_out == 0) return -1;
    memmove(history, history + 480,
            (AUDIO_MEL_FFT_SIZE - 480u) * sizeof(history[0]));
    for (i = 0; i < 480u; ++i) {
        int32_t sample = beamformed[i] >> 8;
        if (sample > 32767) sample = 32767;
        if (sample < -32768) sample = -32768;
        history[AUDIO_MEL_FFT_SIZE - 480u + i] = (int16_t)sample;
    }
    for (i = 0u; i < AUDIO_MEL_FFT_SIZE; ++i) dc_sum += history[i];
    dc_mean = (int32_t)(dc_sum / (int32_t)AUDIO_MEL_FFT_SIZE);
    for (i = 0; i < AUDIO_MEL_FFT_SIZE; ++i) {
        frame[i].re = (int16_t)(((int64_t)(history[i] - dc_mean) * hann_q15[i]) >> 15);
        frame[i].im = 0;
    }
    fft_q15_n(frame, AUDIO_MEL_FFT_SIZE, 0);
    for (i = 0; i <= AUDIO_MEL_FFT_SIZE / 2u; ++i) {
        int32_t re = frame[i].re, im = frame[i].im;
        uint32_t power = (uint32_t)((int64_t)re * re + (int64_t)im * im);
        uint32_t old_noise = noise_psd[i];
        if (noise_warmup_hops < 6u) noise_psd[i] = power;
        uint16_t gain = (bird_active && old_noise == 0u &&
                         noise_warmup_hops >= 6u)
                      ? 32767u : noise_gain_q15(power, &noise_psd[i]);
        if (bird_active && noise_warmup_hops >= 6u) noise_psd[i] = old_noise;
        gain_sum += gain;
        frame[i].re = (int16_t)((re * (int32_t)gain) >> 15);
        frame[i].im = (int16_t)((im * (int32_t)gain) >> 15);
    }
    if (noise_warmup_hops < 6u) ++noise_warmup_hops;
    {
        uint32_t scalar_gain = (uint32_t)(gain_sum / (AUDIO_MEL_FFT_SIZE / 2u + 1u));
        for (i = 0u; i < 480u; ++i) {
            int32_t sample = beamformed[i] >> 8;
            sample = (int32_t)(((int64_t)sample * scalar_gain) >> 15);
            if (sample > 32767) sample = 32767;
            if (sample < -32768) sample = -32768;
            pcm_out[i] = (int16_t)sample;
        }
    }
    for (band = 0; band < 128u; ++band) {
        const mel_band_t *m = &g_mel128_table[band];
        uint64_t sum = 0;
        for (i = m->start; i <= m->end && i <= AUDIO_MEL_FFT_SIZE / 2u; ++i) {
            uint32_t weight = i <= m->peak ? (i - m->start) * m->up_q15
                                           : (m->end - i) * m->down_q15;
            int32_t re = frame[i].re, im = frame[i].im;
            uint32_t power = (uint32_t)((int64_t)re * re + (int64_t)im * im);
            if (weight > 32767u) weight = 32767u;
            sum += (uint64_t)power * weight;
        }
        if (!bird_active) {
            if (sum < band_noise[band])
                band_noise[band] -= (band_noise[band] - sum) >> 4;
            else
                band_noise[band] += (sum - band_noise[band]) >> 5;
        }
        energies[band] = sum > (band_noise[band] << 1)
                       ? sum - (band_noise[band] << 1) : 0u;
    }
    for (band = 0; band < 128u; ++band) {
        /* Q15 FFT and Q15 filter weights put a full-scale band close to 2^41.
         * Preserve an absolute -80..0 dBFS scale across frames. */
        int32_t db_q8 = ((log2_q8_u64(energies[band]) - (41 << 8)) * 771) >> 8;
        int32_t level_q8 = db_q8 + (80 << 8);
        if (level_q8 <= 0) mel_out[band] = 0u;
        else if (level_q8 >= (80 << 8)) mel_out[band] = 65535u;
        else mel_out[band] = (uint16_t)(((uint32_t)level_q8 * 65535u) / (80u << 8));
    }
    return 0;
}
