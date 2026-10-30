# 构建导览

本目录从源码生成 ARM 双核程序、BOOT 启动镜像和 FPGA 固件。所有命令从仓库根目录执行；工具链安装和环境变量见[项目说明](../readme.md)。

```text
build/
├── readme.md              # 构建入口与输入输出
├── verify_package.py     # 校验随包文件
├── build_firmware.py     # 构建 ARM 双核程序
├── build_boot.py         # 打包 BOOT 启动镜像
├── verify_boot.py        # 启动镜像检查工具
├── boot/                 # 启动镜像打包辅助代码
├── pl/                   # FPGA 工程创建、展开与实现脚本
├── receipts/             # 原发布版本的编译输入记录
├── reports/              # 原发布实现及导出检查报告
└── out/                  # 运行时生成的工作区与结果，不提交 Git
```

| 目标 | 命令或入口 | 输出 |
| --- | --- | --- |
| 校验当前包 | `python -B build/verify_package.py` | 终端中的校验结果 |
| 重建两个 ARM 核 | `python -B build/build_firmware.py --core both` | `build/out/firmware/` |
| 用随包固件重新打包 BOOT | `python -B build/build_boot.py` | `build/out/boot/boot.bin` |
| 用刚重建的双核程序打包 BOOT | `python -B build/build_boot.py --rebuilt` | `build/out/boot/boot.bin` |
| 重建 FPGA | [pl/readme.md](pl/readme.md) | `build/out/pl/` |

ARM 构建从 `src/application/`、`src/services/`、`src/platform/` 及两个预处理驱动目录读取输入，先在 `build/out/work/` 中生成最终源码。修改源文件和功能生成器，不要只修改输出工作区中的文件。

构建入口不会自动覆盖 `board/firmware/` 中的发布固件或写 SD 卡。目录内的历史报告不代表新构建的验收结果；当前目录迁移与验证范围见 `report/directory_reorganization.json`。
