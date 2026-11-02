# 上板工具离线验证

这里验证 `board/tools/` 的命令行为。项目仿真总览见[sim/readme.md](../readme.md)，实际上板操作见[board/readme.md](../../board/readme.md)。

```text
sim/board_tools/
├── readme.md              # 测试范围与运行方法
└── run_tests.py           # CLI、Tcl 模拟和写卡临时目录测试
```

| 对象 | 当前目录 |
| --- | --- |
| 实际上板工具 | `board/tools/` |
| 上位机界面源码 | `src/pc/av_monitor/` |
| 已配套固件 | `board/firmware/` |
| 本次运行结果 | `build/out/board_tools_tests.json` |

在仓库根目录运行：

若已按[从零复现](../../reproduce.md)建立虚拟环境，将下面的 `python` 替换为 `.\.venv\Scripts\python.exe`。

```powershell
python -B sim/board_tools/run_tests.py
```

仅使用 Python 标准库（包括 tkinter 的 Tcl 解释器，不需要图形显示）。CLI 守卫通过子进程执行；实际 Tcl 下载与只读脚本的全部硬件命令被替换为记录函数；SD 写卡器使用临时的电脑目录及模拟磁盘身份。不会读取真实板卡或物理 SD 卡。

覆盖默认帮助、显式下载/目标盘参数、日期边界、JTAG 启动命令顺序、只读探针、单/多线缆选择、照片与日期保留、缺失日期补齐、旧启动文件备份、磁盘身份变化和残留临时文件拒绝。

报告写入 `build/out/board_tools_tests.json`，包含实际被测文件的 SHA256。该报告不能代替真实硬件下载、冷启动、可移动磁盘识别和机械性能测试。

本轮完整离线检查实际运行了 25 项并全部通过，记录在[统一回执](../results/offline_checks_20261103.json)。归档记录只证明相应版本的模拟行为；你修改工具后应重新执行。
