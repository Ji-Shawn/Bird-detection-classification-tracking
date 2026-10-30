#ifndef SD_FATFS_PORT_H
#define SD_FATFS_PORT_H
#define FILE_SYSTEM_INTERFACE_SD 1
#ifdef SD_RECORD_HOST
#include <stdint.h>
typedef uintptr_t INTPTR;
#define Xil_DCacheFlushRange(a,n) ((void)(a),(void)(n))
#else
#include "xil_cache.h"
#endif
#endif
