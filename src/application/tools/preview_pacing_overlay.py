"""M41 network preview admission, independent of capture/tracker frame delivery.

Only completed RGB565 copies may enter the sender. At most one preview frame is
pending/in flight. Default admission spacing is 333334 us (3 FPS), configurable
from 1 to 4 FPS without changing physical capture.
Both slots remain protected by the original ownership rules; the spare slot can
continue delivering every available completed copy to NCC, focus and inference.
Sensor timings, full-frame bytes, packet pacing and inference are unchanged.
"""
MARK='/* M41 network preview admission only; capture and tracker cadence unchanged. */\n#include "stream_tuning.h"\n'
ANCHOR='void network_audio_dma_complete(uint32_t slot, uint32_t boot_id,'
HELPER=r'''/* M41: limit network publication after a complete copy, not at capture.
 * The RAM FPS limit is an upper bound, not a promise of received frames. Never queue a
 * second preview behind an active/retry frame: its spare slot belongs to copy.
 * Intentional pacing skips are separate from real video_drop_old/drop_tx. */
#define NETWORK_PREVIEW_MIN_INTERVAL_US stream_preview_interval_us()
static uint64_t preview_last_clock,preview_last_admit;
static unsigned preview_have_clock,preview_have_admit;
/* completed copies, admitted previews, cadence skips, occupied-sender skips,
 * disabled previews, clock rollback resets; remaining words reserved. */
volatile uint32_t network_preview_profile[8];
static void preview_pacing_reset(void) {
    preview_last_clock=preview_last_admit=0;
    preview_have_clock=preview_have_admit=0;
    memset((void *)network_preview_profile,0,sizeof network_preview_profile);
}
static unsigned preview_pacing_admit(const network_service_t *service,uint64_t now) {
    network_preview_profile[0]++;
    if(!board_network_preview) {
        preview_have_clock=preview_have_admit=0;
        network_preview_profile[4]++;return 0;
    }
    if(preview_have_clock && now<preview_last_clock) {
        /* Rebase conservatively: require one full normal interval before
         * another admission, even after repeated backward clock changes. */
        preview_last_clock=preview_last_admit=now;
        preview_have_clock=preview_have_admit=1;
        network_preview_profile[5]++;return 0;
    }
    preview_last_clock=now;preview_have_clock=1;
    for(unsigned slot=0;slot<NETWORK_VIDEO_PENDING;slot++)if(service->video[slot].valid) {
        network_preview_profile[3]++;return 0;
    }
    if(preview_have_admit && now-preview_last_admit<NETWORK_PREVIEW_MIN_INTERVAL_US) {
        network_preview_profile[2]++;return 0;
    }
    /* Date the actual admission, never an overdue schedule slot. */
    preview_last_admit=now;preview_have_admit=1;network_preview_profile[1]++;return 1;
}

'''
OLD_PUBLISH='        frame->valid = board_network_preview?1u:0u;'
NEW_PUBLISH='        frame->valid = (uint8_t)preview_pacing_admit(service,timestamp_us());'
OLD_INIT='''    video_copy_active = 0;
    video_quarantine = 0u;'''
NEW_INIT='''    video_copy_active = 0;
    preview_pacing_reset();
    video_quarantine = 0u;'''


def apply_dma(text):
    assert text.count(ANCHOR)==1 and text.count(OLD_PUBLISH)==1 and text.count(OLD_INIT)==1
    return (MARK+text.replace(ANCHOR,HELPER+ANCHOR,1)
        .replace(OLD_PUBLISH,NEW_PUBLISH,1).replace(OLD_INIT,NEW_INIT,1))


def revert_dma(text):
    assert text.startswith(MARK) and text.count(HELPER+ANCHOR)==1
    assert text.count(NEW_PUBLISH)==1 and text.count(NEW_INIT)==1
    return (text[len(MARK):].replace(HELPER+ANCHOR,ANCHOR,1)
        .replace(NEW_PUBLISH,OLD_PUBLISH,1).replace(NEW_INIT,OLD_INIT,1))
