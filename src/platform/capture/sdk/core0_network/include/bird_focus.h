#ifndef BIRD_FOCUS_H
#define BIRD_FOCUS_H
#include <stdint.h>
/* No sensor geometry/PLL changes: display zoom keeps the full-frame detector. */
void bird_focus_init(int camera_ok, uint64_t now);
void bird_focus_poll(uint64_t now); /* bounded to one SCCB transaction */
void bird_focus_observe(float score, const float box[4], uint32_t sequence,
                        uint64_t captured, uint64_t now);
void bird_focus_forget(void);
int bird_focus_control(unsigned action); /* 0 off, 1 auto, 2 retry/init or refocus */
int bird_focus_manual(unsigned position); /* VCM DAC code 0..1023; not distance */
/* Board contrast controller only: retain user enable/detection/display crop.
 * Uses the same verified VCM ramp with the AF MCU held, never two AF owners. */
int bird_focus_contrast_move(unsigned position);
void bird_focus_manual_status(uint32_t words[6]);
void bird_focus_status(uint32_t words[16], uint64_t now);
extern volatile uint32_t bird_focus_diag[8];
int ov5640_af_read(uint16_t reg, uint8_t *value);
int ov5640_af_write(uint16_t reg, uint8_t value);
#endif
