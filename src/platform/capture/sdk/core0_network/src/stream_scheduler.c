#include "network_service.h"

#include <string.h>

void network_service_init(network_service_t *service, uint32_t boot_id, int jumbo) {
    memset(service, 0, sizeof(*service));
    service->boot_id = boot_id;
    service->mtu_payload = jumbo ? NETWORK_JUMBO_PAYLOAD : NETWORK_COMPAT_PAYLOAD;
}

unsigned network_scheduler_burst(network_service_t *service, uint32_t budget_us,
                                 unsigned max_packets) {
    uint32_t started = platform_time_us();
    unsigned completed = 0;
    if (!budget_us) return 0;
    while (completed < max_packets) {
        if (network_scheduler_poll(service) != 1) break;
        ++completed;
        if ((uint32_t)(platform_time_us() - started) >= budget_us) break;
    }
    return completed;
}

int network_scheduler_poll(network_service_t *service) {
    av_shared_desc_t *audio = (av_shared_desc_t *)(uintptr_t)(AV_RESULT_DESC_BASE +
                              service->audio_read_index * sizeof(*audio));
    uint32_t slot;
    video_frame_t *active_frame = 0;
    platform_cache_invalidate(audio, sizeof(*audio));
    if (audio->state == AV_DESC_READY) {
        audio->state = AV_DESC_READING; platform_cache_flush(audio, sizeof(*audio));
        if (udp_send_audio_result(service, service->audio_read_index) != 0) {
            audio->state = AV_DESC_READY; platform_cache_flush(audio, sizeof(*audio));
            return -1;
        }
        service->audio_read_index = (service->audio_read_index + 1u) % AV_RESULT_RING_SLOTS;
        return 1;
    }
    /* Status is deliberately above video; telemetry code clears the flag. */
    if (service->status_pending) return 2;
    /* Finish a frame once its first fragment has gone out.  Otherwise a
     * newly filled lower-numbered slot can indefinitely pause that frame. */
    for (slot = 0; slot < NETWORK_VIDEO_PENDING; ++slot) {
        if (service->video[slot].valid &&
            (service->video[slot].next_fragment != 0u || service->video[slot].retry_active)) {
            active_frame = &service->video[slot];
            break;
        }
    }
    if (active_frame == 0) {
        for (slot = 0; slot < NETWORK_VIDEO_PENDING; ++slot) {
            if (service->video[slot].valid) {
                active_frame = &service->video[slot];
                break;
            }
        }
    }
    if (active_frame != 0) {
        uint16_t count;
        uint32_t now=platform_time_us();
        if(active_frame->retry_active) {
            /* Keep ownership and fragment number until accepted. Audio was
             * serviced above; never spin or retain a blocked frame forever. */
            if((uint32_t)(now-active_frame->retry_started_us)>=20000u) {
                service->video_drop_tx++;active_frame->valid=0;return -2;
            }
            if((int32_t)(now-active_frame->retry_after_us)<0)return 0;
        }
        count = (uint16_t)((AV_VIDEO_FRAME_BYTES + service->mtu_payload - 1u) / service->mtu_payload);
        if (active_frame->next_fragment >= count) {
            active_frame->valid = 0;
            return 1;
        }
        int rc=udp_send_video_fragment(service, active_frame, active_frame->next_fragment, count);
        if(rc==NETWORK_SEND_RETRY) {
            if(!active_frame->retry_active) {
                active_frame->retry_active=1;active_frame->retry_started_us=now;
            }
            active_frame->retry_after_us=now+200u;
            return 0;
        }
        if (rc != 0) {
            service->video_drop_tx++; active_frame->valid = 0; return -2;
        }
        active_frame->retry_active=0;
        active_frame->next_fragment++;
        if (active_frame->next_fragment == count) active_frame->valid = 0;
        return 1;
    }
    return 0;
}
