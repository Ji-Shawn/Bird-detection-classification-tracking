# Third-party notices

本工程包含项目代码、AMD/Xilinx 平台软件、FatFs 和 lwIP 等第三方内容。以下说明用于保留来源与许可边界，不为整个工程另行授予统一开源许可证。第三方源文件原有版权、许可和免责声明应继续保留；若某个文件有更具体条款，以该文件原文为准。

## 项目代码与模型

现有 M51 没有可证明覆盖全部项目代码及模型权重的根目录开源许可。此工程包不擅自选择 MIT、Apache、GPL 等项目许可证。项目作者与权重提供者对其内容的许可需由权利人明确。

部署模型与类别映射作为复现所需资产保留其来源记录与指纹。工程中没有完整训练数据及完整的数据、权重再发布授权证据。checkpoint 中的历史指标、训练路径或训练元数据不构成许可，也不代表当前整理包重新评测的结果。实际训练框架或模型结构名称不能代替对应权重的许可声明。

## AMD/Xilinx 平台软件

工程 BSP、FSBL 与驱动包含 AMD/Xilinx 版权内容。已检查的平台头文件包含允许复制、修改、分发的软件许可文本；当前 SDPS 驱动文件标记 `SPDX-License-Identifier: MIT`，版权属于 Xilinx, Inc. 及 Advanced Micro Devices, Inc.。保留逐文件的版权和许可头；不是所有文件都可以仅凭一个 SPDX 标记概括。

相关原始文件示例：`xil_types.h`、`xsdps.c`、`xsdps_host.c`、`xsdps_options.c`、`xsdps.h`。对这些软件的使用不包含对 Vivado/Vitis 工具、IP 核或其他专有组件的许可授予。工具与生成硬件所需 IP 仍由对应工具安装及其条款提供。

## FatFs

照片归档使用 FatFs R0.15 w/patch1，以及配套 `ff.h`、`diskio.h` 和 `ffunicode.c`。`ff.c`、`ff.h` 与 Unicode 模块保留 ChaN 的版权与许可。其核心许可文字如下，复制源代码时仍须保留原文件完整头部：

```text
Copyright (C) 2022, ChaN, all right reserved.

FatFs module is an open source software. Redistribution and use of FatFs in
source and binary forms, with or without modification, are permitted provided
that the following condition is met:

1. Redistributions of source code must retain the above copyright notice,
   this condition and the following disclaimer.

This software is provided by the copyright holder and contributors "AS IS"
and any warranties related to this software are DISCLAIMED.
The copyright owner or contributors be NOT LIABLE for any damages caused
by use of this software.
```

工程针对照片目录、日期读取、分块写入及 SD 协作调度的代码不改变 FatFs 原始许可。

## lwIP

平台网络组件包含 lwIP 2.0.2。其原始 `COPYING` 的许可如下；其他 lwIP 文件可能有各自的作者或许可头，应逐文件保留。

```text
Copyright (c) 2001, 2002 Swedish Institute of Computer Science.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
```

## 外部运行与开发依赖

Python、NumPy、Pillow、测试工具、编译器及 AMD/Xilinx 开发工具由使用者安装，不将本机软件安装目录视为项目源码。保留项目内随附第三方源码的原始通知；外部软件按各自版本许可使用。

## 整理原则

本包剔除个人运行日志、缓存和重复历史备份，规范文件路径；不能据此删除源码中的版权、作者归属或许可。原始历史清单中的路径字符串如果被整理为可移植路径，原始证据与打包后的新清单应分别记录，不能把改写后的文件冒充原始已封存文件。
