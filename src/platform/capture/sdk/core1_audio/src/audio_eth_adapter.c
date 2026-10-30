#include "audio_eth_adapter.h"
#include <string.h>
_Static_assert(sizeof(av_audio_result_payload_t)==1280u,"Result ABI changed");
void audio_eth_adapter_pack(av_audio_result_payload_t *out,
    const int16_t pcm[480],const uint16_t mel[128],const direction_result_t *direction) {
    if(!out || !pcm || !mel || !direction) return;
    /* Inputs must not alias out. One network PCM packet remains 960 bytes. */
    memset(out,0,sizeof(*out));
    memcpy(out->enhanced_pcm,pcm,sizeof(out->enhanced_pcm));
    memcpy(out->mel,mel,sizeof(out->mel));
    if(direction->valid) {
        out->direction_valid=1;
        out->direction_q9_7=direction->angle_q9_7;
        out->confidence_q0_15=direction->confidence_q0_15>32767u?32767u:direction->confidence_q0_15;
    }
}
