#ifndef VISUAL_TRACKER_H
#define VISUAL_TRACKER_H
#include <stdint.h>
#define VISUAL_TRACKER_CONFIRM_US 8000000u
#define VISUAL_TRACKER_FRAME_US 1000000u
#define VISUAL_TRACKER_REACQUIRE_US 750000u
#define VISUAL_TRACKER_MAX_MISSES 3u
#define VISUAL_TARGET_CONFIRMATIONS 2u
#define VISUAL_TARGET_MAX_UNSUPPORTED 3u
typedef struct {float score,box[4];} visual_candidate;
/* Cooperative PS tracker. Models and PWM remain on the board. */
void visual_tracker_init(void);
void visual_tracker_reset(void);
void visual_tracker_frame_begin(uint32_t sequence,uint64_t timestamp);
void visual_tracker_frame_chunk(const void *rgb565,uint32_t offset,uint32_t bytes);
void visual_tracker_frame_end(void);
void visual_tracker_frame_abort(void);
void visual_tracker_observe_ssd(float score,const float box[4],uint32_t sequence,
                                uint64_t captured,uint64_t now);
/* Select before observe_ssd; -1 means no new accepted detection this batch.
 * Boxes and active-track association are in the SAME captured camera frame. */
int visual_tracker_select_ssd(const visual_candidate *candidates,unsigned count,
                             uint32_t sequence,uint64_t captured,uint64_t now);
void visual_tracker_selection_status(uint32_t words[12]);
void visual_tracker_poll(uint64_t now);
void visual_tracker_status(uint32_t words[16],uint64_t now);
void visual_tracker_diagnostic(uint32_t words[16],uint64_t now);
#endif
