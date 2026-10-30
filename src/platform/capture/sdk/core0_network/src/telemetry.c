#include "sd_record.h"
#include "stream_tuning.h"
#include "sound_round_tuning.h"
#include "sound_tuning.h"
#include "network_service.h"
#include "av_protocol.h"
#include "av_regs.h"
#include "fusion_bridge.h"
#include "bird_focus.h"
#include "servo_tracking.h"
#include "visual_tracker.h"
#include "video_health.h"
#include "xtime_l.h"
#include <string.h>
#include <stddef.h>

#ifndef AV_REG_BASE
#define AV_REG_BASE 0x43C00000u
#endif

typedef struct __attribute__((packed)) {
    uint32_t protocol_version, register_version, build_id, boot_id, uptime_ms;
    uint32_t frame_count, video_drop_old, video_drop_tx, model_mel_drop;
    uint32_t audio_deadline_miss, status_flags;
    uint16_t mean_y, dark_ratio_q15;
    uint32_t fusion_mode, capture_state;
    uint32_t audio_health[16];
    uint32_t direction_threshold_percent, direction_bird_class, direction_bird_score_bits, direction_age_ms;
    uint32_t bird_focus[16];
    uint32_t focus_diagnostic[8];
    uint32_t manual_focus[6]; /* Optional MF01 extension; legacy 232 bytes unchanged. */
    uint32_t servo_tracking[10]; /* SRV1 extension at byte 256. */
    uint32_t bird_detection[10]; /* TRK1 current camera-space target at byte 296. */
    uint32_t servo_diagnostic[10]; /* SRV2 at byte 336. */
    uint32_t servo_guard[8]; /* SRV3 at byte 376. */
    uint32_t visual_tracker[16]; /* TRK2 PS tracker at byte 408, incl. display-only current box. */
    uint32_t sound_tracking[8]; /* SND1 optional extension at byte 472. */
    uint32_t servo_limits[8]; /* SRV4 position policy at byte 504. */
    uint32_t servo_limit_switch[4]; /* SRV5 explicit angle-limit switch at byte 536. */
    uint32_t tracker_diagnostic[16]; /* TRK3 reacquisition state at byte 552. */
    uint32_t servo_config[16]; /* SRV6 adjustable pan settings at byte 616. */
    uint32_t servo_visual_config[16]; /* SRV7 near-center visual control at byte 680. */
    uint32_t target_selection[12]; /* TRK4 candidate association at byte 744. */
    uint32_t servo_position[12]; /* SRV8 positional pan at byte 792. */
    uint32_t visual_tuning[16]; /* SRV9 v1 RAM-only P control, appended at byte 840. */
    uint32_t audio_tuning[16]; /* SND2 v1 RAM-only sound parameters at byte 904. */
    uint32_t stream_tuning[16]; /* SCN2 v1 scan/preview RAM settings at byte 968. */
    uint32_t video_health[32]; /* VH01 v1 capture/recovery at byte 1032. */
    uint32_t video_input_diag[8]; /* VC01 v1 input/service evidence at byte 1160. */
    uint32_t sound_round_tuning[16]; /* SRT2 v1 audio timing at byte 1192. */
    uint32_t visual_feedforward[32]; /* VFF1 v1 motion observer at byte 1256. */
    uint32_t sd_record[12]; /* SDR2 at 1384. */
} telemetry_v1_t;
_Static_assert(sizeof(telemetry_v1_t)<=NETWORK_STATUS_PAYLOAD_MAX,
               "STATUS payload exceeds standard IPv4 MTU");
_Static_assert(offsetof(telemetry_v1_t,servo_guard)==376 &&
               offsetof(telemetry_v1_t,visual_tracker)==408 &&
               offsetof(telemetry_v1_t,sound_tracking)==472 &&
               offsetof(telemetry_v1_t,servo_limits)==504 &&
               offsetof(telemetry_v1_t,servo_limit_switch)==536 &&
               offsetof(telemetry_v1_t,tracker_diagnostic)==552 &&
               offsetof(telemetry_v1_t,servo_config)==616 &&
               offsetof(telemetry_v1_t,servo_visual_config)==680 &&
               offsetof(telemetry_v1_t,target_selection)==744 &&
               offsetof(telemetry_v1_t,servo_position)==792 &&
               offsetof(telemetry_v1_t,visual_tuning)==840 &&
               offsetof(telemetry_v1_t,audio_tuning)==904 &&
               offsetof(telemetry_v1_t,stream_tuning)==968 &&
               offsetof(telemetry_v1_t,video_health)==1032 &&
               offsetof(telemetry_v1_t,video_input_diag)==1160 &&
               offsetof(telemetry_v1_t,sound_round_tuning)==1192 &&
               offsetof(telemetry_v1_t,visual_feedforward)==1256 && offsetof(telemetry_v1_t,sd_record)==1384 && sizeof(telemetry_v1_t)==1432,
               "Tracker telemetry wire layout");

static uint32_t swap32(uint32_t v) {
    return ((v & 0xFFu) << 24) | ((v & 0xFF00u) << 8) |
           ((v >> 8) & 0xFF00u) | ((v >> 24) & 0xFFu);
}
static uint16_t swap16(uint16_t v) { return (uint16_t)((v << 8) | (v >> 8)); }

int telemetry_send(network_service_t *service, uint32_t sequence,
                   uint32_t uptime_ms, uint32_t audio_deadline_miss) {
    telemetry_v1_t t;
    t.protocol_version = swap32((AV_PROTOCOL_MAJOR << 16) | AV_PROTOCOL_MINOR);
    t.register_version = swap32(platform_mmio_read(AV_REG_BASE + AV_REG_VERSION));
    t.build_id = swap32(platform_mmio_read(AV_REG_BASE + AV_REG_BUILD_ID));
    t.boot_id = swap32(service->boot_id); t.uptime_ms = swap32(uptime_ms);
    t.frame_count = swap32(platform_mmio_read(AV_REG_BASE + AV_REG_FRAME_COUNT));
    t.video_drop_old = swap32(service->video_drop_old);
    t.video_drop_tx = swap32(service->video_drop_tx);
    t.model_mel_drop = swap32(platform_mmio_read(AV_REG_BASE + AV_REG_MEL_DROP_COUNT));
    t.audio_deadline_miss = swap32(audio_deadline_miss);
    t.status_flags = swap32(platform_mmio_read(AV_REG_BASE + AV_REG_STATUS));
    t.mean_y = swap16((uint16_t)platform_mmio_read(AV_REG_BASE + AV_REG_MEAN_Y));
    t.dark_ratio_q15 = swap16((uint16_t)platform_mmio_read(AV_REG_BASE + AV_REG_DARK_RATIO_Q15));
    t.fusion_mode=swap32(fusion_mode());t.capture_state=swap32(fusion_capture_state());
    volatile uint32_t *h=(volatile uint32_t *)FUSION_AUDIO_HEALTH;
    uint32_t before=h[0];av_memory_barrier();
    for(unsigned i=0;i<16;i++)t.audio_health[i]=swap32(h[i]);
    av_memory_barrier();
    if((before&1u) || h[0]!=before)memset(t.audio_health,0,sizeof t.audio_health);
    uint32_t percent,bird,age,bits;float score;
    fusion_direction_status(&percent,&bird,&score,&age);memcpy(&bits,&score,4);
    t.direction_threshold_percent=swap32(percent);t.direction_bird_class=swap32(bird);
    t.direction_bird_score_bits=swap32(bits);t.direction_age_ms=swap32(age);
    uint32_t focus[16];XTime now;XTime_GetTime(&now);
    bird_focus_status(focus,(uint64_t)now*1000000/COUNTS_PER_SECOND);
    for(unsigned i=0;i<16;i++)t.bird_focus[i]=swap32(focus[i]);
    for(unsigned i=0;i<8;i++)t.focus_diagnostic[i]=swap32(bird_focus_diag[i]);
    uint32_t manual[6];bird_focus_manual_status(manual);
    for(unsigned i=0;i<6;i++)t.manual_focus[i]=swap32(manual[i]);
    uint32_t servo[10];servo_tracking_status(servo);
    for(unsigned i=0;i<10;i++)t.servo_tracking[i]=swap32(servo[i]);
    uint32_t detection[10];servo_tracking_detection(detection);
    for(unsigned i=0;i<10;i++)t.bird_detection[i]=swap32(detection[i]);
    uint32_t diagnostic[10];servo_tracking_diagnostic(diagnostic);
    for(unsigned i=0;i<10;i++)t.servo_diagnostic[i]=swap32(diagnostic[i]);
    uint32_t guard[8];servo_tracking_guard_status(guard);
    for(unsigned i=0;i<8;i++)t.servo_guard[i]=swap32(guard[i]);
    uint32_t tracker[16];visual_tracker_status(tracker,(uint64_t)now*1000000/COUNTS_PER_SECOND);
    for(unsigned i=0;i<16;i++)t.visual_tracker[i]=swap32(tracker[i]);
    uint32_t sound[8];servo_tracking_sound_status(sound);
    for(unsigned i=0;i<8;i++)t.sound_tracking[i]=swap32(sound[i]);
    uint32_t limits[8];servo_tracking_limit_status(limits);
    for(unsigned i=0;i<8;i++)t.servo_limits[i]=swap32(limits[i]);
    uint32_t limit_switch[4];servo_tracking_limit_switch_status(limit_switch);
    for(unsigned i=0;i<4;i++)t.servo_limit_switch[i]=swap32(limit_switch[i]);
    uint32_t tracker_diag[16];visual_tracker_diagnostic(tracker_diag,(uint64_t)now*1000000/COUNTS_PER_SECOND);
    for(unsigned i=0;i<16;i++)t.tracker_diagnostic[i]=swap32(tracker_diag[i]);
    uint32_t config[16];servo_tracking_config_status(config);
    for(unsigned i=0;i<16;i++)t.servo_config[i]=swap32(config[i]);
    uint32_t visual_config[16];servo_tracking_visual_config_status(visual_config);
    for(unsigned i=0;i<16;i++)t.servo_visual_config[i]=swap32(visual_config[i]);
    uint32_t selection[12];visual_tracker_selection_status(selection);
    for(unsigned i=0;i<12;i++)t.target_selection[i]=swap32(selection[i]);
    uint32_t position[12];servo_tracking_position_status(position);
    for(unsigned i=0;i<12;i++)t.servo_position[i]=swap32(position[i]);
    uint32_t tuning[16];servo_tracking_tuning_status(tuning,service->boot_id);
    for(unsigned i=0;i<16;i++)t.visual_tuning[i]=swap32(tuning[i]);
    uint32_t audio_tuning[16];servo_tracking_audio_status(audio_tuning,service->boot_id);
    for(unsigned i=0;i<16;i++)t.audio_tuning[i]=swap32(audio_tuning[i]);
    uint32_t stream_tuning[16];stream_tuning_status(stream_tuning,service->boot_id);
    for(unsigned i=0;i<16;i++)t.stream_tuning[i]=swap32(stream_tuning[i]);
    uint32_t health[32];video_health_words(health);
    for(unsigned i=0;i<32;i++)t.video_health[i]=swap32(health[i]);
    /* Read-only MMIO, no sensor bus traffic in healthy tracking. The probe's
     * historical *_seen bits do not prove current PCLK/VSYNC activity. Capture
     * the first telemetry observation of a new fault for later comparison. */
    static uint32_t fault_event, fault_probe;
    uint32_t probe=platform_mmio_read(0x41200008u);
    if(health[11]!=fault_event){fault_event=health[11];fault_probe=probe;}
    extern volatile uint32_t video_profile[16];
    uint32_t input[8]={0x56433031u,1u,probe,fault_probe,video_profile[9],
                       video_profile[0],video_profile[1],focus[2]};
    for(unsigned i=0;i<8;i++)t.video_input_diag[i]=swap32(input[i]);
    uint32_t round[16];sound_round_tuning_status(round,service->boot_id,(uint64_t)now*1000000/COUNTS_PER_SECOND);
    for(unsigned i=0;i<16;i++)t.sound_round_tuning[i]=swap32(round[i]);
    uint32_t ff[32];servo_tracking_feedforward_status(ff,service->boot_id,(uint64_t)now*1000000/COUNTS_PER_SECOND);
    for(unsigned i=0;i<32;i++)t.visual_feedforward[i]=swap32(ff[i]);
    uint32_t sd[12];sd_record_status(sd);
    for(unsigned i=0;i<12;i++)t.sd_record[i]=swap32(sd[i]);
    return udp_send_status_payload(service, sequence, &t, sizeof(t));
}
