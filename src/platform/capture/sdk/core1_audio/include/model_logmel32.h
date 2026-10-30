#ifndef MODEL_LOGMEL32_H
#define MODEL_LOGMEL32_H
#include <stdint.h>
/* CPU1-owned, float32 frequency-major [128][400]. Snapshot stable until the
 * next complete 160000-sample segment. No cross-core/cache ownership implied.
 * Raw signed24 input in int32; callers reset on discontinuity/unhealthy input.
 * Centered periodic Hann, 1024/400, Slaney area-normalized 20..16000 Hz.
 * 401 centered columns, global ref=max/top80 dB, then numpy.resize semantics
 * (flatten/truncate to 128x400), matching the frozen MobileNetV2 training.
 * Silence produces zeros (explicit safe deviation from peak normalization).
 */
void model_logmel32_reset(void);
/* Real PCM length only; the padded model input always has 160000 samples.
 * Adopting a different target discards an incomplete old capture. */
int model_logmel32_set_capture_samples(uint32_t samples);
void model_logmel32_push(const int32_t *pcm, uint32_t count);
/* Samples after the newest completed capture within the last push. This makes
 * completion timestamps exact when capture is not divisible by a 480 hop. */
uint32_t model_logmel32_tail_samples(void);
uint32_t model_logmel32_ready(void);
const float *model_logmel32_data(void);
const int32_t *model_logmel32_pcm(void);
#endif
