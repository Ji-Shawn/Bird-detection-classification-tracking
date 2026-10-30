#include "av_shared.h"
#include "bird_focus.h"
#include "camera_recovery.h"
#include <math.h>
#include <string.h>
#include "ov5640_af_firmware.inc"

/* States on wire: 0 unavailable, 1 loading, 2 ready, 3 focusing,
 * 4 firmware-confirmed+held (not a measured image-quality claim), 5 error,
 * 6 search completed+held but firmware did not confirm contrast,
 * 7 manual moving, 8 manual register target verified (not optical focus). */
enum {IDLE, RESET_READ, RESET_WRITE, LOAD, VERIFY, INIT_REGS, START,
      BOOT_WAIT, ZONE_X, ZONE_Y, ZONE_ACK, ZONE_CMD, ZONE_WAIT,
      TRIGGER_ACK, TRIGGER_CMD, FOCUS_WAIT_ACK, FOCUS_WAIT_STATUS,
      RESULT_ACK, RESULT_CMD, RESULT_WAIT, RESULT_READ,
      HOLD_CMD, HOLD_WAIT, CANCEL_CMD,
      MANUAL_STOP, MANUAL_WAIT, MANUAL_MCU_READ, MANUAL_MCU_STOP,
      MANUAL_READ_HI, MANUAL_READ_LO, MANUAL_WRITE_LO, MANUAL_WRITE_HI,
      MANUAL_VERIFY_HI, MANUAL_VERIFY_LO};
static unsigned manual_mode,manual_target,manual_current,manual_next,manual_sequence;
static unsigned contrast_mode,contrast_stop;
static uint8_t manual_hi,manual_lo,manual_verify_hi,manual_mcu;
static unsigned enabled, state, step, index_, camera_available;
static unsigned hits, misses, zoom, pending, requests, successes;
static unsigned io_retries, firmware_ready;
static unsigned target_attempts;
/* Center requests are independent of detection/zoom. A failed detection must
 * not cancel the search needed to make the detector's input sharp. */
static unsigned center_pending, active_center;
static unsigned recovery_seen,recovery_reset_seen,recovery_wait,recovery_restore;
static unsigned recovery_target,recovery_user_manual;
volatile uint32_t bird_focus_diag[8]; /* last reg, op, I/O failures, FW status,
                                      * zone result, load index, step, retries */
static uint8_t reset_reg, center_x, center_y, result_flag;
static int error;
static uint32_t seq, score_q15;
static uint64_t next_poll, deadline, last_seen, last_observed, last_focus,poll_seen;
/* Lens motion budget survives target loss, mode toggles and manual retries.
 * Target identity (last_focus) must reset on reacquisition; actuator time must not. */
static uint64_t last_attempt;
static float previous[4], target[4], focused[4];
static uint32_t crop[4];
static int read_af(uint16_t r,uint8_t *v) {
    bird_focus_diag[0]=r;bird_focus_diag[1]=0;
    int rc=ov5640_af_read(r,v);
    if(rc)bird_focus_diag[2]++;
    else if(r==0x3029)bird_focus_diag[3]=*v;
    else if(r==0x3028)bird_focus_diag[4]=*v;
    return rc;
}
static int write_af(uint16_t r,uint8_t v) {
    bird_focus_diag[0]=r;bird_focus_diag[1]=1;
    int rc=ov5640_af_write(r,v);if(rc)bird_focus_diag[2]++;return rc;
}
#define ov5640_af_read read_af
#define ov5640_af_write write_af
static unsigned min_u(unsigned a,unsigned b){return a<b?a:b;}
static float overlap(const float *a,const float *b) {
    float w=fminf(a[2],b[2])-fmaxf(a[0],b[0]);
    float h=fminf(a[3],b[3])-fmaxf(a[1],b[1]);
    float inter=fmaxf(0,w)*fmaxf(0,h);
    float area=(a[2]-a[0])*(a[3]-a[1])+(b[2]-b[0])*(b[3]-b[1])-inter;
    return area>0?inter/area:0;
}
static void forget_detection(void) {
    hits=misses=zoom=0;last_seen=last_observed=0;
    /* A reacquired photo may be at a different distance at the SAME pixels. */
    last_focus=0;target_attempts=0;memset(focused,0,sizeof focused);
    memset(previous,0,sizeof previous);memset(target,0,sizeof target);
    memset(crop,0,sizeof crop);
}
void bird_focus_forget(void) {
    forget_detection();pending=0;
    if(state==3 && !active_center)step=CANCEL_CMD;
    else if((state==4 || state==6) && !active_center)state=2;
}
void bird_focus_init(int camera_ok,uint64_t now) {
    camera_available=camera_ok;enabled=1;state=camera_ok?1:0;
    step=camera_ok?RESET_READ:IDLE;index_=0;error=0;
    requests=successes=0;last_focus=last_attempt=0;next_poll=poll_seen=now;deadline=now+60000000u;
    io_retries=firmware_ready=0;memset((void *)bird_focus_diag,0,sizeof bird_focus_diag);
    manual_mode=manual_target=manual_sequence=0;manual_current=UINT32_MAX;
    contrast_mode=contrast_stop=0;
    center_pending=active_center=0;
    recovery_seen=ov5640_recovery_generation();recovery_reset_seen=ov5640_recovery_reset_generation();
    recovery_wait=recovery_restore=0;recovery_target=UINT32_MAX;recovery_user_manual=0;
    memset(focused,0,sizeof focused);bird_focus_forget();
}
int bird_focus_control(unsigned action) {
    if(action>2 || !camera_available)return -1;
    if(manual_mode) {
        if(action==0 && contrast_mode) {
            /* Stop wins even during a split register pair. Complete that pair
             * before holding; never leave half of a VCM code on the sensor. */
            enabled=0;center_pending=active_center=0;bird_focus_forget();
            contrast_mode=0;contrast_stop=1;manual_sequence++;
            if(step==MANUAL_WRITE_HI || step==MANUAL_VERIFY_HI || step==MANUAL_VERIFY_LO)
                manual_target=manual_next;
            else if(manual_current<=1023)manual_target=manual_current;
            return 0;
        }
        /* Finish the bounded split-register update before changing ownership. */
        if(state==7)return -1;
        if(action==0)return 0; /* Hold manual position, never release AF MCU. */
        manual_mode=0;contrast_mode=contrast_stop=0;manual_current=UINT32_MAX;enabled=1;
        bird_focus_forget();state=1;step=RESET_READ;index_=0;
        deadline=0;error=0;firmware_ready=io_retries=0;
        return 0;
    }
    if(action==0){
        enabled=0;center_pending=active_center=0;bird_focus_forget();return 0;
    }
    /* Busy requests are rejected explicitly, never silently marked applied. */
    if(action==2 && (state==1 || state==3))return -1;
    unsigned was_enabled=enabled;
    enabled=1;
    if(action==1 && !was_enabled)center_pending=1;
    if(action==2) {
        if(state==5) {
            if(firmware_ready && error==-4) {
                state=2;step=IDLE;center_pending=1;last_focus=0;error=0;
            } else {
                state=1;step=RESET_READ;index_=0;deadline=0;error=0;firmware_ready=0;
            }
            io_retries=0;
        }
        else if(state==2 || state==4 || state==6) {
            center_pending=1;last_focus=0;target_attempts=0;
        }
    }
    return 0;
}
int bird_focus_manual(unsigned position) {
    if(position>1023 || ov5640_recovery_busy() || !camera_available || !firmware_ready || state==1 || state==5)return -1;
    manual_target=position;manual_sequence++;contrast_stop=0;
    if(contrast_mode) {
        /* A user DAC request takes ownership, including a coalesced request. */
        contrast_mode=contrast_stop=0;enabled=0;
        center_pending=active_center=0;bird_focus_forget();
    }
    if(manual_mode && state==7)return 0; /* Coalesce; finish current register pair. */
    enabled=0;center_pending=active_center=0;bird_focus_forget();error=0;io_retries=0;
    step=manual_mode?MANUAL_READ_HI:MANUAL_STOP;
    manual_mode=1;state=7;deadline=0;
    return 0;
}
int bird_focus_contrast_move(unsigned position) {
    if(position>1023 || ov5640_recovery_busy() || !enabled || !camera_available || !firmware_ready ||
       state==1 || state==5 || state==3 || (manual_mode && !contrast_mode))return -1;
    manual_target=position;manual_sequence++;
    if(contrast_mode && state==7)return 0;
    center_pending=active_center=pending=0;error=0;io_retries=0;
    step=manual_mode?MANUAL_READ_HI:MANUAL_STOP;
    manual_mode=contrast_mode=1;contrast_stop=0;state=7;deadline=0;
    return 0;
}
void bird_focus_manual_status(uint32_t words[6]) {
    words[0]=0x4d463031u;words[1]=manual_mode;words[2]=manual_target;
    words[3]=manual_current;words[4]=(state==7);words[5]=manual_sequence;
}
void bird_focus_observe(float score,const float b[4],uint32_t sequence,
                        uint64_t captured,uint64_t now) {
    if(!enabled || !captured || captured>now || now-captured>5000000u ||
       captured<=last_observed)return;
    last_observed=captured;
    int good=isfinite(score) && score>=.5f && score<=1.f;
    for(unsigned i=0;i<4;i++)good=good && isfinite(b[i]);
    good=good && b[0]>=0 && b[1]>=0 && b[2]<=AV_VIDEO_WIDTH && b[3]<=AV_VIDEO_HEIGHT &&
         b[2]-b[0]>=8 && b[3]-b[1]>=8;
    if(!good) {hits=0;if(++misses>=2)forget_detection();return;}
    misses=0;
    hits=(last_seen && captured-last_seen<=12000000u && overlap(previous,b)>=.35f)?hits+1:1;
    if(hits==1 && zoom) {
        zoom=0;memset(crop,0,sizeof crop);
    }
    memcpy(previous,b,sizeof previous);last_seen=captured;
    if(hits<2)return;
    hits=2;zoom=1;seq=sequence;score_q15=(uint32_t)(score*32767.f);
    memcpy(target,b,sizeof target);
    /* Preserve 16:9, 50% context and the existing 320x180 minimum crop.
     * With a 1920x1080 source this permits up to 6x display-only zoom. */
    float w=fmaxf(320.f,fmaxf((b[2]-b[0])*1.5f,(b[3]-b[1])*1.5f*16.f/9.f));
    unsigned cw=min_u(AV_VIDEO_WIDTH,((unsigned)ceilf(w/16.f))*16),ch=cw*9/16;
    int x=(int)((b[0]+b[2]-cw)*.5f),y=(int)((b[1]+b[3]-ch)*.5f);
    if(x<0)x=0;if(y<0)y=0;
    if(x>(int)(AV_VIDEO_WIDTH-cw))x=AV_VIDEO_WIDTH-cw;if(y>(int)(AV_VIDEO_HEIGHT-ch))y=AV_VIDEO_HEIGHT-ch;
    crop[0]=x;crop[1]=y;crop[2]=x+cw;crop[3]=y+ch;
    /* Detection controls ROI only. Keep the lens held across detections,
     * jitter and misses; optical search itself can temporarily hide a bird.
     * Only startup, explicit enable/refocus or manual control moves it. */
}
static void fail(int reason) {error=reason;state=5;step=CANCEL_CMD;pending=0;if(manual_mode)manual_current=UINT32_MAX;}
static int recovery_sync(uint64_t now){
    unsigned generation=ov5640_recovery_generation();
    if(generation!=recovery_seen){
        recovery_seen=generation;recovery_wait=1;
        recovery_user_manual=manual_mode&&!contrast_mode;
        recovery_target=recovery_user_manual?manual_target:manual_current;
        forget_detection();pending=center_pending=active_center=0;
        if(state==3){step=CANCEL_CMD;state=2;}
        /* A paused contrast update must finish its bounded split-register
         * pair, then hold. Preserve a user's requested manual destination. */
        if(contrast_mode&&state==7){
            if(step==MANUAL_WRITE_HI||step==MANUAL_VERIFY_HI||step==MANUAL_VERIFY_LO)manual_target=manual_next;
            else if(manual_current<=1023u)manual_target=manual_current;
            contrast_stop=1;
        }
    }
    if(ov5640_recovery_busy()){poll_seen=now;return 1;}
    if(recovery_wait){
        recovery_wait=0;next_poll=now;deadline=now+60000000u;
        if(recovery_reset_seen!=ov5640_recovery_reset_generation()){
            recovery_reset_seen=ov5640_recovery_reset_generation();
            if(!recovery_user_manual){unsigned saved;if(ov5640_recovery_saved_focus(&saved))recovery_target=saved;}
            else recovery_target=manual_target;
            /* Reset discards the AF MCU RAM. Reload and verify one byte per
             * poll, but never request default center AF after recovery. */
            recovery_restore=1;firmware_ready=0;io_retries=0;error=0;
            state=1;step=RESET_READ;index_=0;
        }
    }
    return 0;
}
void bird_focus_poll(uint64_t now) {
    if(recovery_sync(now))return;
    if(now<poll_seen) {
        next_poll=now;deadline=now+(manual_mode?5000000u:60000000u);
        last_attempt=now;
        if(last_seen>now)forget_detection();
    }
    poll_seen=now;
    if(last_seen && now-last_seen>12000000u)forget_detection();
    if(now<next_poll || !camera_available)return;
    next_poll=now+1000u; /* One transaction per call; never busy-wait for AF. */
    if(!deadline)deadline=now+(manual_mode?5000000u:60000000u);
    if(((pending && zoom) || center_pending) && enabled && step==IDLE && (state==2 || state==4 || state==6) &&
       (!last_attempt || (now>=last_attempt && now-last_attempt>=8000000u))) {
        active_center=!zoom;center_pending=0;
        pending=0;state=3;error=0;step=ZONE_X;deadline=now+6000000u;
        last_focus=last_attempt=now;requests++;target_attempts++;memcpy(focused,target,sizeof focused);
        /* OV VVF touch center: 80x60. Clamp away from the zone edges.
         * Reference: OV5640 Embedded Firmware User Guide, sections 4/5.
         * Physical zone alignment at 1080p still requires board acceptance. */
        center_x=active_center?40:(uint8_t)fminf(72,fmaxf(8,(target[0]+target[2])*40.f/((float)AV_VIDEO_WIDTH)));
        center_y=active_center?30:(uint8_t)fminf(54,fmaxf(6,(target[1]+target[3])*30.f/((float)AV_VIDEO_HEIGHT)));
    }
    if(step==IDLE)return;
    if(step!=CANCEL_CMD && now>deadline){fail(-2);return;}
    uint8_t value=0;int rc=0;
    unsigned old_step=step,old_index=index_,old_state=state;
    uint64_t old_deadline=deadline;
    bird_focus_diag[5]=index_;bird_focus_diag[6]=step;
    switch(step) {
    case RESET_READ:rc=ov5640_af_read(0x3000,&reset_reg);step=RESET_WRITE;break;
    case RESET_WRITE:rc=ov5640_af_write(0x3000,reset_reg|0x20);index_=0;step=LOAD;break;
    case LOAD:
        rc=ov5640_af_write(0x8000+index_,ov5640_af_firmware[index_]);
        if(++index_==sizeof ov5640_af_firmware){index_=0;step=VERIFY;}break;
    case VERIFY:
        rc=ov5640_af_read(0x8000+index_,&value);
        if(!rc && value!=ov5640_af_firmware[index_]){fail(-3);return;}
        if(++index_==sizeof ov5640_af_firmware){index_=0;step=INIT_REGS;}break;
    case INIT_REGS:
        rc=ov5640_af_write(0x3022+index_,index_==7?0x7f:0);
        if(++index_==8)step=START;break;
    case START:rc=ov5640_af_write(0x3000,reset_reg&~0x20);step=BOOT_WAIT;deadline=now+5000000u;break;
    case BOOT_WAIT:
        rc=ov5640_af_read(0x3029,&value);next_poll=now+20000;
        if(!rc && value==0x70){
            state=2;step=IDLE;firmware_ready=1;
            if(recovery_restore){
                recovery_restore=0;center_pending=active_center=pending=0;
                if(recovery_target<=1023u){
                    manual_target=recovery_user_manual?manual_target:recovery_target;
                    manual_mode=1;contrast_mode=enabled&&!recovery_user_manual;contrast_stop=0;
                    manual_current=UINT32_MAX;manual_sequence++;state=7;step=MANUAL_STOP;deadline=now+5000000u;
                }else{manual_mode=contrast_mode=0;error=-6;} /* Original lens code unavailable. */
            }else center_pending=enabled;
        }break;
    case ZONE_X:rc=ov5640_af_write(0x3024,center_x);step=ZONE_Y;break;
    case ZONE_Y:rc=ov5640_af_write(0x3025,center_y);step=ZONE_ACK;break;
    case ZONE_ACK:rc=ov5640_af_write(0x3023,1);step=ZONE_CMD;break;
    case ZONE_CMD:rc=ov5640_af_write(0x3022,0x81);step=ZONE_WAIT;break;
    case ZONE_WAIT:
        rc=ov5640_af_read(0x3023,&value);next_poll=now+20000;
        if(!rc && !value)step=TRIGGER_ACK;break;
    case TRIGGER_ACK:rc=ov5640_af_write(0x3023,1);step=TRIGGER_CMD;break;
    case TRIGGER_CMD:rc=ov5640_af_write(0x3022,3);step=FOCUS_WAIT_ACK;break;
    case FOCUS_WAIT_ACK:
        rc=ov5640_af_read(0x3023,&value);next_poll=now+20000;
        if(!rc && !value)step=FOCUS_WAIT_STATUS;break;
    case FOCUS_WAIT_STATUS:
        rc=ov5640_af_read(0x3029,&value);next_poll=now+20000;
        if(!rc && value==0x10)step=RESULT_ACK;break;
    case RESULT_ACK:rc=ov5640_af_write(0x3023,1);step=RESULT_CMD;break;
    case RESULT_CMD:rc=ov5640_af_write(0x3022,7);step=RESULT_WAIT;break;
    case RESULT_WAIT:
        rc=ov5640_af_read(0x3023,&value);next_poll=now+20000;
        if(!rc && !value)step=RESULT_READ;break;
    case RESULT_READ:
        /* THIS vendor firmware (SHA in .inc), command 07 handler at 0x0941:
         * A2 37 E4 33 F5 3C -> boolean contrast flag in direct RAM 0x3c;
         * output at 0x0a1d writes 3d..40 to 3024..27, 3c to 3028.
         * 3024 remains the touch X coordinate, NOT a zone-0 failure code.
         * The generic 2010 five-zone firmware guide does not match this ABI.
         * Keep raw flag visible; a completed search alone is not proof of
         * improved sharpness. A clear flag is reported as unconfirmed. */
        rc=ov5640_af_read(0x3028,&value);result_flag=value;
        if(!rc && value>1){fail(-4);return;}
        step=HOLD_CMD;break;
    case HOLD_CMD:rc=ov5640_af_write(0x3022,6);step=HOLD_WAIT;break;
    case HOLD_WAIT:
        rc=ov5640_af_read(0x3022,&value);next_poll=now+20000;
        if(!rc && !value){state=result_flag?4:6;step=IDLE;if(result_flag)successes++;}break;
    case CANCEL_CMD:
        rc=ov5640_af_write(0x3022,6);step=IDLE;
        if(state==3)state=2;break;
    case MANUAL_STOP:rc=ov5640_af_write(0x3022,6);step=MANUAL_WAIT;break;
    case MANUAL_WAIT:
        rc=ov5640_af_read(0x3022,&value);next_poll=now+20000;
        if(!rc && !value)step=MANUAL_MCU_READ;break;
    case MANUAL_MCU_READ:rc=ov5640_af_read(0x3000,&manual_mcu);step=MANUAL_MCU_STOP;break;
    case MANUAL_MCU_STOP:
        /* Halt only the AF MCU; preserve every other 0x3000 bit. No sensor reset. */
        rc=ov5640_af_write(0x3000,manual_mcu|0x20);step=MANUAL_READ_HI;break;
    case MANUAL_READ_HI:rc=ov5640_af_read(0x3603,&manual_hi);step=MANUAL_READ_LO;break;
    case MANUAL_READ_LO:
        rc=ov5640_af_read(0x3602,&manual_lo);
        if(!rc){manual_current=((manual_hi&0x3fu)<<4)|(manual_lo>>4);
            if(contrast_stop)manual_target=manual_current;}
        step=MANUAL_WRITE_LO;break;
    case MANUAL_WRITE_LO:
        /* OV5640 DS tables 3-3 / 7-6: D[9:4] in 3603[5:0], D[3:0]
         * in 3602[7:4]. Preserve slew bits and debug bit, enable VCM (PD=0).
         * Ramp <=16 DAC codes per verified pair; never busy-wait. */
        if(manual_current<manual_target)manual_next=min_u(manual_current+16,manual_target);
        else manual_next=manual_current-manual_target>16?manual_current-16:manual_target;
        rc=ov5640_af_write(0x3602,(manual_next<<4)|(manual_lo&15));
        step=MANUAL_WRITE_HI;break;
    case MANUAL_WRITE_HI:
        rc=ov5640_af_write(0x3603,(manual_hi&0x40)|(manual_next>>4));
        step=MANUAL_VERIFY_HI;break;
    case MANUAL_VERIFY_HI:rc=ov5640_af_read(0x3603,&manual_verify_hi);step=MANUAL_VERIFY_LO;break;
    case MANUAL_VERIFY_LO:
        rc=ov5640_af_read(0x3602,&value);
        if(!rc) {
            if(manual_verify_hi!=((manual_hi&0x40)|(manual_next>>4)) ||
               value!=(uint8_t)((manual_next<<4)|(manual_lo&15))) {
                manual_current=UINT32_MAX;fail(-5);return;
            }
            manual_current=manual_next;last_attempt=now;
            if(manual_current==manual_target){state=8;step=IDLE;}
            else {step=MANUAL_WRITE_LO;next_poll=now+20000;}
        }
        break;
    default:step=IDLE;break;
    }
    if(rc) {
        if(++io_retries<3) {
            /* Do not skip a firmware byte or command after a transient NACK. */
            step=old_step;index_=old_index;state=old_state;deadline=old_deadline;
            next_poll=now+20000;
        } else {error=-1;state=5;step=IDLE;pending=0;firmware_ready=0;if(manual_mode)manual_current=UINT32_MAX;}
    } else io_retries=0;
    bird_focus_diag[7]=io_retries;
}
void bird_focus_status(uint32_t words[16],uint64_t now) {
    memset(words,0,16*sizeof *words);
    words[0]=0x41465a31u;words[1]=enabled;words[2]=state;words[3]=(uint32_t)error;
    words[4]=zoom && enabled && last_seen && now>=last_seen && now-last_seen<=12000000u;
    words[5]=seq;words[6]=last_seen?(uint32_t)((now-last_seen)/1000u):UINT32_MAX;
    words[7]=score_q15;memcpy(words+8,crop,sizeof crop);
    words[12]=center_x;words[13]=center_y;words[14]=requests;words[15]=successes;
}
