"""M37: promote a verified current candidate only after two independent SSDs.

The existing selector/association gates decide confirmation. This overlay only
changes where the newly confirmed NCC template is established: a fresh exact
current image may replace the delayed SSD image when the candidate trajectory
has a matching same-capture checkpoint and pixel identity is revalidated.
Otherwise the original delayed-history path remains intact.
"""

MARK='/* M37 independently confirmed current-frame handoff. */\n'
STATE='''static uint32_t handoff_observed_sequence;
static uint64_t handoff_observed_captured;
'''
INSERT_AT='static uint64_t motion_dt;\n'
OBSERVER_AT='void visual_tracker_observe_ssd('
END_AT='static void motion_samples('

EARLY='''    if(box[0]<0 || box[1]<0 || box[2]>AV_VIDEO_WIDTH || box[3]>AV_VIDEO_HEIGHT ||
       box[2]-box[0]<8 || box[3]-box[1]<8)return;
'''
NEW_EARLY=EARLY+'''    if(handoff_observed_captured==captured && handoff_observed_sequence==sequence)return;
'''
FRAME='''    track_frame *f=0;
'''
NEW_FRAME='''    const float *original_ssd_box=box;
    float handoff_box[4];
    uint32_t seed_sequence=sequence;uint64_t seed_captured=captured;
    unsigned handed_off=0;
'''+FRAME
BEFORE_SEED='''    if(active)reset_track();
'''
NEW_BEFORE_SEED='''    if(!active && have_frame &&
       ssd_fast_handoff(score,box,sequence,captured,now,handoff_box,&seed_sequence,&seed_captured)) {
        track_frame *current=&history[head];
        /* Both SSD association and the current candidate have now been
         * independently validated. Never attach an old raw SSD coordinate
         * to a current image, and never seed from an unfinished image. */
        if(current->valid && current->sequence==seed_sequence && current->timestamp==seed_captured &&
           now>=seed_captured && now-seed_captured<=VISUAL_SERVO_POSITION_MAX_AGE_US &&
           candidate_appearance(f,box,current,handoff_box)>=.85f) {
            box=handoff_box;f=current;handed_off=1;
        } else {seed_sequence=sequence;seed_captured=captured;}
    }
'''+BEFORE_SEED
SEED_CLOCK='''    active=1;confirmed=last_processed=last_checked=captured;last_sequence=sequence;
'''
NEW_SEED_CLOCK='''    active=1;confirmed=captured;last_processed=last_checked=seed_captured;last_sequence=seed_sequence;
'''
FINAL='''    motion_scale=1.f;motion_seed_width=box[2]-box[0];motion_seed_height=box[3]-box[1];motion_last_revalidation=0;
'''
NEW_FINAL=FINAL+'''    if(handed_off) {
        handoff_observed_sequence=sequence;handoff_observed_captured=captured;
        /* This is now a formal fresh measurement, not a candidate. The
         * controller still enforces manual ownership, age, lease and limits. */
        servo_tracking_track(bird_score,box_now,seed_sequence,seed_captured,now);
    }
'''
FLAT='''    if(t_variance<25.f*npoints) {
        current_reason=FLAT_SEED;
        servo_tracking_observe(score,box,sequence,captured,now);return;
    }
'''
NEW_FLAT=FLAT.replace('score,box,sequence','score,original_ssd_box,sequence')
PAIRS=[(EARLY,NEW_EARLY),(FRAME,NEW_FRAME),(BEFORE_SEED,NEW_BEFORE_SEED),
       (SEED_CLOCK,NEW_SEED_CLOCK),(FINAL,NEW_FINAL),(FLAT,NEW_FLAT)]
RESET='void visual_tracker_reset(void) {\n'
NEW_RESET=RESET+'    handoff_observed_sequence=0;handoff_observed_captured=0;\n'


def tracker(text):
    a=text.index(OBSERVER_AT);b=text.index(END_AT,a)
    observer=text[a:b]
    for old,new in PAIRS:
        assert observer.count(old)==1,old
        observer=observer.replace(old,new,1)
    text=text[:a]+observer+text[b:]
    assert text.count(INSERT_AT)==1 and text.count(RESET)==1
    return MARK+text.replace(INSERT_AT,INSERT_AT+STATE,1).replace(RESET,NEW_RESET,1)


def revert_tracker(text):
    assert text.startswith(MARK)
    text=text[len(MARK):]
    a=text.index(OBSERVER_AT);b=text.index(END_AT,a)
    observer=text[a:b]
    for old,new in reversed(PAIRS):
        assert observer.count(new)==1,new
        observer=observer.replace(new,old,1)
    return (text[:a]+observer+text[b:]).replace(INSERT_AT+STATE,INSERT_AT,1).replace(NEW_RESET,RESET,1)
