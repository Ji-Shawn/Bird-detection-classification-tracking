#include <stdint.h>
#include <string.h>
#include "xil_cache.h"
#include "xtime_l.h"
#include "ssd_preprocess_pl.h"
int fusion_ssd_input_reference(const uint16_t *,int,int,int8_t *);
int logmel_test_timer_init(void);
void fusion_yield(void){}
static uint16_t image[1920*1080] __attribute__((aligned(64)));
static int8_t expected[307200] __attribute__((aligned(64)));
static int8_t actual[307200] __attribute__((aligned(64)));
/* magic,status,frames,mismatches,first_index,repairs,CPU ticks lo/hi,
 * PL ticks lo/hi,counts/second,failures,mm,ss,first got,want */
volatile uint32_t ssd_test_result[16] __attribute__((aligned(64)));
int main(void){
    Xil_ICacheEnable();Xil_DCacheEnable();memset((void *)ssd_test_result,0,sizeof ssd_test_result);
    if(logmel_test_timer_init()){ssd_test_result[1]=1;goto done;}
    uint64_t cpu=0,pl=0;uint32_t random=2276;
    for(unsigned frame=0;frame<12;frame++){
        for(unsigned i=0;i<1920u*1080u;i++){
            random^=random<<13;random^=random>>17;random^=random<<5;
            image[i]=frame==0?0:frame==1?65535:frame==2?(uint16_t)i:(uint16_t)random;
        }
        XTime start,end;XTime_GetTime(&start);
        if(fusion_ssd_input_reference(image,1920,1080,expected)){ssd_test_result[1]=2;goto done;}
        XTime_GetTime(&end);cpu+=end-start;
        memset(actual,0x55,sizeof actual);XTime_GetTime(&start);
        if(ssd_preprocess_pl(image,1920,1080,actual)){ssd_test_result[1]=3;goto done;}
        XTime_GetTime(&end);pl+=end-start;
        for(unsigned i=0;i<307200;i++)if(actual[i]!=expected[i]){
            if(!ssd_test_result[3]){ssd_test_result[4]=i;ssd_test_result[14]=(int32_t)actual[i];ssd_test_result[15]=(int32_t)expected[i];}
            ssd_test_result[3]++;
        }
        ssd_test_result[2]++;
    }
    ssd_test_result[6]=(uint32_t)cpu;ssd_test_result[7]=(uint32_t)(cpu>>32);
    ssd_test_result[8]=(uint32_t)pl;ssd_test_result[9]=(uint32_t)(pl>>32);
    ssd_test_result[10]=COUNTS_PER_SECOND;
done:
    ssd_test_result[5]=ssd_pl_stats.repairs;ssd_test_result[11]=ssd_pl_stats.failures;
    ssd_test_result[12]=ssd_pl_stats.mm_status;ssd_test_result[13]=ssd_pl_stats.ss_status;
    ssd_test_result[0]=0x53534414;
    Xil_DCacheFlushRange((INTPTR)ssd_test_result,sizeof ssd_test_result);
    for(;;)__asm__ volatile("wfe");
}
