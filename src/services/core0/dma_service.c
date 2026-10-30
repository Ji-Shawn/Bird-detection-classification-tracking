#include "network_service.h"
#include "av_regs.h"
#include "fusion_bridge.h"
#include "visual_tracker.h"

#include "xaxidma.h"
#include "xaxivdma.h"
#include "xparameters.h"
#include "xtime_l.h"

#include <string.h>

#ifndef AV_REG_BASE
#define AV_REG_BASE 0x43C00000u
#endif

static XAxiVdma video_dma;
static XAxiDma audio_dma;
static uint32_t dma_boot_id;
static uint32_t audio_slot;
static uint32_t audio_sequence;
static uint32_t video_sequence;
static uint32_t last_video_store;
static int audio_active;
static uint64_t audio_started_us;
#define AUDIO_DMA_TIMEOUT_US 100000u
#define AUDIO_DMA_RESET_POLL_LIMIT 100000u
#define VIDEO_COPY_CHUNK_BYTES 65536u
static uint32_t video_copy_offset;
static uint32_t video_copy_frame_id;
static uint64_t video_copy_timestamp;
static uint8_t video_copy_dma_index;
static uint8_t video_copy_target;
static int video_copy_active;
static int fusion_copy_active;
/* PL owns brightness processing. PS only copies a complete immutable frame. */
volatile uint32_t video_last_mean_y, video_last_gain_q8;
volatile uint32_t video_raw_frames, video_enhanced_frames;
static uint8_t video_quarantine;
/* PG020 S2MM_VDMASR bit 15. SDK 2018.3's ERR_ALL_MASK omits EOLLate. */
#define VDMA_ERR_EOL_LATE 0x00008000u
volatile uint32_t video_framing_recoveries;
volatile uint32_t video_last_error_status;
#define VDMA_RECOVERABLE_FRAMING_ERRORS (XAXIVDMA_SR_ERR_INTERNAL_MASK | \
                                     XAXIVDMA_SR_ERR_FSZ_LESS_MASK | \
                                     XAXIVDMA_SR_ERR_LSZ_LESS_MASK | \
                                     XAXIVDMA_SR_ERR_FSZ_MORE_MASK | VDMA_ERR_EOL_LATE)
#define VDMA_FATAL_ERRORS (XAXIVDMA_SR_ERR_SLAVE_MASK | \
                           XAXIVDMA_SR_ERR_DECODE_MASK | \
                           XAXIVDMA_SR_ERR_SG_SLV_MASK | \
                           XAXIVDMA_SR_ERR_SG_DEC_MASK)

static uint64_t timestamp_us(void) {
    XTime ticks;
    XTime_GetTime(&ticks);
    return ((uint64_t)ticks * 1000000u) / COUNTS_PER_SECOND;
}

void network_audio_dma_complete(uint32_t slot, uint32_t boot_id,
                                uint32_t sequence, uint64_t timestamp) {
    av_shared_desc_t *desc;
    av_pcm_payload_t *payload;
    if (slot >= AV_PCM_RING_SLOTS) return;
    desc = (av_shared_desc_t *)(uintptr_t)(AV_PCM_DESC_BASE + slot * sizeof(*desc));
    payload = (av_pcm_payload_t *)(uintptr_t)(AV_PCM_PAYLOAD_BASE + slot * AV_PCM_SLOT_BYTES);
    platform_cache_invalidate(payload, sizeof(*payload));
    desc->boot_id = boot_id;
    desc->sequence = sequence;
    desc->payload_bytes = sizeof(*payload);
    desc->timestamp_us = timestamp;
    desc->error_flags = 0;
    platform_cache_flush(desc, sizeof(*desc));
    av_memory_barrier();
    desc->state = AV_DESC_READY;
    platform_cache_flush(desc, sizeof(*desc));
}

void network_video_complete(network_service_t *service, uint8_t buffer_index,
                            uint32_t frame_id, uint64_t timestamp) {
    uint32_t target = 0;
    if (video_copy_active) {
        service->video_drop_old++;
        return;
    }
    if (service->video[0].valid && service->video[1].valid) {
        service->video_drop_old++;
        return;
    }
    if (service->video[0].valid) target = 1u;
    video_copy_dma_index = buffer_index;
    video_copy_target = (uint8_t)target;
    video_copy_frame_id = frame_id;
    video_copy_timestamp = timestamp;
    video_copy_offset = 0u;
    video_copy_active = 1;
    visual_tracker_frame_begin(frame_id,timestamp);
    fusion_copy_active = fusion_video_begin(frame_id,timestamp);
}

static void video_copy_poll(network_service_t *service, uint32_t current_store) {
    uint32_t remaining;
    uint32_t bytes;
    const void *source;
    void *destination;
    if (!video_copy_active) return;
    if (current_store == video_copy_dma_index) {
        visual_tracker_frame_abort();
        if(fusion_copy_active)fusion_video_abort();
        fusion_copy_active=0;
        video_copy_active = 0;
        service->video_drop_old++;
        return;
    }
    remaining = AV_VIDEO_FRAME_BYTES - video_copy_offset;
    bytes = remaining < VIDEO_COPY_CHUNK_BYTES ? remaining : VIDEO_COPY_CHUNK_BYTES;
    source = (const void *)(uintptr_t)(AV_VIDEO_BUFFER_BASE +
             video_copy_dma_index * AV_VIDEO_FRAME_BYTES + video_copy_offset);
    destination = (void *)(uintptr_t)(AV_VIDEO_TX_BUFFER_BASE +
                  video_copy_target * AV_VIDEO_FRAME_BYTES + video_copy_offset);
    extern volatile uint32_t video_profile[16];
    uint32_t prof_t=platform_time_us();
    platform_cache_invalidate(source, bytes);
    video_profile[10]+=platform_time_us()-prof_t;prof_t=platform_time_us();
    memcpy(destination, source, bytes);
    video_profile[11]+=platform_time_us()-prof_t;prof_t=platform_time_us();
    visual_tracker_frame_chunk(destination,video_copy_offset,bytes);
    video_profile[12]+=platform_time_us()-prof_t;prof_t=platform_time_us();
    if(fusion_copy_active)fusion_video_chunk(destination,video_copy_offset,bytes);
    video_profile[13]+=platform_time_us()-prof_t;
    /* Staging is owned exclusively by Core0. The sender copies into a pbuf;
     * only that pbuf is consumed by Ethernet DMA. Keep these CPU-owned pixels
     * cached instead of flushing and then invalidating them in every packet.
     * Capture source invalidation above remains mandatory (VDMA producer). */
    video_copy_offset += bytes;
    if (video_copy_offset == AV_VIDEO_FRAME_BYTES) {
        /* Debug mirror of the latest PL frame statistic, not a new PS scan.
         * Wire telemetry already reads this same PL register independently. */
        video_last_mean_y = platform_mmio_read(AV_REG_BASE + AV_REG_MEAN_Y);
        video_last_gain_q8 = 256u;
        ++video_raw_frames;
        video_frame_t *frame = &service->video[video_copy_target];
        frame->buffer_index = video_copy_target;
        frame->frame_id = video_copy_frame_id;
        frame->timestamp_us = video_copy_timestamp;
        frame->next_fragment = 0u;
        frame->retry_active = 0u;
        frame->valid = 1u;
        video_copy_active = 0;
        visual_tracker_frame_end();
        if(fusion_copy_active)fusion_video_end();
        fusion_copy_active=0;
    }
}

static int start_audio_transfer(void) {
    av_shared_desc_t *desc = (av_shared_desc_t *)(uintptr_t)(AV_PCM_DESC_BASE +
                              audio_slot * sizeof(*desc));
    UINTPTR payload = (UINTPTR)(AV_PCM_PAYLOAD_BASE + audio_slot * AV_PCM_SLOT_BYTES);
    platform_cache_invalidate(desc, sizeof(*desc));
    if (desc->state != AV_DESC_FREE) return 0;
    desc->state = AV_DESC_WRITING;
    platform_cache_flush(desc, sizeof(*desc));
    if (XAxiDma_SimpleTransfer(&audio_dma, payload, sizeof(av_pcm_payload_t),
                               XAXIDMA_DEVICE_TO_DMA) != XST_SUCCESS) {
        desc->state = AV_DESC_FREE;
        platform_cache_flush(desc, sizeof(*desc));
        return -1;
    }
    audio_active = 1;
    audio_started_us = timestamp_us();
    return 1;
}

static int recover_audio_dma(void) {
    uint32_t attempt;
    if (audio_active) {
        av_shared_desc_t *desc = (av_shared_desc_t *)(uintptr_t)(AV_PCM_DESC_BASE +
                                  audio_slot * sizeof(*desc));
        desc->state = AV_DESC_FREE;
        platform_cache_flush(desc, sizeof(*desc));
        audio_active = 0;
    }
    XAxiDma_Reset(&audio_dma);
    for (attempt = 0u; attempt < AUDIO_DMA_RESET_POLL_LIMIT; ++attempt) {
        if (XAxiDma_ResetIsDone(&audio_dma)) {
            XAxiDma_IntrDisable(&audio_dma, XAXIDMA_IRQ_ALL_MASK,
                                XAXIDMA_DEVICE_TO_DMA);
            return 0;
        }
    }
    return -1;
}

int dma_service_init(network_service_t *service, uint32_t boot_id) {
    XAxiVdma_Config *video_config;
    XAxiVdma_DmaSetup write_config;
    XAxiDma_Config *audio_config;
    uint32_t index;
    (void)service;
    *(volatile uint32_t *)(uintptr_t)AV_SHARED_READY_ADDR = 0u;
    platform_cache_flush((const void *)(uintptr_t)AV_SHARED_READY_ADDR, sizeof(uint32_t));
    dma_boot_id = boot_id;
    for (index = 0; index < AV_PCM_RING_SLOTS; ++index) {
        av_shared_desc_t *desc = (av_shared_desc_t *)(uintptr_t)(AV_PCM_DESC_BASE + index * sizeof(*desc));
        memset(desc, 0, sizeof(*desc));
        platform_cache_flush(desc, sizeof(*desc));
    }
    for (index = 0; index < AV_RESULT_RING_SLOTS; ++index) {
        av_shared_desc_t *desc = (av_shared_desc_t *)(uintptr_t)(AV_RESULT_DESC_BASE + index * sizeof(*desc));
        memset(desc, 0, sizeof(*desc));
        platform_cache_flush(desc, sizeof(*desc));
    }
    video_config = XAxiVdma_LookupConfig(XPAR_VDMA_DEVICE_ID);
    if (video_config == 0 || XAxiVdma_CfgInitialize(&video_dma, video_config,
        video_config->BaseAddress) != XST_SUCCESS) return -1;
    memset(&write_config, 0, sizeof(write_config));
    write_config.VertSizeInput = AV_VIDEO_HEIGHT;
    write_config.HoriSizeInput = AV_VIDEO_STRIDE;
    write_config.Stride = AV_VIDEO_STRIDE;
    write_config.EnableCircularBuf = 1u;
    if (XAxiVdma_DmaConfig(&video_dma, XAXIVDMA_WRITE, &write_config) != XST_SUCCESS) return -2;
    for (index = 0; index < AV_VIDEO_BUFFER_COUNT; ++index)
        write_config.FrameStoreStartAddr[index] = AV_VIDEO_BUFFER_BASE + index * AV_VIDEO_FRAME_BYTES;
    if (XAxiVdma_DmaSetBufferAddr(&video_dma, XAXIVDMA_WRITE,
        write_config.FrameStoreStartAddr) != XST_SUCCESS) return -3;
    if (XAxiVdma_DmaStart(&video_dma, XAXIVDMA_WRITE) != XST_SUCCESS) return -4;
    last_video_store = XAxiVdma_CurrFrameStore(&video_dma, XAXIVDMA_WRITE);

    audio_config = XAxiDma_LookupConfig(XPAR_DMA_DEVICE_ID);
    if (audio_config == 0 || XAxiDma_CfgInitialize(&audio_dma, audio_config) != XST_SUCCESS ||
        XAxiDma_HasSg(&audio_dma)) return -5;
    XAxiDma_IntrDisable(&audio_dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
    audio_slot = audio_sequence = video_sequence = 0u;
    audio_active = 0;
    video_copy_active = 0;
    video_quarantine = 0u;
    video_framing_recoveries = video_last_error_status = 0u;
    video_raw_frames = video_enhanced_frames = 0u;
    video_last_mean_y = 0u; video_last_gain_q8 = 256u;
    platform_mmio_write(AV_REG_BASE + AV_REG_CONTROL,
        platform_mmio_read(AV_REG_BASE + AV_REG_CONTROL) | AV_CONTROL_ENHANCE_ENABLE);
    if (start_audio_transfer() < 0) return -6;
    av_memory_barrier();
    *(volatile uint32_t *)(uintptr_t)AV_SHARED_READY_ADDR = AV_SHARED_READY_MAGIC;
    platform_cache_flush((const void *)(uintptr_t)AV_SHARED_READY_ADDR, sizeof(uint32_t));
    return 0;
}

void dma_service_poll(network_service_t *service) {
    uint32_t current;
    int video_faulted = 0;
    /* VDMA can report a nonfatal short-frame condition during a running stream.
     * Clear it whenever it occurs so the next real SOF can start a new frame.
     * Do not publish the incomplete DMA buffer or hide bus/SG errors. */
    {
        uint32_t status = XAxiVdma_GetStatus(&video_dma, XAXIVDMA_WRITE);
        uint32_t framing = status & VDMA_RECOVERABLE_FRAMING_ERRORS;
        video_faulted = (status & (VDMA_FATAL_ERRORS | XAXIVDMA_SR_HALTED_MASK)) != 0u;
        if (framing != 0u || video_faulted) {
            video_last_error_status = status;
            if (video_copy_active == 1) {
                video_copy_active = 0;
                visual_tracker_frame_abort();
                if(fusion_copy_active)fusion_video_abort();
                fusion_copy_active=0;
            }
            video_quarantine = 1u;
            last_video_store = XAxiVdma_CurrFrameStore(&video_dma, XAXIVDMA_WRITE);
        }
        if (framing != 0u &&
            (status & (VDMA_FATAL_ERRORS | XAXIVDMA_SR_HALTED_MASK)) == 0u) {
            ++video_framing_recoveries;
            (void)XAxiVdma_ClearDmaChannelErrors(&video_dma, XAXIVDMA_WRITE,
                                                 framing);
            XAxiVdma_IntrClear(&video_dma, XAXIVDMA_IXR_ERROR_MASK,
                               XAXIVDMA_WRITE);
        }
    }
    {
        uint32_t status = XAxiDma_ReadReg(audio_dma.RegBase + XAXIDMA_RX_OFFSET,
                                          XAXIDMA_SR_OFFSET);
        int recovered = 0;
        if (audio_active &&
            (status & (XAXIDMA_ERR_ALL_MASK | XAXIDMA_HALTED_MASK |
                       XAXIDMA_IRQ_ERROR_MASK)) != 0u) {
            recovered = (recover_audio_dma() == 0);
        } else if (audio_active && (status & XAXIDMA_IDLE_MASK) != 0u) {
            uint32_t actual_bytes = XAxiDma_ReadReg(audio_dma.RegBase + XAXIDMA_RX_OFFSET,
                                                     XAXIDMA_BUFFLEN_OFFSET);
            if (actual_bytes == sizeof(av_pcm_payload_t)) {
                network_audio_dma_complete(audio_slot, dma_boot_id,
                                           audio_sequence++, timestamp_us());
                audio_slot = (audio_slot + 1u) % AV_PCM_RING_SLOTS;
                audio_active = 0;
                XAxiDma_IntrAckIrq(&audio_dma, XAXIDMA_IRQ_ALL_MASK,
                                   XAXIDMA_DEVICE_TO_DMA);
            } else recovered = (recover_audio_dma() == 0);
        } else if (audio_active &&
                   timestamp_us() - audio_started_us > AUDIO_DMA_TIMEOUT_US) {
            recovered = (recover_audio_dma() == 0);
        }
        if (!audio_active) {
            if (!recovered &&
                (status & (XAXIDMA_ERR_ALL_MASK | XAXIDMA_HALTED_MASK)) != 0u)
                recovered = (recover_audio_dma() == 0);
            if (recovered ||
                (status & (XAXIDMA_ERR_ALL_MASK | XAXIDMA_HALTED_MASK)) == 0u)
                (void)start_audio_transfer();
        }
    }
    /* Fatal errors remain visible for diagnosis, but must not stall audio. */
    if (video_faulted) return;
    current = XAxiVdma_CurrFrameStore(&video_dma, XAXIVDMA_WRITE);
    if (current != last_video_store && current < AV_VIDEO_BUFFER_COUNT) {
        uint32_t completed = (current + AV_VIDEO_BUFFER_COUNT - 1u) % AV_VIDEO_BUFFER_COUNT;
        /* The buffer being written at the error may contain only a prefix.
         * Discard its first completion, then accept a full clean frame. */
        if (video_quarantine) video_quarantine = 0u;
        else network_video_complete(service, (uint8_t)completed, video_sequence++, timestamp_us());
        last_video_store = current;
    }
    video_copy_poll(service, current);
}
