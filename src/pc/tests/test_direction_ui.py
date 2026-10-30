from types import SimpleNamespace
from av_monitor.ui import MonitorWindow, _direction_display
import pytest


class Canvas:
    def __init__(self):self.lines=[];self.text=[]
    def delete(self,*a):pass
    def create_oval(self,*a,**k):pass
    def create_line(self,*a,**k):self.lines.append(a)
    def create_text(self,*a,**k):self.text.append(k['text'])


def test_invalid_direction_never_draws_arrow_or_old_angle():
    canvas=Canvas()
    MonitorWindow._draw_compass(SimpleNamespace(compass=canvas),90,.99,False)
    assert not canvas.lines and not any('°' in text for text in canvas.text)
    assert any('未确认鸟声' in text for text in canvas.text)


def test_valid_direction_labels_localization_quality_separately():
    canvas=Canvas()
    MonitorWindow._draw_compass(SimpleNamespace(compass=canvas),90,.9,True)
    assert len(canvas.lines)==1 and any('90.0°  定位质量' in text for text in canvas.text)


@pytest.mark.parametrize('changes,expected',[
    ({'online':False},'板子离线'),
    ({'fusion_mode':1},'独立视觉'),
    ({'capture_state':2},'输入已冻结'),
    ({'mic_mask':7},'麦克风未全部就绪'),
    ({'direction_bird_class':0xffffffff},'等待完整音频窗'),
    ({'direction_bird_confidence':.7},'未超过门槛'),
])
def test_blocked_direction_hides_cached_angle_and_explains_reason(changes,expected):
    t=dict(online=True,telemetry_age_s=0,fusion_mode=0,capture_state=0,mic_mask=15,
           direction_threshold_percent=70,direction_bird_class=0,direction_bird_confidence=.8)
    t.update(changes)
    valid,reason,text=_direction_display(t,SimpleNamespace(valid=True),['bird'])
    assert not valid and reason and expected in text


def test_valid_direction_keeps_historical_sample_age():
    t=dict(online=True,telemetry_age_s=0,fusion_mode=0,capture_state=0,mic_mask=15,
           direction_threshold_percent=30,direction_bird_class=0,direction_bird_confidence=.8,
           direction_age_ms=1500)
    valid,reason,text=_direction_display(t,SimpleNamespace(valid=True),['bird'])
    assert valid and not reason and '1.5秒' in text
