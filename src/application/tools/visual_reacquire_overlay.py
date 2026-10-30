"""M37: stop corrections immediately, keep camera still for bounded NCC retry.

The original miss count/750-ms deadline, failed-box visibility and 30-s search
deadline remain. The pause only prevents vertical search from moving the image
while the formal tracker is still attempting its existing short reacquisition.
"""

RESET = '    servo_tracking_clear_detection();\n}\nvoid visual_tracker_reset(void)'
RESET_NEW = '    servo_tracking_clear_detection();\n    servo_tracking_reacquire(0,0,0);\n}\nvoid visual_tracker_reset(void)'
MISS = '    servo_tracking_clear_detection();\n    if(misses>=VISUAL_TRACKER_MAX_MISSES'
MISS_NEW = ('    servo_tracking_clear_detection();\n'
            '    servo_tracking_reacquire(1,reacquire_started,now);\n'
            '    if(misses>=VISUAL_TRACKER_MAX_MISSES')
GATE = '    if(servo_tracking_recovery_active())return 0;'
GATE_NEW = ('    /* Keep the existing formal retry visually scheduled while both\n'
            '     * axes hold. A true loss releases audio during the 30-s search. */\n'
            '    if(servo_tracking_reacquire_active(now))return 1;\n'+GATE)


def tracker(text):
    for old,new in ((RESET,RESET_NEW),(MISS,MISS_NEW)):
        assert text.count(old)==1, old
        text=text.replace(old,new,1)
    return text


def revert_tracker(text):
    for old,new in reversed(((RESET,RESET_NEW),(MISS,MISS_NEW))):
        assert text.count(new)==1, new
        text=text.replace(new,old,1)
    return text


def apply(text):
    assert text.count(GATE)==1
    return text.replace(GATE,GATE_NEW,1)


def revert(text):
    assert text.count(GATE_NEW)==1
    return text.replace(GATE_NEW,GATE,1)
