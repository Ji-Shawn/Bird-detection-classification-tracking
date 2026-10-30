#ifndef SOUND_TUNING_H
#define SOUND_TUNING_H
#include <stdint.h>
/* RAM-only sound acceptance/slew settings. This does not control PWM or leases.
 * cmd24/schema1: 46 bytes [command,schema,BE boot/revision/request,8 BE floats].
 * [bird threshold %, energy/floor ratio, quality Q15, jitter degrees,
 *  acquire ms, reaim ms, reaim deadband degrees, commanded pan degrees/s]. */
enum {SOUND_TUNE_THRESHOLD,SOUND_TUNE_ENERGY,SOUND_TUNE_QUALITY,SOUND_TUNE_JITTER,
      SOUND_TUNE_ACQUIRE,SOUND_TUNE_REAIM,SOUND_TUNE_DEADBAND,SOUND_TUNE_SPEED};
#define SOUND_TUNING_DEFAULTS {80.f,4.f,1024.f,12.f,300.f,600.f,15.f,100.f}
float servo_tracking_audio_value(unsigned index);
uint32_t servo_tracking_audio_revision(void);
uint64_t servo_tracking_audio_evidence_after(void);
int servo_tracking_audio_threshold(unsigned percent);
int servo_tracking_audio_command(uint32_t boot_id,const uint8_t *payload,unsigned bytes);
void servo_tracking_audio_status(uint32_t words[16],uint32_t boot_id);
/* Fusion owns classifier/energy/session evidence and clears it on adoption. */
int fusion_audio_tuning_command(uint32_t boot_id,const uint8_t *payload,unsigned bytes);
#endif
