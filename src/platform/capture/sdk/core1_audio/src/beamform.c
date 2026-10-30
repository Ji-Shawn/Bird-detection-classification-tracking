#include "audio_dsp.h"
#include "audio_array.h"

#include <math.h>
#include <string.h>

static uint16_t delay_integer[4];
static uint16_t delay_fraction_q15[4];
static uint8_t channel_mask=15u, fallback_channel;
static int steering_valid=1;
void beamform_set_channels(uint8_t mask, uint8_t fallback, int valid) {
    channel_mask=mask&15u; fallback_channel=fallback&3u; steering_valid=valid;
}
static int32_t saturate24(int64_t v) {
    if(v>8388607) return 8388607;
    if(v< -8388608) return -8388608;
    return (int32_t)v;
}

void beamform_reset(void) {
    channel_mask=15u; fallback_channel=0; steering_valid=1;
    memset(delay_integer, 0, sizeof(delay_integer));
    memset(delay_fraction_q15, 0, sizeof(delay_fraction_q15));
}

void beamform_set_direction(int16_t angle_q9_7) {
    float radians = ((float)angle_q9_7 / 128.0f) * 0.017453292519943295f;
    float x = sinf(radians), y = cosf(radians);
    const float px[4] = AUDIO_ARRAY_X_METRES;
    const float py[4] = AUDIO_ARRAY_Y_METRES;
    float arrival[4], latest;
    uint32_t channel;
    for (channel = 0u; channel < 4u; ++channel)
        arrival[channel] = -(px[channel] * x + py[channel] * y) * (float)AUDIO_SAMPLE_RATE / AUDIO_SOUND_SPEED_M_S;
    latest = arrival[0];
    for (channel = 1u; channel < 4u; ++channel)
        if (arrival[channel] > latest) latest = arrival[channel];
    for (channel = 0u; channel < 4u; ++channel) {
        float delay = latest - arrival[channel];
        uint32_t integer = (uint32_t)delay;
        uint32_t fraction = (uint32_t)((delay - (float)integer) * 32768.0f + 0.5f);
        if (integer > 34u) integer = 34u;
        if (fraction > 32767u) fraction = 32767u;
        delay_integer[channel] = (uint16_t)integer;
        delay_fraction_q15[channel] = (uint16_t)fraction;
    }
}

void beamform_delay_sum(const int32_t pcm[4][AUDIO_FFT_SIZE], uint32_t first,
                        int32_t output[480]) {
    uint32_t sample, channel, count=0;
    if (pcm == 0 || output == 0 || first < 35u || first + 480u > AUDIO_FFT_SIZE) return;
    for(channel=0;channel<4;++channel) count+=(channel_mask>>channel)&1u;
    for (sample = 0u; sample < 480u; ++sample) {
        int64_t sum = 0;
        if(!count) { output[sample]=0; continue; }
        if(!steering_valid) {
            output[sample]=(channel_mask & (1u<<fallback_channel)) ?
                saturate24(pcm[fallback_channel][first+sample]):0;
            continue;
        }
        for (channel = 0u; channel < 4u; ++channel) {
            if(!(channel_mask & (1u<<channel))) continue;
            uint32_t index = first + sample - delay_integer[channel];
            uint32_t fraction = delay_fraction_q15[channel];
            int64_t value = (int64_t)pcm[channel][index] * (32768u - fraction) +
                            (int64_t)pcm[channel][index - 1u] * fraction;
            sum += value;
        }
        /* Signed64 Q15 sum, normalized only by contributing microphones.
         * Symmetric nearest rounding avoids negative DC truncation bias. */
        {
            int64_t divisor=(int64_t)count*32768;
            output[sample]=saturate24(sum>=0 ? (sum+divisor/2)/divisor :
                                      -((-sum+divisor/2)/divisor));
        }
    }
}
