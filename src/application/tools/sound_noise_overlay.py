"""Only motor sound triggering uses adaptive band-energy qualification."""
PREFIX='#include "sound_energy_gate.h"\n#include "sound_bird_confirm.h"\n'
PAIRS=[
 ('static direction_gate doa_gate;', 'static direction_gate doa_gate;\nstatic sound_energy_gate motor_noise;\nstatic sound_bird_confirm motor_bird;'),
 ('requested_mode=mode;direction_gate_clear(&doa_gate);',
  'requested_mode=mode;sound_bird_confirm_clear(&motor_bird);direction_gate_clear(&doa_gate);'),
 ('    direction_gate_clear(&doa_gate);\n    *(volatile uint32_t *)FUSION_DIAG',
  '    direction_gate_clear(&doa_gate);sound_bird_confirm_clear(&motor_bird);\n    *(volatile uint32_t *)FUSION_DIAG'),
 ('int fusion_set_direction_threshold(unsigned percent){return direction_gate_threshold(&doa_gate,percent);}',
  'int fusion_set_direction_threshold(unsigned percent){if(percent>=1u && percent<=99u)sound_bird_confirm_clear(&motor_bird);return direction_gate_threshold(&doa_gate,percent);}'),
 ('        direction_gate_clear(&doa_gate);memset(out,0,sizeof *out);return 0;',
  '        direction_gate_clear(&doa_gate);sound_bird_confirm_clear(&motor_bird);memset(out,0,sizeof *out);return 0;'),
 ('    if((before&1u) || before!=p->generation)sample.valid=0;',
 '''    if((before&1u) || before!=p->generation)sample.valid=0;
    else if(sound_energy_gate_push(&motor_noise,energy,mask,sample.timestamp_us,now,
        sound_bird_confirm_recent(&motor_bird,now,mask))) {
        volatile uint32_t *diag=(volatile uint32_t *)0x30070140u;
        uint32_t floor_bits,energy_bits;
        memcpy(&floor_bits,&motor_noise.floor,4);memcpy(&energy_bits,&motor_noise.energy,4);
        diag[0]=0x534e4731u;diag[1]=motor_noise.count;diag[2]=floor_bits;diag[3]=energy_bits;
        diag[4]=sound_energy_gate_read(&motor_noise,sample.timestamp_us,now);
        diag[5]=motor_noise.passed;diag[6]=motor_noise.rejected;
        diag[7]=motor_noise.count<16u;
        diag[8]=motor_bird.streak;
        diag[9]=sound_bird_confirm_read(&motor_bird,now,mask);
        diag[10]=(uint32_t)motor_bird.end;
    }'''),
 ('        servo_tracking_sound_observe(valid,sound.angle_q9_7,sound.confidence_q0_15,',
  '        valid=valid && sound_bird_confirm_read(&motor_bird,sound_now,((volatile uint32_t *)FUSION_AUDIO_HEALTH)[1]) && sound_energy_gate_read(&motor_noise,sound.timestamp_us,sound_now);\n        servo_tracking_sound_observe(valid,sound.angle_q9_7,sound.confidence_q0_15,'),
 ('        direction_gate_accept(&doa_gate,result.audio_top1,result.confidence,',
  '''        if(requested_mode==2 && capture_state==0 && !visual_present(now_us(),0))
            sound_bird_confirm_push(&motor_bird,result.audio_top1,result.confidence,
                doa_gate.threshold_percent,result.audio_timestamp_us,now_us(),
                ((volatile uint32_t *)FUSION_AUDIO_HEALTH)[1]);
        else sound_bird_confirm_clear(&motor_bird);
        direction_gate_accept(&doa_gate,result.audio_top1,result.confidence,''')]
def apply(text):
    for a,b in PAIRS:
        assert text.count(a)==1,a
        text=text.replace(a,b,1)
    return PREFIX+text
def revert(text):
    assert text.count(PREFIX)==1
    text=text.replace(PREFIX,'',1)
    for a,b in reversed(PAIRS):
        assert text.count(b)==1,b
        text=text.replace(b,a,1)
    return text
