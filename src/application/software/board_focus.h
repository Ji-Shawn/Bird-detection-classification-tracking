#ifndef BOARD_FOCUS_H
#define BOARD_FOCUS_H
#include <stdint.h>
void board_focus_frame_begin(void);
void board_focus_frame_chunk(const void *pixels,unsigned offset,unsigned bytes);
void board_focus_frame_end(uint64_t now);
void board_focus_policy_poll(uint64_t now);
void board_focus_observe(float score,const float box[4],uint64_t now);
/* Already-confirmed tracker target, source-frame coordinates. A candidate must
 * never call this API. Only fresh independent samples may request recovery. */
void board_focus_track(float score,const float box[4],uint32_t sequence,
                       uint64_t captured,uint64_t now);
unsigned board_focus_searching(void);
extern volatile uint32_t board_focus_diag[12];
#endif
