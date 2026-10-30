"""Modeless audio tuning panel; construction/edit/read/default actions never write."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from .audio_tuning import (DEFAULTS, NAMES, display_values, draft_values,
                           feedback_text, value_bytes)
from .audio_round_panel import AudioRoundPanel


ROWS = (
    ("% · 整数 1～99", "鸟声置信度须严格大于此值；默认 80%"),
    ("倍 · 2～16", "能量相对已学习底噪的最低倍数；越大越严格"),
    ("Q15 · 整数 513～16384", "四麦定位质量下限；越大越严格"),
    ("° · 2～30", "稳定方向窗口允许的角度波动；越小越严格"),
    ("ms · 整数 300～1500", "首次寻向前的方向稳定时长"),
    ("ms · 整数 600～1500", "已有方位后的重定向稳定时长；不得小于首次值"),
    ("° · 3～45", "新方位与已接受方位的最小差值"),
    ("°/s · 5～120", "水平位置指令变化率上限；并非实测机械速度"),
)


class AudioTuningPanel:
    def __init__(self, parent, receiver):
        self.receiver = receiver
        self.notebook = ttk.Notebook(parent)
        self.notebook.pack(fill="both", expand=True)
        self.frame = ttk.Frame(self.notebook, padding=12)
        self.frame.pack(fill="both", expand=True)
        self.notebook.add(self.frame, text="定位与寻向")
        self.round_panel = AudioRoundPanel(self.notebook, receiver)
        self.notebook.add(self.round_panel.frame, text="采样与确认时序")
        self._loading = False
        self._dirty = False
        self._last_key = None
        self._last = {}
        self._local_error = ""
        ttk.Label(self.frame, text="听觉定位与寻向在线调参",
                  font=("Microsoft YaHei UI", 13, "bold")).grid(
                      row=0, column=0, columnspan=4, sticky="w")
        ttk.Label(self.frame, text="修改后点击“应用整组参数”，8 项一次发送并核对板端回读；输入过程不发送。",
                  wraplength=950).grid(row=1, column=0, columnspan=4, sticky="w", pady=6)
        for column, title in enumerate(("参数", "待应用值", "单位与范围", "作用")):
            ttk.Label(self.frame, text=title).grid(row=2, column=column, sticky="w", padx=8, pady=4)
        self.variables = [tk.StringVar(value=value) for value in display_values(DEFAULTS)]
        self.fields = []
        for index, (name, (unit, hint)) in enumerate(zip(NAMES, ROWS)):
            row = index + 3
            ttk.Label(self.frame, text=name).grid(row=row, column=0, sticky="w", padx=8, pady=4)
            field = ttk.Entry(self.frame, width=12, textvariable=self.variables[index])
            field.grid(row=row, column=1, padx=8, pady=4)
            self.fields.append(field)
            ttk.Label(self.frame, text=unit).grid(row=row, column=2, sticky="w", padx=8)
            ttk.Label(self.frame, text=hint, wraplength=410).grid(row=row, column=3, sticky="w", padx=8)
        for variable in self.variables:
            variable.trace_add("write", self._draft_changed)
        actions = ttk.Frame(self.frame)
        actions.grid(row=11, column=0, columnspan=4, sticky="w", pady=8)
        self.apply_button = ttk.Button(actions, text="应用整组参数", command=self._apply)
        self.apply_button.pack(side="left", padx=4)
        self.read_button = ttk.Button(actions, text="读取当前", command=self._read)
        self.read_button.pack(side="left", padx=4)
        self.resync_button = ttk.Button(actions, text="重新同步（只读）", command=self._resync)
        self.resync_button.pack(side="left", padx=4)
        ttk.Button(actions, text="填入默认值（待应用）", command=self._defaults).pack(side="left", padx=4)
        self.actual = ttk.Label(self.frame, text="板端当前值：等待回读", justify="left", wraplength=980)
        self.actual.grid(row=12, column=0, columnspan=4, sticky="w", pady=5)
        self.status = ttk.Label(self.frame, text="", justify="left", wraplength=980)
        self.status.grid(row=13, column=0, columnspan=4, sticky="w", pady=5)
        self.feedback = ttk.Label(self.frame, text="", justify="left", wraplength=980)
        self.feedback.grid(row=14, column=0, columnspan=4, sticky="w", pady=5)
        self.direction = ttk.Label(self.frame, text="定位方位：等待新鲜门控后定位结果", justify="left", wraplength=980)
        self.direction.grid(row=15, column=0, columnspan=4, sticky="w", pady=5)
        ttk.Label(self.frame, justify="left", wraplength=980,
                  text=("建议先观察能量、质量与方向稳定性，再调整门槛或寻向变化率；数值越灵敏越容易受噪声影响。\n"
                        "麦阵固定在底座，方位使用基座绝对方向。四麦健康检查、至少 6 个样本、75% 方向共识、"
                        "鸟种一致性和视觉优先规则仍保留。\n"
                        "参数只保存在板端内存（RAM），重启恢复固件默认值。应用会清除待确认的旧声音证据；"
                        "应用本身不启动寻向、不发送舵机动作，也不切换模式。" )).grid(
                            row=16, column=0, columnspan=4, sticky="w", pady=8)
        self.update({})

    def _draft_changed(self, *_):
        if not self._loading:
            self._dirty = True
            self._local_error = ""

    def _fill(self, values):
        self._loading = True
        try:
            for variable, value in zip(self.variables, display_values(values)):
                variable.set(value)
        finally:
            self._loading = False

    def _values(self):
        return draft_values(tuple(variable.get() for variable in self.variables))

    def _defaults(self):
        self._fill(DEFAULTS)
        self._dirty = True
        self._local_error = ""
        self.update(self._last)

    def _read(self):
        try:
            self._fill(self.receiver.read_audio_tuning())
            self._dirty = False
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def _apply(self):
        try:
            self.receiver.send_audio_tuning(self._values())
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def _resync(self):
        try:
            self.receiver.resync_audio_tuning()
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def update_direction(self, direction, valid, reason):
        # Reuse the main window's existing <=10 Hz feature snapshot, without
        # requesting any additional image processing or network publication.
        if valid and direction.valid:
            self.direction.configure(text=(
                f"门控后定位：基座方位 {direction.angle_deg:+.1f}° · "
                f"质量 {round(direction.confidence*32767)} Q15 · 定位龄期 {direction.age_ms:.0f} ms。"
                "定位质量是相关性指标，与鸟声分类置信度不同。"))
        else:
            self.direction.configure(text="当前无新鲜有效定位方位："+(reason or "等待声音或定位恢复"))

    def update(self, telemetry):
        self.round_panel.update(telemetry)
        self._last = telemetry
        tuning = telemetry.get("audio_tuning", {})
        ready = bool(tuning.get("ready"))
        actual = tuning.get("values")
        key = (tuning.get("boot_id"), tuning.get("revision"))
        if ready and actual and key != self._last_key and not self._dirty:
            self._fill(actual)
        valid = False
        if actual:
            try:
                values = self._values()
                self._dirty = value_bytes(values) != value_bytes(actual)
                valid = True
            except ValueError:
                self._dirty = True
        self._last_key = key
        for field in self.fields:
            field.configure(state="normal" if ready else "disabled")
        self.read_button.configure(state="normal" if ready else "disabled")
        self.resync_button.configure(state="normal" if tuning.get("control_open") else "disabled")
        self.apply_button.configure(state="normal" if
                                    ready and valid and self._dirty and not tuning.get("pending")
                                    else "disabled")
        if actual:
            shown = display_values(actual)
            prefix = "板端当前值" if ready else "上次回读值（当前不可应用）"
            self.actual.configure(text=(
                f"{prefix} · 修订 {tuning.get('revision')} · 累计应用 {tuning.get('apply_count', 0)} 次\n"
                f"鸟声门槛 >{shown[0]}% · 能量/底噪 {shown[1]} 倍 · 定位质量 ≥{shown[2]} Q15 · "
                f"方向抖动 {shown[3]}°\n"
                f"首次稳定 {shown[4]} ms · 重定向稳定 {shown[5]} ms · 最小角差 {shown[6]}° · "
                f"指令变化率 {shown[7]}°/s"))
        else:
            self.actual.configure(text="板端当前值：等待支持 M43 的完整声音参数回读")
        message = self._local_error or tuning.get("message", "等待板端参数状态")
        if self._dirty:
            message += "\n输入框包含未应用的修改，板端当前值以上方回读为准。"
        self.status.configure(text=message)
        self.feedback.configure(text=feedback_text(telemetry.get("audio_tuning_feedback", {}), tuning))
