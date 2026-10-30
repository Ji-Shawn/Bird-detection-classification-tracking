#include "audio_worker.h"

#include "xil_cache.h"
#include "xil_io.h"
#include "xtime_l.h"

void platform_cache_flush(const void *address, uint32_t bytes) {
    Xil_DCacheFlushRange((INTPTR)address, bytes);
}
void platform_cache_invalidate(const void *address, uint32_t bytes) {
    Xil_DCacheInvalidateRange((INTPTR)address, bytes);
}
uint32_t platform_cycle_count(void) {
    XTime value; XTime_GetTime(&value); return (uint32_t)value;
}
void platform_mmio_write(uint32_t address, uint32_t value) { Xil_Out32(address, value); }
uint32_t platform_mmio_read(uint32_t address) { return Xil_In32(address); }
