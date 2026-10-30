#ifndef VISUAL_RECOVERY_POLICY_H
#define VISUAL_RECOVERY_POLICY_H
/* One bounded search after formal target loss or an unowned pan endpoint.
 * Pan holds its last accepted command (there is no encoder feedback).
 * Tilt reuses SERVO_SOUND_SCAN_* calibration, step and interval unchanged.
 * Repeated misses/candidates do not renew this deadline. */
#define VISUAL_RECOVERY_SCAN_US 30000000u
/* After losing formal vision, retain both accepted position commands for
 * two seconds before vertical search. Included in the 30-second budget.
 * Initial sound seeking and an unowned endpoint do not inherit this pause. */
#define VISUAL_RECOVERY_LOSS_HOLD_US 2000000u
/* An independently accepted audio direction remains meaningful for at most
 * the existing 8-second sound observation freshness window at an endpoint.
 * Fresh same-bearing samples must pass the existing spatial consensus again
 * to renew this allowance. */
#define VISUAL_RECOVERY_SOUND_MAX_AGE_US 8000000u
/* Once per recovery, a valid post-motion sparse SSD hit may hold the scan
 * while the next independent SSD result checks stability. This uses the
 * existing 3-second candidate allowance and never extends the 30-second
 * recovery deadline. A late SSD coordinate never starts continuous motion. */
#define VISUAL_RECOVERY_SPARSE_CONFIRM_US 3000000u
#endif
