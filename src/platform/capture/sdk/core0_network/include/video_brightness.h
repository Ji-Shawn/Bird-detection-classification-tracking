#ifndef VIDEO_BRIGHTNESS_H
#define VIDEO_BRIGHTNESS_H
#include <stdint.h>
typedef struct { uint64_t sum_y; uint32_t pixels; } video_brightness_t;
void video_brightness_reset(video_brightness_t *s);
void video_brightness_accumulate(video_brightness_t *s, const uint16_t *p, uint32_t n);
uint16_t video_brightness_gain(const video_brightness_t *s, int enabled);
void video_brightness_apply(uint16_t *p, uint32_t n, uint16_t gain_q8);
#endif
