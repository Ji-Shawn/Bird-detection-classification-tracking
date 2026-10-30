import pytest
from av_monitor.tracking_overlay import tracking_target,draw_tracking

def telemetry():
    return dict(online=True,boot_id=7,telemetry_age_s=.1,detection_valid=True,
                detection_age_ms=1000,detection_score=.8,detection_box=[600,300,1200,700],
                servo_sequence=2,detection_motion_sequence=2,servo_busy=False,detection_sequence=19)

def test_raw_box_center_and_error():
    t=tracking_target(telemetry(),7)
    assert t['box']==(200,100,400,700/3)
    assert t['center']==(300,500/3) and t['error']==(-60,-40) and not t['centered']
    assert t['age']==1.1

@pytest.mark.parametrize('change',[
    {'online':False},{'boot_id':8},{'telemetry_age_s':2},{'detection_age_ms':6000},
    {'detection_valid':False},{'servo_busy':True},{'servo_sequence':3},
    {'detection_score':float('nan')},{'detection_box':[0,0,0,0]},
    {'detection_box':[0,0,1921,100]},{'detection_box':[0,0,float('inf'),100]}])
def test_bad_or_pre_motion_box_hidden(change):
    t=telemetry();t.update(change);assert tracking_target(t,7) is None

def test_centered_and_stale():
    t=telemetry();t['detection_box']=[860,440,1060,640]
    assert tracking_target(t,7)['centered']
    assert tracking_target(t,7,True) is None

def test_canvas_center_and_target_separate():
    class Canvas:
        def __init__(self):self.items=[]
        def delete(self,*args):pass
        def __getattr__(self,name):
            def add(*args,**kwargs):self.items.append((name,args,kwargs))
            return add
    c=Canvas();draw_tracking(c,tracking_target(telemetry(),7))
    assert ('create_rectangle',(200,100,400,700/3)) in [(n,a) for n,a,k in c.items]
    assert any(n=='create_line' and a[:2]==(320,180) and a[2:]==(300,500/3) for n,a,k in c.items)

def test_continuous_target_must_have_recent_image_and_recent_ssd_confirmation():
    t=telemetry();t.update(visual_tracker_active=True,visual_tracker_quality=.92,
                         visual_tracker_ssd_age_ms=2100,visual_tracker_target_valid=True,
                         visual_tracker_frame_age_ms=100,visual_tracker_bird_score=.8,
                         visual_tracker_box=t['detection_box'])
    target=tracking_target(t,7)
    assert target['continuous'] and target['quality']==.92 and target['ssd_age']==2.1
    t['visual_tracker_frame_age_ms']=1100;assert tracking_target(t,7) is None
    t['visual_tracker_frame_age_ms']=100;t['visual_tracker_ssd_age_ms']=5001
    assert tracking_target(t,7) is None

def test_current_tracked_box_remains_visible_while_control_waits_for_settling():
    t=telemetry();t.update(servo_busy=True,detection_valid=False,servo_sequence=3,
                         visual_tracker_active=True,visual_tracker_target_valid=True,
                         visual_tracker_quality=.92,visual_tracker_ssd_age_ms=2100,
                         visual_tracker_frame_age_ms=100,visual_tracker_bird_score=.8,
                         visual_tracker_box=[600,300,1200,700])
    assert tracking_target(t,7)['continuous']

def test_locked_horizontal_axis_uses_vertical_alignment_status():
    t=telemetry();t.update(visual_tracker_supported=True,servo_guard_supported=True,
        servo_left_budget=170,servo_right_budget=170,servo_min_tracking_frames=3,
        servo_left_guard_deg_per_frame=1.753,servo_right_guard_deg_per_frame=1.733,
        detection_box=[100,440,300,640])
    target=tracking_target(t,7)
    assert target['vertical_only'] and target['centered'] and target['error'][0]==-760
    t['detection_box']=[100,740,300,940]
    assert not tracking_target(t,7)['centered']
