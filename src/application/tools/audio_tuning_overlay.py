"""M43 RAM-only sound parameters, with reversible exact integration anchors."""


def _replace(text, old, new):
    assert text.count(old) == 1, ('M43 audio exact anchor', old[:120], text.count(old))
    return text.replace(old, new)


FUSION_THRESHOLD_OLD = 'int fusion_set_direction_threshold(unsigned percent){if(percent>=1u && percent<=99u)sound_bird_confirm_clear(&motor_bird);return direction_gate_threshold(&doa_gate,percent);}'
FUSION_THRESHOLD_NEW = r'''/* Threshold changes through either UI share one revision and invalidate all
 * pre-change classifier, direction and energy evidence. No actuator calls. */
static int audio_tuning_capture_fresh(uint64_t captured,uint64_t now) {
    uint64_t after=servo_tracking_audio_evidence_after();
    return captured && captured>after && now>=captured && now>=after;
}
static void audio_tuning_forget_fusion_evidence(void) {
    sound_bird_confirm_clear(&motor_bird);memset(&motor_noise,0,sizeof motor_noise);
    direction_gate_clear(&doa_gate);
    doa_gate.threshold_percent=(unsigned)servo_tracking_audio_value(SOUND_TUNE_THRESHOLD);
}
int fusion_set_direction_threshold(unsigned percent) {
    if(servo_tracking_audio_threshold(percent))return -1;
    audio_tuning_forget_fusion_evidence();return 0;
}
int fusion_audio_tuning_command(uint32_t boot_id,const uint8_t *payload,unsigned bytes) {
    uint32_t before=servo_tracking_audio_revision();
    int result=servo_tracking_audio_command(boot_id,payload,bytes);
    if(before!=servo_tracking_audio_revision())audio_tuning_forget_fusion_evidence();
    return result;
}'''
ENERGY_OLD = '''else if(sound_energy_gate_push(&motor_noise,energy,mask,sample.timestamp_us,now,
        sound_bird_confirm_recent(&motor_bird,now,mask))) {'''
ENERGY_NEW = '''else if(sound_energy_gate_push_config(&motor_noise,energy,mask,sample.timestamp_us,now,
        sound_bird_confirm_recent(&motor_bird,now,mask),
        servo_tracking_audio_value(SOUND_TUNE_ENERGY))) {'''

CAPTURE_OLD = 'if((before&1u) || before!=p->generation)sample.valid=0;'
CAPTURE_NEW = 'if((before&1u) || before!=p->generation || !audio_tuning_capture_fresh(sample.timestamp_us,now))sample.valid=0;'
BIRD_OLD = 'if(requested_mode==2 && capture_state==0 && !visual_present(now_us(),0))'
BIRD_NEW = 'if(requested_mode==2 && capture_state==0 && !visual_present(now_us(),0) &&\n           audio_tuning_capture_fresh(result.audio_timestamp_us,now_us()))'
DIRECTION_OLD = '''        direction_gate_accept(&doa_gate,result.audio_top1,result.confidence,
                              result.audio_timestamp_us,&audio_direction);'''
DIRECTION_NEW = '''        if(audio_tuning_capture_fresh(result.audio_timestamp_us,now_us()))
            direction_gate_accept(&doa_gate,result.audio_top1,result.confidence,
                                  result.audio_timestamp_us,&audio_direction);
        else direction_gate_clear(&doa_gate);'''


def apply_fusion(text):
    text = _replace(text, FUSION_THRESHOLD_OLD, FUSION_THRESHOLD_NEW)
    text = _replace(text, ENERGY_OLD, ENERGY_NEW)
    text = _replace(text, CAPTURE_OLD, CAPTURE_NEW)
    text = _replace(text, BIRD_OLD, BIRD_NEW)
    text = _replace(text, DIRECTION_OLD, DIRECTION_NEW)
    return '#include "sound_tuning.h"\n' + text


def revert_fusion(text):
    assert text.startswith('#include "sound_tuning.h"\n')
    text = text[len('#include "sound_tuning.h"\n'):]
    text = _replace(text, DIRECTION_NEW, DIRECTION_OLD)
    text = _replace(text, BIRD_NEW, BIRD_OLD)
    text = _replace(text, CAPTURE_NEW, CAPTURE_OLD)
    text = _replace(text, ENERGY_NEW, ENERGY_OLD)
    return _replace(text, FUSION_THRESHOLD_NEW, FUSION_THRESHOLD_OLD)


CONTROL = '''    case 24:
        return fusion_audio_tuning_command(service->boot_id,p,bytes)==0 ?
               CONTROL_APPLIED : CONTROL_REJECTED;
'''


def apply_control(text):
    text = _replace(text, '    switch (p[0]) {\n', '    switch (p[0]) {\n'+CONTROL)
    text = _replace(text, 'if (!(bytes && payload[0]==23u))',
                    'if (!(bytes && (payload[0]==23u || payload[0]==24u)))')
    text = _replace(text, 'if (bytes && payload[0]==23u) return result;',
                    'if (bytes && (payload[0]==23u || payload[0]==24u)) return result;')
    return '#include "sound_tuning.h"\n' + text


def revert_control(text):
    assert text.startswith('#include "sound_tuning.h"\n')
    text = text[len('#include "sound_tuning.h"\n'):]
    text = _replace(text, '    switch (p[0]) {\n'+CONTROL, '    switch (p[0]) {\n')
    text = _replace(text, 'if (!(bytes && (payload[0]==23u || payload[0]==24u)))',
                    'if (!(bytes && payload[0]==23u))')
    return _replace(text, 'if (bytes && (payload[0]==23u || payload[0]==24u)) return result;',
                    'if (bytes && payload[0]==23u) return result;')


TELEMETRY_MEMBER = '    uint32_t audio_tuning[16]; /* SND2 v1 RAM-only sound parameters at byte 904. */\n'
TELEMETRY_SEND = '''    uint32_t audio_tuning[16];servo_tracking_audio_status(audio_tuning,service->boot_id);
    for(unsigned i=0;i<16;i++)t.audio_tuning[i]=swap32(audio_tuning[i]);
'''


def apply_telemetry(text):
    text = _replace(text, '} telemetry_v1_t;', TELEMETRY_MEMBER+'} telemetry_v1_t;')
    text = _replace(text, 'offsetof(telemetry_v1_t,visual_tuning)==840 && sizeof(telemetry_v1_t)==904,',
                    'offsetof(telemetry_v1_t,visual_tuning)==840 &&\n'
                    '               offsetof(telemetry_v1_t,audio_tuning)==904 && sizeof(telemetry_v1_t)==968,')
    text = _replace(text, '    return udp_send_status_payload(service, sequence, &t, sizeof(t));',
                    TELEMETRY_SEND+'    return udp_send_status_payload(service, sequence, &t, sizeof(t));')
    return '#include "sound_tuning.h"\n' + text


def revert_telemetry(text):
    assert text.startswith('#include "sound_tuning.h"\n')
    text = text[len('#include "sound_tuning.h"\n'):]
    text = _replace(text, TELEMETRY_MEMBER+'} telemetry_v1_t;', '} telemetry_v1_t;')
    text = _replace(text, 'offsetof(telemetry_v1_t,visual_tuning)==840 &&\n'
                    '               offsetof(telemetry_v1_t,audio_tuning)==904 && sizeof(telemetry_v1_t)==968,',
                    'offsetof(telemetry_v1_t,visual_tuning)==840 && sizeof(telemetry_v1_t)==904,')
    return _replace(text, TELEMETRY_SEND+'    return udp_send_status_payload(service, sequence, &t, sizeof(t));',
                    '    return udp_send_status_payload(service, sequence, &t, sizeof(t));')


SERVO_PAIRS = [('#include "sound_seek_confirm.h"', '#include "sound_seek_confirm.h"\n#include "sound_tuning.h"'), ('static sound_seek_confirm sound_confirmation;\n', 'static sound_seek_confirm sound_confirmation;\n/* M43: sound settings are adopted as a single RAM-only revision. */\nstatic const float audio_defaults[8]=SOUND_TUNING_DEFAULTS;\nstatic float audio_values[8]=SOUND_TUNING_DEFAULTS;\nstatic uint64_t audio_adopted_after;\nstatic uint32_t audio_revision=1u,audio_ack_request,audio_ack_status,audio_applies,audio_cache_next;\nstatic struct {uint8_t request[46];uint32_t id,status,valid;} audio_cache[16];\nstatic void audio_reset(void) {\n    memcpy(audio_values,audio_defaults,sizeof audio_values);\n    audio_adopted_after=0;audio_revision=1u;audio_ack_request=audio_ack_status=audio_applies=audio_cache_next=0;\n    memset(audio_cache,0,sizeof audio_cache);\n}\nstatic void audio_forget_evidence(void) {\n    sound_seek_confirm_clear(&sound_confirmation);\n    sound_cutoff=audio_adopted_after=clock_now;last_sound=0;\n    /* An accepted turn/scan and visual controller keep their current owner.\n     * Only fresh post-application observations may confirm a new bearing. */\n}\nfloat servo_tracking_audio_value(unsigned i) {return i<8u?audio_values[i]:0.f;}\nuint32_t servo_tracking_audio_revision(void) {return audio_revision;}\nuint64_t servo_tracking_audio_evidence_after(void) {return audio_adopted_after;}\nint servo_tracking_audio_threshold(unsigned percent) {\n    if(percent<1u || percent>99u || audio_revision==UINT32_MAX)return -1;\n    audio_values[SOUND_TUNE_THRESHOLD]=(float)percent;audio_revision++;audio_applies++;\n    audio_forget_evidence();return 0;\n}\nstatic uint32_t audio_be32(const uint8_t *p) {\n    return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];\n}\nint servo_tracking_audio_command(uint32_t boot_id,const uint8_t *p,unsigned bytes) {\n    if(!p || bytes!=46u)return -1;\n    uint32_t request=audio_be32(p+10),status=0;\n    audio_ack_request=request;\n    if(p[0]!=24u || p[1]!=1u){audio_ack_status=2u;return -1;}\n    if(!boot_id || audio_be32(p+2)!=boot_id){audio_ack_status=3u;return -1;}\n    if(!request){audio_ack_status=5u;return -1;}\n    for(unsigned i=0;i<16u;i++)if(audio_cache[i].valid && audio_cache[i].id==request) {\n        status=memcmp(audio_cache[i].request,p,46u)?6u:audio_cache[i].status;\n        if(status==1u)status=7u;\n        audio_ack_status=status;return status==7u?0:-1;\n    }\n    float values[8];\n    const float lower[8]={1.f,2.f,513.f,2.f,300.f,600.f,3.f,5.f};\n    const float upper[8]={99.f,16.f,16384.f,30.f,1500.f,1500.f,45.f,120.f};\n    for(unsigned i=0;i<8u;i++) {\n        uint32_t bits=audio_be32(p+14+4u*i);memcpy(values+i,&bits,4);\n        if(!isfinite(values[i]) || values[i]<lower[i] || values[i]>upper[i])status=5u;\n        if((i==0u || i==2u || i==4u || i==5u) &&\n           isfinite(values[i]) && floorf(values[i])!=values[i])status=5u;\n    }\n    if(values[SOUND_TUNE_REAIM]<values[SOUND_TUNE_ACQUIRE])status=5u;\n    if(!supported)status=8u;\n    if(audio_be32(p+6)!=audio_revision || audio_revision==UINT32_MAX)status=4u;\n    if(!status) {\n        memcpy(audio_values,values,sizeof audio_values);audio_revision++;audio_applies++;\n        audio_forget_evidence();status=1u;\n    }\n    unsigned index=audio_cache_next++&15u;\n    memcpy(audio_cache[index].request,p,46u);audio_cache[index].id=request;\n    audio_cache[index].status=status;audio_cache[index].valid=1u;\n    audio_ack_status=status;return status==1u?0:-1;\n}\nvoid servo_tracking_audio_status(uint32_t words[16],uint32_t boot_id) {\n    memset(words,0,16u*sizeof *words);words[0]=0x534e4432u;words[1]=1u;\n    words[2]=audio_revision;words[3]=audio_ack_request;words[4]=audio_ack_status;words[5]=boot_id;\n    for(unsigned i=0;i<8u;i++)memcpy(words+6+i,audio_values+i,4);\n    words[14]=audio_applies;\n}\nstatic int audio_confirm(int32_t target,unsigned quality,uint64_t captured,\n                         uint64_t now,unsigned reaim,int32_t *out) {\n    return sound_seek_confirm_push_config(&sound_confirmation,target,quality,captured,now,\n        (unsigned)(audio_values[reaim?SOUND_TUNE_REAIM:SOUND_TUNE_ACQUIRE]*1000.f),out,\n        (unsigned)audio_values[SOUND_TUNE_QUALITY],\n        (int32_t)(audio_values[SOUND_TUNE_JITTER]*1000.f));\n}\n'), ('continuous_reset();tuning_reset();', 'continuous_reset();tuning_reset();audio_reset();'), ('int32_t step=(int32_t)SERVO_SOUND_TURN_STEP_MDEG;', '/* Keep integer millidegree steps: default 83.3 * 20 = 1666,\n             * exactly the original M42 command progression. */\n            int32_t step=(int32_t)(audio_values[SOUND_TUNE_SPEED]*\n                ((float)SERVO_SOUND_TURN_INTERVAL_US/1000.f));'), ('change>=-SERVO_SOUND_REAIM_DEADBAND_MDEG &&\n       change<=SERVO_SOUND_REAIM_DEADBAND_MDEG', 'change>=-(int32_t)(audio_values[SOUND_TUNE_DEADBAND]*1000.f) &&\n       change<=(int32_t)(audio_values[SOUND_TUNE_DEADBAND]*1000.f)'), ('sound_seek_confirm_push(&sound_confirmation,raw_target,quality,captured,now,\n                SERVO_SOUND_REAIM_CONFIRM_US,&renewed)', 'audio_confirm(raw_target,quality,captured,now,1u,&renewed)'), ('sound_seek_confirm_push(&sound_confirmation,raw_target,quality,captured,now,\n       sound_plan_active?SERVO_SOUND_REAIM_CONFIRM_US:SERVO_SOUND_ACQUIRE_CONFIRM_US,&confirmed)', 'audio_confirm(raw_target,quality,captured,now,sound_plan_active,&confirmed)')]

def apply_servo(text):
    for old,new in SERVO_PAIRS:
        text = _replace(text,old,new)
    return text


def revert_servo(text):
    for old,new in reversed(SERVO_PAIRS):
        text = _replace(text,new,old)
    return text
