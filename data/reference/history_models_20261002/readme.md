# 历史板测的逐层对比数据

本目录的数据由 [历史板测日志](../../../board/evidence/history_models_20261002/readme.md) 转换，原始文件 SHA256 和脱敏规则见该目录的 `provenance.json`。

`layer_comparisons.csv` 包含 222 行：图像隔离 62 行、图像链式 62 行、SSD 链式 98 行。字段含义如下。

| 字段 | 含义 |
| --- | --- |
| `case`、`row` | 历史测试名称和原始结果行号 |
| `compared_bytes` | 原日志报告的实际比较长度，十六进制转十进制 |
| `mismatch_count` | 不同字节数，没有把容差内差异改写为零 |
| `max_abs_difference` | 原程序报告的最大绝对差值 |
| `first_bad_hex` | 原始首错位置，保留十六进制标记 |
| `source_file` | 对应的随包板测日志位置，相对于仓库根目录 |
| `meaning` | `skipped_stem` 为原始跳过行；`measured` 为保留的测试记录 |

`comparison_summary.json` 保留当时的分段计时、时钟条件和边界。它不包含当前固件的现场观察，不是当前样本推理比较器的输入格式。需要复核转换时，对照日志中的 `[n] total=... mismatch=... maxd=... first=...` 或 `SSD_ROW` 行逐字段检查即可。
