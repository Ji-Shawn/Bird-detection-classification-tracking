# 从零复现：AX7020 鸟类识别与音视融合云台

本文面向第一次接触 FPGA 项目的读者。请按顺序操作，每节都有“看到什么才算成功”。本文的命令面向 Windows 10/11 64 位 PowerShell；其他系统的完整构建尚未验收。更新日期：2026-11-03。

本轮已建立全新 Python 环境，把候选交付 ZIP 解压到另一目录，再次运行完整离线检查并全部通过，记录见[迁移复现回执](sim/results/relocation_20261103.json)。这验证了文档的离线步骤和包内依赖关系；真实硬件步骤仍需使用匹配接线与现场记录验收。

## 1. 先选自己的目标

| 目标 | 做哪些章节 | 需要什么 |
| --- | --- | --- |
| 没有板卡，先确认工程包完整、测试能运行 | 第 2～4 节 | Windows 电脑、Python、原生 GCC |
| 有配套硬件，先运行已经发布的系统 | 第 2～6 节 | 上述环境、AX7020、配套相机/转接板、四麦、云台、SD 卡和网线 |
| 修改 ARM 程序并重新生成启动镜像 | 再做第 7 节 | Vitis/Vivado 2023.2 的工具和安装空间 |
| 修改 FPGA 逻辑并重新实现 | 再做第 8 节 | Vivado 2023.2、对应器件支持和许可 |
| 学习模型结构、准备数据或重新训练 | 第 12 节及模型构建说明 | 独立模型环境；训练还需数据集和足够算力 |
| 准备比赛交付 | 第 9～11 节 | 验证结果、真实实测证据 |

先完成没有硬件的检查，再连接板卡。文件校验通过说明文件完整；离线测试通过说明指定测试范围内行为正确；完整编译通过说明能产生可执行产物。板卡现场识别效果、冷启动、SD 延迟和机械运动仍要通过第 9 节验证。

## 2. 把项目放到正确的位置

1. 把交付 ZIP 解压到 `D:\bird_demo\github_pack`。可以换盘，但工程路径用短的英文、数字或下划线，不要放入中文或含空格的目录。
2. 打开该文件夹，应直接看到 `readme.md`、`src`、`sim`、`build`、`board`、`data`、`skill`、`report`。如果里面还有一层 `github_pack`，继续进入那一层。
3. 在文件夹空白处右键，选择“在终端中打开”，打开 PowerShell。也可从开始菜单打开 PowerShell，然后执行：

```powershell
Set-Location 'D:\bird_demo\github_pack'
Get-Location
Test-Path .\build\verify_package.py
```

最后一行应为 `True`。下文所有 PowerShell 命令均在这个根目录运行。代码框里的命令逐行复制，不要把解释文字或终端前面的 `PS D:\...>` 一起复制。

### 术语只需先记住这几个

- **PS / ARM**：板上运行 C 程序的处理器，分 Core0 和 Core1。
- **PL / FPGA**：板上的可编程逻辑，负责采集与部分计算。
- **ELF**：ARM 可执行程序。
- **BIT**：FPGA 配置文件。
- **BOOT.bin**：把启动程序、FPGA 配置、双核程序、模型等装在一起的 SD 启动镜像。
- **BSP**：板级驱动库；**FSBL**：上电时首先执行的初始化程序。
- **上位机**：电脑上的监控界面，源码在 `src/pc/`。

## 3. 安装 Python 并建立独立环境

本次离线检查使用 CPython 3.12.5。建议使用 Python 3.12 系列的 64 位完整安装包，包含 pip 和 Tcl/Tk；不要选嵌入式压缩包。可从 [Python 官方 Windows 下载页面](https://www.python.org/downloads/windows/) 获取安装程序。安装时勾选 pip、Tcl/Tk 和 Python Launcher；安装后重新打开 PowerShell。

```powershell
py -3.12 --version
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r src/pc/requirements_reproduce.txt
.\.venv\Scripts\python.exe -B build/doctor.py --profile pc
```

这里不需要执行 `Activate.ps1`，因此不会因为 PowerShell 的脚本执行策略而卡住。后文固定使用 `.\.venv\Scripts\python.exe`，避免依赖被安装到另一个 Python。

**成功判据**：最后的 JSON 中 `status` 为 `pass`，numpy、PIL、tkinter、tcl 均通过。`requirements_reproduce.txt` 固定了本次测试的依赖版本；`requirements.txt` 是较宽松的开发依赖范围。

如果 `py` 不存在，使用 Python 安装程序修复安装并启用 Launcher，或把 `py -3.12` 替换成你安装的 `python.exe` 完整路径。不要用 ARM GCC 来代替 Python。

## 4. 不连接板卡，先完成离线验证

### 4.1 校验文件和启动镜像

```powershell
.\.venv\Scripts\python.exe -B build/verify_package.py
.\.venv\Scripts\python.exe -B build/verify_boot.py
```

**成功判据**：分别出现 `M51_PORTABLE_PACKAGE_PASS` 和 `M51_PORTABLE_BOOT_PASS`。旧版本代号保留在机器可读标记里。BOOT 检查应报告 8 个分区、388 项运行模型资产。

若提示 `Package file changed`，先记下报错路径，与原交付包比较。不要通过自行改 SHA256 清单来掩盖文件缺失或损坏。修改源码后的开发检查见第 7 节。

### 4.2 准备原生 GCC

原生 GCC 生成电脑上运行的测试程序；ARM GCC 生成板上程序，两者用途不同。已验证的原生编译器为 MinGW GCC 8.1 和 13.1。

若已有 Qt/MinGW 或 Vivado 配套 MinGW，找到其 `bin/gcc.exe` 即可。没有时可以按 [MSYS2 官方入门说明](https://www.msys2.org/)安装 MSYS2，在其 **UCRT64** 窗口运行下面这一条命令（不是在 PowerShell 运行）：

```bash
pacman -S mingw-w64-ucrt-x86_64-gcc
```

安装完成回到 PowerShell。官方软件源会更新 GCC，新版本须以下面的实际测试结果为准；本包不会把未测试版本写成已验证。按你的安装位置设置：

```powershell
$env:HOST_CC = 'C:\msys64\ucrt64\bin\gcc.exe'
$env:PATH = (Split-Path $env:HOST_CC) + ';' + $env:PATH
Test-Path $env:HOST_CC
& $env:HOST_CC --version
.\.venv\Scripts\python.exe -B build/doctor.py --profile offline
```

使用已有 MinGW 时，只替换第一行的路径。`Test-Path` 应为 `True`，doctor 应为 `pass`。这些环境变量只作用于当前终端；新开终端后需要重新设置。

### 4.3 运行完整离线检查

```powershell
.\.venv\Scripts\python.exe -B build/run_checks.py --host-cc $env:HOST_CC
```

它依次检查包完整性、BOOT 配对、存图逻辑、上位机协议与界面逻辑、上板工具模拟行为，以及推理结果比较器。没有真实 JTAG 下载或 SD 卡写入。

当前预期：存图 **37 项**通过；上位机 **377 项及 4 个子测试**通过；上板工具 **25 项**通过；比较器 **8 项**通过。最终状态应为 `pass`，详细结果在 `build/out/checks/`。比较器的自测使用合成变化检查判定逻辑，不是一次模型推理或板测。

如果失败，打开该目录中对应阶段的日志。不要忽略失败继续声称“全部复现成功”。

## 5. 使用发布固件启动板卡

### 5.1 硬件必须匹配

本包固定为 AX7020、器件 `xc7z020clg400-2`、OV5640 摄像头及原发布转接板引脚。旧记录把相机接法称为 M47/M48；它和 M111/M49 新转接板接法不同，不能仅凭“都是 OV5640”混用。

请准备：匹配的 AX7020 电源、已验证的相机与转接板、四麦前端、匹配供电与接线的舵机云台、FAT16/FAT32 SD 卡与读卡器、电脑专用有线网口、网线。HDMI 显示器和 USB JTAG 是显示/诊断工具，可按需要接入。

**接线以板厂资料、你的转接板原理图和随包引脚表共同核对**：引脚表在 [build/reports/pl_pins.tsv](build/reports/pl_pins.tsv)，相机约束在 [camera_adapter](src/pl/board_constraints/camera_adapter/j11_adapter.xdc)。表中封装引脚不是插座排针编号；本文没有把未知转接板接线猜成通用接法。接线和插拔 SD 卡前先断电。云台首次运行要有活动空间，避免堵转。

### 5.2 给新 SD 卡准备文件

先在电脑资源管理器确认 SD 卡盘符。以下假设是 `E:`，必须按实际替换；**不要照抄到系统盘**。SD 卡须已有 FAT16/FAT32 文件系统；脚本不会格式化，也不会清空已有照片。

先预览：

```powershell
.\.venv\Scripts\python.exe -B board/tools/launch.py write-sd --sd-root E:/
```

核对输出中的盘符、卷信息和写入计划，确认是你的 SD 卡后再执行：

```powershell
.\.venv\Scripts\python.exe -B board/tools/launch.py write-sd --sd-root E:/ --write
```

成功输出应包含 `written: true`、`readback_verified: true`。备份在 `build/out/board/card_backup_*/`。已有日期文件会被保留。

某些读卡器被 Windows 识别为固定磁盘，自动写卡工具会拒绝。这时从资源管理器手动复制：

| 包内文件 | SD 卡位置 |
| --- | --- |
| `board/firmware/boot.bin` | SD 根目录 `BOOT.bin` |
| `board/sd_card/bird_class/date.txt` | `bird_class/DATE.TXT`，仅在新卡没有该文件时复制 |

仓库文件小写；卡内启动文件和日期文件使用上述固件要求的名字。

用记事本编辑卡内 `bird_class/DATE.TXT`，只保留一行实际拍摄日期，例如 `2026.11.03`。保存为纯 ASCII 或无 BOM 的 UTF-8，避免变成 `DATE.TXT.txt`；可在资源管理器打开“文件扩展名”检查。不要删除已有照片。日期仅在上电时读取，不自动联网校时，也不自动跨日更新。

安全弹出 SD 卡。板卡断电状态下插卡，按 AX7020 手册设置 SD 启动模式，然后上电。不要用其他 Zynq 板的拨码位置推测本板设置。

### 5.3 配置电脑网口并打开界面

本系统板端固定 `192.168.7.20`；电脑使用 `192.168.7.1`，子网掩码 `255.255.255.0`。建议使用单独的 USB 千兆网卡直连板卡，以免修改办公网络。

1. Windows 设置 → 网络和 Internet → 高级网络设置 → 找到实际连接板卡的以太网适配器。
2. 编辑 IPv4，手动设置 IP `192.168.7.1`、掩码 `255.255.255.0`；直连网口不需要网关和 DNS。
3. 在 PowerShell 执行 `ipconfig`，确认改的是该网卡。
4. 接好网线并等待板卡启动，运行：

```powershell
.\.venv\Scripts\python.exe -B board/tools/launch.py monitor
```

Windows 若询问是否允许 Python 通过防火墙，请允许用于板卡直连的网络，不需要关闭整个防火墙。端口被占用时先关闭旧监控窗口。

**成功判据**：监控窗口打开后能持续收到新的板端状态和图像/计数；不要把“窗口能打开”当成“板卡已连接”。SD 模式启动后进入音视融合。没有鸟声或鸟目标时，可以没有有效识别结果；这与网络故障不同。

关闭窗口只断开这次监控连接。在线调参保存在 RAM，重新上电恢复固件默认值。电脑预览默认上限 2.5 FPS，并不代表摄像头或 HDMI 只有同样帧率。

## 6. 验收基本功能

| 操作 | 应观察到的行为 | 证据应保存什么 |
| --- | --- | --- |
| 网络连接 | 状态持续更新、图像计数前进 | 监控日志和时间范围 |
| KEY1 / KEY2 | 强制开启/关闭增强，再按恢复自动 | 操作前后相同场景的记录 |
| KEY3 / KEY4 | 固定对焦码值 280 / 恢复自动对焦 | 按键操作与显示结果 |
| 鸟目标出现 | SSD 分数严格大于 50% 才进入对应正式目标选择条件 | 带时间戳的识别与追踪结果 |
| 符合存图资格 | SSD≥95%，且同目标鸟种有效、图像新鲜、日期有效、槽位可用时保存 | 原始 BMP、日期目录、识别日志 |
| 重启续存 | 已有照片保留，编号从目录最大编号继续 | 重启前后目录清单 |

不能只拿“没有生成照片”判定存图损坏：SSD 门槛、鸟种标签、时间新鲜度、日期文件和队列状态都影响存图。最高每秒两张是限速，不保证每秒一定两张。当前系统没有编码器，界面角度和 PWM 是控制指令，不能当作实测机械角度。

输出目录为 `bird_class/<ebird_code>_<yyyy.mm.dd>/1.bmp` 等，BMP 为 640×360。不要把95% SSD分数直接当成95%真实准确率。

如需只读 JTAG 诊断，先设置第 7 节的 `VIVADO_BIN`，执行：

```powershell
.\.venv\Scripts\python.exe -B board/tools/launch.py sdcheck
```

该命令读取启动与帧计数。`program --program` 会复位并重新下载，属于另一项操作；初次 SD 复现无需执行它。

## 7. 从源码重新编译 ARM 和 BOOT

仅运行发布固件可跳过本节。原发布双核使用 ARM GNU 6.2.1；本次另在 Vitis 2023.2 的 ARM GCC 12.2.0 下完整构建并校验。更换编译器或路径会改变 ELF/BOOT 哈希，不要求与旧发布镜像逐字节相同。新固件仍需单独上板验收。

安装 AMD Vivado/Vitis **2023.2**，包含 Zynq-7000/xc7z020 器件支持、ARM 工具链、嵌入式软件和下载驱动。到 [AMD 官方开发工具下载页面](https://www.amd.com/en/support/downloads/adaptive-socs-and-fpgas/development-tools/2026-1.html) 的历史版本入口选择 2023.2，不要把页面默认新版当成本文验证版本。

以下以安装到 `D:\Xilinx` 为例，按你电脑的实际安装目录替换：

```powershell
$env:VIVADO_BIN = 'D:\Xilinx\Vivado\2023.2\bin'
$env:ARM_GNU_BIN = 'D:\Xilinx\Vitis\2023.2\gnu\aarch32\nt\gcc-arm-none-eabi\bin'
$env:XILINX_SPEC = 'D:\Xilinx\Vivado\2023.2\data\embeddedsw\scripts\specs\arm\Xilinx.spec'
.\.venv\Scripts\python.exe -B build/doctor.py --profile arm
.\.venv\Scripts\python.exe -B build/build_firmware.py --core both
.\.venv\Scripts\python.exe -B build/build_boot.py --rebuilt
```

**成功判据**：看到 `core0 built`、`core1 built`；BOOT 阶段看到 `M51_PORTABLE_BOOT_PASS`。产物分别在 `build/out/firmware/` 与 `build/out/boot/boot.bin`。编译失败看 `build/out/firmware/core0_build.log` 或 `core1_build.log`，不要把旧 ELF 的存在当作本轮成功。

`build/build_boot.py` 不带 `--rebuilt` 时打包随包发布 ELF；带 `--rebuilt` 才使用新编译的两个 ELF。它不会替换 `board/firmware/`，也不会写入 SD 卡。发布版写卡工具固定校验发布镜像，因此不会自动写入你的重编版本；重编版本须在明确选择该产物并完成备份后单独部署。

修改源码应修改 `src/` 里的 C/H 或 `src/application/tools/` 中的功能生成器，不能只改 `build/out/work/`。生成器会重新产生最终 C 文件。开发期间可运行：

```powershell
.\.venv\Scripts\python.exe -B build/run_checks.py --skip-package --host-cc $env:HOST_CC
```

输出会明确为部分检查；只有重新整理并核验发布清单后才可交付为完整包。

## 8. 从源码重新构建 FPGA

先完成第 7 节的 Vivado 2023.2 安装，无需先编译 ARM。新开终端时重新设置 `VIVADO_BIN`；路径按实际安装位置替换：

```powershell
$env:VIVADO_BIN = 'D:\Xilinx\Vivado\2023.2\bin'
.\.venv\Scripts\python.exe -B build/doctor.py --profile pl
New-Item -ItemType Directory -Force -Path build/out | Out-Null
& "$env:VIVADO_BIN\vivado.bat" -mode batch -source build/pl/build_pl.tcl -log build/out/pl_build.log -journal build/out/pl_build.jou
```

脚本会从包内 RTL、ROM、精确 IP 配置和约束重新创建工程，执行综合、布局、布线、物理优化并生成 `build/out/pl/adapter_system.bit`。过程可能较长；不要因界面暂时无输出而反复启动多份构建。

当前入口已采用10月31日成功记录中的 Explore 布局布线策略，保留时序和布线检查。此前默认策略曾 WNS=-0.073 ns，不能把同源码的旧正时序报告当作新实现的结果。证据见 [完整构建记录](build/reports/rebuild_20261031/readme.md)。

2026-11-03 已再次从源码完成综合与实现，WNS=+0.062 ns、WHS=+0.012 ns，生成新 bitstream；[本轮报告](build/reports/rebuild_20261103/readme.md)保留输入指纹、原始日志及待审查项。不同次实现不要求 bitstream 字节相同。

**成功判据分两层**：脚本完成并打印 `PL_IMPLEMENTATION_TIMING_PASS`，说明其构建和时序门槛通过；还需查看 CDC、I/O 延时覆盖和方法学报告，说明待处理项，最后再上板。当前历史报告中存在未闭合告警，不能写“所有工程检查全绿”。详细处置边界见 [build/pl/readme.md](build/pl/readme.md)。

脚本输出 BIT，不自动产生一套新 XSA/BOOT。改变 PS 外设、地址映射或相机接线时，旧 XSA 和 FSBL 不能继续当作新硬件验收产物。不要套用通用 PS preset 覆盖本项目已经确认的 DDR/MIO 配置。

## 9. 留下能被别人核对的实测证据

监控入口自动把真实接收记录写入 `build/out/board/recognition_results.jsonl`，把监控指标写入 `monitor_metrics.json`。测试结束后保留这些原始文件，同时记录开始/结束时间、设备接法、软件版本和固件 SHA256。不要编辑原始日志内容来消除失败。

```powershell
Get-FileHash board/firmware/boot.bin -Algorithm SHA256
```

该命令记录的是准备部署的文件；还应记录实际写卡和启动过程，不能只凭这条哈希证明板上正在运行同一文件。

每次至少记录：测试目标、输入来源、场景条件、实际结果、参考结果、通过标准、失败样本、固件/模型标识、原始日志路径。分类准确率要说明样本和标注；性能要说明是否包含采集、传输、预处理及推理。历史板测在 [board/evidence](board/evidence/readme.md)，其不同样本或固件的结果不能替代你这一轮的实测。

对包内三个固定输入做数值对拍，请使用 [样本与观察格式](data/models/samples/readme.md)和 `sim/compare_inference.py`。该工具需要独立采集的完整 logits/检测框，普通监控日志的概率或 top1 不等于这些原始数值。没有对应输入与原始输出时，保留“待验证”，不要复制 `expected.json` 充当实际输出。

## 10. 常见故障先查哪里

| 现象 | 优先检查 | 下一步 |
| --- | --- | --- |
| 找不到脚本 | `Test-Path .\build\verify_package.py` | 回到真正的仓库根目录 |
| `No module named ...` | 是否使用同一个 `.venv` Python 安装与运行 | 重做第3节依赖安装 |
| Tcl/Tk 导入失败 | 是否用了嵌入式 Python 或精简安装 | 用完整安装程序补装 Tcl/Tk |
| GCC找不到或缺 DLL | `HOST_CC` 和其 `bin` 是否加入当前 PATH | 重做4.2，不能指向 ARM 编译器 |
| 包校验失败 | 是否修改/遗漏了文件 | 用原交付副本对照，不盲改清单 |
| UI能开但无数据 | 网卡IP、网线、板卡启动、电源、防火墙、旧进程占端口 | 逐项核对，保存状态输出 |
| 无照片 | DATE.TXT、目标分数、同目标鸟种结果、新鲜度和SD状态 | 按6节逐项记录，不降低门槛掩盖问题 |
| 图像正常但云台不动 | 工作模式、控制权、舵机供电及接线 | 不把指令角度当成真实位置反馈 |
| `Timing failed` | 本轮 timing.rpt | 停止采用该轮产物，保留失败报告 |
| CDC返回 `review_required` | 对应端点、同步结构、例外约束 | 查技能包处置流程，不能自动豁免 |

## 11. 导出干净交付包

完成源码、文档和证据整理并更新发布清单后执行：

```powershell
.\.venv\Scripts\python.exe -B build/export_package.py --output build/out/github_pack_delivery.zip
```

这个入口按已校验清单导出，排除 `.git/`、`.venv/` 和 `build/out/`。如果 ZIP 已存在，换一个文件名保存，避免覆盖已有交付。不要直接把含缓存的整个工作目录压缩提交。

压缩包解压后，先从第 3 节为新目录建立 `.venv` 并安装依赖，再按第 4 节重新设置 `HOST_CC` 和运行检查，确认换路径仍可通过。虚拟环境不随 ZIP 分发。提交材料可从[项目总览](readme.md)、[大模型协作报告](report/llm_collaboration.md)、[技能包入口](skill/readme.md)进入。尚未拿到真实当前版本证据的测试项，应在提交前补齐并保留原始记录。

## 12. 构建、训练和评估模型

模型代码在 `src/modeling/`，整理自项目的 CoordinateNet 演化仓库。现在可在本包中查看音频分类、图像分类和鸟目标检测的定义，执行数据准备、训练与评估，不再依赖原作者电脑上的源码目录。

先打开[模型构建说明](src/modeling/readme.md)，按其中步骤建立独立模型环境和安装依赖。第 3 节的上位机环境不包含完整的模型训练依赖。完成安装后，从仓库根目录执行以下两条命令；`python` 必须是刚建好的模型环境中的 Python：

```powershell
python -B build/build_models.py --help
python -B build/build_models.py selftest
```

第一条应列出数据准备、分类、检测和自检入口。第二条检查模型是否能构建并处理测试输入，不下载预训练权重，也不启动正式训练。具体成功标记、训练命令、所需数据目录和每步产物见模型构建说明。模型权重、处理后的数据和评估输出默认进入 `build/out/modeling/`，不需要放进 `src/`。

**复现已有板端系统**与**重新训练模型**应分别验收。已有系统使用 `data/models/` 中配套的 INT8 资产；新训练得到的 FP32 检查点还需要导出、量化、板端格式转换以及数值对拍。当前资产来源、历史量化模板依赖和可重建范围见[模型部署说明](src/modeling/deployment.md)。不要把新 `.pt` 文件改名后直接替换 `.bin`，也不要认为训练结束就获得了已验收的板端模型。
