"""Feed focus from the latest formal image, with exact time.

The NCC implementation is unchanged. Its read-only snapshot cannot confirm a
candidate, renew a coordinate or dispatch a servo command. Explicit manual-ROI
diagnostics retain their existing focus feed.
"""

SNAPSHOT=r'''
/* M38 focus-only view: a successful formal measurement on the latest image. */
int visual_tracker_focus_snapshot(float box[4],float *score,uint32_t *sequence,
                                  uint64_t *captured,uint64_t now) {
    if(!box || !score || !sequence || !captured || !active || misses || !have_frame ||
       !confirmed || now<confirmed || now-confirmed>CONFIRM_US)return 0;
    const track_frame *f=&history[head];
    if(!f->valid || !f->tracked || last_sequence!=f->sequence || last_processed!=f->timestamp ||
       !f->timestamp || now<f->timestamp || now-f->timestamp>VISUAL_SERVO_POSITION_MAX_AGE_US ||
       !isfinite(bird_score) || bird_score<VISUAL_BIRD_MIN_SCORE || bird_score>1.f)return 0;
    memcpy(box,box_now,sizeof box_now);*score=bird_score;*sequence=f->sequence;*captured=f->timestamp;
    return 1;
}
'''

HELPER=r'''/* A formal snapshot uses the original camera capture time, never a time
 * reconstructed from rounded telemetry age. Duplicate frames are rejected by
 * the focus consumer; a candidate or a failed match supplies no target. */
extern int visual_tracker_focus_snapshot(float [4],float *,uint32_t *,uint64_t *,uint64_t);
static void focus_current_target(uint64_t now) {
    if(capture_state!=0 || stage==9 || requested_policy>=2)return;
    float box[4],score;uint32_t sequence;uint64_t captured;
    if(!visual_tracker_focus_snapshot(box,&score,&sequence,&captured,now))return;
    board_focus_track(score,box,sequence,captured,now);
}
'''

ANCHOR='static void service_io(int idle) {\n'
POLL='    bird_focus_poll(now_us());board_focus_policy_poll(now_us());'
NEW_POLL='    focus_current_target(now_us());\n'+POLL
RAW='''        if(capture_state==0 && job_mode==requested_mode) {
            board_focus_observe(result.detector_score,result.box,now_us());
            bird_focus_observe(result.detector_score,result.box,result.video_sequence,
                               result.video_timestamp_us,now_us());
        }'''
NEW_RAW=RAW.replace('            board_focus_observe(',
                    '            if(active_policy>=2)board_focus_observe(')


def tracker(text):
    assert 'int visual_tracker_focus_snapshot(' not in text
    return text+SNAPSHOT


def revert_tracker(text):
    assert text.endswith(SNAPSHOT)
    return text[:-len(SNAPSHOT)]


def apply(text):
    for old,new in ((ANCHOR,HELPER+ANCHOR),(POLL,NEW_POLL),(RAW,NEW_RAW)):
        assert text.count(old)==1, old
        text=text.replace(old,new,1)
    return text


def revert(text):
    for old,new in reversed(((ANCHOR,HELPER+ANCHOR),(POLL,NEW_POLL),(RAW,NEW_RAW))):
        assert text.count(new)==1, new
        text=text.replace(new,old,1)
    return text
