"""Raw SSD geometry; display marks never alter the physical tracking target."""
import math
from .video import WIDTH,HEIGHT
from .servo_limits import auto_pan_limits
from .visual_policy import VISUAL_BIRD_MIN_SCORE

def tracker_confirmation_ms(t):
    return 8000 if t.get('visual_tracker_reacquire_supported') and t.get('visual_tracker_confirm_ms')==8000 else 5000

TRACKER_REASONS={0:'无',1:'匹配质量不足',2:'相似位置不明确',3:'目标移动超出搜索范围',
    4:'鸟框移出画面',5:'SSD确认超时',6:'摄像头画面停更',7:'图像帧间隔过长',
    8:'历史帧被覆盖',9:'时间戳异常',10:'鸟框太小，使用SSD点动',
    11:'目标纹理不足，使用SSD点动',12:'没有对应的历史图像',13:'连续三次检测不支持原目标'}

def selection_text(t):
    if not (t.get('online') and t.get('telemetry_age_s',99)<=1 and t.get('visual_target_selection_supported')):return ''
    why=t.get('visual_target_decision',0);miss=t.get('visual_target_unsupported',0)
    message={0:'等待候选',1:f"切换目标确认 {t.get('visual_target_pending_hits',0)}/2",
             2:'保留原目标',3:'新目标已确认',4:'已确认切换目标',
             5:'原目标本次未检出',6:'已退出旧目标',7:'等待对应帧复核'}.get(why,'等待复核')
    if miss and why in (1,5):message+=f' · 原目标未获支持 {miss}/3'
    return f"选框：{message} · 有效候选 {t.get('visual_target_candidates',0)}"

def _control_display(t,sequence,frame_age,reacquiring):
    """Report accepted coordinates, never infer PWM acceptance or shaft motion."""
    state='display_only';text='仅显示：等待新鲜控制位置'
    seq=t.get('detection_sequence')
    raw_age=t.get('detection_age_ms')
    telemetry_age=t.get('telemetry_age_s',float('inf'))
    age=(raw_age+telemetry_age*1000 if
         isinstance(raw_age,(int,float)) and not isinstance(raw_age,bool) and
         math.isfinite(raw_age) and raw_age>=0 else float('inf'))
    if reacquiring:
        state='reacquiring';text='短暂失配：灰框仅显示上次位置，等待新的有效匹配'
    elif t.get('servo_auto') is False or t.get('servo_tracking_reason')==8:
        state='paused'
        text=('仅显示：心跳超时，追踪已暂停' if t.get('servo_tracking_reason')==8 else
              '仅显示：追踪未开启或已停止')
    elif frame_age<=.5 and t.get('detection_supported') and t.get('detection_valid') and 0<=age<=500:
        ff=t.get('visual_feedforward') or {}
        ff_age=ff.get('age_s',float('inf'))
        flags=ff.get('flags',0)
        # Bit 64 is the P/FF controller's active flag, independent of whether
        # the optional feedforward observer has collected a velocity pair.
        active=(t.get('servo_auto') is True and ff.get('supported') and
                ff.get('boot_id')==t.get('boot_id') and
                isinstance(ff_age,(int,float)) and math.isfinite(ff_age) and 0<=ff_age<=.5 and
                isinstance(flags,int) and bool(flags&64))
        if active and type(seq) is int and 0<=seq<=0xffffffff:
            if seq==sequence:
                state='current'
                text=f'控制已接收当前NCC位置 · #{seq} / {age:.0f} ms（非机械反馈）'
            else:
                state='lagging'
                text=f'此框仅显示：帧 #{sequence} 待交接；控制仍用 #{seq} / {age:.0f} ms（非机械反馈）'
        else:text='仅显示：未收到新鲜的连续控制回读'
    return dict(control_state=state,control_text=text,control_sequence=seq,
                control_age_ms=age if math.isfinite(age) else None)

def tracking_target(t,frame_boot,frame_stale=False):
    if (frame_stale or not t.get('online') or t.get('boot_id')!=frame_boot or
        t.get('telemetry_age_s',float('inf'))>1):
        return None
    continuous=bool(t.get('visual_tracker_active') and t.get('visual_tracker_target_valid'))
    reacquiring=bool(t.get('visual_tracker_reacquire_supported') and t.get('visual_tracker_active') and
                    t.get('visual_tracker_state')==2 and 0<t.get('visual_tracker_misses',0)<3)
    if reacquiring:
        age=t.get('visual_tracker_held_age_ms',0xffffffff)/1000+t.get('telemetry_age_s',0)
        score=t.get('visual_tracker_held_score',0);b=t.get('visual_tracker_held_box',())
        if age>.75:return None
    elif continuous:
        age=t.get('visual_tracker_frame_age_ms',0xffffffff)/1000+t.get('telemetry_age_s',0)
        score=t.get('visual_tracker_bird_score',0);b=t.get('visual_tracker_box',())
    else:
        if (not t.get('detection_valid') or t.get('servo_busy') or
                t.get('detection_motion_sequence')!=t.get('servo_sequence')):return None
        age=t.get('detection_age_ms',0xffffffff)/1000+t.get('telemetry_age_s',0)
        score=t.get('detection_score',0);b=t.get('detection_box',())
    if age>5 or not math.isfinite(score) or not VISUAL_BIRD_MIN_SCORE<score<=1 or len(b)!=4:return None
    if not all(isinstance(v,(int,float)) and math.isfinite(v) for v in b):return None
    x,y,xx,yy=b
    if not (0<=x<xx<=WIDTH and 0<=y<yy<=HEIGHT and xx-x>=8 and yy-y>=8):return None
    cx,cy=(x+xx)/2,(y+yy)/2
    if (continuous or reacquiring) and (age>1 or t.get('visual_tracker_ssd_age_ms',0xffffffff)>tracker_confirmation_ms(t)):return None
    vertical_only=bool(t.get('visual_tracker_supported') and auto_pan_limits(t)==3)
    centered=abs(cy-HEIGHT/2)<=HEIGHT*.04 and (vertical_only or abs(cx-WIDTH/2)<=WIDTH*.025)
    sequence=t.get('visual_tracker_sequence',t.get('detection_sequence',0)) if continuous or reacquiring else t.get('detection_sequence',0)
    target=dict(box=tuple(v/3 for v in b),center=(cx/3,cy/3),
                error=(cx-WIDTH/2,cy-HEIGHT/2),age=age,score=score,
                sequence=sequence,
                continuous=continuous,reacquiring=reacquiring,quality=t.get('visual_tracker_quality',0),
                ssd_age=t.get('visual_tracker_ssd_age_ms',0)/1000,
                vertical_only=vertical_only,centered=centered and not reacquiring)
    if continuous or reacquiring:target.update(_control_display(t,sequence,age,reacquiring))
    return target

def draw_tracking(canvas,target,stale=False,near_threshold_px=None):
    canvas.delete('tracking')
    tag='tracking';cx,cy=320,180
    canvas.create_line(cx-12,cy,cx+12,cy,fill='white',width=2,tags=tag)
    canvas.create_line(cx,cy-12,cx,cy+12,fill='white',width=2,tags=tag)
    canvas.create_rectangle(cx-16,cy-14.4,cx+16,cy+14.4,outline='white',dash=(3,3),tags=tag)
    if isinstance(near_threshold_px,(int,float)) and math.isfinite(near_threshold_px) and 60<=near_threshold_px<=960:
        for sign in (-1,1):
            x=cx+sign*near_threshold_px/3
            canvas.create_line(x,cy-36,x,cy+36,fill='#63cfff',width=2,dash=(3,3),tags=tag)
    if target:
        x,y=target['center'];color='#42ff80' if target['centered'] else '#ffda42'
        if target.get('provisional'):
            canvas.create_rectangle(*target['box'],outline='#ffda42',width=2,dash=(5,3),tags=tag)
            canvas.create_text(target['box'][0],max(16,target['box'][1]-4),anchor='sw',
                fill='#ffda42',text=f"待确认 · SSD {target['score']:.0%}",tags=tag)
            canvas.create_text(8,338,anchor='sw',fill='white',
                text='首次检测，等待后续确认；确认后恢复正式追踪',tags=tag)
            return
        if target.get('reacquiring'):
            canvas.create_rectangle(*target['box'],outline='#bbbbbb',width=2,dash=(4,3),tags=tag)
            canvas.create_text(8,338,anchor='sw',fill='white',text=target.get('control_text','短暂失配，板端正在找回目标')+'\n灰框为上次位置；按失锁恢复策略找回目标',tags=tag)
            return
        canvas.create_rectangle(*target['box'],outline='#42ff80',width=2,tags=tag)
        canvas.create_oval(x-4,y-4,x+4,y+4,outline=color,fill=color,tags=tag)
        canvas.create_line(cx,cy,x,y,fill=color,width=2,dash=(4,3),tags=tag)
        dx,dy=target['error']
        source=(f"NCC显示位置 · 匹配 {target['quality']:.0%} · SSD确认 {target['ssd_age']:.1f}秒前"
                if target.get('continuous') else f"SSD鸟框 {target['score']:.0%}")
        text=(f"{source} · 图像帧 #{target['sequence']} · {target['age']:.1f}秒前\n"
              f"中心偏差 x={dx:+.0f}px y={dy:+.0f}px · "+
              ('上下已对准 · 左右锁定' if target.get('vertical_only') and target['centered'] else
               '等待上下对准 · 左右锁定' if target.get('vertical_only') else
               '已在中心容差内' if target['centered'] else '等待云台对准'))
        if target.get('control_text'):text+='\n'+target['control_text']
    else:text='视频停更 · 隐藏旧鸟框' if stale else '白色十字：画面中心 · 等待有效鸟类检测框'
    canvas.create_text(8,338,anchor='sw',fill='white',text=text,tags=tag)

def tracking_text(target,stale=False):
    if stale:return '视频停更，旧鸟框已隐藏'
    if target:
        if target.get('provisional'):return '待确认鸟框；后续检测确认后进入正式追踪'
        if target.get('control_text'):return target['control_text']
        if target.get('reacquiring'):return '短暂失配，板端正在找回目标；灰框为上次位置，等待新的有效匹配'
        if target.get('vertical_only'):return '上下已对准；左右保持锁定' if target['centered'] else '仅调节上下，让鸟框中心与白色十字等高'
        return '目标已在中心容差内' if target['centered'] else '用舵机移动镜头，让黄点靠近白色十字'
    return '等待SSD检测或重建目标；检测有延迟，移动后等待重新检测'
