#ifndef SERVO_TRACKING_H
#define SERVO_TRACKING_H
#include <stdint.h>
/* Forget pending sound votes after timing adoption, preserving all owners. */
void servo_tracking_sound_timing_forget(uint64_t now);
void servo_tracking_init(uint64_t now);
void servo_tracking_poll(uint64_t now);
void servo_tracking_tick(uint64_t now); /* time/lease only, before incoming I/O */
void servo_tracking_visual_priority(unsigned present,uint64_t now);
/* A formally selected/seeded SSD may pause scanning for at most 500 ms.
 * This does not supply a position, renew the lease, or issue a command. */
void servo_tracking_visual_acquired(uint64_t captured,uint64_t now);
void servo_tracking_position_status(uint32_t words[12]);
void servo_tracking_stop(void); /* also disables automatic tracking */
void servo_tracking_clear_detection(void); /* forget target; keep auto/limits */
int servo_tracking_pan(unsigned direction); /* 0 stop, 1 left, 2 right */
int servo_tracking_configure(unsigned left_us,unsigned right_us,unsigned left_ms,unsigned right_ms);
void servo_tracking_config_status(uint32_t words[16]);
int servo_tracking_configure_visual(unsigned left,unsigned right,unsigned left_ms,unsigned right_ms,
    unsigned enabled,unsigned threshold_px,unsigned left_near_ms,unsigned right_near_ms);
void servo_tracking_visual_config_status(uint32_t words[16]);
int servo_tracking_pan_limit(unsigned enabled); /* 0 bypass, 1 enable; stops auto */
int servo_tracking_tilt(unsigned pulse_us);
/* RAM-only automatic vertical scan rate. Range 0.5..10 shaft degrees/s,
 * startup 5. No action, ownership change or lease renewal on application.
 * This is an accepted command limit, not measured mechanical velocity. */
int servo_tracking_configure_scan_rate(float degrees_per_second);
float servo_tracking_scan_rate(void);
void servo_tracking_scan_timing(uint32_t words[2]); /* step us, interval us */
int servo_tracking_auto(unsigned enabled);
/* Mode 1 visual only; mode 2 sound seeking with visual priority.
 * Microphones are fixed to the base; their bearing is an absolute pan target. */
int servo_tracking_visual_present(uint64_t now);
/* Bounded 30-second loss/endpoint search: pan holds, tilt scans. Fresh
 * formal vision or a newly qualified audio bearing may take ownership. */
int servo_tracking_recovery_active(void);
/* Only formal NCC retry may hold both axes during its existing bounded
 * reacquisition window. No stale position is reused; the 30-s timer runs on. */
void servo_tracking_reacquire(unsigned retry,uint64_t started,uint64_t now);
int servo_tracking_reacquire_active(uint64_t now);
void servo_tracking_sound_observe(int valid,int16_t angle_q9_7,uint16_t quality_q0_15,
                                 uint64_t captured,unsigned visual_present,uint64_t now);
/* Display-only candidate pauses auditory vertical scan for a bounded 3 s. */
void servo_tracking_sound_candidate(unsigned pending,uint64_t now);
void servo_tracking_sound_status(uint32_t words[8]);
int servo_tracking_sound_search_active(void); /* latched turn or vertical search */
/* Monotonic confirmation event within this firmware session. Includes a
 * freshly reconfirmed same bearing without restarting its turn/scan. */
uint32_t servo_tracking_sound_accept_sequence(void);
int servo_tracking_keepalive(void);
void servo_tracking_observe(float score,const float box[4],uint32_t sequence,
                            uint64_t captured,uint64_t now);
/* Formal, independently SSD-confirmed target with latest successful NCC
 * location. Does not itself confirm candidates. Poll applies continuous P
 * corrections; duplicate observations do not renew position freshness.
 * All positions remain accepted command estimates, without encoder feedback. */
void servo_tracking_track(float score,const float box[4],uint32_t sequence,
                          uint64_t captured,uint64_t now);
void servo_tracking_status(uint32_t words[10]);
void servo_tracking_diagnostic(uint32_t words[10]);
void servo_tracking_guard_status(uint32_t words[8]);
void servo_tracking_limit_status(uint32_t words[8]);
void servo_tracking_limit_switch_status(uint32_t words[4]);
void servo_tracking_detection(uint32_t words[10]);
/* M39 RAM-only continuous visual-controller configuration. Values are
 * [pan Kp, tilt Kp, pan max, tilt max, pan enter, pan exit, tilt enter, tilt exit].
 * Kp: command degrees/s per full-image normalized error; max: command deg/s;
 * deadbands: fractions of FULL image width/height, not percentages. Pan uses
 * platform degrees; tilt uses shaft degrees. No encoder/speed feedback.
 * cmd23 v1 is 46 bytes: command/schema, BE boot/revision/request, 8 BE floats.
 * SRV9 appends actual adopted values and request acknowledgement to telemetry.
 */
int servo_tracking_tuning_command(uint32_t boot_id,const uint8_t *payload,unsigned bytes);
void servo_tracking_tuning_status(uint32_t words[16],uint32_t boot_id);
/* M47 cmd27 independent RAM transaction. Zero optical scale disables that
 * axis. VFF1 is 32 words; the observer estimates motion from accepted commands
 * and calibrated image displacement, without encoder feedback. */
int servo_tracking_feedforward_command(uint32_t boot_id,const uint8_t *payload,unsigned bytes);
void servo_tracking_feedforward_status(uint32_t words[32],uint32_t boot_id,uint64_t now);
#endif
