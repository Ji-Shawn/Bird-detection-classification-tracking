"""Add passive SD recorder taps without changing M47 tracking/capture decisions."""
def once(text,old,new):
    assert text.count(old)==1,(old,text.count(old))
    return text.replace(old,new,1)

def apply_main(text):
    text='#include "sd_record.h"\n'+text
    return once(text,'    fusion_init(&network);','    fusion_init(&network);\n    sd_record_init(boot_id);')

def apply_fusion(text):
    text='#include "sd_record.h"\nstatic uint32_t sd_archive_job_identity;\n'+text
    text=once(text,'        roi_result(bird_valid,result.detector_score,selected);','''        roi_result(bird_valid,result.detector_score,selected);
        sd_archive_job_identity=bird_valid && capture_state==0 && job_mode==requested_mode &&
            active_mode==1 && active_policy<2?
            ssd_fast_archive_identity(result.video_sequence,result.video_timestamp_us,active_policy):0u;''')
    text=once(text,'''        if(capture_state==0 && job_mode==requested_mode && active_mode==1 && active_policy<2)
            ssd_fast_class_report(result.video_sequence,result.video_timestamp_us,class_reused,now_us());''','''        if(capture_state==0 && job_mode==requested_mode && active_mode==1 && active_policy<2) {
            ssd_fast_archive_store(sd_archive_job_identity,result.video_sequence,result.video_timestamp_us,
                                   active_policy,now_us(),result.image_top1,class_reused);
            ssd_fast_class_report(result.video_sequence,result.video_timestamp_us,class_reused,now_us());
        }''')
    return once(text,'    servo_tracking_tick(t);','''    servo_tracking_tick(t);
    { uint32_t recording_servo[10];servo_tracking_status(recording_servo);
      uint32_t recording_species=0,recording_identity=0;uint64_t recording_classified=0;
      int recording_named=ssd_fast_archive_snapshot(t,&recording_species,&recording_identity,&recording_classified);
      sd_record_label(recording_named?sd_record_species_code(recording_species):0,
                      recording_identity,recording_classified,t);
      sd_record_target(recording_servo[2] && servo_tracking_visual_present(t),t); }
''')

def apply_dma(text):
    text='#include "sd_record.h"\n'+text
    text=once(text,'    board_focus_frame_begin();visual_tracker_frame_begin(frame_id,timestamp);',
        '    sd_record_frame_begin(frame_id,timestamp,timestamp_us());\n    board_focus_frame_begin();visual_tracker_frame_begin(frame_id,timestamp);')
    # Every existing frame abort discards its incomplete recording as well.
    assert text.count('visual_tracker_frame_abort();')==2
    text=text.replace('visual_tracker_frame_abort();','visual_tracker_frame_abort();sd_record_frame_abort();')
    text=once(text,'    if(fusion_copy_active)fusion_video_chunk(destination,video_copy_offset,bytes);',
        '    if(fusion_copy_active)fusion_video_chunk(destination,video_copy_offset,bytes);\n    sd_record_frame_chunk(destination,video_copy_offset,bytes);')
    text=once(text,'        board_focus_frame_end(video_copy_timestamp);visual_tracker_frame_end();',
        '        board_focus_frame_end(video_copy_timestamp);visual_tracker_frame_end();\n        sd_record_frame_end();')
    return text
