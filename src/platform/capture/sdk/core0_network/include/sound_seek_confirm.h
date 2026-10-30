#ifndef SOUND_SEEK_CONFIRM_H
#define SOUND_SEEK_CONFIRM_H
#include <stdint.h>
#include <string.h>
#include "servo_calibration.h"

typedef struct {
    uint64_t last,seen,time[32];
    int32_t target[32];
    unsigned count;
} sound_seek_confirm;
static inline void sound_seek_confirm_clear(sound_seek_confirm *c) {
    memset(c,0,sizeof *c);
}
static inline void sound_seek_confirm_expire(sound_seek_confirm *c,uint64_t now) {
    if(c->count && (now<c->last || now-c->last>SERVO_SOUND_CONFIRM_GAP_US))
        sound_seek_confirm_clear(c);
}
static inline int32_t sound_seek_delta(int32_t a,int32_t b){
    int32_t d=a-b;while(d>180000)d-=360000;while(d< -180000)d+=360000;return d;
}
/* A short chirp may have gaps or a few reflected directions. Require a
 * three-quarter spatial consensus over timestamped observations. Its fixed
 * angular clusters cannot drift along with random successive noise steps. */
static inline int sound_seek_confirm_push_config(sound_seek_confirm *c,int32_t target,
        unsigned quality,uint64_t captured,uint64_t now,unsigned required,
        int32_t *out,unsigned quality_min,int32_t jitter_mdeg) {
    sound_seek_confirm_expire(c,now);
    if(quality<quality_min || quality>32767u ||
       !captured || captured>now || now-captured>SERVO_SOUND_CONFIRM_GAP_US)return 0;
    if(captured<=c->seen)return 0;
    c->seen=captured;
    if(c->count&&captured-c->last<SERVO_SOUND_CONFIRM_SAMPLE_US)return 0;
    unsigned keep=0;
    for(unsigned i=0;i<c->count;i++)if(captured-c->time[i]<=1800000u){
        c->time[keep]=c->time[i];c->target[keep++]=c->target[i];
    }
    if(keep==32u){memmove(c->time,c->time+1,31*sizeof c->time[0]);memmove(c->target,c->target+1,31*sizeof c->target[0]);keep--;}
    c->count=keep+1;c->time[keep]=captured;c->target[keep]=target;c->last=captured;
    unsigned best=0;int32_t result=0;uint64_t span=0;
    for(unsigned a=0;a<c->count;a++){
        unsigned count=0;int64_t sum=0;uint64_t first=0,last=0;
        for(unsigned i=0;i<c->count;i++){
            int32_t d=sound_seek_delta(c->target[i],c->target[a]);
            if(d< -jitter_mdeg||d>jitter_mdeg)continue;
            if(!count){first=c->time[i];}
            last=c->time[i];count++;sum+=d;
        }
        if(count>best || (count==best&&last-first>span)){best=count;result=c->target[a]+(int32_t)(sum/(int64_t)count);span=last-first;}
    }
    if(best<SERVO_SOUND_CONFIRM_MIN_SAMPLES || best*4u<c->count*3u || span<required)return 0;
    *out=result;
    return 1;
}
/* Default wrapper preserves isolated callers and the established policy. */
static inline int sound_seek_confirm_push(sound_seek_confirm *c,int32_t target,
        unsigned quality,uint64_t captured,uint64_t now,unsigned required,int32_t *out) {
    return sound_seek_confirm_push_config(c,target,quality,captured,now,required,out,
        SERVO_SOUND_DIRECTION_QUALITY_MIN,SERVO_SOUND_DIRECTION_JITTER_MDEG);
}
#endif
