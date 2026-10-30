#include "logmel_pl.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xtime_l.h"
#include "xil_printf.h"
#include "xil_mmu.h"

#define DMA_BASE 0x40420000u
#define MM_CR 0x00u
#define MM_SR 0x04u
#define MM_ADDR 0x18u
#define MM_LEN 0x28u
#define SS_CR 0x30u
#define SS_SR 0x34u
#define SS_ADDR 0x48u
#define SS_LEN 0x58u
#define ERROR_MASK 0x00000770u
#define IOC 0x00001000u
#define TIMEOUT_TICKS (COUNTS_PER_SECOND / 10u)
/* Reserve the last 1 MiB of the original Core1 DDR allocation in our linker.
 * Core1's AMP BSP omits L2 maintenance. Use a dedicated noncacheable section
 * instead of relying on L1 flushes to make HP3 DMA coherent with shared L2. */
#define DMA_BUFFER_BASE 0x0ff00000u
#define INPUT_BYTES (1024u * sizeof(int32_t))
#define OUTPUT_BYTES (128u * sizeof(int32_t))
#ifdef LOGMEL_TEST_HOST
static int32_t input[1024] __attribute__((aligned(64)));
static int32_t output[128] __attribute__((aligned(64)));
#else
#define input ((int32_t *)(uintptr_t)DMA_BUFFER_BASE)
#define output ((int32_t *)(uintptr_t)(DMA_BUFFER_BASE + 0x1000u))
#endif
volatile logmel_pl_stats_t logmel_pl_stats;
static int initialized;
static uint32_t rd(uint32_t offset) { return Xil_In32(DMA_BASE+offset); }
static void wr(uint32_t offset,uint32_t value) { Xil_Out32(DMA_BASE+offset,value); }
static int expired(XTime start) { XTime now;XTime_GetTime(&now);return (now-start)>TIMEOUT_TICKS; }
static int fail(void) {
    logmel_pl_stats.last_mm2s_status=rd(MM_SR);
    logmel_pl_stats.last_s2mm_status=rd(SS_SR);
    ++logmel_pl_stats.failures;logmel_pl_stats.disabled=1;
    /* Do not restart a partially consumed frame. Stop DMA and permanently use
     * the software reference until the next paired board boot. */
    wr(MM_CR,0);wr(SS_CR,0);
    xil_printf("LOGMEL_PL_DISABLED mm=%08x ss=%08x\r\n",
        logmel_pl_stats.last_mm2s_status,logmel_pl_stats.last_s2mm_status);
    return -1;
}
int logmel_pl_frame(const int32_t pcm[1024],float db[128]) {
    XTime start,end;uint32_t i,mm,ss;
    if(logmel_pl_stats.disabled) return -1;
    XTime_GetTime(&start);
    if(!initialized) {
        Xil_SetTlbAttributes(DMA_BUFFER_BASE,NORM_NONCACHE);
        wr(MM_CR,4);
        while(rd(MM_CR)&4) if(expired(start)) return fail();
        initialized=1;
    }
    for(i=0;i<1024;i++) input[i]=pcm[i];
    Xil_DCacheFlushRange((INTPTR)input,INPUT_BYTES);
    Xil_DCacheFlushRange((INTPTR)output,OUTPUT_BYTES);
    wr(MM_SR,0x7000);wr(SS_SR,0x7000);
    wr(SS_CR,1);wr(MM_CR,1);
    wr(SS_ADDR,(uint32_t)(uintptr_t)output);wr(SS_LEN,OUTPUT_BYTES);
    wr(MM_ADDR,(uint32_t)(uintptr_t)input);wr(MM_LEN,INPUT_BYTES);
    for(;;) {
        mm=rd(MM_SR);ss=rd(SS_SR);
        if((mm|ss)&ERROR_MASK) return fail();
        if((mm&IOC)&&(ss&IOC)) break;
        if(expired(start)) return fail();
    }
    if(rd(SS_LEN)!=OUTPUT_BYTES) return fail();
    Xil_DCacheInvalidateRange((INTPTR)output,OUTPUT_BYTES);
    for(i=0;i<128;i++) db[i]=(float)output[i]/65536.0f;
    XTime_GetTime(&end);
    logmel_pl_stats.last_ticks=(uint32_t)(end-start);
    if(logmel_pl_stats.last_ticks>logmel_pl_stats.max_ticks)
        logmel_pl_stats.max_ticks=logmel_pl_stats.last_ticks;
    ++logmel_pl_stats.frames;
    return 0;
}
