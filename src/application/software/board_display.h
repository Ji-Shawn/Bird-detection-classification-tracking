#ifndef BOARD_DISPLAY_H
#define BOARD_DISPLAY_H
#include "fusion_bridge.h"
void board_display_result(const fusion_result *result,uint64_t now);
void board_display_poll(uint64_t now);
extern volatile unsigned board_network_preview;
#endif
