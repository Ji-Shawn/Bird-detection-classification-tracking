#ifndef DIRECTION_GATE_H
#define DIRECTION_GATE_H
#include <stdint.h>
#include <string.h>

/* Classification starts a bird-sound session; live spatially consistent
 * observations sustain it until silence, loss or transport interruption. */
typedef struct {
    uint64_t timestamp_us;
    int16_t angle_q9_7;
    uint16_t confidence_q0_15;
    uint32_t valid;
} fusion_direction_sample;
typedef struct {
    fusion_direction_sample sample;
    uint64_t window_end_us;
    float bird_score;
    uint32_t bird_class, threshold_percent;
    fusion_direction_sample live;
    float live_energy, reference_energy;
    uint64_t last_sound_us;
    uint32_t session_active;
} direction_gate;
static inline void direction_gate_clear(direction_gate *g) {
    memset(&g->sample,0,sizeof g->sample);
    g->window_end_us=0;g->bird_score=0;g->bird_class=UINT32_MAX;
    g->session_active=0;g->last_sound_us=0;g->reference_energy=0;
}
static inline void direction_gate_init(direction_gate *g) {
    memset(g,0,sizeof *g);direction_gate_clear(g);g->threshold_percent=80;
}
static inline int direction_gate_threshold(direction_gate *g,unsigned percent) {
    if(percent<1 || percent>99)return -1;
    direction_gate_clear(g);g->threshold_percent=percent;return 0;
}
static inline void direction_gate_accept(direction_gate *g, unsigned bird,
        float score,uint64_t end,const fusion_direction_sample *sample) {
    if(g->session_active)return; /* A brief classifier fluctuation cannot drop ongoing sound. */
    direction_gate_clear(g);g->window_end_us=end;
    if(bird>=60 || !(score>=0 && score<=1))return;
    g->bird_class=bird;g->bird_score=score;
    if(!(score>(float)g->threshold_percent/100.0f) || !sample->valid ||
       !sample->confidence_q0_15 || sample->confidence_q0_15>32767 ||
       !sample->timestamp_us || sample->timestamp_us>end ||
       end-sample->timestamp_us>5000000u)return;
    g->sample=*sample;
}
static inline int direction_gate_read(const direction_gate *g,uint64_t now,
        fusion_direction_sample *out) {
    memset(out,0,sizeof *out);
    if(g->session_active) {
        if(!g->sample.valid || now<g->last_sound_us || now-g->last_sound_us>750000u)return 0;
        *out=g->sample;return 1;
    }
    if(!g->sample.valid || now<g->window_end_us ||
       now-g->window_end_us>8000000u || now-g->sample.timestamp_us>8000000u)return 0;
    *out=g->sample;return 1;
}
static inline unsigned direction_angle_distance(int a,int b) {
    int d=a-b;while(d>180*128)d-=360*128;while(d< -180*128)d+=360*128;
    return (unsigned)(d<0?-d:d);
}
static inline void direction_gate_stream(direction_gate *g,const fusion_direction_sample *live,
                                        float energy,unsigned mask,uint64_t now) {
    if(g->session_active && (now<g->last_sound_us || now-g->last_sound_us>750000u))
        direction_gate_clear(g);
    if(mask!=15 || !live || !live->valid || live->confidence_q0_15<=512 ||
       live->confidence_q0_15>32767 || !live->timestamp_us || now<live->timestamp_us ||
       now-live->timestamp_us>250000u || !(energy>0))return;
    if(live->timestamp_us<=g->live.timestamp_us)return;
    g->live=*live;g->live_energy=energy;
    if(g->session_active && energy>=g->reference_energy/16.f &&
       direction_angle_distance(live->angle_q9_7,g->sample.angle_q9_7)<=60u*128u) {
        g->sample=*live;g->last_sound_us=live->timestamp_us;
    }
}
static inline int direction_gate_start_session(direction_gate *g,uint64_t now) {
    if(g->session_active)return 1;
    if(!g->sample.valid || !g->live.valid || now<g->window_end_us ||
       now-g->window_end_us>8000000u || now<g->sample.timestamp_us ||
       now-g->sample.timestamp_us>8000000u || now<g->live.timestamp_us ||
       now-g->live.timestamp_us>250000u || !(g->live_energy>0) ||
       direction_angle_distance(g->live.angle_q9_7,g->sample.angle_q9_7)>60u*128u)return 0;
    g->session_active=1;g->sample=g->live;g->last_sound_us=g->live.timestamp_us;
    g->reference_energy=g->live_energy;return 1;
}
#endif
