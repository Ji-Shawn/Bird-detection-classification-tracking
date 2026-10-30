#ifndef M9_PS_MATH_H
#define M9_PS_MATH_H
#include <stdint.h>
typedef struct { int h,w,ci,co,kh,kw,stride,pad_top,pad_left,oh,ow,groups,mul,shift,xzp,yzp; } conv_spec;
void ps_conv(const conv_spec *s, const int8_t *x, const int8_t *w, const int32_t *bias, int8_t *y);
void ps_add(int n, const int8_t *a, const int8_t *b, int8_t *y, float sa,float sb,float sy,int azp,int bzp,int yzp);
typedef struct { const int8_t *cls,*box; int h,w,cls_channels; float cls_scale,box_scale; int cls_zp,box_zp; } ssd_head;
typedef struct { float x1,y1,x2,y2,score; int anchor; } ssd_detection;
int ssd_postprocess(const ssd_head heads[6], const float *anchors, ssd_detection output[100]);
#endif
