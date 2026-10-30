#include "model_logmel32.h"
#include "sound_round_policy.h"
#include <math.h>
#include <string.h>

#define N 1024u
#define BINS 128u
#define COLS 401u
#define SEGMENT SOUND_ROUND_MODEL_SAMPLES
static float window[N], tw_re[N/2], tw_im[N/2];
static float weights[BINS][N/2+1];
static uint16_t first_bin[BINS], last_bin[BINS];
static float ring[N], re[N], im[N];
static float working[BINS][COLS], snapshot[BINS][400];
static uint32_t written, position, column, next_frame, ready, initialized;
static uint32_t nonzero;
static uint32_t capture_samples=SOUND_ROUND_CAPTURE_SAMPLES,ready_tail;
static int32_t segment_pcm[SEGMENT], snapshot_pcm[SEGMENT];

static float hz_to_mel(float hz) {
    return hz<1000.0f ? hz/66.6666666667f : 15.0f+logf(hz/1000.0f)/(logf(6.4f)/27.0f);
}
static float mel_to_hz(float mel) {
    return mel<15.0f ? mel*66.6666666667f : 1000.0f*expf((mel-15.0f)*(logf(6.4f)/27.0f));
}
static void init(void) {
    uint32_t i,b;
    float edge[130], lo=hz_to_mel(20.0f), hi=hz_to_mel(16000.0f);
    if(initialized) return;
    for(i=0;i<N;++i) window[i]=0.5f-0.5f*cosf(6.283185307179586f*i/N);
    for(i=0;i<N/2;++i) {
        tw_re[i]=cosf(-6.283185307179586f*i/N);
        tw_im[i]=sinf(-6.283185307179586f*i/N);
    }
    for(i=0;i<130;++i) edge[i]=mel_to_hz(lo+(hi-lo)*i/129.0f);
    for(b=0;b<BINS;++b) {
        first_bin[b]=512;last_bin[b]=0;
        for(i=0;i<=N/2;++i) {
            float hz=31.25f*i;
            float up=(hz-edge[b])/(edge[b+1]-edge[b]);
            float down=(edge[b+2]-hz)/(edge[b+2]-edge[b+1]);
            float w=fmaxf(0.0f,fminf(up,down))*2.0f/(edge[b+2]-edge[b]);
            weights[b][i]=w;
            if(w>0) {if(i<first_bin[b]) first_bin[b]=(uint16_t)i;last_bin[b]=(uint16_t)i;}
        }
    }
    initialized=1;
}
static void begin_segment(void) {
    memset(ring,0,sizeof(ring));
    written=position=column=nonzero=0;next_frame=512;
}
void model_logmel32_reset(void) {
    init();begin_segment();ready=ready_tail=0;
    memset(snapshot,0,sizeof(snapshot));
}
int model_logmel32_set_capture_samples(uint32_t samples) {
    if(samples<32000u || samples>SOUND_ROUND_MODEL_SAMPLES || samples%32u)return -1;
    if(samples!=capture_samples){capture_samples=samples;model_logmel32_reset();}
    return 0;
}
static void transform(void) {
    uint32_t i,j,len,b;
    for(i=0;i<N;++i) {re[i]=ring[(position+i)&(N-1)]*window[i];im[i]=0;}
    for(i=1,j=0;i<N;++i) {
        uint32_t bit=N>>1;
        while(j&bit){j^=bit;bit>>=1;}j^=bit;
        if(i<j) {float x=re[i];re[i]=re[j];re[j]=x;}
    }
    for(len=2;len<=N;len<<=1) {
        uint32_t half=len>>1,step=N/len;
        for(i=0;i<N;i+=len) for(j=0;j<half;++j) {
            uint32_t a=i+j,z=a+half,k=j*step;
            float xr=tw_re[k]*re[z]-tw_im[k]*im[z];
            float xi=tw_re[k]*im[z]+tw_im[k]*re[z];
            re[z]=re[a]-xr;im[z]=im[a]-xi;re[a]+=xr;im[a]+=xi;
        }
    }
    for(i=0;i<=N/2;++i) re[i]=re[i]*re[i]+im[i]*im[i];
    for(b=0;b<BINS;++b) {
        float sum=0;
        for(i=first_bin[b];i<=last_bin[b];++i) sum+=weights[b][i]*re[i];
        working[b][column]=10.0f*log10f(fmaxf(sum,1e-10f));
    }
    ++column;next_frame+=400;
}
static void append(float value) {
    ring[position]=value;position=(position+1)&(N-1);++written;
    if(written==next_frame && column<COLS) transform();
}
void model_logmel32_push(const int32_t *pcm,uint32_t count) {
    uint32_t i,b,c;
    if(!pcm) return;
    if(!initialized) model_logmel32_reset();
    for(i=0;i<count;++i) {
        int32_t v=pcm[i];
        if(v>8388607)v=8388607;
        if(v< -8388608)v=-8388608;
        nonzero|=(v!=0);
        segment_pcm[written]=v;
        append((float)v/8388608.0f);
        if(written==capture_samples) {
            /* Real PCM at the adopted boundary, then silence to five seconds. */
            while(written<SEGMENT) {
                segment_pcm[written]=0;append(0.0f);
            }
            memcpy(snapshot_pcm,segment_pcm,sizeof snapshot_pcm);
            float peak=-100.0f;
            /* Frozen training uses 401 centered frames including the right
             * boundary, then numpy.resize flattens/truncates to 128x400. */
            while(column<COLS) append(0.0f);
            for(b=0;b<BINS;++b) for(c=0;c<COLS;++c)
                if(working[b][c]>peak) peak=working[b][c];
            for(b=0;b<BINS;++b) for(c=0;c<400;++c) {
                uint32_t i=b*400+c;
                snapshot[b][c]=nonzero ? fmaxf(0.0f,fminf(1.0f,(working[i/COLS][i%COLS]-peak+80.0f)/80.0f)):0.0f;
            }
            ready_tail=count-i-1u;++ready;begin_segment();
        }
    }
}
uint32_t model_logmel32_ready(void){return ready;}
uint32_t model_logmel32_tail_samples(void){return ready_tail;}
const float *model_logmel32_data(void){return &snapshot[0][0];}
const int32_t *model_logmel32_pcm(void){return snapshot_pcm;}
