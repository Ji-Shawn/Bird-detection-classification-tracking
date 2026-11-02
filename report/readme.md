# 设计与验证报告导览

本目录保存设计说明、协作记录、文件来源和验证证据。先了解系统看设计报告，了解本轮人机分工、失败纠正与复用成果看 [大模型协作报告](llm_collaboration.md)；实际操作看根目录 [从零复现](../reproduce.md)。

| 文件 | 用途 |
| --- | --- |
| `design.md` | 系统设计与功能说明 |
| `llm_collaboration.md` | 本轮详细大模型协作报告，含证据、失败、验证边界与技能沉淀 |
| `compliance_review.md` | 逐条对照交付规范、已修复问题与尚待关闭项 |
| `collaboration_log.md` | 原开发阶段协作摘要，保留历史范围 |
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

本轮可核对材料分布在对应功能目录：[离线检查回执](../sim/results/offline_checks_20261103.json)、[ARM/BOOT 重建](../build/receipts/arm_rebuild_20261103.json)、[历史 PL 完整构建](../build/reports/rebuild_20261031/readme.md)、[板测证据](../board/evidence/readme.md)、[可复用技能](../skill/readme.md)。历史报告中的日期、失败和未通过项保持原意；不要将本轮整理日期当成实际测量日期。
