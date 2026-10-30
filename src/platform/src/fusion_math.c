#include "fusion_math.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

static int rhe(float v) { int t=(int)floorf(v); float f=v-t; return t+(f>0.5f || (f==0.5f && (t&1))); }
static int8_t quant(float x,float s,int z) { int q=rhe(x/s)+z; return (int8_t)(q< -128?-128:q>127?127:q); }
void fusion_quant_audio(const float *x,int8_t *out) {
    for(int i=0;i<128*400;i++) { int8_t q=quant(x[i],0.003921568859368563f,-128); out[3*i]=out[3*i+1]=out[3*i+2]=q; }
}
static int rgb(uint16_t p,int c) {
    int v=c==0?(p>>11):c==1?((p>>5)&63):(p&31);
    return c==1?((v<<2)|(v>>4)):((v<<3)|(v>>2));
}
static float norm(int p,int c) {
    const float mean[3]={.485f,.456f,.406f},std[3]={.229f,.224f,.225f};
    return ((float)p/255.0f-mean[c])/std[c];
}
/* Exact scalar expression evaluated once for every possible expanded RGB byte.
 * Avoid changing operation order or requantization rounding. */
static float normalized_rgb[3][256];
static int8_t quantized_rgb[3][256];
static int rgb_tables_ready;
static void prepare_rgb_tables(void) {
    if(rgb_tables_ready)return;
    for(int c=0;c<3;c++)for(int p=0;p<256;p++) {
        normalized_rgb[c][p]=norm(p,c);
        quantized_rgb[c][p]=quant(normalized_rgb[c][p],0.01865844801068306f,-14);
    }
    rgb_tables_ready=1;
}
/* PIL's bilinear antialias filter uses widened support on reduction and
 * fixed-point coefficients (22 fractional bits), with an 8-bit intermediate. */
static int coeff(int in,int out,int index,int *start,int32_t *k) {
    double scale=(double)in/out, fs=scale>1?scale:1, center=(index+.5)*scale;
    int a=(int)(center-fs+.5),b=(int)(center+fs+.5); if(a<0)a=0;if(b>in)b=in;
    double sum=0; for(int x=a;x<b;x++){double d=fabs((x-center+.5)/fs);sum+=d<1?1-d:0;}
    for(int x=a;x<b;x++){double d=fabs((x-center+.5)/fs);k[x-a]=(int32_t)((d<1?1-d:0)/sum*(1<<22)+.5);}
    *start=a;return b-a;
}
static int classify_input(const uint16_t *p,int stride,int w,int h,int ox,int oy,int camera_w,int camera_h,int8_t *image);
int fusion_ssd_input(const uint16_t *p,int w,int h,int8_t *ssd) {
    if(!p || !ssd || w<2 || h<2 || w>4096 || h>4096)return -1;
    prepare_rgb_tables();
    int left[320],right[320];float dxs[320];
    for(int x=0;x<320;x++) {
        float fx=fmaxf(0,(x+.5f)*((float)w/320)-.5f);
        left[x]=(int)fx;right[x]=left[x]+1<w?left[x]+1:left[x];dxs[x]=fx-left[x];
    }
    /* torchvision tensor bilinear, half-pixel centers, no antialias for SSD. */
    for(int y=0;y<320;y++) {
        fusion_yield(); float fy=fmaxf(0,(y+.5f)*((float)h/320)-.5f);int y0=(int)fy,y1=y0+1<h?y0+1:y0;float dy=fy-y0;
        for(int x=0;x<320;x++) {
            int x0=left[x],x1=right[x];float dx=dxs[x];
            for(int c=0;c<3;c++) {
                float a=normalized_rgb[c][rgb(p[y0*w+x0],c)],b=normalized_rgb[c][rgb(p[y0*w+x1],c)];
                float d=normalized_rgb[c][rgb(p[y1*w+x0],c)],e=normalized_rgb[c][rgb(p[y1*w+x1],c)];
                float v=(1-dy)*((1-dx)*a+dx*b)+dy*((1-dx)*d+dx*e);
                ssd[(y*320+x)*3+c]=quant(v,0.01865844987332821f,-14);
            }
        }
    }
    return 0;
}
int fusion_classify_input(const uint16_t *p,int w,int h,int8_t *image) {
    if(!p || !image || w<2 || h<2 || w>4096 || h>4096)return -1;
    return classify_input(p,w,w,h,0,0,w,h,image);
}
int fusion_image_inputs(const uint16_t *p,int w,int h,int8_t *image,int8_t *ssd) {
    if(!image)return -1;
    int rc=fusion_ssd_input(p,w,h,ssd);
    return rc?rc:fusion_classify_input(p,w,h,image);
}
static int clampi(int v,int lo,int hi){return v<lo?lo:v>hi?hi:v;}
static int classify_input(const uint16_t *p,int stride,int w,int h,int ox,int oy,int camera_w,int camera_h,int8_t *image) {
    prepare_rgb_tables();
    int rw=w<=h?147:147*w/h,rh=h<=w?147:147*h/w;
    int cx=rhe((rw-128)/2.0f),cy=rhe((rh-128)/2.0f);
    /* Only retain the horizontal crop; vertical filtering still uses full h. */
    uint8_t *tmp=malloc((size_t)h*128*3);int32_t k[8194];
    int starts[128],counts[128];
    int taps=2*((w+rw-1)/rw)+2;
    int32_t *horizontal=malloc((size_t)128*taps*sizeof(*horizontal));
    int *positions=malloc((size_t)128*taps*sizeof(*positions));
    if(!tmp || !horizontal || !positions){free(tmp);free(horizontal);free(positions);return -2;}
    /* Precompute the same fixed-point coefficients, then traverse contiguous
     * rows. The former column-major loop traversed the whole camera height
     * between yields and repeatedly evicted input/output cache lines. */
    for(int x=0;x<128;x++) {
        counts[x]=coeff(w,rw,cx+x,&starts[x],horizontal+x*taps);
        /* Edge replication can map many taps onto the same source pixel.
         * Merge their nonnegative integer weights without changing the sum. */
        int used=0;
        for(int j=0;j<counts[x];j++) {
            int pos=clampi(ox+starts[x]+j,0,camera_w-1);
            int32_t weight=horizontal[x*taps+j];
            if(!weight)continue;
            if(used && positions[x*taps+used-1]==pos)horizontal[x*taps+used-1]+=weight;
            else {positions[x*taps+used]=pos;horizontal[x*taps+used]=weight;used++;}
        }
        counts[x]=used;
        fusion_yield();
    }
    int previous_row=-1;
    for(int y=0;y<h;y++) {
        int yy=clampi(y+oy,0,camera_h-1);
        if(yy==previous_row) {
            /* Replicated border rows have identical horizontal filter output. */
            memcpy(tmp+y*128*3,tmp+(y-1)*128*3,128*3);
            if(!(y&15))fusion_yield();
            continue;
        }
        previous_row=yy;
        for(int x=0;x<128;x++) {
            if(!(x&15))fusion_yield();
            const int32_t *kx=horizontal+x*taps;
            /* Same Q22 sums/rounding, but load and clamp each RGB565 source
             * pixel once for all three channels. No new interpolation rule. */
            /* At most 58 nonnegative Q22 taps (input <=4096, output >=147).
             * 255*(2^22+58)+2^21 < 2^31, so int32 is exact, including bias. */
            int32_t vr=1<<21,vg=1<<21,vb=1<<21;
            for(int j=0;j<counts[x];j++) {
                uint16_t pixel=p[yy*stride+positions[x*taps+j]];
                int32_t weight=kx[j];
                vr+=rgb(pixel,0)*weight;
                vg+=rgb(pixel,1)*weight;
                vb+=rgb(pixel,2)*weight;
            }
            tmp[(y*128+x)*3]=(uint8_t)(vr>>22);
            tmp[(y*128+x)*3+1]=(uint8_t)(vg>>22);
            tmp[(y*128+x)*3+2]=(uint8_t)(vb>>22);
        }
    }
    free(horizontal);free(positions);
    for(int y=0;y<128;y++) {
        int start,n=coeff(h,rh,cy+y,&start,k);fusion_yield();
        for(int x=0;x<128;x++) {
            if(!(x&15))fusion_yield();
            for(int c=0;c<3;c++) {
                int32_t v=1<<21;for(int j=0;j<n;j++)v+=(int32_t)tmp[((start+j)*128+x)*3+c]*k[j];
                image[(y*128+x)*3+c]=quantized_rgb[c][(int)(v>>22)];
            }
        }
    }
    free(tmp);return 0;
}
int fusion_make_roi(int w,int h,const float *box,int32_t *roi) {
    if(!box || !roi || w<2 || h<2 || w>4096 || h>4096)return -1;
    for(int i=0;i<4;i++)if(!isfinite(box[i]))return -1;
    float x1=fmaxf(0,fminf(w,box[0])),y1=fmaxf(0,fminf(h,box[1]));
    float x2=fmaxf(0,fminf(w,box[2])),y2=fmaxf(0,fminf(h,box[3]));
    if(x2-x1<16 || y2-y1<16)return -1;
    int side=(int)ceilf(1.5f*fmaxf(x2-x1,y2-y1));
    if(side<32)side=32;
    if(side>4096)return -1;
    roi[0]=(int)floorf((x1+x2-side)*.5f);roi[1]=(int)floorf((y1+y2-side)*.5f);
    roi[2]=roi[0]+side;roi[3]=roi[1]+side;return 0;
}
int fusion_image_roi(const uint16_t *p,int w,int h,const int32_t *roi,int8_t *image) {
    if(!p || !roi || !image || w<2 || h<2 || w>4096 || h>4096)return -1;
    for(int i=0;i<4;i++)if(roi[i]< -4096 || roi[i]>8192)return -1;
    int rw=roi[2]-roi[0],rh=roi[3]-roi[1];
    if(rw<2 || rw>4096 || rh!=rw || roi[0]>=w || roi[1]>=h || roi[2]<=0 || roi[3]<=0)return -1;
    return classify_input(p,w,rw,rh,roi[0],roi[1],w,h,image);
}
static void probabilities(const int8_t *q,float scale,float *p) {
    int max=-128;float sum=0;for(int i=0;i<60;i++)if(q[i]>max)max=q[i];
    for(int i=0;i<60;i++){p[i]=expf(((float)q[i]-max)*scale);sum+=p[i];}
    for(int i=0;i<60;i++)p[i]/=sum;
}
int fusion_scores(const int8_t *a,const int8_t *v,float weight,float *out) {
    float pa[60],pv[60];int top=0;
    probabilities(a,0.21258553862571716f,pa);
    if(v)probabilities(v,0.2302367240190506f,pv);else weight=0;
    if(weight<0)weight=0;
    if(weight>1)weight=1;
    for(int i=0;i<60;i++){out[i]=(1-weight)*pa[i]+(weight?weight*pv[i]:0);if(out[i]>out[top])top=i;}
    return top;
}
