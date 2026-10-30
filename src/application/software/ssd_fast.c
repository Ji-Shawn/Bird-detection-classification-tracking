#include "ssd_fast.h"
#include "visual_detection_policy.h"
#include "servo_tracking.h"
#include "network_service.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>

#define W 160
#define H 90
#define SCALE 12
#define GRID 8
#define RADIUS 12
#define SIDE (2*RADIUS+1)
#define TTL 5000000u
static uint32_t boot_id,serial,message_sequence,epoch;
static unsigned visible,seeded,processing,cursor,reason,dirty;
static uint32_t source_sequence,search_sequence;
static uint64_t seed_time,frame_time,search_time,last_send,clear_until;
static float box_now[4],detector_score,quality;
static int ox,oy,sx[GRID*GRID],sy[GRID*GRID];
static uint8_t pixels[GRID*GRID];
static float tsum,tvar,scores[SIDE*SIDE];
/* Candidate-only trajectory. Recording a pose is not formal confirmation and
 * never changes the motor target. The same-capture checkpoint prevents a
 * delayed second SSD result from blessing an unrelated current candidate. */
#define HANDOFF_HISTORY 96u
typedef struct {
    uint32_t sequence;
    uint64_t timestamp;
    float box[4],quality,margin;
} candidate_pose;
static candidate_pose candidate_history[HANDOFF_HISTORY];
static unsigned candidate_history_count,candidate_history_next,handoff_ready;
static candidate_pose handoff_current;
static uint32_t handoff_ssd_sequence;
static uint64_t handoff_ssd_captured;
static float handoff_ssd_box[4],handoff_ssd_score;
static int valid_box(float score,const float *b);
static void candidate_record(float margin) {
    candidate_pose *p=&candidate_history[candidate_history_next];
    p->sequence=source_sequence;p->timestamp=frame_time;
    memcpy(p->box,box_now,sizeof p->box);p->quality=quality;p->margin=margin;
    candidate_history_next=(candidate_history_next+1u)%HANDOFF_HISTORY;
    if(candidate_history_count<HANDOFF_HISTORY)candidate_history_count++;
}
static float handoff_intersection(const float a[4],const float b[4]) {
    float w=fminf(a[2],b[2])-fmaxf(a[0],b[0]);
    float h=fminf(a[3],b[3])-fmaxf(a[1],b[1]);
    if(w<=0 || h<=0)return 0;
    float area=w*h;
    return area/((a[2]-a[0])*(a[3]-a[1])+(b[2]-b[0])*(b[3]-b[1])-area);
}
static unsigned prepare_handoff(float score,const float *box,uint32_t seq,
                                 uint64_t captured,uint64_t now) {
    if(!visible || !seeded || !box || !captured || captured<=seed_time ||
       frame_time<captured || now<frame_time || now-frame_time>500000u ||
       now<seed_time || now-seed_time>TTL || !isfinite(score) ||
       score<=VISUAL_BIRD_MIN_SCORE || score>1.f)return 0;
    if(!valid_box(score,box))return 0;
    const candidate_pose *capture=0,*current=0;
    for(unsigned i=0;i<candidate_history_count;i++) {
        const candidate_pose *p=&candidate_history[i];
        if(p->sequence==seq && p->timestamp==captured)capture=p;
        if(p->sequence==source_sequence && p->timestamp==frame_time)current=p;
    }
    if(!capture || !current || capture->quality<.8f || capture->margin<.03f ||
       current->quality<.8f || current->margin<.03f ||
       handoff_intersection(capture->box,box)<.35f ||
       !ssd_history_exact(seq,captured) || !ssd_history_exact(source_sequence,frame_time))return 0;
    handoff_current=*current;handoff_ssd_sequence=seq;handoff_ssd_captured=captured;
    memcpy(handoff_ssd_box,box,sizeof handoff_ssd_box);handoff_ssd_score=score;
    return 1;
}
/* Cache is bound to a confirmed identity, the current independent SSD frame,
 * and image policy. Replayed packets or a replacement never inherit a label. */
static unsigned class_ready,class_policy;
static uint32_t class_epoch,confirmed_sequence;
static uint64_t class_time,confirmed_time;
static int8_t class_logits[60];
static int32_t class_roi[4];
static uint32_t class_source_sequence,class_applied;
static uint64_t class_source_timestamp;
/* SD labels never feed back into candidate selection, tracking or classifiers. */
#define SD_ARCHIVE_MIN_SSD_SCORE .95f
static unsigned archive_ready,archive_ssd_qualified;
static uint32_t archive_epoch,archive_species;
static uint64_t archive_classified;

static void hide(unsigned why,uint64_t now) {
    visible=seeded=processing=handoff_ready=0;reason=why;clear_until=now+500000u;dirty=1;
}
void ssd_fast_reset(void) {
    archive_ready=archive_ssd_qualified=0;
    visible=seeded=processing=class_ready=handoff_ready=0;
    candidate_history_count=candidate_history_next=0;
    seed_time=frame_time=confirmed_time=0;reason=3;clear_until=0;last_send=0;dirty=1;
    /* serial/epoch remain monotonic across mode resets within a boot. */
}
void ssd_fast_init(uint32_t boot) {
    boot_id=boot;serial=message_sequence=epoch=0;ssd_fast_reset();
}
static int valid_box(float score,const float *b) {
    if(!b || !isfinite(score) || score<=VISUAL_BIRD_MIN_SCORE || score>1.f)return 0;
    for(unsigned i=0;i<4;i++)if(!isfinite(b[i]))return 0;
    return b[0]>=0 && b[1]>=0 && b[2]<=1920 && b[3]<=1080 && b[2]-b[0]>=8 && b[3]-b[1]>=8;
}
static void begin(float score,const float *box,uint32_t seq,uint64_t ts,uint64_t now) {
    handoff_ready=0;candidate_history_count=candidate_history_next=0;
    if(!valid_box(score,box) || !ts || ts>now || now-ts>TTL){hide(2,now);return;}
    if(++serial==0)++serial;
    visible=1;seeded=processing=0;cursor=0;reason=0;
    last_send=0;
    source_sequence=seq;seed_time=frame_time=ts;detector_score=score;quality=1;
    memcpy(box_now,box,sizeof box_now);
    const uint8_t *f=ssd_history_exact(seq,ts);
    if(!f || box[2]-box[0]<96 || box[3]-box[1]<96)return;
    int x1=(int)floorf(box[0]/SCALE),x2=(int)ceilf(box[2]/SCALE);
    int y1=(int)floorf(box[1]/SCALE),y2=(int)ceilf(box[3]/SCALE);
    ox=(x1+x2)/2;oy=(y1+y2)/2;tsum=tvar=0;
    for(int y=0;y<GRID;y++)for(int x=0;x<GRID;x++) {
        int i=y*GRID+x,px=x1+(2*x+1)*(x2-x1)/(2*GRID),py=y1+(2*y+1)*(y2-y1)/(2*GRID);
        if(px<0 || px>=W || py<0 || py>=H)return;
        sx[i]=px-ox;sy[i]=py-oy;float v=pixels[i]=f[py*W+px];tsum+=v;tvar+=v*v;
    }
    tvar-=tsum*tsum/(GRID*GRID);seeded=tvar>=25.f*GRID*GRID;
}
void ssd_fast_selection(unsigned decision,float score,const float *box,
                        uint32_t seq,uint64_t ts,uint64_t now) {
    /* Photos use only this accepted SSD observation, never candidate/NCC or
     * species-classification confidence. Tracking keeps its existing gate. */
    archive_ssd_qualified=0;
    if(decision==1) {archive_ready=0;begin(score,box,seq,ts,now);return;}
    if(decision==2 || decision==3 || decision==4) {
        archive_ssd_qualified=valid_box(score,box) && score>=SD_ARCHIVE_MIN_SSD_SCORE &&
            ts && ts<=now && now-ts<=TTL;
        unsigned ready=decision==3?prepare_handoff(score,box,seq,ts,now):0u;
        if(decision!=2 || !epoch){if(++epoch==0)++epoch;class_ready=0;archive_ready=0;}
        confirmed_sequence=seq;confirmed_time=ts;hide(4,now);handoff_ready=ready;return;
    }
    /* No new candidate, unsupported original target or an unverifiable frame. */
    hide(1,now);
    if(decision==0 || decision==5 || decision==6)archive_ready=0;
    if(decision==0 || decision==6){class_ready=0;confirmed_time=0;}
}
static float match(const uint8_t *f,int dx,int dy) {
    unsigned sum=0,square=0,dot=0;
    for(int i=0;i<GRID*GRID;i++) {
        int x=ox+dx+sx[i],y=oy+dy+sy[i];
        if(x<0 || x>=W || y<0 || y>=H)return -2;
        unsigned v=f[y*W+x];sum+=v;square+=v*v;dot+=v*pixels[i];
    }
    float var=(float)square-(float)sum*sum/(GRID*GRID);
    return var<25.f*GRID*GRID?-2:((float)dot-tsum*sum/(GRID*GRID))/sqrtf(tvar*var);
}
void ssd_fast_poll(uint64_t now) {
    if(!visible)return;
    if(now<seed_time || now-seed_time>TTL){hide(2,now);return;}
    if(!seeded) {if(now<frame_time || now-frame_time>1000000u)hide(1,now);return;}
    if(!processing) {
        const uint8_t *f=ssd_history_next(frame_time,&search_sequence,&search_time);
        if(!f){if(now<frame_time || now-frame_time>1000000u)hide(1,now);return;}
        if(search_time-frame_time>600000u){hide(1,now);return;}
        processing=1;cursor=0;
    }
    const uint8_t *f=ssd_history_exact(search_sequence,search_time);
    if(!f){hide(1,now);return;}
    for(unsigned k=0;k<64 && cursor<SIDE*SIDE;k++,cursor++)
        scores[cursor]=match(f,(int)(cursor%SIDE)-RADIUS,(int)(cursor/SIDE)-RADIUS);
    if(cursor<SIDE*SIDE)return;
    unsigned best=0;for(unsigned i=1;i<SIDE*SIDE;i++)if(scores[i]>scores[best])best=i;
    int dx=(int)(best%SIDE)-RADIUS,dy=(int)(best/SIDE)-RADIUS;float second=-2;
    for(unsigned i=0;i<SIDE*SIDE;i++) {
        int x=(int)(i%SIDE)-RADIUS-dx,y=(int)(i/SIDE)-RADIUS-dy;
        if(x*x+y*y>=9 && scores[i]>second)second=scores[i];
    }
    if(scores[best]<.8f || scores[best]-second<.03f || abs(dx)==RADIUS || abs(dy)==RADIUS ||
       box_now[0]+dx*SCALE<0 || box_now[1]+dy*SCALE<0 ||
       box_now[2]+dx*SCALE>1920 || box_now[3]+dy*SCALE>1080){hide(1,now);return;}
    ox+=dx;oy+=dy;box_now[0]+=dx*SCALE;box_now[2]+=dx*SCALE;
    box_now[1]+=dy*SCALE;box_now[3]+=dy*SCALE;
    frame_time=search_time;source_sequence=search_sequence;quality=scores[best];processing=0;
    candidate_record(scores[best]-second);
}
int ssd_fast_handoff(float score,const float confirmed_box[4],uint32_t sequence,
                      uint64_t captured,uint64_t now,float current_box[4],
                      uint32_t *current_sequence,uint64_t *current_captured) {
    if(!handoff_ready || !confirmed_box || !current_box || !current_sequence || !current_captured ||
       sequence!=handoff_ssd_sequence || captured!=handoff_ssd_captured || score!=handoff_ssd_score ||
       memcmp(confirmed_box,handoff_ssd_box,sizeof handoff_ssd_box) ||
       now<handoff_current.timestamp || now-handoff_current.timestamp>500000u ||
       !ssd_history_exact(sequence,captured) ||
       !ssd_history_exact(handoff_current.sequence,handoff_current.timestamp))return 0;
    memcpy(current_box,handoff_current.box,sizeof handoff_current.box);
    *current_sequence=handoff_current.sequence;*current_captured=handoff_current.timestamp;
    return 1;
}
int ssd_fast_view(uint64_t now,float box[4],float *score) {
    if(!visible || now<seed_time || now-seed_time>TTL || now<frame_time || now-frame_time>1500000u)return 0;
    memcpy(box,box_now,sizeof box_now);*score=detector_score;return 1;
}
void ssd_fast_send(uint64_t now) {
    if(last_send && now>=last_send && now-last_send<33000u)return;
    if(!visible && !dirty && now>clear_until)return;
    uint32_t wire[20]={0x31505653u,1,80,0};float box[4],score=0;
    unsigned show=ssd_fast_view(now,box,&score);
    wire[3]=boot_id;wire[4]=++message_sequence;wire[5]=serial;wire[6]=show;
    wire[7]=source_sequence;wire[8]=(uint32_t)frame_time;wire[9]=(uint32_t)(frame_time>>32);
    wire[10]=(uint32_t)now;wire[11]=(uint32_t)(now>>32);
    if(show){memcpy(wire+12,box,16);memcpy(wire+16,&score,4);memcpy(wire+17,&quality,4);}
    wire[18]=reason;
    if(!platform_udp_send(15005u,wire,sizeof wire)){last_send=now;dirty=0;}
}
void ssd_fast_hold_scan(uint64_t now) {
    float box[4],score;
    servo_tracking_sound_candidate(ssd_fast_view(now,box,&score),now);
}
int ssd_fast_class_reuse(uint32_t seq,uint64_t ts,unsigned policy,uint64_t now,int8_t logits[60],int32_t roi[4],uint32_t *applied) {
    if(!class_ready || class_epoch!=epoch || seq!=confirmed_sequence || ts!=confirmed_time ||
       class_policy!=policy || now<class_time || now-class_time>2000000u)return 0;
    memcpy(logits,class_logits,60);memcpy(roi,class_roi,sizeof class_roi);*applied=class_applied;return 1;
}
void ssd_fast_class_store(uint32_t seq,uint64_t ts,unsigned policy,uint64_t now,const int8_t *logits,float confidence,const int32_t roi[4],unsigned applied) {
    if(!epoch || !confirmed_time || seq!=confirmed_sequence || ts!=confirmed_time || !logits ||
       now<ts || !isfinite(confidence) || confidence<0 || confidence>1.f || !roi)return;
    memcpy(class_logits,logits,60);class_time=now;class_policy=policy;class_epoch=epoch;class_ready=confidence>=.5f;
    memcpy(class_roi,roi,sizeof class_roi);class_applied=applied;
    class_source_sequence=seq;class_source_timestamp=ts;
}
void ssd_fast_class_report(uint32_t seq,uint64_t ts,int reused,uint64_t now) {
    if(!class_time || class_epoch!=epoch || seq!=confirmed_sequence || ts!=confirmed_time)return;
    uint32_t w[24]={0x31435653u,1,96,0};
    w[3]=boot_id;w[4]=++message_sequence;w[5]=epoch;w[6]=seq;w[7]=reused!=0;
    w[8]=(uint32_t)ts;w[9]=(uint32_t)(ts>>32);w[10]=class_source_sequence;w[11]=class_policy;
    w[12]=(uint32_t)class_source_timestamp;w[13]=(uint32_t)(class_source_timestamp>>32);
    w[14]=(uint32_t)class_time;w[15]=(uint32_t)(class_time>>32);
    w[16]=(uint32_t)now;w[17]=(uint32_t)(now>>32);w[18]=class_applied;
    memcpy(w+19,class_roi,sizeof class_roi);
    (void)platform_udp_send(15005u,w,sizeof w);
}
uint32_t ssd_fast_archive_identity(uint32_t seq,uint64_t ts,unsigned policy) {
    return epoch && confirmed_time && seq==confirmed_sequence && ts==confirmed_time && policy<2u?epoch:0u;
}
void ssd_fast_archive_store(uint32_t identity,uint32_t seq,uint64_t ts,
                            unsigned policy,uint64_t now,unsigned species,int reused) {
    if(!identity || identity!=ssd_fast_archive_identity(seq,ts,policy) || species>=60u ||
       !class_time || class_epoch!=identity || class_policy!=policy || now<class_time ||
       now-class_time>2000000u || now<ts || now-ts>TTL)return;
    if(reused) {
        if(!class_ready)return;
    } else if(class_source_sequence!=seq || class_source_timestamp!=ts)return;
    archive_epoch=identity;archive_species=species;archive_classified=class_time;archive_ready=1;
}
int ssd_fast_archive_snapshot(uint64_t now,uint32_t *species,uint32_t *identity,
                              uint64_t *classified_us) {
    if(!species || !identity || !classified_us || !archive_ready || !archive_ssd_qualified || !confirmed_time ||
       now<confirmed_time || now-confirmed_time>TTL ||
       archive_epoch!=epoch || archive_species>=60u || now<archive_classified ||
       now-archive_classified>2000000u)return 0;
    *species=archive_species;*identity=archive_epoch;*classified_us=archive_classified;return 1;
}
