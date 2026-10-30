"""Formal small-bird SSD degradation and search-only camera-space ROI hints.

Applied after the video recovery overlay. The original NCC 96-pixel geometry,
quality/uniqueness gates and servo fallback freshness/ownership rules remain.
"""

MARK='/* M44 formal small-target fallback and search-only ROI hint. */\n'


def once(text,old,new):
    assert text.count(old)==1,(old,text.count(old))
    return text.replace(old,new,1)


HELPERS=r'''
/* A hint locates a detector search only. It never becomes a control position,
 * a confirmation timestamp or an independently observed frame. */
static float roi_hint_box[4],roi_hint_score;
static uint32_t roi_hint_sequence;
static uint64_t roi_hint_captured,roi_hint_clock;
static unsigned roi_hint_valid;
static void roi_hint_clear(void) {
    roi_hint_valid=0;roi_hint_captured=roi_hint_clock=0;
    roi_hint_sequence=0;roi_hint_score=0;
}
void visual_tracker_roi_forget(void) {roi_hint_clear();}
static void roi_hint_note(float score,const float box[4],uint32_t sequence,
                          uint64_t captured,uint64_t now) {
    if(roi_hint_clock && now<roi_hint_clock){roi_hint_clear();return;}
    if(!box || !captured || captured>now || now-captured>CONFIRM_US ||
       !isfinite(score) || score<=VISUAL_BIRD_MIN_SCORE || score>1.f)return;
    for(unsigned i=0;i<4;i++)if(!isfinite(box[i]))return;
    if(box[0]<0 || box[1]<0 || box[2]>AV_VIDEO_WIDTH || box[3]>AV_VIDEO_HEIGHT ||
       box[2]-box[0]<8.f || box[3]-box[1]<8.f)return;
    if(roi_hint_valid && (captured<roi_hint_captured ||
       (captured==roi_hint_captured && sequence!=roi_hint_sequence)))return;
    memcpy(roi_hint_box,box,sizeof roi_hint_box);roi_hint_score=score;
    roi_hint_sequence=sequence;roi_hint_captured=captured;
    roi_hint_clock=now;roi_hint_valid=1;
}
int visual_tracker_roi_hint(float box[4],float *score,uint32_t *sequence,
                            uint64_t *captured,uint64_t now) {
    if(roi_hint_clock && now<roi_hint_clock){roi_hint_clear();return 0;}
    if(!box || !score || !sequence || !captured || !roi_hint_valid ||
       now<roi_hint_captured || now-roi_hint_captured>CONFIRM_US)return 0;
    roi_hint_clock=now; /* lookup clock only; original capture never changes */
    memcpy(box,roi_hint_box,sizeof roi_hint_box);*score=roi_hint_score;
    *sequence=roi_hint_sequence;*captured=roi_hint_captured;return 1;
}
/* Extra association is restricted to one small, centered shrinking proposal
 * in an already tracked SAME image. Untracked images and multiple proposals
 * retain the original identity gate and cannot arbitrarily switch birds. */
static int small_shrink_same_frame(const float old[4],const float box[4]) {
    float ow=old[2]-old[0],oh=old[3]-old[1];
    float w=box[2]-box[0],h=box[3]-box[1];
    if(ow<96.f || oh<96.f || (w>=96.f && h>=96.f))return 0;
    float sx=w/ow,sy=h/oh;
    if(sx<.25f || sy<.25f || sx>.8f || sy>.8f ||
       sx/sy<.8f || sx/sy>1.25f)return 0;
    float dx=fabsf((box[0]+box[2]-old[0]-old[2])*.5f);
    float dy=fabsf((box[1]+box[3]-old[1]-old[3])*.5f);
    return dx<=fmaxf(12.f,.1f*ow) && dy<=fmaxf(12.f,.1f*oh);
}
static void small_leave_ncc(void) {
    motion_known_reset();acquire_catchup=video_recovery_paused=0;
    active=processing=misses=0;
    confirmed=last_processed=last_checked=reacquire_started=0;
    quality=0;motion_x=motion_y=predict_x=predict_y=0;motion_dt=0;
    /* Do not start loss scanning before handing the accepted observation to
     * the existing sparse controller. That entry stops continuous correction
     * itself and enforces the original timing/lease/post-motion guards. */
    servo_tracking_reacquire(0,0,0);
}
'''


def apply_tracker(text):
    assert MARK not in text
    text=once(text,'static void reset_track(void) {',HELPERS+'\nstatic void reset_track(void) {')
    text=once(text,'void visual_tracker_reset(void) {',
              'void visual_tracker_reset(void) {\n    roi_hint_clear();')
    text=once(text,'void visual_tracker_video_pause(void) {',
              'void visual_tracker_video_pause(void) {\n    roi_hint_clear();')
    text=once(text,'    if(!active && continuation<0 && candidate_hits && f && captured>=candidate_captured &&',
              '    if(same<0 && active && f && f->tracked && candidate_count==1u && best>=0 &&\n'
              '       small_shrink_same_frame(f->box,c[best].box))same=best;\n'
              '    if(!active && continuation<0 && candidate_hits && f && captured>=candidate_captured &&')
    old='''    if(handoff_observed_captured==captured && handoff_observed_sequence==sequence)return;
    if(box[2]-box[0]<SCALE*8 || box[3]-box[1]<SCALE*8) {
        if(active)return;
        current_reason=SMALL_SEED;
        servo_tracking_observe(score,box,sequence,captured,now);return;
    }'''
    new='''    if(handoff_observed_captured==captured && handoff_observed_sequence==sequence)return;
    if(!active)roi_hint_note(score,box,sequence,captured,now);
    if(box[2]-box[0]<SCALE*8 || box[3]-box[1]<SCALE*8) {
        if(active) {
            /* Only the production association-selected SAME target may
             * demote an existing NCC identity to sparse SSD correction. */
            if(selection_sequence!=sequence || selection_captured!=captured ||
               selection_reason!=2u || !selected_index)return;
            small_leave_ncc();
        }
        roi_hint_note(score,box,sequence,captured,now);
        handoff_observed_sequence=sequence;handoff_observed_captured=captured;
        current_reason=SMALL_SEED;
        servo_tracking_observe(score,box,sequence,captured,now);return;
    }'''
    text=once(text,old,new)
    text=once(text,'        confirmed=captured;bird_score=score;return;',
              '        roi_hint_note(score,box,sequence,captured,now);\n'
              '        confirmed=captured;bird_score=score;return;')
    # A newly established formal track can be seeded from a newer independently
    # validated handoff, so its precise source timestamp becomes the hint.
    text=once(text,'    handoff_observed_sequence=sequence;handoff_observed_captured=captured;\n    if(handed_off ||',
              '    handoff_observed_sequence=sequence;handoff_observed_captured=captured;\n'
              '    roi_hint_note(score,box_now,seed_sequence,seed_captured,now);\n    if(handed_off ||')
    old='''    if(search_slot==head && now>=f->timestamp && now-f->timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US)
        servo_tracking_track(bird_score,box_now,f->sequence,f->timestamp,now);'''
    new='''    if(search_slot==head && now>=f->timestamp && now-f->timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US) {
        roi_hint_note(bird_score,box_now,f->sequence,f->timestamp,now);
        servo_tracking_track(bird_score,box_now,f->sequence,f->timestamp,now);
    }'''
    text=once(text,old,new)
    return MARK+text
