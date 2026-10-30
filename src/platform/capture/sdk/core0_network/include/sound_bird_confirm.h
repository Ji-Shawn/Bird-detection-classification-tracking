#ifndef SOUND_BIRD_CONFIRM_H
#define SOUND_BIRD_CONFIRM_H
#include <stdint.h>
#include <string.h>
#include <math.h>
#include "sound_round_policy.h"

/* A closed-set bird classifier can be confident on background noise.
 * Motor permission requires the current species above threshold and the
 * same species in two of the latest three independent three-second windows.
 * Direction and power qualification remain separate. */
typedef struct {
    uint64_t end,recognized;
    unsigned streak,percent,count,bird[3];
} sound_bird_confirm;
static inline void sound_bird_confirm_clear(sound_bird_confirm *c) {
    memset(c,0,sizeof *c);
}
static inline void sound_bird_confirm_push_config(sound_bird_confirm *c,
        unsigned bird,float score,unsigned percent,uint64_t end,uint64_t now,
        unsigned mask,uint32_t min_gap_us,uint32_t reset_gap_us) {
    if(c->percent!=percent){sound_bird_confirm_clear(c);c->percent=percent;}
    if(mask!=15u || !end || end>now || now-end>reset_gap_us){
        sound_bird_confirm_clear(c);return;
    }
    if(end<=c->end)return; /* Repeated callbacks are not independent evidence. */
    if(c->end && end-c->end<min_gap_us)return;
    if(c->end && end-c->end>reset_gap_us)c->streak=c->count=0;
    c->end=end;
    if(bird>=60u || !isfinite(score) || score<=percent/100.f || score>1.f)
        bird=UINT32_MAX;
    else c->recognized=end;
    for(unsigned i=2;i>0;i--)c->bird[i]=c->bird[i-1];
    c->bird[0]=bird;if(c->count<3u)c->count++;
    c->streak=0;
    if(bird!=UINT32_MAX)for(unsigned i=0;i<c->count;i++)c->streak+=c->bird[i]==bird;
}
/* Noise-floor learning follows the newest independent classifier result,
 * even when the live direction session retains its earlier display score.
 * Eight seconds also bridge one short low-score window in a bird call. */
static inline int sound_bird_confirm_recent_config(const sound_bird_confirm *c,
        uint64_t now,unsigned mask,uint32_t reset_gap_us) {
    return mask==15u && c->recognized && now>=c->recognized &&
        now-c->recognized<=reset_gap_us;
}
static inline int sound_bird_confirm_read_config(const sound_bird_confirm *c,
        uint64_t now,unsigned mask,uint32_t reset_gap_us) {
    return c->streak>=2u && sound_bird_confirm_recent_config(c,now,mask,reset_gap_us);
}
/* Default wrappers preserve existing callers and the retained M45 boundary tests. */
static inline void sound_bird_confirm_push(sound_bird_confirm *c,
        unsigned bird,float score,unsigned percent,uint64_t end,uint64_t now,unsigned mask) {
    sound_bird_confirm_push_config(c,bird,score,percent,end,now,mask,
        SOUND_ROUND_RESULT_GAP_US,SOUND_ROUND_RESET_GAP_US);
}
static inline int sound_bird_confirm_recent(const sound_bird_confirm *c,
        uint64_t now,unsigned mask) {
    return sound_bird_confirm_recent_config(c,now,mask,SOUND_ROUND_RESET_GAP_US);
}
static inline int sound_bird_confirm_read(const sound_bird_confirm *c,
        uint64_t now,unsigned mask) {
    return c->streak>=2u && sound_bird_confirm_recent(c,now,mask);
}
#endif
