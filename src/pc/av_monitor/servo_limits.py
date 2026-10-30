"""Display the board's current limit policy, including older cumulative firmware."""
import math


def auto_pan_limits(t):
    if t.get('servo_position_supported'):
        pulse=t.get('servo_pan_us')
        if not isinstance(pulse,int) or not t['servo_pan_min_us']<=pulse<=t['servo_pan_max_us']:
            return 3
        return (1 if pulse==t['servo_pan_min_us'] else 0)|(2 if pulse==t['servo_pan_max_us'] else 0)
    if t.get('servo_pan_limit_toggle_supported') and not t.get('servo_pan_limit_enabled',True):
        return 0
    if t.get('servo_config_supported') and (not t.get('servo_pwm_calibrated') or not t.get('servo_angle_estimate_valid')):
        return 3
    if not t.get('servo_guard_supported'):
        return None
    minimum=t.get('servo_min_tracking_frames',3)
    left=minimum*t.get('servo_left_guard_deg_per_frame',0)
    right=minimum*t.get('servo_right_guard_deg_per_frame',0)
    if t.get('servo_limit_policy')=='relative_position':
        if not t.get('servo_reference_valid'):
            return 3
        pose=t.get('servo_limit_position_deg',t.get('servo_estimated_pan',0))
        lower=t.get('servo_position_min_deg',-170)
        upper=t.get('servo_position_max_deg',170)
        if not all(math.isfinite(v) for v in (pose,lower,upper,left,right)) or left<=0 or right<=0:
            return 3
        return (1 if pose-left<lower-1e-9 else 0)|(2 if pose+right>upper+1e-9 else 0)
    limit=t.get('servo_limit_deg',170)
    return ((1 if t.get('servo_left_budget',0)+left>limit+1e-9 else 0)|
            (2 if t.get('servo_right_budget',0)+right>limit+1e-9 else 0))
