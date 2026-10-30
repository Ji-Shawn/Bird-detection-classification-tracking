#ifndef SSD_DW_LAYOUT_H
#define SSD_DW_LAYOUT_H
#include <string.h>
/* Initialize only centered-padding transport slots. Body pixels are copied by
 * the caller, with its original cooperative yield cadence. */
static void ssd_dw_pad(unsigned char *stage,int front,int h,int w,int weng,int tail,int channels,int zp) {
    memset(stage,(unsigned char)zp,front*channels);
    if(weng>w) for(int r=0;r<h;r++)
        memset(stage+(front+r*weng+w)*channels,(unsigned char)zp,(weng-w)*channels);
    memset(stage+(front+h*weng)*channels,(unsigned char)zp,tail*channels);
}
#endif
