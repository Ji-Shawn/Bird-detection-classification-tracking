#include "av_shared.h"
#include "fusion_bridge.h"
#include "fusion_math.h"
#include "runtime.h"
#include "network_service.h"
#include "../capture/sdk/core0_network/include/bird_focus.h"
#include "../capture/sdk/core0_network/include/servo_tracking.h"
#include "../capture/sdk/core0_network/include/visual_tracker.h"
#include "ps_math.h"
#include "xaxidma.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xtime_l.h"
#include <string.h>
#include <math.h>

int unified_validate=0;
int8_t unified_logits[60];
static network_service_t *net;
static uint32_t stage, video_state, service_busy;
static uint64_t wait_start,last_service;
static uint64_t status_start,last_status;
static uint32_t status_sequence;
static int8_t audio_logits[60],image_logits[60];
static fusion_result result;
static direction_gate doa_gate;
volatile uint32_t direction_debug[16];
static unsigned requested_mode,active_mode,capture_state,visual_sequence;
static unsigned job_mode;
static unsigned requested_policy,active_policy;
static uint16_t requested_box[4],active_box[4];
static uint64_t next_visual;
static uint64_t request_start;
unsigned fusion_mode(void){return requested_mode;}
unsigned fusion_capture_state(void){return capture_state;}
int fusion_set_mode(unsigned mode){if(mode>2)return -1;requested_mode=mode;direction_gate_clear(&doa_gate);bird_focus_forget();visual_tracker_reset();servo_tracking_stop();return 0;}
int fusion_set_image_policy(unsigned policy,const uint16_t *box) {
    if(policy>3)return -1;
    if(policy>=2) {
        if(!box || box[2]>AV_VIDEO_WIDTH || box[3]>AV_VIDEO_HEIGHT || box[2]<box[0]+16 || box[3]<box[1]+16)return -1;
        memcpy(requested_box,box,sizeof requested_box);
        fusion_set_mode(1); /* Manual ROI is an explicit visual diagnostic. */
    }
    if(requested_policy!=policy)visual_tracker_reset();
    requested_policy=policy;return 0;
}
int fusion_capture_control(unsigned action){
    if(action>1)return -1;capture_state=action;
    servo_tracking_stop();
    visual_tracker_reset();
    bird_focus_forget();
    direction_gate_clear(&doa_gate);
    *(volatile uint32_t *)FUSION_DIAG=0;Xil_DCacheFlushRange(FUSION_DIAG,64);return 0;
}
/* Configuration is software, unrelated to the brightness threshold 60. */
volatile float fusion_audio_threshold=0.5f;
volatile float fusion_detection_threshold=0.5f;
volatile float fusion_image_weight=0.6f;
static uint64_t now_us(void){XTime t;XTime_GetTime(&t);return (uint64_t)t*1000000/COUNTS_PER_SECOND;}
int fusion_set_direction_threshold(unsigned percent){return direction_gate_threshold(&doa_gate,percent);}
static void direction_stream_poll(uint64_t now) {
    volatile fusion_live_direction *p=(volatile fusion_live_direction *)FUSION_LIVE_DIRECTION;
    uint32_t before=p->generation;av_memory_barrier();
    fusion_direction_sample sample=p->sample;float energy=p->energy;unsigned mask=p->mask;
    av_memory_barrier();
    if((before&1u) || before!=p->generation)sample.valid=0;
    direction_gate_stream(&doa_gate,&sample,energy,mask,now);
}
int fusion_direction_read(fusion_direction_sample *out) {
    uint64_t now=now_us();direction_stream_poll(now);
    (void)direction_gate_start_session(&doa_gate,now);
    direction_debug[0]++;
    unsigned health=((volatile uint32_t *)FUSION_AUDIO_HEALTH)[1];
    direction_debug[1]=health;
    if(requested_mode==1 || active_mode==1 || capture_state==2 || stage==9) {
        direction_debug[2]++;
        if(health!=15u)direction_debug[3]++;
        if(requested_mode==1 || active_mode==1)direction_debug[4]++;
        if(capture_state==2 || stage==9)direction_debug[5]++;
        direction_gate_clear(&doa_gate);memset(out,0,sizeof *out);return 0;
    }
    if(!doa_gate.session_active){memset(out,0,sizeof *out);return 0;}
    return direction_gate_read(&doa_gate,now,out);
}
void fusion_direction_status(uint32_t *percent,uint32_t *bird,float *score,uint32_t *age_ms) {
    fusion_direction_sample sample;
    int valid=fusion_direction_read(&sample);
    *percent=doa_gate.threshold_percent;*bird=doa_gate.bird_class;*score=doa_gate.bird_score;
    *age_ms=valid?(uint32_t)((now_us()-sample.timestamp_us)/1000u):UINT32_MAX;
}
XAxiDma_Config *fusion_dma_config(void) {
    static XAxiDma_Config cfg={1,0x40410000u,0,1,0,64,1,0,64,0,1,1,16,16,0,32,14};
    return &cfg;
}
static unsigned visual_present(uint64_t now) {
    uint32_t tracker[16];visual_tracker_status(tracker,now);
    return (tracker[2] && tracker[6]<=VISUAL_TRACKER_CONFIRM_US/1000u && tracker[11]<=1000u) ||
           servo_tracking_visual_present(now);
}
static void service_io(int idle) {
    if(!net || service_busy)return;
    uint64_t t=now_us();if(!idle && t-last_service<250)return;
    if(last_service && t-last_service>result.max_service_gap_us)result.max_service_gap_us=(uint32_t)(t-last_service);
    last_service=t;service_busy=1;
    servo_tracking_poll(t);
    network_platform_poll();dma_service_poll(net);
    if(capture_state==0 && stage!=9 && requested_policy<2)visual_tracker_poll(now_us());
    if(capture_state==0 && stage!=9 && requested_mode==2 && requested_policy<2) {
        fusion_direction_sample sound;
        int valid=fusion_direction_read(&sound);
        uint64_t sound_now=now_us();
        servo_tracking_sound_observe(valid,sound.angle_q9_7,sound.confidence_q0_15,
                                     sound.timestamp_us,visual_present(sound_now),sound_now);
    }
    /* Inference must get CPU time between bursts. Measure the cooldown from
     * the END of service, otherwise a long burst defeats its own throttle. */
    /* 1080p RGB565 needs 2963 compatibility-MTU datagrams/frame.
     * Charge only sending to this budget: DMA copying/tracking above can
     * otherwise consume it before the first packet. Inference retains its
     * 16-packet bound and end-based cooldown. Idle time may fill 32 packets,
     * still bounded by 500us, with audio priority checked before each packet. */
    (void)network_scheduler_burst(net,500u,idle?32u:16u);
    uint64_t end=now_us();
    if(end-last_status>=100000u) {
        volatile uint32_t *deadline=(volatile uint32_t *)AV_SHARED_AUDIO_DEADLINE_ADDR;
        (void)telemetry_send(net,status_sequence++,(uint32_t)((end-status_start)/1000u),*deadline);
        last_status=end;
    }
    bird_focus_poll(now_us());
    last_service=now_us();
    service_busy=0;
}
void fusion_yield(void){service_io(0);}
void fusion_service_idle(void){service_io(1);}
void fusion_init(void *network) {
    net=network;stage=video_state=0;memset(&result,0,sizeof result);
    direction_gate_init(&doa_gate);
    requested_mode=active_mode=capture_state=visual_sequence=0;next_visual=last_service=0;service_busy=0;
    requested_policy=active_policy=1;memset(requested_box,0,sizeof requested_box);
    status_start=last_status=now_us();status_sequence=0;
    servo_tracking_init(status_start);
    visual_tracker_init();
    memset((void *)FUSION_SHARED,0,sizeof(fusion_audio_slot));
    memset((void *)FUSION_AUDIO_HEALTH,0,64);
    memset((void *)FUSION_LIVE_DIRECTION,0,64);
    result.magic=0x46555331;result.version=3;
    memset((void *)FUSION_DIAG,0,256);Xil_DCacheFlushRange(FUSION_DIAG,256);
}
int fusion_video_begin(uint32_t sequence,uint64_t timestamp) {
    if(video_state!=1 || timestamp<result.audio_timestamp_us)return 0;
    result.video_sequence=sequence;result.video_timestamp_us=timestamp;video_state=2;return 1;
}
void fusion_video_chunk(const void *p,uint32_t offset,uint32_t bytes) {
    if(video_state==2 && offset<=AV_VIDEO_FRAME_BYTES && bytes<=AV_VIDEO_FRAME_BYTES-offset)
        memcpy((void *)(uintptr_t)(FUSION_IMAGE+offset),p,bytes);
}
void fusion_video_abort(void){if(video_state==2)video_state=1;}
void fusion_video_end(void){if(video_state==2)video_state=3;}
static void publish(uint32_t status,int error) {
    if(error){direction_gate_clear(&doa_gate);bird_focus_forget();visual_tracker_reset();servo_tracking_stop();}
    result.status=status;result.error=error;result.total_us=(uint32_t)(now_us()-request_start);
    memcpy((void *)FUSION_RESULT,&result,sizeof result);Xil_DCacheFlushRange(FUSION_RESULT,sizeof result);
    /* A separate, versioned UDP datagram; existing monitor packets retain ABI. */
    (void)platform_udp_send(15005u,&result,sizeof result);
    if(capture_state==1) {
        servo_tracking_stop();
        visual_tracker_reset();
        /* Freeze only inference-owned inputs; live capture and network continue. */
        Xil_DCacheFlushRange(FUSION_IMAGE,AV_VIDEO_FRAME_BYTES);
        Xil_DCacheFlushRange(FUSION_USED_PCM,640000);
        volatile uint32_t *d=(volatile uint32_t *)FUSION_DIAG;
        memset((void *)d,0,256);d[1]=result.sequence;d[2]=active_mode;d[3]=status;
        d[4]=active_mode==0;d[5]=video_state==3;d[6]=result.image_top1!=0xffffffffu;
        memcpy((void *)(d+16),audio_logits,60);memcpy((void *)(d+31),image_logits,60);
        d[0]=0x46525A31u;Xil_DCacheFlushRange(FUSION_DIAG,256);capture_state=2;
    }
    xil_printf("FUSION seq=%lu status=%lu class=%lu confidence_q15=%lu error=%d\r\n",
        (unsigned long)result.sequence,(unsigned long)status,(unsigned long)result.top1,
        (unsigned long)(result.confidence*32768),error);
    video_state=0;stage=error?9:0;
    /* A bounded 250ms breathing interval; inference remains cooperative. */
    if(active_mode==1)next_visual=now_us()+250000u;
}
static int run(int id) {
    volatile uint32_t *mb=(volatile uint32_t *)(uintptr_t)(id==3?0x2F000000u:0x20000000u);
    memset((void *)mb,0,64);mb[0]=id==3?0x53534431u:0xC0DE0004u;mb[5]=51;mb[6]=1;mb[7]=0x4D454D43u;
    Xil_DCacheFlushRange((UINTPTR)mb,64);
    int rc=id==1?audio_run():id==2?image_run():ssd_run();
    if(!rc && mb[13]!=0x600D)rc=-20;
    return rc;
}
void fusion_poll(void) {
    /* Loader publishes this only after validating and loading all weights. */
    Xil_DCacheInvalidateRange(FUSION_ASSETS_READY,64);
    if(*(volatile uint32_t *)FUSION_ASSETS_READY!=FUSION_ASSETS_MAGIC || stage==9 || capture_state==2)return;
    if(stage==0) {
        request_start=now_us();
        memset(&result.audio_compute_us,0,8*sizeof(uint32_t));
        job_mode=requested_mode;
        /* Combined mode listens while seeking. Once a bird is in view, use
         * the accepted independent visual cadence, even if it falls silent.
         * Loss of the target returns to listening at the next job boundary. */
        active_mode=requested_mode==2?(visual_present(now_us())?1u:0u):requested_mode;
        active_policy=requested_policy;memcpy(active_box,requested_box,sizeof active_box);
        result.image_policy=active_policy;result.applied_policy=0;
        memset(result.roi,0,sizeof result.roi);result.full_top1=0xffffffffu;result.full_confidence=0;
        if(active_mode==1) {
            if(now_us()<next_visual)return;
            result.sequence=++visual_sequence;result.audio_timestamp_us=0;
            result.video_timestamp_us=0;result.video_sequence=0;result.audio_top1=0xffffffffu;
            result.image_top1=0xffffffffu;result.top1=0;result.confidence=result.detector_score=0;
            memset(result.box,0,sizeof result.box);memset(result.probabilities,0,sizeof result.probabilities);
            video_state=1;stage=1;wait_start=now_us();return;
        }
        fusion_audio_slot *s=(fusion_audio_slot *)FUSION_SHARED;
        if(s->state!=2)return;
        s->state=3;av_memory_barrier();
        fusion_direction_sample audio_direction=s->direction;
        /* Keep the previously classified observation during computation.
         * Its original sample time and eight-second expiry remain unchanged;
         * direction_gate_accept replaces/clears it when this job finishes. */
        result.sequence=s->sequence;result.audio_timestamp_us=s->timestamp_us;
        result.video_timestamp_us=0;result.video_sequence=0;result.image_top1=0xffffffffu;
        result.detector_score=0;memset(result.box,0,sizeof result.box);
        /* Acquire the matching camera frame while the audio engine runs. */
        video_state=1;wait_start=now_us();
        memcpy((void *)0x32000000u,s->input,153600);Xil_DCacheFlushRange(0x32000000u,153600);
        Xil_DCacheInvalidateRange(FUSION_SLOT_PCM,640000);
        for(unsigned offset=0;offset<640000;offset+=16000) {
            memcpy((void *)(uintptr_t)(FUSION_USED_PCM+offset),(void *)(uintptr_t)(FUSION_SLOT_PCM+offset),16000);
            fusion_yield();
        }
        av_memory_barrier();s->state=0;
        uint64_t audio_start=now_us();
        int rc=run(1);result.audio_compute_us=(uint32_t)(now_us()-audio_start);
        if(rc){publish(4,rc);return;}
        memcpy(audio_logits,unified_logits,60);
        result.top1=result.audio_top1=fusion_scores(audio_logits,0,0,result.probabilities);
        result.confidence=result.probabilities[result.top1];
        direction_debug[6]++;direction_debug[7]+=audio_direction.valid!=0;
        direction_gate_accept(&doa_gate,result.audio_top1,result.confidence,
                              result.audio_timestamp_us,&audio_direction);
        direction_stream_poll(now_us());
        (void)direction_gate_start_session(&doa_gate,now_us());
        direction_debug[8]+=doa_gate.sample.valid!=0;
        direction_debug[9]=audio_direction.valid;
        direction_debug[10]=(uint32_t)audio_direction.timestamp_us;
        direction_debug[11]=(uint32_t)result.audio_timestamp_us;
        result.audio_response_us=(uint32_t)(now_us()-result.audio_timestamp_us);
        if(result.confidence<fusion_audio_threshold){publish(5,0);return;}
        /* Provisional audio packet: no freeze, no state reset. Final packet
         * with the SAME sequence replaces it after visual review. */
        result.status=8;result.error=0;result.total_us=(uint32_t)(now_us()-request_start);
        (void)platform_udp_send(15005u,&result,sizeof result);
        stage=1;wait_start=now_us();return;
    }
    if(stage==1 && video_state!=3) {
        if(now_us()-wait_start>2000000u)publish(active_mode==1?7:3,0);
        return;
    }
    if(stage==1) {
        result.capture_wait_us=(uint32_t)(now_us()-wait_start);
        uint64_t start=now_us();
        int rc=fusion_ssd_input((const uint16_t *)FUSION_IMAGE,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,(int8_t *)0x10190000u);
        result.ssd_preprocess_us=(uint32_t)(now_us()-start);
        if(rc){publish(4,rc);return;}
        Xil_DCacheFlushRange(0x10190000u,307200);
        start=now_us();rc=run(3);result.ssd_compute_us=(uint32_t)(now_us()-start);
        if(rc){publish(4,rc);return;}
        uint32_t count=*(volatile uint32_t *)0x2F001010u;
        if(count>100){publish(4,-21);return;}
        visual_candidate candidates[100];int selected=-1;float highest=0;
        const ssd_detection *d=(const ssd_detection *)0x2F002000u;
        for(unsigned i=0;i<count;i++) {
            candidates[i].score=d[i].score;
            candidates[i].box[0]=d[i].x1*(AV_VIDEO_WIDTH/320.f);
            candidates[i].box[2]=d[i].x2*(AV_VIDEO_WIDTH/320.f);
            candidates[i].box[1]=d[i].y1*(AV_VIDEO_HEIGHT/320.f);
            candidates[i].box[3]=d[i].y2*(AV_VIDEO_HEIGHT/320.f);
            if(isfinite(d[i].score) && d[i].score>=0 && d[i].score<=1 &&
               (selected<0 || d[i].score>highest)){highest=d[i].score;selected=(int)i;}
            if(d[i].score<fusion_detection_threshold)candidates[i].score=0;
        }
        if(capture_state==0 && job_mode==requested_mode && active_policy<2)
            selected=visual_tracker_select_ssd(candidates,count,result.video_sequence,
                                               result.video_timestamp_us,now_us());
        result.detector_score=highest;memset(result.box,0,sizeof result.box);
        if(selected>=0) {
            result.detector_score=candidates[selected].score;
            memcpy(result.box,candidates[selected].box,sizeof result.box);
        }
        int bird_valid=selected>=0 && isfinite(result.detector_score) &&
            result.detector_score>=fusion_detection_threshold && result.detector_score<=1.f;
        for(unsigned i=0;i<4;i++)bird_valid=bird_valid && isfinite(result.box[i]);
        bird_valid=bird_valid && result.box[0]>=0 && result.box[1]>=0 &&
            result.box[2]<=AV_VIDEO_WIDTH && result.box[3]<=AV_VIDEO_HEIGHT &&
            result.box[2]-result.box[0]>=8 && result.box[3]-result.box[1]>=8;
        if(!bird_valid && (!isfinite(result.detector_score) || result.detector_score<0 || result.detector_score>1)) {
            result.detector_score=0;memset(result.box,0,sizeof result.box);
        }
        if(!bird_valid)memset(result.box,0,sizeof result.box);
        if(bird_valid && capture_state==0 && job_mode==requested_mode && active_policy<2)
            visual_tracker_observe_ssd(result.detector_score,result.box,result.video_sequence,
                                       result.video_timestamp_us,now_us());
        if(capture_state==0 && job_mode==requested_mode)
            bird_focus_observe(result.detector_score,result.box,result.video_sequence,
                               result.video_timestamp_us,now_us());
        if(!bird_valid && active_mode==0){publish(1,0);return;}
        if(!bird_valid && active_mode==1 && active_policy<2) {
            /* Closed-set bird classification is not a bird-presence test.
             * Keep explicit manual ROI diagnostics, but abstain in auto mode. */
            result.top1=0;result.confidence=0;result.image_top1=0xffffffffu;
            memset(result.probabilities,0,sizeof result.probabilities);
            publish(9,0);return;
        }
        if(active_policy==3) {
            /* Same captured frame and weights; never pick the larger score
             * as proof of correctness. Keep both predictions for the user. */
            start=now_us();
            rc=fusion_classify_input((const uint16_t *)FUSION_IMAGE,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,(int8_t *)0x32FF9780u);
            result.image_preprocess_us+=(uint32_t)(now_us()-start);
            if(rc){publish(4,rc);return;}
            Xil_DCacheFlushRange(0x32FF9780u,49152);
            start=now_us();rc=run(2);result.image_compute_us+=(uint32_t)(now_us()-start);
            if(rc){publish(4,rc);return;}
            float full_scores[60];result.full_top1=fusion_scores(audio_logits,unified_logits,1,full_scores);
            result.full_confidence=full_scores[result.full_top1];
        }
        float crop_box[4];int use_roi=0;
        if(active_policy>=2) {
            for(int i=0;i<4;i++)crop_box[i]=active_box[i];
            use_roi=fusion_make_roi(AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,crop_box,result.roi)==0;
            if(!use_roi){publish(4,-22);return;}
        } else if(active_policy==1 && result.detector_score>=fusion_detection_threshold) {
            memcpy(crop_box,result.box,sizeof crop_box);
            float area=(crop_box[2]-crop_box[0])*(crop_box[3]-crop_box[1]);
            if(area>0 && area<=((float)AV_VIDEO_WIDTH)*((float)AV_VIDEO_HEIGHT)*.20f && fusion_make_roi(AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,crop_box,result.roi)==0) {
                use_roi=result.roi[2]-result.roi[0]<=AV_VIDEO_HEIGHT;
            }
        }
        if(use_roi) {
            start=now_us();
            rc=fusion_image_roi((const uint16_t *)FUSION_IMAGE,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,result.roi,(int8_t *)0x32FF9780u);
            result.image_preprocess_us+=(uint32_t)(now_us()-start);
            if(rc){publish(4,rc);return;}
            Xil_DCacheFlushRange(0x32FF9780u,49152);result.applied_policy=active_policy;
        } else {
            memset(result.roi,0,sizeof result.roi);start=now_us();
            rc=fusion_classify_input((const uint16_t *)FUSION_IMAGE,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,(int8_t *)0x32FF9780u);
            result.image_preprocess_us+=(uint32_t)(now_us()-start);
            if(rc){publish(4,rc);return;}
            Xil_DCacheFlushRange(0x32FF9780u,49152);
        }
        start=now_us();rc=run(2);result.image_compute_us+=(uint32_t)(now_us()-start);
        if(rc){publish(4,rc);return;}
        memcpy(image_logits,unified_logits,60);float pv[60];
        result.image_top1=fusion_scores(audio_logits,image_logits,1,pv);
        if(active_mode==1) {
            memcpy(result.probabilities,pv,sizeof pv);result.top1=result.image_top1;
            result.confidence=pv[result.top1];publish(6,0);return;
        }
        result.top1=fusion_scores(audio_logits,image_logits,fusion_image_weight,result.probabilities);
        result.confidence=result.probabilities[result.top1];publish(2,0);
    }
}
