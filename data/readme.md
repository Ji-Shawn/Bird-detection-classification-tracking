# 模型与参考数据导览

本目录保存板端运行所需的模型权重、量化表、加载地址清单和少量参考样本。

```text
data/
├── readme.md              # 数据用途与读取入口
├── reference/            # 历史实测与参考的逐层误差、分段性能汇总
└── models/
    ├── assets/           # 音频分类、鸟目标检测、视觉分类的板端模型资产
    ├── assets_manifest.json # 文件路径、大小、加载地址和 SHA256
    └── samples/          # 固定输入、原参考输出和独立观察格式
```

`assets_manifest.json` 共记录 391 项，其中 388 项为板端运行资产。清单内路径相对于 `data/models/`。运行 `python -B build/verify_package.py` 可核对文件大小和 SHA256；命令从仓库根目录执行。

模型资产由 `build/build_boot.py` 打包到启动镜像，或由 `board/tools/launch.py` 的显式 JTAG 下载入口读取。使用方式见[构建说明](../build/readme.md)和[上板说明](../board/readme.md)。

本包没有完整训练数据或训练流水线。第三方和模型授权信息见 `report/third_party_notices.md`，不要把参考样本当作完整准确率评估集。

数值对拍见 [samples/readme.md](models/samples/readme.md)：需要独立采集完整实际输出，再执行 `sim/compare_inference.py`；自测通过或复制参考值不构成板测证据。历史 222 行逐层比较见 [reference/history_models_20261002](reference/history_models_20261002/readme.md)，对应旧输入和旧固件，包含非零误差。
