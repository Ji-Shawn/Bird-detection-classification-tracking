# 2026-11-03 双核 ARM 与 BOOT 重建证据

总回执见 [arm_rebuild_20261103.json](../arm_rebuild_20261103.json)。本目录归档的是本轮实际生成的编译输入清单、编译与链接输出、链接映射和 BOOT 证据；归档时另外进行了输入指纹核验及一次独立 BOOT 解析。没有连接板卡或写入物理 SD 卡。

## 产物与适用范围

本轮使用 Vitis 2023.2 所带 GCC 12.2.0，原发布记录使用 ARM GNU 6.2.1。这是新工具链的双核编译成功记录，不是原发布 ELF 的逐字节复现。

| 产物 | SHA256 |
| --- | --- |
| Core0 | `5a0f4e8a06786d76621cec85f7025f3d9a80107ed5e7139537b12550712621ae` |
| Core1 | `af37381792c63c5135c5e5bdc2dfacd7ac35329dba4b46f608d7edbe2eefa1d3` |
| FSBL | `3030eb22170b83e37e69602ce139bd984791d56599abe0f3494cc6b1d3395c49` |
| 新 BOOT | `dc3b3f1e9059267f14a8a919798f95caf3d81e5a395b066312efa577e18f4d6b` |

新 BOOT 组合新两核 ELF、重新编译的 FSBL、随包发布 PL 和模型；该 ARM/BOOT 回执不包含 FPGA 重新综合。随后单独完成的 FPGA 实现见[本轮 PL 归档](../../reports/rebuild_20261103/readme.md)，其新 bit 没有被加入这里已验证的 BOOT。新二进制仍位于 `build/out/`，没有覆盖 `board/firmware/` 中的发布文件。

## 文件如何阅读

| 文件 | 内容 |
| --- | --- |
| `core0_inputs.json`、`core1_inputs.json` | 原构建器输出的编译输入、依赖和链接输入指纹；Core0 还保留编译选项和头文件集合 |
| `core0_build.txt`、`core1_build.txt` | 双核构建总入口的完成标记 |
| `core0_compile_and_link.txt`、`core1_compile_and_link.txt` | 各原始编译/链接日志按文件名合并；每段注明来源、原始字节数和 SHA256；空日志仍保留条目 |
| `core0_link_map.txt`、`core1_link_map.txt` | 原链接映射，包含实际链接输入和地址分配 |
| `fsbl_inputs.json`、`fsbl_build.txt`、`fsbl_link_map.txt` | FSBL 输入指纹、实际编译/链接命令及链接映射 |
| `boot_layout.txt`、`bootgen.txt`、`boot_build_receipt.json` | BOOT 组成、Bootgen 输出、构建器原始结果；布局文本已脱敏，不应直接作为可执行 BIF |
| `compiler_version.txt` | 归档核验时实际执行同一编译器 `--version` 的输出 |
| `boot_verify.json`、`boot_verify.txt` | 归档核验时再次运行独立 BOOT 解析的结果 |
| `input_hash_audit.json` | 所有已记录输入的当前指纹核验、直接源码映射和当前关键构建脚本快照 |
| `provenance.json` | 每个原始证据文件与归档文件的 SHA256、大小和转换规则 |

编译日志包含警告。构建成功只说明编译与链接完成，不等于消除了所有警告。Core0/Core1 的逐文件日志没有完整记录每个编译器调用参数；编译选项、脚本、依赖和链接映射需结合阅读。FSBL 日志保留了实际命令行。

## 本次归档实际检查了什么

- Core0：35 个源输入、272 个头文件集合条目、214 个编译依赖、46 个链接输入的 SHA256 全部匹配。
- Core1：29 个源输入、109 个编译依赖、39 个链接输入的 SHA256 全部匹配。
- FSBL：126 个输入，以及 ELF、编译器和 Xilinx.spec 的 SHA256 全部匹配。
- 合并去重后，共核验 624 个已记录文件；其中 491 个能够直接映射到当前 `src/` 的文件，均与原输入回执一致。
- 独立解析新 BOOT，验证 8 个分区、388 项模型资产、Core0/Core1/FSBL 运行字节、发布 PL 字节和启动种子。结果为通过。

生成的 overlay、对象文件和链接脚本不一定在 `src/` 中有同路径副本，其身份由编译回执中的指纹记录。关键构建脚本的当前哈希也已保存；这是归档时快照，不能反过来声称存在一份当时未采集的构建前脚本快照。

## 脱敏与重现

路径根用 `${package_root}`、`${vitis_install}`、`${vivado_install}` 代替；JSON 路径分隔符统一为 `/`，原始字节和脱敏后字节分别计算 SHA256。日志保留成功、警告、地址、计数和错误信息，没有根据期望结果改写输出。归档文件不含开发机用户目录或盘符绝对路径。

从项目根目录按[构建说明](../../readme.md)执行重建。只有同一输入、工具链和构建条件下才有逐字节对照的意义；换工具链产生不同 ELF 不等于可以跳过重新验收。本目录没有声称新固件已完成冷启动、实时推理、摄像头/麦克风、云台或存图板测。
