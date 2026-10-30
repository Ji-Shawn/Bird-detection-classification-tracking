#ifndef AUDIO_HEALTH_H
#define AUDIO_HEALTH_H
#include <stdint.h>
typedef struct { uint8_t clean_hops[4]; uint8_t mask; } audio_health_t;
void audio_health_reset(audio_health_t *s);
uint8_t audio_health_update(audio_health_t *s, const int32_t raw[480][4]);
#endif
