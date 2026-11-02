# FPGA 硬件目录导览

PL 是 Zynq 芯片里的 FPGA 可编程逻辑部分。软件向硬件配置参数并搬运数据，下面的 RTL 描述硬件如何处理音频、图像和神经网络运算。

```text
src/pl/
├── readme.md              # 硬件模块与源码位置
├── capture_and_inference/ # 音视频采集、控制与神经网络计算引擎
├── logmel/                # 音频特征提取
├── ssd_preprocess/        # 检测图像预处理
├── image_enhancement/     # 直方图与亮度增强
├── hdmi/                  # 显示输出
├── on_screen_display/     # 字体和屏幕信息叠加
├── display_constraints/   # 显示时序与跨时钟域约束
├── board_constraints/     # 板卡引脚约束
├── structural/            # 系统顶层连接
├── ip_config/             # 官方 IP 配置
├── ip_repo/               # 随包 IP 仓库
└── bd/                    # 历史连接参考
```

下表中的路径相对于 `src/pl/`；构建命令从仓库根目录执行。返回[源码导览](../readme.md)。

| 目录 | 作用 |
| --- | --- |
| `capture_and_inference/capture/pl/rtl/audio/` | 四麦接收、波束形成、音频流 |
| `capture_and_inference/capture/pl/rtl/video/` | 摄像头配置、图像采集、视频流 |
| `capture_and_inference/capture/pl/rtl/control/` | 云台控制等控制逻辑 |
| `capture_and_inference/capture/pl/rtl/model/` | 模型数据通路与接口 |
| `capture_and_inference/hardware/` | 神经网络计算引擎、逐点卷积、深度卷积和 MAC 运算模块 |
| `capture_and_inference/capture/vivado/constraints/` | 基础采集约束 |
| `logmel/` | 音频 Log-Mel 特征提取硬件；`rtl/` 为逻辑，`rom/` 为系数表 |
| `ssd_preprocess/` | SSD 检测输入预处理硬件及量化表 |
| `image_enhancement/` | 直方图统计、亮度增强和相关时序约束 |
| `hdmi/` | HDMI 扫描输出与约束 |
| `on_screen_display/` | 屏幕文字叠加、字体 ROM 及相关约束 |
| `display_constraints/` | 显示时钟及跨时钟域约束 |
| `board_constraints/` | 相机转接板引脚与四个按键约束 |
| `structural/` | 系统顶层及连接各模块的 HDL |
| `ip_config/` | Vivado 官方 IP 的精确配置 |
| `ip_repo/` | 随包提供的 IP 仓库 |
| `bd/` | 历史 Block Design 连线参考 |

从仓库根目录使用 `build/pl/create_project.tcl` 创建工程，使用 `build/pl/build_pl.tcl` 构建。详细步骤与验证限制见 [build/pl/readme.md](../../build/pl/readme.md)。

原报告保留开发时的阶段名，当前目录对照见 `report/directory_reorganization.json`。目录整理不会改变 RTL、ROM、IP 配置或引脚约束内容；正式重新实现后的固件仍需独立检查时序并上板验证。

2026-11-03 从这些输入完成了新的综合与实现，详见[本轮报告](../../build/reports/rebuild_20261103/readme.md)。资源与时序数据描述该轮产物；CDC、I/O 覆盖等待处理项同时保留，不据此声称完成物理板卡验收。
