#include "visual_tracker.h"
#include "servo_tracking.h"
#include "av_shared.h"
#include <math.h>
#include <string.h>
#include <limits.h>
#define WIDTH 160u
#define HEIGHT 90u
#define SCALE 12u
#define HISTORY 32u
#define GRID 12u
#define SAMPLE_SIDE 4u
#define SAMPLE_WIDTH (WIDTH*SAMPLE_SIDE)
#define SAMPLE_COUNT (WIDTH*HEIGHT*SAMPLE_SIDE*SAMPLE_SIDE)
#define RADIUS 16
#define RECOVERY_RADIUS 24
#define MAX_SIDE (2*RECOVERY_RADIUS+1)
#define CANDIDATES (MAX_SIDE*MAX_SIDE)
#define SLICE_CANDIDATES 16u
#define CONFIRM_US VISUAL_TRACKER_CONFIRM_US
enum {TRACK_OK,LOW_MATCH,AMBIGUOUS_MATCH,SEARCH_EDGE,BOX_OUTSIDE,
      CONFIRM_EXPIRED,VIDEO_STALE,FRAME_GAP,HISTORY_OVERWRITE,CLOCK_INVALID,
      SMALL_SEED,FLAT_SEED,NO_SEED_HISTORY,SSD_UNSUPPORTED};
typedef struct {
    uint8_t gray[WIDTH*HEIGHT];
    unsigned valid,tracked;
    uint32_t sequence;
    uint64_t timestamp;
    float box[4];
} track_frame;
static track_frame history[HISTORY];
static unsigned have_frame,head,pending,pending_slot,pixel_cursor;
static uint32_t next_offset;
static uint16_t gray_sums[WIDTH*HEIGHT];
static unsigned active,npoints,processing,search_slot,search_cursor;
static uint32_t search_sequence,tracked_frames,losses,last_sequence;
static uint64_t search_timestamp,last_processed,last_checked,confirmed,reacquire_started;
static unsigned misses,current_reason,last_loss_reason,recovered;
static unsigned search_side,search_candidates;
static int search_radius;
static float box_now[4],bird_score,quality,t_sum,t_variance;
static int origin_x,origin_y,min_x,max_x,min_y,max_y;
static int8_t sample_x[GRID*GRID],sample_y[GRID*GRID];
static uint8_t template_pixels[GRID*GRID];
static float scores[CANDIDATES];
static unsigned candidate_count,candidate_hits,unsupported,selected_index,selection_reason;
static uint32_t selection_sequence,switch_count,rejected_batches;
static uint64_t selection_captured,candidate_captured;
static float candidate_box[4];
static int motion_x,motion_y,predict_x,predict_y;
static uint64_t motion_dt;

static void reset_track(void) {
    active=processing=misses=0;confirmed=last_processed=last_checked=reacquire_started=0;
    quality=0;current_reason=TRACK_OK;
    motion_x=motion_y=predict_x=predict_y=0;motion_dt=0;
    servo_tracking_clear_detection();
}
void visual_tracker_reset(void) {
    reset_track();candidate_count=candidate_hits=unsupported=selected_index=selection_reason=0;
    selection_sequence=0;selection_captured=candidate_captured=0;
}
void visual_tracker_init(void) {
    memset(history,0,sizeof history);have_frame=head=pending=pixel_cursor=0;
    tracked_frames=losses=last_sequence=recovered=last_loss_reason=0;
    switch_count=rejected_batches=0;visual_tracker_reset();
}
void visual_tracker_frame_abort(void){pending=0;}
void visual_tracker_frame_begin(uint32_t sequence,uint64_t timestamp) {
    pending_slot=have_frame?(head+1u)%HISTORY:0;
    track_frame *f=&history[pending_slot];f->valid=f->tracked=0;
    f->sequence=sequence;f->timestamp=timestamp;
    pending=1;pixel_cursor=next_offset=0;
    memset(gray_sums,0,sizeof gray_sums);
}
void visual_tracker_frame_chunk(const void *rgb565,uint32_t offset,uint32_t bytes) {
    if(!pending)return;
    if(!rgb565 || offset!=next_offset || (offset|bytes)&1u ||
       offset>AV_VIDEO_FRAME_BYTES || bytes>AV_VIDEO_FRAME_BYTES-offset) {
        pending=0;return;
    }
    const uint8_t *p=rgb565;uint32_t end=offset+bytes;
    /* Sixteen spatial samples per 12x12 cell suppress point-sampling aliasing.
     * Cursor follows input order, including arbitrary even DMA boundaries. */
    while(pixel_cursor<SAMPLE_COUNT) {
        unsigned x=pixel_cursor%SAMPLE_WIDTH,y=pixel_cursor/SAMPLE_WIDTH;
        uint32_t at=((y*3u+1u)*AV_VIDEO_WIDTH+x*3u+1u)*2u;
        if(at>=end)break;
        if(at<offset || at+1u>=end){pending=0;return;}
        uint16_t v=(uint16_t)(p[at-offset]|((uint16_t)p[at-offset+1u]<<8));
        unsigned r=(v>>11)&31u,g=(v>>5)&63u,b=v&31u;
        r=(r<<3)|(r>>2);g=(g<<2)|(g>>4);b=(b<<3)|(b>>2);
        gray_sums[(y/SAMPLE_SIDE)*WIDTH+x/SAMPLE_SIDE]+=(uint16_t)((77*r+150*g+29*b)>>8);
        pixel_cursor++;
    }
    next_offset=end;
}
void visual_tracker_frame_end(void) {
    if(pending && next_offset==AV_VIDEO_FRAME_BYTES && pixel_cursor==SAMPLE_COUNT &&
       (!have_frame || history[pending_slot].timestamp>history[head].timestamp)) {
        for(unsigned i=0;i<WIDTH*HEIGHT;i++)
            history[pending_slot].gray[i]=(uint8_t)((gray_sums[i]+8u)/16u);
        /* Binomial low-pass makes sub-cell motion less sensitive to texture phase.
         * Reuse sums after conversion, so history storage stays unchanged. */
        uint8_t *gray=history[pending_slot].gray;
        for(unsigned y=0;y<HEIGHT;y++)for(unsigned x=0;x<WIDTH;x++) {
            unsigned l=x?x-1:x,r=x+1<WIDTH?x+1:x;
            unsigned u=y?y-1:y,d=y+1<HEIGHT?y+1:y;
            gray_sums[y*WIDTH+x]=(uint16_t)((gray[u*WIDTH+l]+2u*gray[u*WIDTH+x]+gray[u*WIDTH+r]+
                2u*gray[y*WIDTH+l]+4u*gray[y*WIDTH+x]+2u*gray[y*WIDTH+r]+
                gray[d*WIDTH+l]+2u*gray[d*WIDTH+x]+gray[d*WIDTH+r]+8u)/16u);
        }
        for(unsigned i=0;i<WIDTH*HEIGHT;i++)gray[i]=(uint8_t)gray_sums[i];
        history[pending_slot].valid=1;head=pending_slot;have_frame=1;
    }
    pending=0;
}
static void lost(unsigned why){losses++;reset_track();candidate_hits=0;last_loss_reason=why;}
static void missed(unsigned why,const track_frame *f,uint64_t now) {
    /* Keep the last confirmed template/origin for a bounded retry. A failed
     * image never refreshes the target timestamp or supplies a servo target. */
    if(!misses)reacquire_started=now;
    misses++;current_reason=why;processing=0;last_checked=f->timestamp;
    servo_tracking_clear_detection();
    if(misses>=VISUAL_TRACKER_MAX_MISSES || f->timestamp-last_processed>=VISUAL_TRACKER_REACQUIRE_US ||
       now-reacquire_started>=VISUAL_TRACKER_REACQUIRE_US)lost(why);
}
static float intersection(const float a[4],const float b[4]) {
    float w=fminf(a[2],b[2])-fmaxf(a[0],b[0]);
    float h=fminf(a[3],b[3])-fmaxf(a[1],b[1]);
    if(w<=0 || h<=0)return 0;
    float area=w*h;
    return area/((a[2]-a[0])*(a[3]-a[1])+(b[2]-b[0])*(b[3]-b[1])-area);
}
static int valid_candidate(const visual_candidate *c) {
    if(!isfinite(c->score) || c->score<.5f || c->score>1.f)return 0;
    for(unsigned i=0;i<4;i++)if(!isfinite(c->box[i]))return 0;
    return c->box[0]>=0 && c->box[1]>=0 && c->box[2]<=AV_VIDEO_WIDTH &&
           c->box[3]<=AV_VIDEO_HEIGHT && c->box[2]-c->box[0]>=8 && c->box[3]-c->box[1]>=8;
}
/* Same-capture-frame appearance association for moving SSD proposals.
 * This only supplies the second confirmation; it never creates a detection. */
static float candidate_appearance(const track_frame *a,const float ab[4],
                                  const track_frame *b,const float bb[4]) {
    if(!a || !b)return -2.f;
    float aw=ab[2]-ab[0],ah=ab[3]-ab[1],bw=bb[2]-bb[0],bh=bb[3]-bb[1];
    if(aw<96 || ah<96 || bw<aw*.67f || bw>aw*1.5f || bh<ah*.67f || bh>ah*1.5f ||
       fabsf((ab[0]+ab[2]-bb[0]-bb[2])*.5f)>480.f ||
       fabsf((ab[1]+ab[3]-bb[1]-bb[3])*.5f)>360.f)return -2.f;
    float sa=0,sb=0,aa=0,bbv=0,abv=0;
    for(unsigned y=0;y<GRID;y++)for(unsigned x=0;x<GRID;x++) {
        int ax=(int)((ab[0]+(x+.5f)*aw/GRID)/SCALE),ay=(int)((ab[1]+(y+.5f)*ah/GRID)/SCALE);
        int bx=(int)((bb[0]+(x+.5f)*bw/GRID)/SCALE),by=(int)((bb[1]+(y+.5f)*bh/GRID)/SCALE);
        if(ax<0 || ax>=WIDTH || bx<0 || bx>=WIDTH || ay<0 || ay>=HEIGHT || by<0 || by>=HEIGHT)return -2.f;
        float va=a->gray[ay*WIDTH+ax],vb=b->gray[by*WIDTH+bx];
        sa+=va;sb+=vb;aa+=va*va;bbv+=vb*vb;abv+=va*vb;
    }
    float va=aa-sa*sa/(GRID*GRID),vb=bbv-sb*sb/(GRID*GRID);
    if(va<25*GRID*GRID || vb<25*GRID*GRID)return -2.f;
    return (abv-sa*sb/(GRID*GRID))/sqrtf(va*vb);
}
int visual_tracker_select_ssd(const visual_candidate *c,unsigned count,
                             uint32_t sequence,uint64_t captured,uint64_t now) {
    /* Duplicate, out-of-order or delayed results cannot count as confirmation
     * or as a negative vote. Never compare an old detection with box_now. */
    if(count>100 || (count && !c) || !captured || captured>now ||
       now-captured>5000000u || captured<=selection_captured)return -1;
    selection_captured=captured;selection_sequence=sequence;
    candidate_count=selected_index=0;selection_reason=0;
    track_frame *f=0;
    for(unsigned i=0;i<HISTORY;i++)if(history[i].valid && history[i].sequence==sequence &&
        history[i].timestamp==captured){f=&history[i];break;}
    int best=-1,same=-1,continuation=-1;float best_iou=.25f,continuation_iou=.35f;
    for(unsigned i=0;i<count;i++)if(valid_candidate(&c[i])) {
        candidate_count++;
        if(best<0 || c[i].score>c[best].score)best=(int)i;
        if(active && f && f->tracked) {
            float overlap=intersection(f->box,c[i].box);
            if(overlap>=best_iou){best_iou=overlap;same=(int)i;}
        }
        if(candidate_hits && captured>=candidate_captured && captured-candidate_captured<=5000000u) {
            float overlap=intersection(candidate_box,c[i].box);
            if(overlap>=continuation_iou){continuation_iou=overlap;continuation=(int)i;}
        }
    }
    if(!active && continuation<0 && candidate_hits && f && captured>=candidate_captured &&
       captured-candidate_captured<=3000000u) {
        track_frame *prior=0;
        for(unsigned i=0;i<HISTORY;i++)if(history[i].valid && history[i].timestamp==candidate_captured){prior=&history[i];break;}
        float best_match=-2.f,second_match=-2.f;int appearance_index=-1;
        for(unsigned i=0;i<count;i++)if(valid_candidate(&c[i])) {
            float match=candidate_appearance(prior,candidate_box,f,c[i].box);
            if(match>best_match){second_match=best_match;best_match=match;appearance_index=(int)i;}
            else if(match>second_match)second_match=match;
        }
        if(best_match>=.85f && best_match-second_match>=.08f)continuation=appearance_index;
    }
    if(same>=0) {
        unsupported=candidate_hits=0;selection_reason=2;selected_index=(unsigned)same+1u;
        return same;
    }
    /* A positive result from a frame the tracker has not processed cannot
     * establish that it refers to another object. Await a verifiable batch. */
    if(active && best>=0 && (!f || !f->tracked)) {
        candidate_hits=0;selection_reason=7;return -1;
    }
    if(active)unsupported++;
    else unsupported=0;
    if(best>=0) {
        if(continuation>=0){best=continuation;candidate_hits++;}
        else candidate_hits=1;
        memcpy(candidate_box,c[best].box,sizeof candidate_box);candidate_captured=captured;
        /* Protect the existing target for two missing detections. Replacing
         * it requires both repeated evidence and exhaustion of that grace. */
        if(candidate_hits>=VISUAL_TARGET_CONFIRMATIONS &&
           (!active || unsupported>=VISUAL_TARGET_MAX_UNSUPPORTED)) {
            unsigned replacing=active;
            if(replacing){lost(SSD_UNSUPPORTED);switch_count++;}
            candidate_hits=unsupported=0;selection_reason=replacing?4u:3u;
            selected_index=(unsigned)best+1u;return best;
        }
        selection_reason=1;
    } else {candidate_hits=0;selection_reason=active?5u:0u;}
    if(active && unsupported>=VISUAL_TARGET_MAX_UNSUPPORTED) {
        lost(SSD_UNSUPPORTED);selection_reason=6;
    }
    rejected_batches++;return -1;
}
void visual_tracker_selection_status(uint32_t words[12]) {
    words[0]=0x54524b34u;words[1]=1;words[2]=candidate_count;words[3]=candidate_hits;
    words[4]=unsupported;words[5]=selected_index;words[6]=selection_reason;
    words[7]=switch_count;words[8]=rejected_batches;words[9]=VISUAL_TARGET_CONFIRMATIONS;
    words[10]=VISUAL_TARGET_MAX_UNSUPPORTED;words[11]=selection_sequence;
}
void visual_tracker_observe_ssd(float score,const float box[4],uint32_t sequence,
                                uint64_t captured,uint64_t now) {
    if(!box || !isfinite(score) || score<.5f || score>1.f || captured>now ||
       now-captured>CONFIRM_US)return;
    for(unsigned i=0;i<4;i++)if(!isfinite(box[i]))return;
    if(box[0]<0 || box[1]<0 || box[2]>AV_VIDEO_WIDTH || box[3]>AV_VIDEO_HEIGHT ||
       box[2]-box[0]<8 || box[3]-box[1]<8)return;
    if(box[2]-box[0]<SCALE*8 || box[3]-box[1]<SCALE*8) {
        if(active)return;
        current_reason=SMALL_SEED;
        servo_tracking_observe(score,box,sequence,captured,now);return;
    }
    track_frame *f=0;
    for(unsigned i=0;i<HISTORY;i++)if(history[i].valid && history[i].sequence==sequence &&
        history[i].timestamp==captured){f=&history[i];break;}
    if(!f) {
        /* Sparse SSD fallback can still correct small or untrackable birds.
         * Never seed an old SSD box onto an unrelated current image. */
        if(!active){current_reason=NO_SEED_HISTORY;servo_tracking_observe(score,box,sequence,captured,now);}
        return;
    }
    if(active && f->tracked && intersection(f->box,box)>=.25f) {
        confirmed=captured;bird_score=score;return;
    }
    if(active)reset_track();
    int x1=(int)floorf(box[0]/SCALE),y1=(int)floorf(box[1]/SCALE);
    int x2=(int)ceilf(box[2]/SCALE),y2=(int)ceilf(box[3]/SCALE);
    origin_x=(x1+x2)/2;origin_y=(y1+y2)/2;
    unsigned gw=(unsigned)(x2-x1)<GRID?(unsigned)(x2-x1):GRID;
    unsigned gh=(unsigned)(y2-y1)<GRID?(unsigned)(y2-y1):GRID;
    npoints=0;t_sum=t_variance=0;
    min_x=min_y=INT_MAX;max_x=max_y=INT_MIN;
    for(unsigned y=0;y<gh;y++)for(unsigned x=0;x<gw;x++) {
        int px=x1+(int)((2*x+1)*(unsigned)(x2-x1)/(2*gw));
        int py=y1+(int)((2*y+1)*(unsigned)(y2-y1)/(2*gh));
        if(px<0 || px>=(int)WIDTH || py<0 || py>=(int)HEIGHT)return;
        int dx=px-origin_x,dy=py-origin_y;
        if(dx<min_x)min_x=dx;
        if(dx>max_x)max_x=dx;
        if(dy<min_y)min_y=dy;
        if(dy>max_y)max_y=dy;
        sample_x[npoints]=(int8_t)dx;sample_y[npoints]=(int8_t)dy;
        float v=template_pixels[npoints++]=f->gray[py*WIDTH+px];
        t_sum+=v;t_variance+=v*v;
    }
    t_variance-=t_sum*t_sum/npoints;
    if(t_variance<25.f*npoints) {
        current_reason=FLAT_SEED;
        servo_tracking_observe(score,box,sequence,captured,now);return;
    }
    servo_tracking_clear_detection();
    memcpy(box_now,box,sizeof box_now);memcpy(f->box,box,sizeof f->box);f->tracked=1;
    active=1;confirmed=last_processed=last_checked=captured;last_sequence=sequence;
    motion_x=motion_y=0;motion_dt=0;
    quality=1;bird_score=score;misses=0;current_reason=TRACK_OK;reacquire_started=0;
}
static float correlation(const track_frame *f,int dx,int dy) {
    int cx=origin_x+dx,cy=origin_y+dy;
    if(cx+min_x<0 || cx+max_x>=(int)WIDTH || cy+min_y<0 || cy+max_y>=(int)HEIGHT)
        return -2.f;
    uint32_t sum=0,square=0,dot=0;
    for(unsigned i=0;i<npoints;i++) {
        unsigned v=f->gray[(cy+sample_y[i])*WIDTH+cx+sample_x[i]];
        sum+=v;square+=v*v;dot+=v*template_pixels[i];
    }
    float variance=(float)square-(float)sum*sum/npoints;
    if(variance<25.f*npoints)return -2.f;
    return ((float)dot-t_sum*sum/npoints)/sqrtf(t_variance*variance);
}
void visual_tracker_poll(uint64_t now) {
    if(!active)return;
    if(now<confirmed || (have_frame && now<history[head].timestamp)) {lost(CLOCK_INVALID);return;}
    if(now-confirmed>CONFIRM_US){lost(CONFIRM_EXPIRED);return;}
    if(!have_frame || now-history[head].timestamp>VISUAL_TRACKER_FRAME_US){lost(VIDEO_STALE);return;}
    if(misses && now-reacquire_started>=VISUAL_TRACKER_REACQUIRE_US){lost(current_reason);return;}
    if(!processing) {
        unsigned found=0;uint64_t earliest=UINT64_MAX;
        for(unsigned i=0;i<HISTORY;i++)if(history[i].valid && history[i].timestamp>last_checked &&
            history[i].timestamp<earliest){search_slot=i;earliest=history[i].timestamp;found=1;}
        if(!found)return;
        if(earliest-last_checked>600000u){lost(FRAME_GAP);return;}
        search_cursor=0;processing=1;
        search_radius=misses?RECOVERY_RADIUS:RADIUS;
        search_side=(unsigned)(2*search_radius+1);search_candidates=search_side*search_side;
        search_sequence=history[search_slot].sequence;search_timestamp=earliest;
        /* Bound extrapolation to retain the old location in the search window.
         * Failed frames never update velocity or refresh the confirmation. */
        float ratio=motion_dt && !misses?(float)(earliest-last_processed)/(float)motion_dt:0.f;
        predict_x=(int)roundf(fmaxf(-12.f,fminf(12.f,motion_x*ratio)));
        predict_y=(int)roundf(fmaxf(-12.f,fminf(12.f,motion_y*ratio)));
    }
    track_frame *f=&history[search_slot];
    if(!f->valid || f->sequence!=search_sequence || f->timestamp!=search_timestamp){lost(HISTORY_OVERWRITE);return;}
    for(unsigned k=0;k<SLICE_CANDIDATES && search_cursor<search_candidates;k++,search_cursor++)
        scores[search_cursor]=correlation(f,predict_x+(int)(search_cursor%search_side)-search_radius,
                                         predict_y+(int)(search_cursor/search_side)-search_radius);
    if(search_cursor<search_candidates)return;
    unsigned best=0;
    for(unsigned i=1;i<search_candidates;i++)if(scores[i]>scores[best])best=i;
    int dx=(int)(best%search_side)-search_radius,dy=(int)(best/search_side)-search_radius;
    float second=-2.f;
    for(unsigned i=0;i<search_candidates;i++) {
        int x=(int)(i%search_side)-search_radius-dx,y=(int)(i/search_side)-search_radius-dy;
        if(x*x+y*y>=9 && scores[i]>second)second=scores[i];
    }
    quality=fmaxf(0.f,fminf(1.f,scores[best]));
    if(scores[best]<.75f){missed(LOW_MATCH,f,now);return;}
    if(scores[best]-second<.02f){missed(AMBIGUOUS_MATCH,f,now);return;}
    if(dx==-search_radius || dx==search_radius || dy==-search_radius || dy==search_radius) {
        missed(SEARCH_EDGE,f,now);return;
    }
    dx+=predict_x;dy+=predict_y;
    if(box_now[0]+dx*(int)SCALE<0 || box_now[1]+dy*(int)SCALE<0 ||
       box_now[2]+dx*(int)SCALE>AV_VIDEO_WIDTH || box_now[3]+dy*(int)SCALE>AV_VIDEO_HEIGHT) {
        missed(BOX_OUTSIDE,f,now);return;
    }
    origin_x+=dx;origin_y+=dy;
    box_now[0]+=dx*(int)SCALE;box_now[2]+=dx*(int)SCALE;
    box_now[1]+=dy*(int)SCALE;box_now[3]+=dy*(int)SCALE;
    motion_x=dx;motion_y=dy;motion_dt=f->timestamp-last_processed;
    /* Adapt only unique, strong matches, never a failed/recovery frame.
     * Low texture and ambiguity gates remain unchanged. */
    if(!misses && scores[best]>=.90f && scores[best]-second>=.08f) {
        t_sum=t_variance=0;
        for(unsigned i=0;i<npoints;i++) {
            unsigned current=f->gray[(origin_y+sample_y[i])*WIDTH+origin_x+sample_x[i]];
            float v=template_pixels[i]=(uint8_t)((template_pixels[i]+current+1u)/2u);
            t_sum+=v;t_variance+=v*v;
        }
        t_variance-=t_sum*t_sum/npoints;
    }
    if(misses)recovered++;
    misses=0;current_reason=TRACK_OK;reacquire_started=0;
    quality=fminf(1.f,scores[best]);last_processed=last_checked=f->timestamp;last_sequence=f->sequence;
    memcpy(f->box,box_now,sizeof f->box);f->tracked=1;tracked_frames++;processing=0;
    /* Replay historical images to catch up to SSD's capture time, but never
     * move the camera from that backlog. Only a recent latest frame can drive. */
    if(search_slot==head && now>=f->timestamp && now-f->timestamp<=500000u)
        servo_tracking_observe(bird_score,box_now,f->sequence,f->timestamp,now);
}
void visual_tracker_status(uint32_t words[16],uint64_t now) {
    uint64_t age=confirmed && now>=confirmed?(now-confirmed)/1000u:UINT64_MAX;
    words[0]=0x54524b32u;words[1]=1;words[2]=active;words[3]=1; /* PS NCC */
    words[4]=tracked_frames;words[5]=losses;words[6]=age>UINT32_MAX?UINT32_MAX:(uint32_t)age;
    words[7]=(uint32_t)(quality*1000000.f+.5f);words[8]=last_sequence;words[9]=processing;
    uint64_t frame_age=last_processed && now>=last_processed?(now-last_processed)/1000u:UINT64_MAX;
    unsigned visible=active && !misses && age<=CONFIRM_US/1000u && frame_age<=VISUAL_TRACKER_FRAME_US/1000u;
    words[10]=visible?(uint32_t)(bird_score*1000000.f+.5f):0;
    words[11]=frame_age>UINT32_MAX?UINT32_MAX:(uint32_t)frame_age;
    for(unsigned i=0;i<4;i++)words[12+i]=visible?(uint32_t)(box_now[i]*1000.f+.5f):0;
}
void visual_tracker_diagnostic(uint32_t words[16],uint64_t now) {
    uint64_t age=last_processed && now>=last_processed?(now-last_processed)/1000u:UINT64_MAX;
    words[0]=0x54524b33u;words[1]=1;words[2]=active?(misses?2u:1u):0u;
    words[3]=misses;words[4]=current_reason;words[5]=last_loss_reason;
    words[6]=CONFIRM_US/1000u;words[7]=VISUAL_TRACKER_REACQUIRE_US/1000u;
    words[8]=recovered;words[9]=active?(uint32_t)(bird_score*1000000.f+.5f):0u;
    words[10]=age>UINT32_MAX?UINT32_MAX:(uint32_t)age;
    for(unsigned i=0;i<4;i++)words[11+i]=active?(uint32_t)(box_now[i]*1000.f+.5f):0u;
    words[15]=VISUAL_TRACKER_MAX_MISSES;
}
