#ifndef VISUAL_SERVO_POLICY_H
#define VISUAL_SERVO_POLICY_H
/* Candidate command-rate tuning; these are not measured mechanical speeds.
 * Normalized errors divide pixel error by the FULL image width/height.
 * Pan units are camera/platform degrees (the 2x shaft transmission is already
 * included by pose()/pulse_for_pose()). Tilt units are servo shaft degrees.
 * M47 adopts the user's latest online tuning: Kp 105/100, command-rate caps
 * 20/20 deg/s. M47 adopts the pictured deadbands 4/6% and 1.5/2.5%.
 * These settings
 * were selected by observing motion; no encoder speed measurement exists.
 * P only: I and D absent. The 20 ms target cycle is unchanged.
 */
#define VISUAL_SERVO_PERIOD_US 20000u
#define VISUAL_SERVO_MAX_DT_US 40000u
#define VISUAL_SERVO_POSITION_MAX_AGE_US 500000u
#define VISUAL_SERVO_PAN_KP_DPS 105.0f
#define VISUAL_SERVO_TILT_KP_DPS 100.0f
#define VISUAL_SERVO_PAN_MAX_DPS 20.0f
#define VISUAL_SERVO_TILT_MAX_DPS 20.0f
#define VISUAL_SERVO_PAN_DEAD_ENTER 0.040f
#define VISUAL_SERVO_PAN_DEAD_EXIT 0.060f
#define VISUAL_SERVO_TILT_DEAD_ENTER 0.015f
#define VISUAL_SERVO_TILT_DEAD_EXIT 0.025f
/* Preserve the existing visual tilt limits, independent of audio scan limits. */
#define VISUAL_SERVO_TILT_MIN_US 540u
#define VISUAL_SERVO_TILT_MAX_US 2181u
#endif
