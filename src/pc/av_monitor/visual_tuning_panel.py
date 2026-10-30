"""Modeless online-tuning panel. Creating/opening it never sends a command."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from .visual_tuning import (DEFAULTS, display_values, draft_values,
                            feedback_text, value_bytes)
from .visual_feedforward_panel import VisualFeedforwardPanel


class VisualTuningPanel:
    def __init__(self, parent, receiver):
        self.receiver = receiver
        self.notebook = ttk.Notebook(parent)
        self.notebook.pack(fill="both", expand=True)
        self.frame = ttk.Frame(self.notebook, padding=12)
        self.frame.pack(fill="both", expand=True)
        self.notebook.add(self.frame, text="比例与死区")
        self.feedforward_panel = VisualFeedforwardPanel(self.notebook, receiver)
        self.notebook.add(self.feedforward_panel.frame, text="运动前馈")
        self._loading = False
        self._dirty = False
        self._loaded = False
        self._last_key = None
        self._last = {}
        self._local_error = ""
        ttk.Label(self.frame, text="视觉连续追踪在线调参",
                  font=("Microsoft YaHei UI", 13, "bold")).grid(
                      row=0, column=0, columnspan=5, sticky="w")
        ttk.Label(self.frame, text="修改输入后点击“应用整组参数”，两轴 8 项同时发送；输入过程不发送。",
                  wraplength=850).grid(row=1, column=0, columnspan=5, sticky="w", pady=6)
        for col, title in enumerate(("轴向", "比例增益 Kp", "最大指令变化率（°/s）",
                                     "进入死区（%）", "退出死区（%）")):
            ttk.Label(self.frame, text=title).grid(row=2, column=col, padx=8, pady=5)
        self.variables = [tk.StringVar(value=value) for value in display_values(DEFAULTS)]
        self.fields = []
        for row, (axis, indices) in enumerate(
                (("水平云台", (0, 2, 4, 5)), ("竖直舵机", (1, 3, 6, 7))), 3):
            ttk.Label(self.frame, text=axis).grid(row=row, column=0, sticky="w", padx=8)
            for col, index in enumerate(indices, 1):
                field = ttk.Entry(self.frame, width=15, textvariable=self.variables[index])
                field.grid(row=row, column=col, padx=8, pady=5)
                self.fields.append(field)
        for variable in self.variables:
            variable.trace_add("write", self._draft_changed)
        actions = ttk.Frame(self.frame)
        actions.grid(row=5, column=0, columnspan=5, sticky="w", pady=8)
        self.apply_button = ttk.Button(actions, text="应用整组参数", command=self._apply)
        self.apply_button.pack(side="left", padx=4)
        self.read_button = ttk.Button(actions, text="读取当前", command=self._read)
        self.read_button.pack(side="left", padx=4)
        self.resync_button = ttk.Button(actions, text="重新同步（只读）", command=self._resync)
        self.resync_button.pack(side="left", padx=4)
        ttk.Button(actions, text="填入默认值（待应用）", command=self._defaults).pack(side="left", padx=4)
        self.actual = ttk.Label(self.frame, text="板端当前值：等待回读", justify="left",
                                wraplength=880)
        self.actual.grid(row=6, column=0, columnspan=5, sticky="w", pady=5)
        self.status = ttk.Label(self.frame, text="", justify="left", wraplength=880)
        self.status.grid(row=7, column=0, columnspan=5, sticky="w", pady=5)
        self.feedback = ttk.Label(self.frame, text="", justify="left", wraplength=880)
        self.feedback.grid(row=8, column=0, columnspan=5, sticky="w", pady=5)
        ttk.Label(self.frame, justify="left", wraplength=880,
                  text=("Kp 单位：°/s ÷ 归一化画面偏差；死区按整幅图像的宽度或高度计算。"
                        "范围：Kp 1～240，指令变化率 1～60°/s，进入死区 0.5～15%，"
                        "退出死区 1～20%；每轴进入值须小于退出值。\n"
                        "仅调节正式 NCC 连续追踪，不改变 SSD 门槛、声音寻向、扫描范围或标定。"
                        "应用参数不启动追踪，也不发送单独的舵机动作。\n"
                        "参数仅保存在板端 RAM，重启恢复固件默认值。变化率是指令上限，"
                        "并非实测机械速度；没有编码器反馈。")).grid(
                            row=9, column=0, columnspan=5, sticky="w", pady=8)
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
        self._loaded = True

    def _values(self):
        return draft_values(tuple(variable.get() for variable in self.variables))

    def _defaults(self):
        self._fill(DEFAULTS)
        self._dirty = True
        self._local_error = ""
        self.update(self._last)

    def _read(self):
        try:
            values = self.receiver.read_visual_tuning()
            self._fill(values)
            self._dirty = False
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def _apply(self):
        try:
            values = self._values()
            self.receiver.send_visual_tuning(values)
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def _resync(self):
        try:
            self.receiver.resync_visual_tuning()
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def update(self, telemetry):
        self.feedforward_panel.update(telemetry)
        self._last = telemetry
        tuning = telemetry.get("visual_tuning", {})
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
            self.actual.configure(
                text=(f"{prefix} · 修订 {tuning.get('revision')} · "
                      f"累计应用 {tuning.get('apply_count',0)} 次\n"
                      f"水平：Kp {shown[0]}，变化率 {shown[2]}°/s，"
                      f"死区 {shown[4]}% / {shown[5]}%\n"
                      f"竖直：Kp {shown[1]}，变化率 {shown[3]}°/s，"
                      f"死区 {shown[6]}% / {shown[7]}%"))
        else:
            self.actual.configure(text="板端当前值：等待支持 M39 的完整参数回读")
        message = self._local_error or tuning.get("message", "等待板端参数状态")
        if self._dirty:
            message += "\n输入框包含未应用的修改，板端当前值以上方回读为准。"
        self.status.configure(text=message)
        self.feedback.configure(text=feedback_text(telemetry.get("visual_tuning_feedback", {}), tuning))

