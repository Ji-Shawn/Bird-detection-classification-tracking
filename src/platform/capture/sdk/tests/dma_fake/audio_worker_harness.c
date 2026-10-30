/* Production worker/health/beamformer, hardware and expensive DSP calls stubbed.
 * Validates worker mask/history/DOA gating and transport continuity. */
#include <windows.h>
#include <stdio.h>
#define audio_process_reset tracked_audio_process_reset
#include "../../core1_audio/src/audio_worker.c"
#undef audio_process_reset
void audio_process_reset(void);
static unsigned gcc_calls, publications, process_resets, model_samples;
static int simulated_vad=1;
static uint64_t time_offset;
static uint32_t hardware_delays[4];
void platform_cache_flush(const void *p,uint32_t n) {}
void platform_cache_invalidate(const void *p,uint32_t n) {}
uint32_t platform_cycle_count(void) {return 0;}
void platform_mmio_write(uint32_t a,uint32_t v) {
    unsigned c;
    for(c=0;c<4;++c) if(a==AV_REG_BASE+AV_REG_AUDIO_DELAY(c)) hardware_delays[c]=v;
}
uint32_t platform_mmio_read(uint32_t a) {return 0;}
int av_ring_claim_ready(av_shared_desc_t *d) {return d->state==AV_DESC_READY;}
void av_ring_release_free(av_shared_desc_t *d) {d->state=AV_DESC_FREE;}
int av_ring_publish(av_shared_desc_t *d,const void *p,uint32_t n,uint32_t b,uint32_t s,uint64_t t) {++publications;return 1;}
void model_logmel32_reset(void) {model_samples=0;}
void model_logmel32_push(const int32_t *p,uint32_t n) {model_samples+=n;}
uint32_t model_logmel32_ready(void) {return 0;}
const float *model_logmel32_data(void) {return 0;}
void fusion_audio_publish(const float *x,uint64_t t,const fusion_direction_sample *d) {}
void bird_frontend_reset(bird_frontend_state_t *s) {memset(s,0,sizeof(*s));}
int bird_frontend_process_hop(bird_frontend_state_t *s,const int32_t a[480][4],int32_t f[4][480],bird_vad_result_t *v) {
    unsigned c,i; for(c=0;c<4;++c) for(i=0;i<480;++i) f[c][i]=a[i][c];
    memset(v,0,sizeof(*v));v->active=simulated_vad;return 0;
}
int gcc_phat_4ch(const int32_t p[4][1024],tdoa_result_t *t) {++gcc_calls;memset(t,0,sizeof(*t));return 0;}
int tdoa_to_direction(const tdoa_result_t *t,direction_result_t *d) {d->valid=1;d->angle_q9_7=0;return 0;}
void tracked_audio_process_reset(void) {++process_resets;audio_process_reset();}
void audio_model_tensor_reset(void) {}
void audio_model_tensor_push_missing(uint32_t n) {}
void audio_model_tensor_push(const uint16_t m[128],uint32_t n,uint64_t t) {}
#define CHECK(c,m) do {if(!(c)){fprintf(stderr,"%s\n",m);return 1;}}while(0)
static void hop(audio_worker_state_t *s,unsigned mask,unsigned sequence) {
    unsigned c,i; av_shared_desc_t *d=input_desc(s->input_index);
    av_pcm_payload_t *p=input_payload(s->input_index);
    for(i=0;i<480;++i) for(c=0;c<4;++c) p->sample[i][c]=(mask&(1u<<c))?1000+(int)i:0;
    d->state=AV_DESC_READY;d->boot_id=1;d->sequence=sequence;
    d->timestamp_us=(uint64_t)sequence*15000u+time_offset;
    audio_worker_poll(s);
}
int main(void) {
    audio_worker_state_t s; unsigned i,before,reset_before;
    int16_t fresh_pcm[480];uint16_t fresh_mel[128];
    /* Exercise the real PL register packing at the confirmed 30 cm span.
     * Front/right/rear/left delay distances in units of one 15 cm arm. */
    const unsigned expected[4][4]={{2,1,0,1},{1,2,1,0},{0,1,2,1},{1,0,1,2}};
    const int headings[4]={0,90,180,-90};
    unsigned heading,c;
    for(heading=0;heading<4;++heading) {
        direction_result_t d={0};d.valid=1;d.angle_q9_7=headings[heading]*128;
        commit_delays(&d,15);
        for(c=0;c<4;++c) {
            float actual=(float)(hardware_delays[c]&63u)+(float)(hardware_delays[c]>>6)/32768.0f;
            float target=(float)expected[heading][c]*0.15f*32000.0f/343.0f;
            CHECK((hardware_delays[c]&63u)<=38u,"30cm delay exceeds PL history");
            CHECK(fabsf(actual-target)<0.0001f,"wrong 30cm PL steering delay");
        }
    }
    CHECK(VirtualAlloc((void *)(uintptr_t)AV_SHARED_BASE,0x100000,MEM_RESERVE|MEM_COMMIT,PAGE_READWRITE)==(void *)(uintptr_t)AV_SHARED_BASE,"RAM failed");
    audio_worker_init(&s,1);
    for(i=0;i<4;++i) hop(&s,15,i);
    CHECK(!gcc_calls,"DOA ran before history filled");
    hop(&s,15,4); CHECK(gcc_calls==1,"full healthy history not localized");
    hop(&s,2,5); CHECK(gcc_calls==1,"single mic falsely localized");
    CHECK(beamformed[0]==1000 && beamformed[479]==1479,"fallback attenuated or stale delay used");
    before=gcc_calls;
    hop(&s,15,20);hop(&s,15,21);hop(&s,15,22);hop(&s,15,23);
    CHECK(gcc_calls==before,"sequence gap reused old localization history");
    hop(&s,15,24);CHECK(gcc_calls==before+1,"reconnected history not restored");
    before=gcc_calls;time_offset=100000;reset_before=process_resets;
    hop(&s,15,25);CHECK(gcc_calls==before,"DMA outage with contiguous sequence reused history");
    CHECK(process_resets>reset_before,"display Mel kept pre-outage history/noise");
    audio_process_reset();
    audio_process_hop(beamformed,fresh_pcm,fresh_mel,0);
    CHECK(!memcmp(fresh_pcm,wire_pcm,sizeof(fresh_pcm)) &&
          !memcmp(fresh_mel,wire_mel,sizeof(fresh_mel)),
          "resumed actual display DSP differs from fresh state");
    hop(&s,0,26); CHECK(beamformed[0]==0,"dead microphones not muted");
    CHECK(publications==13,"unhealthy microphones stopped transport");
    for(i=27;i<32;++i) hop(&s,15,i);
    CHECK(model_samples>=480,"model did not start with healthy PCM");
    before=model_samples;simulated_vad=0;
    hop(&s,15,32);
    CHECK(model_samples==before+480,"ordinary bird pause reset valid model time window");
    time_offset+=15000;reset_before=process_resets;
    hop(&s,15,33);
    CHECK(process_resets>reset_before && model_samples==0,
          "one lost 15ms DMA block silently bridged model history");
    return 0;
}
