#ifndef SSD_ROI_H
#define SSD_ROI_H
#include <stdint.h>
/* Square source-frame coordinates; no padding, resizing metadata or state. */
typedef struct {int32_t x,y,side;} ssd_roi_box;
/* Return 1 on success, 0 on rejection. Output remains untouched on rejection.
 * Hint must be a valid complete source-frame xyxy box, >=8 pixels per axis.
 * Oversized hints that cannot fit a square are left to full-frame detection. */
int ssd_roi_from_box(const float hint[4],int width,int height,ssd_roi_box *out);
/* Map a complete valid ROI detection into the camera, never silently clip an
 * invalid box. Original-image width and height must both remain >=8 pixels. */
int ssd_roi_map(const ssd_roi_box *roi,const float box320[4],int width,int height,float mapped[4]);
/* Return 0 on success, -1 on invalid arguments. Direct stride sampling,
 * byte-identical to fusion_ssd_input_reference on a copied square crop.
 * No full-frame/crop allocation; cooperative yield once per output row. */
int ssd_roi_input(const uint16_t *full,int width,int height,const ssd_roi_box *roi,int8_t *out);
#endif
