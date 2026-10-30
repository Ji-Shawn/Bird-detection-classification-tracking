#include "audio_dsp.h"
#include "audio_array.h"

#include <stddef.h>
#include <string.h>

static const uint8_t pair_a[AUDIO_PAIR_COUNT] = AUDIO_ARRAY_PAIR_A;
static const uint8_t pair_b[AUDIO_PAIR_COUNT] = AUDIO_ARRAY_PAIR_B;
static const uint8_t lag_limit[AUDIO_PAIR_COUNT] = AUDIO_ARRAY_PAIR_LAG_LIMITS;

static complex_q15_t spectra[4][AUDIO_FFT_SIZE];
static complex_q15_t correlation[AUDIO_FFT_SIZE];

static int16_t sat16(int32_t value) {
    if (value > 32767) return 32767;
    if (value < -32768) return -32768;
    return (int16_t)value;
}

static uint32_t abs32(int32_t value) { return (uint32_t)(value < 0 ? -value : value); }

int gcc_phat_4ch(const int32_t pcm[4][AUDIO_FFT_SIZE], tdoa_result_t *out) {
    uint32_t channel, bin, pair;
    uint64_t energy[4] = {0, 0, 0, 0};
    uint64_t max_energy = 0;
    if (pcm == NULL || out == NULL) return -1;
    memset(out, 0, sizeof(*out));
    for (channel = 0; channel < 4u; ++channel) {
        uint32_t peak=1;
        for(bin=0;bin<AUDIO_FFT_SIZE;bin++) {
            uint32_t v=abs32(pcm[channel][bin]);if(v>peak)peak=v;
        }
        /* Preserve weak-channel precision through the scaled Q15 FFT.
         * One reciprocal per channel; keep original energy/quality gates. */
        uint32_t gain_q16=(uint32_t)((16384LL*65536)/peak);
        for (bin = 0; bin < AUDIO_FFT_SIZE; ++bin) {
            int32_t sample = pcm[channel][bin] >> 8;
            spectra[channel][bin].re = sat16((int32_t)(((int64_t)pcm[channel][bin]*gain_q16)/65536));
            spectra[channel][bin].im = 0;
            energy[channel] += (uint64_t)(sample * (int64_t)sample);
        }
        if (energy[channel] > max_energy) max_energy = energy[channel];
        fft_q15(spectra[channel], 0);
    }
    for (pair = 0; pair < AUDIO_PAIR_COUNT; ++pair) {
        uint8_t a = pair_a[pair], b = pair_b[pair], limit = lag_limit[pair];
        int best_lag = 0;
        int32_t best = -1;
        uint32_t side = 1u;
        if (energy[a] < 1024u || energy[b] < 1024u) continue;
        memset(correlation, 0, sizeof(correlation));
        for (bin = 10u; bin <= 256u; ++bin) { /* 312.5 Hz .. 8 kHz at 32 kHz */
            int32_t ar = spectra[a][bin].re, ai = spectra[a][bin].im;
            int32_t br = spectra[b][bin].re, bi = spectra[b][bin].im;
            int32_t re = ar * br + ai * bi;
            int32_t im = ai * br - ar * bi;
            uint32_t xr = abs32(re), xi = abs32(im);
            uint32_t magnitude = (xr > xi ? xr + (xi >> 1) : xi + (xr >> 1));
            if (magnitude > 32u) {
                correlation[bin].re = sat16((int32_t)(((int64_t)re * 32768) / magnitude));
                correlation[bin].im = sat16((int32_t)(((int64_t)im * 32768) / magnitude));
                if (bin != AUDIO_FFT_SIZE / 2u) {
                    correlation[AUDIO_FFT_SIZE - bin].re = correlation[bin].re;
                    correlation[AUDIO_FFT_SIZE - bin].im = (int16_t)-correlation[bin].im;
                }
            }
        }
        fft_q15(correlation, 1);
        {
            int lag;
            for (lag = -(int)limit; lag <= (int)limit; ++lag) {
                uint32_t index = lag < 0 ? AUDIO_FFT_SIZE + (uint32_t)lag : (uint32_t)lag;
                int32_t value = correlation[index].re;
                if (value > best) {
                    best = value;
                    best_lag = lag;
                }
            }
        }
        {
            int lag;
            int32_t fraction_q8 = 0;
            /* A strong negative sidelobe is also an ambiguous correlation peak. */
            for (lag = -(int)limit; lag <= (int)limit; ++lag) {
                if ((lag < best_lag - 2) || (lag > best_lag + 2)) {
                    uint32_t index = lag < 0 ? AUDIO_FFT_SIZE + (uint32_t)lag : (uint32_t)lag;
                    uint32_t magnitude = abs32(correlation[index].re);
                    if (magnitude > side) side = magnitude;
                }
            }
            if ((best_lag > -(int)limit) && (best_lag < (int)limit)) {
                uint32_t left_index = best_lag - 1 < 0
                                    ? AUDIO_FFT_SIZE + (uint32_t)(best_lag - 1)
                                    : (uint32_t)(best_lag - 1);
                uint32_t centre_index = best_lag < 0
                                      ? AUDIO_FFT_SIZE + (uint32_t)best_lag
                                      : (uint32_t)best_lag;
                uint32_t right_index = best_lag + 1 < 0
                                     ? AUDIO_FFT_SIZE + (uint32_t)(best_lag + 1)
                                     : (uint32_t)(best_lag + 1);
                int32_t left = correlation[left_index].re;
                int32_t centre = correlation[centre_index].re;
                int32_t right = correlation[right_index].re;
                int32_t denominator = left - 2 * centre + right;
                if (denominator != 0) {
                    fraction_q8 = (int32_t)(((int64_t)(left - right) * 128) / denominator);
                    if (fraction_q8 < -128) fraction_q8 = -128;
                    if (fraction_q8 > 128) fraction_q8 = 128;
                }
            }
            out->lag_q8_8[pair] = (int16_t)(best_lag * 256 + fraction_q8);
        }
        if (best > 0 && (uint32_t)best > side) {
            uint64_t weaker_energy = energy[a] < energy[b] ? energy[a] : energy[b];
            uint32_t pair_energy_q15 = max_energy != 0U
                                     ? (uint32_t)((weaker_energy * 32767U) / max_energy)
                                     : 0U;
            uint32_t confidence = (uint32_t)(((int64_t)(best - (int32_t)side) << 15) / best);
            if (confidence > 32767u) confidence = 32767u;
            confidence = (confidence * pair_energy_q15) >> 15;
            out->pair_confidence_q0_15[pair] = (uint16_t)confidence;
            if (confidence > 512u) out->valid_pair_mask |= (uint8_t)(1u << pair);
        }
    }
    return out->valid_pair_mask ? 0 : -2;
}
