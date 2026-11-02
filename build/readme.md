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
├── receipts/             # 原发布及本轮 ARM/BOOT 编译输入记录
├── reports/              # 原发布实现、历史重建及新构建报告
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

2026-11-03 已用 ARM GCC 12.2.0 完整编译双核、FSBL 并重打包 BOOT，8 个分区和 388 项模型资产配对验证通过，见 [本轮 ARM 回执](receipts/arm_rebuild_20261103.json)。此结果不是上板验证。10 月 31 日完整 PL 重建曾默认策略失败、Explore 策略通过时序，见 [原始证据与告警边界](reports/rebuild_20261031/readme.md)。当前入口已包含成功策略，CDC 与 I/O 覆盖等仍须单独审查。

本轮亦已重新完成 PL 综合与实现，时序 WNS=+0.062 ns、WHS=+0.012 ns，记录见 [2026-11-03 PL 证据](reports/rebuild_20261103/readme.md)。新 ARM/BOOT 使用原发布 bitstream；新 PL bit 单独保存，二者没有自动组成已验收的整机新版本。
