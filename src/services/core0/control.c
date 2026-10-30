#include "network_service.h"
#include "av_protocol.h"
#include "av_regs.h"
#include "fusion_bridge.h"
#include "bird_focus.h"
#include "servo_tracking.h"

#ifndef AV_REG_BASE
#define AV_REG_BASE 0x43C00000u
#endif
#ifdef M16_CAMERA_TEST
int ov5640_test_exposure(unsigned mode);
#endif

static uint16_t read_be16(const uint8_t *p) { return (uint16_t)(((uint16_t)p[0] << 8) | p[1]); }

static control_result_t apply_command(network_service_t *service, control_state_t *control,
                                      const uint8_t *p, uint16_t bytes) {
    uint32_t value;
    if (bytes == 0u) return CONTROL_REJECTED;
    switch (p[0]) {
    case 22: {
        extern volatile uint32_t video_fast_tracker;
        if(bytes!=2u || p[1]>1u)return CONTROL_REJECTED;
        video_fast_tracker=p[1];return CONTROL_APPLIED;
    }
    case 21: {
        extern volatile uint32_t network_video_gap_us;
        if(bytes!=3u || read_be16(p+1)>200u)return CONTROL_REJECTED;
        network_video_gap_us=read_be16(p+1);
        platform_cache_flush((const void *)&network_video_gap_us,sizeof(network_video_gap_us));
        return CONTROL_APPLIED;
    }
#ifdef M16_CAMERA_TEST
    case 20:
        return bytes==2u && ov5640_test_exposure(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
#endif
    case 1:
        if (bytes != 5u || p[1] >= p[2] || read_be16(p + 3) > 32767u) return CONTROL_REJECTED;
        value = platform_mmio_read(AV_REG_BASE + AV_REG_THRESHOLDS);
        value = (value & 0xFFFF0000u) | ((uint32_t)p[2] << 8) | p[1];
        platform_mmio_write(AV_REG_BASE + AV_REG_THRESHOLDS, value);
        platform_mmio_write(AV_REG_BASE + AV_REG_DARK_RATIO_ENTER, read_be16(p + 3));
        if (platform_mmio_read(AV_REG_BASE + AV_REG_THRESHOLDS) != value) return CONTROL_REJECTED;
        return CONTROL_APPLIED;
    case 2:
        if (bytes != 3u) return CONTROL_REJECTED;
        value = read_be16(p + 1);
        if (value < 300u || value > 380u) return CONTROL_REJECTED;
        control->sound_speed_mps = (uint16_t)value;
        return CONTROL_APPLIED;
    case 3:
        if (bytes != 3u) return CONTROL_REJECTED;
        value = read_be16(p + 1);
        if (value != NETWORK_COMPAT_PAYLOAD && value != NETWORK_JUMBO_PAYLOAD) return CONTROL_REJECTED;
        service->mtu_payload = value;
        return CONTROL_APPLIED;
    case 4:
        if (bytes != 2u || p[1] > 1u) return CONTROL_REJECTED;
        value = platform_mmio_read(AV_REG_BASE + AV_REG_CONTROL);
        value = (value & ~AV_CONTROL_ENHANCE_ENABLE) | (p[1] ? AV_CONTROL_ENHANCE_ENABLE : 0u);
        platform_mmio_write(AV_REG_BASE + AV_REG_CONTROL, value);
        return platform_mmio_read(AV_REG_BASE + AV_REG_CONTROL) == value ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 5:
        return bytes==2u && fusion_set_mode(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 6:
        return bytes==2u && fusion_capture_control(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 7:
        bird_focus_forget();
        return bytes==2u && ov5640_diagnostic_pattern(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 8: {
        uint16_t box[4];
        if(bytes!=10u)return CONTROL_REJECTED;
        for(unsigned i=0;i<4;i++)box[i]=read_be16(p+2+2*i);
        return fusion_set_image_policy(p[1],box)==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    }
    case 9:
        return bytes==2u && ov5640_diagnostic_phase(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 10:
        return bytes==2u && fusion_set_direction_threshold(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 11:
        return bytes==2u && bird_focus_control(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 12:
        return bytes==3u && bird_focus_manual(read_be16(p+1))==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 13:
        return bytes==2u && servo_tracking_pan(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 14:
        return bytes==3u && servo_tracking_tilt(read_be16(p+1))==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 18:
        return bytes==9u && servo_tracking_configure(read_be16(p+1),read_be16(p+3),
            read_be16(p+5),read_be16(p+7))==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 15:
        if(bytes!=2u || p[1]>2u)return CONTROL_REJECTED;
        uint32_t servo_status[10];servo_tracking_status(servo_status);
        if(!servo_status[1])return CONTROL_REJECTED;
        if(p[1]==2u) {
            uint32_t config[16],limits[8];
            servo_tracking_config_status(config);servo_tracking_limit_status(limits);
            if(!config[13] || !config[14] || !limits[2])return CONTROL_REJECTED;
        }
        if(p[1]) {
            // Visual mode bypasses audio; combined mode listens while seeking.
            if(fusion_set_image_policy(1,0) || fusion_set_mode(p[1]==2?2:1))return CONTROL_REJECTED;
        }
        return servo_tracking_auto(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 16:
        return bytes==2u && p[1]==1u && servo_tracking_keepalive()==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 17:
        return bytes==2u && servo_tracking_pan_limit(p[1])==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    case 19:
        if(bytes!=17u)return CONTROL_REJECTED;
        return servo_tracking_configure_visual(read_be16(p+1),read_be16(p+3),read_be16(p+5),read_be16(p+7),
            read_be16(p+9),read_be16(p+11),read_be16(p+13),read_be16(p+15))==0 ? CONTROL_APPLIED : CONTROL_REJECTED;
    default: return CONTROL_UNSUPPORTED;
    }
}

control_result_t control_handle(network_service_t *service, control_state_t *control,
                                uint32_t source_ipv4, uint32_t sequence,
                                const uint8_t *payload, uint16_t bytes, uint32_t now_ms) {
    uint32_t fingerprint, index;
    control_result_t result;
    if (source_ipv4 != control->allowed_ipv4 || payload == 0) return CONTROL_REJECTED;
    fingerprint = av_crc32(payload, bytes);
    for (index = 0; index < 16u; ++index)
        if (control->cache[index].valid && control->cache[index].sequence == sequence)
            return control->cache[index].fingerprint == fingerprint ?
                   (control_result_t)control->cache[index].result : CONTROL_REJECTED;
    if ((uint32_t)(now_ms - control->window_start_ms) >= 1000u) {
        control->window_start_ms = now_ms; control->attempts_in_window = 0;
    }
    if (control->attempts_in_window >= 20u) return CONTROL_REJECTED;
    control->attempts_in_window++;
    result = apply_command(service, control, payload, bytes);
    index = control->cache_next++ & 15u;
    control->cache[index].sequence = sequence;
    control->cache[index].fingerprint = fingerprint;
    control->cache[index].result = (uint8_t)result;
    control->cache[index].valid = 1u;
    return result;
}
