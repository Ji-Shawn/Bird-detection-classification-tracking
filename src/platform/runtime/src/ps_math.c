#include "fusion_math.h"
#include "ps_math.h"
#include <math.h>
#include <stdlib.h>

static int round_even(float v) {
    int t=(int)v;
    if(v<0 && v!=(float)t) t--;
    float f=v-(float)t;
    if(f>0.5f || (f==0.5f && (t&1))) t++;
    return t;
}
static int8_t sat(int v) { return (int8_t)(v>127?127:(v< -128?-128:v)); }
static int8_t requant(int32_t acc,int mul,int shift,int zp) {
    int64_t t=(int64_t)acc*mul, base=t>>shift, frac=t-base*((int64_t)1<<shift), half=(int64_t)1<<(shift-1);
    if(frac>half || (frac==half && (base&1))) base++;
    return sat((int)base+zp);
}
void ps_conv(const conv_spec *s,const int8_t *x,const int8_t *w,const int32_t *bias,int8_t *y) {
    for(int r=0;r<s->oh;r++) for(int c=0;c<s->ow;c++) for(int o=0;o<s->co;o++) {
        if(!(o&15))fusion_yield();
        int32_t acc=bias[o];
        for(int kr=0;kr<s->kh;kr++) for(int kc=0;kc<s->kw;kc++) {
            int ir=r*s->stride+kr-s->pad_top, ic=c*s->stride+kc-s->pad_left;
            if(ir<0 || ir>=s->h || ic<0 || ic>=s->w) continue;
            if(s->groups==1) {
                for(int ci=0;ci<s->ci;ci++) acc+=((int)x[(ir*s->w+ic)*s->ci+ci]-s->xzp)*(int)w[((o*s->ci+ci)*s->kh+kr)*s->kw+kc];
            } else {
                acc+=((int)x[(ir*s->w+ic)*s->ci+o]-s->xzp)*(int)w[(o*s->kh+kr)*s->kw+kc];
            }
        }
        y[(r*s->ow+c)*s->co+o]=requant(acc,s->mul,s->shift,s->yzp);
    }
}
void ps_add(int n,const int8_t *a,const int8_t *b,int8_t *y,float sa,float sb,float sy,int azp,int bzp,int yzp) {
    for(int i=0;i<n;i++) { if(!(i&2047))fusion_yield();
        float va=((float)a[i]-azp)*sa, vb=((float)b[i]-bzp)*sb;
        y[i]=sat(round_even((va+vb)/sy)+yzp);
    }
}
static float clamp320(float v) { return fminf(320.0f,fmaxf(0.0f,v)); }
static int descending(const void *aa,const void *bb) {
    const ssd_detection *a=aa,*b=bb;
    if(a->score>b->score) return -1;
    if(a->score<b->score) return 1;
    return a->anchor-b->anchor;
}
static float overlap(const ssd_detection *a,const ssd_detection *b) {
    float iw=fmaxf(0,fminf(a->x2,b->x2)-fmaxf(a->x1,b->x1));
    float ih=fmaxf(0,fminf(a->y2,b->y2)-fmaxf(a->y1,b->y1));
    float inter=iw*ih, sum=(a->x2-a->x1)*(a->y2-a->y1)+(b->x2-b->x1)*(b->y2-b->y1)-inter;
    return sum>0?inter/sum:0;
}
int ssd_postprocess(const ssd_head heads[6],const float *anchors,ssd_detection output[100]) {
    static ssd_detection candidates[3234];
    int count=0, index=0;
    for(int level=0;level<6;level++) { fusion_yield();
        const ssd_head *h=&heads[level];
        for(int p=0;p<h->h*h->w;p++) for(int a=0;a<6;a++,index++) {
            if(!(index&63))fusion_yield();
            const int8_t *cls=h->cls+p*h->cls_channels+2*a;
            float d=((float)cls[1]-(float)cls[0])*h->cls_scale;
            float z=expf(-fabsf(d)), score=d>=0?1.0f/(1.0f+z):z/(1.0f+z);
            if(score<=0.01f) continue;
            const int8_t *box=h->box+p*24+4*a;
            const float *an=anchors+4*index;
            float aw=an[2]-an[0], ah=an[3]-an[1], acx=an[0]+aw*.5f, acy=an[1]+ah*.5f;
            float dx=((float)box[0]-h->box_zp)*h->box_scale/10.0f;
            float dy=((float)box[1]-h->box_zp)*h->box_scale/10.0f;
            float dw=fminf(((float)box[2]-h->box_zp)*h->box_scale/5.0f,4.135166556742356f);
            float dh=fminf(((float)box[3]-h->box_zp)*h->box_scale/5.0f,4.135166556742356f);
            float cx=dx*aw+acx, cy=dy*ah+acy, w=expf(dw)*aw, ht=expf(dh)*ah;
            candidates[count++]=(ssd_detection){clamp320(cx-w*.5f),clamp320(cy-ht*.5f),clamp320(cx+w*.5f),clamp320(cy+ht*.5f),score,index};
        }
    }
    if(index!=3234) return -1;
    qsort(candidates,count,sizeof(candidates[0]),descending);
    if(count>300) count=300;
    int n=0;
    for(int i=0;i<count && n<100;i++) {
        fusion_yield();
        int keep=1;
        for(int j=0;j<n;j++) if(overlap(&candidates[i],&output[j])>0.45f) {keep=0;break;}
        if(keep) output[n++]=candidates[i];
    }
    return n;
}
