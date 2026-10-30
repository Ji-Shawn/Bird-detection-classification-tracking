"""M42 give real control service priority over optional species classification.

An SSD confirmation is not a PWM acceptance. Live automatic localization yields
to the main loop, then classification waits for a fresh matched control source
and an accepted command or an unblocked control opportunity. Grace is bounded;
stale positions never become fresh by waiting. Manual ROI/freeze diagnostics keep
their same-call classification path. All substitutions have exact inverses.
"""
MARK='/* M42 real control service precedes optional species classification. */\n#include "visual_classification_policy.h"\n'
OLD_STATE='static uint64_t request_start;'
NEW_STATE=OLD_STATE+'''
static uint64_t classification_control_started;
static uint64_t control_service_time,classification_busy_until;
static uint32_t control_service_epoch,classification_control_epoch;
static uint32_t classification_busy_epoch;
static unsigned classification_formal_accepted;
static unsigned classification_control_pending;
/* queued, fresh/control-ready, bypass, grace-expired, waiting epoch,
 * waiting fresh position, waiting hardware acceptance, cancelled. */
volatile uint32_t classification_priority_profile[8];'''
HELPER=r'''/* This is command acceptance/availability, never measured servo motion. */
static void classification_control_begin(uint64_t now) {
    classification_control_started=now;classification_control_epoch=control_service_epoch;
    classification_busy_until=0;classification_busy_epoch=control_service_epoch;
    classification_formal_accepted=0;
    classification_control_pending=1;classification_priority_profile[0]++;
}
static void classification_control_service(uint64_t now) {
    uint32_t before[10]={0},source[10]={0};unsigned formal=0;
    if(classification_control_pending) {
        float box[4],score;uint32_t sequence;uint64_t captured;
        servo_tracking_status(before);servo_tracking_detection(source);
        formal=before[1] && before[2] && !servo_tracking_recovery_active() &&
            visual_tracker_focus_snapshot(box,&score,&sequence,&captured,now) &&
            source[3] && source[1]==sequence;
    }
    servo_tracking_poll(now);
    control_service_time=now;control_service_epoch++;
    if(classification_control_pending && formal) {
        uint32_t after[10],current[10];
        servo_tracking_status(after);servo_tracking_detection(current);
        /* Bind acceptance to this fresh formal control service. Recovery,
         * sound and manual writes elsewhere in the wait are not evidence. */
        if(after[1] && after[2] && !servo_tracking_recovery_active() &&
           current[3] && current[1]==source[1] &&
           (after[8]!=before[8] || after[4]!=before[4]))classification_formal_accepted=1;
    }
}
static int classification_control_ready(uint64_t now) {
    if(now<classification_control_started)return -1;
    /* A real main-loop service must occur even if the time grace is exhausted. */
    if(control_service_epoch==classification_control_epoch) {
        classification_priority_profile[4]++;return 0;
    }
    uint32_t servo[10];servo_tracking_status(servo);
    if(!servo[1] || !servo[2])return 2; /* no automatic actuator owner */
    uint32_t tracker[16];visual_tracker_status(tracker,now);
    if(!tracker[2])return 2; /* small/flat seed: retain sparse SSD rules */
    float box[4],score;uint32_t sequence;uint64_t captured;
    unsigned fresh=visual_tracker_focus_snapshot(box,&score,&sequence,&captured,now);
    uint32_t detection[10];servo_tracking_detection(detection);
    fresh=fresh && detection[3] && detection[1]==sequence;
    if(fresh) {
        /* Center/deadband and mechanical limits legitimately need no write.
         * A pre-existing busy slot without new acceptance keeps its grace. */
        if(classification_formal_accepted)return 1;
        if(servo[7]&7u) {
            classification_busy_until=UINT64_MAX-now<VISUAL_SERVO_PERIOD_US?
                UINT64_MAX:now+VISUAL_SERVO_PERIOD_US;
            classification_busy_epoch=control_service_epoch;
            classification_priority_profile[6]++;
        } else if(!classification_busy_until ||
            (control_service_epoch!=classification_busy_epoch &&
             control_service_time>=classification_busy_until))return 1;
    } else classification_priority_profile[5]++;
    return now-classification_control_started>=VISUAL_CLASSIFY_CONTROL_GRACE_US?3:0;
}

'''
OLD_SERVICE='    servo_tracking_poll(servo_now);'
NEW_SERVICE='    classification_control_service(servo_now);'
OLD_INIT='    status_start=last_status=now_us();status_sequence=0;'
NEW_INIT=OLD_INIT+'''
    classification_control_pending=0;classification_control_started=0;
    control_service_epoch=classification_control_epoch=0;
    control_service_time=classification_busy_until=0;classification_busy_epoch=0;
    classification_formal_accepted=0;
    memset((void *)classification_priority_profile,0,sizeof classification_priority_profile);'''
CLASS_START='        if(active_policy==3) {'
CLASS_SPLIT='''        /* Keep the captured inference image immutable (video_state==3),
         * but return live localization to the real main-loop control service. */
        classification_control_pending=0;
        if(bird_valid && capture_state==0 && active_policy<2) {
            classification_control_begin(now_us());stage=2;
            /* Serve fresh NCC and the visual controller immediately, before
             * any species crop/preprocessing or classifier execution. */
            service_io(1);return;
        }
        stage=2;
    }
    if(stage==2) {
        if(job_mode!=requested_mode || active_policy!=requested_policy) {
            classification_control_pending=0;classification_priority_profile[7]++;
            ssd_fast_reset();video_state=stage=0;return;
        }
        if(classification_control_pending) {
            int ready=classification_control_ready(now_us());
            if(ready<0) {
                classification_control_pending=0;classification_priority_profile[7]++;
                ssd_fast_reset();video_state=stage=0;return;
            }
            if(!ready)return;
            classification_control_pending=0;classification_priority_profile[ready]++;
        }
        uint64_t start;int rc;
        if(active_policy==3) {'''
ANCHOR='static void service_io(int idle) {'

PAIRS=[(OLD_STATE,NEW_STATE),(OLD_SERVICE,NEW_SERVICE),(OLD_INIT,NEW_INIT),
       (CLASS_START,CLASS_SPLIT),(ANCHOR,HELPER+ANCHOR)]

def apply_fusion(text):
    for old,new in PAIRS:
        assert text.count(old)==1,old
        text=text.replace(old,new,1)
    return MARK+text

def revert_fusion(text):
    assert text.startswith(MARK)
    text=text[len(MARK):]
    for old,new in reversed(PAIRS):
        assert text.count(new)==1,new
        text=text.replace(new,old,1)
    return text
