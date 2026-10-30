#ifndef VISUAL_FEEDFORWARD_H
#define VISUAL_FEEDFORWARD_H
/* M47 command-compensated motion observer. Image drift alone is NOT target
 * velocity. Optical conversion is supplied by the user; zero disables an axis.
 * The camera term is accepted PWM-derived command position, never an encoder.
 * Static inline keeps the observer available to the existing native harnesses.
 */
#include <stdint.h>
#include <string.h>
#include <math.h>
#define VISUAL_FF_HISTORY 64u
typedef struct {float velocity;unsigned count;int direction;} visual_ff_axis;
typedef struct {
    struct {uint64_t at;float pose[2];} history[VISUAL_FF_HISTORY];
    unsigned head,used,baseline,reason;
    uint32_t sequence;
    uint64_t captured;
    float error[2],pose[2],width,height;
    visual_ff_axis axis[2];
} visual_ff_state;

static inline unsigned visual_ff_configured(const float c[8],unsigned axis) {
    return c[axis]>0.f && c[2u+axis]>0.f && c[4u+axis]>0.f;
}
static inline void visual_ff_reset(visual_ff_state *s,unsigned reason) {
    memset(s,0,sizeof *s);s->reason=reason;
}
static inline void visual_ff_history(visual_ff_state *s,uint64_t at,float pan,float tilt) {
    if(!isfinite(pan) || !isfinite(tilt))return;
    if(s->used && at<s->history[s->head].at)visual_ff_reset(s,2u);
    if(!s->used){s->head=0;s->used=1;}
    else if(at!=s->history[s->head].at) {
        s->head=(s->head+1u)%VISUAL_FF_HISTORY;
        if(s->used<VISUAL_FF_HISTORY)s->used++;
    }
    s->history[s->head].at=at;
    s->history[s->head].pose[0]=pan;s->history[s->head].pose[1]=tilt;
}
static inline int visual_ff_query(const visual_ff_state *s,uint64_t at,float pose[2]) {
    for(unsigned n=0;n<s->used;n++) {
        unsigned i=(s->head+VISUAL_FF_HISTORY-n)%VISUAL_FF_HISTORY;
        if(s->history[i].at<=at) {
            pose[0]=s->history[i].pose[0];pose[1]=s->history[i].pose[1];return 1;
        }
    }
    return 0;
}
static inline void visual_ff_clear_axes(visual_ff_state *s,unsigned reason) {
    memset(s->axis,0,sizeof s->axis);s->reason=reason;
}
static inline void visual_ff_observe(visual_ff_state *s,const float c[8],
    float x,float y,float width,float height,uint32_t sequence,uint64_t captured) {
    float p[2],e[2]={x,y};
    if(!visual_ff_configured(c,0) && !visual_ff_configured(c,1))return;
    /* Duplicates and delayed packets cannot refresh/confirm an estimate. The
     * controller applies its stronger source/time guards before this call. */
    if(s->captured && (captured<=s->captured || sequence==s->sequence))return;
    if(!isfinite(x) || !isfinite(y) || !isfinite(width) || !isfinite(height) ||
       width<=0.f || height<=0.f) {
        s->baseline=0;visual_ff_clear_axes(s,4u);return;
    }
    if(!visual_ff_query(s,captured,p)) {
        s->baseline=0;visual_ff_clear_axes(s,1u);return;
    }
    uint64_t elapsed=s->baseline?captured-s->captured:0;
    unsigned jump=s->baseline && (fabsf(x-s->error[0])>.2f || fabsf(y-s->error[1])>.2f ||
        width>=2.f*s->width || width<=.5f*s->width ||
        height>=2.f*s->height || height<=.5f*s->height);
    if(!s->baseline || elapsed<20000u || elapsed>250000u || jump) {
        visual_ff_clear_axes(s,jump?4u:(!s->baseline?1u:3u));
    } else {
        float dt=(float)elapsed*.000001f,alpha=dt/(c[6]*.001f+dt);
        s->reason=0;
        for(unsigned a=0;a<2;a++) {
            visual_ff_axis *v=s->axis+a;
            if(!visual_ff_configured(c,a)){memset(v,0,sizeof *v);continue;}
            float raw=(c[a]*(e[a]-s->error[a])+(p[a]-s->pose[a]))/dt;
            if(!isfinite(raw)){memset(v,0,sizeof *v);s->reason=4u;continue;}
            if(fabsf(raw)<=c[7]){memset(v,0,sizeof *v);continue;}
            int direction=raw>0.f?1:-1;
            if(v->direction && direction!=v->direction) {
                memset(v,0,sizeof *v);s->reason=5u;
            }
            v->direction=direction;
            if(v->count<2u)v->count++;
            v->velocity+=alpha*(raw-v->velocity);
        }
    }
    s->baseline=1;s->captured=captured;s->sequence=sequence;
    s->error[0]=x;s->error[1]=y;s->pose[0]=p[0];s->pose[1]=p[1];
    s->width=width;s->height=height;
}
static inline float visual_ff_contribution(const visual_ff_state *s,const float c[8],
    unsigned axis,uint64_t now,float error,float exit_deadband) {
    const visual_ff_axis *v=s->axis+axis;
    if(!visual_ff_configured(c,axis) || !s->baseline || v->count<2u ||
       now<s->captured || now-s->captured>=250000u || fabsf(v->velocity)<=c[7])return 0.f;
    float value=c[2u+axis]*v->velocity,cap=c[4u+axis];
    if(value>cap)value=cap;else if(value<-cap)value=-cap;
    /* Do not let an old direction drive farther from an already large error. */
    if(fabsf(error)>exit_deadband && value*error<0.f)return 0.f;
    uint64_t age=now-s->captured;
    if(age>150000u)value*=(float)(250000u-age)/100000.f;
    return value;
}
#endif
