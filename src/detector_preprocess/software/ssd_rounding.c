#include "ssd_preprocess_pl.h"
#include <math.h>
static float green_norm(uint16_t p) {
    unsigned g=(p>>5)&63;g=(g<<2)|(g>>4);
    return ((float)g/255.0f-.456f)/.224f;
}
unsigned ssd_repair_rounding(const uint16_t *p,int8_t *out) {
    unsigned repairs=0;
    for(unsigned i=0;i<320u*320u;i++)if(out[3*i+1]==127) {
        unsigned x=i%320,y=i/320,x0=6*x+2,y0=(54*y+19)/16;
        float dy=(float)((54*y+19)%16)/16.0f;
        float a=green_norm(p[y0*1920+x0]),b=green_norm(p[y0*1920+x0+1]);
        float d=green_norm(p[(y0+1)*1920+x0]),e=green_norm(p[(y0+1)*1920+x0+1]);
        float v=(1-dy)*(.5f*a+.5f*b)+dy*(.5f*d+.5f*e);
        float q=v/.01865844987332821f;int t=(int)floorf(q);float f=q-t;
        out[3*i+1]=(int8_t)(t+(f>.5f || (f==.5f && (t&1)))-14);repairs++;
    }
    return repairs;
}
