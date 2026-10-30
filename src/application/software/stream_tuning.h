#ifndef M44_STREAM_TUNING_H
#define M44_STREAM_TUNING_H
#include <stdint.h>
/* cmd25/schema1: 22 bytes [command,schema,BE boot,revision,request,2 floats].
 * Values: vertical scan degrees/s (0.5..10), preview publication FPS (1..4).
 * Atomic RAM settings; no tracking/mode/lease or standalone actuator command. */
void stream_tuning_init(void);
int stream_tuning_command(uint32_t boot,const uint8_t *payload,unsigned bytes);
void stream_tuning_status(uint32_t words[16],uint32_t boot);
uint32_t stream_preview_interval_us(void);
#endif
