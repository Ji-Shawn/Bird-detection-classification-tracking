#include "audio_worker.h"
#include "av_shared.h"
#include "xil_cache.h"
#include "xil_mmu.h"
#include "xil_printf.h"
#include "sd_writer.h"

static void record_yield(void *context) {
    (void)audio_worker_poll((audio_worker_state_t *)context);
}

int main(void) {
    audio_worker_state_t worker;
    volatile uint32_t *ready = (volatile uint32_t *)(uintptr_t)AV_SHARED_READY_ADDR;
    volatile uint32_t *shared_boot = (volatile uint32_t *)(uintptr_t)AV_SHARED_BOOT_ID_ADDR;
    uint32_t boot_id;
    Xil_SetTlbAttributes(AV_SHARED_BASE, NORM_NONCACHE);
    Xil_ICacheEnable(); Xil_DCacheEnable();
    do {
        platform_cache_invalidate((const void *)ready, sizeof(*ready));
    } while (*ready != AV_SHARED_READY_MAGIC);
    platform_cache_invalidate((const void *)shared_boot, sizeof(*shared_boot));
    boot_id = *shared_boot;
    audio_worker_init(&worker, boot_id);
    sd_writer_init(boot_id,record_yield,&worker);
    xil_printf("core1 audio ready\r\n");
    for (;;) {
        (void)audio_worker_poll(&worker);
        sd_writer_poll();
    }
}
