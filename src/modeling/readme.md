# 模型构建、训练与评估

这里补齐电脑端的模型源码和训练入口：音频 MobileNetV2、图像 MobileNetV2，以及两分类鸟目标 SSDlite320-MobileNetV2。它们取自现役模型仓库并作路径适配，源仓库保持只读。训练得到的 PyTorch 权重还不能直接替换板端资产；当前发布模型的身份与后续转换边界见[部署对应说明](deployment.md)。

主入口是 `build/build_models.py`，它转发到本目录的 `run.py`；两者使用相同子命令。先执行环境检查和无下载自检，再准备数据。**只有显式执行 `train` 才会训练**；数据准备、自检、帮助和审计均不会自动启动训练。当前交付没有重新训练模型、下载预训练权重或完整数据，也没有测量新的分类准确率。

## 1. 文件在哪里、分别做什么

```text
src/modeling/
├── readme.md
├── deployment.md                # 当前发布模型身份与转换边界
├── run.py                       # 所有模型任务的统一入口
├── requirements.txt             # 已验证的基础依赖
├── requirements_audio.txt       # 音频准备附加依赖
├── source_mapping.json          # 原源文件与入包文件的指纹及适配说明
├── model/
│   ├── classification_data.py   # mel、图像预处理和确定性划分
│   ├── classification_training.py # 两种分类器的构建、训练和评估
│   ├── ssdlite_mobilenet_v2.py   # 检测器结构与背景空图损失
│   ├── bird_detection_data.py   # 检测数据审计、划分和加载
│   ├── train_bird_detector.py   # 通用检测器训练、评估、预测
│   ├── ssdlite_background_finetune.py # 已审核无鸟背景的微调配方
│   └── ssdlite_cub_continue.py  # 已发布 SSD 所用 CUB 续训路线
├── scripts/
│   ├── prepare_ssw60.py         # 只准备 SSW60 数据
│   ├── audio_preprocessing.py   # 原有色噪声增强函数
│   └── selftest.py              # CPU 合成数据自检
└── tests/                      # 分类、检测、背景和 CUB 审计测试
```

输出默认集中在仓库的 `build/out/modeling/`；大数据目录由你指定。`model/` 中的模块导入时不读取训练数据、不创建模型权重、不启动训练。旧 GAP/SmallBirdCNN、teacher、蒸馏、一次性实验、原 `runs/`、权重、数据和虚拟环境没有整包复制。现役 CUB 续训配方单独保留，因为它与当前已发布 SSD 的来源有关。

## 2. 第一次运行：环境和自检

以下 PowerShell 命令均在 `github_pack` 根目录执行。需要 Python 3.12；本轮实际验证的是 Python 3.12.5、torch 2.8.0+cpu、torchvision 0.23.0+cpu，其余版本在 requirements 中。原模型仓库 README 中的另一套版本声明不作为本次验证环境。

```powershell
python -m venv build/out/modeling/venv
$model_python = (Resolve-Path build/out/modeling/venv/Scripts/python.exe).Path
& $model_python -m pip install torch==2.8.0 torchvision==0.23.0 --index-url https://download.pytorch.org/whl/cpu
& $model_python -m pip install -r src/modeling/requirements.txt
& $model_python build/build_models.py doctor
& $model_python -B build/build_models.py selftest
```

CPU 安装组合按 [PyTorch 官方历史版本说明的 2.8.0 条目](https://pytorch.org/get-started/previous-versions/#v280)核对。需要实际 GPU 训练时，在另一个环境安装同版本对应的 CUDA 轮子，按显卡与驱动选择官方支持的组合；本轮没有验证 CUDA 训练。不要在源仓库的 `.venv` 中升级或覆盖依赖。

不想运行任何任务时，执行 `python src/modeling/run.py` 只显示帮助。`doctor` 只检查包版本和解释器；它不证明 torchvision 算子可以加载，仍须执行 `selftest`。自检使用 CPU、合成张量和临时图像，阻止网络连接，包含前向/反向传播检查但不进行数据集训练或权重优化。

本轮自检 **16 项通过、0 跳过**：保留原 9 项检测器/背景测试，新增 6 项分类预处理/划分/结构/学习率测试及 1 项 CUB 审计测试。新运行输出为 `build/out/modeling/selftest/results.json` 和 `tests.txt`，本轮正式归档见[模型集成验证回执](../../sim/results/modeling_20261103.json)。成功退出码为 0；缺依赖或测试失败应先排错。自检不代表完整训练收敛、数据集准确率、ONNX/INT8 转换或 FPGA 验收。

## 3. 准备音频与图像分类数据

额外安装音频依赖：

```powershell
& $model_python -m pip install -r src/modeling/requirements_audio.txt
```

本轮使用 librosa 0.11.0、soundfile 0.14.0，并在临时依赖目录补充 resampy 0.4.3，验证了 16 kHz、22050 Hz、32 kHz 合成音频的加载与原 `kaiser_fast` 重采样路径；没有修改源仓库环境。主用例 6 段 WAV 生成 24 个 mel 样本和 8 张图像，22050 Hz 补充用例 2 段 WAV 生成 7 个 mel 样本。合计 8 段 WAV、31 个 mel、8 张图像，不能替代完整 SSW60 数据准备或真实数据集评估。

数据从以下官方入口获取；本次只核对页面，没有下载数据：

- [SSW60 官方仓库](https://github.com/visipedia/ssw60)提供整包 tar 下载。解压后将包含 `taxa.csv` 的那一层作为 `--ssw`，不要误指向外层压缩包目录。官方音频为 22050 Hz，准备脚本按原配方重采样到 32000 Hz。
- [NABirds 官方数据入口](https://dl.allaboutbirds.org/nabirds)提供检测所需额外框标注；SSW60 的官方说明要求另取 NABirds 的 `bounding_boxes.txt`，仅有分类图片 CSV 不能完成检测训练准备。
- [CUB-200-2011 官方页面](https://www.vision.caltech.edu/datasets/cub_200_2011/)用于第 6 节的可选续训路线。音图分类与通用 NABirds 检测准备不需要先下载 CUB。

准备一个独立 SSW60 数据目录，至少有 `taxa.csv`、`audio_ml.csv` 和 `audio_ml/*.wav`；图像部分需要 `images_nabirds.csv`、`images_inat.csv` 与各自同名图像目录。数据不随工程包提供。把示例的 `D:/datasets/ssw60` 替换为你的真实目录：

```powershell
& $model_python -B build/build_models.py prepare-ssw60 --ssw D:/datasets/ssw60 --output D:/datasets/bird_prepared --component both
```

只处理音频或图像时，将 `both` 改为 `audio` 或 `image`。输出不能位于源数据目录内；新输出中创建 `mels/`、`images/`、`config/registry_mels.html`、日志和 `preparation.json`。数据准备完成时记录 `status=complete`；读音频或复制图像失败会报错，不再以跳过文件的方式隐瞒不完整输入。

准备输出必须是全新或完全空的目录，不复用缓存窗口。中断后的目录保留 `incomplete` 便于排错；重新运行时选择新的输出目录。这样每次从首个窗口按同一顺序消耗随机数，避免部分缓存使注册表漏项、增强变化或旧数据混入。源数据发生变化时也使用新输出目录。

保留的原始配方与需要理解的限制：

- 音频采样率 32000 Hz，5 秒窗，128 mel、FFT 1024、hop 400、20–16000 Hz；训练窗偏移 0/1.25/2.5/3.75/5 秒，后两窗使用原有色噪声增强，验证窗偏移 0/5 秒。
- 原实际源码按每物种录音用 seed 2276 随机留出约 10%，同一录音所有窗口属于同一划分。**这不是官方 SSW60 train/test 评测协议**；旧适配器注释与实际代码不符，本包按实际代码保留并说明。
- 图像按类别复制后，由训练器按排序后的文件和 seed 2276 作每类 90/10 划分；不是按视频/个体分组的独立测试。本包没有把这一内部验证分数写成官方测试准确率。
- 文件名改为小写英文结构，如 `mels/<bird>/<id>_w0.npy`、`config/registry_mels.html`。使用旧版含空格目录的数据时需重新准备或显式整理路径，不能直接让脚本猜旧开发机目录。

## 4. 构建、训练与评估两个 MobileNetV2 分类器

先查看参数：

```powershell
& $model_python build/build_models.py classify --help
```

准备好数据后，以下命令才会开始训练。`--device cpu` 可以运行但全量训练可能很慢；有已配置 GPU 环境时改为 `cuda`。默认使用 ImageNet V1 初始权重，首次训练可能下载；`--no-pretrained` 是从随机初始化开始，改变了原预训练配方，不能用它声称复现同一训练结果。

```powershell
& $model_python -B build/build_models.py classify train --task audio --workdir D:/datasets/bird_prepared --output build/out/modeling/audio --device cpu --workers 0
& $model_python -B build/build_models.py classify train --task image --workdir D:/datasets/bird_prepared --output build/out/modeling/image --device cpu --workers 0
```

两个模型均为宽度 1.0 的 MobileNetV2，分类头大小来自排序后的物种目录。保留原 seed 2276、batch 32、Adam 与卷积权重衰减分组；音频默认 30 epoch，图像 40 epoch，分段学习率保持原逻辑。原训练器按**最小训练 loss**保存权重，本包保留这个选择规则并写入记录，没有悄悄改为按验证集选优。

音频 `.npy` 保留原 `abs(spec+80)`、按最大值归一化、`numpy.resize` 到 128×400、复制三通道的处理。这里的 resize 是 NumPy 数组重排/补齐语义，**不是图像插值**。全 -80 dB 输入新增零张量保护，非法形状/NaN/Inf 会失败；不再允许读取 pickle 对象数组。图像训练保留随机裁剪、水平翻转、颜色增强和 ImageNet 归一化，验证保留 resize+中心裁剪到 128×128。

每次训练输出 `run_config.json`、`classes.txt`、`split_manifest.json`、`initial_weights.pt`、`best_weights.pt` 和 `history.jsonl`。数据为空、同一样本跨训练/验证、权重与类别顺序不一致时均报错。已有训练输出要求换新目录，避免静默覆盖。

训练完成后使用独立的评估输出目录：

```powershell
& $model_python -B build/build_models.py classify evaluate --task audio --workdir D:/datasets/bird_prepared --weights build/out/modeling/audio/best_weights.pt --classes build/out/modeling/audio/classes.txt --output build/out/modeling/audio_eval --device cpu --workers 0
& $model_python -B build/build_models.py classify evaluate --task image --workdir D:/datasets/bird_prepared --weights build/out/modeling/image/best_weights.pt --classes build/out/modeling/image/classes.txt --output build/out/modeling/image_eval --device cpu --workers 0
```

评估结果写入 `evaluation.json`，说明样本数、loss、accuracy、类别顺序及权重 SHA256。它只评估上述内部 validation 划分。训练时指定 `--weights` 和 `--classes` 可显式载入旧权重继续优化，但这是**只载权重的 warm start**，不恢复 Adam 状态或 epoch；原训练器的隐式自动加载已改为显式参数。

## 5. 通用 SSDlite320-MobileNetV2 鸟目标检测

检测器固定两类：0 为背景，1 为鸟。需要图像 CSV 中的 `asset_id,label,split,width,height`、对应 `.jpg`，以及每行 `id x y width height` 的 NABirds 框文件。下列路径都要换成实际位置。准备阶段读取/解码图像、核对尺寸和框、保留 official test，并从 official train 按物种留出 validation。

```powershell
& $model_python -B build/build_models.py detect prepare --csv D:/datasets/ssw60/images_nabirds.csv --boxes D:/datasets/nabirds/bounding_boxes.txt --images D:/datasets/ssw60/images_nabirds --output build/out/modeling/detector
& $model_python -B build/build_models.py detect train --manifest build/out/modeling/detector/manifest.json --output build/out/modeling/detector --device cpu --workers 0 --no-amp
& $model_python -B build/build_models.py detect evaluate --manifest build/out/modeling/detector/manifest.json --weights build/out/modeling/detector/best_weights.pt --split test --output build/out/modeling/detector_eval --device cpu --workers 0
& $model_python -B build/build_models.py detect predict --weights build/out/modeling/detector/best_weights.pt --image D:/datasets/example.jpg --output build/out/modeling/detector_prediction --device cpu
```

`train` 默认 ImageNet 预训练骨干，首次使用可能下载；`--no-pretrained` 可关闭但改变训练初始化。测试从不开启它。通用训练保留原 AdamW、余弦学习率、最佳 validation AP50 选优、完整 resume 状态与空背景损失。`--resume <last.pt>` 用于同配方恢复；完整 resume 文件包含 Python/NumPy 随机状态，只读取你信任的本地检查点。普通 `best_weights.pt` 按限制性权重加载路径读取。

数据审计遇到缺图/错框会停止并写 `audit.json`。确实要排除问题图时显式添加 `--allow-exclusions`，报告中仍保留排除项。可用 `--background` 指向人工审核的无鸟背景根目录，每个来源子目录至少三张图；不要制造“背景框”。评估中的 `ap50` 是单鸟类、一对一匹配的 AP@IoU0.5，**不是 COCO 多阈值 mAP**；检测分数也不是准确率。

## 6. 已发布 SSD 的背景/CUB 续训路线

通用 `detect train` 并不能单独复现当前发布 SSD。来源核对显示发布权重来自 `ssdlite_cub_face_v2_v1_20261021`，以 `face_v2` 背景微调权重继续训练；其精确身份见[部署对应说明](deployment.md)。所以这里额外保留两个真实配方，而不是把它们全部当成旧实验删去。

`background audit/train` 使用人工审核、按场景/录音划分的 `train/`、`val/`，可选 `test/` 无鸟图像。它检查解码像素重复；负样本不能是随意截图或含鸟图片。示例仅作输入格式说明：

```powershell
& $model_python -B build/build_models.py background audit --background-root D:/datasets/bird_free --manifest build/out/modeling/detector/manifest.json
```

`cub-continue` 保留当时的 CUB 官方测试留出、10% train 验证、旧正样本/背景重放、像素去重、冻结 BN、25% 负样本、10 epoch、batch 8、lr 1e-4、seed 2276 和原接受门槛。它保留 CUDA 训练限制；CPU 可以做审计与轻量自检，不能误启动这条长训练。

```powershell
& $model_python -B build/build_models.py cub-continue audit --cub D:/datasets/cub_200_2011 --old-manifest D:/datasets/replay/positive_manifest.json --background-manifest D:/datasets/replay/background_manifest.json --weights D:/models/face_v2/best_weights.pt --output build/out/modeling/cub_continue
```

CUB 根目录需有 `images.txt`、`bounding_boxes.txt`、`train_test_split.txt`、`image_class_labels.txt` 与 `images/`。`--old-manifest` 是原正样本审计清单，`--background-manifest` 是原背景微调生成的记录列表；列表中的图像路径必须在本机有效。**缺少旧数据、face_v2 权重或对应清单时，无法声称精确重建已发布权重。** 本包不附这些大文件。确认审计无误、依赖和 GPU 可用后，用户可把 `audit` 改为 `train` 明确启动训练。已有输出会复用其已审计 manifest，改变数据时应使用新输出目录。

## 7. 来源、必要适配和未完成的工作

上游为 `D:/CoordinateNet-main/CoordinateNet-main`。其原始研究项目是 [Stanislav Novikov 的 CoordinateNet](https://github.com/Run4rest/CoordinateNet)，作者与来源沿用源 README；后续 MobileNetV2、检测及部署扩展属于该工作区的后续实现，不能全部归为原作者原始代码。文件级来源、原 SHA256、当前 SHA256 和适配摘要见 [source_mapping.json](source_mapping.json)。第三方许可沿用[仓库来源说明](../third_party_notices.md)，本次没有为来源不明的文件虚构许可证。

适配集中于：清除开发机硬编码路径和含空格的输出目录；将仅供借用的 MelDataset/噪声函数从旧训练器中解耦；提供显式训练命令、输出目录、类别检查和空数据失败；修正旧注释与实际划分的差异；保留检测器原结构和 CUB 配方；去掉 CUB 模块导入时强设 OpenMP 环境变量的副作用。没有启用原项目的自动训练编排器。

除 16 项 CPU 自检外，独立审查通过 28 次 CLI 执行核对了 48 项检查，包含合成准备、非法参数拒绝、重复录音/非法代码/缺标签拒绝和固定 logits 的音图评估。初次基线对拍因线程设置不同出现最大约 7.63e-6 dB 差异；双方统一 `OMP_NUM_THREADS=2` 后实际重跑，24 个 mel 数组及文件 SHA256 完全一致，原失败记录仍保留在[正式回执](../../sim/results/modeling_20261103.json)。此结果限定于该数据与环境，不宣称跨平台浮点输出必然逐字节相同；固定 logits 的 0.5 accuracy 也仅是评估代码自检，不能作为模型准确率。

尚未执行全量 SSW60 数据准备、完整训练/续训、真实数据集评估、CUDA 路线、ONNX 导出、校准量化、黄金层生成、板端资产重打包或物理上板。现成的发布资产继续由主工程使用；将新训练权重部署到硬件前，必须补齐[部署对应说明](deployment.md)列出的转换与验证。
