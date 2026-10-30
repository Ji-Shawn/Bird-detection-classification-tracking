# 模型与参考数据导览

本目录保存板端运行所需的模型权重、量化表、加载地址清单和少量参考样本。

```text
data/
├── readme.md              # 数据用途与读取入口
└── models/
    ├── assets/           # 音频分类、鸟目标检测、视觉分类的板端模型资产
    ├── assets_manifest.json # 文件路径、大小、加载地址和 SHA256
    └── samples/          # 少量参考样本
```

`assets_manifest.json` 共记录 391 项，其中 388 项为板端运行资产。清单内路径相对于 `data/models/`。运行 `python -B build/verify_package.py` 可核对文件大小和 SHA256；命令从仓库根目录执行。

模型资产由 `build/build_boot.py` 打包到启动镜像，或由 `board/tools/launch.py` 的显式 JTAG 下载入口读取。使用方式见[构建说明](../build/readme.md)和[上板说明](../board/readme.md)。

本包没有完整训练数据或训练流水线。第三方和模型授权信息见 `report/third_party_notices.md`，不要把参考样本当作完整准确率评估集。
