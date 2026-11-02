# AX7020 鸟类识别与音视融合云台
本仓库以 SSD95 发布版本（历史编号 M51）为基线，包含四麦听声定位、SSD 鸟目标检测、NCC 视觉追踪、鸟种分类、HDMI 显示、网络上位机在线调参，以及 SD 卡按鸟种和日期自动保存照片。

**第一次接触本项目，请从[从零复现文档](reproduce.md)开始。** 它包含软件安装、可复制命令、每步成功判据、硬件匹配、写卡、源码构建和排错。

本轮补齐复现入口、测试数据、构建修复和可追溯证据，原 M51 工作工程未修改。相机使用 M47/M48 原转接板引脚，不使用 M111/M49 的新转接板引脚。开发过程与验证边界见[大模型协作报告](report/llm_collaboration.md)，复用流程见[技能包](skill/readme.md)。
## 目录说明

首次使用建议按“项目说明 → 对应目录说明 → 操作脚本”的顺序阅读。七个顶层目录均有独立导览：[源码](src/readme.md)、[仿真验证](sim/readme.md)、[构建](build/readme.md)、[上板运行](board/readme.md)、[模型数据](data/readme.md)、[技能手册](skill/readme.md)、[设计与验证报告](report/readme.md)。

全部提交路径使用小写英文、数字、下划线或连字符；扩展名用英文点号。说明文件统一使用 `readme.md`，中文只用于文件正文。顶层框架固定，内部按功能组织，无需先了解 M12、M29 等开发阶段编号。

```text
github_pack/
├── readme.md                  # 从这里开始：项目简介与复现步骤
├── reproduce.md               # 零基础逐步操作、成功判据和排错
├── src/                       # 设计源码（详见 src/readme.md）
│   ├── pc/                    # 电脑端：监控界面、预览与在线调参
│   ├── application/           # 板端应用：追踪、对焦、显示、存图及功能生成器
│   ├── services/              # ARM 双核服务
│   │   ├── core0/             # 主核：网络、视频、融合调度与视觉追踪
│   │   └── core1/             # 副核：音频与 SD 写入任务的构建入口
│   ├── platform/              # 公共基础：BSP、双核启动代码、协议和推理运行库
│   ├── audio_features/        # 音频 Log-Mel 特征的板端驱动
│   ├── detector_preprocess/   # SSD 图像预处理的板端驱动
│   └── pl/                    # FPGA 硬件：采集、推理、图像增强、HDMI 与约束
├── sim/                       # 离线仿真与验证脚本、测试数据
├── build/                     # ARM / BOOT / FPGA 构建脚本与实现报告
├── board/                     # 已配套固件、SD 卡模板和上板运行工具
├── data/                      # 模型权重、量化参数与参考样本
├── skill/                     # 项目开发与排障技能手册
└── report/                    # 设计报告、协作记录、来源映射和校验清单
```

### 我想做什么，从哪里开始？

| 目标 | 入口 |
| --- | --- |
| 完全小白，从安装到运行 | [reproduce.md](reproduce.md) |
| 先运行现成固件、连接板卡 | [board/readme.md](board/readme.md) |
| 修改电脑端监控界面 | `src/pc/av_monitor/` |
| 修改追踪、对焦、显示或 SD 存图 | `src/application/software/` 及 `src/application/tools/` |
| 查看双核分工、网络与融合服务 | `src/services/`，基础代码在 `src/platform/` |
| 修改 FPGA 硬件或引脚约束 | [src/pl/readme.md](src/pl/readme.md) |
| 从源码重新生成固件 | 本文“从源码重建 ARM 与 BOOT”，统一从 `build/` 运行 |
| 先做离线验证 | [sim/readme.md](sim/readme.md)、`build/run_checks.py` |
| 理解整体设计与开发经验 | `report/design.md`、[协作报告](report/llm_collaboration.md)、[skill/readme.md](skill/readme.md) |

| 目录 | 内容 |
| --- | --- |
| `src/` | ARM 双核软件、上位机、BSP、持久化 overlay，以及 `pl/` 中实际 RTL/ROM/约束 |
| `sim/` | 存图/FatFs 仿真、协议夹具、推理数值比较、离线验证结果，不访问物理 SD 卡 |
| `build/` | ARM、BOOT、PL 构建脚本、原编译输入摘要和实现报告；生成内容进入 `build/out/` |
| `board/` | 当前配套固件、SD 日期模板、下载及连接工具、标明版本的历史实测证据 |
| `data/models/` | 当前三模型的板端运行权重、量化表、地址和 SHA256 清单；含少量原参考样本 |
| `skill/` | 项目 Zynq 开发与排障手册 |
| `report/` | 设计说明、协作摘要、原版验证证据、来源对照和本包校验清单 |

`src/services/` 是实际参与构建的服务源码与入口。应用构建会将基础服务与 `src/application/tools/` 中的功能生成器组合成最终 C 源码；修改功能时同时检查这两处。`src/**/build/` 保留必要链接脚本和 FSBL（第一阶段启动程序）源码；新生成的编译结果统一进入 `build/out/`。

历史报告中的 Mxx 编号保留作来源追溯，不再用作当前目录名。目录迁移对照和本次验证范围见 `report/directory_reorganization.json`；原有验证报告描述的是整理前的工程导出。

## 最新行为

- 视觉追踪：SSD 鸟目标置信度严格 **>50%**，首次有效鸟目标先交给追踪，再进行鸟种分类。
- 拍照：SSD 鸟目标置信度 **≥95%**，还需有效的同目标视觉鸟种结果、新鲜完整图像和空闲存图槽位。高置信度仍可能误判。
- SD 启动直接进入音视融合；电脑通过千兆网连接上位机，连接过程不重新下载固件或复位板卡。
- 图片为 640×360 整幅画面的 BMP，最多每秒 2 张；不保存原始视频。保持视觉控制优先，忙碌时允许跳过存图。
- 保存路径：`bird_class/<ebird_code>_<yyyy.mm.dd>/1.bmp`、`2.bmp`……。按各目录已有最大编号续存，保留旧照片。
- 日期只读取 SD 卡内 `bird_class/DATE.TXT`，上电时读取一次；没有联网校时或自动跨日更新。
- KEY1 强制开启增强，再按恢复自动；KEY2 强制关闭增强，再按恢复自动；KEY3 关闭自动对焦并固定 280；KEY4 恢复自动对焦。

云台没有编码器。界面的角度、速度和 PWM 表示指令估计，不能当作机械角度或实际速度反馈。网络预览默认上限 2.5 FPS；摄像头采集、HDMI 和 NCC 使用完整采集链路。

## 先校验，再运行

建议把工程解压到短的英文路径。下面是熟悉 Python 的读者使用的简明入口；新手按[复现第 3～4 节](reproduce.md)建立 Python 3.12 虚拟环境并配置原生 GCC。项目代码要求 Python 3.10+，本次实际环境为 Python 3.12.5、GCC 8.1/13.1。

```powershell
python -m pip install -r src/pc/requirements_reproduce.txt
python -B build/verify_package.py
python -B build/run_checks.py
```

测试需要本机原生 GCC/Clang 的 GCC 兼容入口；若未在 PATH 中，设置 `HOST_CC` 为其完整路径。它不是 ARM 交叉编译器。

## SD 启动及电脑调试

已配套固件位于 `board/firmware/boot.bin`。仓库采用小写文件名，复制到 FAT SD 卡后使用 `BOOT.bin`；日期模板 `board/sd_card/bird_class/date.txt` 在卡上使用 `bird_class/DATE.TXT`。

先查看 `board/readme.md` 和工具帮助：

```powershell
python -B board/tools/launch.py --help
```

为新卡准备 `BOOT.bin` 和 `bird_class/DATE.TXT` 两项。日期文件只写一行，例如 `2026.10.29`；请按实际拍摄日期填写，不要直接沿用模板日期。不要删除原卡照片。板卡断电后插卡，按 AX7020 板卡手册设置 SD 启动，再上电。

电脑专用有线网口设为 `192.168.7.1/24`，板端为 `192.168.7.20`。连接千兆网后开启上位机；JTAG USB 可用于只读诊断。网卡配置需要电脑管理员权限。JTAG/SD 写入操作均须由用户显式启动，本包校验和仿真不会操作板卡。

## 从源码重建 ARM 与 BOOT

已发布版本使用 Vivado 2023.2、ARM GNU 6.2.1（Xilinx SDK 2017.4）。2026-11-03 另用 Vitis 2023.2 的 ARM GCC 12.2.0 完整重建双核与 FSBL/BOOT，见[构建回执](build/receipts/arm_rebuild_20261103.json)。保留 BSP 源码和对应静态库；ARM 构建链接已配套 BSP 库，不会隐式重建 BSP。工具链和 Vivado 本身不随包分发。

按本机安装位置设置变量，示例中的路径需要替换：

```powershell
$env:ARM_GNU_BIN = 'c:/xilinx/vitis/2023.2/gnu/aarch32/nt/gcc-arm-none-eabi/bin'
$env:VIVADO_BIN = 'c:/xilinx/vivado/2023.2/bin'
$env:XILINX_SPEC = 'c:/xilinx/vivado/2023.2/data/embeddedsw/scripts/specs/arm/Xilinx.spec'
python -B build/build_firmware.py --core both
python -B build/build_boot.py
```

第一条构建命令把持久化源码与生成器放入隔离目录 `build/out/work`，重新生成 C，再编译 Core0/Core1；不要只修改生成 C。`build_boot.py` 默认用随包已配套 ELF/PL 重新打包，输出 `build/out/boot/boot.bin`；如要使用刚编译的两个 ELF，请显式执行：

```powershell
python -B build/build_boot.py --rebuilt
```

构建命令不写 SD 卡，不会自动替换 `board/firmware/` 中的已发布固件。Core1 的 Xilinx 驱动断言包含 `__FILE__` 字符串，重建路径改变会改变 ELF 的字节；已发布固件保持原始配对版本。

PL 正式重建入口使用当前实际结构 HDL、模块边界源码和精确 IP 配置，使用 Vivado 2023.2 生成官方 IP：

```powershell
New-Item -ItemType Directory -Force -Path build/out | Out-Null
& "$env:VIVADO_BIN\vivado.bat" -mode batch -source build/pl/build_pl.tcl -log build/out/pl_build.log -journal build/out/pl_build.jou
```

旧 BD 导出保留为连线参考：其中一处 AXI 协议元数据不能通过重新验证，因此不将该 BD 当作正式构建入口，也未修改协议参数来绕过检查。正式入口从真实结构源码重新生成 IP 并实现，已补入 Explore 策略。10 月 31 日实际完整构建的默认策略失败、Explore 通过时序，两份结果均保留在[构建证据](build/reports/rebuild_20261031/readme.md)。CDC、I/O 覆盖及普通告警仍需审查；重新实现后必须检查新的报告并另行上板验证。

2026-11-03 本轮完整 PL 构建已产生新 bitstream，WNS=+0.062 ns、WHS=+0.012 ns，详见[本轮综合与实现报告](build/reports/rebuild_20261103/readme.md)。已保留告警与审查结论，没有将时序通过写成整机签核。

## 验证范围与发布

本轮运行存图 37 项、上位机 377 项和 4 个子测试、上板工具 25 项、推理比较器 8 项；存图测试同时在原生 GCC 8.1 与 13.1 通过。最新检查状态、范围、输入哈希和原日志见[离线回执](sim/results/offline_checks_20261103.json)。完整 ARM/BOOT 重建也已完成，8 个分区与 388 项运行模型资产配对校验通过。上述结果不代表模型准确率、机械响应或 SD 冷启动实测。

真实历史模型板测已归档在[board/evidence](board/evidence/readme.md)，包含失败及逐层误差。当前 SSD95 集成固件的实测日志尚待提供并核对；未把历史实验、新编译产物和已发布固件混写成同一次验收。本轮未连接板卡或写物理 SD 卡。原始导出和目录整理报告仍保留原日期与验证范围。

原始封存清单的摘要只用于追溯；本包使用独立的相对路径清单 `report/package_manifest.json` 校验，不依赖开发机历史目录或旧版本工程。导出时清除了重复备份、旧固件、对象文件、缓存、抓拍数据和运行日志。

上传 GitHub 时使用源文件与经审阅的证据；交付 ZIP 使用 `python -B build/export_package.py` 按清单导出，详见[复现第 11 节](reproduce.md)。不要把含缓存的整个工作目录直接压缩。`build/out/`、虚拟环境和运行抓拍不属于提交材料；`.gitattributes` 禁用自动换行转换，使跨机器克隆后的校验值保持一致。当前交付文件均小于 50 MiB。

第三方许可和当前授权信息见 `report/third_party_notices.md`。本包没有擅自为原项目、模型或训练数据授予新的开源许可证。
