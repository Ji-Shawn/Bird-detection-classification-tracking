"""Modeless scan / network preview tuning; only explicit Apply sends a write."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from .scan_preview_tuning import DEFAULTS, NAMES, display_values, draft_values, value_bytes


class ScanPreviewTuningPanel:
    def __init__(self, parent, receiver):
        self.receiver = receiver
        self.frame = ttk.Frame(parent, padding=12)
        self.frame.pack(fill="both", expand=True)
        self._loading = self._dirty = False
        self._last_key = None
        self._last = {}
        self._local_error = ""
        ttk.Label(self.frame, text="扫描与预览在线调参",
                  font=("Microsoft YaHei UI", 13, "bold")).grid(
                      row=0, column=0, columnspan=4, sticky="w")
        ttk.Label(self.frame, text="修改后点击“应用整组参数”，2 项一起发送；输入过程不发送。",
                  wraplength=830).grid(row=1, column=0, columnspan=4, sticky="w", pady=6)
        for column, title in enumerate(("参数", "待应用值", "单位与范围", "作用")):
            ttk.Label(self.frame, text=title).grid(row=2, column=column, sticky="w", padx=8, pady=4)
        self.variables = [tk.StringVar(value=value) for value in display_values(DEFAULTS)]
        self.fields = []
        rows = (("°/s · 0.5～10", "越大上下扫描越快；默认 4"),
                ("FPS · 1～4，可填小数", "板端向上位机发布图像的频率上限；默认 2.5"))
        for index, (name, (unit, hint)) in enumerate(zip(NAMES, rows)):
            row = index + 3
            ttk.Label(self.frame, text=name).grid(row=row, column=0, sticky="w", padx=8, pady=6)
            field = ttk.Entry(self.frame, width=12, textvariable=self.variables[index])
            field.grid(row=row, column=1, padx=8, pady=6)
            self.fields.append(field)
            ttk.Label(self.frame, text=unit).grid(row=row, column=2, sticky="w", padx=8)
            ttk.Label(self.frame, text=hint, wraplength=310).grid(row=row, column=3, sticky="w", padx=8)
        for variable in self.variables:
            variable.trace_add("write", self._draft_changed)
        actions = ttk.Frame(self.frame)
        actions.grid(row=5, column=0, columnspan=4, sticky="w", pady=8)
        self.apply_button = ttk.Button(actions, text="应用整组参数", command=self._apply)
        self.apply_button.pack(side="left", padx=4)
        self.read_button = ttk.Button(actions, text="读取当前", command=self._read)
        self.read_button.pack(side="left", padx=4)
        self.resync_button = ttk.Button(actions, text="重新同步（只读）", command=self._resync)
        self.resync_button.pack(side="left", padx=4)
        ttk.Button(actions, text="填入默认值（待应用）", command=self._defaults).pack(side="left", padx=4)
        self.actual = ttk.Label(self.frame, text="板端当前值：等待回读", justify="left", wraplength=830)
        self.actual.grid(row=6, column=0, columnspan=4, sticky="w", pady=5)
        self.status = ttk.Label(self.frame, text="", justify="left", wraplength=830)
        self.status.grid(row=7, column=0, columnspan=4, sticky="w", pady=5)
        self.feedback = ttk.Label(self.frame, text="", justify="left", wraplength=830)
        self.feedback.grid(row=8, column=0, columnspan=4, sticky="w", pady=5)
        ttk.Label(self.frame, justify="left", wraplength=830, text=(
            "扫描速度是竖直位置指令的变化率；无编码器，不代表实测机械速度。扫描范围仍为 0°～100°。\n"
            "网络预览上限控制画面接收频率；实际接收 FPS 还受处理耗时与网络影响。"
            "摄像头采集、HDMI 显示、NCC 和识别使用的完整图像不受此参数影响。\n"
            "参数仅保存在板端 RAM，重启恢复默认值。应用参数不会启动扫描或追踪，不发送单独舵机动作。"
        )).grid(row=9, column=0, columnspan=4, sticky="w", pady=8)
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
            self._fill(self.receiver.read_scan_preview_tuning())
            self._dirty = False
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def _apply(self):
        try:
            self.receiver.send_scan_preview_tuning(self._values())
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def _resync(self):
        try:
            self.receiver.resync_scan_preview_tuning()
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def update(self, telemetry):
        self._last = telemetry
        tuning = telemetry.get("scan_preview_tuning", {})
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
                f"扫描指令变化率 {shown[0]}°/s · 网络预览上限 {shown[1]} FPS\n"
                f"板端扫描调度：每步 {tuning.get('scan_step_us', '—')} μs，"
                f"节拍 {tuning.get('scan_interval_us', 0)/1000:g} ms；"
                f"预览发布间隔至少 {tuning.get('preview_interval_us', 0)/1000:g} ms。"))
        else:
            self.actual.configure(text="板端当前值：等待支持扫描与预览调参的完整回读")
        message = self._local_error or tuning.get("message", "等待板端参数状态")
        if self._dirty:
            message += "\n输入框包含未应用的修改，板端当前值以上方回读为准。"
        self.status.configure(text=message)
        self.feedback.configure(text=(
            f"实际完整画面接收：{telemetry.get('received_fps', 0):.1f} FPS"
            f"（最近 3 秒） · 组帧超时：{telemetry.get('video_assembly_loss', 0)}。"))
