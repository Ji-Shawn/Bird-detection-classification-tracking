#ifndef CAMERA_RECOVERY_H
#define CAMERA_RECOVERY_H
#include <stdint.h>
/* Cooperative sensor-only recovery. A successful poll means that registers
 * were configured, never that an image was received. The video watchdog must
 * confirm a genuinely completed new frame separately. */
int ov5640_recovery_begin(uint64_t now);
int ov5640_recovery_poll(uint64_t now); /* 0 busy, 1 configured, negative error */
int ov5640_recovery_busy(void);
unsigned ov5640_recovery_generation(void);
unsigned ov5640_recovery_reset_generation(void);
void ov5640_recovery_confirm_frame(void);
int ov5640_recovery_saved_focus(unsigned *code);
extern volatile uint32_t camera_recovery_diag[12];
#endif
