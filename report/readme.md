# 设计与验证报告导览

本目录保存设计说明、协作记录、文件来源和验证证据。先了解系统看设计报告，核对本次目录整理看迁移记录。

| 文件 | 用途 |
| --- | --- |
| `design.md` | 系统设计与功能说明 |
| `collaboration_log.md` | 开发与大模型协作记录 |
| `directory_reorganization.json` | 功能目录迁移对照与整理后的验证范围 |
| `readme_update.json` | 本次全部 readme 更新清单与检查结果 |
| `package_manifest.json` | 当前包的相对路径及 SHA256 校验清单 |
| `source_mapping.json` | 原始源码位置与当前包路径的对应关系 |
| `package_validation.json` | 原始导出阶段的总体离线验证 |
| `arm_rebuild.json` | 原始导出阶段的 ARM 重建结果 |
| `pl_package.json` | 原始硬件导出的 IP 配置与 RTL 展开证据 |
| `boot_rebuild.json`、`source_boot_rebuild.json` | 原始启动镜像重建记录 |
| `board_tools_tests.json` | 原始上板工具离线测试记录 |
| `original_*.json` | 原发布版本的封存与验证记录 |
| `third_party_notices.md` | 第三方来源与授权说明 |

历史报告中出现的 Mxx 编号及旧工程路径用于追溯，当前源码按 `src/application/`、`src/platform/`、`src/services/`、`src/pc/`、`src/pl/` 等功能目录查找，详见[源码导览](../src/readme.md)。

从仓库根目录运行 `python -B build/verify_package.py` 校验当前包。自行运行测试与构建的新结果位于 `build/out/`，不会自动改写本目录的历史证据。目录整理、说明更新、源码生成检查均不能替代完整构建和上板验收。
