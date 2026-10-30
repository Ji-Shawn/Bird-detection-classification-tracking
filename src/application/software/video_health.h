#ifndef M44_VIDEO_HEALTH_H
#define M44_VIDEO_HEALTH_H
#include <stdint.h>
#define VIDEO_HEALTH_MAGIC 0x56483031u
#define VIDEO_HEALTH_WORDS 32u
enum { VH_HEALTHY=0,VH_WATCH,VH_SENSOR,VH_STOP,VH_RESET,VH_CONFIG,
       VH_WAIT_FRAMES,VH_COOLDOWN,VH_EXHAUSTED,VH_SUPPRESSED };
enum { VH_SOURCE_STALL=1,VH_DMA_FAULT,VH_COPY_STALL,VH_HDMI_FAULT,VH_FRAMING };
/* VH01, version 1. Telemetry words are network byte order on the wire.
 * 0 magic,1 version,2 state,3 reason,4 flags,5 PL valid frames,
 * 6 S2MM status,7 MM2S status,8 write store,9 read store,10 last error,
 * 11 events,12 DMA attempts,13 sensor attempts,14 recovered,15 failures,
 * 16 capture age ms,17 completed copy age ms,18 PL progress age ms,
 * 19 current stall ms,20 last recovery duration ms,21 max stall ms,
 * 22 copy aborts,23 discarded previews,24 sensor generation,
 * 25 active copy offset,26 video sequence,27 startup grace remaining ms,
 * 28 saved fault S2MM,29 saved fault MM2S,30 round attempts,31 suppressed.
 * flags: source recent,capture recent,copy active,sensor busy,diagnostic
 * suppressed,read running,write running (bits 0..6).
 * Unknown ages are UINT32_MAX; zero never means an invented fresh frame. */
void video_health_words(uint32_t out[VIDEO_HEALTH_WORDS]);
int video_health_ready(void);
/* Invalidates camera-owned evidence, without changing mode/audio/actuators. */
void fusion_video_invalidate(void);
void fusion_video_hard_invalidate(void);
int fusion_video_recovery_suppressed(void);
#endif
