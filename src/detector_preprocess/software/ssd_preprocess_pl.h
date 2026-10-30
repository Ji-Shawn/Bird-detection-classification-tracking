#ifndef SSD_PREPROCESS_PL_H
#define SSD_PREPROCESS_PL_H
#include <stdint.h>
typedef struct {uint32_t frames,failures,disabled,repairs,last_ticks,mm_status,ss_status;} ssd_pl_stats_t;
extern volatile ssd_pl_stats_t ssd_pl_stats;
/* Core0 owner only. Requires matching M14 bit; unsupported size returns -1. */
int ssd_preprocess_pl(const uint16_t *pixels,int w,int h,int8_t *tensor);
unsigned ssd_repair_rounding(const uint16_t *pixels,int8_t *tensor);
#endif
