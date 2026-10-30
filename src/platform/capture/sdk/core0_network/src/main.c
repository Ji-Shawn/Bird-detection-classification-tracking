#include "network_service.h"
#include "fusion_bridge.h"
#include "bird_focus.h"

#include "lwip/init.h"
#include "xil_cache.h"
#include "xil_mmu.h"
#include "xil_printf.h"
#include "xtime_l.h"
int ps_requant_selftest(void);
extern volatile unsigned m17_requant_test_count,m17_requant_test_errors;

int main(void) {
    network_service_t network;
    int camera_status;
    XTime now;
    uint32_t boot_id;
    volatile uint32_t *boot_counter =
        (volatile uint32_t *)(uintptr_t)AV_SHARED_BOOT_COUNTER_ADDR;
    /* The two AMP cores exchange ownership through this 1 MiB MMU section.
     * Keep it non-cacheable so descriptor state cannot be hidden in either
     * core's private cache or in the asymmetric L2 maintenance path. */
    Xil_SetTlbAttributes(AV_SHARED_BASE, NORM_NONCACHE);
    Xil_ICacheEnable(); Xil_DCacheEnable();
    if (ps_requant_selftest()!=0) {
        xil_printf("M17 NEON requant self-test failed\r\n");
        return 4;
    }
    Xil_DCacheFlushRange((UINTPTR)&m17_requant_test_count,sizeof(unsigned));
    Xil_DCacheFlushRange((UINTPTR)&m17_requant_test_errors,sizeof(unsigned));
    *(volatile uint32_t *)(uintptr_t)AV_SHARED_READY_ADDR = 0u;
    platform_cache_flush((const void *)(uintptr_t)AV_SHARED_READY_ADDR, sizeof(uint32_t));
    XTime_GetTime(&now);
    platform_cache_invalidate((const void *)boot_counter, 2u * sizeof(uint32_t));
    if ((boot_counter[0] ^ boot_counter[1]) == 0xFFFFFFFFu)
        boot_id = boot_counter[0] + 1u;
    else
        boot_id = (uint32_t)now ^ (uint32_t)(now >> 32) ^ 0xA7020A5Au;
    if (boot_id == 0u) boot_id = 1u;
    boot_counter[0] = boot_id;
    boot_counter[1] = ~boot_id;
    platform_cache_flush((const void *)boot_counter, 2u * sizeof(uint32_t));
    *(volatile uint32_t *)(uintptr_t)AV_SHARED_BOOT_ID_ADDR = boot_id;
    platform_cache_flush((const void *)(uintptr_t)AV_SHARED_BOOT_ID_ADDR, sizeof(uint32_t));
    *(volatile uint32_t *)(uintptr_t)AV_SHARED_AUDIO_DEADLINE_ADDR = 0u;
    platform_cache_flush((const void *)(uintptr_t)AV_SHARED_AUDIO_DEADLINE_ADDR, sizeof(uint32_t));
    lwip_init();
    network_service_init(&network, boot_id, 0);
    /* lwIP stores IPv4 addresses in network-byte order; this is 192.168.7.1. */
    if (network_platform_init(0x0107A8C0u, &network) != 0) {
        xil_printf("core0 network init failed\r\n");
        return 1;
    }
    fusion_init(&network);
    camera_status = ov5640_camera_prepare();
    if (camera_status != 0) xil_printf("OV5640 init failed: %d\r\n", camera_status);
    XTime_GetTime(&now);
    bird_focus_init(camera_status==0,(uint64_t)now*1000000/COUNTS_PER_SECOND);
    if (dma_service_init(&network, boot_id) != 0) {
        xil_printf("DMA init failed\r\n");
        return 2;
    }
    if (camera_status == 0 && ov5640_camera_start() != 0) return 3;
    xil_printf("core0 network ready\r\n");
    for (;;) {
        fusion_service_idle();
        fusion_poll();
    }
}
