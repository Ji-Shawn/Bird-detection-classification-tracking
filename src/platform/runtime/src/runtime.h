#ifndef UNIFIED_RUNTIME_H
#define UNIFIED_RUNTIME_H
#include <stdint.h>
#include "xaxidma.h"
XAxiDma_Config *fusion_dma_config(void);
void fusion_yield(void);
extern int unified_validate;
extern int8_t unified_logits[60];
int audio_run(void);
int image_run(void);
int ssd_run(void);
#endif
