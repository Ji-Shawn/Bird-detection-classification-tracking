#ifndef M48_SD_DISK_H
#define M48_SD_DISK_H
#include <stdint.h>
#define SD_DISK_DMA_BASE 0x37200000u
#define SD_DISK_DMA_END  0x37300000u
void sd_disk_set_yield(void (*callback)(void *),void *context);
uint32_t sd_disk_max_call_us(void);
uint32_t sd_disk_yield_count(void);
#ifndef SD_RECORD_HOST
#include "xil_types.h"
/* The M47 Core1 BSP omitted SDPS; the paired FSBL hardware has exactly SD0. */
#ifndef XPAR_XSDPS_NUM_INSTANCES
#define XPAR_XSDPS_NUM_INSTANCES 1
#endif
u32 sd_disk_wait_event(UINTPTR address,u32 mask,u32 event,u32 timeout);
u32 sd_disk_wait_events(UINTPTR address,u32 mask,u32 events,u32 timeout,u32 *seen);
int sd_disk_delay(unsigned microseconds);
#endif
#endif
