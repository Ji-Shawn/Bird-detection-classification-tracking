#ifndef VISUAL_DETECTION_POLICY_H
#define VISUAL_DETECTION_POLICY_H
/* SSD bird presence is STRICTLY >50%; independent of species/audio. */
#define VISUAL_BIRD_MIN_SCORE .5f
#define VISUAL_BIRD_MIN_SCORE_Q6 500000u
#define VISUAL_CANDIDATE_SCAN_HOLD_US 3000000u
#include <stdint.h>
/* Only an accepted float32 >0.5 score is nudged past the wire quantization
 * boundary. nextafterf(0.5,+inf) must remain visible after Q6 rounding; an
 * exact 0.5 is never promoted or accepted by this helper. */
static inline uint32_t visual_detection_score_q6(float score) {
    uint32_t value=(uint32_t)(score*1000000.f+.5f);
    return score>VISUAL_BIRD_MIN_SCORE && value<=VISUAL_BIRD_MIN_SCORE_Q6?
        VISUAL_BIRD_MIN_SCORE_Q6+1u:value;
}
#endif
