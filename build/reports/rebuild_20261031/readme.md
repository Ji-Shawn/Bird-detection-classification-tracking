# 2026-10-31 完整 PL 重建证据

这是一份**历史构建归档**，来自独立目录 `github_vivado_7bcce46`、提交 `7bcce4663d3e4c0fd4e6e5e4db191003d908d46c`。本次整理将原始结果入包，并将成功实现策略补入当前 `build/pl/build_pl.tcl`。这里的历史数值不自动等于后来修改源码后的构建结果。

工具为 Vivado 2023.2，目标 `xc7z020clg400-2`。原记录核对了 39 份 IP 配置、217 项手动 PS 参数和 168 个引脚，差异为零。完整结果见 [result.json](result.json)，文件来源及原始/入包 SHA256 见 [provenance.json](provenance.json)。归档文本只替换开发机根目录并规范换行，没有删除失败或告警。

| 项目 | 默认实现策略 | Explore 策略 |
| --- | --- | --- |
| WNS | -0.073 ns | +0.082 ns |
| TNS | -0.175 ns | 0 ns |
| 失败 setup 端点 | 3 | 0 |
| WHS | +0.049 ns | +0.012 ns |
| 结论 | 时序失败 | 通过这轮实现的时序门槛 |

第二次实现使用 Explore 布局、AggressiveExplore 物理优化、Explore 布线及再次物理优化。`successful_strategy.tcl` 是原始脚本归档，会读取当时的中间检查点，**不是新机器的构建入口**。可复现入口为根目录执行 `build/pl/build_pl.tcl`，从源码和 IP 配置开始构建。

本轮资源：LUT 43274/53200（81.34%）、FF 35369/106400（33.24%）、Slice 13037/13300（98.02%）、BRAM 89/140（63.57%）、DSP 164/220（74.55%）。Slice 占用高，不应仅凭 FF 尚有余量判断布局宽松。详细文件为 `utilization.rpt`、`timing.rpt`、`clocks.rpt`、`route.rpt`。

## 待处理项及验收边界

本归档的结论是“实现时序通过，工程签核待审查”，不是“全部检查通过”。本次没有修改 RTL/CDC 或凭经验豁免告警。

| 证据 | 当前状态 | 后续处理与成功判据 |
| --- | --- | --- |
| CDC 含 1 个 Unknown、1 个 Unsafe | 待审查 | 逐端点核对 OSD 控制跨域及 VDMA FIFO 复位链；分析源稳定性、同步器和复位释放，修复后重跑，或提供有审阅人的明确豁免依据 |
| no_input_delay=7、no_output_delay=11、partial_input_delay=4 | 待审查 | 按板级接口逐个说明延时、异步或静态属性；补齐约束并重跑，不能仅凭内部未约束端点为零关闭此项 |
| 方法学与 DRC 普通告警 | 待审查 | 用 `methodology.rpt`、`drc.rpt` 定位，记录功能影响、修改或保留理由；无 Error 不代表无需处理 |
| XDC 中 `if` 不受支持 | 已在当前构建 Tcl 加入等价存在性断言；历史原告警保留 | 当前普通 Tcl 必须找到 4 个按键首级同步寄存器；XDC 告警仍须在新日志中检查，未声称已经消失 |
| 新 bit 与已发布 bit 不同 | 正常版本差异，未上板 | 留下文件哈希，单独验证新硬件与软件配对、冷启动、摄像头/HDMI/音频/存图，不能用历史板测代替 |

`cdc_details.rpt` 保留端点细节。技能包提供 [报告审查步骤](../../../skill/zynq_pl_accel/references/report_review.md)和告警处置模板，用于把每条问题形成可核对的记录。不得通过把未知项计为零、隐藏告警、扩大 false path 来获得表面通过。
