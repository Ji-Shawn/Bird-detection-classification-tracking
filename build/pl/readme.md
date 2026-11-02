# FPGA 硬件构建导览

本目录把 `src/pl/` 中的硬件源码和 IP 配置创建为 Vivado 工程，并提供展开检查与完整实现入口。硬件模块按采集、推理、音频特征、视频增强和显示等功能组织，详见[硬件源码导览](../../src/pl/readme.md)。ARM 双核与 BOOT 的构建步骤见[构建总览](../readme.md)。

```text
build/pl/
├── readme.md              # 本说明
├── create_project.tcl     # 创建工程并生成 IP
├── check_pl.tcl           # RTL 展开检查
├── build_pl.tcl           # 完整综合、实现和时序检查
└── av_system.tcl          # 历史连线参考
```

输入源码位于 `src/pl/`，生成工程和结果位于 `build/out/pl/`，原发布实现报告位于 `build/reports/`。所有命令从仓库根目录运行。

工具版本为 Vivado 2023.2，器件为 `xc7z020clg400-2`。在仓库根目录执行：

```powershell
$env:VIVADO_BIN = 'D:\Xilinx\Vivado\2023.2\bin'
New-Item -ItemType Directory -Force -Path build/out | Out-Null
& "$env:VIVADO_BIN\vivado.bat" -mode batch -source build/pl/create_project.tcl -log build/out/pl_create.log -journal build/out/pl_create.jou
& "$env:VIVADO_BIN\vivado.bat" -mode batch -source build/pl/check_pl.tcl -log build/out/pl_check.log -journal build/out/pl_check.jou
& "$env:VIVADO_BIN\vivado.bat" -mode batch -source build/pl/build_pl.tcl -log build/out/pl_build.log -journal build/out/pl_build.jou
```

Windows 可使用 Vivado 安装目录中的 `vivado.bat`。第一条命令只建立工程并重新生成 IP；第二条只做 RTL 展开检查；第三条从工程创建开始，继续完整综合、实现和时序检查，成功后输出 `build/out/pl/adapter_system.bit`。这些命令均不下载。所有输出均放入忽略目录 `build/out/`，不会覆盖 `board/firmware/` 内的已发布固件。

正式构建输入为 `src/pl/structural/` 的 16 份真实结构连接源码、当前 RTL/ROM、39 份 `src/pl/ip_config/` 叶 IP 配置和 `src/pl/ip_repo/` 的 Digilent HDMI IP。结构文件来自已发布四按键 PL 的实际生成输入，包括顶层、14 个模块引用边界以及总线层级连接。它们是保持真实硬件连接所必需的设计输入。重新生成的官方 IP HDL、缓存、综合检查点和历史工程不随包提供。

叶 IP 配置只调整生成目录，协议、数据位宽和其他功能参数保持原值。构建脚本先复制配置到输出目录，再调用 Vivado 重新生成。字库文件路径改为相对名称，RTL 标识及存储器内容不变。源文件的 Verilog/SystemVerilog 类型沿用原工程；时钟、CDC、J11 和实体按键约束以及原时钟归一化步骤均保留。

`src/pl/bd/av_system.bd` 与 `build/pl/av_system.tcl` **仅作为原设计连线和地址配置的参考**，不作为正式构建入口。对它们进行全新 `validate_bd_design` 时，旧接口传播元数据将 `vdma_proto` 的目标协议推为 AXI4，但该转换器只接受 AXI3/AXI4LITE，因此检查失败。已发布硬件的真实配置是该转换器输出 AXI3，而后级总线接收 AXI4 子集。打包没有更改协议、跳过失败后声称通过，也没有改动已发布的 bitstream；改用实际结构连接源码保留原来硬件实现。

原始导出阶段完成了干净工程创建、39 个叶 IP 重新生成和功能配置核对，以及 `synth_design -rtl` 展开检查（168 个端口、4 位实体按键，0 严重警告、0 错误；487 条普通警告）。历史结果见 `build/receipts/package_history/pl_package.json` 与 `build/reports/pl_package_checks.txt`，旧阶段路径可通过 `build/metadata/history/directory_reorganization.json` 对照。

10 月 31 日同一 Git 提交完整重建，默认策略 WNS=-0.073 ns，Explore 策略 WNS=+0.082 ns、WHS=+0.012 ns。39 个 IP、217 项手动 PS 设置、168 个引脚核对一致。原始成功脚本以前只在忽略的输出目录中，本轮已把该策略加入正式入口，详见[完整证据与待审查项](../reports/rebuild_20261031/readme.md)。顶层 `pl_*.rpt` 仍是原发布实现，不能与新构建混用。

2026-11-03 已从源码完整重建，WNS=+0.062 ns、WHS=+0.012 ns，输出 bitstream。新报告包含综合与实现阶段，见[本轮证据](../reports/rebuild_20261103/readme.md)。随后仅改变 IP 生成的工作目录以避免根目录产生临时文件，又在独立新目录实测完成 39 个 IP 生成；具体两次运行的范围与脚本指纹在该证据内分别记录。

正式脚本输出综合和实现报告，通过时序、内部未约束端点、DRC 严重错误及总线偏斜门槛后，打印 `PL_IMPLEMENTATION_TIMING_PASS`。该标记不表示完整工程签核：CDC 中的 Unknown/Unsafe、I/O 延时缺项和方法学普通告警仍需人工处置。用技能包的[报告审查流程](../../skill/zynq_pl_accel/references/report_review.md)核对新报告，不要自动豁免。当前没有完成这些问题的 RTL 修复或新硬件上板验收。

结构构建只导出 bitstream；调整 PS 配置或地址映射后，需要重新建立有效的硬件交接描述，不能继续使用原 XSA。按键 XDC 中原有 `if` 会触发工具警告，当前构建已在普通 Tcl 中另外核对 4 个首级同步寄存器存在，历史告警仍保留供复核。
