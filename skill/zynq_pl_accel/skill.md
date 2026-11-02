---
name: zynq-pl-accel
description: Review Zynq PL accelerator evidence, triage numerical and timing failures, and produce a reproducible validation record from supplied source, golden data, and Vivado reports. Use for PS/PL verification and release evidence; do not infer hardware success from compilation or report hashes.
---

# Zynq PL 加速验证与交付技能

本技能帮助另一支团队建立“输入、执行、结果、判定”可追溯的验证闭环。适用于有 PS 软件、PL RTL 或 HLS 算子、参考数据及构建报告的 Zynq 项目；本包实例为 AX7020 / Zynq-7020 / Vivado 2023.2。其他器件、工具版本及接口参数需要重新核对，不能照抄实例常量。

## 开始前先确定问题与证据

1. 记录用户要验证的功能、软件/硬件版本、输入格式、输出格式和验收阈值。没有阈值时，先列出缺项；不能在看过实际输出后选择恰好能通过的阈值。
2. 查阅项目当前入口。这个包的正式入口是根 `readme.md`、`build/readme.md` 与 `board/readme.md`。`src/pl/bd/` 是历史连接参考，正式 PL 构建读取 `src/pl/structural/`。
3. 按任务只读取下列相关材料，不把旧排障笔记当作现役工程配置。

| 任务 | 使用材料 | 可交付结果 |
| --- | --- | --- |
| 从报告判断资源、时序与 CDC 证据是否完整 | [报告检查流程](references/report_review.md) 与 [检查脚本](scripts/inspect_reports.py) | 含输入哈希、指标、缺项和待审查条目的 JSON |
| 数值不一致、停顿丢数据、重复运行异常 | [数值与数据通路排障](references/numerical_debug.md) | 可证伪假设、最小用例、前后结果和结论边界 |
| 把团队经验用于新项目 | [历史案例边界](references/casebook.md) | 已验证事实与待验证假设分别记录 |
| 给模型下达一次可审查任务 | [提示词模板](assets/task_prompt.md) | 任务范围、证据、操作约束与验收条件 |
| 记录验证与告警处置 | [实验记录模板](assets/validation_record.md)、[告警处置模板](assets/finding_disposition.md) | 可复跑记录及每项告警的依据 |

## 执行约束

- 源码哈希、编译成功、仿真通过、实现通过、板卡实测是不同证据。结论必须说明实际完成哪一层，以及未覆盖什么。
- 本项目有多个时钟域。读当前 timing / CDC 报告确定时钟关系，不能使用历史“单钟域，免查 CDC”的说法。
- 遇到缺文件、解析失败或缺少实际输出，结论写 `incomplete`；已知不满足验收条件写 `fail`。不要填造测量值，也不要把没有告警文本等同于报告通过。
- 修改设计时，每次围绕一个可验证假设，保留修改前后的输入、命令与结果。跨帧、尾块和反压是流式模块的独立用例；单帧恒定 TREADY 的结果不能替代这些用例。
- 不因旧案例统一禁用 PIPELINE、改变复位顺序或设置固定 hold 余量门槛。实际控制协议、状态机、时钟约束和工具版本决定适用性，详见案例边界。
- 上板操作按当前已验证脚本执行。读取文档或报告不包含下载固件、复位处理器、写卡或驱动云台的授权；任务已有明确授权时按其范围继续，不重复索取。

## 完成时的最小交付

给出：检查对象与版本 → 可复制的命令 → 实际结果及证据路径 → 通过/失败/未完成判定 → 剩余风险或下一项验证。报告中的数字必须能追溯至输入文件或本次运行输出。

技能的适用条件、运行示例、退出码、失效条件和已验证效果集中在 [skill/readme.md](../readme.md)。本仓库按交付规则保留小写 `skill.md`；若某个代理框架强制要求 `SKILL.md`，可在仓库外的个人技能安装目录复制并改名，再按该框架说明加载。本项目未自动安装或启用任何代理配置。
