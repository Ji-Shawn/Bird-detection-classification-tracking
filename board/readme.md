# M51 上板与运行

本目录的固件是最新 SSD 拍照门槛 **≥95%** 的 M51 配套版本。视觉追踪仍使用 **>50%** 的鸟目标门槛。使用 M48/M47 原转接板引脚，不能用于 M111/M49 的新转接板。

所有命令在仓库根目录执行。Python 3.10 或更高版本；上位机依赖安装方法见根 readme.md。JTAG 使用 Vivado 2023.2 的 xsdb 与 hw_server，可设置 `VIVADO_BIN`，也可把工具加入 PATH。`XSCT` 可显式指定 xsdb/xsct 程序完整路径。连接多条 JTAG 线缆时用 `--cable` 选择其序列号；单条线缆自动选择，包内没有固定的个人设备序列号。

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

打包仅完成离线检查，未在本次打包中重新上板、写物理 SD 卡或验证机械性能。
