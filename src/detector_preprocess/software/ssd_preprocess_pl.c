#include "ssd_preprocess_pl.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xtime_l.h"
#include <stddef.h>
#define BASE 0x40430000u
#define INPUT_BYTES (1920u*1080u*2u)
#define OUTPUT_BYTES (320u*320u*3u)
#define ERRORS 0x770u
#define IOC 0x1000u
volatile ssd_pl_stats_t ssd_pl_stats;
static int initialized,busy;
static uint32_t rd(unsigned o){return Xil_In32(BASE+o);}
static void wr(unsigned o,uint32_t v){Xil_Out32(BASE+o,v);}
static int timeout(XTime start){XTime t;XTime_GetTime(&t);return t-start>COUNTS_PER_SECOND;}
static int failed(void){
    ssd_pl_stats.mm_status=rd(4);ssd_pl_stats.ss_status=rd(0x34);
    ssd_pl_stats.disabled=1;ssd_pl_stats.failures++;wr(0,0);wr(0x30,0);
    /* Quiesce outstanding writes before allowing the PS reference to overwrite
     * this tensor. A stuck reset is fatal to this request, not a safe fallback. */
    wr(0,4);XTime start;XTime_GetTime(&start);
    while(rd(0)&4)if(timeout(start)){ssd_pl_stats.disabled=2;busy=0;return -2;}
    busy=0;return -1;
}
int ssd_preprocess_pl(const uint16_t *p,int w,int h,int8_t *out){
    if(ssd_pl_stats.disabled==2 || busy)return -2;
    if(!p||!out||w!=1920||h!=1080||ssd_pl_stats.disabled)return -1;
    /* Whole cache-line buffers: avoid invalidating another allocation. The
     * production frame and SSD tensor addresses are both page aligned. */
    if(((uintptr_t)p&63)||((uintptr_t)out&63))return -1;
    uintptr_t a=(uintptr_t)p,b=(uintptr_t)out;
    if(a<b+OUTPUT_BYTES && b<a+INPUT_BYTES)return -1;
    XTime start,end;XTime_GetTime(&start);busy=1;
    if(!initialized){wr(0,4);while(rd(0)&4)if(timeout(start))return failed();initialized=1;}
    /* This driver runs on Core0, whose BSP performs both L1 and L2 maintenance.
     * It must not be used from the AMP Core1 BSP (unlike Mel's NC buffers). */
    Xil_DCacheFlushRange((INTPTR)p,INPUT_BYTES);
    Xil_DCacheFlushRange((INTPTR)out,OUTPUT_BYTES);
    wr(4,0x7000);wr(0x34,0x7000);wr(0x30,1);wr(0,1);
    wr(0x48,(uint32_t)b);wr(0x58,OUTPUT_BYTES);
    wr(0x18,(uint32_t)a);wr(0x28,INPUT_BYTES);
    for(;;){uint32_t mm=rd(4),ss=rd(0x34);
        if((mm|ss)&ERRORS)return failed();
        if((mm&IOC)&&(ss&IOC))break;
        if(timeout(start))return failed();
    }
    if(rd(0x58)!=OUTPUT_BYTES)return failed();
    Xil_DCacheInvalidateRange((INTPTR)out,OUTPUT_BYTES);
    ssd_pl_stats.repairs+=ssd_repair_rounding(p,out);
    XTime_GetTime(&end);ssd_pl_stats.last_ticks=(uint32_t)(end-start);ssd_pl_stats.frames++;busy=0;
    return 0;
}
