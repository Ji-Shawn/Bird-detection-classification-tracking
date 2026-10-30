#include "av_shared.h"
#include "audio_worker.h"

int av_ring_claim_ready(av_shared_desc_t *desc) {
    platform_cache_invalidate(desc, sizeof(*desc));
    if (desc->state != AV_DESC_READY) return 0;
    desc->state = AV_DESC_READING;
    av_memory_barrier();
    platform_cache_flush(desc, sizeof(*desc));
    return 1;
}

void av_ring_release_free(av_shared_desc_t *desc) {
    av_memory_barrier();
    desc->state = AV_DESC_FREE;
    platform_cache_flush(desc, sizeof(*desc));
}

int av_ring_publish(av_shared_desc_t *desc, const void *payload, uint32_t bytes,
                    uint32_t boot_id, uint32_t sequence, uint64_t timestamp_us) {
    platform_cache_invalidate(desc, sizeof(*desc));
    if (desc->state != AV_DESC_FREE) return 0;
    desc->state = AV_DESC_WRITING;
    platform_cache_flush(desc, sizeof(*desc));
    platform_cache_flush(payload, bytes);
    av_memory_barrier();
    desc->boot_id = boot_id;
    desc->sequence = sequence;
    desc->payload_bytes = bytes;
    desc->timestamp_us = timestamp_us;
    desc->error_flags = 0;
    platform_cache_flush(desc, sizeof(*desc));
    av_memory_barrier();
    desc->state = AV_DESC_READY;
    platform_cache_flush(desc, sizeof(*desc));
    return 1;
}
