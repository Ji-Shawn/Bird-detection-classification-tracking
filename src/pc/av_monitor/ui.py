"""Dependency-light Tkinter GUI; no Qt or C++ runtime is required."""

from __future__ import annotations
from .sd_record_status import status_text as sd_record_status_text

import math
import tkinter as tk
from tkinter import ttk
from pathlib import Path
import json,time
import numpy as np

from .network import ReceiverService
from .video import rgb565_to_rgb888
from .recognition import result_text
from .bird_zoom import active_box, FrameRenderer, focus_text, ZoomTransition, FULL
from .tracking_overlay import tracking_target,draw_tracking,tracking_text,tracker_confirmation_ms,TRACKER_REASONS,selection_text
from .ssd_preview import preview_target
from .servo_limits import auto_pan_limits as _servo_auto_pan_limits
from .visual_tuning_panel import VisualTuningPanel
from .audio_tuning_panel import AudioTuningPanel
from .scan_preview_tuning_panel import ScanPreviewTuningPanel
from .frame_flow import FrameFlow
from .video_health import preview_stale_after_s, health_text


def _ppm(rgb: np.ndarray) -> bytes:
    height, width, _ = rgb.shape
    return f"P6 {width} {height} 255\n".encode("ascii") + rgb.tobytes()


def _mel_rgb(data: np.ndarray, width: int = 600, lift_weak: bool = False) -> np.ndarray:
    if data.shape[1] > width:
        data = data[:, -width:]
    elif data.shape[1] < width:
        data = np.pad(data, ((0, 0), (width - data.shape[1], 0)))
    # Firmware encodes a fixed -80..0 dBFS interval across uint16. Keep a
    # fixed display transfer curve across frames, but lift low/mid energy so
    # bird harmonics remain visible without changing the transported tensor.
    display_floor = 2048.0
    display_ceiling = 49152.0
    normalized = np.clip(
        (data.astype(np.float32) - display_floor) /
        (display_ceiling - display_floor),
        0.0,
        1.0,
    )
    scaled = np.rint((np.sqrt(normalized) if lift_weak else normalized) * 255.0).astype(np.uint8)
    scaled = np.flipud(scaled)
    return np.stack((scaled, np.minimum(255, scaled.astype(np.uint16) * 2).astype(np.uint8),
                     (255 - scaled) // 2), axis=-1)


def _direction_display(telemetry, direction, classes):
    if not telemetry.get('online') or telemetry.get('telemetry_age_s',float('inf'))>1:
        return False,'板子离线','板子离线：鸟声方位暂停，等待重新连接。'
    if telemetry.get('fusion_mode')==1:
        return False,'独立视觉：方位暂停','独立视觉模式：鸟声方位暂停。点击“正常融合”恢复音频识别。'
    if telemetry.get('fusion_mode') not in (0,2):
        return False,'等待模式状态','等待板端运行模式，暂不显示方位。'
    if telemetry.get('fusion_mode')==2 and telemetry.get('sound_tracking_state')==4:
        return False,'视觉接管追踪','鸟框有效，视觉正在控制云台；丢失目标后恢复听声寻找。'
    if telemetry.get('capture_state')==2:
        return False,'输入已冻结','输入已冻结：鸟声方位暂停。点击“恢复推理”。'
    mask=telemetry.get('mic_mask')
    if mask!=15:
        message=('四麦输入异常：音频识别与方位暂停。' if mask==0 else
                 '麦克风未全部就绪：鸟声方位暂停；需四路麦克风均正常。')
        return False,'麦克风未就绪',message
    percent=telemetry.get('direction_threshold_percent')
    if percent is None:
        return False,'等待鸟声门控状态','当前固件无鸟声置信度门控状态，隐藏方位。'
    bird=telemetry.get('direction_bird_class',0xffffffff)
    score=telemetry.get('direction_bird_confidence',0)
    if not 0<=bird<len(classes):
        return False,'等待鸟声识别',f'等待完整音频窗及识别结果；方位门槛为音频置信度 >{percent}%。'
    candidate=f'板端门槛 >{percent}% | 确认鸟声 {classes[bird]} {score:.1%}'
    if not score>percent/100:
        return False,'鸟声置信度未达门槛',candidate+'\n音频置信度未超过门槛，隐藏方位。'
    if not direction.valid:
        return False,'暂无新鲜有效方位',candidate+'\n当前无新鲜有效方位；等待定位恢复或重新确认鸟声。'
    age=telemetry.get('direction_age_ms')
    age_text=f'，采样距今 {age/1000:.1f}秒' if age is not None else ''
    return True,'',candidate+age_text+'\n确认鸟声后持续更新角度；声音消失或定位持续无效时退出。'


def _servo_elevation_text(t):
    """Use the firmware shaft calibration once; this is not encoder feedback."""
    pulse = t.get('servo_tilt_us')
    if not isinstance(pulse, (int, float)) or isinstance(pulse, bool) or not math.isfinite(pulse):
        return '仰角（指令估计）：未知 · 等待竖直PWM回读'
    pulses = (540,640,740,840,940,1040,1140,1240,1340,1440,
              1540,1640,1740,1840,1940,2040,2140,2240,2340,2440,2480)
    angles = (0,10,20,30,40,50,60,70,80,90,
              100,105,110,120,125,140,145,150,165,175,180)
    if not pulses[0] <= pulse <= pulses[-1]:
        return f'仰角（指令估计）：未知 · 俯仰PWM {pulse:g} μs（超出标定范围）'
    for low, high, a0, a1 in zip(pulses, pulses[1:], angles, angles[1:]):
        if pulse <= high:
            angle = a0 + (pulse-low)*(a1-a0)/(high-low)
            return f'仰角（指令估计）：{angle:.1f}° · 俯仰PWM {pulse:g} μs（无编码器反馈）'


def _servo_position_text(t):
    reason={0:'手动保持位置',1:'等待稳定鸟框',2:'目标已在画面中心',3:'等待位置调节间隔',
        4:'当前方向已达位置边界',5:'等待运动后的新画面',6:'等待鸟框',7:'正在调整位置',
        8:'心跳超时，保持当前位置',9:'丢失目标，缓慢归中',10:'已归中，等待新的声音方位'}
    text=(f"水平位置指令：{t['servo_camera_angle_deg']-180:+.1f}° · PWM {t['servo_pan_us']} μs · "
        '180°舵机 × 2倍云台传动（指令角度，无编码器反馈）\n'
        '前方 0° / 1440 μs；PWM减小左转，增大右转；范围 −180°～+180° / 540–2480 μs。\n'
        +_servo_elevation_text(t)+' · '+reason.get(t.get('servo_tracking_reason'),'等待状态'))
    if t.get('servo_homing'):
        text+=f"\n缓慢归中：每 {t['servo_home_interval_ms']} ms 调整 {t['servo_home_step_us']} μs；归中后再等待新声音。"
    if t.get('sound_tracking_enabled'):
        state={1:'等待新识别的有效鸟声方位',2:'等待归中或转动后采集的声音',3:'已朝向声源',
            4:'视觉接管',5:'位置边界',6:'等待位置调节间隔',7:'限速转向已锁定声源，等待稳定',8:'心跳超时',9:'缓慢归中',
            10:'持续听声，水平保持，竖直 0°～135° 扫视；新方位有效时重新转向',
            11:'发现待确认鸟框，暂停上下扫描 3 秒，等待视觉确认'}
        text+='\n音视联动：'+state.get(t.get('sound_tracking_state'),'等待状态')
        if t.get('sound_tracking_mount')=='base':
            text+=' · 麦克风固定底座，声音方位直接对应水平目标角度'
    elif not t.get('servo_auto'):
        text+='\n自动追踪关闭；开启“视觉追踪”或“音视联动”。停止后保持当前位置。'
    return text


def _servo_text(t):
    if t.get('servo_position_supported'):
        return _servo_position_text(t)
    limit_off=bool(t.get('servo_pan_limit_toggle_supported') and not t.get('servo_pan_limit_enabled',True))
    relative=t.get('servo_limit_policy')=='relative_position'
    limits=t.get('servo_limits',0)
    pan_text=('等待点动结束/冷却' if t.get('servo_busy') else '左右手动点动预算不足；俯仰可微调' if limits==3 else
              '左手动点动预算不足；右可点动' if limits==1 else '右手动点动预算不足；左可点动' if limits==2 else '可点动')
    if relative:
        pan_text=('角度参考无效，左右已锁定' if not t.get('servo_reference_valid') else
                  '等待点动结束/冷却' if t.get('servo_busy') else
                  '左右受限' if limits==3 else
                  '接近左侧位置边界；可向右返回' if limits==1 else
                  '接近右侧位置边界；可向左返回' if limits==2 else '可左右往返')
    pose=t.get('servo_limit_position_deg',t.get('servo_estimated_pan',0)) if relative else t.get('servo_estimated_pan',0)
    direction='左' if pose<0 else '右' if pose>0 else '初始朝向'
    if t.get('servo_config_supported') and not t.get('servo_angle_estimate_valid'):
        text='水平角度估算：不可用（已使用未标定PWM，需重新建立实体0°参考）\n'
    else:text=f"水平角度估算：{direction} {abs(pose):.2f}° · 按PWM输出时长推算，非实测角度\n"
    text+=_servo_elevation_text(t)+' · '
    if limit_off:
        text+='左右软件限位：关闭（调试） · '+('等待点动结束/冷却' if t.get('servo_busy') else '可左右点动')
    elif relative:
        text+=(f"相对0°位置限位 {t.get('servo_position_min_deg',-170):g}°～"
               f"{t.get('servo_position_max_deg',170):g}° · {pan_text}")
    else:
        text+=(f"左/右累计预算 {t.get('servo_left_budget',0):.1f}° / "
               f"{t.get('servo_right_budget',0):.1f}°，各{t.get('servo_limit_deg',170):g}° · {pan_text}")
    if t.get('servo_diagnostic_supported'):
        reason={0:'手动控制',1:'等待新的有效定位',2:'鸟框中心已在中心容差内',
            3:'等待点动冷却',4:'当前方向已达软件限位',5:'等待运动后采集的新鸟框',
            6:'等待有效鸟框（置信度>50%，采样≤5秒）',7:'正在点动',8:'追踪心跳超时，已停止'}.get(t.get('servo_tracking_reason'),'等待状态')
        text+=(f"\n左 {t['servo_left_us']} / 右 {t['servo_right_us']} / 停 {t['servo_stop_us']} µs · "
               f"上次水平动作 {t.get('servo_last_burst_ms',0)} ms · 已输出左/右 {t.get('servo_left_frames',0)} / "
               f"{t.get('servo_right_frames',0)} 个20 ms周期 · 追踪{'开启' if t.get('servo_auto') else '关闭'}：{reason}")
    if t.get('servo_config_supported') and not t.get('servo_pwm_calibrated'):
        text+='\n当前PWM未经转速标定：不使用原转速推算后续转角，左右软件限位开启时锁定水平运动。'
    elif t.get('servo_guard_supported'):
        text+=(f"\n空载实测估算速率：左 {t.get('servo_left_rate',0):.2f} / 右 {t.get('servo_right_rate',0):.2f}°/s；"
               "带载启动/停止角度尚待校准。"+
               ("目前不执行左右角度限位检查。" if limit_off else "每次点动预留50%速度余量，非实测转角。"))
        if _servo_auto_pan_limits(t)==3:
            text+='\n水平自动受限，左右保持锁定；俯仰独立调节，不受水平偏差阻挡。'
            text+=(' 角度参考无效，需停止并重新确认实体0°参考。' if relative else
                   ' 总路程累计额度已耗尽，回中不会回补；需停止并重新确认实体0°参考。')
    if t.get('visual_tracker_supported'):
        text+=(f"\n板端连续跟踪：{'运行' if t.get('visual_tracker_active') else '等待SSD确认并建立目标'} · "
               f"已跟踪 {t.get('visual_tracker_frames',0)} 帧 · 匹配质量 {t.get('visual_tracker_quality',0):.0%}")
        if t.get('visual_tracker_active'):
            text+=f" · SSD确认 {t.get('visual_tracker_ssd_age_ms',0)/1000:.1f}秒前"
        if t.get('visual_tracker_reacquire_supported'):
            if t.get('visual_tracker_state')==2:
                text+=f" · 正在找回（失配{t.get('visual_tracker_misses',0)}帧），暂停新的舵机调节"
            text+=(f" · 已找回 {t.get('visual_tracker_recovered',0)} 次 · 最近丢失原因："+
                   TRACKER_REASONS.get(t.get('visual_tracker_last_loss_reason',0),'未知'))
        text+=' · 自动俯仰20/40/60 µs步长，最短400 ms间隔；手动仍20 µs'
        selected=selection_text(t)
        if selected:text+='\n'+selected
    if not t.get('servo_auto'):
        text+='\n追踪关闭：点击“开启视觉追踪”；手动控制、切换模式或分类策略会关闭追踪。'
        if t.get('sound_tracking_supported'):
            text+=' 听声寻找并接管视觉请点击“开启音视联动”。'
    elif t.get('capture_state')==2:
        text+='\n输入已冻结：点击“恢复推理”，再开启视觉追踪。'
    elif t.get('sound_tracking_enabled'):
        sound_state=5 if _servo_auto_pan_limits(t)==3 else t.get('sound_tracking_state')
        state={0:'已关闭',1:'等待新识别的有效鸟声方位',2:'等待转动后重新采集的声音',
            3:'估算已进入正前方容差，等待新方位或鸟框',4:'鸟框有效，视觉接管',
            5:'当前方向已达软件限位',6:'等待点动冷却',7:'正在分段朝声源转向',
            8:'心跳超时，已停止',11:'发现待确认鸟框，暂停上下扫描 3 秒'}.get(sound_state,'等待板端状态')
        text+=f'\n音视联动：{state} · 已执行声控点动 {t.get("sound_tracking_steps",0)} 次'
        if t.get('register_version',0)>=0x10007:
            text+=' · 剩余偏差>30°时300 ms，≤30°时60–120 ms'
        if t.get('sound_tracking_age_ms') is not None:
            text+=f' · 上次声音角度 {t.get("sound_tracking_angle_deg",0):+.1f}°'
    elif (t.get('visual_tracker_reacquire_supported') and t.get('visual_tracker_state')==2):
        text+='\n短暂失配，正在从新画面找回目标；灰框不参与舵机控制。'
    elif (t.get('visual_tracker_active') and t.get('visual_tracker_target_valid') and
          t.get('visual_tracker_frame_age_ms',1001)<=1000 and
          t.get('visual_tracker_ssd_age_ms',0xffffffff)<=tracker_confirmation_ms(t)):
        text+='\n连续鸟框有效；俯仰按最新画面及冷却状态调节。'
    elif not t.get('detection_valid') or t.get('detection_age_ms',5001)>5000:
        text+='\n等待新鲜有效SSD鸟框（>50%）；手动画的选区不参与舵机追踪。'
    return text


class MonitorWindow:
    def __init__(self, root: tk.Tk, receiver: ReceiverService, metrics_file=None, sd_attach: bool=False) -> None:
        self.root = root
        self.receiver = receiver
        self._sd_attach = sd_attach
        self.root.title("AX7020 三模型识别 · 实时图像 / Log-Mel / 鸟声方位")
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        self._closed = False
        self._video_image: tk.PhotoImage | None = None
        self._mel_image: tk.PhotoImage | None = None
        self.lift_weak = tk.BooleanVar(value=False)
        self.metrics_file=metrics_file;self.last_metrics=0
        self._frame_flow=FrameFlow()
        self.roi_box=None;self.roi_start=None;self.select_roi=tk.BooleanVar(value=False)
        self._display_frame=None;self._display_key=None
        self._display_rgb=None;self._display_boot=None;self._zoom_transition=ZoomTransition(.8)
        self._renderer=None;self._source_key=None;self._last_details=0
        self._frame_received_at=0;self._servo_heartbeat_at=0
        self._config_loaded_boot=None;self._config_pending=None
        self._visual_tuning_window=None;self._visual_tuning_panel=None
        self._audio_tuning_window=None;self._audio_tuning_panel=None
        self._scan_preview_tuning_window=None;self._scan_preview_tuning_panel=None
        self._last_telemetry={}

        root.rowconfigure(0,weight=1);root.columnconfigure(0,weight=1)
        viewport=tk.Canvas(root,highlightthickness=0)
        viewport.grid(row=0,column=0,sticky='nsew')
        vertical=ttk.Scrollbar(root,orient='vertical',command=viewport.yview)
        vertical.grid(row=0,column=1,sticky='ns')
        horizontal=ttk.Scrollbar(root,orient='horizontal',command=viewport.xview)
        horizontal.grid(row=1,column=0,sticky='ew')
        viewport.configure(yscrollcommand=vertical.set,xscrollcommand=horizontal.set)
        outer = ttk.Frame(viewport, padding=8)
        viewport.create_window((0,0),window=outer,anchor='nw')
        outer.bind('<Configure>',lambda e:viewport.configure(scrollregion=viewport.bbox('all')))
        root.geometry(f'{min(1300,root.winfo_screenwidth()-60)}x{min(900,root.winfo_screenheight()-80)}')
        self.video_label = tk.Canvas(outer,width=640,height=360,highlightthickness=0,bg='#101820')
        self.video_label.grid(row=5, column=0, padx=4, pady=4)
        self.video_item=self.video_label.create_image(0,0,anchor='nw')
        self.video_label.bind('<ButtonPress-1>',self._roi_start)
        self.video_label.bind('<B1-Motion>',self._roi_drag)
        self.video_label.bind('<ButtonRelease-1>',self._roi_end)
        right = ttk.Frame(outer)
        right.grid(row=5, column=1, padx=4, pady=4, sticky="n")
        self.mel_label = ttk.Label(right, text="等待 128 维 Log-Mel…")
        self.mel_label.grid(row=0, column=0)
        ttk.Checkbutton(right,text='提亮弱信号（也会放大底噪，仅改变显示）',variable=self.lift_weak).grid(row=2,column=0)
        self.compass = tk.Canvas(right, width=260, height=180, bg="#101820", highlightthickness=0)
        self.compass.grid(row=1, column=0, pady=8)
        doa_controls=ttk.Frame(right);doa_controls.grid(row=3,column=0,sticky='w')
        ttk.Label(doa_controls,text='方位输出：鸟种置信度 >').pack(side='left')
        self.direction_threshold=tk.StringVar(value='80')
        self._last_direction_percent=None
        self.direction_threshold_input=ttk.Spinbox(doa_controls,from_=1,to=99,width=4,textvariable=self.direction_threshold)
        self.direction_threshold_input.pack(side='left')
        ttk.Label(doa_controls,text='%').pack(side='left')
        ttk.Button(doa_controls,text='应用',command=self._direction_threshold).pack(side='left')
        self.direction_status=ttk.Label(right,text='等待板端鸟声门控状态',wraplength=590)
        self.direction_status.grid(row=4,column=0,sticky='w')
        self.status = ttk.Label(outer, text="初始化…", justify="left")
        self.status.grid(row=6, column=0, columnspan=2, sticky="w")
        controls=ttk.Frame(outer);controls.grid(row=4,column=0,columnspan=2,sticky='ew',pady=6)
        for text,command,value in [('正常融合',5,0),('独立视觉测试',5,1),('冻结下一次输入',6,1),
                                   ('恢复推理',6,0),('原始画面',4,0),('自动增强',4,1),
                                   ('PL彩条诊断',7,1),('恢复摄像头',7,0)]:
            ttk.Button(controls,text=text,command=lambda c=command,v=value,t=text:self._control(c,v,t)).pack(side='left',padx=2)
        ttk.Button(controls,text='保存画面',command=self._save_frame).pack(side='left',padx=2)
        self.control_status=ttk.Label(outer,text='');self.control_status.grid(row=8,column=0,columnspan=2,sticky='w')
        roi_controls=ttk.Frame(outer);roi_controls.grid(row=0,column=0,columnspan=2,sticky='ew',pady=4)
        ttk.Checkbutton(roi_controls,text='框选鸟（拖动左侧画面）',variable=self.select_roi).pack(side='left')
        for label,policy in [('整图分类',0),('自动小鸟裁剪',1),('使用手动鸟框',2),('同帧整图/鸟框对照',3)]:
            ttk.Button(roi_controls,text=label,command=lambda p=policy:self._image_policy(p)).pack(side='left',padx=3)
        self.roi_status=ttk.Label(outer,text='手动框选完整鸟身，自动保留50%上下文；手动模式切换为独立视觉，固定区域不跟踪移动鸟。')
        self.roi_status.grid(row=1,column=0,columnspan=2,sticky='w')
        focus_controls=ttk.Frame(outer)
        focus_controls.grid(row=9,column=0,columnspan=2,sticky='w',pady=5)
        for label,action in [('自动放大/对焦',1),('关闭自动放大/对焦',0),('重新对焦/重试',2)]:
            ttk.Button(focus_controls,text=label,
                command=lambda a=action,t=label:self._control(11,a,t)).pack(side='left',padx=3)
        self.focus_status=ttk.Label(outer,text='等待对焦状态')
        self.focus_status.grid(row=10,column=0,columnspan=2,sticky='w')
        manual=ttk.LabelFrame(outer,text='手动镜头调焦 · 码值不是距离；应用后关闭自动放大/对焦',padding=5)
        manual.grid(row=11,column=0,columnspan=2,sticky='ew',pady=4)
        self.manual_focus_value=tk.StringVar(value='512')
        ttk.Label(manual,text='镜头码值 0–1023').pack(side='left')
        ttk.Spinbox(manual,from_=0,to=1023,increment=8,width=6,textvariable=self.manual_focus_value).pack(side='left',padx=3)
        self.manual_focus_buttons=[]
        for label,delta in [('−32',-32),('−8',-8),('应用',0),('+8',8),('+32',32)]:
            button=ttk.Button(manual,text=label,command=lambda d=delta:self._manual_focus(d))
            button.pack(side='left',padx=2);self.manual_focus_buttons.append(button)
        ttk.Button(manual,text='恢复自动对焦',command=lambda:self._control(11,1,'恢复自动对焦')).pack(side='left',padx=4)
        self.manual_focus_status=ttk.Label(outer,text='等待手动调焦能力信息')
        self.manual_focus_status.grid(row=12,column=0,columnspan=2,sticky='w')
        servo=ttk.LabelFrame(outer,text='云台 · 视觉追踪 / 声音寻找 / 软件限位',padding=5)
        servo.grid(row=2,column=0,columnspan=2,sticky='ew',pady=4)
        servo_actions=ttk.Frame(servo);servo_actions.pack(anchor='w',fill='x')
        self.servo_buttons=[]
        for label,command,value in [('左转一点',13,1),('右转一点',13,2),
                                    ('停止 / 关闭追踪',13,0),('开启视觉追踪',15,1)]:
            button=ttk.Button(servo_actions,text=label,command=lambda c=command,v=value,t=label:self._control(c,v,t))
            button.pack(side='left',padx=3);self.servo_buttons.append(button)
        for label,delta in [('向上微调',-20),('向下微调',20)]:
            button=ttk.Button(servo_actions,text=label,command=lambda d=delta:self._servo_tilt(d))
            button.pack(side='left',padx=3);self.servo_buttons.append(button)
        self.sound_tracking_button=ttk.Button(servo_actions,text='开启音视联动',
            command=lambda:self._control(15,2,'开启音视联动'))
        self.sound_tracking_button.pack(side='left',padx=3)
        self.pan_limit_button=ttk.Button(servo_actions,text='左右限位开关不可用',command=self._toggle_pan_limit)
        self.pan_limit_button.pack(side='left',padx=3)
        ttk.Button(servo_actions,text='视觉在线调参',command=self._open_visual_tuning).pack(side='left',padx=3)
        ttk.Button(servo_actions,text='听觉在线调参',command=self._open_audio_tuning).pack(side='left',padx=3)
        runtime_actions=ttk.Frame(servo);runtime_actions.pack(anchor='w',fill='x',pady=(4,0))
        ttk.Button(runtime_actions,text='扫描与预览在线调参',command=self._open_scan_preview_tuning).pack(side='left',padx=3)
        if self._sd_attach:
            ttk.Label(servo,wraplength=1100,text='SD 连接：关闭窗口仅断开连接；停止请点“停止 / 关闭追踪”。电脑接管后的自动控制仍按断线规则停止。').pack(anchor='w',pady=(4,0))
        debug=ttk.LabelFrame(servo,text='左右参数调试 · 手动点动和视觉追踪共用',padding=4)
        self.servo_debug_frame=debug
        debug.pack(anchor='w',fill='x',pady=(5,0))
        self.servo_config_values=[tk.StringVar(value=v) for v in ('1650','1300','100','100')]
        self.servo_config_inputs=[]
        for col,label,index,lo,hi,step in ((0,'左PWM µs',0,1501,2000,5),(2,'左远/手动 ms',2,20,300,20),
                                        (4,'右PWM µs',1,1000,1499,5),(6,'右远/手动 ms',3,20,300,20)):
            ttk.Label(debug,text=label).grid(row=0,column=col,padx=(3,0))
            field=ttk.Spinbox(debug,from_=lo,to=hi,increment=step,width=6,textvariable=self.servo_config_values[index])
            field.grid(row=0,column=col+1,padx=3);self.servo_config_inputs.append(field)
        self.servo_config_apply=ttk.Button(debug,text='应用参数',command=self._apply_servo_config)
        self.servo_config_apply.grid(row=0,column=8,padx=3)
        self.servo_config_read=ttk.Button(debug,text='读取当前',command=self._read_servo_config)
        self.servo_config_read.grid(row=0,column=9,padx=3)
        ttk.Button(debug,text='填入默认值',command=self._default_servo_config).grid(row=0,column=10,padx=3)
        near=ttk.Frame(debug);near.grid(row=1,column=0,columnspan=11,sticky='w',pady=4)
        self.servo_near_enabled=tk.BooleanVar(value=True)
        self.servo_near_values=[tk.StringVar(value=v) for v in ('192','40','40')]
        self.servo_near_checkbox=ttk.Checkbutton(near,text='视觉接近中心时缩短点动',variable=self.servo_near_enabled)
        self.servo_near_checkbox.pack(side='left',padx=3)
        self.servo_near_inputs=[]
        for index,label,lo,hi,step in ((0,'水平阈值（原图px）',60,960,12),(1,'左近 ms',20,300,20),(2,'右近 ms',20,300,20)):
            ttk.Label(near,text=label).pack(side='left',padx=(8,0))
            field=ttk.Spinbox(near,from_=lo,to=hi,increment=step,width=6,textvariable=self.servo_near_values[index])
            field.pack(side='left',padx=3);self.servo_near_inputs.append(field)
        actions=ttk.Frame(debug);actions.grid(row=2,column=0,columnspan=11,sticky='w',pady=3)
        self.servo_config_tests=[]
        for label,direction in (('左转测试',1),('右转测试',2)):
            button=ttk.Button(actions,text=label,command=lambda d=direction:self._test_servo_config(d))
            button.pack(side='left',padx=3);self.servo_config_tests.append(button)
        self.servo_config_status=ttk.Label(actions,text='等待支持参数调试的新固件',wraplength=920)
        self.servo_config_status.pack(side='left',padx=5)
        ttk.Label(debug,wraplength=1100,justify='left',text='时间20–300 ms，步进20 ms；输入后点“应用参数”。水平偏差≤48px停止，48px外且≤阈值用近档，超过阈值用远档；手动测试用远/手动时长。').grid(row=3,column=0,columnspan=11,sticky='w')
        ttk.Label(debug,wraplength=1100,justify='left',text='阈值按1920px原图计（预览中÷3），蓝线表示分档边界；PWM周期20ms、停止1500µs。修改PWM前先关闭左右限位；重启恢复默认。').grid(row=4,column=0,columnspan=11,sticky='w')
        self.servo_status=ttk.Label(outer,text='等待云台能力信息',wraplength=1200)
        self.servo_status.grid(row=3,column=0,columnspan=2,sticky='w')
        recognition = ttk.LabelFrame(outer, text='板上识别结果 · 60类鸟种代码', padding=10)
        recognition.grid(row=7, column=0,columnspan=2,sticky='ew',pady=(10,0))
        self.result_title = ttk.Label(recognition, text='等待板上识别结果…', font=('Microsoft YaHei UI', 17, 'bold'))
        self.result_title.pack(anchor='w')
        self.result_detail = ttk.Label(recognition, text='', justify='left', font=('Microsoft YaHei UI', 10))
        self.result_detail.pack(anchor='w', pady=5)
        ttk.Label(recognition, text='置信度不是准确率；仅音频结果不代表摄像头已确认鸟类。画面为实时帧，识别结果有计算延迟。').pack(anchor='w')
        self.root.after(33, self._refresh)

    def _refresh(self) -> None:
        if self._closed:
            return
        frame, telemetry, stats = self.receiver.snapshots()
        self._last_telemetry=telemetry
        if self._visual_tuning_panel is not None:
            self._visual_tuning_panel.update(telemetry)
        if self._audio_tuning_panel is not None:
            self._audio_tuning_panel.update(telemetry)
        if self._scan_preview_tuning_panel is not None:
            self._scan_preview_tuning_panel.update(telemetry)
        percent=telemetry.get('direction_threshold_percent')
        if (isinstance(percent,int) and 1<=percent<=99 and percent!=self._last_direction_percent and
                self.root.focus_get()!=self.direction_threshold_input):
            self.direction_threshold.set(str(percent));self._last_direction_percent=percent
        servo_ready=(telemetry.get('online') and telemetry.get('telemetry_age_s',float('inf'))<=1 and
                     telemetry.get('servo_supported'))
        if servo_ready and telemetry.get('servo_auto') and time.monotonic()-self._servo_heartbeat_at>.5:
            try:self.receiver.send_servo_keepalive()
            except (RuntimeError,OSError):pass
            self._servo_heartbeat_at=time.monotonic()
        busy=bool(telemetry.get('servo_busy'))
        config_dirty=self._update_servo_config(telemetry)
        limits=telemetry.get('servo_limits',0)
        for index,button in enumerate(self.servo_buttons):
            enabled=servo_ready
            if index in (0,1):enabled=enabled and not busy and not (limits & (1<<index))
            if index in (0,1,3) and config_dirty:enabled=False
            if index==3:
                enabled=enabled and not telemetry.get('servo_auto')
                button.configure(text=('视觉追踪（联动中）' if telemetry.get('sound_tracking_enabled') else
                    '视觉追踪已开启' if telemetry.get('servo_auto') else
                    '开启上下追踪（左右锁定）' if telemetry.get('visual_tracker_supported') and _servo_auto_pan_limits(telemetry)==3 else
                    '开启追踪（水平受限）' if _servo_auto_pan_limits(telemetry)==3 else '开启视觉追踪'))
            if index in (4,5):enabled=enabled and not busy
            button.configure(state='normal' if enabled else 'disabled')
        sound_enabled=bool(telemetry.get('sound_tracking_enabled'))
        self.sound_tracking_button.configure(text='音视联动已开启' if sound_enabled else '开启音视联动',
            state='normal' if servo_ready and telemetry.get('sound_tracking_supported') and
                not telemetry.get('servo_auto') and (not telemetry.get('servo_config_supported') or
                (telemetry.get('servo_pwm_calibrated') and telemetry.get('servo_angle_estimate_valid') and
                 telemetry.get('servo_reference_valid'))) else 'disabled')
        limit_toggle_ready=servo_ready and telemetry.get('servo_pan_limit_toggle_supported')
        self.pan_limit_button.configure(
            text=('关闭左右软件限位' if telemetry.get('servo_pan_limit_enabled',True) else '启用左右软件限位')
                 if telemetry.get('servo_pan_limit_toggle_supported') else ('水平位置范围固定（0°–360°）' if telemetry.get('servo_position_supported') else '左右限位开关不可用'),
            state='normal' if limit_toggle_ready else 'disabled')
        if servo_ready:
            self.servo_status.configure(text=_servo_text(telemetry)+'\n'+sd_record_status_text(telemetry))
        else:self.servo_status.configure(text=('板子离线，云台控制暂停' if not telemetry.get('online') else
                                             '云台状态未就绪，需要配套bit与core0固件；自动追踪默认关闭'))
        manual_ready=(telemetry.get('online') and telemetry.get('telemetry_age_s',float('inf'))<=1 and
                      telemetry.get('manual_focus_supported') and telemetry.get('focus_state') not in (0,1,5))
        for button in self.manual_focus_buttons:button.configure(state='normal' if manual_ready else 'disabled')
        if not telemetry.get('manual_focus_supported'):
            manual_text='当前固件未提供手动调焦；需要配套新core0固件'
        elif not telemetry.get('online') or telemetry.get('telemetry_age_s',float('inf'))>1:
            manual_text='状态过期，手动调焦不可用'
        elif telemetry.get('manual_focus_mode'):
            manual_text=f"手动目标 {telemetry.get('manual_focus_target')} / 寄存器回读 {telemetry.get('manual_focus_readback')} · "+('移动中' if telemetry.get('manual_focus_busy') else '保持')
            if telemetry.get('focus_error'):manual_text+=' · 调焦失败，请恢复自动对焦重新初始化'
        else:manual_text='自动模式；输入码值后点应用，或点±8微调；手动时不需要检测到鸟'
        self.manual_focus_status.configure(text=manual_text)
        now=time.monotonic()
        if frame is not None:
            self._display_frame=frame
            source_key=(frame.boot_id,frame.frame_id,frame.timestamp_us)
            if source_key!=self._source_key:
                self._display_rgb=rgb565_to_rgb888(frame.rgb565)
                self._renderer=FrameRenderer(self._display_rgb);self._source_key=source_key
                self._frame_received_at=now
        frame=self._display_frame
        frame_stale=frame is not None and now-self._frame_received_at>preview_stale_after_s(telemetry)
        # Servo tracking must show the real sensor center, without digital crop.
        tracking_view=telemetry.get('servo_supported',False)
        box=active_box(telemetry,frame.boot_id,self.select_roi.get()) if frame and not frame_stale and not tracking_view else None
        immediate=(frame_stale or not telemetry.get('online') or telemetry.get('telemetry_age_s',float('inf'))>1 or
                   not telemetry.get('focus_enabled') or self.select_roi.get() or tracking_view or
                   (frame and (self._display_boot!=frame.boot_id or telemetry.get('boot_id')!=frame.boot_id)))
        animated=self._zoom_transition.update(box,time.monotonic(),immediate=immediate)
        if frame:self._display_boot=frame.boot_id
        view_box=animated if animated!=FULL else None
        key=(frame.boot_id,frame.frame_id,view_box,frame_stale) if frame else None
        if frame is not None and self.roi_start is None and key!=self._display_key:
            rgb=self._renderer.render(view_box)
            self._video_image = tk.PhotoImage(data=_ppm(rgb), format="PPM")
            self.video_label.itemconfigure(self.video_item,image=self._video_image)
            self.video_label.delete('zoom_label')
            self.video_label.delete('stale_label')
            if frame_stale:
                self.video_label.create_text(8,8,anchor='nw',fill='#ff7050',tags='stale_label',
                    text='视频已停更 · 当前为旧帧，等待新图像')
            if view_box:
                self.video_label.delete('selection')
                self.video_label.create_text(8,8,anchor='nw',fill='#ffff70',tags='zoom_label',
                    text=f'渐变数字放大 {1920/(view_box[2]-view_box[0]):.1f}x · 最近鸟框区域（非逐帧追踪）')
            self._display_key=key
        target=tracking_target(telemetry,frame.boot_id,frame_stale) if frame and tracking_view else None
        if target is None and frame and tracking_view:
            target=preview_target(telemetry,frame.boot_id,frame_stale)
        if frame and tracking_view and self.roi_start is None:
            draw_tracking(self.video_label,target,frame_stale,
                telemetry.get('servo_near_threshold_px') if telemetry.get('servo_visual_config_supported') and
                telemetry.get('servo_near_enabled') else None)
        else:self.video_label.delete('tracking')
        self.focus_status.configure(text=focus_text(telemetry)+
            (' | 视频旧帧，等待恢复' if frame_stale else
             ' | 全景 · '+tracking_text(target) if tracking_view else
             ' | 已放大，右下角为全景' if box else ' | 全景；连续两次鸟检测确认后放大'))
        # Keep zoom at 30Hz, while Mel/text/compass refresh at <=10Hz. Never
        # hold the receiver lock while resizing or constructing Tk images.
        if time.monotonic()-self._last_details<.1:
            self.root.after(33,self._refresh);return
        self._last_details=time.monotonic()
        mel, direction = self.receiver.features.snapshot()
        mel_rgb = _mel_rgb(mel,lift_weak=self.lift_weak.get())
        self._mel_image = tk.PhotoImage(data=_ppm(mel_rgb), format="PPM")
        self.mel_label.configure(image=self._mel_image, text="")
        direction_valid,direction_reason,direction_text=_direction_display(telemetry,direction,self.receiver.classes)
        if self._audio_tuning_panel is not None:
            self._audio_tuning_panel.update_direction(direction,direction_valid,direction_reason)
        self._draw_compass(direction.angle_deg, direction.confidence, direction_valid,direction_reason)
        self.direction_status.configure(text=direction_text)
        result, age = self.receiver.recognition_snapshot()
        title, detail = result_text(result, age)
        if target and target.get('provisional'):
            title='首次检出鸟类候选 · 等待后续确认'
            detail='黄色虚线框会随当前画面更新；后续检测确认后转为正式追踪，鸟种分类另行显示。'
        elif (result and result['status']==9 and telemetry.get('visual_tracker_active') and
                telemetry.get('visual_tracker_target_valid') and
                telemetry.get('visual_tracker_frame_age_ms',1001)<=1000 and
                telemetry.get('visual_tracker_ssd_age_ms',0xffffffff)<=tracker_confirmation_ms(telemetry)):
            title='本次SSD未确认 · 板端仍在跟踪近期目标'
            detail=(f"最近一次SSD确认 {telemetry['visual_tracker_ssd_age_ms']/1000:.1f}秒前；"
                    f"当前匹配质量 {telemetry.get('visual_tracker_quality',0):.0%}。"
                    '继续等待SSD复核；跟踪丢失或确认过期后不再调节。')
        elif (telemetry.get('visual_tracker_reacquire_supported') and telemetry.get('visual_tracker_state')==2):
            title='短暂失配 · 板端正在找回目标'
            detail='灰框表示上次确认的位置；找回新的有效位置后才继续调节舵机。'
        self.result_title.configure(text=title, foreground='#9b3d00' if age>15 or (result and result['status']==4) else '#075c40')
        self.result_detail.configure(text=detail)
        self.control_status.configure(text=f"{telemetry.get('control_message','')} | 板端模式: { {0:'正常融合',1:'独立视觉',2:'音视联动'}.get(telemetry.get('fusion_mode'),'旧固件') } | "
                                     f"诊断采样: { {0:'运行',1:'待冻结',2:'已冻结，可导出'}.get(telemetry.get('capture_state'),'-') } | "
                                     f"麦克风健康掩码: {telemetry.get('mic_mask','-')} (15=四路正常) | 声音活动: {telemetry.get('audio_activity','-')}"+
                                     (' | 单麦降级分类，方位禁用' if 0<telemetry.get('mic_mask',15)<15 else
                                      ' | 四麦输入异常：音频推理与方位暂停' if telemetry.get('mic_mask')==0 else ''))
        self.status.configure(text=(
            f"板卡: {'在线' if telemetry.get('online') else '等待数据'}    "
            f"包: {stats.packets}  坏包: {stats.malformed}  PCM缺口: {stats.pcm_gaps}  "
            f"识别包: {stats.fusion_packets}  识别坏包: {stats.fusion_errors}  "
            f"接收FPS（近3s）: {telemetry.get('received_fps',0):.1f}  最近1s完整帧: {telemetry.get('video_last_second_frames',0)}  组帧超时: {telemetry.get('video_assembly_loss',0)}\n"
            f"亮度均值: {telemetry.get('mean_y', '-')}  暗像素比例Q15: "
            f"{telemetry.get('dark_ratio_q15', '-')}  PL帧计数: {telemetry.get('frame_count', '-')}\n"+
            health_text(telemetry)))
        if self.metrics_file and time.monotonic()-self.last_metrics>=1:
            self.last_metrics=time.monotonic()
            try:
                flow=self._frame_flow.sample(telemetry,stats.video_frames,time.monotonic_ns(),result,age)
                flow['wall_time']=time.time()
                self.metrics_file.write_text(json.dumps(dict(telemetry,packets=stats.packets,malformed=stats.malformed,
                    pcm_gaps=stats.pcm_gaps,video_frames=stats.video_frames,fusion_packets=stats.fusion_packets,
                    direction_valid=direction_valid,direction_feature_valid=direction.valid,
                    direction_angle_deg=direction.angle_deg if direction_valid else None,
                    direction_quality=direction.confidence if direction_valid else None,
                    frame_flow=flow,wall_time=time.time()),ensure_ascii=False,indent=2),encoding='utf-8')
                with self.metrics_file.with_name('frame_flow.jsonl').open('a',encoding='utf-8') as flow_file:
                    flow_file.write(json.dumps(flow,ensure_ascii=False)+'\n')
            except OSError:pass
        self.root.after(33, self._refresh)

    def _control(self,command,value,label):
        try:
            if command in (13,15) and value:
                _,t,_=self.receiver.snapshots()
                if t.get('servo_config_supported'):
                    if not self._config_ready(t):raise ValueError('参数状态过期，未发送')
                    if self._config_input(t)!=self._config_actual(t) or self._config_pending:
                        raise ValueError('请先应用参数并等待板端生效')
            self.receiver.send_control(command,value,label)
        except (OSError,RuntimeError,ValueError,KeyError) as e:self.control_status.configure(text=str(e))

    def _direction_threshold(self):
        try:
            value=int(self.direction_threshold.get())
            if not 1<=value<=99:raise ValueError('门槛须为1到99之间的整数')
            self.receiver.send_control(10,value,f'鸟声方位门槛>{value}%')
        except (OSError,RuntimeError,ValueError) as e:self.control_status.configure(text=str(e))

    def _toggle_pan_limit(self):
        try:
            _,t,_=self.receiver.snapshots()
            if (not t.get('online') or t.get('telemetry_age_s',float('inf'))>1 or
                    not t.get('servo_supported') or not t.get('servo_pan_limit_toggle_supported')):
                raise ValueError('左右限位开关状态未就绪')
            enabled=not t.get('servo_pan_limit_enabled',True)
            label=('启用' if enabled else '关闭')+'左右软件限位（并停止追踪）'
            self.receiver.send_control(17,int(enabled),label)
        except (OSError,RuntimeError,ValueError) as e:self.control_status.configure(text=str(e))

    @staticmethod
    def _config_ready(t):
        return bool(t.get('online') and t.get('telemetry_age_s',float('inf'))<=1 and t.get('servo_config_supported'))

    @staticmethod
    def _config_actual(t):
        values=(t['servo_left_us'],t['servo_right_us'],t['servo_left_burst_ms'],t['servo_right_burst_ms'])
        if t.get('servo_visual_config_supported'):
            values+=(int(t['servo_near_enabled']),t['servo_near_threshold_px'],t['servo_near_left_ms'],t['servo_near_right_ms'])
        return values

    def _config_input(self,t):
        values=tuple(int(v.get()) for v in self.servo_config_values)
        if t.get('servo_visual_config_supported'):
            values+=(int(self.servo_near_enabled.get()),)+tuple(int(v.get()) for v in self.servo_near_values)
        return values

    def _fill_servo_config(self,values):
        for var,value in zip(self.servo_config_values,values):var.set(str(value))
        if len(values)==8:
            self.servo_near_enabled.set(bool(values[4]))
            for var,value in zip(self.servo_near_values,values[5:]):var.set(str(value))

    def _default_servo_config(self):
        self._fill_servo_config((1650,1300,100,100,1,192,40,40))
        self.control_status.configure(text='已填入默认值；点击“应用参数”后以板端生效值为准。')

    def _read_servo_config(self):
        try:
            _,t,_=self.receiver.snapshots()
            if not self._config_ready(t):raise ValueError('参数状态过期或固件不支持')
            self._fill_servo_config(self._config_actual(t))
            self._config_pending=None
        except (ValueError,KeyError) as e:self.control_status.configure(text=str(e))

    def _update_servo_config(self,t):
        if t.get('servo_position_supported'):
            self.servo_debug_frame.pack_forget()
            return False
        if not self.servo_debug_frame.winfo_manager():
            self.servo_debug_frame.pack(anchor='w',fill='x',pady=(5,0))
        ready=self._config_ready(t)
        for field in self.servo_config_inputs:field.configure(state='normal' if ready else 'disabled')
        near_ready=ready and t.get('servo_visual_config_supported')
        for field in [self.servo_near_checkbox,*self.servo_near_inputs]:field.configure(state='normal' if near_ready else 'disabled')
        for index in (1,3):self.servo_config_inputs[index].configure(from_=t.get('servo_min_burst_ms',60))
        self.servo_config_read.configure(state='normal' if ready else 'disabled')
        self.servo_config_apply.configure(state='normal' if ready and not t.get('servo_busy') else 'disabled')
        dirty=False
        if ready:
            actual=self._config_actual(t)
            loaded_key=(t.get('boot_id'),bool(t.get('servo_visual_config_supported')))
            if self._config_loaded_boot!=loaded_key:
                self._fill_servo_config(actual);self._config_loaded_boot=loaded_key;self._config_pending=None
            try:dirty=self._config_input(t)!=actual
            except ValueError:dirty=True
            message=f'板端生效：左 {actual[0]} µs / {actual[2]} ms；右 {actual[1]} µs / {actual[3]} ms'
            if near_ready:
                message+=(f' · 分档开启：阈值{actual[5]}px，左近{actual[6]} / 右近{actual[7]}ms' if actual[4] else ' · 视觉分档关闭')
                band=t.get('servo_visual_last_band',0)
                if band:message+=f" · 上次水平视觉动作：{'近档' if band==1 else '远档'} {t.get('servo_last_burst_ms',0)}ms"
            if self._config_pending:
                values,sequence,sent_at=self._config_pending
                if actual==values and t['servo_config_sequence']!=sequence:self._config_pending=None
                elif (t.get('control_message','').startswith('应用左右PWM与时长') and
                      t.get('control_message','').partition(': ')[2] in ('拒绝','不支持')):
                    self._config_pending=None;message+=' · 板端拒绝，参数未应用'
                elif time.monotonic()-sent_at>4:
                    self._config_pending=None;message+=' · 应用未确认，请读取当前值'
                else:message+=' · 等待应用确认'
            if dirty:message+=' · 输入尚未应用'
            if not t.get('servo_pwm_calibrated'):message+=' · 新PWM尚未标定转速'
        else:message='参数调试不可用：等待新固件或恢复在线状态'
        self.servo_config_status.configure(text=message)
        for index,button in enumerate(self.servo_config_tests):
            enabled=ready and not dirty and not self._config_pending and not t.get('servo_busy') and not (t.get('servo_limits',0)&(1<<index))
            button.configure(state='normal' if enabled else 'disabled')
        return dirty if ready else False

    def _apply_servo_config(self):
        try:
            _,t,_=self.receiver.snapshots()
            if not self._config_ready(t):raise ValueError('参数状态过期或固件不支持，未发送')
            if t.get('servo_busy'):raise ValueError('请等待点动结束与冷却')
            values=self._config_input(t)
            if not (1500<values[0]<=2000 and 1000<=values[1]<1500):
                raise ValueError('左PWM范围1501–2000 µs，右PWM范围1000–1499 µs')
            minimum=t.get('servo_min_burst_ms',60)
            if any(v<minimum or v>300 or v%20 for v in values[2:4]):
                raise ValueError(f'持续时间须为{minimum}–300 ms，且是20 ms的整数倍')
            if values[:2]!=(1620,1330) and t.get('servo_pan_limit_enabled',True):
                raise ValueError('修改PWM前请先关闭左右软件限位；新PWM尚未标定转速')
            if len(values)==8:
                if not 60<=values[5]<=960:raise ValueError('水平阈值须为60–960原图像素')
                if any(v<20 or v>300 or v%20 for v in values[6:]):raise ValueError('近档时间须为20–300 ms且为20 ms的整数倍')
                if values[4] and (values[6]>values[2] or values[7]>values[3]):raise ValueError('近档时长不能大于对应远档时长')
                self.receiver.send_servo_visual_config(*values)
            else:self.receiver.send_servo_config(*values)
            self._config_pending=(values,t['servo_config_sequence'],time.monotonic())
            self._update_servo_config(t)
        except (ValueError,KeyError,RuntimeError,OSError) as e:self.control_status.configure(text=str(e))

    def _test_servo_config(self,direction):
        try:
            _,t,_=self.receiver.snapshots()
            if not self._config_ready(t):raise ValueError('参数状态过期，未试转')
            if self._config_input(t)!=self._config_actual(t) or self._config_pending:
                raise ValueError('请先应用参数并等待板端生效')
            if t.get('servo_busy') or t.get('servo_limits',0)&(1<<(direction-1)):
                raise ValueError('等待冷却或当前方向受限')
            self.receiver.send_control(13,direction,'左转测试' if direction==1 else '右转测试')
        except (ValueError,KeyError,RuntimeError,OSError) as e:self.control_status.configure(text=str(e))

    def _roi_start(self,event):
        if not self.select_roi.get() or self._video_image is None:return
        self.roi_start=(max(0,min(640,event.x)),max(0,min(360,event.y)))
        self.roi_box=None
        self.video_label.delete('selection')

    def _roi_drag(self,event):
        if self.roi_start is None:return
        x,y=self.roi_start;xx=max(0,min(640,event.x));yy=max(0,min(360,event.y))
        self.video_label.delete('selection')
        self.video_label.create_rectangle(x,y,xx,yy,outline='#ffcf33',width=2,tags='selection')

    def _roi_end(self,event):
        if self.roi_start is None:return
        x,y=self.roi_start;xx=max(0,min(640,event.x));yy=max(0,min(360,event.y))
        self._roi_drag(event);self.roi_start=None
        self.roi_box=tuple(3*v for v in (min(x,xx),min(y,yy),max(x,xx),max(y,yy)))
        self.roi_status.configure(text=f'待应用鸟框 {self.roi_box}；点击“同帧整图/鸟框对照”比较，黄框只是选区，不是SSD检测框。')

    def _servo_tilt(self,delta):
        try:
            _,t,_=self.receiver.snapshots()
            if not t.get('online') or t.get('telemetry_age_s',float('inf'))>1 or not t.get('servo_supported'):
                raise ValueError('云台状态过期')
            pulse=max(540,min(2281,int(t['servo_tilt_us'])+delta))
            self.receiver.send_servo_tilt(pulse)
        except (ValueError,RuntimeError,OSError) as exc:self.control_status.configure(text=str(exc))

    def _manual_focus(self,delta=0):
        try:
            _,t,_=self.receiver.snapshots()
            if not t.get('online') or t.get('telemetry_age_s',float('inf'))>1 or not t.get('manual_focus_supported'):
                raise ValueError('未连接支持手动调焦的新固件，未发送')
            position=int(self.manual_focus_value.get())+delta
            if not 0<=position<=1023:raise ValueError('镜头码值范围0–1023，未发送')
            self.receiver.send_manual_focus(position)
            self.manual_focus_value.set(str(position))
        except (OSError,RuntimeError,ValueError) as e:self.control_status.configure(text=str(e))

    def _image_policy(self,policy):
        try:
            if policy>=2 and self.roi_box is None:raise ValueError('请先勾选框选鸟，并拖动框住完整鸟身')
            self.receiver.send_image_policy(policy,self.roi_box if policy>=2 else None)
            if policy>=2:self.receiver.send_control(11,0,'手动诊断：关闭自动放大/对焦')
            self.roi_status.configure(text='裁剪设置已发送；以板端确认和下一次结果中的“分类输入”为准。'+
                                      ('手动模式切换为独立视觉；手机/鸟移动后需重新框选。' if policy>=2 else ''))
        except (OSError,RuntimeError,ValueError) as e:self.roi_status.configure(text=str(e))

    def _save_frame(self):
        try:
            path=self.receiver.save_frame(Path(__file__).resolve().parents[3]/'captures')
            self.result_detail.configure(text=f'已保存 {path}')
        except (OSError,RuntimeError) as e:self.result_detail.configure(text=str(e))

    def _draw_compass(self, angle_deg: float, confidence: float, valid: bool,
                      reason: str = '未确认鸟声 / 暂无有效方位') -> None:
        c = self.compass
        c.delete("all")
        cx, cy, radius = 130, 85, 65
        c.create_oval(cx-radius, cy-radius, cx+radius, cy+radius, outline="#8aa4b8", width=2)
        for text, x, y in (("前", cx, cy-radius-12), ("后", cx, cy+radius+12),
                           ("左", cx-radius-14, cy), ("右", cx+radius+14, cy)):
            c.create_text(x, y, text=text, fill="white")
        if valid:
            rad = math.radians(angle_deg - 90.0)
            x, y = cx + radius * 0.85 * math.cos(rad), cy + radius * 0.85 * math.sin(rad)
            c.create_line(cx, cy, x, y, fill="#32d17d", width=5, arrow=tk.LAST)
        c.create_text(cx, 168, text=(f"{angle_deg:.1f}°  定位质量 {confidence:.2f}" if valid else
                      reason), fill="white")

    def _open_scan_preview_tuning(self):
        if self._scan_preview_tuning_window is not None:
            self._scan_preview_tuning_window.lift()
            return
        window=tk.Toplevel(self.root)
        window.title('扫描与预览 · 在线调参')
        self._scan_preview_tuning_window=window
        self._scan_preview_tuning_panel=ScanPreviewTuningPanel(window,self.receiver)
        self._scan_preview_tuning_panel.update(self._last_telemetry)
        window.protocol('WM_DELETE_WINDOW',self._close_scan_preview_tuning)

    def _close_scan_preview_tuning(self):
        window=self._scan_preview_tuning_window
        self._scan_preview_tuning_window=None;self._scan_preview_tuning_panel=None
        if window is not None:window.destroy()

    def _open_audio_tuning(self):
        if self._audio_tuning_window is not None:
            self._audio_tuning_window.lift()
            return
        window=tk.Toplevel(self.root)
        window.title('听觉定位与寻向 · 在线调参')
        self._audio_tuning_window=window
        self._audio_tuning_panel=AudioTuningPanel(window,self.receiver)
        self._audio_tuning_panel.update(self._last_telemetry)
        window.protocol('WM_DELETE_WINDOW',self._close_audio_tuning)

    def _close_audio_tuning(self):
        window=self._audio_tuning_window
        self._audio_tuning_window=None;self._audio_tuning_panel=None
        if window is not None:window.destroy()

    def _open_visual_tuning(self):
        if self._visual_tuning_window is not None:
            self._visual_tuning_window.lift()
            return
        window=tk.Toplevel(self.root)
        window.title('视觉连续追踪 · 在线调参')
        self._visual_tuning_window=window
        self._visual_tuning_panel=VisualTuningPanel(window,self.receiver)
        self._visual_tuning_panel.update(self._last_telemetry)
        window.protocol('WM_DELETE_WINDOW',self._close_visual_tuning)

    def _close_visual_tuning(self):
        window=self._visual_tuning_window
        self._visual_tuning_window=None;self._visual_tuning_panel=None
        if window is not None:window.destroy()

    def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        self._close_scan_preview_tuning()
        self._close_audio_tuning()
        self._close_visual_tuning()
        if not self._sd_attach:
            try:
                _,t,_=self.receiver.snapshots()
                if t.get('online') and t.get('servo_supported'):
                    self.receiver.send_control(13,0,'关闭窗口：停止云台')
            except (RuntimeError,OSError):pass
        self.receiver.stop()
        self.root.destroy()
