# M51 PL 构建

工具版本为 Vivado 2023.2，器件为 `xc7z020clg400-2`。在仓库根目录执行：

```text
vivado -mode batch -source build/pl/create_project.tcl
vivado -mode batch -source build/pl/check_pl.tcl
vivado -mode batch -source build/pl/build_pl.tcl
```

Windows 可使用 Vivado 安装目录中的 `vivado.bat`。第一条命令只建立工程并重新生成 IP；第二条只做 RTL 展开检查；第三条从工程创建开始，继续完整综合、实现和时序检查，成功后输出 `build/out/pl/adapter_system.bit`。这些命令均不下载。所有输出均放入忽略目录 `build/out/`，不会覆盖 `board/firmware/` 内的已发布固件。

正式构建输入为 `src/pl/structural/` 的 16 份真实结构连接源码、当前 RTL/ROM、39 份 `src/pl/ip_config/` 叶 IP 配置和 `src/pl/ip_repo/` 的 Digilent HDMI IP。结构文件来自已发布四按键 PL 的实际生成输入，包括顶层、14 个模块引用边界以及总线层级连接。它们是保持真实硬件连接所必需的设计输入。重新生成的官方 IP HDL、缓存、综合检查点和历史工程不随包提供。

叶 IP 配置只调整生成目录，协议、数据位宽和其他功能参数保持原值。构建脚本先复制配置到输出目录，再调用 Vivado 重新生成。字库文件路径改为相对名称，RTL 标识及存储器内容不变。源文件的 Verilog/SystemVerilog 类型沿用原工程；时钟、CDC、J11 和实体按键约束以及原时钟归一化步骤均保留。

`src/pl/bd/av_system.bd` 与 `build/pl/av_system.tcl` **仅作为原设计连线和地址配置的参考**，不作为正式构建入口。对它们进行全新 `validate_bd_design` 时，旧接口传播元数据将 `vdma_proto` 的目标协议推为 AXI4，但该转换器只接受 AXI3/AXI4LITE，因此检查失败。已发布硬件的真实配置是该转换器输出 AXI3，而后级总线接收 AXI4 子集。打包没有更改协议、跳过失败后声称通过，也没有改动已发布的 bitstream；改用实际结构连接源码保留原来硬件实现。

本次已完成：干净工程创建、39 个叶 IP 全部重新生成、39 份功能配置逐项一致性核对，以及 `synth_design -rtl` 展开检查（168 个外部端口、4 位实体按键，0 严重警告、0 错误；487 条普通警告）。详细结果见 `report/pl_package.json` 与 `build/reports/pl_package_checks.txt`。未重新运行完整综合、布局布线或上板测试；`build/reports/` 的时序等报告属于原已发布实现。重新完整构建后必须满足脚本保留的时序、未约束路径、DRC 和总线偏斜检查。结构构建只导出 bitstream；调整 PS 配置或地址映射后，需要重新建立有效的硬件交接描述，不能继续使用原 XSA。
