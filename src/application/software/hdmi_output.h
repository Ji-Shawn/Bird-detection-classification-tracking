#ifndef M18_HDMI_OUTPUT_H
#define M18_HDMI_OUTPUT_H
#include "xaxivdma.h"
XAxiVdma_Config *hdmi_vdma_config(const XAxiVdma_Config *capture);
int hdmi_capture_genlock(XAxiVdma *dma);
void hdmi_output_poll(XAxiVdma *dma, unsigned clean_frames);
/* Prepare a channel-specific asynchronous restart; does not reset capture. */
void hdmi_output_restart(void);
extern volatile unsigned hdmi_read_started,hdmi_last_status,hdmi_read_error,hdmi_start_error;
#endif
