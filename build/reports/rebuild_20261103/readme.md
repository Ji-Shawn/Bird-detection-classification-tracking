# 2026-11-03 当前工程完整 FPGA 重建

本目录保存最新一轮从项目源码和 IP 配置开始的实际综合、布局、布线及 bitstream 生成结果。Vivado 2023.2 于 2026-11-03 00:53:38 启动，01:14:26 正常结束，日志出现 `PL_IMPLEMENTATION_TIMING_PASS`。当前发布固件的配套报告仍为上级目录的 `pl_*.rpt`，本目录描述单独生成的新 PL，未替换 `board/firmware/` 中的发布文件。

**结论：完成实现并满足本次脚本的时序门槛，仍需审查 CDC、I/O 约束和普通告警；没有新上板验收。** 结构化结果见 [result.json](result.json)。

## 实际结果

| 项目 | 本次结果 |
| --- | --- |
| 器件 / 顶层 | `xc7z020clg400-2` / `av_system_wrapper` |
| WNS / TNS | +0.062 ns / 0 ns；setup 失败端点 0 |
| WHS / THS | +0.012 ns / 0 ns；hold 失败端点 0 |
| 最差脉宽余量 | +0.147 ns；脉宽失败端点 0 |
| 无时钟 / 内部未约束端点 | 0 / 0 |
| 可布线网 / 已完全布线网 | 77545 / 77545；布线错误 0 |
| LUT / FF / DSP | 43274 / 35369 / 164 |
| RAMB36 / RAMB18 | 80 / 18；按容量折合 89 个 36 Kb 块 |
| 新 bitstream SHA256 | `898d143f655862a23132a45232d4f9893c6caa9e7bfc58c9cdcab91078649710` |

时序数字从 `timing.rpt` 的全设计 12 列摘要独立提取；资源从 `utilization.rpt` 顶层行读取；路由数量从 `route.rpt` 读取，并与技能脚本结果交叉核对。层次化资源行不可相加，否则会重复计数。正余量不是额外提高频率的许可，也不是实时整机帧率。

使用策略为 Explore 布局、AggressiveExplore 物理优化、Explore 布线及再次 AggressiveExplore 物理优化。新 bit 与发布 bit 不同，保存在 `build/out/pl/adapter_system.bit`；未覆盖发布固件，也未加入此前 ARM 重建所验证的 BOOT。该 BOOT 仍使用发布 PL。

## 原始证据与指纹

| 文件 | 用途 |
| --- | --- |
| `implementation_log.txt`、`session_journal.txt` | 完整运行日志、入口与会话信息 |
| `timing.rpt`、`utilization.rpt`、`route.rpt` | 实现后时序、层次化资源和路由状态 |
| `synthesis_timing.rpt`、`synthesis_utilization.rpt` | 综合阶段结果，不能冒充实现后结果 |
| `cdc.rpt`、`drc.rpt`、`methodology.rpt`、`bus_skew.rpt` | 保留待分析条目和原检查结果 |
| `summary_review.json` | 对脱敏前 `build/out/pl/` 报告运行技能脚本的真实输出：`review_required`，32 条待审查事项；输入哈希对应原文件 |
| `input_sha256.json` | 归档时 148 个 `src/pl/` 文件及构建 Tcl 的指纹、脚本直接引用路径 |
| `provenance.json` | 原文件与脱敏归档文件各自的 SHA256、大小和转换规则 |
| `process_stderr.txt` | 原进程 stderr 的两行“系统找不到指定的路径。”，由 GB18030 转为 UTF-8 后保留 |

日志只替换工作目录、工具安装目录、临时目录和主机名；不删除告警、错误或失败条目。脱敏后归档 `.rpt` 的字节和哈希会变化，不能用 `summary_review.json` 中的原输入哈希直接校验本目录文件；应查看 `provenance.json` 中原文件与归档文件的对应记录。原 stderr 消息的具体来源尚未定位，它没有阻止本次 Vivado 完成；不能把它从证据中隐藏，也不能将其等同于本轮综合实现失败。

`input_sha256.json` 是**归档时快照**，不是当时未保存的全输入构建前快照。除了单独留存的实际运行脚本版本，不声称已经有所有源文件的构建前后哈希对照。

## 完整构建与目录修复属于两个验证范围

完整构建读取的工程创建脚本已保存为 `create_project_used.tcl`。本轮发现 IP 生成器可能把辅助摘要写到进程工作目录后，`create_project.tcl` 增加了两行注释和 `cd $m51_pl_out`，以把输出集中到构建目录；除此之外内容相同。这个中间版本归档为 `create_project_current.tcl`，精确差异见 `create_project_change.txt`；文件名保留首次归档时的名称。

随后用当前脚本在独立新目录重新创建工程并生成 IP，01:17:18 结束：**39 个 IP、当前目录为指定的新输出目录、仓库根目录 `NA` 摘要不存在**。证据见 [ip_generation_check.json](ip_generation_check.json)、`ip_output_check.txt`、`ip_output_check_log.txt` 和实际驱动脚本 `ip_output_check.tcl`。

最终复查还发现该 Tcl 的原始混合换行形式含 CRCRLF 和独立 CR。文件随后只做了通用换行转换，统一为 LF；独立逐字节检查确认，将中间版本的 CRLF 和独立 CR 转为 LF 后，与最终文件完全一致，没有改变 Tcl 内容。最终脚本归档为 `create_project_final.tcl`，SHA256 为 `c35912c45e5903c81c829765e8b68d466f8c9bc78e1c2ccc56af5472490f1f33`。

最终 LF 脚本又在另一个独立输出目录生成了 39 个 IP，01:27:56 正常结束，目录和根目录摘要检查再次通过。证据见 [ip_generation_final_check.json](ip_generation_final_check.json)及 `ip_output_final_check_log.txt`。这次也没有重新运行综合布线。

这两次跟进检查没有再次运行综合、布局、布线或 bitstream 生成，因此不能把本次完整构建的 bit 哈希写成“修改工作目录和换行后再次完整生成”的结果。最终指纹复核中，RTL、IP 配置及约束未变化；`src/pl/readme.md` 的导航更新和 Tcl 的换行变化分别记录在 `input_sha256.json`，保留较早快照，没有静默替换其哈希。

## 尚未关闭的检查项

- CDC 摘要含 1 个 Unsafe 和 1 个 Unknown。应进一步核对实际跨域端点、同步结构和复位释放，不能凭正 WNS 自动关闭。
- `no_input_delay=7`、`no_output_delay=11`、`partial_input_delay=4`。需要逐个说明板级接口的时序模型或例外依据。
- 方法学摘要有 139 个条目，DRC 摘要合计 321 个条目，包含普通 Warning 和 Advisory。技能脚本汇总成 32 条待审查事项，两者不是同一计数口径。
- 完整日志保留 3 行 Critical Warning：一行逐文件添加效率提醒，两行 XDC 内 `if` 不受支持的提醒。构建 Tcl 的等价同步寄存器数量断言不等于历史/当前日志中这些警告已经消失。
- 新 bit 尚未做冷启动、实时摄像头/麦克风、HDMI、云台或 SD 存图验收。`PL_IMPLEMENTATION_TIMING_PASS` 只对应脚本已执行的工程门槛。

按[构建说明](../../readme.md)从项目根目录重建；按[技能报告审查流程](../../../skill/zynq_pl_accel/references/report_review.md)处理告警。不要删除问题记录、放宽例外或把不同固件的板测混在一起来形成“全部通过”的结论。
