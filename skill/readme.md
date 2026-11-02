# 技能包：把经验变成可复用的验证方法

这个目录面向拿到项目的另一支团队，也可交给大模型作为操作说明。先读 [zynq_pl_accel/skill.md](zynq_pl_accel/skill.md)。所有命令均在仓库根目录执行，文件名保持小写英文；中文仅用于正文。

```text
skill/
├── readme.md
└── zynq_pl_accel/
    ├── skill.md                  # 技能入口与任务路由
    ├── scripts/
    │   ├── inspect_reports.py    # 只读检查 Vivado 报告，输出 JSON
    │   └── test_inspect_reports.py # 缺报告、负余量等反例自检
    ├── references/
    │   ├── report_review.md      # 报告审查步骤与判定规则
    │   ├── numerical_debug.md    # 数值/数据通路排障流程
    │   └── casebook.md           # 历史案例、已知边界与当前修正
    ├── assets/
    │   ├── task_prompt.md        # 可复制的模型任务提示词
    │   ├── validation_record.md  # 输入、命令、输出与结论记录模板
    │   └── finding_disposition.md # 告警处置记录模板
    └── examples/
        └── published_report_review.json # 对随包历史报告的实际检查结果
```

## 每一项如何使用

| 项目与形式 | 适用范围、前提 | 使用方法与产物 | 失效条件、停止条件 | 已验证效果或来源 |
| --- | --- | --- | --- | --- |
| 报告检查脚本 | 英文 Vivado 文本报告；有 timing、层次化 utilization、CDC、methodology、DRC 五份报告；Python 3.10+，仅标准库 | 运行下方命令；得到指标、原文行号、SHA256、待审查项及状态 | 文件缺失、格式不支持、摘要缺字段时返回 `incomplete`；不支持自动判断同步器拓扑正确性、自动批准豁免或推断板卡结果 | 随包 2026-10-27 报告能提取 WNS 0.128 ns、WHS 0.005 ns、LUT 43722、FF 35383、DSP 164，并识别 CDC 与 I/O 约束待审查项；记录见 examples JSON |
| 报告判读工作流 | 有实际报告但不能确定“时序全绿”是否足够 | 按 [report_review.md](zynq_pl_accel/references/report_review.md) 检查范围、缺项、指标和告警；用告警模板记录处置 | 报告与固件/源码版本关系不明、只有截图或口头结果时不做完整签核 | 来源为本包 timing 的缺 I/O delay 记录及 CDC 的 Unsafe/Unknown 条目；这是报告事实，不是已完成硬件根因诊断 |
| 数值与数据通路排障清单 | 有独立参考输出、可重复输入和执行入口；适用于 PS/PL 数据交换或流式算子 | 按 [numerical_debug.md](zynq_pl_accel/references/numerical_debug.md) 分离输入、传输、运算、输出契约，逐次记录实验 | 黄金数据读取失败、输入哈希不明、比较数为零、计时未标定、工具或硬件状态变化未记录时停止下结论 | 来源为旧开发记录中的读取失败假绿、地址区间重叠、反压冻结和量化符号案例；历史记录详见 casebook，未将旧测试次数视为本次复测 |
| 模型任务提示词 | 需要模型审查或修改一项工程问题；已明确可操作范围 | 复制 [task_prompt.md](zynq_pl_accel/assets/task_prompt.md)，填写项目入口、证据、阈值和允许操作；要求输出可验证结论 | 缺原始数据时只列缺项；不得要求模型补写不存在的实测数字 | 模板针对本项目“路径存在即当作构建通过”“把局部测试写成整机通过”等审查缺口设计；效果以每次真实执行记录评价 |
| 实验与告警记录模板 | 需要交接、答辩或复查；适用于成功、失败及未完成实验 | 复制 validation_record / finding_disposition 到当前项目的证据目录，填入真实值并附原始日志 | 未填写项保留“未测/待确认”；豁免没有对象、依据、责任人与剩余风险时保持未关闭 | 模板规定证据结构，本身不提供测量结果；已有结果示例仅来自 examples JSON |

## 十分钟运行一个实际案例

电脑只需安装 Python。下面检查的是随包历史实现报告，不连接板卡、不启动 Vivado、不改变约束：

```powershell
python -B skill/zynq_pl_accel/scripts/inspect_reports.py --reports build/reports --prefix pl_ --output build/out/skill_review.json
```

对当前随包报告，预期得到 **`review_required`，退出码 2**。这是脚本正确识别尚需解释的 CDC、方法学与 I/O 约束条目，不是命令运行故障。打开 `build/out/skill_review.json`，先看 `findings`，再依据其中的文件与行号回到原报告。不要为了得到绿色状态删除告警或放宽时序约束。

检查自己新产生的报告时，用本次报告目录替换 `build/reports`。本包的 `build/pl/build_pl.tcl` 输出文件不带 `pl_` 前缀，使用：

```powershell
python -B skill/zynq_pl_accel/scripts/inspect_reports.py --reports build/out/pl --prefix= --output build/out/new_pl_review.json
```

脚本可在 Python 可运行的平台检查文本文件。它不负责跨平台运行 Vivado/ARM 工具链。若需要资源预算检查，显式提供项目预算，例如 `--max-dsp 220 --max-lut 53200`；这些数字是本例的预算输入，迁移器件时必须替换，不能当作所有器件的资源上限。

| 状态 | 退出码 | 含义 |
| --- | --- | --- |
| `screen_pass` | 0 | 所支持的摘要检查未发现问题；仍不等于硬件、功能、CDC 拓扑或整机签核通过 |
| `review_required` | 2 | 摘要可读，但存在需要人工确认的告警、CDC 或覆盖问题 |
| `fail` | 2 | 明确负余量、失败端点、错误或超过用户给定的资源预算 |
| `incomplete` | 3 | 必需文件/字段缺失、无法解析或报告设计名不一致；不能判为通过 |

脚本将每份输入的 SHA256 与路径写入结果。重复运行相同输入和参数，应得到相同指标和判定。对输入的更改应由新的哈希显示出来。

## 检查脚本自身是否会“假绿”

```powershell
python -B skill/zynq_pl_accel/scripts/test_inspect_reports.py
```

自检包含当前报告、干净的人工最小报告，以及缺报告、截断摘要、负余量、资源超预算、漏时钟/约束和报告设计名混用等反例。人工最小报告只用于验证解析器判定，不是任何实物工程的验收证据。

## 迁移到另一个项目

1. 复制整个 `skill/` 到目标项目，保留目录说明、`zynq_pl_accel/` 和内部相对链接。
2. 修改项目入口、器件、工具版本和参考数据说明；报告格式不受支持时先适配解析器并运行反例测试。
3. 从提示词模板选择一个具体任务，使用实验记录模板记录真实过程。
4. 复用方法，不复用本项目的地址、复位顺序、门槛或实测结论；边界见 [casebook.md](zynq_pl_accel/references/casebook.md)。

比赛包使用小写 `skill.md`。代理工具如要求大写 `SKILL.md`，仅在仓库外的个人安装副本中改名；普通阅读和脚本运行不需要安装代理技能。返回[项目说明](../readme.md)或[源码导览](../src/readme.md)。
