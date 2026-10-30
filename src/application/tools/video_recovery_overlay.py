"""M44 cooperative video watchdog, channel-specific VDMA and sensor recovery.

The SDK XAxiVdma_DmaStop and XAxiVdma_Reset issue register writes only.
Completion is sampled on later main-loop turns, never in a busy loop.
Healthy capture does not issue SCCB writes or restart any DMA channel.
"""

def once(text, old, new):
    assert text.count(old) == 1, (old, text.count(old))
    return text.replace(old, new, 1)


RUNTIME = r'''
/* VH01: actual progress, not preview pacing, owns the watchdog clock. */
#define VH_STARTUP_US 3000000u
#define VH_SOURCE_STALL_US 700000u
#define VH_CAPTURE_STALL_US 500000u
#define VH_COPY_STALL_US 900000u
#define VH_CHANNEL_WAIT_US 100000u
#define VH_FRESH_WAIT_US 1500000u
#define VH_RETRY_COOLDOWN_US 2000000u
#define VH_MAX_ATTEMPTS 3u
static uint32_t vh_words[VIDEO_HEALTH_WORDS];
static uint64_t vh_boot,vh_now,vh_source_at,vh_capture_at,vh_copy_at;
static uint64_t vh_started,vh_deadline,vh_state_at,vh_last_copy_restart;
static uint32_t vh_source_count,vh_capture_store,vh_clean,vh_dma_mask;
static unsigned vh_sensor_reset_generation;
extern unsigned visual_tracker_video_active(void);
static unsigned vh_have_source,vh_have_capture,vh_have_copy,vh_attempts;
static unsigned vh_sensor_wait,vh_fault_latched,vh_diag_was_active;
static unsigned vh_suspended_state;
static uint32_t vh_age_ms(uint64_t now,uint64_t then,unsigned have) {
    if(!have || now<then)return 0xffffffffu;
    uint64_t age=(now-then)/1000u;
    return age>0xfffffffeu?0xfffffffeu:(uint32_t)age;
}
void video_health_words(uint32_t out[VIDEO_HEALTH_WORDS]) {
    memcpy(out,vh_words,sizeof vh_words);
}
int video_health_ready(void) {
    return !ov5640_recovery_busy() && vh_words[2]!=VH_STOP &&
        vh_words[2]!=VH_RESET && vh_words[2]!=VH_CONFIG;
}
static void vh_state(unsigned state,uint64_t now,uint64_t wait) {
    vh_words[2]=state;vh_state_at=now;vh_deadline=now+wait;
}
static void vh_abort_copy(network_service_t *service,unsigned all_previews) {
    if(video_copy_active) {
        video_copy_active=0;visual_tracker_frame_abort();
        if(fusion_copy_active)fusion_video_abort();
        fusion_copy_active=0;vh_words[22]++;service->video_drop_old++;
    }
    if(all_previews)for(unsigned i=0;i<NETWORK_VIDEO_PENDING;i++) {
        if(service->video[i].valid)vh_words[23]++;
        service->video[i].valid=0;service->video[i].retry_active=0;
        service->video[i].next_fragment=0;
    }
}
static void vh_break_source(network_service_t *service) {
    vh_abort_copy(service,1);fusion_video_invalidate();
    video_quarantine=1;vh_clean=0;
    last_video_store=XAxiVdma_CurrFrameStore(&video_dma,XAXIVDMA_WRITE);
}
static void vh_event(unsigned reason,uint64_t now) {
    if(!vh_fault_latched) {
        vh_started=(reason==VH_SOURCE_STALL || reason==VH_DMA_FAULT)?vh_capture_at:now;
        vh_words[11]++;vh_fault_latched=1;
        vh_words[28]=vh_words[6];vh_words[29]=vh_words[7];
    }
    vh_words[3]=reason;
}
static void vh_failure(uint64_t now) {
    vh_words[15]++;
    vh_state(vh_attempts>=VH_MAX_ATTEMPTS?VH_EXHAUSTED:VH_COOLDOWN,
             now,VH_RETRY_COOLDOWN_US);
}
static void vh_success(uint64_t now) {
    if(vh_fault_latched) {
        uint32_t duration=vh_age_ms(now,vh_started,1);
        vh_words[14]++;vh_words[20]=duration;
        if(duration>vh_words[21])vh_words[21]=duration;
    }
    vh_fault_latched=0;vh_attempts=0;vh_words[30]=0;vh_sensor_wait=0;
    vh_dma_mask=0;vh_clean=0;vh_state(VH_HEALTHY,now,0);
}
static void vh_copy_completed(uint64_t now,uint64_t captured) {
    vh_copy_at=now;vh_have_copy=1;
    /* Confirmation needs a real new capture after recovery, never a retained
     * preview frame or a store completion observed before the sensor resumed. */
    if(captured>=vh_state_at && vh_words[2]==VH_WAIT_FRAMES &&
       vh_have_source && now>=vh_source_at && now-vh_source_at<400000u &&
       vh_have_capture && vh_capture_at>=vh_state_at && now>=captured &&
       now-captured<=500000u && !ov5640_recovery_busy()) {
        if(++vh_clean>=2u) {
            ov5640_recovery_confirm_frame();vh_success(now);
        }
    }
}
static void vh_init(uint64_t now) {
    memset(vh_words,0,sizeof vh_words);
    vh_words[0]=VIDEO_HEALTH_MAGIC;vh_words[1]=1;
    vh_boot=vh_now=vh_source_at=vh_capture_at=vh_copy_at=now;
    vh_source_count=platform_mmio_read(AV_REG_BASE+AV_REG_FRAME_COUNT);
    vh_capture_store=XAxiVdma_CurrFrameStore(&video_dma,XAXIVDMA_WRITE);
    vh_have_source=vh_have_capture=vh_have_copy=0;
    vh_started=vh_deadline=vh_last_copy_restart=0;
    vh_attempts=vh_fault_latched=vh_sensor_wait=vh_dma_mask=vh_clean=0;
    vh_diag_was_active=vh_suspended_state=0;
    vh_sensor_reset_generation=ov5640_recovery_reset_generation();
    vh_state(VH_HEALTHY,now,0);
}
static int vh_start_sensor(network_service_t *service,uint64_t now) {
    if(vh_attempts>=VH_MAX_ATTEMPTS){vh_state(VH_EXHAUSTED,now,0);return 0;}
    int rc=ov5640_recovery_begin(now);
    vh_words[13]++;
    if(rc<0){
        /* A time-based begin backoff is retriable; all other rejections count
         * toward exhaustion even when no sensor transaction was started. */
        if(rc!=-2)vh_attempts++;
        vh_words[30]=vh_attempts;vh_failure(now);return 0;
    }
    vh_attempts++;vh_words[30]=vh_attempts;
    vh_break_source(service);vh_sensor_wait=1;vh_dma_mask=0;
    vh_state(VH_SENSOR,now,6500000u);return 1;
}
static void vh_start_dma(network_service_t *service,uint64_t now,unsigned mask) {
    if(vh_attempts>=VH_MAX_ATTEMPTS){vh_state(VH_EXHAUSTED,now,0);return;}
    vh_attempts++;vh_words[12]++;vh_words[30]=vh_attempts;vh_dma_mask=mask;vh_sensor_wait=0;
    if(mask&2u)vh_break_source(service);
    if(mask&1u){hdmi_output_restart();XAxiVdma_DmaStop(&video_dma,XAXIVDMA_READ);}
    if(mask&2u)XAxiVdma_DmaStop(&video_dma,XAXIVDMA_WRITE);
    vh_state(VH_STOP,now,VH_CHANNEL_WAIT_US);
}
static int vh_configure_write(void) {
    XAxiVdma_DmaSetup c;memset(&c,0,sizeof c);
    c.VertSizeInput=AV_VIDEO_HEIGHT;c.HoriSizeInput=AV_VIDEO_STRIDE;
    c.Stride=AV_VIDEO_STRIDE;c.EnableCircularBuf=1u;
    c.EnableSync=1u;c.GenLockRepeat=1u;
    for(unsigned i=0;i<AV_VIDEO_BUFFER_COUNT;i++)
        c.FrameStoreStartAddr[i]=AV_VIDEO_BUFFER_BASE+i*AV_VIDEO_FRAME_BYTES;
    int rc=XAxiVdma_DmaConfig(&video_dma,XAXIVDMA_WRITE,&c);
    if(rc==XST_SUCCESS)rc=XAxiVdma_DmaSetBufferAddr(&video_dma,XAXIVDMA_WRITE,c.FrameStoreStartAddr);
    if(rc==XST_SUCCESS)rc=hdmi_capture_genlock(&video_dma);
    if(rc==XST_SUCCESS)rc=XAxiVdma_DmaStart(&video_dma,XAXIVDMA_WRITE);
    return rc;
}
static int vh_recovery_poll(network_service_t *service,uint64_t now) {
    uint32_t source=platform_mmio_read(AV_REG_BASE+AV_REG_FRAME_COUNT);
    uint32_t wr=XAxiVdma_GetStatus(&video_dma,XAXIVDMA_WRITE);
    uint32_t rd=XAxiVdma_GetStatus(&video_dma,XAXIVDMA_READ);
    uint32_t store=XAxiVdma_CurrFrameStore(&video_dma,XAXIVDMA_WRITE);
    unsigned wbad=(wr&(VDMA_FATAL_ERRORS|XAXIVDMA_SR_HALTED_MASK))!=0u;
    unsigned rbad=hdmi_start_error || (hdmi_read_started &&
        (rd&(VDMA_FATAL_ERRORS|XAXIVDMA_SR_HALTED_MASK))!=0u);
    if(now<vh_now) {
        /* Clock anomalies invalidate timing evidence, not healthy hardware. */
        vh_boot=now;vh_have_source=vh_have_capture=vh_have_copy=0;
        vh_source_at=vh_capture_at=vh_copy_at=now;vh_last_copy_restart=0;
        if(vh_words[2]==VH_STOP || vh_words[2]==VH_RESET ||
           vh_words[2]==VH_CONFIG)vh_failure(now);
    }
    vh_now=now;
    if(source!=vh_source_count){vh_source_at=now;vh_have_source=1;vh_source_count=source;}
    if(store!=vh_capture_store && store<AV_VIDEO_BUFFER_COUNT && !wbad) {
        vh_capture_at=now;vh_have_capture=1;vh_capture_store=store;
    }
    uint64_t source_age=now-vh_source_at,capture_age=now-vh_capture_at;
    uint64_t copy_age=now-vh_copy_at;
    vh_words[5]=source;vh_words[6]=wr;vh_words[7]=rd;vh_words[8]=store;
    vh_words[9]=XAxiVdma_CurrFrameStore(&video_dma,XAXIVDMA_READ);
    vh_words[10]=video_last_error_status;
    vh_words[16]=vh_age_ms(now,vh_capture_at,vh_have_capture);
    vh_words[17]=vh_age_ms(now,vh_copy_at,vh_have_copy);
    vh_words[18]=vh_age_ms(now,vh_source_at,vh_have_source);
    vh_words[19]=vh_age_ms(now,vh_started,vh_fault_latched);
    if(!vh_fault_latched)vh_words[19]=0;
    else if(vh_words[19]>vh_words[21])vh_words[21]=vh_words[19];
    vh_words[24]=ov5640_recovery_generation();
    vh_words[25]=video_copy_active?video_copy_offset:0;vh_words[26]=video_sequence;
    vh_words[27]=now-vh_boot<VH_STARTUP_US?(uint32_t)((VH_STARTUP_US-(now-vh_boot))/1000u):0;
    unsigned suppressed=fusion_video_recovery_suppressed();
    vh_words[4]=((source_age<300000u && vh_have_source)?1u:0u)|
        ((capture_age<300000u && vh_have_capture)?2u:0u)|
        (video_copy_active?4u:0u)|(ov5640_recovery_busy()?8u:0u)|
        (suppressed?16u:0u)|((hdmi_read_started && !(rd&XAXIVDMA_SR_HALTED_MASK))?32u:0u)|
        (!(wr&XAXIVDMA_SR_HALTED_MASK)?64u:0u);
    /* Diagnostic capture is an intentional frozen inference image. Do not
     * reinterpret it as a watchdog request or restart its hardware. */
    if(suppressed && !ov5640_recovery_busy() &&
       vh_words[2]!=VH_STOP && vh_words[2]!=VH_RESET && vh_words[2]!=VH_CONFIG) {
        if(!vh_diag_was_active){vh_words[31]++;vh_suspended_state=vh_words[2];}
        vh_diag_was_active=1;vh_words[2]=VH_SUPPRESSED;return wbad;
    }
    if(vh_diag_was_active) {
        vh_diag_was_active=0;vh_words[2]=vh_suspended_state;
        vh_boot=now; /* explicit resume gets a startup grace period */
    }
    if(vh_words[2]==VH_SENSOR) {
        int rc=ov5640_recovery_poll(now);
        unsigned reset_generation=ov5640_recovery_reset_generation();
        if(reset_generation!=vh_sensor_reset_generation) {
            vh_sensor_reset_generation=reset_generation;
            fusion_video_hard_invalidate();
        }
        if(rc<0 || now>=vh_deadline){vh_failure(now);return 1;}
        if(rc>0){vh_clean=0;vh_state(VH_WAIT_FRAMES,now,VH_FRESH_WAIT_US);}
        return ov5640_recovery_busy() || wbad;
    }
    if(vh_words[2]==VH_STOP) {
        unsigned halted=(!(vh_dma_mask&1u)||(rd&XAXIVDMA_SR_HALTED_MASK)) &&
                        (!(vh_dma_mask&2u)||(wr&XAXIVDMA_SR_HALTED_MASK));
        if(halted || now>=vh_deadline) {
            if(vh_dma_mask&1u)XAxiVdma_Reset(&video_dma,XAXIVDMA_READ);
            if(vh_dma_mask&2u)XAxiVdma_Reset(&video_dma,XAXIVDMA_WRITE);
            vh_state(VH_RESET,now,VH_CHANNEL_WAIT_US);
        }
        return (vh_dma_mask&2u)!=0u;
    }
    if(vh_words[2]==VH_RESET) {
        unsigned busy=((vh_dma_mask&1u)&&XAxiVdma_ResetNotDone(&video_dma,XAXIVDMA_READ)) ||
                      ((vh_dma_mask&2u)&&XAxiVdma_ResetNotDone(&video_dma,XAXIVDMA_WRITE));
        if(!busy)vh_state(VH_CONFIG,now,VH_CHANNEL_WAIT_US);
        else if(now>=vh_deadline)vh_failure(now);
        return (vh_dma_mask&2u)!=0u;
    }
    if(vh_words[2]==VH_CONFIG) {
        int rc=XST_SUCCESS;
        if(vh_dma_mask&2u) {
            rc=vh_configure_write();video_quarantine=1;
            last_video_store=XAxiVdma_CurrFrameStore(&video_dma,XAXIVDMA_WRITE);
            vh_capture_store=last_video_store;
        } else if(vh_dma_mask&1u) {
            hdmi_output_poll(&video_dma,2u);
            if(hdmi_start_error)rc=(int)hdmi_start_error;
        }
        if(rc!=XST_SUCCESS){video_last_error_status=(uint32_t)rc;vh_failure(now);}
        else {vh_clean=0;vh_state(VH_WAIT_FRAMES,now,VH_FRESH_WAIT_US);}
        return (vh_dma_mask&2u)!=0u;
    }
    if(vh_words[2]==VH_WAIT_FRAMES) {
        if(vh_dma_mask==1u && hdmi_read_started && !rbad)vh_success(now);
        else if(vh_sensor_wait && source_age<300000u && wbad)
            vh_start_dma(service,now,3u);
        else if(now>=vh_deadline) {
            /* Sensor configuration succeeding is not proof of video recovery.
             * If source is now live and S2MM is stuck, repair DMA next. */
            if(source_age<400000u && (wbad || capture_age>VH_CAPTURE_STALL_US))
                vh_start_dma(service,now,3u);
            else vh_failure(now);
        }
        return wbad;
    }
    if(vh_words[2]==VH_COOLDOWN || vh_words[2]==VH_EXHAUSTED) {
        /* A genuine spontaneous recovery ends the incident; stale pixels do
         * not. Exhaustion is visible and never spins resets indefinitely. */
        if(vh_have_copy && vh_copy_at>vh_started && copy_age<300000u &&
           source_age<300000u && capture_age<300000u && !wbad) {
            ov5640_recovery_confirm_frame();vh_success(now);
        } else if(vh_words[2]==VH_EXHAUSTED || now<vh_deadline)return wbad;
    }
    if(now-vh_boot<VH_STARTUP_US)return wbad;
    unsigned tracking=visual_tracker_video_active();
    uint64_t source_limit=tracking?350000u:VH_SOURCE_STALL_US;
    uint64_t capture_limit=tracking?350000u:VH_CAPTURE_STALL_US;
    if(source_age>=source_limit && capture_age>=capture_limit) {
        vh_event(VH_SOURCE_STALL,now);(void)vh_start_sensor(service,now);
        return ov5640_recovery_busy() || wbad;
    }
    if(source_age<400000u && (wbad || capture_age>=VH_CAPTURE_STALL_US)) {
        vh_event(VH_DMA_FAULT,now);vh_start_dma(service,now,3u);
        return 1;
    }
    if(rbad && capture_age<400000u && source_age<400000u) {
        vh_event(VH_HDMI_FAULT,now);vh_start_dma(service,now,1u);
        return wbad;
    }
    if(capture_age<300000u && source_age<300000u && copy_age>=VH_COPY_STALL_US &&
       (!vh_last_copy_restart || now-vh_last_copy_restart>=VH_COPY_STALL_US)) {
        /* CPU starvation/old sender slots do not justify resetting VDMA.
         * Drop one expired copy and take the next complete current image. */
        vh_words[3]=VH_COPY_STALL;vh_words[11]++;
        vh_abort_copy(service,1);vh_last_copy_restart=now;
    }
    vh_state((source_age>=300000u && capture_age>=300000u)?VH_WATCH:VH_HEALTHY,now,0);
    return wbad;
}
'''


def apply_dma(text):
    text = '#include "video_health.h"\n#include "camera_recovery.h"\n' + text
    text = once(text, 'static uint64_t timestamp_us(void) {',
                RUNTIME + '\nstatic uint64_t timestamp_us(void) {')
    text = once(text, '        ++video_raw_frames;',
                '        ++video_raw_frames;\n        vh_copy_completed(timestamp_us(),video_copy_timestamp);')
    text = once(text, '    video_last_mean_y = 0u; video_last_gain_q8 = 256u;',
                '    video_last_mean_y = 0u; video_last_gain_q8 = 256u;\n    vh_init(timestamp_us());')
    begin = text.index('    /* VDMA can report a nonfatal short-frame condition')
    end = text.index('    {\n        uint32_t status = XAxiDma_ReadReg', begin)
    text = text[:begin] + r'''    /* One watchdog state transition per main-loop turn. Audio below always
     * gets its service opportunity, including sensor/DMA recovery turns. */
    {
        uint32_t status=XAxiVdma_GetStatus(&video_dma,XAXIVDMA_WRITE);
        uint32_t framing=status&VDMA_RECOVERABLE_FRAMING_ERRORS;
        if(framing || (status&VDMA_FATAL_ERRORS))video_last_error_status=status;
        if(framing && !(status&(VDMA_FATAL_ERRORS|XAXIVDMA_SR_HALTED_MASK))) {
            ++video_framing_recoveries;vh_abort_copy(service,0);video_quarantine=1;
            last_video_store=XAxiVdma_CurrFrameStore(&video_dma,XAXIVDMA_WRITE);
            (void)XAxiVdma_ClearDmaChannelErrors(&video_dma,XAXIVDMA_WRITE,framing);
            XAxiVdma_IntrClear(&video_dma,XAXIVDMA_IXR_ERROR_MASK,XAXIVDMA_WRITE);
        }
        video_faulted=vh_recovery_poll(service,timestamp_us());
    }
''' + text[end:]
    # Read-channel reset can proceed while capture/copy stay live. Never let
    # the ordinary starter race a reset still in flight.
    text = once(text, '    hdmi_output_poll(&video_dma, video_sequence);',
                '    if(!(vh_dma_mask&1u) || (vh_words[2]!=VH_STOP && vh_words[2]!=VH_RESET && vh_words[2]!=VH_CONFIG))\n'
                '        hdmi_output_poll(&video_dma, (vh_dma_mask&2u)?vh_clean:video_sequence);')
    return text


def apply_fusion(text):
    text = '#include "video_health.h"\n' + text
    text = once(text, 'static uint32_t stage, video_state, service_busy;',
                'static uint32_t stage, video_state, service_busy;\n'
                'static uint32_t video_recovery_epoch,job_video_epoch;\n'
                'extern void visual_tracker_video_break(void);\n'
                'extern void visual_tracker_video_pause(void);')
    text = once(text, 'int fusion_video_begin(uint32_t sequence,uint64_t timestamp) {', r'''
int fusion_video_recovery_suppressed(void) {return capture_state==2u || stage==9u;}
void fusion_video_invalidate(void) {
    ++video_recovery_epoch;classification_control_pending=0;
    visual_tracker_video_pause();
    /* Keep source-owned audio evidence, stop/manual state and requested mode.
     * In-flight inference checks this epoch after every cooperative yield. */
    /* Never relabel an SSD/classifier already executing on an old immutable
     * image: keep its saved epoch unchanged until its post-yield rejection.
     * Waiting/partial capture and an audio job may request a new frame. */
    if(video_state)video_state=(video_state==3u && stage!=0u)?0u:1u;
    result.video_timestamp_us=0;result.video_sequence=0;
}
void fusion_video_hard_invalidate(void) {
    fusion_video_invalidate();visual_tracker_video_break();
}
int fusion_video_begin(uint32_t sequence,uint64_t timestamp) {''')
    text = once(text, '    result.video_sequence=sequence;result.video_timestamp_us=timestamp;video_state=2;return 1;',
                '    job_video_epoch=video_recovery_epoch;\n'
                '    result.video_sequence=sequence;result.video_timestamp_us=timestamp;video_state=2;return 1;')
    old='if(job_mode!=requested_mode || active_policy!=requested_policy) {'
    new='if(job_mode!=requested_mode || active_policy!=requested_policy || job_video_epoch!=video_recovery_epoch) {'
    # Anchor only video jobs; a camera reset never invalidates independent
    # audio classification/DOA evidence or an audio-only job.
    for before,after in [
        ('        /* Commands received while inference yielded invalidate the old job. */\n        ',''),
        ('    if(stage==2) {\n        ',''),
        ('','\n            ssd_fast_reset();video_state=stage=0;return;\n        }\n        memcpy(image_logits,unified_logits,60);')]:
        text=once(text,before+old+after,before+new+after)
    return text


def apply_tracker(text):
    assert 'void visual_tracker_video_break(void)' not in text
    text=once(text,'static unsigned acquire_catchup;',
              'static unsigned acquire_catchup;\nstatic unsigned video_recovery_paused;')
    text=once(text,'    acquire_catchup=0;\n    active=processing=misses=0;',
              '    acquire_catchup=0;video_recovery_paused=0;\n    active=processing=misses=0;')
    old='    if(!have_frame || now-history[head].timestamp>VISUAL_TRACKER_FRAME_US){lost(VIDEO_STALE);return;}'
    text=once(text,old,r'''    if(video_recovery_paused) {
        /* A brief stream/DMA repair retains the verified anchor, never its
         * old control freshness. Keep the original video/miss timeouts. */
        if(now<last_processed || now-last_processed>VISUAL_TRACKER_FRAME_US) {
            lost(VIDEO_STALE);return;
        }
        if(misses && now-reacquire_started>=VISUAL_TRACKER_REACQUIRE_US) {
            lost(current_reason);return;
        }
        if(!have_frame || !history[head].valid || now<history[head].timestamp ||
           now-history[head].timestamp>VISUAL_SERVO_POSITION_MAX_AGE_US)return;
        video_recovery_paused=0;
    }
'''+old)
    return text+r'''
unsigned visual_tracker_video_active(void) {return active;}
void visual_tracker_video_pause(void) {
    /* Preserve template/identity/confirmation/miss clocks and last accepted
     * source timestamp. No old location is promoted to a fresh observation. */
    processing=0;acquire_catchup=active;video_recovery_paused=active;
    ssd_fast_reset();candidate_count=candidate_hits=unsupported=0;
    candidate_captured=selection_sequence=selection_captured=0;
    for(unsigned i=0;i<HISTORY;i++)history[i].valid=history[i].tracked=0;
    have_frame=head=pending=pixel_cursor=next_offset=0;
}
/* A changed camera generation must not reuse old image history. This avoids
 * rerunning NEON startup self-tests or clearing megabytes of image pixels. */
void visual_tracker_video_break(void) {
    visual_tracker_reset();
    for(unsigned i=0;i<HISTORY;i++)history[i].valid=history[i].tracked=0;
    have_frame=head=pending=pixel_cursor=next_offset=0;
}
'''
