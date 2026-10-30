#include "audio_dsp.h"

#include <math.h>

static complex_q15_t twiddle[AUDIO_MEL_FFT_SIZE / 2u];
static int initialized;

static int16_t sat16(int32_t value) {
    if (value > 32767) return 32767;
    if (value < -32768) return -32768;
    return (int16_t)value;
}

void fft_q15_init(void) {
    uint32_t index;
    if (initialized) return;
    for (index = 0; index < AUDIO_MEL_FFT_SIZE / 2u; ++index) {
        float phase = -6.2831853071795864769f * (float)index / (float)AUDIO_MEL_FFT_SIZE;
        twiddle[index].re = (int16_t)lrintf(cosf(phase) * 32767.0f);
        twiddle[index].im = (int16_t)lrintf(sinf(phase) * 32767.0f);
    }
    initialized = 1;
}

void fft_q15(complex_q15_t data[AUDIO_FFT_SIZE], int inverse) {
    fft_q15_n(data, AUDIO_FFT_SIZE, inverse);
}

void fft_q15_n(complex_q15_t *data, uint32_t size, int inverse) {
    uint32_t i, j, length;
    if (data == 0 || (size != AUDIO_FFT_SIZE && size != AUDIO_MEL_FFT_SIZE)) return;
    fft_q15_init();
    for (i = 1u, j = 0u; i < size; ++i) {
        uint32_t bit = size >> 1;
        while (j & bit) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) { complex_q15_t temp = data[i]; data[i] = data[j]; data[j] = temp; }
    }
    for (length = 2u; length <= size; length <<= 1) {
        uint32_t half = length >> 1;
        uint32_t step = AUDIO_MEL_FFT_SIZE / length;
        for (i = 0; i < size; i += length) {
            for (j = 0; j < half; ++j) {
                complex_q15_t w = twiddle[j * step];
                int32_t wi = inverse ? -(int32_t)w.im : (int32_t)w.im;
                complex_q15_t odd = data[i + j + half];
                int32_t tr = ((int32_t)w.re * odd.re - wi * odd.im + 16384) >> 15;
                int32_t ti = ((int32_t)w.re * odd.im + wi * odd.re + 16384) >> 15;
                int32_t er = data[i + j].re;
                int32_t ei = data[i + j].im;
                /* One-bit scaling per stage guarantees overflow-free Q15. */
                data[i + j].re = sat16((er + tr) >> 1);
                data[i + j].im = sat16((ei + ti) >> 1);
                data[i + j + half].re = sat16((er - tr) >> 1);
                data[i + j + half].im = sat16((ei - ti) >> 1);
            }
        }
    }
}
