"""Fresh initial acquisition and exact reverse-motion retry; no relaxed gates."""
MARK='/* M44 fresh acquisition and symmetric reversal search. */\n'
def apply(text):
    pairs=[
    ('enum {MOTION_NORMAL,MOTION_EXPANDED,MOTION_REFINE,MOTION_SCALE};',
     'enum {MOTION_NORMAL,MOTION_EXPANDED,MOTION_REFINE,MOTION_SCALE,MOTION_RECENTER};\n'
     'static unsigned acquire_catchup;\nstatic float reverse_scores[2];\n'
     'static int reverse_x[2],reverse_y[2];'),
    ('    active=processing=misses=0;confirmed=',
     '    acquire_catchup=0;\n    active=processing=misses=0;confirmed='),
    ('    quality=1;bird_score=score;misses=0;current_reason=TRACK_OK;reacquire_started=0;',
     '    quality=1;bird_score=score;misses=0;current_reason=TRACK_OK;reacquire_started=0;\n'
     '    acquire_catchup=now>=seed_captured && now-seed_captured>VISUAL_SERVO_POSITION_MAX_AGE_US;\n'
     '    servo_tracking_visual_acquired(captured,now);'),
    ('*scale=motion_phase==MOTION_NORMAL?1u:hypothesis%3u;',
     '*scale=(motion_phase==MOTION_NORMAL || motion_phase==MOTION_RECENTER)?1u:hypothesis%3u;'),
    ('    else if(motion_phase==MOTION_EXPANDED){*dx=x*3;*dy=y*3;}',
     '    else if(motion_phase==MOTION_RECENTER){*dx=x;*dy=y;}\n'
     '    else if(motion_phase==MOTION_EXPANDED){*dx=x*3;*dy=y*3;}'),
    ('side*side*(phase==MOTION_NORMAL?1u:phase==MOTION_REFINE?6u:3u)',
     'side*side*((phase==MOTION_NORMAL || phase==MOTION_RECENTER)?1u:phase==MOTION_REFINE?6u:3u)'),
    ('        if(!found)return;\n        if(earliest-last_checked>600000u){lost(FRAME_GAP);return;}',
     '''        if(!found)return;
        unsigned fresh_catchup=acquire_catchup && history[head].valid &&
            history[head].timestamp>last_checked && now>=history[head].timestamp &&
            now-history[head].timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US;
        if(fresh_catchup){search_slot=head;earliest=history[head].timestamp;}
        if(earliest-last_checked>600000u && !fresh_catchup){lost(FRAME_GAP);return;}'''),
    ('            motion_retry_frames++;motion_stage(MOTION_EXPANDED,25u);return;',
     '''            if(predict_x || predict_y) {
                /* Retain the two independent normal-window peaks. A reversed
                 * search must not hide a known competing target. */
                unsigned other=best;float competitor=-3.f;
                for(unsigned i=0;i<motion_candidates;i++) {
                    int x,y;unsigned s;motion_candidate(i,&x,&y,&s);
                    x-=dx;y-=dy;
                    if(x*x+y*y>=9 && scores[i]>competitor){competitor=scores[i];other=i;}
                }
                reverse_scores[0]=scores[best];reverse_x[0]=dx;reverse_y[0]=dy;
                reverse_scores[1]=competitor;
                unsigned s;motion_candidate(other,&reverse_x[1],&reverse_y[1],&s);
                motion_stage(MOTION_RECENTER,(unsigned)(2*search_radius+1));return;
            }
            motion_retry_frames++;motion_stage(MOTION_EXPANDED,25u);return;'''),
    ('    if(motion_phase==MOTION_EXPANDED) {\n        unsigned plane=',
     '''    if(motion_phase==MOTION_RECENTER) {
        for(unsigned i=0;i<2;i++) {
            int x=reverse_x[i]-dx,y=reverse_y[i]-dy;
            if(x*x+y*y>=9 && reverse_scores[i]>second)second=reverse_scores[i];
        }
        if(!(scores[best]>=.75f && scores[best]-second>=.02f &&
             dx>-search_radius && dx<search_radius && dy>-search_radius && dy<search_radius)) {
            motion_retry_frames++;motion_stage(MOTION_EXPANDED,25u);return;
        }
    }
    if(motion_phase==MOTION_EXPANDED) {
        unsigned plane='''),
    ('    misses=0;current_reason=TRACK_OK;reacquire_started=0;\n    quality=fminf',
     '    acquire_catchup=0;\n    misses=0;current_reason=TRACK_OK;reacquire_started=0;\n    quality=fminf')]
    for old,new in pairs:
        assert text.count(old)==1,(old,text.count(old))
        text=text.replace(old,new,1)
    return MARK+text
