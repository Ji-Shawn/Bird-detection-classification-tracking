# 历史文档与审查索引

本目录保存早期协作摘要、交付规范审查和文档要求核对记录。当前两份报告正文位于仓库根目录的 `report/`：[大模型协作报告](../../../report/llm_collaboration.md)和[技能包提炼过程](../../../report/skill_extraction.md)。实际操作从[从零复现](../../../reproduce.md)开始。

## 本目录的文件

| 文件 | 用途与范围 |
| --- | --- |
| [collaboration_log.md](collaboration_log.md) | 原开发阶段的协作摘要，保留当时需求、决策和验证范围。 |
| [compliance_review.md](compliance_review.md) | 对照交付规范记录审查发现、修复和仍需处理的事项。 |
| [requirements_confirmation.md](requirements_confirmation.md) | 将截图中的协作与技能提炼要求拆成七项，定位到两份报告正文。 |
| [collaboration_review_20261103.json](collaboration_review_20261103.json) | 七项文档要求的结构化核对记录；“已覆盖”表示文档内容覆盖，不代表硬件验收通过。 |

## 其他材料的实际位置

下表链接均指向其他目录，文件不在本目录内。

| 要查的内容 | 实际位置 |
| --- | --- |
| 系统设计与功能 | [src/design.md](../../../src/design.md) |
| 第三方来源与授权 | [src/third_party_notices.md](../../../src/third_party_notices.md) |
| 用户补充原文、Word 正文、交接摘录与来源指纹 | [data/collaboration_sources/readme.md](../../../data/collaboration_sources/readme.md) |
| 当前文件校验清单与源码路径对应 | [package_manifest.json](../../metadata/package_manifest.json)、[source_mapping.json](../../metadata/source_mapping.json)，位于 `build/metadata/` |
| 目录整理与 readme 更新的历史记录 | [directory_reorganization.json](../../metadata/history/directory_reorganization.json)、[readme_update.json](../../metadata/history/readme_update.json) |
| 原始导出、ARM/BOOT、上板工具离线测试及原发布封存回执 | `build/receipts/package_history/`；分类说明见[构建导览](../../readme.md) |
| 本轮离线检查 | [sim/results/offline_checks_runner_new_full_20261103.json](../../../sim/results/offline_checks_runner_new_full_20261103.json) |
| 本轮 ARM/BOOT 重建 | [build/receipts/arm_rebuild_20261103.json](../../receipts/arm_rebuild_20261103.json) |
| PL 构建与时序证据 | [2026-10-31 历史重建](../rebuild_20261031/readme.md)、[2026-11-03 重建](../rebuild_20261103/readme.md) |
| 历史板测与可复用方法 | [board/evidence/readme.md](../../../board/evidence/readme.md)、[skill/readme.md](../../../skill/readme.md) |

历史记录中的 Mxx 编号和旧工程路径用于追溯。当前源码按功能目录组织，见[源码导览](../../../src/readme.md)。历史日期、失败和未通过项保留原意，整理日期不等于实际测量日期。

从仓库根目录运行 `python -B build/verify_package.py` 校验当前清单；自行运行测试与构建的新结果写入 `build/out/`。清单一致、文档要求已覆盖和目录整理完成，分别说明对应检查的结果，不能替代完整构建或板卡验收。
