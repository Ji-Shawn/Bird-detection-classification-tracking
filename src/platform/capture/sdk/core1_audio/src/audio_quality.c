#include "audio_quality.h"
#include <math.h>
#include <string.h>
#include <limits.h>
void audio_quality_measure(const int32_t pcm[480][4],audio_channel_quality_t out[4]) {
    uint32_t c,i;
    if(!pcm||!out) return;
    memset(out,0,4*sizeof(*out));
    for(c=0;c<4;++c) {
        int64_t sum=0;
        /* Double protects the diagnostic against arbitrary invalid int32
         * containers without overflowing a sum-of-squares integer. */
        double energy=0;
        out[c].minimum=INT32_MAX;out[c].maximum=INT32_MIN;
        for(i=0;i<480;++i) {
            int32_t v=pcm[i][c];
            if(v<out[c].minimum)out[c].minimum=v;
            if(v>out[c].maximum)out[c].maximum=v;
            sum+=v;energy+=(double)v*v;
            out[c].zeros+=(v==0);
            out[c].clips+=(v>=8388607||v<=-8388608);
            out[c].invalid+=(v>8388607||v< -8388608);
        }
        out[c].samples=480;out[c].mean=(float)((double)sum/480.0);
        out[c].rms=(float)sqrt(energy/480.0);
    }
}
