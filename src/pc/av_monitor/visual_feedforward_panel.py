"""Independent feedforward drafts; only explicit atomic Apply writes settings."""
from __future__ import annotations

from decimal import Decimal, InvalidOperation
import tkinter as tk
from tkinter import ttk

from .visual_feedforward import (BOUNDS, DEFAULTS, NAMES, RESET_NAMES,
                                  display_values, draft_values, value_bytes)

STEPS = (1., 1., .05, .05, 1., 1., 10., .1)
ROWS = (
    ("0～360 °/整幅水平归一化位移", "水平云台指令角度换算；0 表示未设置，该轴前馈关闭"),
    ("0～180 °/整幅竖直归一化位移", "竖直舵机指令角度换算；0 表示未设置，该轴前馈关闭"),
    ("0～1 · 无量纲", "水平目标运动补偿比例；0 关闭水平前馈"),
    ("0～1 · 无量纲", "竖直目标运动补偿比例；0 关闭竖直前馈"),
    ("0～60 °/s · 指令", "限制水平前馈分量；最终仍受原水平总变化率上限限制"),
    ("0～60 °/s · 指令", "限制竖直前馈分量；最终仍受原竖直总变化率上限限制"),
    ("20～1000 ms", "目标速度估计的平滑时间；越大越平滑，响应越慢"),
    ("0～10 °/s · 估计", "小于此值的估计目标运动不进入前馈"),
)


class VisualFeedforwardPanel:
    def __init__(self, parent, receiver):
        self.receiver = receiver
        self.frame = ttk.Frame(parent, padding=12)
        self.frame.pack(fill="both", expand=True)
        self._loading = False
        self._dirty = False
        self._last_key = None
        self._last = {}
        self._local_error = ""
        ttk.Label(self.frame, text="视觉目标运动前馈", font=("Microsoft YaHei UI", 13, "bold")).grid(
            row=0, column=0, columnspan=4, sticky="w")
        ttk.Label(self.frame, text="± 仅修改草稿；点击“应用整组前馈”才发送 8 项参数。默认水平换算系数 0（前馈关闭），竖直换算系数 55。",
                  wraplength=1020).grid(row=1, column=0, columnspan=4, sticky="w", pady=5)
        for column, title in enumerate(("参数", "待应用值", "单位与范围", "作用")):
            ttk.Label(self.frame, text=title).grid(row=2, column=column, sticky="w", padx=7, pady=4)
        self.variables = [tk.StringVar(value=value) for value in display_values(DEFAULTS)]
        self.fields = []
        self.step_buttons = []
        for index, (name, (unit, hint)) in enumerate(zip(NAMES, ROWS)):
            row = index+3
            ttk.Label(self.frame, text=name).grid(row=row, column=0, sticky="w", padx=7, pady=4)
            editor = ttk.Frame(self.frame)
            editor.grid(row=row, column=1, padx=7, pady=4)
            minus = ttk.Button(editor, text="−", width=2, command=lambda i=index:self._step(i,-1))
            minus.pack(side="left")
            field = ttk.Spinbox(editor, width=10, from_=BOUNDS[index][0], to=BOUNDS[index][1],
                                increment=STEPS[index], textvariable=self.variables[index])
            field.pack(side="left", padx=3)
            plus = ttk.Button(editor, text="+", width=2, command=lambda i=index:self._step(i,1))
            plus.pack(side="left")
            self.fields.append(field)
            self.step_buttons.extend((minus, plus))
            ttk.Label(self.frame, text=unit).grid(row=row, column=2, sticky="w", padx=7)
            ttk.Label(self.frame, text=hint, wraplength=370).grid(row=row, column=3, sticky="w", padx=7)
        actions = ttk.Frame(self.frame)
        actions.grid(row=11, column=0, columnspan=4, sticky="w", pady=7)
        self.apply_button = ttk.Button(actions, text="应用整组前馈", command=self._apply)
        self.apply_button.pack(side="left", padx=3)
        self.read_button = ttk.Button(actions, text="读取当前", command=self._read)
        self.read_button.pack(side="left", padx=3)
        self.resync_button = ttk.Button(actions, text="重新同步（只读）", command=self._resync)
        self.resync_button.pack(side="left", padx=3)
        ttk.Button(actions, text="填入默认值（待应用）", command=self._defaults).pack(side="left", padx=3)
        ttk.Button(actions, text="关闭前馈（待应用）", command=self._disable).pack(side="left", padx=3)
        self.calibration = ttk.Label(self.frame, text="", justify="left", wraplength=1020)
        self.calibration.grid(row=12, column=0, columnspan=4, sticky="w", pady=4)
        self.actual = ttk.Label(self.frame, text="板端前馈参数：等待回读", justify="left", wraplength=1020)
        self.actual.grid(row=13, column=0, columnspan=4, sticky="w", pady=4)
        self.status = ttk.Label(self.frame, text="", justify="left", wraplength=1020)
        self.status.grid(row=14, column=0, columnspan=4, sticky="w", pady=4)
        self.feedback = ttk.Label(self.frame, text="", justify="left", wraplength=1020)
        self.feedback.grid(row=15, column=0, columnspan=4, sticky="w", pady=4)
        ttk.Label(self.frame, justify="left", wraplength=1020,
                  text=("换算系数是在线可调的软件换算参数，不代表已完成光学标定。速度估计使用目标图像位移与已接受位置指令历史，"
                        "无编码器，不能当作实测角度或实测速度反馈。\n"
                        "前馈需连续新鲜正式 NCC 观测确认；反向、丢失或跳变时重置。150 ms 后衰减，250 ms 归零。"
                        "本页参数只存 RAM，应用不启动自动模式、不发送舵机动作，也不续期控制租约。" )).grid(
                            row=16, column=0, columnspan=4, sticky="w", pady=5)
        for variable in self.variables:
            variable.trace_add("write", self._draft_changed)
        self.update({})

    def _draft_changed(self, *_):
        if not self._loading:
            self._dirty = True
            self._local_error = ""
            self.update(self._last)

    def _fill(self, values):
        self._loading = True
        try:
            for variable, value in zip(self.variables, display_values(values)):
                variable.set(value)
        finally:
            self._loading = False

    def _values(self):
        return draft_values(tuple(variable.get() for variable in self.variables))

    def _step(self, index, direction):
        try:
            value = Decimal(self.variables[index].get())
            if not value.is_finite():
                raise ValueError("参数须为有限数字")
            low, high = (Decimal(str(bound)) for bound in BOUNDS[index])
            value = max(low,min(high,value+Decimal(str(STEPS[index]))*direction))
            self.variables[index].set(format(value,"f").rstrip("0").rstrip(".") if value % 1 else str(int(value)))
        except (InvalidOperation, ValueError) as exc:
            self._local_error = str(exc) or "请先填写有效数字"
        self.update(self._last)

    def _defaults(self):
        self._fill(DEFAULTS)
        self._dirty = True
        self._local_error = ""
        self.update(self._last)

    def _disable(self):
        self.variables[2].set("0")
        self.variables[3].set("0")
        self._dirty = True
        self._local_error = ""
        self.update(self._last)

    def _read(self):
        try:
            self._fill(self.receiver.read_visual_feedforward())
            self._dirty = False
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)
        self.update(self._last)

    def _apply(self):
        try:
            self.receiver.send_visual_feedforward(self._values())
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def _resync(self):
        try:
            self.receiver.resync_visual_feedforward()
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)
        self.update(self._last)

    def update(self, telemetry):
        self._last = telemetry
        tuning = telemetry.get("visual_feedforward", {})
        ready = bool(tuning.get("ready"))
        actual = tuning.get("values")
        key = (tuning.get("boot_id"), tuning.get("revision"))
        if ready and actual and key != self._last_key and not self._dirty:
            self._fill(actual)
        valid = False
        try:
            values = self._values()
            valid = True
            if actual:
                self._dirty = value_bytes(values) != value_bytes(actual)
        except ValueError:
            self._dirty = True
        self._last_key = key
        for field in (*self.fields, *self.step_buttons):
            field.configure(state="normal" if ready else "disabled")
        self.read_button.configure(state="normal" if ready else "disabled")
        self.resync_button.configure(state="normal" if tuning.get("control_open") else "disabled")
        self.apply_button.configure(state="normal" if ready and valid and self._dirty and not tuning.get("pending") else "disabled")
        if actual:
            shown = display_values(actual)
            axes = []
            for index, axis in enumerate(("水平", "竖直")):
                axes.append(axis+("需设置换算系数，前馈关闭" if actual[index] == 0 else
                                  f"换算系数 {shown[index]}°/整幅归一化位移"))
            self.calibration.configure(text="板端换算设置："+"；".join(axes)+"（软件换算参数）")
            prefix = "板端当前前馈" if ready else "上次前馈回读（当前不可应用）"
            self.actual.configure(text=(f"{prefix} · 独立修订 {tuning.get('revision')} · 累计应用 {tuning.get('apply_count',0)} 次\n"
                f"水平：换算 {shown[0]}，增益 {shown[2]}，前馈上限 {shown[4]}°/s；"
                f"竖直：换算 {shown[1]}，增益 {shown[3]}，前馈上限 {shown[5]}°/s\n"
                f"滤波时间常数 {shown[6]} ms · 速度死区 {shown[7]}°/s；增益或前馈上限为 0 时该轴关闭。"))
            age = tuning.get("observation_age_ms", 0xffffffff)
            age_text = "无可用观测" if age == 0xffffffff else f"{age} ms"
            flags = tuning.get("flags", 0)
            reset = tuning.get("reset_reason", 0)
            self.feedback.configure(text=(
                f"软件估计回读（{'状态新鲜' if ready else '状态过期'}）：目标水平 {tuning.get('pan_velocity',0):+.2f}°/s / 竖直 {tuning.get('tilt_velocity',0):+.2f}°/s；观测龄期 {age_text}\n"
                f"前馈指令分量：水平 {tuning.get('pan_ff',0):+.2f}°/s / 竖直 {tuning.get('tilt_ff',0):+.2f}°/s；"
                f"方向确认 {'是' if flags&4 else '否'} / {'是' if flags&8 else '否'}，有效间隔 {tuning.get('pan_pairs',0)} / {tuning.get('tilt_pairs',0)}\n"
                f"P 指令 {tuning.get('pan_p_rate',0):+.2f} / {tuning.get('tilt_p_rate',0):+.2f}°/s；"
                f"限幅后总指令 {tuning.get('pan_total_rate',0):+.2f} / {tuning.get('tilt_total_rate',0):+.2f}°/s；"
                f"帧 {tuning.get('source_sequence','—')}，重置：{RESET_NAMES[reset]}。无编码器反馈。"))
        else:
            self.calibration.configure(text="默认换算系数：水平 0（前馈关闭）、竖直 55；等待板端完整参数回读。")
            self.actual.configure(text="板端前馈参数：等待支持 M47 的完整参数回读")
            self.feedback.configure(text="等待目标速度估计与前馈指令回读；无编码器反馈。")
        message = self._local_error or tuning.get("message", "等待板端前馈状态")
        if self._dirty:
            message += "\n输入框包含未应用的修改，板端当前参数以上方回读为准。"
        self.status.configure(text=message)
