"""M37 authoritative same-size NCC fast path and spatially sound retry gate.

A valid unique normal match is a complete measurement. Optional scale recovery
must not veto it or defer publication. The original low-texture, .75 correlation,
.02 uniqueness, history, capture freshness and SSD association gates remain.
"""
from visual_motion_overlay import NEW_POLL as MOTION_POLL

OLD_NORMAL = '''        if(scores[best]>=.75f && scores[best]-second>=.02f &&
           x>-search_radius && x<search_radius && y>-search_radius && y<search_radius) {
            for(unsigned s=0;s<3;s++){motion_centers_x[s]=dx;motion_centers_y[s]=dy;}
            motion_outer_second=second;motion_stage(MOTION_SCALE,5u);return;
        }
        /* Retry the exact same image around the last accepted origin. This
         * includes the opposite direction when the motion prediction reverses. */
        motion_retry_frames++;motion_stage(MOTION_EXPANDED,25u);return;'''
NEW_NORMAL = '''        if(!(scores[best]>=.75f && scores[best]-second>=.02f &&
             x>-search_radius && x<search_radius && y>-search_radius && y<search_radius)) {
            /* Only a failed normal match pays for scale/expanded recovery.
             * Its immutable frame/sequence is retained throughout retry. */
            motion_retry_frames++;motion_stage(MOTION_EXPANDED,25u);return;
        }
        /* Authoritative 1x match: publish now. A neighboring scale is never
         * allowed to reject this already valid position or alter its size. */'''

OLD_OUTER = '''            if(x*x+y*y>=36 && scores[i]>motion_outer_second)motion_outer_second=scores[i];'''
NEW_OUTER = '''            if(x*x+y*y>=36 && scores[i]>motion_outer_second) {
                motion_outer_second=scores[i];
                motion_outer_x=x+dx;motion_outer_y=y+dy;
            }'''

OLD_SECOND = '''    if(motion_outer_second>second)second=motion_outer_second;'''
NEW_SECOND = '''    /* Coarse and refined winners can differ. Recheck the competitor's
     * location relative to the FINAL winner, rather than comparing a detached
     * old score belonging to the same target. The 3-cell exclusion is original. */
    int outer_dx=motion_outer_x-dx,outer_dy=motion_outer_y-dy;
    if(motion_outer_second>second && outer_dx*outer_dx+outer_dy*outer_dy>=9)
        second=motion_outer_second;'''

OLD_ADAPT = '''if(!misses && motion_phase==MOTION_SCALE && scores[best]>=.90f && scores[best]-second>=.08f)'''
NEW_ADAPT = '''if(!misses && motion_phase==MOTION_NORMAL && !background_scale && scores[best]>=.90f && scores[best]-second>=.08f)'''

BACKGROUND=r'''/* Independent geometry maintenance never invalidates an accepted position.
 * At most one 75-candidate check per 200 ms capture time. A new camera frame
 * preempts it; neither a failed check nor a new scale is another observation. */
static void stable_template_adapt(const track_frame *f,unsigned scale) {
    t_sum=t_variance=0;
    for(unsigned i=0;i<npoints;i++) {
        unsigned current=f->gray[(origin_y+motion_sample_y[scale][i])*WIDTH+origin_x+motion_sample_x[scale][i]];
        float v=template_pixels[i]=(uint8_t)((template_pixels[i]+current+1u)/2u);
        t_sum+=v;t_variance+=v*v;
    }
    t_variance-=t_sum*t_sum/npoints;
}
static void stable_scale_finish(track_frame *f,float best,float second,int dx,int dy,unsigned scale) {
    processing=0;
    unsigned changed=0;
    if(scale!=1u && best>=.75f && best-second>=.02f && best>=stable_scale_reference+.03f) {
        float next_scale=motion_scales[scale];
        float cx=(box_now[0]+box_now[2])*.5f+dx*(int)SCALE;
        float cy=(box_now[1]+box_now[3])*.5f+dy*(int)SCALE;
        float w=motion_seed_width*next_scale,h=motion_seed_height*next_scale;
        float box[4]={cx-w*.5f,cy-h*.5f,cx+w*.5f,cy+h*.5f};
        if(w>=96.f && h>=96.f && box[0]>=0 && box[1]>=0 &&
           box[2]<=AV_VIDEO_WIDTH && box[3]<=AV_VIDEO_HEIGHT) {
            origin_x+=dx;origin_y+=dy;motion_scale=next_scale;
            memcpy(box_now,box,sizeof box);memcpy(f->box,box,sizeof box);motion_scaled_frames++;
            changed=1;
        }
    }
    /* Defer adaptation so optional scale scores use one unchanged template.
     * Even when no new size wins (or a new frame preempts the job), complete
     * the already accepted strong normal measurement's original adaptation. */
    if(!stable_scale_was_recovery) {
        if(changed) {
            if(best>=.90f && best-second>=.08f)stable_template_adapt(f,scale);
        } else if(stable_scale_reference>=.90f && stable_scale_margin>=.08f)
            stable_template_adapt(f,1u);
    }
}
'''

OLD_RESULT='''    motion_candidate(best,&dx,&dy,&scale);
    if(motion_phase==MOTION_NORMAL) {'''
NEW_RESULT='''    motion_candidate(best,&dx,&dy,&scale);
    if(motion_phase==MOTION_SCALE) {
        stable_scale_finish(f,scores[best],second,dx,dy,scale);return;
    }
    if(motion_phase==MOTION_NORMAL) {'''
OLD_GEOMETRY='''    float next_scale=motion_scales[scale];'''
NEW_GEOMETRY='''    unsigned background_scale=motion_phase==MOTION_NORMAL && scores[best]<.995f &&
        search_slot==head && now>=f->timestamp && now-f->timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US &&
        (!stable_last_scale || (f->timestamp>=stable_last_scale && f->timestamp-stable_last_scale>=200000u));
    unsigned was_recovery=misses!=0;
    float next_scale=motion_scales[scale];'''
OLD_END='''        servo_tracking_track(bird_score,box_now,f->sequence,f->timestamp,now);
}'''
NEW_END='''        servo_tracking_track(bird_score,box_now,f->sequence,f->timestamp,now);
    if(background_scale) {
        stable_last_scale=f->timestamp;stable_scale_reference=quality;
        stable_scale_margin=scores[best]-second;stable_scale_was_recovery=was_recovery;
        for(unsigned s=0;s<3;s++)motion_centers_x[s]=motion_centers_y[s]=0;
        motion_samples();motion_outer_second=-2.f;processing=1;motion_stage(MOTION_SCALE,5u);
    }
}'''

STABLE_POLL=MOTION_POLL.replace(OLD_NORMAL,NEW_NORMAL,1).replace(OLD_OUTER,NEW_OUTER,1)
STABLE_POLL=STABLE_POLL.replace(OLD_SECOND,NEW_SECOND,1).replace(OLD_ADAPT,NEW_ADAPT,1)
STABLE_POLL=STABLE_POLL.replace('    if(!active)return;','''    if(!active)return;
    if(processing && motion_phase==MOTION_SCALE && search_slot!=head) {
        track_frame *previous=&history[search_slot];
        if(previous->valid && previous->sequence==search_sequence && previous->timestamp==search_timestamp)
            stable_scale_finish(previous,-2.f,-2.f,0,0,1u);
        else processing=0;
    }''',1)
STABLE_POLL=STABLE_POLL.replace(OLD_RESULT,NEW_RESULT,1).replace(OLD_GEOMETRY,NEW_GEOMETRY,1)
STABLE_POLL=STABLE_POLL.replace(OLD_END,NEW_END,1)
STATE='static float motion_scales[3],motion_outer_second;\n'
NEW_STATE=STATE+'''static int motion_outer_x,motion_outer_y;
static uint64_t stable_last_scale;
static float stable_scale_reference,stable_scale_margin;
static unsigned stable_scale_was_recovery;
'''
MARK='/* M37 stable authoritative NCC overlay. */\n'
RESET='void visual_tracker_reset(void) {\n'
NEW_RESET=RESET+'    stable_last_scale=0;stable_scale_reference=stable_scale_margin=0;stable_scale_was_recovery=0;\n'


def tracker(text):
    assert text.count(MOTION_POLL)==1 and text.count(STATE)==1
    for old in (OLD_NORMAL,OLD_OUTER,OLD_SECOND,OLD_ADAPT):
        assert MOTION_POLL.count(old)==1
    text=text.replace(MOTION_POLL,BACKGROUND+STABLE_POLL,1).replace(STATE,NEW_STATE,1)
    return MARK+text.replace(RESET,NEW_RESET,1)


def revert_tracker(text):
    assert text.startswith(MARK) and text.count(BACKGROUND+STABLE_POLL)==1 and text.count(NEW_STATE)==1
    return (text[len(MARK):].replace(BACKGROUND+STABLE_POLL,MOTION_POLL,1)
            .replace(NEW_STATE,STATE,1).replace(NEW_RESET,RESET,1))
