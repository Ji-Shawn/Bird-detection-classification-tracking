"""M46 independent sound timing, preserving SND2 and all existing owners."""

def once(text, old, new):
    assert text.count(old)==1, ('M46 timing anchor', old[:120], text.count(old))
    return text.replace(old,new,1)


FUSION_COMMAND = r'''
int fusion_sound_round_tuning_command(uint32_t boot,const uint8_t *payload,unsigned bytes) {
    uint32_t before=sound_round_tuning_revision();uint64_t now=now_us();
    int result=sound_round_tuning_command(boot,payload,bytes,now);
    if(before!=sound_round_tuning_revision()) {
        sound_bird_confirm_clear(&motor_bird);direction_gate_clear(&doa_gate);
        sound_round_noise_until=0;
        servo_tracking_sound_timing_forget(now);
        sound_round_discard_ready();
    }
    return result;
}
'''


def apply_fusion(text):
    text=once(text,'static void direction_stream_poll(uint64_t now) {',
              FUSION_COMMAND+'\nstatic void direction_stream_poll(uint64_t now) {')
    text=once(text,'    stream_tuning_init();',
              '    stream_tuning_init();\n    sound_round_tuning_init(now_us());')
    text=once(text,'sound_bird_confirm_recent(&motor_bird,now,mask)',
              'sound_bird_confirm_recent_config(&motor_bird,now,mask,sound_round_current().reset_gap_ms*1000u)')
    text=once(text,'sound_bird_confirm_read(&motor_bird,now,mask)',
              'sound_bird_confirm_read_config(&motor_bird,now,mask,sound_round_current().reset_gap_ms*1000u)')
    text=once(text,'sound_bird_confirm_read(&motor_bird,sound_now,((volatile uint32_t *)FUSION_AUDIO_HEALTH)[1])',
              'sound_bird_confirm_read_config(&motor_bird,sound_now,((volatile uint32_t *)FUSION_AUDIO_HEALTH)[1],sound_round_current().reset_gap_ms*1000u)')
    text=once(text,'sound_bird_confirm_push(&motor_bird,result.audio_top1,result.confidence,\n'
              '                doa_gate.threshold_percent,result.audio_timestamp_us,now_us(),\n'
              '                ((volatile uint32_t *)FUSION_AUDIO_HEALTH)[1]);',
              'sound_bird_confirm_push_config(&motor_bird,result.audio_top1,result.confidence,\n'
              '                doa_gate.threshold_percent,result.audio_timestamp_us,now_us(),\n'
              '                ((volatile uint32_t *)FUSION_AUDIO_HEALTH)[1],\n'
              '                sound_round_current().min_gap_ms*1000u,sound_round_current().reset_gap_ms*1000u);')
    return '#include "sound_round_tuning.h"\n'+text


def apply_control(text):
    text=once(text,'    switch (p[0]) {\n',
              '    switch (p[0]) {\n    case 26:\n'
              '        return fusion_sound_round_tuning_command(service->boot_id,p,bytes)==0 ? CONTROL_APPLIED : CONTROL_REJECTED;\n')
    old='payload[0]==23u || payload[0]==24u || payload[0]==25u'
    assert text.count(old)==2, ('M46 timing control exceptions',text.count(old))
    text=text.replace(old,old+' || payload[0]==26u')
    return '#include "sound_round_tuning.h"\n'+text
