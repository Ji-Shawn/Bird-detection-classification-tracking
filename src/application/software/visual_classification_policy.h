#ifndef M42_VISUAL_CLASSIFICATION_POLICY_H
#define M42_VISUAL_CLASSIFICATION_POLICY_H
#include "visual_servo_policy.h"
/* Extra live-control grace, measured from completed SSD localization, in us.
 * Main-loop I/O/NCC/controller service continues throughout this interval.
 * Expiry permits optional classification; it never authorizes stale motion. */
#define VISUAL_CLASSIFY_CONTROL_GRACE_US 250000u
#endif
