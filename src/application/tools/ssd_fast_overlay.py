"""Reversible SSD-only integration after the accepted sound/focus overlays."""
PREFIX='#include "ssd_fast.h"\n'
FUSION=[
('        uint32_t count=*(volatile uint32_t *)0x2F001010u;',
 '        /* Commands received while inference yielded invalidate the old job. */\n'
 '        if(job_mode!=requested_mode || active_policy!=requested_policy) {\n'
 '            ssd_fast_reset();video_state=stage=0;return;\n'
 '        }\n'
 '        uint32_t count=*(volatile uint32_t *)0x2F001010u;'),
('    visual_tracker_init();','    visual_tracker_init();\n    ssd_fast_init(net->boot_id);'),
('    /* Give the current M29 tracker result priority before a loss-home step. */',
 '    ssd_fast_poll(now_us());ssd_fast_send(now_us());\n    /* Give the current M29 tracker result priority before a loss-home step. */'),
('        result.detector_score=highest;memset(result.box,0,sizeof result.box);',
 '        /* Selection seeds a display-only candidate before classification. */\n'
 '        ssd_fast_send(now_us());\n'
 '        result.detector_score=highest;memset(result.box,0,sizeof result.box);'),
('        float crop_box[4];int use_roi=0;',
 '        int class_reused=capture_state==0 && job_mode==requested_mode && active_mode==1 && active_policy<2 &&\n'
 '            ssd_fast_class_reuse(result.video_sequence,result.video_timestamp_us,active_policy,now_us(),image_logits,result.roi,&result.applied_policy);\n'
 '        if(!class_reused) {\n'
 '        float crop_box[4];int use_roi=0;'),
('        memcpy(image_logits,unified_logits,60);float pv[60];',
 '        if(job_mode!=requested_mode || active_policy!=requested_policy) {\n'
 '            ssd_fast_reset();video_state=stage=0;return;\n'
 '        }\n'
 '        memcpy(image_logits,unified_logits,60);\n'
 '        }\n'
 '        float pv[60];'),
('        result.image_top1=fusion_scores(audio_logits,image_logits,1,pv);',
 '        result.image_top1=fusion_scores(audio_logits,image_logits,1,pv);\n'
 '        if(!class_reused && capture_state==0 && job_mode==requested_mode && active_mode==1 && active_policy<2)\n'
 '            ssd_fast_class_store(result.video_sequence,result.video_timestamp_us,active_policy,now_us(),image_logits,pv[result.image_top1],result.roi,result.applied_policy);\n'
 '        if(capture_state==0 && job_mode==requested_mode && active_mode==1 && active_policy<2)\n'
 '            ssd_fast_class_report(result.video_sequence,result.video_timestamp_us,class_reused,now_us());'),
]
TRACKER=[
('    reset_track();candidate_count=candidate_hits=unsupported=selected_index=selection_reason=0;',
 '    ssd_fast_reset();\n    reset_track();candidate_count=candidate_hits=unsupported=selected_index=selection_reason=0;'),
('static void lost(unsigned why){losses++;',
 'static void lost(unsigned why){ssd_fast_reset();losses++;'),
('        return same;',
 '        ssd_fast_selection(2,c[same].score,c[same].box,sequence,captured,now);\n        return same;'),
('            selected_index=(unsigned)best+1u;return best;',
 '            selected_index=(unsigned)best+1u;\n'
 '            ssd_fast_selection(selection_reason,c[best].score,c[best].box,sequence,captured,now);\n'
 '            return best;'),
('        selection_reason=1;',
 '        selection_reason=1;\n'
 '        if(!active)ssd_fast_selection(1,c[best].score,c[best].box,sequence,captured,now);'),
('    rejected_batches++;return -1;',
 '    if(selection_reason!=1)ssd_fast_selection(selection_reason,0,0,sequence,captured,now);\n'
 '    rejected_batches++;return -1;'),
]
HISTORY='''
/* Read-only history views; candidates never change formal tracker history. */
const uint8_t *ssd_history_exact(uint32_t seq,uint64_t ts) {
    for(unsigned i=0;i<HISTORY;i++)if(history[i].valid && history[i].sequence==seq && history[i].timestamp==ts)
        return history[i].gray;
    return 0;
}
const uint8_t *ssd_history_next(uint64_t after,uint32_t *seq,uint64_t *ts) {
    const track_frame *f=0;
    for(unsigned i=0;i<HISTORY;i++)if(history[i].valid && history[i].timestamp>after &&
        (!f || history[i].timestamp<f->timestamp))f=&history[i];
    if(!f)return 0;
    *seq=f->sequence;*ts=f->timestamp;return f->gray;
}
'''
def change(text,pairs,reverse=False):
    for a,b in (reversed(pairs) if reverse else pairs):
        if reverse:a,b=b,a
        assert text.count(a)==1,a
        text=text.replace(a,b,1)
    return text
def apply(text):return PREFIX+change(text,FUSION)
def revert(text):
    assert text.startswith(PREFIX)
    return change(text[len(PREFIX):],FUSION,True)
def tracker(text):return PREFIX+change(text,TRACKER)+HISTORY
def revert_tracker(text):
    assert text.startswith(PREFIX) and text.endswith(HISTORY)
    return change(text[len(PREFIX):-len(HISTORY)],TRACKER,True)
