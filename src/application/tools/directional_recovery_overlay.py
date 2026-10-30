"""M42 loss search starts toward the last accepted formal image position.

Only the controller is transformed. Freshness, NCC association/retry limits,
automatic scan calibration, audio qualification and the 30-second deadline
remain unchanged. A direction is a one-use scan hint, never encoder feedback
or permission to continue an expired NCC velocity.
"""
MARK='/* M42 one-use formal vertical direction for visual loss search. */\n'
ANCHOR='static uint64_t reacquire_hold_until;\n'
STATE=r'''/* Image Y grows downward, and positive visual Y increases tilt PWM.
 * This memory only picks the first scan direction; it does not keep a stale
 * coordinate alive. Existing NCC/sparse freshness contracts remain intact. */
static int last_formal_vertical_direction;
static uint64_t formal_direction_capture,formal_direction_observed;
static unsigned recovery_directional;
static void formal_direction_forget(void) {
    last_formal_vertical_direction=0;
    formal_direction_capture=formal_direction_observed=0;
}
static void formal_direction_record(const float box[4],uint64_t captured,uint64_t now) {
    float error=(box[1]+box[3])*.5f-AV_VIDEO_HEIGHT*.5f;
    last_formal_vertical_direction=error>0.f?1:error<0.f?-1:0;
    formal_direction_capture=captured;formal_direction_observed=now;
}
static void formal_direction_time_guard(uint64_t now) {
    formal_direction_forget();
    if(!automatic)return;
    /* Invalid time cannot unlock an inherited motion guard or issue a
     * same-call scan step. Clock rollback retains the stronger existing floor. */
    uint64_t after=UINT64_MAX-now<SERVO_FRAME_US?UINT64_MAX:now+SERVO_FRAME_US;
    if(not_before<after)not_before=after;
    if(settled_after<after)settled_after=after;
}
'''

PAIRS=[
    (ANCHOR,ANCHOR+STATE,1),
    ('    reacquire_hold_until=0;\n}',
     '    reacquire_hold_until=0;recovery_directional=0;\n}',1),
    ('    if(!retry){reacquire_hold_until=0;return;}\n',
     '    if(!retry){reacquire_hold_until=0;return;}\n'
     '    /* Known-direction loss intentionally starts scanning immediately,\n'
     '     * while NCC may still run its unchanged bounded matching retries. */\n'
     '    if(recovery_directional)return;\n',1),
    ('    unsigned time_invalid=continuous.active && now<continuous.clock;\n    servo_tracking_tick(now);',
     '    unsigned time_invalid=continuous.active && now<continuous.clock;\n'
     '    if(time_invalid || now<continuous_time_floor || !captured || captured>now ||\n'
     '       (last_capture && captured<last_capture))formal_direction_time_guard(now);\n'
     '    servo_tracking_tick(now);',1),
    ('    recovery_reset();boundary_latched=0;\n    if(!continuous.active)',
     '    recovery_reset();boundary_latched=0;\n'
     '    candidate_hold_reset(); /* Formal vision supersedes the old display-only hold. */\n'
     '    formal_direction_record(box,captured,now);\n    if(!continuous.active)',1),
    ('static void start_home(void) {\n    continuous_reset();',
     'static void start_home(void) {\n    formal_direction_forget();\n    continuous_reset();',1),
    ('    scan_direction=-1;\n    reason=NO_DETECTION;sound_state=SOUND_SCANNING;',
     '    /* A bounded, one-use formal hint may remove only the inherited\n'
     '     * visual move cooldown. PL busy/acceptance and future scan cadence\n'
     '     * remain authoritative. Unknown/centered/old/time-invalid hints keep\n'
     '     * the original default direction and stationary retry behavior. */\n'
     '    recovery_directional=last_formal_vertical_direction && formal_direction_capture &&\n'
     '        clock_now>=formal_direction_capture && clock_now>=formal_direction_observed &&\n'
     '        clock_now-formal_direction_observed<=SERVO_VISUAL_FRESH_US &&\n'
     '        clock_now>=continuous_time_floor && clock_now<auto_expires;\n'
     '    scan_direction=recovery_directional?last_formal_vertical_direction:-1;\n'
     '    formal_direction_forget();\n'
     '    if(recovery_directional) {not_before=clock_now;settled_after=clock_now;}\n'
     '    reason=NO_DETECTION;sound_state=SOUND_SCANNING;',1),
    ('void servo_tracking_init(uint64_t now) {\n    continuous_reset();tuning_reset();',
     'void servo_tracking_init(uint64_t now) {\n    formal_direction_forget();\n    continuous_reset();tuning_reset();',1),
    ('void servo_tracking_stop(void) {\n    continuous_reset();',
     'void servo_tracking_stop(void) {\n    formal_direction_forget();\n    continuous_reset();',1),
    ('    recovery_reset();boundary_latched=0;had_visual=0;external_visual=0;detection[3]=0;ncc_detection=0;',
     '    formal_direction_forget();\n'
     '    recovery_reset();boundary_latched=0;had_visual=0;external_visual=0;detection[3]=0;ncc_detection=0;',1),
    ('    unsigned expired=automatic && now>=auto_expires;\n    servo_tracking_tick(now);',
     '    unsigned expired=automatic && now>=auto_expires;\n'
     '    if(now<continuous_time_floor || !captured || captured>now ||\n'
     '       (last_capture && captured<last_capture))formal_direction_time_guard(now);\n'
     '    servo_tracking_tick(now);',1),
    ('    unsigned recovering=recovery_scanning;\n    if(!recovering)',
     '    formal_direction_record(box,captured,now);\n'
     '    unsigned recovering=recovery_scanning;\n    if(!recovering)',1),
    ('    if(captured<settled_after){hits=0;reason=WAIT_POST_MOTION;return;}\n',
     '    if(captured<settled_after){hits=0;reason=WAIT_POST_MOTION;return;}\n'
     '    candidate_hold_reset(); /* A post-motion formal SSD may now take ownership. */\n',1),
]


def change(text,reverse=False):
    for old,new,count in (reversed(PAIRS) if reverse else PAIRS):
        if reverse:old,new=new,old
        assert text.count(old)==count,(old,text.count(old),count)
        text=text.replace(old,new)
    return text


def controller(text):
    return MARK+change(text)


def revert_controller(text):
    assert text.startswith(MARK)
    return change(text[len(MARK):],True)
