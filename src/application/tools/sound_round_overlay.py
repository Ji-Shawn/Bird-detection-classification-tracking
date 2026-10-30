"""M45 three-second audio rounds and five-second post-confirmation pause."""
def replace(text,old,new,count=1):
    assert text.count(old)==count,('sound round anchor',old[:100],text.count(old))
    return text.replace(old,new)

STATE=r'''
static uint64_t sound_round_resume,sound_round_noise_until;
static sound_round_settings sound_round_current(void) {
    uint32_t generation;uint64_t resume,after;
    sound_round_settings settings=SOUND_ROUND_SETTINGS_DEFAULTS;
    (void)sound_round_snapshot_config(
        (volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR,
        &generation,&resume,&after,&settings);
    return settings;
}
static inline int sound_round_fresh(uint64_t captured,uint64_t now) {
    uint32_t generation;uint64_t resume,after;sound_round_settings settings;
    return sound_round_snapshot_config(
        (volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR,
        &generation,&resume,&after,&settings) &&
        sound_round_result_fresh_config(captured,now,resume,after,settings.capture_ms);
}
static void sound_round_discard_ready(void) {
    fusion_audio_slot *slot=(fusion_audio_slot *)FUSION_SHARED;
    /* Core1 owns WRITING and Core0 inference owns READING. */
    if(slot->state==2u){av_memory_barrier();slot->state=0;}
}
static void sound_round_reset(void) {
    sound_round_resume=sound_round_noise_until=0;
    sound_round_publish((volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR,0);
    sound_round_discard_ready();
}
static void sound_round_begin(uint64_t accepted_now) {
    sound_round_settings settings=sound_round_current();
    sound_round_resume=sound_round_add(accepted_now,(uint64_t)settings.pause_ms*1000u);
    /* Preserve only the old noise-floor freeze, not its bird/direction votes. */
    sound_round_noise_until=motor_bird.recognized?
        sound_round_add(motor_bird.recognized,(uint64_t)settings.reset_gap_ms*1000u):0;
    sound_bird_confirm_clear(&motor_bird);direction_gate_clear(&doa_gate);
    sound_round_publish((volatile sound_round_control *)(uintptr_t)SOUND_ROUND_CONTROL_ADDR,
                        sound_round_resume);
    sound_round_discard_ready();
}
'''

def apply_fusion(text):
    text=replace(text,'/* ROI is only a detector search hint.',
        STATE+'\n/* ROI is only a detector search hint.')
    text=replace(text,'requested_mode=mode;sound_bird_confirm_clear',
        'sound_round_reset();requested_mode=mode;sound_bird_confirm_clear')
    text=replace(text,'if(action>1)return -1;capture_state=action;',
        'if(action>1)return -1;sound_round_reset();capture_state=action;')
    text=replace(text,'memset((void *)FUSION_LIVE_DIRECTION,0,64);',
        'memset((void *)FUSION_LIVE_DIRECTION,0,64);\n    sound_round_reset();')
    text=replace(text,'sound_bird_confirm_recent(&motor_bird,now,mask),',
        '(sound_bird_confirm_recent(&motor_bird,now,mask) ||\n'
        '         (mask==15u && sound_round_noise_until && now<sound_round_noise_until)),')
    text=replace(text,'uint64_t now=now_us();direction_stream_poll(now);',
        'uint64_t now=now_us();direction_stream_poll(now);\n'
        '    if(sound_round_resume && now<sound_round_resume){memset(out,0,sizeof *out);return 0;}')
    old='audio_tuning_capture_fresh(result.audio_timestamp_us,now_us())'
    text=replace(text,old,'('+old+' &&\n'
        '           sound_round_fresh(result.audio_timestamp_us,now_us()))',2)
    text=replace(text,'        servo_tracking_sound_observe(valid,sound.angle_q9_7,sound.confidence_q0_15,\n'
        '                                     sound.timestamp_us,visual_present(sound_now,0),sound_now);',
        '        uint32_t accepted_before=servo_tracking_sound_accept_sequence();\n'
        '        servo_tracking_sound_observe(valid,sound.angle_q9_7,sound.confidence_q0_15,\n'
        '                                     sound.timestamp_us,visual_present(sound_now,0),sound_now);\n'
        '        if(servo_tracking_sound_accept_sequence()!=accepted_before)sound_round_begin(sound_now);')
    text=replace(text,'        if(s->state!=2)return;',
        '        if(s->state!=2)return;\n'
        '        if(!sound_round_fresh(s->timestamp_us,now_us())) {\n'
        '            sound_round_discard_ready();return;\n'
        '        }')
    return '#include "sound_round_policy.h"\n'+text
