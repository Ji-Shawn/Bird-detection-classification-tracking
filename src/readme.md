# 源码导览

先分清运行位置：`pc/` 在电脑上运行；`application/`、`services/`、`platform/` 和两个预处理驱动运行在 Zynq 的 ARM 处理器上；`pl/` 是 FPGA 内的硬件逻辑。

```text
src/
├── readme.md              # 源码总览
├── design.md              # 系统设计与功能说明
├── third_party_notices.md # 第三方来源与授权说明
├── pc/                    # 电脑端监控与调参界面
├── application/           # 当前板端应用与功能生成器
├── services/              # core0 主核服务、core1 副核构建入口
├── platform/              # 双核基础代码、协议、BSP 与推理运行库
├── audio_features/        # 音频特征硬件驱动
├── detector_preprocess/   # 检测预处理硬件驱动
└── pl/                    # FPGA 硬件源码与约束
```

下表中的路径相对于本目录；命令均从仓库根目录执行。返回[项目说明](../readme.md)，或查看[构建导览](../build/readme.md)。

系统功能与软硬件分工见[设计说明](design.md)，第三方来源与授权范围见[来源说明](third_party_notices.md)。

| 目录 | 内容 | 常见修改入口 |
| --- | --- | --- |
| `pc/` | Python 监控界面、图像预览、在线调参 | `av_monitor/`；本轮固定依赖在 `requirements_reproduce.txt`，开发范围在 `requirements.txt` |
| `application/` | 当前板端应用及构建时应用的功能修改 | `software/` 为 C 源码；`tools/` 为构建与功能生成器 |
| `services/core0/` | 主核基础服务：视频 DMA、UDP 网络、融合调度、视觉追踪 | `dma_service.c`、`udp_stream.c`、`fusion_service.c`、`visual_tracker.c` |
| `services/core1/` | 副核构建入口，组合音频、Log-Mel 与 SD 写入源码 | `build_core1.py` |
| `platform/` | 双核基础代码、通信协议、模型运行库、BSP 驱动 | `capture/sdk/`、`capture/shared/`、`runtime/`、`src/` |
| `audio_features/` | Log-Mel 硬件接口的 ARM 驱动、测试和链接辅助工具 | `software/`、`tools/linker.py` |
| `detector_preprocess/` | SSD 硬件预处理的 ARM 驱动与参考实现 | `software/` |
| `pl/` | 硬件逻辑、ROM、IP 配置与约束 | [硬件目录导览](pl/readme.md) |

## 应用如何构建

从仓库根目录运行 `python -B build/build_firmware.py --core both`。统一入口把源码复制到 `build/out/work/`，组合基础 C 源码与 `application/tools/` 中的功能生成器，再编译双核固件，输出到 `build/out/firmware/`。

不要只修改 `build/out/` 中生成的 C 文件：重新构建会覆盖它们。Core0 的生成入口是 `application/tools/build_software.py`，Core1 的入口是 `services/core1/build_core1.py`。安装依赖、设置工具链与 BOOT 打包步骤见[从零复现](../reproduce.md)。本轮双核与 BOOT 实际重建证据见[构建回执](../build/receipts/arm_rebuild_20261103.json)，新固件仍需单独上板。

## 基础目录里的术语

- BSP：板级支持包，包含 Xilinx 驱动、头文件和配套静态库。
- `platform/capture/sdk/core0_network/`：主核网络应用基础代码。
- `platform/capture/sdk/core1_audio/`：副核音频应用基础代码。
- `platform/capture/shared/`：双核共用的协议和接口。
- `platform/runtime/`：模型推理运行库和生成的模型表。
- `platform/build/`：链接脚本；`application/build/fsbl/`：第一阶段启动程序源码及其 BSP。这些目录中的文件是构建输入。
