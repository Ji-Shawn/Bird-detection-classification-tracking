# 仿真与验证导览

本目录用于离线检查存图门槛、文件系统写入逻辑和上板工具行为。所有命令从仓库根目录运行。

```text
sim/
├── readme.md              # 验证入口与范围
├── run_tests.py           # 37 项存图门槛和 FatFs 集成用例
├── archive/               # 保留的存图测试 C 源码
├── fixtures/              # 测试用文件系统数据
└── board_tools/           # 25 项上板工具离线测试
```

| 目标 | 命令 | 结果位置 |
| --- | --- | --- |
| 存图策略与 FatFs 集成 | `python -B sim/run_tests.py` | `build/out/tests/` |
| 上板工具行为 | `python -B sim/board_tools/run_tests.py` | `build/out/board_tools_tests.json` |
| 文件完整性 | `python -B build/verify_package.py` | 终端校验结果 |

存图测试编译 `src/application/software/` 中的实际生产代码，需要原生 GCC 兼容编译器，可用 `HOST_CC` 指定其完整路径。上板工具测试需要 Python 标准库中的 tkinter/Tcl，不需要板卡；详细范围见 [board_tools/readme.md](board_tools/readme.md)。

这些测试不访问物理 SD 卡或板卡，不代表模型准确率、机械性能或 SD 冷启动实测。实际操作见[上板运行说明](../board/readme.md)，历史与当前验证记录见[报告导览](../report/readme.md)。
