"""Scoped, reversible visual threshold and bounded auditory-scan hold."""
PREFIX='#include "visual_detection_policy.h"\n'
STATE='''static uint64_t candidate_hold_until;
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
    if(automatic && sound_automatic && sound_plan_active && sound_phase==SEEK_SCAN &&
       now<auto_expires)(void)candidate_hold_active(now);
}
'''
CONTROLLER=[
('SOUND_LEASE_EXPIRED,SOUND_HOMING,SOUND_SCANNING};','SOUND_LEASE_EXPIRED,SOUND_HOMING,SOUND_SCANNING,SOUND_CANDIDATE_HOLD};'),
('static void sound_advance(void);',STATE+'static void sound_advance(void);'),
('static void start_home(void) {','static void start_home(void) {\n    candidate_hold_reset();'),
('void servo_tracking_init(uint64_t now) {','void servo_tracking_init(uint64_t now) {\n    candidate_hold_reset();'),
('void servo_tracking_stop(void) {','void servo_tracking_stop(void) {\n    candidate_hold_reset();'),
('    sound_state=SOUND_SCANNING;',
 '    /* One bounded camera-still interval per candidate appearance. */\n'
 '    if(candidate_hold_active(clock_now)) {\n'
 '        sound_state=SOUND_CANDIDATE_HOLD;reason=WAIT_STABLE;return;\n'
 '    }\n'
 '    sound_state=SOUND_SCANNING;'),
('score<.5f','score<VISUAL_BIRD_MIN_SCORE'),
]
HEADER=[('void servo_tracking_sound_status(uint32_t words[8]);',
 '/* Display-only candidate pauses auditory vertical scan for a bounded 3 s. */\n'
 'void servo_tracking_sound_candidate(unsigned pending,uint64_t now);\n'
 'void servo_tracking_sound_status(uint32_t words[8]);')]
FUSION=[
('volatile float fusion_detection_threshold=0.5f;','volatile float fusion_detection_threshold=VISUAL_BIRD_MIN_SCORE;'),
('tracker[10]>=500000u','tracker[10]>=VISUAL_BIRD_MIN_SCORE_Q6'),
('ssd_fast_poll(now_us());ssd_fast_send(now_us());','ssd_fast_poll(now_us());ssd_fast_send(now_us());ssd_fast_hold_scan(now_us());'),
('        ssd_fast_send(now_us());','        ssd_fast_send(now_us());ssd_fast_hold_scan(now_us());'),
]
TRACKER=[('c->score<.5f','c->score<VISUAL_BIRD_MIN_SCORE'),
 ('if(!box || !isfinite(score) || score<.5f || score>1.f || captured>now ||',
  'if(!box || !isfinite(score) || score<VISUAL_BIRD_MIN_SCORE || score>1.f || captured>now ||')]
def change(text,pairs,reverse=False):
    for a,b in (reversed(pairs) if reverse else pairs):
        if reverse:a,b=b,a
        assert text.count(a)==1,a
        text=text.replace(a,b,1)
    return text
def controller(text):return PREFIX+change(text,CONTROLLER)
def revert_controller(text):
    assert text.startswith(PREFIX)
    return change(text[len(PREFIX):],CONTROLLER,True)
def header(text):return change(text,HEADER)
def revert_header(text):return change(text,HEADER,True)
def apply(text):return PREFIX+change(text,FUSION)
def revert(text):
    assert text.startswith(PREFIX)
    return change(text[len(PREFIX):],FUSION,True)
def tracker(text):return PREFIX+change(text,TRACKER)
def revert_tracker(text):
    assert text.startswith(PREFIX)
    return change(text[len(PREFIX):],TRACKER,True)
