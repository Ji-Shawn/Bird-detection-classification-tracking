# 构建导览

本目录从源码生成 ARM 双核程序、BOOT 启动镜像和 FPGA 固件。所有命令从仓库根目录执行；安装、环境变量、成功输出和排错详见[从零复现第 3、7、8 节](../reproduce.md)。下表的 `python` 应使用该文档建立的虚拟环境 Python。

```text
build/
├── readme.md              # 构建入口与输入输出
├── verify_package.py     # 校验随包文件
├── doctor.py             # 检查本机 Python/编译器/工具路径
├── run_checks.py         # 完整离线检查与结果汇总
├── export_package.py     # 按清单导出干净 ZIP
├── build_firmware.py     # 构建 ARM 双核程序
├── build_boot.py         # 打包 BOOT 启动镜像
├── verify_boot.py        # 启动镜像检查工具
├── boot/                 # 启动镜像打包辅助代码
├── pl/                   # FPGA 工程创建、展开与实现脚本
├── metadata/             # 当前包校验清单、来源映射与整理历史
├── receipts/             # 构建回执；package_history/ 保存原始导出与发布回执
├── reports/              # 实现报告；documentation_history/ 保存历史文档审查
└── out/                  # 运行时生成的工作区与结果，不提交 Git
```

| 目标 | 命令或入口 | 输出 |
| --- | --- | --- |
| 校验当前包 | `python -B build/verify_package.py` | 终端中的校验结果 |
| 完整离线检查 | `python -B build/run_checks.py --host-cc <native_gcc_path>` | `build/out/checks/` |
| 重建两个 ARM 核 | `python -B build/build_firmware.py --core both` | `build/out/firmware/` |
| 用随包固件重新打包 BOOT | `python -B build/build_boot.py` | `build/out/boot/boot.bin` |
| 用刚重建的双核程序打包 BOOT | `python -B build/build_boot.py --rebuilt` | `build/out/boot/boot.bin` |
| 重建 FPGA | [pl/readme.md](pl/readme.md) | `build/out/pl/` |

ARM 构建从 `src/application/`、`src/services/`、`src/platform/` 及两个预处理驱动目录读取输入，先在 `build/out/work/` 中生成最终源码。修改源文件和功能生成器，不要只修改输出工作区中的文件。

构建入口不会自动覆盖 `board/firmware/` 中的发布固件或写 SD 卡。目录内的历史报告不代表新构建的验收结果。

## 清单与历史回执从哪里找

| 要核对的内容 | 文件或目录 | 如何理解 |
| --- | --- | --- |
| 当前包的文件身份 | [metadata/package_manifest.json](metadata/package_manifest.json) | `verify_package.py` 使用的当前相对路径与 SHA256 清单；校验通过说明文件与清单一致。 |
| 原始源码与当前路径对应 | [metadata/source_mapping.json](metadata/source_mapping.json) | 用于追溯来源；查找现役源码仍按 `src/` 功能目录。 |
| 目录和 readme 整理历史 | [metadata/history/directory_reorganization.json](metadata/history/directory_reorganization.json)、[readme_update.json](metadata/history/readme_update.json) | 保存整理时的检查范围与结果，不作为当前包清单。 |
| 原始导出验证 | [receipts/package_history/package_validation.json](receipts/package_history/package_validation.json) | 原始导出阶段的总体离线验证。 |
| 原始 ARM、PL 与 BOOT 记录 | [arm_rebuild.json](receipts/package_history/arm_rebuild.json)、[pl_package.json](receipts/package_history/pl_package.json)、[boot_rebuild.json](receipts/package_history/boot_rebuild.json)、[source_boot_rebuild.json](receipts/package_history/source_boot_rebuild.json) | 均位于 `receipts/package_history/`，描述其原运行对象；PL 导出记录不等于重新实现报告。 |
| 原始工具测试与发布封存 | [board_tools_tests.json](receipts/package_history/board_tools_tests.json)、[original_validation.json](receipts/package_history/original_validation.json)、[original_ssd95_tests.json](receipts/package_history/original_ssd95_tests.json)、[original_release_manifest.json](receipts/package_history/original_release_manifest.json) | 均位于 `receipts/package_history/`；保留原判据与限制，原发布清单不能替代 `metadata/package_manifest.json`。 |
| 文档与规范审查 | [reports/documentation_history/readme.md](reports/documentation_history/readme.md) | 汇总历史协作摘要、规范审查和七项文档要求核对。两份正式报告正文在根目录 `report/`。 |

用户补充来源在 [data/collaboration_sources/](../data/collaboration_sources/readme.md)，系统设计和第三方说明在 [src/design.md](../src/design.md)与[src/third_party_notices.md](../src/third_party_notices.md)。本轮测试日志位于 `sim/results/`，已归档的重建证据见下文；自行运行的新输出仍位于 `build/out/`。

2026-11-03 已用 ARM GCC 12.2.0 完整编译双核、FSBL 并重打包 BOOT，8 个分区和 388 项模型资产配对验证通过，见 [本轮 ARM 回执](receipts/arm_rebuild_20261103.json)。此结果不是上板验证。10 月 31 日完整 PL 重建曾默认策略失败、Explore 策略通过时序，见 [原始证据与告警边界](reports/rebuild_20261031/readme.md)。当前入口已包含成功策略，CDC 与 I/O 覆盖等仍须单独审查。

本轮亦已重新完成 PL 综合与实现，时序 WNS=+0.062 ns、WHS=+0.012 ns，记录见 [2026-11-03 PL 证据](reports/rebuild_20261103/readme.md)。新 ARM/BOOT 使用原发布 bitstream；新 PL bit 单独保存，二者没有自动组成已验收的整机新版本。
