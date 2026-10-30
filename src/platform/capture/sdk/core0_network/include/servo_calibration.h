#ifndef SERVO_CALIBRATION_H
#define SERVO_CALIBRATION_H
/* 180-degree positional servo, 2x pan mechanism. User table: 2026-10-13. */
#define SERVO_PAN_CENTER_US 1440u
#define SERVO_PAN_MIN_US 540u
#define SERVO_PAN_MAX_US 2480u
#define SERVO_PAN_STEP_US 30u
#define SERVO_PAN_NEAR_STEP_US 10u
#define SERVO_PAN_HOME_STEP_US 10u
#define SERVO_PAN_HOME_INTERVAL_US 100000u
#define SERVO_PAN_MOVE_INTERVAL_US 300000u
#define SERVO_PAN_SETTLE_US 300000u
#define SERVO_DEFAULT_NEAR_THRESHOLD_PX 192u
#define SERVO_FRAME_US 20000u
#define SERVO_VISUAL_FRESH_US 5000000u /* Retain the M29 visual freshness contract. */
/* Vertical shaft calibration uses the supplied table directly, without pan's
 * 2x mechanism: 0 deg = 540 us, 60 deg = 1140 us, 100 deg = 1540 us.
 * M38 changes sound/recovery scan endpoints only; visual tilt bounds remain. */
#define SERVO_INITIAL_TILT_US 1140u
#define SERVO_SOUND_TILT_MIN_US 540u
#define SERVO_SOUND_TILT_MAX_US 1540u
#define SERVO_SOUND_SCAN_STEP_US 20u
#define SERVO_SOUND_SCAN_INTERVAL_US 400000u
/* Conservative travel allowance, not measured position feedback. */
#define SERVO_SOUND_TRAVEL_US_PER_DEG 6000u
/* Commanded slew at half the previous nominal travel-rate estimate. The
 * previous endpoint jump did not measure the physical servo speed. */
#define SERVO_SOUND_SPEED_DIVISOR 2u
#define SERVO_SOUND_TURN_INTERVAL_US 20000u
#define SERVO_SOUND_TURN_STEP_MDEG (SERVO_SOUND_TURN_INTERVAL_US*1000u / \
    (SERVO_SOUND_SPEED_DIVISOR*SERVO_SOUND_TRAVEL_US_PER_DEG))
#define SERVO_SOUND_REAIM_DEADBAND_MDEG 15000
/* Only sound-triggered target acceptance; slew/scan timing is unchanged. */
#define SERVO_SOUND_DIRECTION_QUALITY_MIN 1024u
#define SERVO_SOUND_DIRECTION_JITTER_MDEG 12000
#define SERVO_SOUND_CONFIRM_SAMPLE_US 60000u
#define SERVO_SOUND_CONFIRM_GAP_US 500000u
#define SERVO_SOUND_CONFIRM_MIN_SAMPLES 6u
#define SERVO_SOUND_ACQUIRE_CONFIRM_US 600000u
#define SERVO_SOUND_REAIM_CONFIRM_US 1000000u
#endif
