# 模型、参考数据与协作来源导览

本目录保存板端运行所需的模型权重、量化表、加载地址清单、参考样本，以及协作报告所引用的来源材料。

```text
data/
├── readme.md              # 数据用途与读取入口
├── collaboration_sources/ # 用户补充原文、Word 正文、交接摘录及来源指纹
└── models/
    ├── assets/           # 音频分类、鸟目标检测、视觉分类的板端模型资产
    ├── assets_manifest.json # 文件路径、大小、加载地址和 SHA256
    └── samples/          # 固定输入、原参考输出和独立观察格式
```

`assets_manifest.json` 共记录 391 项，其中 388 项为板端运行资产。清单内路径相对于 `data/models/`。运行 `python -B build/verify_package.py` 可核对文件大小和 SHA256；命令从仓库根目录执行。

模型资产由 `build/build_boot.py` 打包到启动镜像，或由 `board/tools/launch.py` 的显式 JTAG 下载入口读取。使用方式见[构建说明](../build/readme.md)和[上板说明](../board/readme.md)。

模型定义、数据准备、训练与评估代码见 [src/modeling/](../src/modeling/readme.md)，从根目录运行 `python -B build/build_models.py` 查看可用命令。完整训练数据由使用者单独准备，训练产物默认写入 `build/out/modeling/`。随包的 `data/models/` 是既有板端资产，训练新模型后还需导出、量化、资产转换和重新验收，见[训练与部署的对应关系](../src/modeling/deployment.md)。第三方和模型授权信息见[来源与授权说明](../src/third_party_notices.md)，不要把参考样本当作完整准确率评估集。

数值对拍见 [samples/readme.md](models/samples/readme.md)：需要独立采集完整实际输出，再执行 `sim/compare_inference.py`；自测通过或复制参考值不构成板测证据。本目录仅提供当前运行资产及固定样本，当前集成固件的完整实测输出仍待采集，要求见 [board/evidence/readme.md](../board/evidence/readme.md)。

## 协作报告的来源材料

`collaboration_sources/` 保存两份来源 Markdown、Word 全文提取、带原行号的交接摘录及来源记录；阅读方式见[来源材料说明](collaboration_sources/readme.md)，文件身份与转换方式见 [provenance.json](collaboration_sources/provenance.json)。这些材料用于核对报告中的提示词摘要、判断变化和技能来源，不作为模型输入或板端资产清单的一部分。

来源稿保留当时的表述，包括后来撤回或收窄的结论；它们不能替代原始实验日志，也不能直接当作现行操作指令。当前采纳结论见 [大模型协作报告](../report/llm_collaboration.md)和[技能包提炼过程](../report/skill_extraction.md)，实际技能使用见 [skill/readme.md](../skill/readme.md)。根目录 `report/` 保留[最终设计报告 PDF](../report/report.pdf)和这两份专题 Markdown。
