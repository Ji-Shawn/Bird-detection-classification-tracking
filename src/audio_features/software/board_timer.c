/* Isolated Core1 test only. No SCU/global/private timer writes.
 * ARM Cortex-A9 TRM DDI0388: PMCR.D selects CPU cycles / 64.
 * https://documentation-service.arm.com/static/5e8e2743fd977155116a5ea9
 * Scale by 32 to match BSP COUNTS_PER_SECOND = CPU clock / 2, allowing
 * the unchanged production DMA driver's timeout arithmetic to be exercised.
 */
#include <stdint.h>
#include "xtime_l.h"
static uint32_t previous;
static uint64_t elapsed;
static uint32_t cycles(void) {
    uint32_t value;
    __asm__ volatile("isb\n\tmrc p15, 0, %0, c9, c13, 0" : "=r"(value) :: "memory");
    return value;
}
int logmel_test_timer_init(void) {
    uint32_t value,i;
    __asm__ volatile("mrc p15, 0, %0, c9, c12, 0" : "=r"(value));
    value |= 13u; /* enable, reset CCNT, divide by 64 */
    __asm__ volatile("mcr p15, 0, %0, c9, c12, 0" :: "r"(value) : "memory");
    value=0x80000000u;
    __asm__ volatile("mcr p15, 0, %0, c9, c12, 1\n\tisb" :: "r"(value) : "memory");
    previous=cycles();elapsed=0;
    for(i=0;i<1024;i++) __asm__ volatile("nop" ::: "memory");
    return cycles()!=previous ? 0 : -1;
}
void logmel_test_get_time(XTime *value) {
    uint32_t now=cycles();
    elapsed+=(uint32_t)(now-previous);
    previous=now;
    *value=elapsed<<5;
}
