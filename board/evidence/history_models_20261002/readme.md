# 历史模型支线板测：2026-10-02

## 来源与整理方式

原始目录为开发工作区的 `m9_visual_deploy/board_20261002_095532/`。这里选入 15 份证据文件，来源和原始 SHA256 见 [provenance.json](provenance.json)。入包前核对了选入运行日志与当时 `board_validation.json` 所记指纹的一致性。

日志以 `.txt` 保存，保留原有数值、成功标记、错误标记及原记录已有的乱码；仅将开发机工作区绝对前缀替换为 `${original_workspace}/`。因此入包文件与原始文件可能具有不同哈希，清单同时记录两者。JSON 中完整原日志索引的部分条目仅用于追溯，没有把整个原工作区复制入包。

`candidate_100mhz_failure_20260929.txt` 来自更早的 PW128 候选试验。它不是 10 月 2 日新流水候选的日志，保留它是为了说明为什么不能用“单次通过”作为稳定性结论。

## 实际读到了什么

| 试验 | 证据 | 能成立的结论 |
| --- | --- | --- |
| 旧音频引擎链式执行 | `old_chain_head.txt` | 完成标记出现；top1 与 expected_top1 均为 11；E1–E51 为 84.433080 ms |
| 新流水候选连续三轮 | `candidate_chain_1_head.txt` 至 `candidate_chain_3_head.txt` | 三轮均完成且 top1=11；E1–E51 分别为 64.055345、64.054771、64.067119 ms |
| 图像分类隔离与链式 | `image_isolated_clean.txt`、`image_chain_1.txt`、`image_chain_repeat_2.txt` | 保留 62 行比较统计及完成、模型身份、头部读回；链式对原 QDQ 的非零差异没有删除 |
| SSD 链式与重复执行 | `ssd_chain_1.txt`、`ssd_chain_repeat_2.txt` | 98 行比较记录均有实际比较长度，mismatch=0；保留两个检测框和完成标记 |
| 更早候选的失败 | `candidate_100mhz_failure_20260929.txt` | 第二轮在第 3 层超时，此前层已出现大量错误，不能将该候选作为稳定基线 |

音频三轮 E 段均值为 **64.059078 ms**，相对同次上电旧引擎的 **84.433080 ms** 降低 **24.130%**。这是当时的引擎相关分段计时，不是整机实时采集、识别、显示、存图的端到端延迟；也不是当前发布固件的重新测量。

## 必须同时保留的边界

- 历史记录采用 100 MHz PL 时钟，计时校准值为每 tick 95.72 ns；不包含主机数据传输和实时输入采集，图像 PS stem/add 的计时也不完整。
- 音频头部仍记录 `visual_bad=0x47a`、`logits_bad=0x38`。top1 相同不能写成全部输出逐字节相同。
- 图像链式采用原浮点 QDQ 参考与独立整数契约的不同判定层次，日志中的非零误差必须连同原判定语义一起解释。不得只保留 PASS 字样。
- 各模型切换时采取完整系统复位、PS 初始化、候选重新配置和 DDR 探针检查，并重新灌数据。这里不验证常驻集成应用的无复位模型切换。
- 原始汇总的 `release_ready` 就是 `false`，尚缺重复物理冷启动、长期稳定性、实时麦克风/相机融合和完整帧时延；整理时没有将它改为通过。
- SSD 日志样本与当前 `data/models/samples/expected.json` 不同，不能直接拿其框坐标与当前参考作同输入对比。

便于查看的十进制统计表见 [layer_comparisons.csv](../../../data/reference/history_models_20261002/layer_comparisons.csv)。表中 `skipped_stem` 是原程序跳过的 stem 行，不算一次成功比较。CSV 是日志机械转换结果，没有重新运行 FPGA。
