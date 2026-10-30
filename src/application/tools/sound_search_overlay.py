"""Reversible, scoped integration of continuous sound seeking into M29."""
PREFIX='#include "sound_search_policy.h"\n'
REPLACEMENTS=[
 ('static uint64_t request_start;',
  'static uint64_t request_start;\nstatic unsigned sound_last_job_audio;'),
 ('if(requested_mode==1 || active_mode==1 || capture_state==2 || stage==9)',
  'if(sound_search_audio_blocked(requested_mode,active_mode,servo_tracking_sound_search_active()) || capture_state==2 || stage==9)'),
 ('active_mode=requested_mode==2?(visual_present(now_us(),0)?1u:0u):requested_mode;',
  'active_mode=sound_search_mode(requested_mode,visual_present(now_us(),0),\n            servo_tracking_sound_search_active(),((fusion_audio_slot *)FUSION_SHARED)->state==2,sound_last_job_audio);'),
 ('result.sequence=++visual_sequence;result.audio_timestamp_us=0;',
  'sound_last_job_audio=0;\n            result.sequence=++visual_sequence;result.audio_timestamp_us=0;'),
 ('s->state=3;av_memory_barrier();',
  'sound_last_job_audio=1;\n        s->state=3;av_memory_barrier();'),
 ('        direction_gate_accept(&doa_gate,result.audio_top1,result.confidence,',
  '        /* A new classification must pass the existing threshold again;\n         * an old sound session cannot mask a different bird direction. */\n'
  '        if(requested_mode==2 && servo_tracking_sound_search_active() && !visual_present(now_us(),0))\n'
  '            direction_gate_clear(&doa_gate);\n'
  '        direction_gate_accept(&doa_gate,result.audio_top1,result.confidence,'),
]

def apply(text):
    for old,new in REPLACEMENTS:
        assert text.count(old)==1,old
        text=text.replace(old,new,1)
    return PREFIX+text

def revert(text):
    assert text.count(PREFIX)==1
    text=text.replace(PREFIX,'',1)
    for old,new in reversed(REPLACEMENTS):
        assert text.count(new)==1,new
        text=text.replace(new,old,1)
    return text
