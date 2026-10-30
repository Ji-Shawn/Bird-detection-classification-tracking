#ifndef M48_STANDALONE_FUSION_H
#define M48_STANDALONE_FUSION_H
#include <stdint.h>

#define STANDALONE_FUSION_BOOT_MAGIC 0x4d343846u
enum {
    STANDALONE_FUSION_DISABLED = 0,
    STANDALONE_FUSION_ACTIVE = 1,
    STANDALONE_FUSION_PC = 2,
    STANDALONE_FUSION_STOPPED = 3,
    STANDALONE_FUSION_CAMERA_FAILED = 4,
    STANDALONE_FUSION_START_FAILED = 5
};
extern volatile uint32_t standalone_fusion_state;
extern volatile uint32_t standalone_fusion_last_command;

/* One boot-only request; JTAG supplies zero and retains the M47 startup. */
void standalone_fusion_start(uint32_t request, unsigned camera_ready, uint64_t now);
/* Called before the existing servo tick, without resetting targets or modes. */
void standalone_fusion_poll(void);
/* Run only after the ordinary decoder has accepted and applied the command. */
void standalone_fusion_command(const uint8_t *payload, unsigned bytes, int accepted);
#endif
