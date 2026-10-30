"""Keep M29 baseline sources intact; reversible audio/vision scheduling fixes."""
PREFIX='#include "av_responsiveness.h"\nstatic unsigned visual_confirmation_retry;\nstatic unsigned visual_present(uint64_t now,unsigned require_current_target);\n'
REPLACEMENTS=[
 ('int fusion_direction_read(fusion_direction_sample *out) {',
  PREFIX+'int fusion_direction_read(fusion_direction_sample *out) {'),
 ('sound_search_audio_blocked(requested_mode,active_mode,servo_tracking_sound_search_active())',
  'response_audio_blocked(requested_mode,visual_present(now,0))'),
 ('servo_tracking_visual_priority(visual_present(servo_now,1),servo_now);',
  'servo_tracking_visual_priority(visual_present(servo_now,0),servo_now);'),
 ('sound.timestamp_us,visual_present(sound_now,1),sound_now);',
  'sound.timestamp_us,visual_present(sound_now,0),sound_now);'),
 ('if(active_mode==1)next_visual=now_us()+250000u;',
  'if(active_mode==1)next_visual=now_us()+20000u;'),
 ('        active_mode=sound_search_mode(',
  '        /* Discard READY audio while a bird is visible, or when it is already\n'
  '         * over two seconds old. Core1 owns WRITING; Core0 owns READY/READING.\n'
  '         * Never start a new listening session using a pre-tracking window. */\n'
  '        fusion_audio_slot *ready=(fusion_audio_slot *)FUSION_SHARED;\n'
  '        uint64_t schedule_now=now_us();\n'
  '        if(response_discard_audio(requested_mode,capture_state,ready->state,\n'
  '           visual_present(schedule_now,0),ready->timestamp_us,schedule_now)) {\n'
  '            av_memory_barrier();ready->state=0;\n'
  '        }\n'
  '        active_mode=sound_search_mode('),
 ('        active_policy=requested_policy;memcpy(active_box,requested_box,sizeof active_box);',
  '        uint32_t selection[12];visual_tracker_selection_status(selection);\n'
  '        if(response_confirm_first(requested_mode,active_mode,selection[3],visual_confirmation_retry)) {\n'
  '            active_mode=1;visual_confirmation_retry=1;\n'
  '        }\n'
  '        active_policy=requested_policy;memcpy(active_box,requested_box,sizeof active_box);'),
 ('        sound_last_job_audio=1;',
  '        sound_last_job_audio=1;visual_confirmation_retry=0;'),
 ('        video_state=1;wait_start=now_us();',
  '        video_state=response_audio_only(job_mode,capture_state)?0u:1u;wait_start=now_us();'),
 ('        if(result.confidence<fusion_audio_threshold){publish(5,0);return;}',
  '        if(result.confidence<fusion_audio_threshold){publish(5,0);return;}\n'
  '        /* In linked mode audio classification and SSD are independent jobs.\n'
  '         * SSD captures a NEW frame on its own turn, never one frozen before\n'
  '         * the audio network ran. Diagnostic one-shot captures keep pairing. */\n'
  '        if(response_audio_only(job_mode,capture_state)){publish(8,0);return;}'),
]

TRACKER_REPLACEMENTS=[
 ('#define HISTORY 32u','#define HISTORY 96u'),
 ('#define SLICE_CANDIDATES 16u','#define SLICE_CANDIDATES 64u'),
]

def transform(text, pairs, reverse=False):
    for old,new in (reversed(pairs) if reverse else pairs):
        if reverse:old,new=new,old
        assert text.count(old)==1,old
        text=text.replace(old,new,1)
    return text

def apply(text):return transform(text,REPLACEMENTS)
def revert(text):return transform(text,REPLACEMENTS,True)
def tracker(text):return transform(text,TRACKER_REPLACEMENTS)
def revert_tracker(text):return transform(text,TRACKER_REPLACEMENTS,True)
