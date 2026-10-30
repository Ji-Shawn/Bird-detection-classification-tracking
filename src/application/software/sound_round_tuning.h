#ifndef SOUND_ROUND_TUNING_H
#define SOUND_ROUND_TUNING_H
#include <stdint.h>
#include "sound_round_policy.h"
/* cmd26/schema1 native 30B: command,schema,BE boot/revision/request,4 BE ms.
 * SRT2 schema1 is appended at byte1192; existing SND2's eight values stay fixed. */
enum {SOUND_ROUND_TUNE_CAPTURE,SOUND_ROUND_TUNE_MIN_GAP,
      SOUND_ROUND_TUNE_RESET_GAP,SOUND_ROUND_TUNE_PAUSE};
void sound_round_tuning_init(uint64_t now);
uint32_t sound_round_tuning_value(unsigned index);
uint32_t sound_round_tuning_revision(void);
int sound_round_tuning_command(uint32_t boot,const uint8_t *payload,unsigned bytes,uint64_t now);
void sound_round_tuning_status(uint32_t words[16],uint32_t boot,uint64_t now);
int fusion_sound_round_tuning_command(uint32_t boot,const uint8_t *payload,unsigned bytes);
#endif
