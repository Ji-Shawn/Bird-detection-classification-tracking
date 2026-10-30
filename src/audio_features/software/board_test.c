#include <stdint.h>
#include <math.h>
#include "xil_cache.h"
#include "xtime_l.h"
#include "logmel_pl.h"
#include "board_vectors.h"
/* Compile the immutable production float reference into this validation ELF.
 * It is not used by the deployed PL fast path. */
#include "model_logmel32_reference.c"
volatile uint32_t logmel_test_result[16] __attribute__((aligned(64)));
int logmel_test_timer_init(void);
static void publish(void) { Xil_DCacheFlushRange((INTPTR)logmel_test_result,sizeof(logmel_test_result)); }
int main(void) {
    XTime a,b;uint64_t cpu_ticks=0,pl_ticks=0;
    float out[128],max_error=0;uint32_t round,f,k,bad=0;
    Xil_ICacheEnable();Xil_DCacheEnable();
    logmel_test_result[0]=0x4d454c31;logmel_test_result[1]=1;publish();
    logmel_test_result[11]=0x504d5536;logmel_test_result[12]=64;
    if(logmel_test_timer_init()!=0) {
        logmel_test_result[1]=0xdead0003;publish();goto finished;
    }
    init();
    for(round=0;round<5;round++) for(f=0;f<20;f++) {
        position=0;column=0;
        for(k=0;k<1024;k++)ring[k]=(float)board_pcm[f][k]/8388608.0f;
        XTime_GetTime(&a);transform();XTime_GetTime(&b);cpu_ticks+=b-a;
        XTime_GetTime(&a);
        if(logmel_pl_frame(board_pcm[f],out)!=0) {
            logmel_test_result[1]=0xdead0001;logmel_test_result[2]=round*20+f;publish();goto finished;
        }
        XTime_GetTime(&b);pl_ticks+=b-a;
        for(k=0;k<128;k++) {
            float error=fabsf(out[k]-working[k][0]);
            if(!isfinite(out[k]) || error>.12f)bad++;
            if(error>max_error)max_error=error;
        }
        logmel_test_result[2]=round*20+f+1;
    }
    logmel_test_result[3]=bad;
    logmel_test_result[4]=(uint32_t)(max_error*1000000.0f);
    logmel_test_result[5]=(uint32_t)cpu_ticks;logmel_test_result[6]=(uint32_t)(cpu_ticks>>32);
    logmel_test_result[7]=(uint32_t)pl_ticks;logmel_test_result[8]=(uint32_t)(pl_ticks>>32);
    logmel_test_result[9]=(uint32_t)COUNTS_PER_SECOND;
    logmel_test_result[10]=logmel_pl_stats.failures;
    logmel_test_result[1]=bad?0xdead0002:0x600d;publish();
finished:
    for(;;)__asm__ volatile("wfe");
}
