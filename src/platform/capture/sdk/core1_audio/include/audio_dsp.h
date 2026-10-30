#ifndef AUDIO_DSP_H
#define AUDIO_DSP_H

#include <stdint.h>

#define AUDIO_SAMPLE_RATE 32000u
#define AUDIO_HOP_SAMPLES 480u /* Frozen DMA/network block: 15 ms at 32 kHz. */

#define AUDIO_FFT_SIZE 1024u
#define AUDIO_MEL_FFT_SIZE 1024u
#define AUDIO_PAIR_COUNT 6u
#define AUDIO_GCC_RESIDUAL_LIMIT 3.0f

typedef struct { int16_t re, im; } complex_q15_t;

typedef struct {
    int16_t lag_q8_8[AUDIO_PAIR_COUNT];
    uint16_t pair_confidence_q0_15[AUDIO_PAIR_COUNT];
    uint8_t valid_pair_mask;
} tdoa_result_t;

typedef struct {
    int16_t angle_q9_7;
    uint16_t confidence_q0_15;
    uint8_t valid;
    uint8_t reserved;
    int16_t lag_q8_8[AUDIO_PAIR_COUNT];
    uint16_t residual_q8_8;
} direction_result_t;

void fft_q15_init(void);
void fft_q15(complex_q15_t data[AUDIO_FFT_SIZE], int inverse);
void fft_q15_n(complex_q15_t *data, uint32_t size, int inverse);
int gcc_phat_4ch(const int32_t pcm[4][AUDIO_FFT_SIZE], tdoa_result_t *out);
int tdoa_to_direction(const tdoa_result_t *tdoa, direction_result_t *out);
void beamform_reset(void);
void beamform_set_channels(uint8_t mask, uint8_t fallback, int steering_valid);
void beamform_set_direction(int16_t angle_q9_7);
void beamform_delay_sum(const int32_t pcm[4][AUDIO_FFT_SIZE], uint32_t first,
                        int32_t output[480]);
void audio_process_reset(void);
int audio_process_hop(const int32_t beamformed[480], int16_t pcm_out[480],
                      uint16_t mel_out[128], uint8_t bird_active);
uint16_t noise_gain_q15(uint32_t power, uint32_t *noise_psd);

#endif
