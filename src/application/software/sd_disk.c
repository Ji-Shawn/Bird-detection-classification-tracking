/* M48 Core1 only: explicit SDPS backend. No success path without actual I/O.
 * FatFs buffers need not be cache-line aligned; ALL ADMA uses bounce[] instead.
 * Core1's USE_AMP BSP only maintains L1, not the shared L2. Therefore DMA
 * instance/descriptors, bounce and vendor SCR/SWITCH/EXT_CSD buffers all live
 * in a private noncacheable 1 MiB region. Never rely on L1-only invalidation
 * to make SD DMA writes visible, and never change global L2 state.
 */
#include "sd_disk.h"
#include "sd_vendor/ff.h"
#include "sd_vendor/diskio.h"
#include "sd_vendor/xsdps.h"
#include "xil_io.h"
#include "xil_mmu.h"
#include "sd_record.h"
#include "xtime_l.h"
#include <string.h>
#define card (*(XSdPs *)(uintptr_t)SD_DISK_DMA_BASE)
#define bounce ((uint8_t *)(uintptr_t)(SD_DISK_DMA_BASE+0x2000u))
_Static_assert(sizeof(XSdPs)<=0x2000u,"SDPS instance and ADMA fit reserved DMA range");
/* Copied hardware facts from the paired 2023.2 FSBL xparameters/config table.
 * PS7 SD0 @ E0100000, 100MHz input, CD yes/WP no, MIO bank0, noncoherent. */
static XSdPs_Config config={0,0xE0100000u,100000000u,1,0,0,0,0,0,0,0,0,0,0,0,0};
static DSTATUS state=STA_NOINIT;
static void (*yield_callback)(void *);
static void *yield_context;
static unsigned in_yield,in_io;
static uint32_t worst_us,yield_count;
static uint64_t last_yield;
static uint64_t now_us(void){XTime t;XTime_GetTime(&t);return (uint64_t)t*1000000u/COUNTS_PER_SECOND;}
static void cooperate(void){
    uint64_t now=now_us();
    if(!in_yield && yield_callback && (now<last_yield || now-last_yield>=250u)){
        last_yield=now;in_yield=1;++yield_count;yield_callback(yield_context);in_yield=0;
    }
}
void sd_disk_set_yield(void (*callback)(void *),void *context){
    /* Core0 flushes complete payload ranges to DDR before READY. Core1 reads
     * those immutable slots uncached, so its AMP L1-only APIs cannot retain
     * old photos in L2. The mailbox already uses AV_SHARED_BASE NORM_NONCACHE. */
    Xil_SetTlbAttributes(SD_RECORD_PAYLOAD_ADDR,NORM_NONCACHE);
    Xil_SetTlbAttributes(SD_RECORD_PAYLOAD_ADDR+SD_RECORD_SLOT_BYTES,NORM_NONCACHE);
    Xil_SetTlbAttributes(SD_DISK_DMA_BASE,NORM_NONCACHE);
    yield_callback=callback;yield_context=context;in_yield=in_io=0;worst_us=yield_count=0;last_yield=now_us();
    state=STA_NOINIT;
}
uint32_t sd_disk_max_call_us(void){return worst_us;}
uint32_t sd_disk_yield_count(void){return yield_count;}
u32 sd_disk_wait_event(UINTPTR address,u32 mask,u32 event,u32 timeout){
    uint64_t start=now_us();do{
        if((Xil_In32(address)&mask)==event)return XST_SUCCESS;
        cooperate();
    }while(now_us()-start<timeout);
    return XST_FAILURE;
}
u32 sd_disk_wait_events(UINTPTR address,u32 mask,u32 events,u32 timeout,u32 *seen){
    uint64_t start=now_us();*seen=0;do{
        u32 value=Xil_In32(address)&mask;if(value&events){*seen=value;return XST_SUCCESS;}
        cooperate();
    }while(now_us()-start<timeout);
    return XST_FAILURE;
}
int sd_disk_delay(unsigned us){uint64_t start=now_us();do{cooperate();}while(now_us()-start<us);return 0;}
static void duration(uint64_t start){uint64_t n=now_us()-start;if(n>worst_us)worst_us=n>0xffffffffu?0xffffffffu:(uint32_t)n;}
DSTATUS disk_status(BYTE drive){
    if(drive)return STA_NOINIT;
    if((Xil_In32(config.BaseAddress+XSDPS_PRES_STATE_OFFSET)&XSDPS_PSR_CARD_INSRT_MASK)==0u)
        return state=STA_NOINIT|STA_NODISK;
    return state;
}
DSTATUS disk_initialize(BYTE drive){
    if(drive || in_io)return STA_NOINIT;
    if(!(disk_status(drive)&STA_NOINIT))return state;
    if(state&STA_NODISK)return state;
    in_io=1;uint64_t start=now_us();memset(&card,0,sizeof card);
    int rc=XSdPs_CfgInitialize(&card,&config,config.BaseAddress);
    if(rc==XST_SUCCESS)rc=XSdPs_CardInitialize(&card);
    state=rc==XST_SUCCESS?0:STA_NOINIT;duration(start);in_io=0;return state;
}
static DRESULT transfer(BYTE drive,BYTE *readbuf,const BYTE *writebuf,LBA_t sector,UINT count){
    if(drive || !count || (!readbuf && !writebuf))return RES_PARERR;
    if(in_io || disk_status(drive)&STA_NOINIT)return RES_NOTRDY;
    if(sector>=card.SectorCount || count>card.SectorCount-sector)return RES_PARERR;
    in_io=1;uint64_t started=now_us();DRESULT result=RES_OK;
    while(count){
        UINT n=count>8u?8u:count;u32 address=(u32)sector;
        if(!card.HCS){if(address>0x007fffffu){result=RES_PARERR;break;}address*=512u;}
        int rc;
        if(writebuf){memcpy(bounce,writebuf,n*512u);Xil_DCacheFlushRange((UINTPTR)bounce,n*512u);
            rc=XSdPs_WritePolled(&card,address,n,bounce);
        }else{
            Xil_DCacheFlushRange((UINTPTR)bounce,n*512u);
            Xil_DCacheInvalidateRange((UINTPTR)bounce,n*512u);
            rc=XSdPs_ReadPolled(&card,address,n,bounce);
            Xil_DCacheInvalidateRange((UINTPTR)bounce,n*512u);
            if(rc==XST_SUCCESS)memcpy(readbuf,bounce,n*512u);
        }
        if(rc!=XST_SUCCESS){state=STA_NOINIT;result=RES_ERROR;break;}
        sector+=n;count-=n;if(readbuf)readbuf+=n*512u;if(writebuf)writebuf+=n*512u;
        cooperate();
    }
    duration(started);in_io=0;return result;
}
DRESULT disk_read(BYTE drive,BYTE *buffer,LBA_t sector,UINT count){return transfer(drive,buffer,0,sector,count);}
DRESULT disk_write(BYTE drive,const BYTE *buffer,LBA_t sector,UINT count){return transfer(drive,0,buffer,sector,count);}
DRESULT disk_ioctl(BYTE drive,BYTE command,void *buffer){
    if(drive || disk_status(drive)&STA_NOINIT)return RES_NOTRDY;
    switch(command){
    case CTRL_SYNC: return in_io?RES_NOTRDY:RES_OK;
    case GET_SECTOR_COUNT: if(!buffer)return RES_PARERR;*(LBA_t *)buffer=card.SectorCount;return RES_OK;
    case GET_SECTOR_SIZE: if(!buffer)return RES_PARERR;*(WORD *)buffer=512;return RES_OK;
    case GET_BLOCK_SIZE: if(!buffer)return RES_PARERR;*(DWORD *)buffer=128;return RES_OK;
    default:return RES_PARERR; /* In particular, never issue trim/erase. */
    }
}
