#include <stdint.h>
typedef uint64_t XTime;
#define COUNTS_PER_SECOND 1000000u
static inline void XTime_GetTime(XTime *t) { *t = 1000; }
