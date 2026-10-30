/* One ELF, persistent weights and model state, sequential ownership of PL/DMA.
 * Command and status use separate cache lines. Host writes sequence last and
 * never alters inputs/commands while BUSY. Outputs survive the next model run.
 */
#include <string.h>
#include "xil_cache.h"
#include "xil_exception.h"
#include "xil_types.h"
#include "runtime.h"

#define COMMAND ((volatile u32 *)0x2E000000u)
#define STATUS  ((volatile u32 *)0x2E000040u)
#define CLASS_MB ((volatile u32 *)0x20000000u)
#define SSD_MB ((volatile u32 *)0x2F000000u)
#define MODEL_RESULT(id) (0x2E010000u + ((id)-1u)*0x4000u)
#define READY 1u
#define BUSY 2u
#define DONE 3u
#define ERROR 4u
#define FAULT 5u

int unified_validate;
int8_t unified_logits[60];

static inline u32 ticks(void) {
    u32 v;
    __asm__ volatile("mrc p15, 0, %0, c9, c13, 0":"=r"(v));
    return v;
}
static void timer_enable(void) {
    u32 v;
    __asm__ volatile("mrc p15, 0, %0, c9, c12, 0":"=r"(v));
    v |= 1;
    __asm__ volatile("mcr p15, 0, %0, c9, c12, 0"::"r"(v));
    __asm__ volatile("mcr p15, 0, %0, c9, c12, 1"::"r"(0x80000000u));
}
static void publish(void) {
    Xil_DCacheFlushRange((UINTPTR)STATUS,64);
    __asm__ volatile("dsb sy":::"memory");
}
static void data_abort(void *unused) {
    u32 address, reason;
    (void)unused;
    __asm__ volatile("mrc p15, 0, %0, c6, c0, 0":"=r"(address));
    __asm__ volatile("mrc p15, 0, %0, c5, c0, 0":"=r"(reason));
    STATUS[2]=FAULT; STATUS[4]=(u32)-200; STATUS[10]=address; STATUS[11]=reason;
    publish();
    for (;;) { __asm__ volatile("nop"); }
}
static int run_model(u32 id, u32 sequence) {
    volatile u32 *out=(volatile u32 *)MODEL_RESULT(id);
    int result;
    u32 start=ticks(), timeout=0;
    STATUS[5]=id;
    publish();
    memset((void *)out,0,0x4000);
    out[0]=0x4D4F4431u; out[1]=id; out[2]=sequence; out[5]=unified_validate;
    /* No ownership change until the last accelerator transaction completed. */
    while (!(*(volatile u32 *)0x43C00000u & 4u)) {
        if (++timeout>=50000000u) { out[3]=(u32)-201; Xil_DCacheFlushRange((UINTPTR)out,64); return -201; }
    }
    memset(unified_logits,0,sizeof unified_logits);
    Xil_DCacheFlush();
    if (id==1 || id==2) {
        memset((void *)CLASS_MB,0,64);
        CLASS_MB[0]=0xC0DE0004u; CLASS_MB[5]=51; CLASS_MB[6]=1; CLASS_MB[7]=0x4D454D43u;
        Xil_DCacheFlushRange((UINTPTR)CLASS_MB,64);
        result=id==1?audio_run():image_run();
        if (!result && CLASS_MB[13]!=0x600D) result=-202;
        memcpy((void *)((UINTPTR)out+0x40),unified_logits,60);
        memcpy((void *)((UINTPTR)out+0x100),(const void *)0x20000500u,64);
        memcpy((void *)((UINTPTR)out+0x200),(const void *)0x20000100u,62*16);
        out[6]=62; out[7]=*(volatile u32 *)0x2000050Cu;
    } else {
        memset((void *)SSD_MB,0,64);
        SSD_MB[0]=0x53534431u; SSD_MB[6]=1; SSD_MB[7]=0x4D454D43u;
        Xil_DCacheFlushRange((UINTPTR)SSD_MB,64);
        result=ssd_run();
        if (!result && SSD_MB[13]!=0x600D) result=-203;
        memcpy((void *)((UINTPTR)out+0x100),(const void *)0x2F001000u,64);
        memcpy((void *)((UINTPTR)out+0x200),(const void *)0x2F000100u,98*16);
        u32 count=*(volatile u32 *)0x2F001010u;
        if (count>100) { result=-204; count=0; }
        memcpy((void *)((UINTPTR)out+0x1000),(const void *)0x2F002000u,count*24);
        out[6]=98; out[7]=count;
    }
    out[3]=(u32)result; out[4]=ticks()-start;
    Xil_DCacheFlushRange((UINTPTR)out,0x4000);
    if (!result) STATUS[6] |= 1u<<(id-1);
    return result;
}

int main(void) {
    u32 last=0;
    memset((void *)STATUS,0,64);
    memset((void *)COMMAND,0,64);
    Xil_DCacheFlushRange((UINTPTR)COMMAND,64);
    timer_enable();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_DATA_ABORT_INT,data_abort,0);
    STATUS[0]=0x554E4931u; STATUS[1]=1; STATUS[2]=READY;
    publish();
    for (;;) {
        Xil_DCacheInvalidateRange((UINTPTR)COMMAND,64);
        u32 sequence=COMMAND[0];
        if (!sequence || sequence==last) {
            for (volatile int delay=0; delay<1024; delay++) { }
            continue;
        }
        u32 id=COMMAND[1], validate=COMMAND[2];
        last=sequence;
        STATUS[2]=BUSY; STATUS[3]=sequence; STATUS[4]=0; STATUS[5]=0; STATUS[6]=0;
        publish();
        int result=0;
        u32 start=ticks();
        if (id<1 || id>4 || validate>1) result=-100;
        else {
            unified_validate=(int)validate;
            if (id==4) {
                const u32 order[3]={1,3,2}; /* audio -> detection -> full-frame classification */
                for (int i=0;i<3;i++) { result=run_model(order[i],sequence); if (result) break; }
            } else result=run_model(id,sequence);
        }
        STATUS[4]=(u32)result; STATUS[7]=ticks()-start;
        if (!result) { STATUS[2]=DONE; STATUS[8]++; }
        else STATUS[2]=result==-100?ERROR:FAULT;
        publish();
        if (STATUS[2]==FAULT) {
            /* Hardware faults require host preflight; never run another model
             * on a possibly incomplete stream or contaminated DMA state. */
            for (;;) { __asm__ volatile("nop"); }
        }
    }
}
