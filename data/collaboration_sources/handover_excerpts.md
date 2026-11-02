# 历史交接文件核对摘录

这些摘录是历史交接叙述及其中保留的日志片段，不是本轮重新运行结果。行号对应本次读取的原文件版本；文件整体 SHA256 见 provenance.json。以下保留原文，包括后来需要修订的判断；当前采纳结论见大模型协作报告和技能提炼过程。

## HANDOVER_vivado_v2.0.md

### 原文件第 132 至 166 行

> L0132 先校准 PMCCNTR(偏小 ~10x)再谈优化;首选 gpw 的 og 循环并行度 / gdw ch 组并行。
> L0133 另外 L00(STD conv0 3×3 s2 3→32)尚未上 PL(现跳过,靠 L01 黄金输入直灌),
> L0134 整网端到端还需要它(PS 实算或补 gstd 引擎)+ GAP/FC 头部(未抽黄金包)。
> L0135 
> L0136 ## 5g. 2026-09-26:POR 后重测 —— 推翻"流水即毒",真凶是边际时序(hold)
> L0137 
> L0138 **前置：板子已断电重启(POR)。复测阶梯全部重跑,结论大改:**
> L0139 
> L0140 1. **保守版基线:POR 后 62/62 全绿**(数据全量重灌)——流程健康。
> L0141 2. **B2'(保守版 + gpw MAC 拍平循环 II=1 流水):62/62 全绿 @100MHz!**
> L0142    → **"流水化有毒"彻底证伪**:§5f 期间 Step B/B2 的失败全是板子劣化污染,与流水线无关。
> L0143    流水线化是可用的性能手段。
> L0144 3. **B2' 实测 464ms/窗**(引擎+DMA 段合计,隔离模式;保守版为 ~1020ms,2.2×)。
> L0145    逐层分解显示**瓶颈已转移到顺序读/写瘦循环**(~17-20 拍/拍;L03 单层 70ms)。
> L0146 4. **perf 版(读顺序、bias/MAC/重组/写全流水)**:不挂了,但**确定性错数据**
> L0147    (L01 493B 错、两次复跑位置完全一致),且该构建 **WHS=+0.017ns**(hold 余量极薄;
> L0148    保守版 WHS=+0.024/0.050)。L01 是 DW(gdw 源未动),源级不可能错 → **构建级边际时序
> L0149    (hold)实锤存在**,且与是否流水化无关。→ 教训:WHS <0.05ns 的构建不可信,
> L0150    需要换 strategy(Performance_ExploreWithHoldFix)重出或降频验证。
> L0151 5. **"同源重建全错"之谜也解开了**:那是板子劣化期的污染,不是构建不确定性。
> L0152    健康板上同源构建行为可复现。
> L0153 6. **武器库新增**:drive_net_fast.tcl 第 5 参 FCLK50=1 可把 FCLK_CLK0 降到 25MHz
> L0154    (SLCR.FCLK_CLK0_CTRL @0xF8000170,DIVISOR0 5→20;IO PLL 1000MHz/(20×2))——
> L0155    边际时序 vs 协议 bug 的判别开关,免重出 bit。
> L0156 
> L0157 **当前认知**:流水线化安全(B2' 实证);真正的天花板是① 顺序瘦流循环的 ~17 拍/拍开销、
> L0158 ② 构建的 hold 余量。M5.5 继续方向:读/写循环流水化(B3 进行中)+ 64 位流 + 小层片上驻留。
> L0159 
> L0160 ### 5g 续:B3/B4 实验与当前收尾状态
> L0161 
> L0162 - **B3(B2'+读循环流水)**:回归挂于 L14/L15(装载阶段),L02 单跑也挂 → **含 `in.read()` 的
> L0163   循环流水化 = 挂,实锤**(B2' 对照组同板同时段全绿,排除板子因素)。
> L0164 - **B4(B2'+写循环流水)**:3/62、L01 起全错(WHS 0.057 健康)→ 含 `out.write()` 的循环
> L0165   流水化也不可用(或受板子/数据状态污染,未完全定锤,但不值得再赌)。
> L0166 - **引擎定式(健康板实证)**:**流读写循环必须顺序(PIPELINE off),纯计算循环(MAC)可流水

### 原文件第 188 至 207 行

> L0188   **隔离回归 62/62 零差异 + 链式 top1=11=golden,引擎+DMA 段 345.8ms/窗**
> L0189   (32 位 B2' 为 464ms;逐拍瘦循环开销摊薄不及预期,1.34× 而非 2×)。
> L0190 - 结构 = B2' 定式加宽:读/写顺序(PIPELINE off)、MAC 流水 II=1、gpw MAC 为
> L0191   16 bank×4 lane(DSP 188/220;8 lane 会 251 超编);wbank/lb/行缓存 64 位字,
> L0192   权重/bias 装载拍数减半(w_words=CIN*CT/8、b_words=CT/2;DW 为 C*9/8、C/2)。
> L0193 - **AXI DMA 陷阱**:流口位宽是独立参数,不随 M_AXI 变——只改 `c_m_axi_*_data_width`
> L0194   会得到 MM2S 流 32 位 + 引擎 64 位被自动补零的静默坏 BD(HDL 自检照不到,
> L0195   因为只查绑死常量);必须显式 `c_m_axis_mm2s_tdata_width`/`c_s_axis_s2mm_tdata_width`。
> L0196   **新自检:集成后查 `system.v` 的流 TDATA 线宽声明(应为 [63:0])。**
> L0197 - 32 位基线备份:`vitis_workspace/dma_loopback/src/main_32bit.c.bak` +
> L0198   `D:/Xilinx/workspace/dma_loopback_32bit_b2prime.elf`。
> L0199 - 剩余差距 ~7×:下一步是跨层融合/小层片上驻留(结构性,另开 milestone),不再折腾流拍。
> L0200 - **perf2(requant 入流水 + 薄写循环)**:62/62 绿,338.2ms——只比 64 位版快 2%。
> L0201   **由此定位真瓶颈:每像素 ~400 拍的 FSM 状态开销**(HLS 顺序循环的逐拍状态步进 +
> L0202   子循环进出),不是 requant、不是 DMA 饥饿。L03(expand 层)59ms 为最大头。
> L0203   要破这个墙只剩两条路:① 像素级 dataflow 重叠(三定律 #1 的高危区,需专门验证
> L0204   帧重启);② 手写 RTL 取代 HLS 瘦循环。已远超渐进优化范畴,建议另开 M6.5 里程碑评估。
> L0205 - **perf2 的链式验证未完成**:两次尝试都撞在板子 wedge(第二次 ELF 下载中途断链)。
> L0206   引擎与 64 位版同构(链式 top1 已在那版验证),POR 后补跑 `drive_net_fast.tcl 0 1` 即可。
> L0207 

### 原文件第 217 至 270 行

> L0217 - **xsim 全绿**:PW 34/34 层 + DW 17/17 层零差异(经 wrapper 级复验,多瓦片/多帧连跑都过)。
> L0218   TB:`pw_tb_wrap.sv` / `dw_tb_wrap.sv`(并发捕获缓冲模式,层表从 layer_table.h 生成:
> L0219   `pw_layers.txt` / `dw_layers.txt`)。
> L0220 - 集成脚本 `integrate_m64rtl.tcl`(module reference;注意:BD module ref 顶层不许 .sv,
> L0221   故 wrapper 为 .v;改引擎后必删 `m1_dma_loopback.gen/sources_1/bd/mref/` 陈旧缓存)。
> L0222 
> L0223 **当前卡点:DSP 超编**。两核独立综合 pw=162 / dw=177 DSP,合计 339 > 220。
> L0224 根因:Vivado 把组合加法链也往 DSP48 里塞(MAC 之外约 100 DSP/核);HLS 版靠跨模式
> L0225 资源共享只出一份。**下一步方案:wrapper 里做一个共享 MAC 池(两核互斥运行,计算相交给
> L0226 共享池)**——重构量中等,两核的控制 FSM 与缓存结构不变。
> L0227 
> L0228 **备选/后续**:若共享池也紧,dw 降 8lane×9t 为 4lane×9t 两拍(DW 时间加倍可接受);
> L0229 requant 乘法可 `use_dsp="no"` 换 LUT(对本例属性未生效,需查实写法)。
> L0230 
> L0231 **注意**:当前 impl_1 的 bit 仍是 HLS perf2 版(338ms 基线,上板全绿),没被 RTL 版覆盖。
> L0232 独立综合快速验证:`vivado -mode batch -source D:/Temp/memtest/synth_pw.tcl`(读 dw/pw util)。
> L0233 
> L0234 ## 5f. 2026-09-24 session:伪 bug 证伪 + 真 bug 定位与修复(部分结论已被 §5g 推翻)
> L0235 
> L0236 ### 最终状态(本 session 收尾时)
> L0237 
> L0238 - **现役源(m5_hls_block/,保守融合版)在板子健康时完整验证通过:62/62 零差异 + 链式 top1=11=golden。**
> L0239 - **但当前 impl_1 的 bit 是同源重建版,验证时被劣化的板子污染(全错)——未单独复验。**
> L0240   POR 后第一步就是复验它(或先用 m54ila.bit 做基线对照)。
> L0241 - 现役引擎源:gpw 像素阶段保守融合结构(读写算一体、全顺序、`UNROLL factor=1` + `PIPELINE off`);
> L0242   gdw 像素循环同。csim 51 层零差异,零 214-376 自动流水化。备份:`gpw_layer_v2_conservative.cpp.bak` 等。
> L0243 - 实测基线(链式,51 层合计,健康板)≈1020ms/窗;距 <50ms 目标 ~20×。
> L0244 
> L0245 ### 结论速览
> L0246 
> L0247 1. **§5e 未决问题 1("多瓦片 PW 第 2 帧挂")证伪——从来不是引擎 bug**。真凶二合一:
> L0248    - **DDR 黄金数据腐烂**:wedge 事故期间个别字节被改写(实测 GOLDIN(2) 偏移 0x0D 处 0x80→0x00)。
> L0249      只灌一次数据就反复跑的"快速重跑"前提不成立。症状可完美伪装成引擎 bug(全字节错/挂起)。
> L0250    - **DAP wedge 反复**加深了混乱。
> L0251    - 铁证:`system_wrapper_m54ila.bit`(09-22,62 项回归全绿时代的引擎)+ 全量重灌数据 →
> L0252      **62/62 零差异**,L02 连跑稳定。**板子、BD、DMA、旧引擎全部无恙。**
> L0253 2. **真问题:09-23 的引擎重构("读-算-重组-写分离" + 撤除装载循环 PIPELINE off)上板 100% 挂死**,
> L0254    DW/PW 同症、从第 0 帧就挂。csim/cosim(含 `-random_stall`)全绿,**此 bug cosim 原理性不可复现**,
> L0255    别再信 cosim 当板级判官。
> L0256    - ILA 波形(ila_m55_dw.csv=L01 DW 挂死帧;L02 PW 同形态):
> L0257      引擎寄存器全部正确;引擎正常吃流、产出约 38 px 后,**S2MM TREADY 中途掉低不复返**
> L0258      (DMASR=0 无错误标志、busy),引擎守规矩背压后死锁。
> L0259    - 好引擎对照(ila_m54_good.csv):beat 稀疏模式相同 → 稀疏非诱因;好引擎的 TREADY 回压
> L0260      是瞬态,重构版是永久。**⚠️ §5g 注:这些 ILA 观测是在板子劣化期做的,当时"挂死"本身
> L0261      就是劣化症状——POR 后流水化版本(L02)实测通过,本节归因作废,真实问题是边际时序+板子劣化。**
> L0262    - 教训:任何"结构性性能优化"必须逐小步上板验证;csim/cosim 绿了不等于上板能跑。
> L0263 3. 09-23 晚 §5d 的 M5.5 性能数字(L03 11.5ms、325ms 基线等)是在重构版引擎上测的,
> L0264    **可信度存疑**(彼时已有 wedge/数据腐烂),下轮性能收口需用现役保守版重测基线。
> L0265 
> L0266 ### 新工具(全部已验证)
> L0267 
> L0268 - **`drive_net_fast.tcl`**(现役主力,参数:`[LRANGE] [CHAIN] [BIT] [LOAD]`):
> L0269   DAP 自愈链(fpga 重载 → `rst -system` → after 500 + 空 `targets` 重枚举 → ps7_init/post_config →
> L0270   mwr 探针,3 次重试,**大多数 wedge 免 POR**);LOAD=1 时全量重灌黄金数据;结束后打印


## HANDOVER_vivado_v3.0.md

### 原文件第 1 至 96 行

> L0001 # 交接文档 HANDOVER v3.0 —— M6:全 HDL 化(摆脱 HLS)
> L0002 
> L0003 > **⚠ 本文档已被 v4.0 取代:当前入口是 `HANDOVER_vivado_v4.0.md`**。
> L0004 > 本文保留 M6 全过程的证据链(假绿/真 bug/时序/陈旧产物/DAP wedge),教训细节仍要读。
> L0005 
> L0006 > 写给下一位接手本项目的 agent。**目标路线变更:引擎不再用 HLS,全部手写 HDL。**
> L0007 > 原因(M5.5 血泪):① HLS 顺序循环每像素 ~400 拍 FSM 开销,性能墙拆不掉;
> L0008 > ② HLS 流水化循环含流操作上板即挂且 csim/cosim 照不到;③ HLS 会偷偷自动流水化
> L0009 > (日志 214-376),改 pragma 如走钢丝;④ 生成 RTL 不可读,边际时序 bug 无从调试。
> L0010 > 手写 RTL:结构透明、时序可控、ILA 信号有意义。
> L0011 >
> L0012 > **先读 `skills/zynq-pl-accel/SKILL.md`(21+ 条踩坑全记录),再读本文件。**
> L0013 > 历史:v1.0 = Phase 0/1;v2.0 = M5.4 整网 + M5.5 排障/64 位化全过程(§5f/§5g 仍有效,详录排障证据)。
> L0014 
> L0015 ## 1. 项目一句话
> L0016 
> L0017 音视双模态鸟类识别(SSW60,60 种北美鸟),ALINX AX7020(XC7Z020-2CLG400),Vivado/Vitis/HLS 2023.2。
> L0018 任务:MobileNetV2-1.0 int8 QDQ 推理链路上 PL。模型侧永不重训。
> L0019 
> L0020 ## 2. 当前基线(已上板验证,别破坏)
> L0021 
> L0022 - **现役 bit**:`D:\Xilinx\workspace\m1_dma_loopback\m1_dma_loopback.runs\impl_1\system_wrapper.bit`
> L0023   = **M6 手写 RTL 引擎(pw/dw 双核 + 共享乘法池),隔离回归 62/62(L24 1 字节 tie,main.c 特判),
> L0024   链式整网 top1=11(与 HLS 时代文档一致),引擎+DMA 段合计 ≈368ms/窗(与 HLS perf2 的 338ms 持平)**,
> L0025   时序 WNS≥+0.05/WHS≥+0.04,DSP 35/LUT 23K/BRAM 50。
> L0026   **链式挂死破案(2026-09-28):不是设计问题,是 DAP wedge 级联**(链式长连跑中一次
> L0027   "Memory write error 0x100000 / DAP 0xF0000021" 毒化后续全部运行)。恢复链(免 POR,已验证):
> L0028   `xsct dap_recover.tcl`(fpga 重载→DAP rst -system→重枚举→ps7_init→DDR 探针)。
> L0029 - **现役引擎源(RTL,主战场已完成)**:`D:\Xilinx\workspace\m6_rtl\`
> L0030 - **现役裸机编排器**:`D:\Xilinx\workspace\m1_dma_loopback\vitis_workspace\dma_loopback\src\main.c`
> L0031   (64 位版;32 位备份 `main_32bit.c.bak` + `D:\Xilinx\workspace\dma_loopback_32bit_b2prime.elf`)
> L0032   构建:`cd vitis_workspace/dma_loopback/build && D:/Xilinx/Vitis/2023.2/gnuwin/bin/make.exe`
> L0033 - **基线备份**:HLS perf2 时代 bit 可从 `system_wrapper_m64.xsa`(2026-09-26)恢复。
> L0034 
> L0035 ### 性能演进(引擎+DMA 段/窗)
> L0036 
> L0037 ```
> L0038 1020ms 全顺序 HLS → 464ms MAC流水(B2') → 345.8ms 64位流(HWC8) → 338ms perf2
> L0039 ≈368ms RTL 引擎 v1(上板实测,与 HLS 持平;dw 拍率 8 拍/拍串行 PH1/PH2/PH3 是主要欠账)
> L0040 目标 <50ms —— 下一步:dw 拍间流水化(PH1/PH2/PH3 交叠)+ 跨层融合(消 DDR 往返)
> L0041 ```
> L0042 
> L0043 ## 3. 手写 RTL 引擎现状(M6-RTL,已完成)
> L0044 
> L0045 **位置:`D:\Xilinx\workspace\m6_rtl\`**
> L0046 
> L0047 | 文件 | 内容 | 状态 |
> L0048 |---|---|---|
> L0049 | `pw_core_rtl.sv` | PW 核(4 级 MAC 流水 + S_DRAIN + S_WRITE 3 拍输出流水) | **真 xsim 34/34 零差异** ✓ |
> L0050 | `dw_core_rtl.sv` | DW 核(PH1/PH2/PH3-6 拍;行缓存当拍组合地址读) | **真 xsim 17/17 零差异** ✓ |
> L0051 | `mac_pool_rtl.sv` | 共享乘法池:72 路 10×8 + 8 路 32×32 requant,输入/积全寄存,rq 带 pipe_en 冻结 | ✓ |
> L0052 | `mnet_engine_rtl.v` | 双模式顶层(wrapper 持寄存器文件,r_mode 选通核与池) | ✓ |
> L0053 | `pw_engine_rtl.sv` / `dw_engine_rtl.sv` | 单核 AXI 版(退役参考,已同步修复符号 x/lb 地址) | — |
> L0054 | `pw_tb_wrap.sv` / `dw_tb_wrap.sv` | TB(随机反压;`string dir`;bias 按字节装配;cap_n 初始化) | ✓ |
> L0055 | `m1_dma_loopback/integrate_m64rtl.tcl` | 集成脚本(含三层陈旧产物清理) | ✓ |
> L0056 
> L0057 **契约(与 HLS 版逐位一致,main.c 不变)**:s_axilite 寄存器 CTRL@0x00(bit0 ap_start 自清、
> L0058 bit2 ap_idle)、mode@0x10、mul@0x18、shift@0x20、x_zp@0x28、y_zp@0x30、n@0x38、c@0x40、
> L0059 w@0x48、cout_t@0x50、w_words@0x58、b_words@0x60、stride2@0x68、out_chunk@0x70;
> L0060 帧 = [w 字][bias 字][像素];64 位 HWC8;requant 恰半向偶 shift=28;DW 边界垫 x_zp。
> L0061 
> L0062 ### 真 bug 全记录(2026-09-27,均被 TB 假绿掩盖,板上实证后逐个挖出)
> L0063 
> L0064 1. **TB 路径左补零**:`$fscanf %s` 读进宽 reg → `$sformat` 路径前导 NUL → golden 全 X →
> L0065    **X!==X 假通过,数月假绿**。修:TB 改 `string`。教训:验 TB 先 display 一个 golden 读回值。
> L0066 2. **TB `$fread` 进 32 位数组字节交换**:bias 全错。修:按字节读 + 手工装配。
> L0067 3. **dw 行缓存读地址**:非阻塞语义下 `lb0_rd <= lb0[addr_r]` 在 PH1 末沿采到上一拍旧地址
> L0068    (通道组错位)——** dw 全灭主因**。修:读地址用当拍组合 `lb_addr_c`。
> L0069 4. **dw bbank 组索引**:`cnt[6:2]` 只能数到 31,C>256 的 bias 高组缺载+别名覆盖。修:`cnt[8:2]`。
> L0070 5. **pw 像素符号**:零扩展 `{1'b0,x}` 使负像素全偏 +256——**pw 全灭主因**。修:`$signed(x)`。
> L0071 6. **pw bias 末组**:cout_t 非 16 倍数时 512 位组装不满,高组 bias 永不写回。修:末拍右移补齐。
> L0072 7. **流水 backpressure 跳字**(pipe_en 冻结,已修;TB 加随机反压防回归)。
> L0073 8. **L24 1 字节 tie**:acc=7157 vs 7156 的恰半边界(引擎与 numpy 独立模型一致),
> L0074    main.c 已有 `bad<=1` 特判,接受。
> L0075 
> L0076 ### 上板前自查清单(本轮新坑全在这)
> L0077 
> L0078 1. `vivado -mode batch -source D:/Temp/memtest/synth_pw.tcl`(dw 同)先过独立综合资源关
> L0079    (DSP ≤ 220 合计、LUT ≤ 53K、BRAM ≤ 140)。顶层检查用 `synth_top.tcl`(含 mac_pool)。
> L0080 2. BD module reference:顶层文件必须 .v(不许 .sv);改引擎后**三层陈旧产物全清**
> L0081    (mref/ + ip/system_mnet_engine_*/ OOC 产物 + IP cache 里的 mnet 条目,
> L0082    `integrate_m64rtl.tcl` §2 已内置);`integrate_m64rtl.tcl` 里有
> L0083    `reset_run` 全部 mnet run 的语句(别删)。验收:新网表 grep 新信号名命中才算数。
> L0084 3. 存储纪律:大数组必须 BRAM(同步读写)或 LUTRAM(1D + `ram_style="distributed"` +
> L0085    单异步读口);**多维 unpacked 数组不推断存储**;宽字打包(每拍整字读写)是唯一安全形态。
> L0086 4. **xsim 复验两个 wrap TB 全绿后,才许出 bit**——且 TB 必须先证明不是假绿
> L0087    (display golden 读回值非 X)。
> L0088 
> L0089 ### 已解决的卡点:DSP 超编(339 > 220)与时序收敛
> L0090 
> L0091 根因(综合日志实证):不是乘法数量,是**操作数位宽**——`(x-xzp)` 被扩成 32 位,
> L0092 每个 8×32 乘法吃 2 个 DSP48(pw 162 + dw 177)。解法已实施:**wrapper 内置共享池**
> L0093 (`mac_pool_rtl.sv`):72 路窄位宽 10×8 MAC(两核互斥,`r_mode` 二选一驱动)+ 8 路共享
> L0094 32×32 requant。结果:**DSP 35 / LUT 23K / BRAM 50**(全绿,余量巨大)。
> L0095 
> L0096 **时序三连坑(同轮解决,血泪)**:


## HANDOVER_vivado_v5.0.md

### 原文件第 1 至 22 行

> L0001 # FPGA 支线交接 v5.0 —— PW 128 路时序排障暂停点
> L0002 
> L0003 > **当前入口，2026-10-02 更新。** 保留历史暂停与排障记录；更换电源后的最新板测见 §11。
> L0004 > 新会话按顺序读：① 本文件；② `skills/zynq-pl-accel/SKILL.md`；③ `deploy_plan_v2.0.md`。
> L0005 > M6 全过程证据回查 `HANDOVER_vivado_v3.0.md`，截至 9 月 28 日的历史基线回查
> L0006 > `HANDOVER_vivado_v4.0.md`。本轮原始板测与实现证据见 `M7_pw_128lane_20260928.md`。
> L0007 
> L0008 ## 1. 一句话状态
> L0009 
> L0010 AX7020 / Vivado+Vitis 2023.2 的音视三模型共用 RTL 引擎支线。目前**现役仍是已上板验证的
> L0011 72 路共享乘法池版本**：音频隔离 62/62、链式 top1=11，E1–E51 约 84.44ms/窗。
> L0012 原 128 路 PW 候选把同条件 E1–E51 降至 63.696ms，但 **100MHz 连续运行不稳定，绝不可替换现役 bit**。
> L0013 为修正其 PW 累加关键路径，已在独立目录增加一拍寄存。双 TB、C=1280 定向仿真与独立顶层实现通过，
> L0014 严格 hold 检查下 WNS +0.230ns、WHS +0.012ns。10 月 1 日新候选完成隔离 62/62（沿用既有
> L0015 判定规则）及 **100MHz 连续三轮链式 top1=11**，逐层误差统计与旧版一致，无 DMA 超时；
> L0016 E1–E51 平均 **64.064694ms**，比同次上电旧版 **84.454713ms 缩短 24.143%**。
> L0017 本轮完成中断的验证，独立候选保留，现役文件未替换。PS 冷初始化期间的 POR 原因仍未解决；
> L0018 本次使用成功初始化后保留 PS/DDR 状态的 PL 重配置，不能据此宣布冷启动可靠，详见 §8。
> L0019 
> L0020 ## 2. 不要混淆的三套文件
> L0021 
> L0022 | 用途 | 路径 | 状态（更新至 2026-10-01） |

### 原文件第 531 至 550 行

> L0531 若输入先下跌，查外部供电；若输入稳定而板上电源下跌，查稳压/负载；若电源稳定而 POR
> L0532 出现低脉冲，查复位链路。没有这些测量，目前无法远程区分适配器故障与板上器件故障。
> L0533 微弱啾声仅是现场现象，不能据此确定晶振损坏。本轮原因核对未再次触发 DCI，未修改 RTL
> L0534 或 bit，硬件保留 §10.1 的双核停止状态。
> L0535 
> L0536 ## 11. 2026-10-02 更换故障适配器后上板验收完成
> L0537 
> L0538 用户确认故障来自原电源适配器，更换新电源后恢复，明确要求继续上板。
> L0539 本轮证据目录 `m9_visual_deploy/board_20261002_095532/`，独立于之前失败日志。
> L0540 新旧 bit 哈希与 §8 一致，离线包审计通过，未重建或替换 RTL/bit/ELF。
> L0541 250kHz 连接 PS ID 连续20/20；随后1MHz 标准 `ps7_init` 一次完成，A5 POR 标记保持，
> L0542 旧 bit 下载和四种 DDR 图案读写均通过，FCLK0=0x00200500（100MHz）。
> L0543 没有使用 `resume_after_mio` 或跳过失败初始化；这是更换电源后的直接复测证据。
> L0544 旧版音频隔离全量重灌后62/62符合历史判定，包括跳过stem和L24舍入特例。
> L0545 后续套件 `run_board_20261002.ps1` 保持PL 100MHz，JTAG数据传输使用3MHz、1KiB块；
> L0546 串行运行旧版链式、候选隔离与三轮链式、视觉和SSD各自隔离/链式，任一验收失败即停。
> L0547 `suite.log`、逐项日志与 `passed_tests.json` 记录实际进度；尚未结束的项不能当作通过。
> L0548 
> L0549 ### 11.1 音频验收与视觉加载异常的处理
> L0550 

