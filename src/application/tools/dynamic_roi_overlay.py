"""M44 one-pass, alternating square-ROI SSD recovery on immutable fresh input."""


def once(text, old, new):
    assert text.count(old) == 1, (old, text.count(old))
    return text.replace(old, new, 1)


RUNTIME = r'''
/* ROI is only a detector search hint. It never supplies a servo measurement.
 * One SSD pass per job: an ROI retry always yields the next job to full view. */
extern int visual_tracker_roi_hint(float [4],float *,uint32_t *,uint64_t *,uint64_t);
extern void visual_tracker_roi_forget(void);
static ssd_roi_box roi_job;
static float roi_job_hint[4];
static unsigned roi_retry_pending,roi_last_was_local,roi_job_active,roi_owned,roi_mode,roi_policy;
static uint32_t roi_owner_epoch,roi_job_owner_epoch,roi_camera_epoch;
static uint64_t roi_clock;
/* magic,full jobs,ROI jobs,ROI formal positives,ambiguous ROI batches,
 * preprocessing failures,cancelled ROI jobs,bad mapped candidates,
 * ROI x,y,side,hint age ms,last model score q6,last selection,owner,version. */
volatile uint32_t roi_detection_profile[16];
static void roi_search_clear(void) {
    roi_retry_pending=roi_last_was_local=0;
    visual_tracker_roi_forget();
}
static void roi_owner_poll(uint64_t now) {
    uint32_t servo[10];servo_tracking_status(servo);
    unsigned owner=servo[1] && servo[2] && capture_state==0 && stage!=9 &&
        requested_mode!=0 && requested_policy<2;
    if(now<roi_clock || roi_camera_epoch!=video_recovery_epoch || owner!=roi_owned ||
       requested_mode!=roi_mode || requested_policy!=roi_policy) {
        ++roi_owner_epoch;roi_search_clear();
    }
    if(!owner)roi_search_clear();
    roi_clock=now;roi_owned=owner;roi_camera_epoch=video_recovery_epoch;
    roi_mode=requested_mode;roi_policy=requested_policy;
    roi_detection_profile[14]=owner;
}
static void roi_before_inference(uint64_t now) {
    roi_owner_poll(now);roi_job_active=0;
    roi_job_owner_epoch=roi_owner_epoch;
    if(!roi_owned || active_mode!=1 || active_policy>=2) {
        roi_detection_profile[1]++;return;
    }
    float hint[4],score;uint32_t seq;uint64_t captured;
    if(!visual_tracker_roi_hint(hint,&score,&seq,&captured,now)) {
        roi_retry_pending=roi_last_was_local=0;roi_detection_profile[1]++;return;
    }
    uint32_t tracker[16];visual_tracker_status(tracker,now);
    if(!tracker[2] || tracker[7]<750000u || tracker[11]>500u)roi_retry_pending=1;
    if(roi_last_was_local) {
        roi_last_was_local=0;roi_detection_profile[1]++;return;
    }
    if(roi_retry_pending && ssd_roi_from_box(hint,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,&roi_job)) {
        memcpy(roi_job_hint,hint,sizeof hint);roi_job_active=roi_last_was_local=1;
        roi_detection_profile[2]++;roi_detection_profile[8]=(uint32_t)roi_job.x;
        roi_detection_profile[9]=(uint32_t)roi_job.y;roi_detection_profile[10]=(uint32_t)roi_job.side;
        roi_detection_profile[11]=(uint32_t)((now-captured)/1000u);
    } else roi_detection_profile[1]++;
}
static int roi_map_candidate(const float input[4],float mapped[4]) {
    if(!ssd_roi_map(&roi_job,input,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,mapped)) {
        roi_detection_profile[7]++;return 0;
    }
    float w=roi_job_hint[2]-roi_job_hint[0],h=roi_job_hint[3]-roi_job_hint[1];
    float bw=mapped[2]-mapped[0],bh=mapped[3]-mapped[1];
    float dx=fabsf((mapped[0]+mapped[2]-roi_job_hint[0]-roi_job_hint[2])*.5f);
    float dy=fabsf((mapped[1]+mapped[3]-roi_job_hint[1]-roi_job_hint[3])*.5f);
    /* Bounded translation/size change around a formal bird, not an arbitrary
     * new object elsewhere in the crop. Existing tracker association follows. */
    if(bw<w*.2f || bh<h*.2f || bw>w*2.5f || bh>h*2.5f ||
       dx>fmaxf(96.f,w*.8f) || dy>fmaxf(96.f,h*.8f)) {
        roi_detection_profile[7]++;return 0;
    }
    return 1;
}
static void roi_result(unsigned bird_valid,float score,int selected) {
    if(!roi_job_active)roi_retry_pending=!bird_valid;
    else if(bird_valid){roi_retry_pending=0;roi_detection_profile[3]++;}
    roi_detection_profile[12]=isfinite(score) && score>=0.f && score<=1.f?
        (uint32_t)(score*1000000.f+.5f):0u;
    roi_detection_profile[13]=(uint32_t)(selected+1);
}
'''

OWNER_GUARD = '''
        if(roi_job_active && (!roi_owned || roi_job_owner_epoch!=roi_owner_epoch)) {
            classification_control_pending=0;roi_detection_profile[6]++;
            ssd_fast_reset();video_state=stage=0;return;
        }'''


def guard_video_jobs(text):
    pattern = 'if(job_mode!=requested_mode || active_policy!=requested_policy || job_video_epoch!=video_recovery_epoch)'
    positions = []
    at = 0
    while True:
        at = text.find(pattern, at)
        if at < 0:
            break
        end = text.index('{', at)+1
        depth = 1
        while depth:
            depth += (text[end] == '{')-(text[end] == '}')
            end += 1
        positions.append(end)
        at = end
    assert len(positions) == 3
    for end in reversed(positions):
        text = text[:end]+OWNER_GUARD+text[end:]
    return text


def apply_fusion(text):
    text = '#include "ssd_roi.h"\n' + text
    text = once(text, 'static unsigned sound_last_job_audio;',
                'static unsigned sound_last_job_audio;\n' + RUNTIME)
    text = once(text, '    classification_control_service(servo_now);',
                '    classification_control_service(servo_now);\n    roi_owner_poll(now_us());')
    text = once(text, '    ssd_fast_init(net->boot_id);',
                '    ssd_fast_init(net->boot_id);\n'
                '    roi_retry_pending=roi_last_was_local=roi_job_active=roi_owned=0;\n'
                '    roi_owner_epoch=roi_job_owner_epoch=roi_camera_epoch=0;roi_clock=0;roi_mode=roi_policy=0;\n'
                '    memset((void *)roi_detection_profile,0,sizeof roi_detection_profile);\n'
                '    roi_detection_profile[0]=0x524f4931u;roi_detection_profile[15]=1u;')
    old = '        int rc=fusion_ssd_input((const uint16_t *)FUSION_IMAGE,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,(int8_t *)0x10190000u);'
    text = once(text, old,
                '        roi_before_inference(start);\n'
                '        int rc=roi_job_active?ssd_roi_input((const uint16_t *)FUSION_IMAGE,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,&roi_job,(int8_t *)0x10190000u):\n'
                '            fusion_ssd_input((const uint16_t *)FUSION_IMAGE,AV_VIDEO_WIDTH,AV_VIDEO_HEIGHT,(int8_t *)0x10190000u);\n'
                '        if(rc && roi_job_active)roi_detection_profile[5]++;')
    text = once(text, '        Xil_DCacheFlushRange(0x10190000u,307200);',
                OWNER_GUARD+'\n        Xil_DCacheFlushRange(0x10190000u,307200);')
    old = '''            candidates[i].box[0]=d[i].x1*(AV_VIDEO_WIDTH/320.f);
            candidates[i].box[2]=d[i].x2*(AV_VIDEO_WIDTH/320.f);
            candidates[i].box[1]=d[i].y1*(AV_VIDEO_HEIGHT/320.f);
            candidates[i].box[3]=d[i].y2*(AV_VIDEO_HEIGHT/320.f);'''
    text = once(text, old, '''            if(roi_job_active) {
                float local[4]={d[i].x1,d[i].y1,d[i].x2,d[i].y2};
                if(!roi_map_candidate(local,candidates[i].box)) {
                    candidates[i].score=0.f;memset(candidates[i].box,0,sizeof candidates[i].box);
                }
            } else {
'''+old+'''
            }''')
    text = once(text, '        if(capture_state==0 && job_mode==requested_mode && active_policy<2)\n            selected=visual_tracker_select_ssd',
                '''        unsigned roi_batch_supported=1u;
        if(roi_job_active) {
            unsigned positives=0;
            for(unsigned i=0;i<count;i++)if(candidates[i].score>fusion_detection_threshold &&
                candidates[i].score<=1.f)positives++;
            roi_batch_supported=positives==1u;
            /* Two possible birds in a local retry cannot silently switch the
             * previous identity. Let the following full-frame pass associate. */
            if(positives>1u) {
                for(unsigned i=0;i<count;i++)candidates[i].score=0.f;
                roi_detection_profile[4]++;
            }
        }
        if(capture_state==0 && job_mode==requested_mode && active_policy<2)
            selected=visual_tracker_select_ssd''')
    text = once(text, '''        if(capture_state==0 && job_mode==requested_mode && active_policy<2)
            selected=visual_tracker_select_ssd(candidates,count,result.video_sequence,
                                               result.video_timestamp_us,now_us());''',
                '''        if(capture_state==0 && job_mode==requested_mode && active_policy<2) {
            /* A limited local search cannot supply a negative identity vote.
             * It also cannot refresh confirmation unless association accepts
             * one real positive. Full-frame negatives retain their old rules. */
            if(!roi_job_active || roi_batch_supported)
                selected=visual_tracker_select_ssd(candidates,count,result.video_sequence,
                                                   result.video_timestamp_us,now_us());
            else selected=-1;
        }''')
    text = once(text, '        if(!bird_valid && active_mode==0){publish(1,0);return;}',
                '        roi_result(bird_valid,result.detector_score,selected);\n'
                '        if(!bird_valid && active_mode==0){publish(1,0);return;}')
    return guard_video_jobs(text)
