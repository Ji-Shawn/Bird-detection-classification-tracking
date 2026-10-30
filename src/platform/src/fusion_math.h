#ifndef FUSION_MATH_H
#define FUSION_MATH_H
#include <stdint.h>
void fusion_yield(void);
void fusion_quant_audio(const float *normalized, int8_t *output);
int fusion_image_inputs(const uint16_t *rgb565, int w, int h, int8_t *image, int8_t *ssd);
int fusion_ssd_input(const uint16_t *rgb565,int w,int h,int8_t *ssd);
int fusion_classify_input(const uint16_t *rgb565,int w,int h,int8_t *image);
/* Square crop including 50% context. xyxy may extend beyond the camera:
 * edge replication preserves shape instead of distorting border targets. */
int fusion_make_roi(int w,int h,const float *box,int32_t *xyxy);
int fusion_image_roi(const uint16_t *rgb565,int w,int h,const int32_t *xyxy,int8_t *image);
int fusion_scores(const int8_t *audio, const int8_t *image, float image_weight, float *scores);
#endif
