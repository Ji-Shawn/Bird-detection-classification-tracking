"""Fresh formal NCC handoff and latest-frame bounded reacquisition.

An identity becomes control-ready only from a current seed or a successful
job that started on the latest complete image. Historical SSD replay cannot
grant readiness. A newer camera head arriving during that job is harmless.
"""
MARK='/* M47 fresh formal NCC handoff and recovery scheduling. */\n'

def apply(text):
    pairs=[
        ('static unsigned acquire_catchup;', '''static unsigned acquire_catchup;
/* These fields belong to the current NCC identity, not an SSD candidate.
 * Reset/seed cancels processing before replacing identity; no job survives
 * that boundary. Miss/pause revoke readiness but retain monotonic guards. */
static unsigned control_ready,control_live_job;
static uint64_t control_last_capture;
static uint32_t control_last_sequence;
static void control_handoff_reset(void) {
    control_ready=control_live_job=0;
    control_last_capture=0;control_last_sequence=0;
}'''),
        ('static void small_leave_ncc(void) {\n',
         'static void small_leave_ncc(void) {\n    control_handoff_reset();\n'),
        ('static void reset_track(void) {\n',
         'static void reset_track(void) {\n    control_handoff_reset();\n'),
        ('    misses++;current_reason=why;processing=0;last_checked=f->timestamp;',
         '    control_ready=control_live_job=0;\n    misses++;current_reason=why;processing=0;last_checked=f->timestamp;'),
        ('    if(active)reset_track();\n    int x1=',
         '    control_handoff_reset();\n    if(active)reset_track();\n    int x1='),
        ('    active=1;confirmed=captured;last_processed=last_checked=seed_captured;last_sequence=seed_sequence;',
         '''    control_last_capture=seed_captured;control_last_sequence=seed_sequence;
    active=1;confirmed=captured;last_processed=last_checked=seed_captured;last_sequence=seed_sequence;'''),
        ('        servo_tracking_track(bird_score,box_now,seed_sequence,seed_captured,now);',
         '        control_ready=1;\n        servo_tracking_track(bird_score,box_now,seed_sequence,seed_captured,now);'),
        ('        unsigned fresh_catchup=(acquire_catchup ||',
         '        unsigned fresh_catchup=(acquire_catchup || misses ||'),
        ('        motion_known_reset();\n        processing=1;search_radius=',
         '''        /* Choose once at the job boundary. A new head never restarts
         * a nonexpired scoring job, so continuous capture cannot starve it. */
        control_live_job=search_slot==head;
        motion_known_reset();
        processing=1;search_radius='''),
        ('    if(search_slot==head && now>=f->timestamp && now-f->timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US) {\n        roi_hint_note',
         '''    uint32_t control_delta=f->sequence-control_last_sequence;
    if((control_ready || control_live_job) && f->timestamp>control_last_capture &&
       control_delta && control_delta<0x80000000u && now>=f->timestamp &&
       now-f->timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US) {
        /* Publish the validated immutable image, even if head advanced while
         * scoring. Capture time is never rewritten to the completion time. */
        control_ready=1;control_last_capture=f->timestamp;control_last_sequence=f->sequence;
        roi_hint_note'''),
        ('    processing=0;acquire_catchup=active;video_recovery_paused=active;',
         '    control_ready=control_live_job=0;\n    processing=0;acquire_catchup=active;video_recovery_paused=active;'),
    ]
    for old,new in pairs:
        assert text.count(old)==1,(old,text.count(old))
        text=text.replace(old,new,1)
    return MARK+text
