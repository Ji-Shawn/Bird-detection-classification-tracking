"""Four timing drafts in seconds; only the explicit Apply action writes."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from .audio_round_tuning import BOUNDS, DEFAULTS, NAMES, display_values, draft_values

ROWS = (
    ("1～5 秒", "本轮有效采音；不足模型固定 5 秒的部分在尾部补静音"),
    ("1～10 秒", "相邻声音轮次结束的最小间隔；不得小于有效采样时长"),
    ("2～30 秒", "声音轮次超过此间隔后重置；须严格大于最小结束间隔"),
    ("0～30 秒", "接受声音定位方位后暂停采样；0 表示不额外等待"),
)


class AudioRoundPanel:
    def __init__(self, parent, receiver):
        self.receiver = receiver
        self.frame = ttk.Frame(parent, padding=12)
        self.frame.pack(fill="both", expand=True)
        self._loading = False
        self._dirty = False
        self._last_key = None
        self._last = {}
        self._local_error = ""
        ttk.Label(self.frame, text="采样与确认时序", font=("Microsoft YaHei UI", 13, "bold")).grid(
            row=0, column=0, columnspan=4, sticky="w")
        ttk.Label(self.frame, text="以秒填写，支持 ± 按钮；最多 3 位小数（1 ms）。修改草稿不发送。",
                  wraplength=930).grid(row=1, column=0, columnspan=4, sticky="w", pady=6)
        for column, title in enumerate(("参数", "待应用秒数", "范围", "作用")):
            ttk.Label(self.frame, text=title).grid(row=2, column=column, sticky="w", padx=8, pady=4)
        self.variables = [tk.StringVar(value=value) for value in display_values(DEFAULTS)]
        self.fields = []
        for index, (name, bounds, (unit, hint)) in enumerate(zip(NAMES, BOUNDS, ROWS)):
            row = index + 3
            ttk.Label(self.frame, text=name).grid(row=row, column=0, sticky="w", padx=8, pady=6)
            field = ttk.Spinbox(self.frame, width=12, from_=bounds[0]/1000, to=bounds[1]/1000,
                                increment=.1, textvariable=self.variables[index])
            field.grid(row=row, column=1, padx=8, pady=6)
            self.fields.append(field)
            ttk.Label(self.frame, text=unit).grid(row=row, column=2, sticky="w", padx=8)
            ttk.Label(self.frame, text=hint, wraplength=420).grid(row=row, column=3, sticky="w", padx=8)
        self.silence = ttk.Label(self.frame, text="", wraplength=930)
        self.silence.grid(row=7, column=0, columnspan=4, sticky="w", padx=8, pady=8)
        actions = ttk.Frame(self.frame)
        actions.grid(row=8, column=0, columnspan=4, sticky="w", pady=8)
        self.apply_button = ttk.Button(actions, text="应用整组时序", command=self._apply)
        self.apply_button.pack(side="left", padx=4)
        self.read_button = ttk.Button(actions, text="读取当前", command=self._read)
        self.read_button.pack(side="left", padx=4)
        self.resync_button = ttk.Button(actions, text="重新同步（只读）", command=self._resync)
        self.resync_button.pack(side="left", padx=4)
        ttk.Button(actions, text="填入默认值（待应用）", command=self._defaults).pack(side="left", padx=4)
        self.actual = ttk.Label(self.frame, text="板端时序：等待回读", justify="left", wraplength=940)
        self.actual.grid(row=9, column=0, columnspan=4, sticky="w", pady=8)
        self.status = ttk.Label(self.frame, text="", justify="left", wraplength=940)
        self.status.grid(row=10, column=0, columnspan=4, sticky="w", pady=8)
        ttk.Label(self.frame, justify="left", wraplength=940,
                  text=("4 项独立于“定位与寻向”的 8 项门槛，一次应用整组，并核对 Core0 回读与 Core1 采纳修订。\n"
                        "时序参数仅保存在 RAM，重启恢复 3 / 3 / 8 / 5 秒。应用清除旧声音确认轮次，"
                        "自身不启动自动模式、不驱动舵机，也不续期控制租约。\n"
                        "新暂停时长从下一次接受方位起使用；当前暂停倒计时继续沿用既有截止时间。"
                        "样本数为本组配置目标；Core1 是否采纳以修订同步为准。倒计时为板端软件状态。")).grid(
                            row=11, column=0, columnspan=4, sticky="w", pady=8)
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

    def _defaults(self):
        self._fill(DEFAULTS)
        self._dirty = True
        self._local_error = ""
        self.update(self._last)

    def _read(self):
        try:
            self._fill(self.receiver.read_audio_round_tuning())
            self._dirty = False
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)
        self.update(self._last)

    def _apply(self):
        try:
            self.receiver.send_audio_round_tuning(self._values())
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def _resync(self):
        try:
            self.receiver.resync_audio_round_tuning()
            self._local_error = ""
        except (ValueError, RuntimeError, OSError) as exc:
            self._local_error = str(exc)

    def update(self, telemetry):
        self._last = telemetry
        tuning = telemetry.get("audio_round_tuning", {})
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
                self._dirty = values != tuple(actual)
            silence = display_values((5000-values[0],))[0]
            self.silence.configure(text=f"模型输入固定 5 秒 · 草稿有效采样 {self.variables[0].get()} 秒 + 尾部静音 {silence} 秒（自动计算，只读）")
        except ValueError:
            self.silence.configure(text="尾部静音为 5 秒减去有效采样时长（自动计算，只读）；请先修正时序输入。")
            self._dirty = True
        self._last_key = key
        for field in self.fields:
            field.configure(state="normal" if ready else "disabled")
        self.read_button.configure(state="normal" if ready else "disabled")
        self.resync_button.configure(state="normal" if tuning.get("control_open") else "disabled")
        self.apply_button.configure(state="normal" if ready and valid and self._dirty and not tuning.get("pending") else "disabled")
        if actual:
            sync = "Core1 已同步" if tuning.get("fully_applied") else "Core1 同步中；以下为 Core0 当前参数"
            prefix = "板端时序回读" if ready else "上次时序回读（当前不可应用）"
            self.actual.configure(text=(
                f"{prefix} · Core0 修订 {tuning.get('revision')} / Core1 已观测 {tuning.get('core1_observed_revision')} · {sync}\n"
                f"有效采样 {actual[0]} ms · 最小结束间隔 {actual[1]} ms · 重置间隔 {actual[2]} ms · 定位后暂停 {actual[3]} ms\n"
                f"本组配置采样目标 {tuning.get('capture_samples', '—')} 样本 · 补静音目标 {tuning.get('silence_samples', '—')} 样本 · "
                f"本次暂停剩余 {tuning.get('pause_remaining_ms', '—')} ms · 累计应用 {tuning.get('apply_count', 0)} 次"))
        else:
            self.actual.configure(text="板端时序：等待支持 M46 的完整参数与 Core1 状态回读")
        message = self._local_error or tuning.get("message", "等待板端时序状态")
        if self._dirty:
            message += "\n输入框包含未应用的修改，板端当前参数以上方回读为准。"
        self.status.configure(text=message)
