#ifndef SOUND_ENERGY_GATE_H
#define SOUND_ENERGY_GATE_H
#include <stdint.h>
#include <string.h>
#include <math.h>

/* Band-filtered mean-square PCM energy, not a sound-pressure calibration.
 * Learn the lower fifth of a 3.84-second history. Confident bird sessions may
 * lower the floor, but cannot teach a sustained bird call as background. */
typedef struct {
    float history[64],floor,energy;
    uint64_t last,seen,signal;
    unsigned count,index,passed,rejected;
} sound_energy_gate;
static inline int sound_energy_gate_push_config(sound_energy_gate *g,float energy,
        unsigned mask,uint64_t captured,uint64_t now,unsigned freeze_rise,float ratio) {
    if(mask!=15u || (g->seen && (now<g->seen || now-g->seen>500000u)))
        memset(g,0,sizeof *g);
    if(mask!=15u || !isfinite(energy) || energy<=0 || !captured ||
       captured>now || now-captured>250000u || captured<=g->seen)return 0;
    g->seen=captured;g->energy=energy;
    if(g->floor>0&&energy>=g->floor*ratio)g->signal=captured;
    if(g->last && captured-g->last<60000u)return 0;
    g->last=captured;g->history[g->index++]=energy;g->index%=64u;
    if(g->count<64u)g->count++;
    if(g->count<16u)return 1;
    float values[64];memcpy(values,g->history,g->count*sizeof(float));
    for(unsigned i=1;i<g->count;i++){
        float v=values[i];unsigned j=i;
        while(j&&values[j-1]>v){values[j]=values[j-1];j--;}
        values[j]=v;
    }
    float base=values[g->count/5u];
    if(!(g->floor>0))g->floor=base;
    else if(base<g->floor)g->floor+=(base-g->floor)/8.f;
    else if(!freeze_rise)g->floor+=(base-g->floor)/32.f;
    if(energy>=g->floor*ratio)g->passed++;else g->rejected++;
    return 1;
}
static inline int sound_energy_gate_push(sound_energy_gate *g,float energy,
        unsigned mask,uint64_t captured,uint64_t now,unsigned freeze_rise) {
    return sound_energy_gate_push_config(g,energy,mask,captured,now,freeze_rise,4.f);
}
static inline int sound_energy_gate_read(const sound_energy_gate *g,
        uint64_t captured,uint64_t now) {
    return g->count>=16u && g->floor>0 && g->signal &&
        g->seen>=g->signal && g->seen-g->signal<=150000u &&
        captured && captured<=g->seen && g->seen-captured<=80000u &&
        now>=g->seen && now-g->seen<=80000u;
}
#endif
