#include "audio_health.h"
#include <string.h>
void audio_health_reset(audio_health_t *s) { memset(s,0,sizeof(*s)); }
uint8_t audio_health_update(audio_health_t *s, const int32_t raw[480][4]) {
    unsigned c,i;
    s->mask=0;
    for(c=0;c<4;++c) {
        unsigned nonzero=0,changed=0,clipped=0,invalid=0;
        for(i=0;i<480;++i) {
            int32_t v=raw[i][c];
            nonzero+=(v!=0);
            changed+=(i && v!=raw[i-1][c]);
            clipped+=(v>=8388607 || v<=-8388608);
            invalid+=(v>8388607 || v< -8388608);
        }
        /* Transport-health heuristic, NOT an acoustic activity detector.
         * >=87.5% exact zeros, constant codes, >1% rails or invalid 24-bit
         * samples disable immediately. Three clean hops restore (45 ms at 32k). */
        if(nonzero<=60 || changed<4 || clipped>4 || invalid) s->clean_hops[c]=0;
        else if(s->clean_hops[c]<3) ++s->clean_hops[c];
        if(s->clean_hops[c]>=3) s->mask|=(uint8_t)(1u<<c);
    }
    return s->mask;
}
