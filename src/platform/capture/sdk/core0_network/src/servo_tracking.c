/* M42 one-use formal vertical direction for visual loss search. */
#include "visual_detection_policy.h"
#include "visual_servo_policy.h"
#include "visual_feedforward.h"
#include "visual_recovery_policy.h"
#include "visual_tracker.h"
#include "servo_tracking.h"
#include "servo_calibration.h"
#include "sound_seek_confirm.h"
#include "sound_tuning.h"
#include "network_service.h"
#include "av_regs.h"
#include <math.h>
#include <string.h>
#include <limits.h>
#define REG_BASE 0x43C00000u
#define BOOT_STATE 0x30f01100u
#define SOUND_FRESH_US 8000000u
enum {MANUAL,WAIT_STABLE,CENTERED,COOLDOWN,LIMIT,WAIT_POST_MOTION,
      NO_DETECTION,MOVING,LEASE_EXPIRED,HOMING,WAIT_SOUND};
enum {SOUND_OFF,SOUND_WAIT,SOUND_POST_MOTION,SOUND_CENTERED,SOUND_VISUAL,
      SOUND_LIMIT,SOUND_COOLDOWN,SOUND_MOVING,SOUND_LEASE_EXPIRED,SOUND_HOMING,SOUND_SCANNING,SOUND_CANDIDATE_HOLD};
enum {SEEK_TURN,SEEK_SETTLE,SEEK_SCAN};
static uint64_t clock_now,not_before,settled_after,auto_expires,home_next;
static uint64_t detection_captured,last_capture,sound_cutoff,last_sound,external_visual_time;
static unsigned hz,supported,automatic,sound_automatic,pan_us,tilt_us,hits;
static unsigned had_visual,homing,sound_plan_active,sound_state,reason,visual_last_band;
static unsigned external_visual;
static unsigned sound_phase,sound_target_us;
static uint64_t sound_pan_stable_after;
static int32_t sound_command_yaw;
static int scan_direction;
/* Scan commands use <=0.2-degree increments rather than a 2-degree jump
 * every 400 ms. The 0..100-degree shaft table has exactly 10 us/degree.
 * A late service call never accrues a larger motion or a burst of commands. */
static float scan_rate_dps=4.f;
static unsigned scan_step_us=1u,scan_interval_us=25000u,scan_active;
static uint64_t scan_last_accepted;
int servo_tracking_configure_scan_rate(float rate) {
    if(!isfinite(rate) || rate<.5f || rate>10.f)return -1;
    unsigned step=rate>5.f?2u:1u;
    unsigned interval=(unsigned)ceilf((float)step*100000.f/rate);
    if(interval<SERVO_FRAME_US)interval=SERVO_FRAME_US;
    scan_rate_dps=rate;scan_step_us=step;scan_interval_us=interval;
    return 0;
}
float servo_tracking_scan_rate(void) {return scan_rate_dps;}
void servo_tracking_scan_timing(uint32_t words[2]) {
    words[0]=scan_step_us;words[1]=scan_interval_us;
}
static void scan_reset(void) {scan_active=0;scan_last_accepted=0;}
static unsigned recovery_scanning,boundary_latched,recovery_sparse_seen;
static uint64_t recovery_started,recovery_deadline,recovery_clock,recovery_sparse_until,last_qualified_sound;
static uint64_t recovery_visual_hold_until;
/* Formal NCC's bounded retry holds the camera still; it never renews the
 * 30-second recovery deadline or supplies a location to continuous control. */
static uint64_t reacquire_hold_until;
/* Image Y grows downward, and positive visual Y increases tilt PWM.
 * This memory only picks the first scan direction; it does not keep a stale
 * coordinate alive. Existing NCC/sparse freshness contracts remain intact. */
static int last_formal_vertical_direction;
static uint64_t formal_direction_capture,formal_direction_observed;
static unsigned recovery_directional;
static void formal_direction_forget(void) {
    last_formal_vertical_direction=0;
    formal_direction_capture=formal_direction_observed=0;
}
static void formal_direction_record(const float box[4],uint64_t captured,uint64_t now) {
    float error=(box[1]+box[3])*.5f-AV_VIDEO_HEIGHT*.5f;
    last_formal_vertical_direction=error>0.f?1:error<0.f?-1:0;
    formal_direction_capture=captured;formal_direction_observed=now;
}
static void formal_direction_time_guard(uint64_t now) {
    formal_direction_forget();
    if(!automatic)return;
    /* Invalid time cannot unlock an inherited motion guard or issue a
     * same-call scan step. Clock rollback retains the stronger existing floor. */
    uint64_t after=UINT64_MAX-now<SERVO_FRAME_US?UINT64_MAX:now+SERVO_FRAME_US;
    if(not_before<after)not_before=after;
    if(settled_after<after)settled_after=after;
}
static void recovery_start(void);
static void recovery_poll(void);
static int tilt(unsigned pulse,unsigned maximum_step,unsigned interval);
static void recovery_reset(void) {
    scan_reset();
    recovery_scanning=0;recovery_started=recovery_deadline=recovery_clock=0;
    recovery_visual_hold_until=0;
    recovery_sparse_seen=0;recovery_sparse_until=0;
    reacquire_hold_until=0;recovery_directional=0;
}
int servo_tracking_recovery_active(void) {return recovery_scanning!=0;}
int servo_tracking_reacquire_active(uint64_t now) {
    return automatic && now<auto_expires && recovery_scanning &&
        now>=recovery_started && now>=recovery_clock &&
        reacquire_hold_until && now<reacquire_hold_until && now<recovery_deadline;
}
void servo_tracking_reacquire(unsigned retry,uint64_t started,uint64_t now) {
    if(!retry){reacquire_hold_until=0;return;}
    /* Known-direction loss intentionally starts scanning immediately,
     * while NCC may still run its unchanged bounded matching retries. */
    if(recovery_directional)return;
    if(!automatic || !recovery_scanning || now<started || now<recovery_started ||
       now<recovery_clock || started<recovery_started || now>=auto_expires)return;
    uint64_t until=UINT64_MAX-started<VISUAL_TRACKER_REACQUIRE_US?
        UINT64_MAX:started+VISUAL_TRACKER_REACQUIRE_US;
    if(until>recovery_deadline)until=recovery_deadline;
    if(until<=now)return;
    /* Repeated missed frames cannot slide the first retry's fixed deadline. */
    if(!reacquire_hold_until || until<reacquire_hold_until)reacquire_hold_until=until;
}
static sound_seek_confirm sound_confirmation;
static uint32_t sound_accept_sequence;
uint32_t servo_tracking_sound_accept_sequence(void){return sound_accept_sequence;}
/* M43: sound settings are adopted as a single RAM-only revision. */
static const float audio_defaults[8]=SOUND_TUNING_DEFAULTS;
static float audio_values[8]=SOUND_TUNING_DEFAULTS;
static uint64_t audio_adopted_after;
static uint32_t audio_revision=1u,audio_ack_request,audio_ack_status,audio_applies,audio_cache_next;
static struct {uint8_t request[46];uint32_t id,status,valid;} audio_cache[16];
static void audio_reset(void) {
    memcpy(audio_values,audio_defaults,sizeof audio_values);
    audio_adopted_after=0;audio_revision=1u;audio_ack_request=audio_ack_status=audio_applies=audio_cache_next=0;
    memset(audio_cache,0,sizeof audio_cache);
}
static void audio_forget_evidence(void) {
    sound_seek_confirm_clear(&sound_confirmation);
    sound_cutoff=audio_adopted_after=clock_now;last_sound=0;
    /* An accepted turn/scan and visual controller keep their current owner.
     * Only fresh post-application observations may confirm a new bearing. */
}
void servo_tracking_sound_timing_forget(uint64_t now) {
    sound_seek_confirm_clear(&sound_confirmation);
    sound_cutoff=now;last_sound=0;
}
float servo_tracking_audio_value(unsigned i) {return i<8u?audio_values[i]:0.f;}
uint32_t servo_tracking_audio_revision(void) {return audio_revision;}
uint64_t servo_tracking_audio_evidence_after(void) {return audio_adopted_after;}
int servo_tracking_audio_threshold(unsigned percent) {
    if(percent<1u || percent>99u || audio_revision==UINT32_MAX)return -1;
    audio_values[SOUND_TUNE_THRESHOLD]=(float)percent;audio_revision++;audio_applies++;
    audio_forget_evidence();return 0;
}
static uint32_t audio_be32(const uint8_t *p) {
    return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];
}
int servo_tracking_audio_command(uint32_t boot_id,const uint8_t *p,unsigned bytes) {
    if(!p || bytes!=46u)return -1;
    uint32_t request=audio_be32(p+10),status=0;
    audio_ack_request=request;
    if(p[0]!=24u || p[1]!=1u){audio_ack_status=2u;return -1;}
    if(!boot_id || audio_be32(p+2)!=boot_id){audio_ack_status=3u;return -1;}
    if(!request){audio_ack_status=5u;return -1;}
    for(unsigned i=0;i<16u;i++)if(audio_cache[i].valid && audio_cache[i].id==request) {
        status=memcmp(audio_cache[i].request,p,46u)?6u:audio_cache[i].status;
        if(status==1u)status=7u;
        audio_ack_status=status;return status==7u?0:-1;
    }
    float values[8];
    const float lower[8]={1.f,2.f,513.f,2.f,300.f,600.f,3.f,5.f};
    const float upper[8]={99.f,16.f,16384.f,30.f,1500.f,1500.f,45.f,120.f};
    for(unsigned i=0;i<8u;i++) {
        uint32_t bits=audio_be32(p+14+4u*i);memcpy(values+i,&bits,4);
        if(!isfinite(values[i]) || values[i]<lower[i] || values[i]>upper[i])status=5u;
        if((i==0u || i==2u || i==4u || i==5u) &&
           isfinite(values[i]) && floorf(values[i])!=values[i])status=5u;
    }
    if(values[SOUND_TUNE_REAIM]<values[SOUND_TUNE_ACQUIRE])status=5u;
    if(!supported)status=8u;
    if(audio_be32(p+6)!=audio_revision || audio_revision==UINT32_MAX)status=4u;
    if(!status) {
        memcpy(audio_values,values,sizeof audio_values);audio_revision++;audio_applies++;
        audio_forget_evidence();status=1u;
    }
    unsigned index=audio_cache_next++&15u;
    memcpy(audio_cache[index].request,p,46u);audio_cache[index].id=request;
    audio_cache[index].status=status;audio_cache[index].valid=1u;
    audio_ack_status=status;return status==1u?0:-1;
}
void servo_tracking_audio_status(uint32_t words[16],uint32_t boot_id) {
    memset(words,0,16u*sizeof *words);words[0]=0x534e4432u;words[1]=1u;
    words[2]=audio_revision;words[3]=audio_ack_request;words[4]=audio_ack_status;words[5]=boot_id;
    for(unsigned i=0;i<8u;i++)memcpy(words+6+i,audio_values+i,4);
    words[14]=audio_applies;
}
static int audio_confirm(int32_t target,unsigned quality,uint64_t captured,
                         uint64_t now,unsigned reaim,int32_t *out) {
    return sound_seek_confirm_push_config(&sound_confirmation,target,quality,captured,now,
        (unsigned)(audio_values[reaim?SOUND_TUNE_REAIM:SOUND_TUNE_ACQUIRE]*1000.f),out,
        (unsigned)audio_values[SOUND_TUNE_QUALITY],
        (int32_t)(audio_values[SOUND_TUNE_JITTER]*1000.f));
}
static uint64_t candidate_hold_until;
static uint64_t formal_acquire_until,formal_acquire_capture,formal_acquire_clock;
void servo_tracking_visual_acquired(uint64_t captured,uint64_t now) {
    if(now<formal_acquire_clock){formal_acquire_until=0;return;}
    if(!automatic || now>=auto_expires || !captured || captured>now ||
       now-captured>5000000u || captured<=formal_acquire_capture)return;
    formal_acquire_capture=captured;formal_acquire_clock=now;
    formal_acquire_until=UINT64_MAX-now<500000u?UINT64_MAX:now+500000u;
}
static unsigned formal_acquire_hold(uint64_t now) {
    return automatic && now>=formal_acquire_clock && now<formal_acquire_until;
}
static unsigned candidate_live,candidate_seen;
static void candidate_hold_reset(void) {
    candidate_hold_until=0;candidate_live=candidate_seen=0;
}
static unsigned candidate_hold_active(uint64_t now) {
    if(candidate_hold_until && now>=candidate_hold_until)candidate_hold_until=0;
    if(!candidate_live && !candidate_hold_until)candidate_seen=0;
    if(candidate_live && !candidate_seen) {
        candidate_seen=1;candidate_hold_until=now+VISUAL_CANDIDATE_SCAN_HOLD_US;
    }
    return candidate_hold_until && now<candidate_hold_until;
}
void servo_tracking_sound_candidate(unsigned pending,uint64_t now) {
    candidate_live=pending!=0;
    if(candidate_hold_until && now>=candidate_hold_until)candidate_hold_until=0;
    if(!candidate_live && !candidate_hold_until)candidate_seen=0;
    if(automatic && (recovery_scanning ||
       (sound_automatic && sound_plan_active && sound_phase==SEEK_SCAN)) &&
       now<auto_expires)(void)candidate_hold_active(now);
}
static void sound_advance(void);
static uint32_t last_observation,last_command,sound_steps,detection[10];
static int32_t sound_angle_mdeg,sound_target_pan;
static float previous_x,previous_y;
static unsigned ncc_detection;
static uint64_t continuous_time_floor;
static struct {
    unsigned active,pan_moving,tilt_moving;
    uint32_t sequence;
    uint64_t captured,updated,clock;
    float x,y,pan_mdeg,tilt_mdeg;
} continuous;
/* M39: full-frame normalized visual errors; compile-time defaults remain
 * the M38 candidate settings. All changes are atomic and RAM-only. */
static const float tuning_defaults[8]={VISUAL_SERVO_PAN_KP_DPS,VISUAL_SERVO_TILT_KP_DPS,
    VISUAL_SERVO_PAN_MAX_DPS,VISUAL_SERVO_TILT_MAX_DPS,VISUAL_SERVO_PAN_DEAD_ENTER,
    VISUAL_SERVO_PAN_DEAD_EXIT,VISUAL_SERVO_TILT_DEAD_ENTER,VISUAL_SERVO_TILT_DEAD_EXIT};
static float tuning_values[8];
static uint32_t tuning_revision,tuning_ack_request,tuning_ack_status,tuning_applies,tuning_cache_next;
static struct {uint8_t request[46];uint32_t id,status,valid;} tuning_cache[16];
/* Independent RAM-only M47 transaction; the original SRV9 values stay intact. */
static const float ff_defaults[8]={0.f,55.f,.3f,.3f,5.f,3.f,120.f,1.f};
static float ff_values[8],ff_p[2],ff_total[2];
static visual_ff_state feedforward;
static uint32_t ff_revision,ff_ack_request,ff_ack_status,ff_applies,ff_cache_next;
static struct {uint8_t request[46];uint32_t id,status,valid;} ff_cache[16];
static void ff_configuration_reset(void) {
    memcpy(ff_values,ff_defaults,sizeof ff_values);ff_revision=1u;
    ff_ack_request=ff_ack_status=ff_applies=ff_cache_next=0;
    memset(ff_cache,0,sizeof ff_cache);
}
static void tuning_reset(void) {
    memcpy(tuning_values,tuning_defaults,sizeof tuning_values);
    tuning_revision=1u;tuning_ack_request=tuning_ack_status=tuning_applies=tuning_cache_next=0;
    memset(tuning_cache,0,sizeof tuning_cache);
}
static void continuous_reset(void) {
    memset(&continuous,0,sizeof continuous);visual_ff_reset(&feedforward,6u);
    memset(ff_p,0,sizeof ff_p);memset(ff_total,0,sizeof ff_total);
}
static void visual_location_lost(void) {
    continuous_reset();
    if(automatic && had_visual)recovery_start();
}
static void continuous_poll(void);
static const unsigned pulse_table[]={540,640,740,840,940,1040,1140,1240,1340,1440,
    1540,1640,1740,1840,1940,2040,2140,2240,2340,2440,2480};
static const unsigned angle_table[]={0,10,20,30,40,50,60,70,80,90,
    100,105,110,120,125,140,145,150,165,175,180};
static uint32_t read_reg(unsigned offset){return platform_mmio_read(REG_BASE+offset);}
static void write_reg(unsigned offset,uint32_t value){platform_mmio_write(REG_BASE+offset,value);}
static uint32_t ticks(unsigned us){return (uint32_t)(((uint64_t)hz*us+500000u)/1000000u);}
/* Camera yaw relative to center, using the supplied shaft calibration x2.
 * This is a commanded position, not encoder feedback. */
static int32_t pose(void) {
    for(unsigned i=1;i<sizeof pulse_table/sizeof pulse_table[0];i++)if(pan_us<=pulse_table[i]) {
        unsigned span=pulse_table[i]-pulse_table[i-1];
        uint32_t shaft=angle_table[i-1]*1000u+
            ((pan_us-pulse_table[i-1])*(angle_table[i]-angle_table[i-1])*1000u+span/2)/span;
        return (int32_t)(shaft*2u)-180000;
    }
    return 180000;
}
static unsigned pulse_for_pose(int32_t yaw) {
    if(yaw<=-180000)return SERVO_PAN_MIN_US;
    if(yaw>=180000)return SERVO_PAN_MAX_US;
    unsigned shaft=(unsigned)(yaw+180000)/2u;
    for(unsigned i=1;i<sizeof angle_table/sizeof angle_table[0];i++)if(shaft<=angle_table[i]*1000u) {
        unsigned span=(angle_table[i]-angle_table[i-1])*1000u;
        return pulse_table[i-1]+((shaft-angle_table[i-1]*1000u)*
            (pulse_table[i]-pulse_table[i-1])+span/2)/span;
    }
    return SERVO_PAN_MAX_US;
}
static float shaft_for_pulse(unsigned pulse) {
    if(pulse<=pulse_table[0])return 0.f;
    for(unsigned i=1;i<sizeof pulse_table/sizeof pulse_table[0];i++)if(pulse<=pulse_table[i])
        return angle_table[i-1]*1000.f+(pulse-pulse_table[i-1])*
            (angle_table[i]-angle_table[i-1])*1000.f/(pulse_table[i]-pulse_table[i-1]);
    return 180000.f;
}
static unsigned pulse_for_shaft(float shaft) {
    if(shaft<=0.f)return pulse_table[0];
    for(unsigned i=1;i<sizeof angle_table/sizeof angle_table[0];i++)if(shaft<=angle_table[i]*1000.f)
        return pulse_table[i-1]+(unsigned)((shaft-angle_table[i-1]*1000.f)*
            (pulse_table[i]-pulse_table[i-1])/((angle_table[i]-angle_table[i-1])*1000.f)+.5f);
    return pulse_table[20];
}
static float bound(float value,float lower,float upper) {
    return value<lower?lower:value>upper?upper:value;
}
static float visual_rate(float error,unsigned *moving,float enter,float leave,float kp,float maximum) {
    if(*moving) {if(fabsf(error)<=enter)*moving=0;}
    else if(fabsf(error)>leave)*moving=1;
    return *moving?bound(kp*error,-maximum,maximum):0.f;
}
/* Validate every value before replacing any value. Configuration bounds
 * are not claims of verified mechanical speed. IEEE values are copied by bits,
 * never through an unaligned wire pointer. */
static uint32_t tuning_be32(const uint8_t *p) {
    return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];
}
int servo_tracking_tuning_command(uint32_t boot_id,const uint8_t *p,unsigned bytes) {
    if(!p || bytes!=46u)return -1;
    uint32_t request=tuning_be32(p+10),status=0;
    tuning_ack_request=request;
    if(p[0]!=23u || p[1]!=1u){tuning_ack_status=2u;return -1;}
    if(!boot_id || tuning_be32(p+2)!=boot_id){tuning_ack_status=3u;return -1;}
    if(!request){tuning_ack_status=5u;return -1;}
    for(unsigned i=0;i<16;i++)if(tuning_cache[i].valid && tuning_cache[i].id==request) {
        status=memcmp(tuning_cache[i].request,p,46u)?6u:tuning_cache[i].status;
        if(status==1u)status=7u;
        tuning_ack_status=status;return status==7u?0:-1;
    }
    float values[8];
    for(unsigned i=0;i<8;i++) {
        uint32_t bits=tuning_be32(p+14+4*i);memcpy(values+i,&bits,4);
        if(!isfinite(values[i]))status=5u;
    }
    for(unsigned i=0;i<2;i++)if(values[i]<1.f || values[i]>240.f)status=5u;
    for(unsigned i=2;i<4;i++)if(values[i]<1.f || values[i]>60.f)status=5u;
    for(unsigned i=4;i<8;i+=2)
        if(values[i]<.005f || values[i]>.15f || values[i+1]<.01f ||
           values[i+1]>.20f || values[i]>=values[i+1])status=5u;
    if(!supported)status=8u;
    if(tuning_be32(p+6)!=tuning_revision || tuning_revision==UINT32_MAX)status=4u;
    if(!status) {
        memcpy(tuning_values,values,sizeof tuning_values);tuning_revision++;tuning_applies++;
        /* Drop old sub-PWM fractions and hysteresis, retaining accepted PWM
         * estimates, frame freshness, elapsed-time clock and control owner.
         * This function writes no registers and never renews the lease. */
        if(continuous.active) {
            continuous.pan_mdeg=(float)pose();continuous.tilt_mdeg=shaft_for_pulse(tilt_us);
            continuous.pan_moving=continuous.tilt_moving=0;
        }
        status=1u;
    }
    unsigned index=tuning_cache_next++&15u;
    memcpy(tuning_cache[index].request,p,46u);tuning_cache[index].id=request;
    tuning_cache[index].status=status;tuning_cache[index].valid=1u;
    tuning_ack_status=status;return status==1u?0:-1;
}
void servo_tracking_tuning_status(uint32_t words[16],uint32_t boot_id) {
    memset(words,0,16*sizeof *words);
    words[0]=0x53525639u;words[1]=1u;words[2]=tuning_revision;
    words[3]=tuning_ack_request;words[4]=tuning_ack_status;words[5]=boot_id;
    for(unsigned i=0;i<8;i++)memcpy(words+6+i,tuning_values+i,4);
    words[14]=tuning_applies;
}
int servo_tracking_feedforward_command(uint32_t boot_id,const uint8_t *p,unsigned bytes) {
    if(!p || bytes!=46u)return -1;
    uint32_t request=tuning_be32(p+10),status=0;
    ff_ack_request=request;
    if(p[0]!=27u || p[1]!=1u){ff_ack_status=2u;return -1;}
    if(!boot_id || tuning_be32(p+2)!=boot_id){ff_ack_status=3u;return -1;}
    if(!request){ff_ack_status=5u;return -1;}
    for(unsigned i=0;i<16;i++)if(ff_cache[i].valid && ff_cache[i].id==request) {
        status=memcmp(ff_cache[i].request,p,46u)?6u:ff_cache[i].status;
        if(status==1u)status=7u;
        ff_ack_status=status;return status==7u?0:-1;
    }
    float values[8];
    static const float lower[8]={0.f,0.f,0.f,0.f,0.f,0.f,20.f,0.f};
    static const float upper[8]={360.f,180.f,1.f,1.f,60.f,60.f,1000.f,10.f};
    for(unsigned i=0;i<8;i++) {
        uint32_t bits=tuning_be32(p+14u+4u*i);memcpy(values+i,&bits,4);
        if(!isfinite(values[i]) || values[i]<lower[i] || values[i]>upper[i])status=5u;
    }
    if(!supported)status=8u;
    if(tuning_be32(p+6)!=ff_revision || ff_revision==UINT32_MAX)status=4u;
    if(!status) {
        memcpy(ff_values,values,sizeof ff_values);ff_revision++;ff_applies++;
        visual_ff_reset(&feedforward,7u);
        memset(ff_p,0,sizeof ff_p);memset(ff_total,0,sizeof ff_total);
        /* No actuation, position/clock reset, ownership change or lease renewal.
         * The new observer waits for capture-time history and fresh pairs. */
        status=1u;
    }
    unsigned index=ff_cache_next++&15u;
    memcpy(ff_cache[index].request,p,46u);ff_cache[index].id=request;
    ff_cache[index].status=status;ff_cache[index].valid=1u;
    ff_ack_status=status;return status==1u?0:-1;
}
void servo_tracking_feedforward_status(uint32_t words[32],uint32_t boot_id,uint64_t now) {
    memset(words,0,32*sizeof *words);
    words[0]=0x56464631u;words[1]=1u;words[2]=ff_revision;
    words[3]=ff_ack_request;words[4]=ff_ack_status;words[5]=boot_id;
    for(unsigned i=0;i<8;i++)memcpy(words+6+i,ff_values+i,4);
    words[14]=ff_applies;
    unsigned fresh=continuous.active && feedforward.baseline && now>=feedforward.captured &&
        now-feedforward.captured<250000u;
    for(unsigned a=0;a<2;a++) {
        if(visual_ff_configured(ff_values,a))words[15]|=1u<<a;
        if(fresh && feedforward.axis[a].count>=2u)words[15]|=4u<<a;
        float velocity=fresh?feedforward.axis[a].velocity:0.f;
        float error=a?continuous.y:continuous.x;
        float value=continuous.active?visual_ff_contribution(&feedforward,ff_values,a,now,
            error,tuning_values[a?7:5]):0.f;
        if(value!=0.f)words[15]|=16u<<a;
        memcpy(words+16+a,&velocity,4);memcpy(words+18+a,&value,4);
        words[21+a]=feedforward.axis[a].count;
        memcpy(words+24+a,ff_p+a,4);memcpy(words+26+a,ff_total+a,4);
    }
    if(continuous.active)words[15]|=64u;
    uint64_t age=feedforward.captured && now>=feedforward.captured?
        (now-feedforward.captured)/1000u:UINT64_MAX;
    words[20]=age>UINT32_MAX?UINT32_MAX:(uint32_t)age;
    words[23]=feedforward.reason;words[28]=feedforward.sequence;
}
static void continuous_poll(void) {
    if(clock_now<continuous.updated){continuous_reset();feedforward.reason=2u;return;}
    uint64_t elapsed=clock_now-continuous.updated;
    if(elapsed<VISUAL_SERVO_PERIOD_US)return;
    /* Drop elapsed busy time rather than accumulating an eventual catch-up. */
    continuous.updated=clock_now;
    visual_ff_history(&feedforward,clock_now,(float)pose()*.001f,shaft_for_pulse(tilt_us)*.001f);
    unsigned status=read_reg(AV_REG_SERVO_STATUS)&7u;
    if(status&5u){reason=COOLDOWN;return;}
    if(elapsed>VISUAL_SERVO_MAX_DT_US)elapsed=VISUAL_SERVO_MAX_DT_US;
    float dt=(float)elapsed*.000001f;
    float vx=visual_rate(continuous.x,&continuous.pan_moving,tuning_values[4],
        tuning_values[5],tuning_values[0],tuning_values[2]);
    float vy=visual_rate(continuous.y,&continuous.tilt_moving,tuning_values[6],
        tuning_values[7],tuning_values[1],tuning_values[3]);
    float fx=visual_ff_contribution(&feedforward,ff_values,0,clock_now,continuous.x,tuning_values[5]);
    float fy=visual_ff_contribution(&feedforward,ff_values,1,clock_now,continuous.y,tuning_values[7]);
    ff_p[0]=vx;ff_p[1]=vy;
    /* Configured axes add FF before the original total cap. In particular an
     * opposing FF cannot reduce an already saturated, large P error wrongly.
     * An unconfigured axis follows the M46 arithmetic exactly. */
    if(visual_ff_configured(ff_values,0)) {
        ff_p[0]=continuous.pan_moving?tuning_values[0]*continuous.x:0.f;
        vx=bound(ff_p[0]+fx,-tuning_values[2],tuning_values[2]);
    }
    if(visual_ff_configured(ff_values,1)) {
        ff_p[1]=continuous.tilt_moving?tuning_values[1]*continuous.y:0.f;
        vy=bound(ff_p[1]+fy,-tuning_values[3],tuning_values[3]);
    }
    ff_total[0]=vx;ff_total[1]=vy;
    if(!continuous.pan_moving && fx==0.f)continuous.pan_mdeg=(float)pose();
    if(!continuous.tilt_moving && fy==0.f)continuous.tilt_mdeg=shaft_for_pulse(tilt_us);
    float pan=bound(continuous.pan_mdeg+vx*dt*1000.f,-180000.f,180000.f);
    /* Pan has one hardware pending slot. A busy pan must not block the
     * independently accepted tilt command, or accrue deferred pan motion. */
    if(status&2u)pan=continuous.pan_mdeg;
    float tilt_min=shaft_for_pulse(VISUAL_SERVO_TILT_MIN_US);
    float tilt_max=shaft_for_pulse(VISUAL_SERVO_TILT_MAX_US);
    /* A retained boot/manual tilt above the visual limit may move inward at
     * the configured rate; taking ownership must not snap it to the limit. */
    if(continuous.tilt_mdeg>tilt_max)tilt_max=continuous.tilt_mdeg;
    if(continuous.tilt_mdeg<tilt_min)tilt_min=continuous.tilt_mdeg;
    float angle=bound(continuous.tilt_mdeg+vy*dt*1000.f,tilt_min,tilt_max);
    unsigned target_pan=(status&2u)?pan_us:pulse_for_pose((int32_t)(pan+(pan>=0.f?.5f:-.5f)));
    unsigned target_tilt=pulse_for_shaft(angle);
    unsigned command=(target_pan!=pan_us?1u:0u)|(target_tilt!=tilt_us?4u:0u);
    if(!command) {
        /* Retain sub-microsecond fractions, not a hidden velocity estimate. */
        continuous.pan_mdeg=pan;continuous.tilt_mdeg=angle;
        reason=continuous.pan_moving || continuous.tilt_moving || fx!=0.f || fy!=0.f?LIMIT:CENTERED;return;
    }
    uint32_t before=read_reg(AV_REG_SERVO_COUNT);
    if(command&1u)write_reg(AV_REG_SERVO_PAN,ticks(target_pan));
    if(command&4u)write_reg(AV_REG_SERVO_TILT,ticks(target_tilt));
    write_reg(AV_REG_SERVO_COMMAND,command);
    unsigned moved=0;
    if(!(command&1u) || read_reg(AV_REG_SERVO_COUNT)==before+1u) {
        continuous.pan_mdeg=pan;
        if(command&1u){pan_us=target_pan;last_command=before+1u;moved=1;}
    }
    /* RTL accepts every valid tilt command and has no tilt counter/encoder.
     * Register readback fences the AXI write; this is an accepted command
     * estimate. The PWM changes at the following 50-Hz frame boundary. */
    if(!(command&4u) || read_reg(AV_REG_SERVO_TILT)==ticks(target_tilt)) {
        continuous.tilt_mdeg=angle;
        if(command&4u){tilt_us=target_tilt;moved=1;}
    }
    if(moved) {
        visual_ff_history(&feedforward,clock_now,(float)pose()*.001f,shaft_for_pulse(tilt_us)*.001f);
        not_before=clock_now+VISUAL_SERVO_PERIOD_US;
        /* Used only on subsequent sparse SSD/home/audio handoff, never as
         * a freshness barrier for the continuous NCC path itself. */
        settled_after=clock_now+SERVO_FRAME_US+SERVO_PAN_SETTLE_US;
        sound_pan_stable_after=settled_after;reason=MOVING;
    } else reason=COOLDOWN;
}
void servo_tracking_track(float score,const float box[4],uint32_t sequence,uint64_t captured,uint64_t now) {
    unsigned time_invalid=continuous.active && now<continuous.clock;
    if(time_invalid || now<continuous_time_floor || !captured || captured>now ||
       (last_capture && captured<last_capture))formal_direction_time_guard(now);
    servo_tracking_tick(now);
    if(time_invalid || now<continuous_time_floor)return;
    if(!box || !isfinite(score) || score<=VISUAL_BIRD_MIN_SCORE || score>1.f ||
       !captured || captured>now || now-captured>VISUAL_SERVO_POSITION_MAX_AGE_US) {
        visual_location_lost();return;
    }
    for(unsigned i=0;i<4;i++)if(!isfinite(box[i])){visual_location_lost();return;}
    if(box[0]<0 || box[1]<0 || box[2]>AV_VIDEO_WIDTH || box[3]>AV_VIDEO_HEIGHT ||
       box[2]-box[0]<8 || box[3]-box[1]<8){visual_location_lost();return;}
    /* Upstream has already independently confirmed SSD identity. Reusing
     * one NCC result holds its error briefly, but never confirms it again or
     * renews its source timestamp. Reject older/duplicate source frames. */
    if(captured<last_capture){visual_location_lost();return;}
    if(captured==last_capture || (automatic && sequence==last_observation))return;
    if(recovery_scanning && captured<recovery_started)return;
    last_capture=captured;last_observation=sequence;
    detection_captured=captured;detection[1]=sequence;detection[3]=1;ncc_detection=1;
    detection[4]=visual_detection_score_q6(score);
    for(unsigned i=0;i<4;i++)detection[5+i]=(uint32_t)(box[i]*1000.f+.5f);
    detection[9]=last_command;
    if(!automatic)return;
    formal_acquire_until=0; /* Fresh formal NCC has completed the handover. */
    recovery_reset();boundary_latched=0;
    candidate_hold_reset(); /* Formal vision supersedes the old display-only hold. */
    formal_direction_record(box,captured,now);
    if(!continuous.active) {
        continuous_reset();continuous.active=1;
        continuous.pan_mdeg=(float)pose();continuous.tilt_mdeg=shaft_for_pulse(tilt_us);
        continuous.updated=now>=VISUAL_SERVO_PERIOD_US?now-VISUAL_SERVO_PERIOD_US:0;
        visual_ff_history(&feedforward,now,(float)pose()*.001f,shaft_for_pulse(tilt_us)*.001f);
    }
    visual_ff_observe(&feedforward,ff_values,
        (box[0]+box[2])/(2.f*AV_VIDEO_WIDTH)-.5f,
        (box[1]+box[3])/(2.f*AV_VIDEO_HEIGHT)-.5f,
        (box[2]-box[0])/AV_VIDEO_WIDTH,(box[3]-box[1])/AV_VIDEO_HEIGHT,sequence,captured);
    continuous.sequence=sequence;continuous.captured=captured;continuous.clock=now;
    continuous.x=(box[0]+box[2])/(2.f*AV_VIDEO_WIDTH)-.5f;
    continuous.y=(box[1]+box[3])/(2.f*AV_VIDEO_HEIGHT)-.5f;
    homing=sound_plan_active=0;had_visual=1;sound_cutoff=now;
    if(sound_automatic)sound_state=SOUND_VISUAL;
    /* No register write here: network stop/miss processing precedes poll. */
}
static int move_pan(unsigned target,unsigned interval) {
    if(!supported || target<SERVO_PAN_MIN_US || target>SERVO_PAN_MAX_US)return -1;
    if(clock_now<not_before || (read_reg(AV_REG_SERVO_STATUS)&7u)){reason=COOLDOWN;return -1;}
    if(target==pan_us){reason=LIMIT;return -1;}
    uint32_t before=read_reg(AV_REG_SERVO_COUNT);
    write_reg(AV_REG_SERVO_PAN,ticks(target));write_reg(AV_REG_SERVO_COMMAND,1);
    if(read_reg(AV_REG_SERVO_COUNT)!=before+1u){reason=COOLDOWN;return -1;}
    scan_reset();
    pan_us=target;last_command=before+1u;
    not_before=clock_now+interval;
    settled_after=clock_now+SERVO_FRAME_US+SERVO_PAN_SETTLE_US;
    sound_pan_stable_after=settled_after;
    reason=MOVING;return 0;
}
static int pan_step(unsigned direction,unsigned step,unsigned interval) {
    unsigned target=direction==1?(pan_us<SERVO_PAN_MIN_US+step?SERVO_PAN_MIN_US:pan_us-step):
        (pan_us+step>SERVO_PAN_MAX_US?SERVO_PAN_MAX_US:pan_us+step);
    return move_pan(target,interval);
}
static void start_home(void) {
    formal_direction_forget();
    continuous_reset();
    recovery_reset();
    candidate_hold_reset();
    sound_seek_confirm_clear(&sound_confirmation);
    had_visual=0;homing=1;sound_plan_active=0;last_sound=last_qualified_sound=0;
    sound_cutoff=clock_now;home_next=clock_now;
}
static void recovery_start(void) {
    if(!automatic || recovery_scanning || homing)return;
    unsigned visual_loss=had_visual;
    continuous_reset();
    scan_reset();
    recovery_scanning=1;recovery_started=recovery_clock=clock_now;
    recovery_deadline=UINT64_MAX-clock_now<VISUAL_RECOVERY_SCAN_US?
        UINT64_MAX:clock_now+VISUAL_RECOVERY_SCAN_US;
    recovery_visual_hold_until=visual_loss?
        (UINT64_MAX-clock_now<VISUAL_RECOVERY_LOSS_HOLD_US?
         UINT64_MAX:clock_now+VISUAL_RECOVERY_LOSS_HOLD_US):0;
    boundary_latched=pan_us==SERVO_PAN_MIN_US || pan_us==SERVO_PAN_MAX_US;
    hits=0;had_visual=0;sound_plan_active=0;external_visual=0;detection[3]=0;ncc_detection=0;
    last_sound=last_qualified_sound=0;sound_cutoff=clock_now;
    sound_seek_confirm_clear(&sound_confirmation);
    /* A bounded, one-use formal hint may remove only the inherited
     * visual move cooldown. PL busy/acceptance and future scan cadence
     * remain authoritative. Unknown/centered/old/time-invalid hints keep
     * the original default direction and stationary retry behavior. */
    recovery_directional=last_formal_vertical_direction && formal_direction_capture &&
        clock_now>=formal_direction_capture && clock_now>=formal_direction_observed &&
        clock_now-formal_direction_observed<=SERVO_VISUAL_FRESH_US &&
        clock_now>=continuous_time_floor && clock_now<auto_expires;
    scan_direction=recovery_directional?last_formal_vertical_direction:-1;
    formal_direction_forget();
    if(recovery_directional) {not_before=clock_now;settled_after=clock_now;}
    reason=NO_DETECTION;sound_state=SOUND_SCANNING;
}
static void scan_poll(void) {
    /* The first scan command still respects inherited pan/visual settling.
     * Subsequent tiny steps use their own cadence; reapplying the generic
     * 320-ms settle after every step would defeat the smooth progression. */
    if(!supported || clock_now<not_before || (!scan_active && clock_now<settled_after) ||
       (read_reg(AV_REG_SERVO_STATUS)&7u))return;
    if(scan_active && (clock_now<scan_last_accepted ||
       clock_now-scan_last_accepted<scan_interval_us))return;
    if(tilt_us<=SERVO_SOUND_TILT_MIN_US)scan_direction=1;
    else if(tilt_us>=SERVO_SOUND_TILT_MAX_US)scan_direction=-1;
    unsigned target=scan_direction>0?
        (tilt_us+scan_step_us>SERVO_SOUND_TILT_MAX_US?SERVO_SOUND_TILT_MAX_US:tilt_us+scan_step_us):
        (tilt_us<SERVO_SOUND_TILT_MIN_US+scan_step_us?SERVO_SOUND_TILT_MIN_US:tilt_us-scan_step_us);
    if(target==tilt_us)return;
    uint32_t target_ticks=ticks(target);
    write_reg(AV_REG_SERVO_TILT,target_ticks);write_reg(AV_REG_SERVO_COMMAND,4u);
    /* Tilt has no command counter/encoder. Readback fences the accepted
     * register write, matching continuous NCC's existing tilt contract. */
    if(read_reg(AV_REG_SERVO_TILT)!=target_ticks){reason=COOLDOWN;return;}
    tilt_us=target;scan_active=1;scan_last_accepted=clock_now;
    not_before=clock_now+scan_interval_us;
    /* Preserve the sparse SSD post-motion barrier. Formal fresh NCC may
     * take ownership immediately through its independent path. */
    settled_after=clock_now+SERVO_FRAME_US+SERVO_PAN_SETTLE_US;
    hits=0;reason=MOVING;
}
static void recovery_poll(void) {
    if(!recovery_scanning)return;
    /* A backwards clock must never shorten a search or dispatch a command.
     * The continuous path's existing quarantine also covers this state. */
    if(clock_now<recovery_started)return;
    if(clock_now>=recovery_deadline){start_home();return;}
    reason=NO_DETECTION;sound_state=SOUND_SCANNING;
    /* This independent gate pauses only the loss scan. Fresh formal visual
     * or qualified sound handover keeps its existing ownership/timing rules.
     * Repeated misses cannot move the original recovery/hold deadlines. */
    if(clock_now<recovery_visual_hold_until){reason=WAIT_STABLE;return;}
    if(servo_tracking_reacquire_active(clock_now)) {
        sound_state=SOUND_CANDIDATE_HOLD;reason=WAIT_STABLE;return;
    }
    if(formal_acquire_hold(clock_now) || candidate_hold_active(clock_now) || clock_now<recovery_sparse_until) {
        sound_state=SOUND_CANDIDATE_HOLD;reason=WAIT_STABLE;return;
    }
    scan_poll();
}
static void home_poll(void) {
    if(!homing)return;
    reason=HOMING;sound_state=sound_automatic?SOUND_HOMING:SOUND_OFF;
    if(pan_us==SERVO_PAN_CENTER_US) {
        homing=0;sound_cutoff=clock_now;
        if(settled_after<clock_now+SERVO_PAN_SETTLE_US)settled_after=clock_now+SERVO_PAN_SETTLE_US;
        reason=sound_automatic?WAIT_SOUND:NO_DETECTION;
        sound_state=sound_automatic?SOUND_POST_MOTION:SOUND_OFF;return;
    }
    if(clock_now<home_next)return;
    unsigned step=SERVO_PAN_HOME_STEP_US,target;
    if(pan_us<SERVO_PAN_CENTER_US)target=pan_us+step>SERVO_PAN_CENTER_US?SERVO_PAN_CENTER_US:pan_us+step;
    else target=pan_us<SERVO_PAN_CENTER_US+step?SERVO_PAN_CENTER_US:pan_us-step;
    if(!move_pan(target,SERVO_PAN_HOME_INTERVAL_US)) {
        home_next=clock_now+SERVO_PAN_HOME_INTERVAL_US;reason=HOMING;
        if(target==SERVO_PAN_CENTER_US) {
            homing=0;sound_cutoff=clock_now;reason=sound_automatic?WAIT_SOUND:NO_DETECTION;
            sound_state=sound_automatic?SOUND_POST_MOTION:SOUND_OFF;
        }
    }
}
void servo_tracking_init(uint64_t now) {
    formal_acquire_until=formal_acquire_capture=formal_acquire_clock=0;
    formal_direction_forget();
    continuous_reset();tuning_reset();ff_configuration_reset();audio_reset();sound_accept_sequence=0;
    feedforward.reason=1u;
    (void)servo_tracking_configure_scan_rate(4.f);
    recovery_reset();boundary_latched=0;last_qualified_sound=0;
    ncc_detection=0;continuous_time_floor=0;
    candidate_hold_reset();
    sound_seek_confirm_clear(&sound_confirmation);
    clock_now=not_before=now;settled_after=now+SERVO_PAN_SETTLE_US;
    auto_expires=home_next=0;detection_captured=last_capture=sound_cutoff=last_sound=external_visual_time=0;
    sound_phase=SEEK_TURN;sound_target_us=SERVO_PAN_CENTER_US;scan_direction=-1;
    sound_pan_stable_after=settled_after;sound_command_yaw=0;
    external_visual=0;
    automatic=sound_automatic=hits=had_visual=homing=sound_plan_active=0;
    reason=MANUAL;sound_state=SOUND_OFF;visual_last_band=0;
    pan_us=SERVO_PAN_CENTER_US;tilt_us=SERVO_INITIAL_TILT_US;
    last_observation=last_command=sound_steps=0;sound_angle_mdeg=sound_target_pan=0;
    memset(detection,0,sizeof detection);
    supported=read_reg(AV_REG_VERSION)==AV_REG_VERSION_VALUE && read_reg(AV_REG_SERVO_ID)==0x53525631u;
    hz=supported?read_reg(AV_REG_SERVO_CLOCK):0;
    if(hz<90000000u || hz>110000000u)supported=0;
    /* Retain an explicit validated tilt seed for protocol compatibility; M38's
     * downloader supplies 1140 us (60 shaft degrees). Otherwise use that same
     * default. Discard old horizontal budgets/pose and center pan at 1440 us. */
    if(supported) {
        uint32_t seed[8],check=0xa5a55a5au;
        for(unsigned i=0;i<8;i++)seed[i]=platform_mmio_read(BOOT_STATE+4u*i);
        if(seed[0]==0x53525032u) {
            for(unsigned i=0;i<7;i++)check^=seed[i];
            int32_t position=(int32_t)seed[3];
            if(check==seed[7] && seed[1]<=170000u && seed[2]<=170000u &&
               seed[4]>=540u && seed[4]<=2281u && seed[5]<=7u && seed[6]==0 &&
               (!(seed[5]&1u) || (position>=-170000 && position<=170000)))tilt_us=seed[4];
        } else if(seed[0]==0x53525332u || seed[0]==0x53525031u) {
            for(unsigned i=0;i<5;i++)check^=seed[i];
            if(check==seed[5] && seed[1]<=170000u && seed[2]<=170000u &&
               seed[4]>=540u && seed[4]<=2281u &&
               (int32_t)seed[3]>=-170000 && (int32_t)seed[3]<=170000)tilt_us=seed[4];
        }
    }
    platform_mmio_write(BOOT_STATE,0);
    if(supported) {
        write_reg(AV_REG_SERVO_PAN,ticks(pan_us));write_reg(AV_REG_SERVO_TILT,ticks(tilt_us));
        write_reg(AV_REG_SERVO_COMMAND,5);last_command=read_reg(AV_REG_SERVO_COUNT);
    }
}
int servo_tracking_visual_present(uint64_t now) {
    return !recovery_scanning && detection[3] && detection_captured && now>=detection_captured &&
        now-detection_captured<=(ncc_detection?VISUAL_SERVO_POSITION_MAX_AGE_US:SERVO_VISUAL_FRESH_US);
}
void servo_tracking_visual_priority(unsigned present,uint64_t now) {
    clock_now=now;external_visual=present!=0;external_visual_time=now;
    if(present && !recovery_scanning && automatic && now<auto_expires) {
        sound_seek_confirm_clear(&sound_confirmation);
        homing=sound_plan_active=0;had_visual=1;sound_cutoff=now;
        if(sound_automatic)sound_state=SOUND_VISUAL;
    }
}
void servo_tracking_tick(uint64_t now) {
    if(recovery_scanning && now<recovery_clock && continuous_time_floor<recovery_clock)
        continuous_time_floor=recovery_clock;
    if(recovery_scanning && now>=recovery_clock)recovery_clock=now;
    if(continuous.active && now<continuous.clock) {
        continuous_time_floor=continuous.clock;continuous_reset();feedforward.reason=2u;
    }
    if(continuous.active && (now<continuous.captured ||
       now-continuous.captured>VISUAL_SERVO_POSITION_MAX_AGE_US)) {
        clock_now=now;visual_location_lost();feedforward.reason=3u;
    }
    if(continuous.active)continuous.clock=now;
    clock_now=now;
    if(automatic && now>=auto_expires) {
        servo_tracking_stop();reason=LEASE_EXPIRED;sound_state=SOUND_LEASE_EXPIRED;return;
    }
}
void servo_tracking_poll(uint64_t now) {
    servo_tracking_tick(now);
    if(!automatic)return;
    if(now<continuous_time_floor)return;
    continuous_time_floor=0;
    if(continuous.active)continuous_poll();
    unsigned visible=!recovery_scanning && (servo_tracking_visual_present(now) ||
        (external_visual && now>=external_visual_time && now-external_visual_time<=SERVO_VISUAL_FRESH_US));
    if(had_visual && !visible)recovery_start();
    unsigned boundary=pan_us==SERVO_PAN_MIN_US || pan_us==SERVO_PAN_MAX_US;
    if(!boundary)boundary_latched=0;
    unsigned qualified_sound=sound_plan_active && last_qualified_sound && now>=last_qualified_sound &&
        now-last_qualified_sound<=VISUAL_RECOVERY_SOUND_MAX_AGE_US;
    if(boundary && !boundary_latched && !homing && !visible && !qualified_sound)recovery_start();
    recovery_poll();
    home_poll();
    if(sound_automatic && !homing && !recovery_scanning && !visible)sound_advance();
}
void servo_tracking_stop(void) {
    formal_acquire_until=formal_acquire_capture=formal_acquire_clock=0;
    formal_direction_forget();
    continuous_reset();
    recovery_reset();boundary_latched=0;last_qualified_sound=0;
    /* Clock rollback quarantine survives control ownership changes. Only
     * initialization or recovery to the previous clock releases the floor. */
    candidate_hold_reset();
    sound_seek_confirm_clear(&sound_confirmation);
    automatic=sound_automatic=hits=had_visual=homing=sound_plan_active=0;
    external_visual=0;
    reason=MANUAL;sound_state=SOUND_OFF;
    /* Keep the last accepted positional setpoint. Never write a neutral/center pulse here. */
}
void servo_tracking_clear_detection(void) {
    continuous_reset();
    ncc_detection=0;
    hits=last_observation=0;memset(detection,0,sizeof detection);detection_captured=0;
    if(automatic && had_visual)recovery_start();
    reason=automatic?NO_DETECTION:MANUAL;
}
int servo_tracking_pan(unsigned direction) {
    if(direction>2)return -1;
    servo_tracking_stop();
    if(!direction)return supported?0:-1;
    return pan_step(direction,SERVO_PAN_STEP_US,SERVO_PAN_MOVE_INTERVAL_US);
}
/* Old continuous-servo tuning packets are no longer meaningful. */
int servo_tracking_configure(unsigned l,unsigned r,unsigned lm,unsigned rm) {
    (void)l;(void)r;(void)lm;(void)rm;return -1;
}
int servo_tracking_configure_visual(unsigned l,unsigned r,unsigned lm,unsigned rm,
    unsigned enabled,unsigned threshold,unsigned ln,unsigned rn) {
    (void)l;(void)r;(void)lm;(void)rm;(void)enabled;(void)threshold;(void)ln;(void)rn;return -1;
}
void servo_tracking_config_status(uint32_t words[16]) {
    memset(words,0,16*sizeof *words);words[0]=0x53525636u;
    words[13]=words[14]=supported; /* Mode-2 preflight: calibration/reference exists. */
}
void servo_tracking_visual_config_status(uint32_t words[16]){memset(words,0,16*sizeof *words);words[0]=0x53525637u;}
int servo_tracking_pan_limit(unsigned enabled){(void)enabled;return -1;} /* Physical pulse bounds always apply. */
static int tilt(unsigned pulse,unsigned maximum_step,unsigned interval) {
    if(!supported || pulse<540 || pulse>2281)return -1;
    if(clock_now<not_before || (read_reg(AV_REG_SERVO_STATUS)&7u)){reason=COOLDOWN;return -1;}
    if(pulse>tilt_us+maximum_step || pulse+maximum_step<tilt_us)return -1;
    scan_reset();
    write_reg(AV_REG_SERVO_TILT,ticks(pulse));write_reg(AV_REG_SERVO_COMMAND,4);tilt_us=pulse;
    not_before=clock_now+interval;settled_after=clock_now+SERVO_FRAME_US+SERVO_PAN_SETTLE_US;
    hits=0;reason=MOVING;return 0;
}
int servo_tracking_tilt(unsigned pulse){servo_tracking_stop();return tilt(pulse,20u,660000u);}
static int auto_tilt(float error) {
    unsigned step=fabsf(error)>=.20f?60u:fabsf(error)>=.10f?40u:20u;
    unsigned pulse=error>0?tilt_us+step:tilt_us-step;
    if(pulse>2181)pulse=2181;
    if(pulse<540)pulse=540;
    int rc=tilt(pulse,60u,400000u);
    if(!rc)hits=1; /* M29 retains confirmation, requires a NEW post-motion frame. */
    return rc;
}
int servo_tracking_auto(unsigned enabled) {
    if(!supported || enabled>2)return -1;
    servo_tracking_stop();automatic=enabled!=0;sound_automatic=enabled==2;
    sound_state=sound_automatic?SOUND_WAIT:SOUND_OFF;sound_cutoff=clock_now;last_sound=0;
    auto_expires=clock_now+2000000u;
    if(enabled)reason=WAIT_STABLE;
    /* Enabling away from center without a visual target also returns home first. */
    if(enabled && pan_us!=SERVO_PAN_CENTER_US) {
        if(pan_us==SERVO_PAN_MIN_US || pan_us==SERVO_PAN_MAX_US)recovery_start();
        else {homing=1;home_next=clock_now;}
    }
    return 0;
}
int servo_tracking_keepalive(void) {
    if(!supported || !automatic || clock_now>=auto_expires)return -1;
    auto_expires=clock_now+2000000u;return 0;
}
int servo_tracking_sound_search_active(void) {
    return automatic && sound_automatic && sound_plan_active && clock_now<auto_expires;
}
static void sound_advance(void) {
    if(!sound_plan_active)return;
    if(sound_phase==SEEK_TURN) {
        if(clock_now<not_before || (read_reg(AV_REG_SERVO_STATUS)&7u)) {
            sound_state=SOUND_MOVING;return;
        }
        if(sound_target_us!=pan_us) {
            int32_t delta=sound_target_pan-sound_command_yaw;
            /* Keep integer millidegree steps: default 83.3 * 20 = 1666,
             * exactly the original M42 command progression. */
            int32_t step=(int32_t)(audio_values[SOUND_TUNE_SPEED]*
                ((float)SERVO_SOUND_TURN_INTERVAL_US/1000.f));
            int32_t next=delta>step?sound_command_yaw+step:
                delta< -step?sound_command_yaw-step:sound_target_pan;
            /* Advance one bounded angular step per PWM period. This also
             * prevents a delayed service call from producing a large jump. */
            if(move_pan(pulse_for_pose(next),SERVO_SOUND_TURN_INTERVAL_US)) {
                sound_state=reason==LIMIT?SOUND_LIMIT:SOUND_COOLDOWN;return;
            }
            sound_command_yaw=next;sound_steps++;sound_state=SOUND_MOVING;
            if(pan_us!=sound_target_us)return;
        } else {
            uint64_t wait=clock_now+SERVO_FRAME_US+SERVO_PAN_SETTLE_US;
            if(sound_pan_stable_after<wait)sound_pan_stable_after=wait;
        }
        if(settled_after<sound_pan_stable_after)settled_after=sound_pan_stable_after;
        if(not_before<settled_after)not_before=settled_after;
        sound_phase=SEEK_SETTLE;sound_state=SOUND_MOVING;return;
    }
    if(sound_phase==SEEK_SETTLE) {
        if(clock_now<settled_after || (read_reg(AV_REG_SERVO_STATUS)&7u))return;
        sound_phase=SEEK_SCAN;scan_direction=-1;
    }
    /* One bounded camera-still interval per candidate appearance. */
    if(formal_acquire_hold(clock_now) || candidate_hold_active(clock_now)) {
        sound_state=SOUND_CANDIDATE_HOLD;reason=WAIT_STABLE;return;
    }
    sound_state=SOUND_SCANNING;
    /* Start toward 0 degrees, then reverse at the calibrated endpoints. */
    scan_poll();
}
void servo_tracking_sound_observe(int valid,int16_t angle_q9_7,uint16_t quality,
    uint64_t captured,unsigned visual_present,uint64_t now) {
    servo_tracking_visual_priority(visual_present,now);
    servo_tracking_poll(now);
    /* poll may quarantine a backwards timestamp without dispatching work.
     * Incoming DOA evidence must obey that same floor: it cannot accumulate
     * confirmation, replace recovery ownership or restart its deadline. */
    if(now<continuous_time_floor)return;
    if(!automatic || !sound_automatic)return;
    if((visual_present && !recovery_scanning) || servo_tracking_visual_present(now)) {
        homing=sound_plan_active=0;had_visual=1;sound_cutoff=now;
        sound_state=SOUND_VISUAL;return;
    }
    if(homing){sound_seek_confirm_clear(&sound_confirmation);sound_state=SOUND_HOMING;return;}
    if(!valid || quality<=512u || quality>32767u || !captured || captured>now ||
       now-captured>SOUND_FRESH_US || angle_q9_7<-23040 || angle_q9_7>23040) {
        sound_seek_confirm_expire(&sound_confirmation,now);
        if(!sound_plan_active)sound_state=SOUND_WAIT;
        return;
    }
    /* The microphone array is fixed to the base. Use fresh post-pan-settle
     * observations so servo movement noise cannot start another target.
     * Vertical scan steps must not starve the horizontal direction updates. */
    if(captured<=last_sound || captured<=sound_cutoff || captured<sound_pan_stable_after) {
        sound_seek_confirm_expire(&sound_confirmation,now);
        if(!sound_plan_active)sound_state=SOUND_POST_MOTION;
        return;
    }
    int32_t angle=(int32_t)angle_q9_7*1000/128;
    last_sound=captured;
    /* Array front and the 1440-us camera center share the base zero.
     * A base-fixed bearing is already an absolute pan target. */
    int32_t raw_target=angle,target=raw_target;
    target=target<-180000?-180000:target>180000?180000:target;
    int32_t change=sound_seek_delta(target,sound_target_pan);
    /* Small bearing changes do not restart a sweep. Larger changes require
     * fresh spatially consistent observations before replacing its target. */
    if(sound_plan_active && change>=-(int32_t)(audio_values[SOUND_TUNE_DEADBAND]*1000.f) &&
       change<=(int32_t)(audio_values[SOUND_TUNE_DEADBAND]*1000.f)) {
        /* Reconfirm the same direction for the next timed listening round,
         * using the configured re-aim consensus without restarting a turn or
         * scan. Endpoint grace still requires this qualified confirmation. */
        int32_t renewed;
        if(audio_confirm(raw_target,quality,captured,now,1u,&renewed)) {
            if(pan_us==SERVO_PAN_MIN_US || pan_us==SERVO_PAN_MAX_US)
                last_qualified_sound=captured;
            sound_accept_sequence++;
            sound_seek_confirm_clear(&sound_confirmation);
        }
        return;
    }
    int32_t confirmed;
    if(!audio_confirm(raw_target,quality,captured,now,sound_plan_active,&confirmed))return;
    sound_seek_confirm_clear(&sound_confirmation);
    formal_direction_forget();
    recovery_reset();boundary_latched=0;had_visual=0;external_visual=0;detection[3]=0;ncc_detection=0;
    last_qualified_sound=captured;
    sound_angle_mdeg=confirmed;
    while(sound_angle_mdeg>180000)sound_angle_mdeg-=360000;
    while(sound_angle_mdeg< -180000)sound_angle_mdeg+=360000;
    target=confirmed<-180000?-180000:confirmed>180000?180000:confirmed;
    sound_target_pan=target;sound_command_yaw=pose();
    sound_target_us=pulse_for_pose(sound_target_pan);
    sound_accept_sequence++;
    sound_phase=SEEK_TURN;sound_plan_active=1;sound_advance();
}
void servo_tracking_observe(float score,const float box[4],uint32_t sequence,uint64_t captured,uint64_t now) {
    /* Sparse fallback is an independent observation entry, so check the
     * lease/clock before clearing continuous state or counting stable hits. */
    unsigned expired=automatic && now>=auto_expires;
    if(now<continuous_time_floor || !captured || captured>now ||
       (last_capture && captured<last_capture))formal_direction_time_guard(now);
    servo_tracking_tick(now);
    if(expired || now<continuous_time_floor)return;
    /* Sparse SSD fallback retains its independent post-motion guard. A delayed
     * SSD box must never leave a prior NCC velocity running. */
    continuous_reset();
    ncc_detection=0;
    clock_now=now;
    if(automatic && now>=auto_expires){servo_tracking_poll(now);return;}
    /* Keep capture ordering across misses so delayed negative or positive
     * frames cannot replace a newer target or count as another stable hit. */
    if(captured && captured<=last_capture)return;
    if(automatic && sequence==last_observation)return;
    if(captured && captured<=now)last_capture=captured;
    if(!box || !isfinite(score) || score<=VISUAL_BIRD_MIN_SCORE || score>1.f || !captured ||
       captured>now || now-captured>SERVO_VISUAL_FRESH_US) {
        servo_tracking_clear_detection();return;
    }
    for(unsigned i=0;i<4;i++)if(!isfinite(box[i])){servo_tracking_clear_detection();return;}
    if(box[0]<0 || box[1]<0 || box[2]>AV_VIDEO_WIDTH || box[3]>AV_VIDEO_HEIGHT ||
       box[2]-box[0]<8 || box[3]-box[1]<8){servo_tracking_clear_detection();return;}
    if(recovery_scanning && captured<recovery_started)return;
    detection_captured=captured;detection[1]=sequence;detection[3]=1;
    detection[4]=visual_detection_score_q6(score);
    for(unsigned i=0;i<4;i++)detection[5+i]=(uint32_t)(box[i]*1000.f+.5f);
    detection[9]=last_command;
    if(!automatic)return;
    /* Fresh visual evidence interrupts homing immediately, even while settling.
     * Movement still waits for a new, stable, post-motion observation. */
    formal_direction_record(box,captured,now);
    unsigned recovering=recovery_scanning;
    if(!recovering) {
        homing=sound_plan_active=0;had_visual=1;sound_cutoff=now;
    }
    if(sound_automatic)sound_state=SOUND_VISUAL;
    last_observation=sequence;
    if(captured<settled_after){hits=0;reason=WAIT_POST_MOTION;return;}
    candidate_hold_reset(); /* A post-motion formal SSD may now take ownership. */
    float ex=(box[0]+box[2])*.5f-AV_VIDEO_WIDTH*.5f;
    float x=ex/AV_VIDEO_WIDTH,y=(box[1]+box[3])/(2.f*AV_VIDEO_HEIGHT)-.5f;
    if(!hits || fabsf(x-previous_x)>.2f || fabsf(y-previous_y)>.2f)hits=1;else hits++;
    previous_x=x;previous_y=y;
    /* Upstream SSD identity is already formal after one >50% detection.
     * This fallback takes at most one step per independent post-motion image;
     * it never turns a delayed SSD coordinate into continuous velocity. */
    if(recovering) {
        /* The sparse SSD fallback needs a new independent post-motion frame;
         * candidate/coarse presence and delayed pre-loss coordinates cannot
         * cancel the bounded recovery search. It remains a single step. */
        if(captured<recovery_started){reason=WAIT_POST_MOTION;return;}
        recovery_reset();boundary_latched=0;homing=sound_plan_active=0;had_visual=1;sound_cutoff=now;
    }
    if(now<not_before){reason=COOLDOWN;return;}
    unsigned close=fabsf(ex)<=SERVO_DEFAULT_NEAR_THRESHOLD_PX;
    unsigned step=close?SERVO_PAN_NEAR_STEP_US:SERVO_PAN_STEP_US;
    if(ex<-48.f && pan_us>SERVO_PAN_MIN_US) {
        if(!pan_step(1,step,SERVO_PAN_MOVE_INTERVAL_US)){visual_last_band=close?1:2;hits=1;}
    } else if(ex>48.f && pan_us<SERVO_PAN_MAX_US) {
        if(!pan_step(2,step,SERVO_PAN_MOVE_INTERVAL_US)){visual_last_band=close?1:2;hits=1;}
    } else if(y>.04f && tilt_us<2181)auto_tilt(y);
    else if(y<-.04f && tilt_us>540)auto_tilt(y);
    else reason=fabsf(y)>.04f || fabsf(ex)>48.f?LIMIT:CENTERED;
}
void servo_tracking_status(uint32_t words[10]) {
    words[0]=0x53525631u;words[1]=supported;words[2]=automatic;
    words[3]=(uint32_t)pose();words[4]=tilt_us;words[5]=words[6]=0;
    words[7]=supported?read_reg(AV_REG_SERVO_STATUS):0;words[8]=last_command;
    words[9]=(pan_us==SERVO_PAN_MIN_US?1u:0u)|(pan_us==SERVO_PAN_MAX_US?2u:0u);
}
void servo_tracking_diagnostic(uint32_t words[10]) {
    words[0]=0x53525632u;words[1]=SERVO_PAN_CENTER_US-SERVO_PAN_STEP_US;
    words[2]=SERVO_PAN_CENTER_US+SERVO_PAN_STEP_US;words[3]=SERVO_PAN_CENTER_US;
    words[4]=words[5]=words[6]=0;
    words[7]=supported?read_reg(AV_REG_SERVO_LEFT_FRAMES):0;
    words[8]=supported?read_reg(AV_REG_SERVO_RIGHT_FRAMES):0;words[9]=reason;
}
void servo_tracking_guard_status(uint32_t words[8]) {
    memset(words,0,8*sizeof *words);words[0]=0x53525633u;words[1]=180000;
    words[6]=SERVO_FRAME_US;words[7]=2; /* Position calibration, not angular speed. */
}
void servo_tracking_limit_status(uint32_t words[8]) {
    words[0]=0x53525634u;words[1]=1;words[2]=supported;
    words[3]=(uint32_t)-180000;words[4]=180000;words[5]=(uint32_t)pose();words[6]=words[7]=0;
}
void servo_tracking_limit_switch_status(uint32_t words[4]) {
    words[0]=0x53525635u;words[1]=0;words[2]=1;words[3]=1;
}
void servo_tracking_detection(uint32_t words[10]) {
    memcpy(words,detection,sizeof detection);words[0]=0x54524b31u;
    uint64_t age=clock_now>=detection_captured?clock_now-detection_captured:UINT64_MAX;
    words[2]=age/1000u>UINT32_MAX?UINT32_MAX:(uint32_t)(age/1000u);
    if(ncc_detection) {
        if(age>VISUAL_SERVO_POSITION_MAX_AGE_US)words[3]=0;
    } else if(age>SERVO_VISUAL_FRESH_US || detection_captured<settled_after)words[3]=0;
}
void servo_tracking_sound_status(uint32_t words[8]) {
    uint64_t age=last_sound && clock_now>=last_sound?(clock_now-last_sound)/1000u:UINT64_MAX;
    words[0]=0x534e4431u;words[1]=supported;words[2]=automatic && sound_automatic;
    words[3]=sound_state;words[4]=(uint32_t)sound_angle_mdeg;
    words[5]=age>UINT32_MAX?UINT32_MAX:(uint32_t)age;words[6]=sound_steps;words[7]=0; /* base-fixed array */
}
void servo_tracking_position_status(uint32_t words[12]) {
    words[0]=0x53525638u;words[1]=supported;words[2]=1; /* positional mode */
    words[3]=pan_us;words[4]=SERVO_PAN_CENTER_US;words[5]=SERVO_PAN_MIN_US;words[6]=SERVO_PAN_MAX_US;
    words[7]=(uint32_t)(pose()+180000);words[8]=homing;
    words[9]=SERVO_PAN_HOME_STEP_US;words[10]=SERVO_PAN_HOME_INTERVAL_US/1000u;words[11]=2;
}
