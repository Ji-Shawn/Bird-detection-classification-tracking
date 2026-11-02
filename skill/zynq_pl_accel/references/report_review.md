# 报告检查：从可解析到可签核

## 适用范围

本流程用于查看一组已有英文 Vivado 报告是否支持所写结论。随包实例来自 Vivado 2023.2；脚本支持该实例的摘要格式。换版本、语言或报告选项后，先确认字段可解析，再讨论设计结果。此流程不创建工程，不修改 XDC，也不替代 RTL 仿真或板卡测量。

## 输入与运行

准备同一设计、同一实现的五份报告：`timing.rpt`、`utilization.rpt`、`cdc.rpt`、`methodology.rpt`、`drc.rpt`。本包历史文件有 `pl_` 前缀。使用 `inspect_reports.py --reports <目录> --prefix <前缀>`，输出 JSON；具体可复制命令见 [技能目录说明](../../readme.md)。

脚本只使用 Python 标准库。它会保存文件路径、SHA256、大小、报告头元数据，并提取：

- timing：setup/hold/pulse 的 worst slack、total slack、失败与总端点数，check_timing 覆盖计数、时钟周期/频率；
- utilization：完整顶层的 LUT、FF、RAMB36、RAMB18、DSP 等计数；
- CDC：摘要行中的源/目的时钟、分类、约束类型、Safe/Unsafe/Unknown/No ASYNC_REG 计数；
- methodology/DRC：规则编号、严重性和数量；摘要表的数量必须与报告总数一致。

五份报告缺一份、必需字段缺失、内容截断或设计名混用，均返回 `incomplete`。单时钟设计若得到没有 crossing 行的 CDC 报告，当前解析器也保守返回 `incomplete`；应人工确认报告确实表示零跨域后适配解析器，不能把空文件当作零跨域。

## 分四层审查

### 第一层：先证明检查了什么

看报告的 Design、Device、Date、Tool Version、Design State。解析器只能发现部分不一致，无法仅凭文本证明五份报告来自同一个 checkpoint。将本次构建命令、源码清单、工具版本、bitstream 哈希和报告放在同一个实验记录里。报告属于旧实现时就标旧实现，不能改日期伪装新运行。

### 第二层：看数值与覆盖

负余量或非零失败端点表示报告里的检查未满足；资源预算来自用户或目标器件，脚本不自动猜预算。正余量仅对应已分析且受当前约束覆盖的路径。继续检查 no_clock、unconstrained_internal_endpoints、no_input_delay、no_output_delay、partial_*、时钟列表及约束例外。

本包历史报告的 WNS 为 0.128 ns、WHS 为 0.005 ns，且内部未约束端点为 0；同一报告仍列出 no_input_delay=7、no_output_delay=11、partial_input_delay=4。应检查这些端口是否有合理的接口或静态输入依据，不能因内部端点为 0 就写“所有约束无问题”。来源：[pl_timing.rpt](../../../build/reports/pl_timing.rpt)。

### 第三层：逐项处理 CDC 和方法学条目

本包历史 [pl_cdc.rpt](../../../build/reports/pl_cdc.rpt) 包含 1 个报告为 Unsafe 的端点和 1 个 Unknown 端点；不能从摘要认定它们必然导致功能错误，也不能自动豁免。要找到具体路径、同步器/握手拓扑、约束目标及路径类别，再填写 [告警处置模板](../assets/finding_disposition.md)。

脚本不会因 `False Path`、`User Ignored`、`Safely Timed` 或 `ASYNC_REG` 字样自动批准告警。规则编号和数量保留原值。文档解释不等同于约束豁免；修改约束后需要新报告支持，不能把修改前的报告继续当作修改后的验收。

### 第四层：把检查结果接到发布结论

`screen_pass` 仅表示所支持摘要检查未发现问题；`review_required` 表示需要人工解释；`fail` 表示明确违反指标；`incomplete` 表示缺证据。任一状态都不能直接推导模型精度、实际帧率、机械稳定性、冷启动成功或板卡安全。

已关闭的条目应包含对象、证据、处理前后差异、审核人和剩余风险。脚本有意不接受“全局忽略所有 Warning”的参数。团队确需豁免时，在逐项处置记录中说明并由项目负责人判定。

## 已验证效果与失效边界

2026-11-03，本技能对随包历史报告得到 `review_required`、30 个待检查条目；实际输出在 [published_report_review.json](../examples/published_report_review.json)。脚本的 16 个行为测试覆盖干净人工摘要、缺文件、截断、非有限数字、负余量、零检查端点、CDC Unsafe、未知 CDC 严重级别或残缺数据行、资源预算和混合设计等条件；自检命令见技能目录说明。CDC 表头后的非空数据行必须全部解析；遇到不支持的格式会返回 `incomplete`，不会忽略该行后给出通过。

这些测试证明解析器对已覆盖输入的行为，不证明支持所有 Vivado 版本。结果数字来自历史报告，不是本次重新实现或上板的测量。新报告格式应补充对应真实样本与失败反例后再使用。
