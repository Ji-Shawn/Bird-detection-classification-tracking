#include "audio_dsp.h"

uint16_t noise_gain_q15(uint32_t power, uint32_t *noise_psd) {
    uint32_t noise;
    int64_t delta;
    if (noise_psd == 0) return 1024u;
    noise = *noise_psd;
    if (noise == 0u) noise = power ? power : 1u;
    if (power < noise) noise = (7u * noise + power) >> 3;
    else {
        delta = (int64_t)power - noise;
        noise = (uint32_t)((int64_t)noise + (delta >> 9));
    }
    if (noise == 0u) noise = 1u;
    *noise_psd = noise;
    if ((uint64_t)power <= 4u * (uint64_t)noise) return 1024u; /* stationary floor: -30 dB */
    {
        uint64_t subtraction = ((uint64_t)noise * 49152u) / power;
        uint32_t gain = subtraction >= 32768u ? 0u : 32768u - (uint32_t)subtraction;
        if (gain < 1024u) gain = 1024u;
        if (gain > 32767u) gain = 32767u;
        return (uint16_t)gain;
    }
}
