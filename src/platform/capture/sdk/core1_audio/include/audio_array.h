#ifndef AUDIO_ARRAY_H
#define AUDIO_ARRAY_H

/* Confirmed 2026-10-06: CH0 front, CH1 right, CH2 rear, CH3 left.
 * Both opposite microphone separations are 0.30 m (0.15 m arms).
 * Heading: front 0 degrees, right +90, left -90, rear +/-180. */
#define AUDIO_ARRAY_X_METRES {0.0f, 0.15f, 0.0f, -0.15f}
#define AUDIO_ARRAY_Y_METRES {0.15f, 0.0f, -0.15f, 0.0f}
#define AUDIO_SOUND_SPEED_M_S 343.0f
#define AUDIO_ARRAY_PAIR_A {0, 0, 0, 1, 1, 2}
#define AUDIO_ARRAY_PAIR_B {1, 2, 3, 2, 3, 3}
/* ceil(pair distance * 32000 / 343): adjacent 20, opposite 28.
 * Maximum steering delay is 27.989 samples, below the existing
 * software cap of 34 and the PL fractional-delay limit of 38. */
#define AUDIO_ARRAY_PAIR_LAG_LIMITS {20, 28, 20, 20, 28, 20}

#endif
