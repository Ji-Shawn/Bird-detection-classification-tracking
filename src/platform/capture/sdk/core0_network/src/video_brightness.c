#include "video_brightness.h"
/* Unsigned integer RGB565; Q8 gain, round-to-nearest, explicit saturation.
 * Statistics are reset for EACH complete staged frame, never previous-frame. */
static uint8_t luma[65536];
static int initialized;
static uint16_t tone_gain[192], cached_gain;
void video_brightness_reset(video_brightness_t *s) {
    uint32_t p;
    if (!initialized) {
        for (p=0; p<65536u; ++p) {
            uint32_t r=p>>11, g=(p>>5)&63u, b=p&31u;
            r=(r<<3)|(r>>2); g=(g<<2)|(g>>4); b=(b<<3)|(b>>2);
            luma[p]=(uint8_t)((77u*r+150u*g+29u*b+128u)>>8);
        }
        initialized=1;
    }
    s->sum_y=0; s->pixels=0;
}
void video_brightness_accumulate(video_brightness_t *s, const uint16_t *p, uint32_t n) {
    uint32_t i;
    for(i=0;i<n;++i) s->sum_y+=luma[p[i]];
    s->pixels+=n;
}
uint16_t video_brightness_gain(const video_brightness_t *s, int enabled) {
    /* PL auto_vision owns enhancement. Keep the existing statistics/ABI,
     * but never request the PS second pass (including FORCE_DAY/bypass). */
    (void)s; (void)enabled;
    return 256u;
}
void video_brightness_apply(uint16_t *p, uint32_t n, uint16_t g) {
    uint32_t i;
    if(g<=256u) return; /* Bit-exact raw path: no unpack/repack. */
    if(g>2048u) g=2048u;
    if(g!=cached_gain) {
        /* Monotonic highlight-anchored curve M' = 192*g*M /
         * (192*256 + (g-256)*M). Same RGB ratio, black=0, knee=192.
         * 192 divisions per frame gain change, never per pixel on Cortex-A9.
         * All products unsigned32 (maximum numerator 100663296). */
        for(i=0;i<192u;++i)
            tone_gain[i]=(uint16_t)((192u*256u*g)/(192u*256u+(g-256u)*i));
        cached_gain=g;
    }
    for(i=0;i<n;++i) {
        uint32_t r=p[i]>>11, green=(p[i]>>5)&63u, b=p[i]&31u;
        uint32_t m=(r<<3)|(r>>2), t=(green<<2)|(green>>4), gain;
        if(t>m) m=t;
        t=(b<<3)|(b>>2); if(t>m) m=t;
        if(m==0u || m>=192u) continue;
        gain=tone_gain[m];
        r=(r*gain+128u)>>8; green=(green*gain+128u)>>8; b=(b*gain+128u)>>8;
        if(r>31u) r=31u;
        if(green>63u) green=63u;
        if(b>31u) b=31u;
        p[i]=(uint16_t)((r<<11)|(green<<5)|b);
    }
}
