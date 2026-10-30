#ifndef AUDIO_QUALITY_H
#define AUDIO_QUALITY_H
#include <stdint.h>
typedef struct {
    int32_t minimum,maximum;
    float mean,rms;
    uint32_t zeros,clips,invalid,samples;
} audio_channel_quality_t;
/* Raw interleaved 480x4 signed32 containers. rms includes DC; mean is DC.
 * zero/clipping ratio = corresponding count / samples. CPU1/JTAG diagnostic,
 * not a new network field. No samples are replaced or normalized here. */
void audio_quality_measure(const int32_t pcm[480][4],audio_channel_quality_t out[4]);
#endif
