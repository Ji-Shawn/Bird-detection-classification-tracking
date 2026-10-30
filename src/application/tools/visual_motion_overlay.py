"""M36 bounded same-frame motion/scale NCC and trajectory-aligned SSD refresh.

Applied after M35's continuous-control overlay. The SSD association/confirmation
gate, frame history and latest-frame 500 ms servo gate are unchanged. Every poll
still evaluates at most 64 candidate correlations. Expanded retry is completed
against the SAME immutable sequence/timestamp before declaring a missed frame.
"""

EXTRA_STATE = r'''
/* Scale is dimensionless relative to the currently validated template. */
enum {MOTION_NORMAL,MOTION_EXPANDED,MOTION_REFINE,MOTION_SCALE};
static unsigned motion_phase,motion_side,motion_candidates;
static float motion_scale=1.f,motion_seed_width,motion_seed_height;
static float motion_scales[3],motion_outer_second;
static int16_t motion_sample_x[3][GRID*GRID],motion_sample_y[3][GRID*GRID];
static int motion_min_x[3],motion_max_x[3],motion_min_y[3],motion_max_y[3];
static int motion_centers_x[6],motion_centers_y[6];
static unsigned motion_retry_frames,motion_scaled_frames,motion_aligned_ssd;
static uint64_t motion_last_revalidation;
'''

NEW_CORRELATION = r'''static void motion_samples(void) {
    for(unsigned s=0;s<3;s++) {
        motion_scales[s]=motion_scale*(s==0?.9f:s==1?1.f:1.1f);
        motion_min_x[s]=motion_min_y[s]=INT_MAX;
        motion_max_x[s]=motion_max_y[s]=INT_MIN;
        for(unsigned i=0;i<npoints;i++) {
            int x=(int)roundf(sample_x[i]*motion_scales[s]);
            int y=(int)roundf(sample_y[i]*motion_scales[s]);
            motion_sample_x[s][i]=(int16_t)x;motion_sample_y[s][i]=(int16_t)y;
            if(x<motion_min_x[s])motion_min_x[s]=x;
            if(x>motion_max_x[s])motion_max_x[s]=x;
            if(y<motion_min_y[s])motion_min_y[s]=y;
            if(y>motion_max_y[s])motion_max_y[s]=y;
        }
    }
}
static float motion_correlation(const track_frame *f,int dx,int dy,unsigned scale) {
    float cx_box=(box_now[0]+box_now[2])*.5f+dx*(int)SCALE;
    float cy_box=(box_now[1]+box_now[3])*.5f+dy*(int)SCALE;
    float w=motion_seed_width*motion_scales[scale],h=motion_seed_height*motion_scales[scale];
    if(w<96.f || h<96.f || cx_box-w*.5f<0 || cy_box-h*.5f<0 ||
       cx_box+w*.5f>AV_VIDEO_WIDTH || cy_box+h*.5f>AV_VIDEO_HEIGHT)return -2.f;
    int cx=origin_x+dx,cy=origin_y+dy;
    if(cx+motion_min_x[scale]<0 || cx+motion_max_x[scale]>=(int)WIDTH ||
       cy+motion_min_y[scale]<0 || cy+motion_max_y[scale]>=(int)HEIGHT)return -2.f;
    uint32_t sum=0,square=0,dot=0;
    for(unsigned i=0;i<npoints;i++) {
        unsigned v=f->gray[(cy+motion_sample_y[scale][i])*WIDTH+cx+motion_sample_x[scale][i]];
        sum+=v;square+=v*v;dot+=v*template_pixels[i];
    }
    float variance=(float)square-(float)sum*sum/npoints;
    if(variance<25.f*npoints)return -2.f;
    return ((float)dot-t_sum*sum/npoints)/sqrtf(t_variance*variance);
}
static void motion_candidate(unsigned index,int *dx,int *dy,unsigned *scale) {
    unsigned plane=motion_side*motion_side;
    unsigned hypothesis=index/plane;
    *scale=motion_phase==MOTION_NORMAL?1u:hypothesis%3u;
    unsigned local=index%plane;
    int x=(int)(local%motion_side)-(int)(motion_side/2u);
    int y=(int)(local/motion_side)-(int)(motion_side/2u);
    if(motion_phase==MOTION_NORMAL){*dx=predict_x+x;*dy=predict_y+y;}
    else if(motion_phase==MOTION_EXPANDED){*dx=x*3;*dy=y*3;}
    else {*dx=motion_centers_x[hypothesis]+x;*dy=motion_centers_y[hypothesis]+y;}
}
static void motion_stage(unsigned phase,unsigned side) {
    motion_phase=phase;motion_side=side;search_cursor=0;
    motion_candidates=side*side*(phase==MOTION_NORMAL?1u:phase==MOTION_REFINE?6u:3u);
}
static unsigned motion_best(float *second) {
    unsigned best=0;int bx,by;unsigned bs;
    for(unsigned i=1;i<motion_candidates;i++)if(scores[i]>scores[best])best=i;
    motion_candidate(best,&bx,&by,&bs);
    /* Quantized normalized offsets can alias adjacent sizes. Prefer the
     * current size for effectively equal, co-located scores to prevent jitter. */
    if(bs!=1u)for(unsigned i=0;i<motion_candidates;i++) {
        int x,y;unsigned s;motion_candidate(i,&x,&y,&s);x-=bx;y-=by;
        if(s==1u && x*x+y*y<=4 && scores[i]>=scores[best]-.002f){best=i;break;}
    }
    motion_candidate(best,&bx,&by,&bs);*second=-2.f;
    for(unsigned i=0;i<motion_candidates;i++) {
        int x,y;unsigned s;motion_candidate(i,&x,&y,&s);
        x-=bx;y-=by;
        /* Different scales of the same location are one spatial hypothesis. */
        if(x*x+y*y>=9 && scores[i]>*second)*second=scores[i];
    }
    return best;
}
'''

REVALIDATE = r'''/* Apply an old SSD's residual to the CURRENT tracked trajectory.
 * The original capture frame is needed for association; the current exact
 * head is needed for image validation. Raw delayed coordinates never drive.
 * Limit each refresh to 24 source pixels of center correction and 2.5% size. */
static void motion_revalidate(const track_frame *capture,const float box[4],uint64_t now) {
    if(misses || !have_frame || capture->timestamp<=motion_last_revalidation)return;
    motion_last_revalidation=capture->timestamp;
    track_frame *f=&history[head];
    if(!f->valid || !f->tracked || f->sequence!=last_sequence || f->timestamp!=last_processed ||
       now<f->timestamp || now-f->timestamp>VISUAL_SERVO_POSITION_MAX_AGE_US)return;
    float w=box_now[2]-box_now[0],h=box_now[3]-box_now[1];
    float cw=capture->box[2]-capture->box[0],ch=capture->box[3]-capture->box[1];
    if(cw<=0 || ch<=0)return;
    float dx=(box[0]+box[2]-capture->box[0]-capture->box[2])*.5f;
    float dy=(box[1]+box[3]-capture->box[1]-capture->box[3])*.5f;
    float cx=(box_now[0]+box_now[2])*.5f+fmaxf(-24.f,fminf(24.f,dx*.25f));
    float cy=(box_now[1]+box_now[3])*.5f+fmaxf(-24.f,fminf(24.f,dy*.25f));
    w*=1.f+.25f*(fmaxf(.9f,fminf(1.1f,(box[2]-box[0])/cw))-1.f);
    h*=1.f+.25f*(fmaxf(.9f,fminf(1.1f,(box[3]-box[1])/ch))-1.f);
    float mapped[4]={cx-w*.5f,cy-h*.5f,cx+w*.5f,cy+h*.5f};
    if(mapped[0]<0 || mapped[1]<0 || mapped[2]>AV_VIDEO_WIDTH || mapped[3]>AV_VIDEO_HEIGHT ||
       w<96.f || h<96.f || candidate_appearance(capture,box,f,mapped)<.85f)return;
    int ox=(int)roundf(cx/SCALE),oy=(int)roundf(cy/SCALE);
    int8_t xs[GRID*GRID],ys[GRID*GRID];uint8_t values[GRID*GRID];
    float sum=0,variance=0;
    for(unsigned y=0;y<GRID;y++)for(unsigned x=0;x<GRID;x++) {
        unsigned i=y*GRID+x;
        int px=(int)((mapped[0]+(x+.5f)*w/GRID)/SCALE);
        int py=(int)((mapped[1]+(y+.5f)*h/GRID)/SCALE);
        if(px<0 || px>=WIDTH || py<0 || py>=HEIGHT || px-ox<INT8_MIN || px-ox>INT8_MAX ||
           py-oy<INT8_MIN || py-oy>INT8_MAX)return;
        xs[i]=(int8_t)(px-ox);ys[i]=(int8_t)(py-oy);
        float v=values[i]=f->gray[py*WIDTH+px];sum+=v;variance+=v*v;
    }
    variance-=sum*sum/(GRID*GRID);
    if(variance<25.f*GRID*GRID)return;
    /* Do not disturb a perfect revalidation or its learned motion estimate. */
    float change=0;for(unsigned i=0;i<4;i++)change+=fabsf(mapped[i]-box_now[i]);
    if(change<.01f)return;
    npoints=GRID*GRID;memcpy(sample_x,xs,sizeof xs);memcpy(sample_y,ys,sizeof ys);
    memcpy(template_pixels,values,sizeof values);t_sum=sum;t_variance=variance;
    origin_x=ox;origin_y=oy;motion_seed_width=w;motion_seed_height=h;motion_scale=1.f;
    memcpy(box_now,mapped,sizeof mapped);memcpy(f->box,mapped,sizeof mapped);
    processing=0;motion_x=motion_y=0;motion_dt=0;motion_aligned_ssd++;
}
'''

NEW_POLL = r'''void visual_tracker_poll(uint64_t now) {
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
        processing=1;search_radius=misses?RECOVERY_RADIUS:RADIUS;
        search_sequence=history[search_slot].sequence;search_timestamp=earliest;
        float ratio=motion_dt && !misses?(float)(earliest-last_processed)/(float)motion_dt:0.f;
        predict_x=(int)roundf(fmaxf(-12.f,fminf(12.f,motion_x*ratio)));
        predict_y=(int)roundf(fmaxf(-12.f,fminf(12.f,motion_y*ratio)));
        motion_samples();motion_stage(MOTION_NORMAL,(unsigned)(2*search_radius+1));
        motion_outer_second=-2.f;
    }
    track_frame *f=&history[search_slot];
    if(!f->valid || f->sequence!=search_sequence || f->timestamp!=search_timestamp){lost(HISTORY_OVERWRITE);return;}
    for(unsigned k=0;k<SLICE_CANDIDATES && search_cursor<motion_candidates;k++,search_cursor++) {
        int dx,dy;unsigned scale;motion_candidate(search_cursor,&dx,&dy,&scale);
        scores[search_cursor]=motion_correlation(f,dx,dy,scale);
    }
    if(search_cursor<motion_candidates)return;
    float second;unsigned best=motion_best(&second);int dx,dy;unsigned scale;
    motion_candidate(best,&dx,&dy,&scale);
    if(motion_phase==MOTION_NORMAL) {
        int x=dx-predict_x,y=dy-predict_y;
        if(scores[best]>=.75f && scores[best]-second>=.02f &&
           x>-search_radius && x<search_radius && y>-search_radius && y<search_radius) {
            for(unsigned s=0;s<3;s++){motion_centers_x[s]=dx;motion_centers_y[s]=dy;}
            motion_outer_second=second;motion_stage(MOTION_SCALE,5u);return;
        }
        /* Retry the exact same image around the last accepted origin. This
         * includes the opposite direction when the motion prediction reverses. */
        motion_retry_frames++;motion_stage(MOTION_EXPANDED,25u);return;
    }
    if(motion_phase==MOTION_EXPANDED) {
        unsigned plane=motion_side*motion_side;
        for(unsigned s=0;s<3;s++) {
            unsigned peak=s*plane;
            for(unsigned i=peak+1;i<(s+1)*plane;i++)if(scores[i]>scores[peak])peak=i;
            unsigned unused;motion_candidate(peak,&motion_centers_x[s],&motion_centers_y[s],&unused);
            /* Refine a second spatial peak at each scale as well. Otherwise
             * coarse stride phase could hide an equally good duplicate target. */
            unsigned other=peak;float other_score=-3.f;
            for(unsigned i=s*plane;i<(s+1)*plane;i++) {
                int x,y;motion_candidate(i,&x,&y,&unused);
                x-=motion_centers_x[s];y-=motion_centers_y[s];
                if(x*x+y*y>=36 && scores[i]>other_score){other=i;other_score=scores[i];}
            }
            motion_candidate(other,&motion_centers_x[s+3u],&motion_centers_y[s+3u],&unused);
        }
        /* Preserve a competing, distant coarse peak for the refinement gate. */
        motion_outer_second=-2.f;
        for(unsigned i=0;i<motion_candidates;i++) {
            int x,y;unsigned s;motion_candidate(i,&x,&y,&s);x-=dx;y-=dy;
            if(x*x+y*y>=36 && scores[i]>motion_outer_second)motion_outer_second=scores[i];
        }
        motion_stage(MOTION_REFINE,7u);return;
    }
    if(motion_outer_second>second)second=motion_outer_second;
    quality=fmaxf(0.f,fminf(1.f,scores[best]));
    if(scores[best]<.75f){missed(LOW_MATCH,f,now);return;}
    if(scores[best]-second<.02f){missed(AMBIGUOUS_MATCH,f,now);return;}
    if(motion_phase==MOTION_REFINE && (dx<=-36 || dx>=36 || dy<=-36 || dy>=36)) {
        missed(SEARCH_EDGE,f,now);return;
    }
    float next_scale=motion_scales[scale];
    float cx=(box_now[0]+box_now[2])*.5f+dx*(int)SCALE;
    float cy=(box_now[1]+box_now[3])*.5f+dy*(int)SCALE;
    float w=motion_seed_width*next_scale,h=motion_seed_height*next_scale;
    float next_box[4]={cx-w*.5f,cy-h*.5f,cx+w*.5f,cy+h*.5f};
    if(next_box[0]<0 || next_box[1]<0 || next_box[2]>AV_VIDEO_WIDTH || next_box[3]>AV_VIDEO_HEIGHT ||
       w<96.f || h<96.f) {missed(BOX_OUTSIDE,f,now);return;}
    origin_x+=dx;origin_y+=dy;memcpy(box_now,next_box,sizeof next_box);
    motion_x=dx;motion_y=dy;motion_dt=f->timestamp-last_processed;
    if(scale!=1u)motion_scaled_frames++;
    motion_scale=next_scale;
    /* Adapt only a unique strong non-recovery match using its normalized
     * geometry. Neither an ambiguous frame nor a retry refreshes the template. */
    if(!misses && motion_phase==MOTION_SCALE && scores[best]>=.90f && scores[best]-second>=.08f) {
        t_sum=t_variance=0;
        for(unsigned i=0;i<npoints;i++) {
            unsigned current=f->gray[(origin_y+motion_sample_y[scale][i])*WIDTH+origin_x+motion_sample_x[scale][i]];
            float v=template_pixels[i]=(uint8_t)((template_pixels[i]+current+1u)/2u);
            t_sum+=v;t_variance+=v*v;
        }
        t_variance-=t_sum*t_sum/npoints;
    }
    if(misses)recovered++;
    misses=0;current_reason=TRACK_OK;reacquire_started=0;
    quality=fminf(1.f,scores[best]);last_processed=last_checked=f->timestamp;last_sequence=f->sequence;
    memcpy(f->box,box_now,sizeof f->box);f->tracked=1;tracked_frames++;processing=0;
    if(search_slot==head && now>=f->timestamp && now-f->timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US)
        servo_tracking_track(bird_score,box_now,f->sequence,f->timestamp,now);
}
'''

OLD_REFRESH = '''    if(active && f->tracked && intersection(f->box,box)>=.25f) {
        confirmed=captured;bird_score=score;return;
    }'''
NEW_REFRESH = '''    if(active && f->tracked && intersection(f->box,box)>=.25f) {
        motion_revalidate(f,box,now);
        confirmed=captured;bird_score=score;return;
    }'''
SEED = '    quality=1;bird_score=score;misses=0;current_reason=TRACK_OK;reacquire_started=0;'
NEW_SEED = SEED + '\n    motion_scale=1.f;motion_seed_width=box[2]-box[0];motion_seed_height=box[3]-box[1];motion_last_revalidation=0;'
STATE_AT = 'static uint64_t motion_dt;\n'
OBSERVER_AT = 'void visual_tracker_observe_ssd('
MARK = '/* M36 same-frame motion overlay. */\n'


def tracker(text):
    assert text.count(OLD_CORRELATION) == 1 and text.count(OLD_POLL) == 1
    assert text.count(OLD_REFRESH) == 1 and text.count(SEED) == 1
    text = text.replace(STATE_AT, STATE_AT + EXTRA_STATE, 1)
    text = text.replace(OBSERVER_AT, REVALIDATE + OBSERVER_AT, 1)
    text = text.replace(OLD_REFRESH, NEW_REFRESH, 1).replace(SEED, NEW_SEED, 1)
    text = text.replace(OLD_CORRELATION, NEW_CORRELATION, 1).replace(OLD_POLL, NEW_POLL, 1)
    # Stage-specific grids replace the old uniform square; keep the per-poll
    # budget macro and history/image code byte-for-byte unchanged.
    text = text.replace('static unsigned search_side,search_candidates;\n', '', 1)
    return MARK + text


def revert_tracker(text):
    assert text.startswith(MARK) and text.count(NEW_CORRELATION) == 1 and text.count(NEW_POLL) == 1
    text = text[len(MARK):].replace(NEW_CORRELATION, OLD_CORRELATION, 1).replace(NEW_POLL, OLD_POLL, 1)
    text = text.replace(STATE_AT + EXTRA_STATE, STATE_AT, 1).replace(REVALIDATE + OBSERVER_AT, OBSERVER_AT, 1)
    text = text.replace(NEW_REFRESH, OLD_REFRESH, 1).replace(NEW_SEED, SEED, 1)
    text = text.replace('static int search_radius;\n', 'static unsigned search_side,search_candidates;\nstatic int search_radius;\n', 1)
    return text


# Exact pre-overlay functions captured from the preserved M35 build.
OLD_CORRELATION = 'static float correlation(const track_frame *f,int dx,int dy) {\n    int cx=origin_x+dx,cy=origin_y+dy;\n    if(cx+min_x<0 || cx+max_x>=(int)WIDTH || cy+min_y<0 || cy+max_y>=(int)HEIGHT)\n        return -2.f;\n    uint32_t sum=0,square=0,dot=0;\n    for(unsigned i=0;i<npoints;i++) {\n        unsigned v=f->gray[(cy+sample_y[i])*WIDTH+cx+sample_x[i]];\n        sum+=v;square+=v*v;dot+=v*template_pixels[i];\n    }\n    float variance=(float)square-(float)sum*sum/npoints;\n    if(variance<25.f*npoints)return -2.f;\n    return ((float)dot-t_sum*sum/npoints)/sqrtf(t_variance*variance);\n}\n'
OLD_POLL = "void visual_tracker_poll(uint64_t now) {\n    if(!active)return;\n    if(now<confirmed || (have_frame && now<history[head].timestamp)) {lost(CLOCK_INVALID);return;}\n    if(now-confirmed>CONFIRM_US){lost(CONFIRM_EXPIRED);return;}\n    if(!have_frame || now-history[head].timestamp>VISUAL_TRACKER_FRAME_US){lost(VIDEO_STALE);return;}\n    if(misses && now-reacquire_started>=VISUAL_TRACKER_REACQUIRE_US){lost(current_reason);return;}\n    if(!processing) {\n        unsigned found=0;uint64_t earliest=UINT64_MAX;\n        for(unsigned i=0;i<HISTORY;i++)if(history[i].valid && history[i].timestamp>last_checked &&\n            history[i].timestamp<earliest){search_slot=i;earliest=history[i].timestamp;found=1;}\n        if(!found)return;\n        if(earliest-last_checked>600000u){lost(FRAME_GAP);return;}\n        search_cursor=0;processing=1;\n        search_radius=misses?RECOVERY_RADIUS:RADIUS;\n        search_side=(unsigned)(2*search_radius+1);search_candidates=search_side*search_side;\n        search_sequence=history[search_slot].sequence;search_timestamp=earliest;\n        /* Bound extrapolation to retain the old location in the search window.\n         * Failed frames never update velocity or refresh the confirmation. */\n        float ratio=motion_dt && !misses?(float)(earliest-last_processed)/(float)motion_dt:0.f;\n        predict_x=(int)roundf(fmaxf(-12.f,fminf(12.f,motion_x*ratio)));\n        predict_y=(int)roundf(fmaxf(-12.f,fminf(12.f,motion_y*ratio)));\n    }\n    track_frame *f=&history[search_slot];\n    if(!f->valid || f->sequence!=search_sequence || f->timestamp!=search_timestamp){lost(HISTORY_OVERWRITE);return;}\n    for(unsigned k=0;k<SLICE_CANDIDATES && search_cursor<search_candidates;k++,search_cursor++)\n        scores[search_cursor]=correlation(f,predict_x+(int)(search_cursor%search_side)-search_radius,\n                                         predict_y+(int)(search_cursor/search_side)-search_radius);\n    if(search_cursor<search_candidates)return;\n    unsigned best=0;\n    for(unsigned i=1;i<search_candidates;i++)if(scores[i]>scores[best])best=i;\n    int dx=(int)(best%search_side)-search_radius,dy=(int)(best/search_side)-search_radius;\n    float second=-2.f;\n    for(unsigned i=0;i<search_candidates;i++) {\n        int x=(int)(i%search_side)-search_radius-dx,y=(int)(i/search_side)-search_radius-dy;\n        if(x*x+y*y>=9 && scores[i]>second)second=scores[i];\n    }\n    quality=fmaxf(0.f,fminf(1.f,scores[best]));\n    if(scores[best]<.75f){missed(LOW_MATCH,f,now);return;}\n    if(scores[best]-second<.02f){missed(AMBIGUOUS_MATCH,f,now);return;}\n    if(dx==-search_radius || dx==search_radius || dy==-search_radius || dy==search_radius) {\n        missed(SEARCH_EDGE,f,now);return;\n    }\n    dx+=predict_x;dy+=predict_y;\n    if(box_now[0]+dx*(int)SCALE<0 || box_now[1]+dy*(int)SCALE<0 ||\n       box_now[2]+dx*(int)SCALE>AV_VIDEO_WIDTH || box_now[3]+dy*(int)SCALE>AV_VIDEO_HEIGHT) {\n        missed(BOX_OUTSIDE,f,now);return;\n    }\n    origin_x+=dx;origin_y+=dy;\n    box_now[0]+=dx*(int)SCALE;box_now[2]+=dx*(int)SCALE;\n    box_now[1]+=dy*(int)SCALE;box_now[3]+=dy*(int)SCALE;\n    motion_x=dx;motion_y=dy;motion_dt=f->timestamp-last_processed;\n    /* Adapt only unique, strong matches, never a failed/recovery frame.\n     * Low texture and ambiguity gates remain unchanged. */\n    if(!misses && scores[best]>=.90f && scores[best]-second>=.08f) {\n        t_sum=t_variance=0;\n        for(unsigned i=0;i<npoints;i++) {\n            unsigned current=f->gray[(origin_y+sample_y[i])*WIDTH+origin_x+sample_x[i]];\n            float v=template_pixels[i]=(uint8_t)((template_pixels[i]+current+1u)/2u);\n            t_sum+=v;t_variance+=v*v;\n        }\n        t_variance-=t_sum*t_sum/npoints;\n    }\n    if(misses)recovered++;\n    misses=0;current_reason=TRACK_OK;reacquire_started=0;\n    quality=fminf(1.f,scores[best]);last_processed=last_checked=f->timestamp;last_sequence=f->sequence;\n    memcpy(f->box,box_now,sizeof f->box);f->tracked=1;tracked_frames++;processing=0;\n    /* Replay historical images to catch up to SSD's capture time, but never\n     * move the camera from that backlog. Only a recent latest frame can drive. */\n    if(search_slot==head && now>=f->timestamp && now-f->timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US)\n        servo_tracking_track(bird_score,box_now,f->sequence,f->timestamp,now);\n}\n"
