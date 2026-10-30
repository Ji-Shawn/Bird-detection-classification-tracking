"""Display-only ROI: sensor/detector coordinates always remain full-frame."""
import math
from PIL import Image
from .video import WIDTH, HEIGHT

FULL=(0.,0.,float(WIDTH),float(HEIGHT))

class ZoomTransition:
    """Time-based smoothstep; animated display only, never sensor coordinates."""
    def __init__(self,duration=.8):
        self.duration=duration;self.start=FULL;self.target=FULL;self.started=0.
    def value(self,now):
        t=max(0.,min(1.,(now-self.started)/self.duration))
        a=t*t*(3-2*t)
        return tuple(s+(e-s)*a for s,e in zip(self.start,self.target))
    def update(self,box,now,immediate=False):
        target=tuple(map(float,box)) if box is not None else FULL
        if immediate:
            self.start=self.target=target;self.started=now
        elif target!=self.target:
            self.start=self.value(now);self.target=target;self.started=now
        return self.value(now)


def active_box(telemetry, frame_boot, selecting=False):
    if (selecting or not telemetry.get('online') or
        telemetry.get('boot_id')!=frame_boot or
        telemetry.get('telemetry_age_s',float('inf'))>1 or
        not telemetry.get('focus_enabled') or not telemetry.get('bird_zoom_active') or
        telemetry.get('bird_zoom_age_ms',0xffffffff)>12000):
        return None
    b=telemetry.get('bird_zoom_box',[])
    if len(b)!=4 or not all(isinstance(v,(int,float)) and math.isfinite(v) for v in b):
        return None
    x,y,xx,yy=map(int,b)
    if not (0<=x<xx<=WIDTH and 0<=y<yy<=HEIGHT and xx-x>=320 and yy-y>=180):
        return None
    if (xx-x)*9!=(yy-y)*16:return None
    return x,y,xx,yy


class FrameRenderer:
    """Prepare the source and panorama ONCE per received frame, not animation tick."""
    def __init__(self,rgb):
        self.rgb=rgb
        self.image=Image.fromarray(rgb)
        self.small=None
    def render(self,box):
        if box is None:
            import numpy as np
            return np.asarray(self.image.resize((640,360),Image.Resampling.BILINEAR))
        image=self.image.transform((640,360),Image.Transform.EXTENT,box,
                                   Image.Resampling.BILINEAR)
        if self.small is None:
            self.small=self.image.resize((160,90),Image.Resampling.BILINEAR)
        image.paste(self.small,(478,268))
        import numpy as np
        return np.asarray(image)

def render(rgb, box):
    return FrameRenderer(rgb).render(box)


def focus_text(t):
    if 'focus_state' not in t:return '当前固件没有自动对焦状态'
    if not t.get('online') or t.get('telemetry_age_s',float('inf'))>1:
        return '对焦状态已过期；恢复全景'
    state={0:'相机不可用',1:'加载并校验对焦固件',2:'对焦就绪/冷却；无鸟也可重新对焦',
           3:'对焦中',4:'固件确认对焦并保持',5:'对焦控制失败',
           6:'搜索结束并保持，未确认清晰度（可重试）',
           7:'镜头调整中',8:'镜头位置已读回，清晰度请看画面'}.get(t['focus_state'],'未知状态')
    if not t.get('focus_enabled'):state='自动放大/对焦已关闭 · '+state
    if t.get('focus_error'):state+=f"（错误 {t['focus_error']}；可点击重试）"
    return f"{state} | 触发 {t.get('focus_requests',0)} 次 / 完成 {t.get('focus_completed',0)} 次"
