#include "fusion_bridge.h"
#include "fusion_math.h"
#include "av_shared.h"
#include "model_logmel32.h"
#include "xil_cache.h"
#include <string.h>
/* This complete section is mapped noncacheable on both A9s. One producer,
 * one consumer; READY/READING may never be overwritten. */
void fusion_audio_publish(const float *x,uint64_t timestamp,const fusion_direction_sample *direction) {
    fusion_audio_slot *s=(fusion_audio_slot *)FUSION_SHARED;
    if(s->state){s->dropped++;return;}
    s->state=1;av_memory_barrier();
    fusion_quant_audio(x,s->input);s->sequence++;s->timestamp_us=timestamp;s->direction=*direction;
    memcpy((void *)FUSION_SLOT_PCM,model_logmel32_pcm(),160000u*4u);
    Xil_DCacheFlushRange(FUSION_SLOT_PCM,160000u*4u);
    av_memory_barrier();s->state=2;
}
void fusion_yield(void) {}
