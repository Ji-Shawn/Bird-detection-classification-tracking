# 固定输入与数值对拍

本目录提供三个固定输入及其原参考输出，用于发现实现偏差。它们不是带完整标注的准确率评估集，也不是本轮新采集的板测结果。

| 模型编号 | 输入 | 参考输出 |
| --- | --- | --- |
| `1` | `audio.bin` | 60 个 int8 分类 logits，top1=11 |
| `2` | `image.bin` | 60 个 int8 分类 logits，top1=0 |
| `3` | `ssd.bin` | 检测框、分数和 anchor；参考包含 3231 与 444 |

`expected.json` 保存原参考值；输入哈希来自上级 `assets_manifest.json`。当前工程没有一条已验收的“把这些样本送入板卡并自动导出完整输出”的通用命令。普通监控日志主要记录识别事件，不能替代原始 60 维 logits；完成离线比较器自测也不能证明 PL 推理正确。

## 1. 先取得独立输出

1. 在明确版本的板上测试程序、RTL 仿真或 CPU 参考程序中使用本目录的**原样输入**。记录输入布局、量化、后处理和加载方式；不要把 JPG/WAV 直接当成这些二进制张量。
2. 保存未经修改的原始输出日志或导出数据，记录运行时间、输入 SHA256、实际固件或设计 SHA256。分类输出必须为 60 个有符号 int8 值；SSD 使用同一后处理设置，导出所有参考层级检测，不能先应用拍照的 95% 门槛而只剩一个框。
3. 复制 `observation_template.json` 到自己的结果目录，填写记录。模板故意含 `null` 和空字符串，未采集数据时运行一定失败。
4. 将完整结果填入 `results`，使用 `{"logits": [...], "top1": 11}` 或 `{"detections": [{"anchor": 3231, "box": [x1,y1,x2,y2], "score": value}]}`。这里的省略号、坐标变量不是可直接使用的 JSON；必须替换成实际采集数值。

`capture.execution` 只能为 `board`、`rtl_simulation` 或 `cpu_reference`。`raw_evidence` 是相对于观察 JSON 的原始日志路径。`captured_at` 填带时区的时间，`run_id` 填可追溯的实验编号。不要复制参考值填到实际输出，也不要把另一个固件、另一组输入的旧日志改称当前结果。

10 月 2 日的历史 SSD 记录使用 anchor 3175，和本目录样本不同；历史分类记录没有完整 logits。因此它们不能直接输入这个比较器，已有对照单独放在 [历史参考汇总](../../reference/history_models_20261002/readme.md)。

## 2. 执行比较

所有命令从仓库根目录执行；Python 环境建立方法见 [从零复现](../../../reproduce.md)。假定实际观察保存在 `build/out/observations/actual.json`：

```powershell
.\.venv\Scripts\python.exe -B sim/compare_inference.py --actual build/out/observations/actual.json --output build/out/observations/comparison.json
```

成功为 `pass_numeric`、退出码 0；数值不一致为 `fail_numeric`、退出码 1；字段缺失、输入哈希不符、缺少原始记录等返回 `INVALID_OBSERVATION` 和非零退出码。结果包含误差、缺失/多余检测、参考与实际文件哈希。

默认要求 logits 逐项完全相同、top1 一致；检测框坐标绝对误差 ≤0.001 像素、分数绝对误差 ≤0.00001。SSD 按 anchor 匹配，不依赖输出排序。缺少框、多出框、重复 anchor、NaN、把概率填成 logits 均不会得到通过。只有经分析确认参考与实现的数值定义允许误差后，才可通过 `--logit-tol`、`--box-tol`、`--score-tol` 改阈值，并在实验报告写明理由。

`pass_numeric` 只说明给出的两个数值结果符合阈值。脚本检查文件存在与哈希，无法证明日志确由板卡产生，仍须人工核对运行过程和版本关系。它不度量识别准确率、帧率、SD 写入性能或机械响应。

## 3. 比较器自身的验证

```powershell
.\.venv\Scripts\python.exe -B sim/test_inference_comparison.py
```

8 项测试检查同 top1 但 logits 错误、缺检测、乱序、重复 anchor、NaN 等边界。测试中的合成结果只验证判定逻辑，不作为模型验收证据。完整离线入口 `build/run_checks.py` 已包含这一组。
