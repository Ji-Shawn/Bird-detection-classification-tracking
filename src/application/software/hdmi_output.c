#include "hdmi_output.h"
#include "network_service.h"
#include <string.h>
#define HDMI_GPIO 0x41210000u
volatile unsigned hdmi_read_started,hdmi_last_status,hdmi_read_error,hdmi_start_error;
static XAxiVdma_Config hardware_config;
void hdmi_output_restart(void) {
 hdmi_read_started=hdmi_read_error=hdmi_start_error=0;
 platform_mmio_write(HDMI_GPIO,1u);
}
XAxiVdma_Config *hdmi_vdma_config(const XAxiVdma_Config *capture) {
 if (!capture) return 0;
 hardware_config=*capture;
 hardware_config.HasMm2S=1;hardware_config.HasMm2SDRE=0;
 hardware_config.Mm2SWordLen=64;hardware_config.Mm2SStreamWidth=16;
 hardware_config.Mm2SBufDepth=2048;hardware_config.Mm2SGenLock=3;
 hardware_config.S2MmGenLock=2;hardware_config.InternalGenLock=1;
 hardware_config.UseFsync=1;
 hdmi_read_started=hdmi_last_status=hdmi_read_error=hdmi_start_error=0;
 platform_mmio_write(HDMI_GPIO,1u); /* bars until clean capture exists */
 return &hardware_config;
}
int hdmi_capture_genlock(XAxiVdma *dma) {
 return XAxiVdma_GenLockSourceSelect(dma,XAXIVDMA_INTERNAL_GENLOCK,XAXIVDMA_WRITE);
}
void hdmi_output_poll(XAxiVdma *dma, unsigned clean_frames) {
 XAxiVdma_DmaSetup config;unsigned i;int rc;
 hdmi_last_status=platform_mmio_read(HDMI_GPIO+8u);
 if(hdmi_read_started) {
  hdmi_read_error=XAxiVdma_GetStatus(dma,XAXIVDMA_READ);
  return;
 }
 if(clean_frames<2u||hdmi_start_error) return;
 memset(&config,0,sizeof(config));
 config.VertSizeInput=AV_VIDEO_HEIGHT;config.HoriSizeInput=AV_VIDEO_STRIDE;
 config.Stride=AV_VIDEO_STRIDE;config.EnableCircularBuf=1;config.EnableSync=1;
 for(i=0;i<AV_VIDEO_BUFFER_COUNT;i++)config.FrameStoreStartAddr[i]=AV_VIDEO_BUFFER_BASE+i*AV_VIDEO_FRAME_BYTES;
 rc=XAxiVdma_DmaConfig(dma,XAXIVDMA_READ,&config);
 if(rc==XST_SUCCESS)rc=XAxiVdma_DmaSetBufferAddr(dma,XAXIVDMA_READ,config.FrameStoreStartAddr);
 if(rc==XST_SUCCESS)rc=XAxiVdma_GenLockSourceSelect(dma,XAXIVDMA_INTERNAL_GENLOCK,XAXIVDMA_READ);
 if(rc==XST_SUCCESS)rc=XAxiVdma_DmaStart(dma,XAXIVDMA_READ);
 if(rc!=XST_SUCCESS){hdmi_start_error=(unsigned)rc;return;}
 hdmi_read_started=1;
 platform_mmio_write(HDMI_GPIO,0u); /* raster switches only at vertical blank */
}
