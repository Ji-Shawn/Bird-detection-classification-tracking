# CRC32 独立原型：验证方法的后续复用案例

历史实验日期为 **2026-10-14**，由 XSim 日志和两份报告中的时间确认；2026-11-03 只做文件核验和归档，没有重新运行 XSim、Vivado 或硬件。原模块名 `crc16_stream` 中的 16 指每次接收 16 位数据，算法实际为反射形式的 IEEE CRC32，不是 CRC16。

## 直接证据与计数含义

| 项目 | 可核对的结果 | 原始证据 |
| --- | --- | --- |
| 仿真比较 | 3042 个数据包、2123546 个输入拍、2265319 个运行周期 | [xsim.txt](xsim.txt) 第 18 行 |
| 输出反压 | 197 个 `m_valid && !m_ready` 时钟周期，不是 197 个独立事件 | [tb_crc16.sv](tb_crc16.sv) 第 15～16 行 |
| 黄金参考 | Python 标准库 `zlib.crc32`；种子 2276，含空包、`123456789`、奇数尾字节、边界长度、随机包及一帧分包 | [make_vectors.py](make_vectors.py)、[expected.hex](expected.hex) |
| 比较结束条件 | 输入数与收到的 CRC 数均达到声明值，至少发生一次输出反压；逐包 CRC 不符即失败，并有看门狗 | [tb_crc16.sv](tb_crc16.sv) 第 19～43 行 |
| CRC 内核综合资源 | LUT 138、FF 65、DSP 0、BRAM 0；报告状态为 Synthesized | [crc_utilization.rpt](crc_utilization.rpt) |
| 独立实现的内部时序 | 10 ns 时钟，WNS +4.871 ns、WHS +0.253 ns；报告状态为 Routed | [crc_timing.rpt](crc_timing.rpt) 第 135～154 行 |

3042 包包括 15 个固定/边界用例、64 个随机用例和 2963 个 1920×1080 RGB565 帧分包。它不是 3042 帧视频，也不是 3042 次板卡运行。2265319 是测试平台计数的仿真时钟周期；测试平台时钟周期为 10 ns，不能将该数写成 CPU 耗时或整机帧率测量。

本次又用只读标准库脚本解析原 `input.hex`，逐包重算 CRC，并核对包数、输入拍数及两个标准检查值。结果见 [vector_audit.json](vector_audit.json)。这一步独立检查测试数据与黄金文件的一致性，没有重跑 RTL。其时间和历史 XSim 运行分开记录。

## 能说明的复用与不能说明的事情

该案例实际采用了独立软件参考、逐包数值比较、确定性输入、随机输入停顿/输出反压、停顿时输出稳定性检查、复位中止未完成包和明确结束计数。这些做法体现了前述数值与握手验证方法在另一个模块中的应用。现有源文件和日志能够证明这些检查存在且该次仿真完成，不能仅凭方法相似证明某一句历史提示词或某个模型直接造成了全部改进。

这是**尚未集成的独立 CRC 原型**。138 LUT 不含整机接口、CRC 表缓存、跨时钟结构和控制。时序报告明确有 22 个输入、34 个输出未设置 I/O delay；[synth.txt](synth.txt) 还保留 `HD.CLK_SRC` 未指定的警告，不能据此完成整机时序或 CDC 签核。

[original_result.md](original_result.md) 中约 30 ms 来自 2963 包乘以旧软件约 10 μs/包的预算估算，既不是新 CRC 核板测，也不是可直接兑现的端到端时延下降。三帧 CRC 表、约 12 个 BRAM36、接口控制不超过 500 LUT 等同样属于集成预算。旧软件 CRC 优化的板测数字仅作为原总结保留；本目录没有纳入它们各自的原始板测日志。

[restored_m23.json](restored_m23.json) 仅记录恢复旧固件后的在线检查，不能作为新原型的性能证据。集成后的帧序号/缓冲区身份、陈旧 CRC 回退、分包边界、CDC、复位与实际帧率仍需另行实现和验证。

## 文件来源与轻量复核

[provenance.json](provenance.json) 记录各原始文件与归档文件的 SHA256、大小和脱敏规则。源码、测试平台和向量生成器保持原字节；文本日志仅将绝对路径及主机名换成占位符。约 14.9 MB 的 `input.hex` 没有复制，原哈希已保留；可在临时目录用原生成器重建。生成器会覆盖其所在目录的向量文件，因此不要在本证据目录直接运行它。

以下命令从仓库根目录执行，只使用 Python 标准库，在 `build/out/` 中生成输入并检查，不启动 FPGA 工具。`python` 应替换为复现文档中同一个虚拟环境解释器。

```powershell
New-Item -ItemType Directory -Force build/out/crc_method_reuse | Out-Null
Copy-Item sim/evidence/crc_method_reuse_20261014/make_vectors.py build/out/crc_method_reuse/make_vectors.py
python -B build/out/crc_method_reuse/make_vectors.py
python -B sim/evidence/crc_method_reuse_20261014/audit_vectors.py --vectors-dir build/out/crc_method_reuse
```

成功为 JSON 中 `status: pass`、`packets_compared: 3042`、`crc_mismatches: 0`；还应将 `input_files_sha256` 与归档的 `vector_audit.json` 比较。原生成器使用平台文本换行，跨平台时文件字节哈希可能不同，应另行比较解析后的向量值与结果；不能把换行变化直接认作算法差异。历史综合脚本仅作证据保留，未将它纳入当前整机的构建入口。
