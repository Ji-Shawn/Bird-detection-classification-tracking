#ifndef AUDIO_MODEL_INPUT_H
#define AUDIO_MODEL_INPUT_H

#include <stdint.h>

#define AUDIO_MODEL_MEL_BINS 128u
#define AUDIO_MODEL_TIME_FRAMES 400u

/* Legacy DISPLAY-history tensor, not the CoordinateNet model input.
 * At 32 kHz, 400 network hops of 480 samples span SIX seconds.
 * Use model_logmel32.h for the float32 128x400 / five-second model contract. */
typedef struct {
    uint16_t mel[AUDIO_MODEL_MEL_BINS][AUDIO_MODEL_TIME_FRAMES];
    uint32_t sequence;
    uint32_t valid_frames;
    uint64_t timestamp_us;
} audio_model_tensor_t;

void audio_model_tensor_reset(void);
void audio_model_tensor_push(const uint16_t mel[AUDIO_MODEL_MEL_BINS],
                             uint32_t sequence, uint64_t timestamp_us);
void audio_model_tensor_push_missing(uint32_t frames);
/* Returned data is coherent and remains stable until the next acquire call.
 * Producer and consumer are expected to run on CPU1; a cross-core/PL consumer
 * must add an explicit cache-maintained shared-memory ownership protocol. */
const audio_model_tensor_t *audio_model_tensor_acquire(void);

#endif
