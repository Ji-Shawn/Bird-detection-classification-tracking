"""M35: route fresh, formal NCC positions to the continuous servo controller.

The three delayed-SSD fallback calls, target selection, two independent SSD
confirmations, NCC algorithm and capture pipeline remain the M33 implementation.
This reversible final overlay is applied by the actual ARM build.
"""

OLD = '''    if(search_slot==head && now>=f->timestamp && now-f->timestamp<=500000u)
        servo_tracking_observe(bird_score,box_now,f->sequence,f->timestamp,now);'''
NEW = '''    if(search_slot==head && now>=f->timestamp && now-f->timestamp<=VISUAL_SERVO_POSITION_MAX_AGE_US)
        servo_tracking_track(bird_score,box_now,f->sequence,f->timestamp,now);'''
PREFIX = '#include "visual_servo_policy.h"\n'


def tracker(text):
    assert text.count(OLD) == 1, 'M33 latest-NCC servo entry changed'
    return PREFIX + text.replace(OLD, NEW, 1)


def revert_tracker(text):
    assert text.startswith(PREFIX) and text.count(NEW) == 1
    return text[len(PREFIX):].replace(NEW, OLD, 1)
