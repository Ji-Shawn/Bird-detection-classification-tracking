/* Exercise production poll/copy code. Only external BSP/hardware is substituted. */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include "../../core0_network/src/dma_service.c"
uint32_t fake_video_status, fake_store, fake_cleared;
uint32_t fake_audio_status;
static unsigned fusion_ended, fusion_aborted;
/* Tracking consumes CPU-owned copies; this harness tests DMA ownership only. */
void visual_tracker_frame_begin(uint32_t sequence,uint64_t timestamp) {(void)sequence;(void)timestamp;}
void visual_tracker_frame_chunk(const void *p,uint32_t offset,uint32_t bytes) {(void)p;(void)offset;(void)bytes;}
void visual_tracker_frame_end(void) {}
void visual_tracker_frame_abort(void) {}
void visual_tracker_reset(void) {}
int fusion_video_begin(uint32_t sequence, uint64_t timestamp) { return 1; }
void fusion_video_chunk(const void *p,uint32_t offset,uint32_t bytes) {
    memcpy((void *)(uintptr_t)(FUSION_IMAGE+offset),p,bytes);
}
void fusion_video_end(void) { ++fusion_ended; }
void fusion_video_abort(void) { ++fusion_aborted; }
uint32_t platform_mmio_read(uint32_t a) {
    return a==AV_REG_BASE+AV_REG_MEAN_Y ? 137u : 1u;
}
void platform_mmio_write(uint32_t a, uint32_t v) {}
void platform_cache_flush(const void *p, uint32_t n) {}
void platform_cache_invalidate(const void *p, uint32_t n) {}
#define CHECK(c, msg) do { if (!(c)) { fprintf(stderr, "%s\n", msg); return 1; } } while (0)
int main(int argc, char **argv) {
    network_service_t service = {0};
    unsigned i;
    int which = argc > 1 ? atoi(argv[1]) : 0;
    void *ram = VirtualAlloc((void *)(uintptr_t)AV_SHARED_BASE, 0x01000000u,
                            MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    CHECK(ram == (void *)(uintptr_t)AV_SHARED_BASE, "test RAM allocation failed");
    ram = VirtualAlloc((void *)(uintptr_t)AV_VIDEO_BUFFER_BASE, 0x01800000u,
                       MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    CHECK(ram == (void *)(uintptr_t)AV_VIDEO_BUFFER_BASE, "HD video RAM allocation failed");
    if(which == 7) {
        network_video_complete(&service,0,0,0);
        video_copy_poll(&service,1);
        CHECK(video_copy_active && !service.video[0].valid,"partial frame published");
        video_copy_poll(&service,0);
        CHECK(!video_copy_active && !service.video[0].valid,"reused source accepted");
        CHECK(fusion_aborted==1 && fusion_ended==0,"partial inference frame accepted");
        return 0;
    }
    if (which == 6 || which == 8) {
        uint16_t *src=(uint16_t *)(uintptr_t)AV_VIDEO_BUFFER_BASE;
        uint16_t *dst=(uint16_t *)(uintptr_t)AV_VIDEO_TX_BUFFER_BASE;
        unsigned frame;
        for(frame=0;frame<2;++frame) {
            for(i=0;i<AV_VIDEO_FRAME_BYTES/2;++i) src[i]=frame?0x8410:0x2104;
            service.video[0].valid=0;
            network_video_complete(&service,0,frame,0);
            unsigned chunks=(AV_VIDEO_FRAME_BYTES+VIDEO_COPY_CHUNK_BYTES-1)/VIDEO_COPY_CHUNK_BYTES;
            for(i=0;i<chunks-1;++i) video_copy_poll(&service,1);
            CHECK(!service.video[0].valid,"incomplete staged frame published");
            video_copy_poll(&service,1);
            CHECK(dst[0]==(frame?0x8410:0x2104),"PS changed a PL-owned pixel");
            CHECK(service.video[0].valid,"safe frame was not published");
            if(which==8) {
                CHECK(video_last_mean_y==137u,"staging repeated PS pixel statistics instead of PL-owned statistics");
                CHECK(video_last_gain_q8==256u,"PS gain must remain bypassed");
            }
            CHECK(memcmp(dst,(void *)(uintptr_t)FUSION_IMAGE,AV_VIDEO_FRAME_BYTES)==0,
                  "inference and transmitted frame differ");
            CHECK(fusion_ended==frame+1,"missing inference frame completion");
            /* DMA may overwrite the source, never the completed staged copy. */
            memset(src,0,AV_VIDEO_FRAME_BYTES);
            for(i=0;i<113;++i) video_copy_poll(&service,0);
            CHECK(dst[0]==(frame?0x8410:0x2104),"staged frame reused source storage");
            for(i=1;i<AV_VIDEO_FRAME_BYTES/2;++i) CHECK(dst[i]==dst[0],"partial or mixed frame");
        }
        return 0;
    }
    audio_active = 1; /* Audio DMA remains busy; no audio restart is needed. */
    last_video_store = fake_store = 1;
    fake_video_status = (which == 2 || which == 5) ? 0x1D020u :
        which == 3 ? 0x1D001u :
        which == 4 ? 0x15080u : 0x1D000u;
    video_copy_active = 1;
    video_copy_dma_index = 0;
    if (which == 5) fake_audio_status = 2u;
    dma_service_poll(&service);
    if (which == 2 || which == 3 || which == 5) {
        CHECK(fake_cleared == 0, "fatal bus errors must not be cleared as framing errors");
        CHECK(!video_copy_active, "faulted DMA must cancel unfinished copy");
        CHECK(!service.video[0].valid, "faulted DMA published a frame");
        if (which == 5) {
            CHECK(audio_sequence == 1, "video fault blocked audio completion");
            CHECK(((av_shared_desc_t *)(uintptr_t)AV_PCM_DESC_BASE)->state == AV_DESC_READY,
                  "audio payload not published during video fault");
        }
        return 0;
    }
    CHECK((fake_video_status & 0x8080u) == 0, "framing error remains set: video cannot resume");
    CHECK(!video_copy_active, "damaged partial frame not cancelled");
    fake_store = 2;
    dma_service_poll(&service);
    CHECK(!video_copy_active, "first post-error store may be damaged; must quarantine");
    CHECK(!service.video[0].valid, "partial frame published after recovery");
    if (which == 1) {
        fake_video_status = 0x1D000u;
        dma_service_poll(&service);
        fake_store = 0;
        dma_service_poll(&service);
        CHECK(!video_copy_active, "repeated error must rearm quarantine");
        fake_store = 1;
    } else fake_store = 0;
    memset((void *)(uintptr_t)(AV_VIDEO_BUFFER_BASE +
           ((fake_store + 2) % 3) * AV_VIDEO_FRAME_BYTES), 0x5A, AV_VIDEO_FRAME_BYTES);
    for (i = 0; i < 120; ++i) dma_service_poll(&service);
    CHECK(service.video[0].valid, "complete clean frame did not resume after quarantine");
    CHECK(service.video[0].frame_id == 0, "recovery changed sender frame numbering");
    CHECK(memcmp((void *)(uintptr_t)AV_VIDEO_TX_BUFFER_BASE,
          (void *)(uintptr_t)(AV_VIDEO_BUFFER_BASE + ((fake_store + 2) % 3) * AV_VIDEO_FRAME_BYTES),
          AV_VIDEO_FRAME_BYTES) == 0, "resumed frame payload corrupted");
    return 0;
}
