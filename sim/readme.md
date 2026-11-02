# 仿真与验证导览

这里说明每组检查验证什么、如何运行和如何判断成功。所有命令从仓库根目录执行，即能看到 `src/`、`build/`、`sim/` 的那一级。

```text
sim/
├── readme.md              # 检查范围、命令与成功判据
├── run_tests.py           # 37 项存图门槛和实际 FatFs 集成用例
├── compare_inference.py   # 实际推理输出与参考值比较
├── test_inference_comparison.py # 对比器自身的 8 项边界测试
├── archive/               # 存图测试的 C 源码
├── fixtures/
│   ├── card_vbr.bin       # 文件系统测试用启动扇区
│   └── protocol/          # 固定 AVP1 协议报文及来源/哈希清单
├── board_tools/           # 25 项 CLI、Tcl 模拟及写卡临时目录测试
└── results/               # 已保存的离线验证记录；新运行结果进入 build/out/
```

## 一次运行离线检查

准备 Python 3.10 或更新版本（包含 tkinter）、原生 GCC 兼容编译器，再安装依赖。Windows 下优先使用已安装的 MinGW-w64；这里的编译器用于电脑上的 C 测试，不能用 `arm-none-eabi-gcc` 替代。2026-11-03 实际验证了 GCC 8.1.0 和 13.1.0。

第一次运行请先按[从零复现第 3～4 节](../reproduce.md)建立环境。下文的 `python` 均应使用同一个解释器；按该文档创建虚拟环境后，将它替换为 `.\.venv\Scripts\python.exe`，不需要激活环境。

```powershell
python -m pip install -r src/pc/requirements_reproduce.txt
# 把下面的路径改为你自己的原生 gcc.exe 所在位置。
$env:HOST_CC = 'c:/tools/mingw64/bin/gcc.exe'
python -B build/run_checks.py
```

也可以用 `python -B build/run_checks.py --host-cc 'c:/tools/mingw64/bin/gcc.exe'` 显式指定。脚本会记录实际 Python、依赖和 GCC 版本，不会默默跳过缺失的依赖。

成功时最后一行是 `OFFLINE_CHECKS_PASS build/out/checks/results.json`，进程退出码为 0。打开 `build/out/checks/results.json`，六组检查的 `status` 应均为 `pass`；每组的日志路径也在其中。失败时最后一行含 `FAIL`，退出码非 0，先看对应日志，不要只看之前保留的测试记录。

默认执行包校验、BOOT 分区检查、存图测试、推理对比器自测、全部上位机单元测试、上板工具模拟测试。运行中不会连接板卡、调用实际 JTAG 下载或写入物理 SD 卡。

如果主动修改了源码或说明，发布哈希清单会与文件不一致。开发过程中可用 `--skip-package` 继续检查功能；此时结果明确标记 `pass_partial`，不能当作最终交付校验通过。最终发布应重新生成并独立核对清单，再去掉该选项重跑。

## 单独运行和成功判据

| 目的 | 命令 | 成功判据与输出 |
| --- | --- | --- |
| 包完整性 | `python -B build/verify_package.py` | `M51_PORTABLE_PACKAGE_PASS`；核对文件与模型清单 |
| BOOT 内容配套 | `python -B build/verify_boot.py` | `M51_PORTABLE_BOOT_PASS`；8 个分区、388 项运行资产，结果在 `build/out/boot_verify.json` |
| 存图策略与真实 FatFs 集成 | `python -B sim/run_tests.py` | `M51_SSD95_RECORD_NATIVE_PASS 37 cases`；`build/out/tests/results.json` |
| 推理对比器边界测试 | `python -B sim/test_inference_comparison.py` | 8 项 unittest 通过；验证比较逻辑，不代表已完成实际推理 |
| 上位机完整单元测试 | `python -B -m pytest src/pc/tests -q` | 所有测试通过；修复后本次为 377 项通过，另有 4 个子测试通过 |
| 上板工具离线行为 | `python -B sim/board_tools/run_tests.py` | `M51_BOARD_TOOLS_OFFLINE_PASS 25 cases`；`build/out/board_tools_tests.json` |

输出标记中的 M51 是保留的固件版本标识，目录已经按功能组织。

## 本轮实际验证记录

2026-11-03 在新建的 Python 3.12.5 虚拟环境中，使用原生 GCC 13.1.0 完成了包含包完整性检查的六组完整运行，[最终离线回执](results/offline_checks_20261103.json)为 `pass`。存图 37 项、比较器 8 项、上位机 377 项和 4 个子测试、上板工具 25 项全部通过；BOOT 核验为 8 个分区、388 项运行资产。PC JUnit 的 381 项计数包含这 4 个子测试，不能再次相加。

回执中的 `archived_log`、`archived_detail` 和 `archived_junit` 指向这次运行的 `new_full_20261103` 文件；[归档来源清单](results/offline_checks_archive_20261103.json)记录原始文件与归档文件的 SHA256、脱敏规则和分项关联。113 个被测源码与夹具指纹在归档时再次核对一致。[环境核验](results/python_environment_new_full_20261103.json)记录同一新环境的解释器和依赖版本，明确其采集时间为运行完成后的归档阶段。

此前跳过包校验的[开发阶段快照](results/offline_checks_development_20261103.json)保留为 `pass_partial`，其旧日志没有替换成新运行结果。单独的 [GCC 8.1 记录](results/native_gcc8_20261103.json)和早期 GCC 13.1 记录同样保留，不能与本轮完整运行混为一次。

完整运行中的包校验对应当时的清单，日志记录 2605 个文件、391 项模型资产。将这些回执纳入交付包后，文件数和清单会变化，发布时还须刷新清单并再次独立核验包完整性；不能要求回执预先包含它自身最终哈希。这些离线结果均不表示完成了当前固件的上板验收。

## 各项测试能证明什么

- 存图测试编译 `src/application/software/` 的实际生产者、写入器与 FatFs 源码，检查 SSD 置信度边界、分类身份及时效、图像完整性和写入协调；包含 5 项实际生产者到 FatFs 的集成用例。它用模拟磁盘，不测真实 SD 卡速度、掉电可靠性或模型准确率。
- 上位机测试覆盖协议、数据重组、图像预览、识别结果和界面策略。协议测试读取 `sim/fixtures/protocol/` 的固定报文，缺少任何规定文件都会失败。7 个原始报文从原 SDK 测试集逐字节复制，另加 2 个独立计算 CRC 的非法分片报文，避免只因 CRC 错误而漏测分片边界；来源及 SHA256 见该目录的 `provenance.json`。
- 上板工具测试替换硬件命令，并用电脑临时目录模拟写卡。它验证工具的操作逻辑，不证明真实 JTAG、SD 冷启动、摄像头、四麦或云台已在本次验证中通过。
- 包哈希和 BOOT 检查只确认文件完整性、固件配套和镜像结构。主要推理功能需要实际输出与模型参考结果比较；系统性能还需要真实上板测量。

实际推理数据的格式、样本来源和比较方法见 [data/models/samples/readme.md](../data/models/samples/readme.md)。对比器自测使用明确标记的测试数据验证成功与失败分支，不会把参考结果直接当作板端实际结果来出具通过结论。

## 常见问题

| 现象 | 处理方法 |
| --- | --- |
| 找不到 pytest、numpy 或 Pillow | 用运行测试的同一个 `python` 执行上面的 `python -m pip install` |
| 找不到 gcc 或提示 HOST_CC 无效 | 用 `& $env:HOST_CC --version` 检查路径；必须指向完整可执行文件 |
| 测试启动时缺少 DLL | 保留完整 MinGW 安装目录；统一检查入口会把编译器的 `bin` 加到子进程 PATH |
| `Package file changed` | 文件与发布清单不一致；重新取得未改动的发布包，或在开发时显式使用 `--skip-package` |
| 协议黄金文件缺失 | 恢复 `sim/fixtures/protocol/`，不要删除测试或用当前解码器临时生成“期望值” |
| 电脑测试全绿，但板卡仍无输出 | 按 [board/readme.md](../board/readme.md) 排查实际连接和启动；离线通过不能代替上板验收 |

详细上板工具测试说明见 [board_tools/readme.md](board_tools/readme.md)，构建与验证证据见[构建导览](../build/readme.md)，过去的目录审查记录见[历史审查文档](../build/reports/documentation_history/readme.md)。

技能方法迁移的补充案例见 [CRC32 独立原型归档](evidence/crc_method_reuse_20261014/readme.md)：历史 XSim 完成 3042 包对拍，本轮只核验并重建黄金向量，没有重新运行 RTL 或集成到当前固件。该案例独立于上述完整离线套件，不能计入当前 SSD95 整机板测。
