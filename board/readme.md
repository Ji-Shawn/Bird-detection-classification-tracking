# 上板与运行导览

本目录用于把配套固件运行在 AX7020 板卡上。第一次使用请按[从零复现第 2～6 节](../reproduce.md)准备环境、写卡和验收；下面是简明命令索引。需要改源码时查看[源码导览](../src/readme.md)，重新构建查看[构建导览](../build/readme.md)。

```text
board/
├── readme.md              # 上板与连接步骤
├── firmware/             # 已发布的配套启动镜像、双核程序和 FPGA 固件
├── sd_card/              # SD 卡文件模板，含 bird_class/date.txt
├── evidence/             # 可追溯实测证据，明确历史版本与当前验收的区别
└── tools/                # 校验、连接、写卡及 JTAG 工具
    └── launch.py         # 统一命令入口
```

上位机界面源码位于 `src/pc/av_monitor/`，运行数据和备份写入 `build/out/board/`。下文的命令均从仓库根目录执行，不能在 `board/` 内直接照抄运行。若按从零复现文档建立了未激活的虚拟环境，请将下文所有 `python` 替换为 `.\.venv\Scripts\python.exe`，确保使用已安装依赖的环境。

本目录保留原 SSD95 发布版本（历史编号 M51）的配套固件，拍照门槛为 **≥95%**，视觉追踪使用 **>50%** 的鸟目标门槛。相机使用已发布版本的原转接板引脚；历史记录中称为 M48/M47，与 M111/M49 新转接板不兼容。这些编号仅用于硬件来源追溯，不代表当前目录位置。

需要 Python 3.10 或更高版本；上位机依赖安装方法见[项目说明](../readme.md)。JTAG 使用 Vivado 2023.2 的 xsdb 与 hw_server，可设置 `VIVADO_BIN`，也可把工具加入 PATH。`XSCT` 可显式指定 xsdb/xsct 程序完整路径。连接多条 JTAG 线缆时用 `--cable` 选择其序列号；单条线缆自动选择，包内没有固定的个人设备序列号。

## 离线检查

```powershell
python board/tools/launch.py verify
```

只检查本机工程，不连接板卡。直接运行 `launch.py` 只显示帮助。

## SD 卡启动

板卡断电后，把 FAT16/FAT32 SD 卡放入电脑读卡器，先预览目标盘，再显式写入：

```powershell
python board/tools/launch.py write-sd --sd-root E:/
python board/tools/launch.py write-sd --sd-root E:/ --write
```

`E:/` 必须替换成实际 SD 盘符。自动写卡器仅支持 Windows 检测为可移动的 FAT 卷，会拒绝系统盘和子目录；不会格式化。旧启动文件备份在 `build/out/board/card_backup_*/`。现有日期设置及照片保留，只有日期文件缺失时才复制模板。首次运行前修改卡内 `bird_class/DATE.TXT` 为所需拍摄日期，例如 `2026.10.29`，随后断电重启使日期生效。

手动复制也可以：将 `board/firmware/boot.bin` 复制到 SD 卡根目录，**命名为 `BOOT.bin`**；将 `board/sd_card/bird_class/date.txt` 复制为 `bird_class/DATE.TXT`。源包文件名全部小写；卡内文件名按固件启动要求写成上述形式。不要覆盖旧 DATE.TXT 或删除旧照片。

安全弹出 SD 卡，板卡断电插卡，选择 SD 启动后上电。SD 固件会直接进入音视融合，自动保存满足 SSD≥95%、有效视觉鸟种、完整新鲜图像等条件的照片：

```text
bird_class/<ebird_code>_<yyyy.mm.dd>/1.bmp
bird_class/<ebird_code>_<yyyy.mm.dd>/2.bmp
```

图片为 640×360 完整画面 BMP，上限 2 张/秒。目录日期只来自卡内设置文件，不自动校时或跨日更新；95% 门槛也不能消除所有高置信度误检。

## 连接上位机

电脑有线网口设置为 `192.168.7.1/24`，板卡为 `192.168.7.20`。连接千兆网线，允许当前 Python 接收局域网 UDP。SD 正常运行后：

```powershell
python board/tools/launch.py monitor
```

关闭此模式的窗口只断开上位机连接，保留 SD 独立运行的行为。在线调参继续使用原界面和原控制权规则，参数只保存在 RAM。

可选的 JTAG 只读检查：

```powershell
python board/tools/launch.py sdcheck
```

它读取 SD 启动状态和相隔 1 秒的图像帧计数，不停止 CPU、不复位、不下载固件。

## 明确要求 JTAG 重新下载时

```powershell
python board/tools/launch.py program --program
python board/tools/launch.py monitor
```

这会复位并重新下载配套 PL、两核 ELF 和模型，初始俯仰命令 1140 μs（60°），保留原 JTAG 入口的自动追踪关闭及水平参考无效状态；在上位机点击音视联动启动。SD 上电自启动流程仍直接进入融合。此入口只使用 `board/firmware/` 内固定配对版本，不自动编译源码，不能把单独重编的 ELF 混入后继续使用原下载脚本。

板上四键：KEY1 强制亮度增强/再次恢复自动；KEY2 强制关闭增强/再次恢复自动；KEY3 关闭自动对焦并固定码值 280；KEY4 恢复自动对焦。角度、PWM 与变化率表示位置指令估计，没有编码器反馈。

本轮已完成离线验证与 ARM/BOOT 重建，未操作板卡、写物理 SD 卡或验证机械性能。已有真实历史板测已归档在 [evidence/readme.md](evidence/readme.md)；当前 SSD95 集成版本的实测日志待提供并核对版本，不用旧结果代替当前验收。
