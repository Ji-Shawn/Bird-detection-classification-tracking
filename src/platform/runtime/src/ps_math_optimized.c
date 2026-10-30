/* SSD stem specialization; frozen generic math remains the exact reference.
 * Repack OIHW weights once per call; reuse one centered 27-element input
 * patch across all 32 outputs. Eight output channels share each NEON MAC.
 * All rounding, Add and detection postprocessing remain unchanged.
 */
#define ps_conv ps_conv_reference
#define ps_add ps_add_reference
#include "ps_math.c"
#undef ps_conv
#undef ps_add
#include <string.h>
#if defined(__ARM_NEON)
#include <arm_neon.h>
/* Exact signed 64-bit product, floor shift, then ties-to-even. The supported
 * multiplier bound keeps the shifted value plus zero point inside int32. */
static int32x4_t requant4_28(int32x4_t acc,int mul,int zp) {
    int32x2_t m=vdup_n_s32(mul);
    int64x2_t a=vmull_s32(vget_low_s32(acc),m);
    int64x2_t b=vmull_s32(vget_high_s32(acc),m);
    int32x4_t base=vcombine_s32(vshrn_n_s64(a,28),vshrn_n_s64(b,28));
    int32x4_t frac=vandq_s32(vcombine_s32(vmovn_s64(a),vmovn_s64(b)),vdupq_n_s32(0x0fffffff));
    int32x4_t half=vdupq_n_s32(0x08000000);
    uint32x4_t round=vorrq_u32(vcgtq_s32(frac,half),
        vandq_u32(vceqq_s32(frac,half),vtstq_s32(base,vdupq_n_s32(1))));
    return vaddq_s32(vsubq_s32(base,vreinterpretq_s32_u32(round)),vdupq_n_s32(zp));
}
static int8x8_t requant8_28(int32x4_t lo,int32x4_t hi,int mul,int zp) {
    return vqmovn_s16(vcombine_s16(vqmovn_s32(requant4_28(lo,mul,zp)),
                                  vqmovn_s32(requant4_28(hi,mul,zp))));
}
#endif

/* Executed on the actual ARM NEON unit at startup, before camera capture.
 * Includes negative half ties, saturation and full signed accumulator range. */
volatile unsigned m17_requant_test_count,m17_requant_test_errors;
int ps_requant_selftest(void) {
#if defined(__ARM_NEON)
    unsigned seed=2276;
    static const int muls[]={742456,1,0x04000000,1342177};
    static const int32_t edge[]={0,1,-1,2,-2,0x7fffffff,(-2147483647-1),0x08000000,
        -0x08000000,0x18000000,-0x18000000,0x07ffffff,0x08000001};
    for(unsigned t=0;t<8192;t++) {
        int32_t a[8];int8_t actual[8];int mul=muls[t%4],zp=(int)(t%256)-128;
        for(unsigned j=0;j<8;j++) {
            seed=seed*1664525u+1013904223u;
            a[j]=t<sizeof(edge)/sizeof(edge[0])?edge[(t+j)%(sizeof(edge)/sizeof(edge[0]))]:(int32_t)seed;
        }
        vst1_s8(actual,requant8_28(vld1q_s32(a),vld1q_s32(a+4),mul,zp));
        for(unsigned j=0;j<8;j++) {
            ++m17_requant_test_count;
            if(actual[j]!=requant(a[j],mul,28,zp))++m17_requant_test_errors;
        }
    }
#endif
    return m17_requant_test_errors?-1:0;
}

/* Each quantized input pair has only 65536 possible values. Build the exact
 * original floating-point expression once per quantization configuration.
 * 32 tables use 2 MiB of Core0 DDR; no model, rounding or threshold changes. */
typedef struct { float sa,sb,sy;int azp,bzp,yzp;unsigned valid;int8_t values[65536]; } add_cache;
static add_cache add_tables[32];
static unsigned add_next;
void ps_add(int n,const int8_t *a,const int8_t *b,int8_t *y,
            float sa,float sb,float sy,int azp,int bzp,int yzp) {
    add_cache *entry=0;
    for(unsigned k=0;k<32;k++) {
        add_cache *t=&add_tables[k];
        if(t->valid && t->sa==sa && t->sb==sb && t->sy==sy &&
           t->azp==azp && t->bzp==bzp && t->yzp==yzp){entry=t;break;}
    }
    if(!entry) {
        entry=&add_tables[add_next++%32];entry->valid=0;
        for(unsigned ai=0;ai<256;ai++) {
            fusion_yield();
            float va=((float)(int8_t)ai-azp)*sa;
            for(unsigned bi=0;bi<256;bi++) {
                float vb=((float)(int8_t)bi-bzp)*sb;
                entry->values[(ai<<8)|bi]=sat(round_even((va+vb)/sy)+yzp);
            }
        }
        entry->sa=sa;entry->sb=sb;entry->sy=sy;
        entry->azp=azp;entry->bzp=bzp;entry->yzp=yzp;entry->valid=1;
    }
    for(int i=0;i<n;i++) {
        if(!(i&2047))fusion_yield();
        y[i]=entry->values[((unsigned)(uint8_t)a[i]<<8)|(uint8_t)b[i]];
    }
}

void ps_conv(const conv_spec *s,const int8_t *x,const int8_t *w,
             const int32_t *bias,int8_t *y) {
    if(s->ci!=3 || s->co!=32 || s->kh!=3 || s->kw!=3 || s->groups!=1) {
        ps_conv_reference(s,x,w,bias,y);
        return;
    }
    int16_t packed[27][32] __attribute__((aligned(16)));
    for(int kr=0;kr<3;kr++) for(int kc=0;kc<3;kc++) for(int ci=0;ci<3;ci++) {
        int k=(kr*3+kc)*3+ci;
        for(int o=0;o<32;o++) packed[k][o]=w[(o*3+ci)*9+kr*3+kc];
    }
    for(int r=0;r<s->oh;r++) for(int c=0;c<s->ow;c++) { if(!(c&15))fusion_yield();
        int16_t patch[27];
        int ir0=r*s->stride-s->pad_top,ic0=c*s->stride-s->pad_left;
        /* One interior decision replaces nine bounds decisions for the common
         * case. Boundary patches retain centered zero padding exactly. */
        if(ir0>=0 && ir0+2<s->h && ic0>=0 && ic0+2<s->w) {
            for(int kr=0;kr<3;kr++) {
                const int8_t *pixel=x+((ir0+kr)*s->w+ic0)*3;
                for(int k=0;k<9;k++) patch[kr*9+k]=(int)pixel[k]-s->xzp;
            }
        } else {
            for(int kr=0;kr<3;kr++) for(int kc=0;kc<3;kc++) {
                int ir=ir0+kr,ic=ic0+kc,k=(kr*3+kc)*3;
                if((unsigned)ir<(unsigned)s->h && (unsigned)ic<(unsigned)s->w) {
                    const int8_t *pixel=x+(ir*s->w+ic)*3;
                    for(int ci=0;ci<3;ci++) patch[k+ci]=(int)pixel[ci]-s->xzp;
                } else patch[k]=patch[k+1]=patch[k+2]=0;
            }
        }
        for(int o=0;o<32;o+=8) {
            int32_t acc[8];
#if defined(__ARM_NEON)
            int32x4_t lo=vld1q_s32(bias+o),hi=vld1q_s32(bias+o+4);
            for(int k=0;k<27;k++) {
                int16x8_t weights=vld1q_s16(packed[k]+o);
                int16x4_t value=vdup_n_s16(patch[k]);
                lo=vmlal_s16(lo,vget_low_s16(weights),value);
                hi=vmlal_s16(hi,vget_high_s16(weights),value);
            }
            if(s->shift==28 && s->mul>0 && s->mul<=0x04000000 && s->yzp>=-128 && s->yzp<=127) {
                vst1_s8(y+(r*s->ow+c)*32+o,requant8_28(lo,hi,s->mul,s->yzp));
                continue;
            }
            vst1q_s32(acc,lo);vst1q_s32(acc+4,hi);
#else
            for(int j=0;j<8;j++) acc[j]=bias[o+j];
            for(int k=0;k<27;k++) for(int j=0;j<8;j++) acc[j]+=patch[k]*packed[k][o+j];
#endif
            for(int j=0;j<8;j++) y[(r*s->ow+c)*32+o+j]=requant(acc[j],s->mul,s->shift,s->yzp);
        }
    }
}
