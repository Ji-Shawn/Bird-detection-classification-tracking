# SKILL: Zynq-7020 PL 加速开发实战手册

> 适用场景:在 Zynq-7020(本例 ALINX AX7020,Vivado/Vitis/Vitis HLS 2023.2)上用 HLS 写算子、
> 经 AXI DMA 与 PS 协同、对黄金模型做逐层数值验证。本文是两次大排障(M1 数据通路、M5.1/5.2 算子)
> 沉淀的完整方法论。**先读本文再动手,可省数十小时。**

## 0. 总开发闭环(每个算子都走这条路)

```
HLS C 源 → csim(黄金数据对拍)→ csynth(查资源/结构)→ export IP
→ BD 集成(替换引擎单元)→ HDL 自检(搜绑死常量)→ 综合实现出 bit
→ xsct:复位→ps7_init→下bit→ps7_post_config→灌数据→跑→邮箱/串口读结果
```

铁律:**每一步都要有可复现的数值检查点**;csim 全对才许上板;上板对拍对象永远是黄金模型,不是"看起来合理"。

## 1. Zynq 数据通路(PS↔DDR↔PL)

### 1.1 标准结构

- Zynq PS( preset TCL 配 DDR/MIO/时钟,板厂提供)+ **AXI DMA(simple 模式)** 挂 S_AXI_HP0(2 从口时 interconnect 必须 NUM_SI=2!)+ AXI4-Stream 环回(FIFO 或 HLS 算子)
- DMA 控制口挂 M_AXI_GP0;HLS 算子控制口挂 GP0 第二路(典型 0x43C00000)
- FCLK_CLK0=100MHz 全局同钟;proc_sys_reset 的 peripheral_aresetn 统一复位

### 1.2 必知陷阱(按代价排序)

1. **BD 单针桩网**:GUI 里手动断开接口内单信号 → 生成单针 stub net,**静默覆盖**接口级连接,界面不可见。症状:综合 `8-4442 BlackBox has unconnected pin`、信号绑常量、引擎假死。**排查:看生成的 `synth/system.v` 搜 `(1'b0)` / `(1'b1)`;修复:删全部单针桩网 + 补接,并验证 address map 和 interconnect NUM_SI/NUM_MI。** 批处理脚本里应带"单针桩网清理循环 + HDL 绑死自检"两道保险。
2. **AXI DMA 寄存器偏移(PG021)**:MM2S_DMACR=0x00、DMASR=0x04、SA=**0x18**、LENGTH=**0x20**;S2MM_DMACR=0x30、DMASR=0x34、DA=**0x48**、LENGTH=**0x50**。SA/LEN 不是 0x48/0x58!**Reset 位是 bit2(0x4)**:`DMACR=0x00010002` 是健康上电值(bit1+bit16),不是复位卡死。
    **(2b, 2026-09-26)流口位宽是独立参数**:改 `c_m_axi_*_data_width`(M_AXI 侧)**不会**自动改流口——只改前者会得到不对称流口(MM2S 32 位 vs S2MM 64 位),对端 64 位 IP 被连接自动化**静默补零**(生成网表里 `in_r_TDATA({32{1'b0}, ...})`),绑死自检照不到。必须显式设 `c_m_axis_mm2s_tdata_width`/`c_s_axis_s2mm_tdata_width`,集成后查 `system.v` 的 TDATA 线宽声明应为 [63:0]。
3. **启动顺序铁律**:PS 复位 → `ps7_init` → **下 PL bit** → `ps7_post_config`(开电平转换器+释放 fabric 复位)→ 下 ELF → 跑。电平转换器开着时配 PL 会闩死 HP0;launch.json 里 ps7_init 后**不许再有 rst-processor**(会清掉 DDR 配置 → "Memory write error at 0x100000")。
4. **hw_server 拦 PL 地址**:`Blocked address ... not been added to the memory map` → 用 `memmap -addr 0x40400000 -size 0x10000 -flags 3` 解锁(APU target 上下文能读,A9 上下文读 PL 地址会被拦)。
5. **DAP 卡死**(`APB AP transaction error, DAP status 0xF0000021/0x30000021`):调试口闩死。预防:别在 PL 复位期间让 PS 访问 PL(总线挂死毒化 DAP)。**恢复(2026-09-24 验证,多数情况免 POR)**:`fpga` 重载(清 PL 侧悬挂事务)→ 对 DAP target `rst -system`(清 PS 侧悬挂)→ `after 500` + 空 `targets` 强制重新枚举 → `ps7_init` + `ps7_post_config` → mwr/mrd 探针验证 DDR 可写。仅当此链失败才真正需要断电。注意 `rst -system` 会清掉 DDR 控制器配置,**之后必须重跑 ps7_init**,否则报 "Cannot access DDR: held in reset"——这比 DAP wedge 表象轻,别误判成卡死。**2026-09-26 追加:板子连续工作数小时不 POR 会持续劣化(失败率上升直至恢复链失效)——长 session 收工前主动断电;每次跑完测试后脚本要 `stop` 住 A9(否则它空转轮询 DMA 寄存器,下次 fpga 重载必撞毒 DAP)。**
6. **UART 路由**:AX7020 USB 串口接 **PS UART1(MIO48/49)**,但 standalone BSP 默认 stdout=ps7_uart_0 → 打印静默丢失。改 BSP(或 bsp.yaml)stdin/stdout=ps7_uart_1,重建 platform。**裸机备用信道:DDR 邮箱**(固定地址写状态码,DAP mrd 读)——比串口可靠。
7. **SDT 流程 API**:2023.2 Unified IDE 的驱动库里 `X*_LookupConfigBaseAddr` 头文件声明了但库里没有,用 `X*_LookupConfig((UINTPTR)基地址)`(SDT 下它吃基地址不是设备号)。
8. **Vitis Unified vs Classic**:Unified 的 launch 配置要手动管 bitstream 路径与 ps7_init.tcl;`vitis-comp.json` 的 `"xsa"` 字段可直接改后重建。
9. **平台/BSP 重建会重置 BSP 配置**(stdin/stdout 会被打回 uart_0,重建后必须复查)。
10. **Cache 一致性**:CPU 写后 flush、DMA 写后 invalidate,按 range 对齐 cache 行;APU/DAP 读 DDR 是物理视角(CPU cache 里的脏数据看不见)。
11. **harness 地址图重叠**(M5.4 最痛的坑):黄金数据/权重/期望分区灌 DDR 时,槽位地址公式必须画重叠检查表——我们 EXPCT(i)=base+i×2MB 与 WGHT(j)=base+j×1MB 交叠,**偶数槽权重被覆盖 → 严格隔帧交替全错**,极易误判为引擎跨帧污染。配套纪律:结果表先清 DEADBEEF、邮箱 magic/done 最后写先清零、探针间 fpga 重载清 PL 状态。
    **姊妹坑(2026-09-24 实证):DDR 数据腐烂**。跳过重灌的"快速重跑"默认 DDR 里的黄金数据仍完好——但 DAP wedge 事故/异常运行会静默改写个别字节。症状可完美伪装成引擎 bug(全字节错、甚至伴随挂起),且**换新旧 bit 都一样错**。本session 为此把"多瓦片 PW bug"白查一轮:最终靠"旧 bit(62 项全绿时代)+ 全量重灌 = 通过"定位。纪律:**任何 wedge 事故之后,先怀疑 DDR 内容**;快速重跑前抽查若干字节(mrd 对比 .bin),或直接全量重灌;判案第一实验永远是"已知好 bit + 新灌数据"。
12. **cosim(RTL)是引擎 vs harness 的判官**:csim 全绿 + 板上挂 → 跑一次多层连跑的 cosim;cosim 绿 = 引擎 RTL 无辜,回头查 harness(地址图/脚本/DMA 序列),别在引擎里瞎翻。
13. **多层多帧场景用 ap_ctrl_hs + 流前缀协议**(帧=[权重字][bias 字][像素]):PS 先写全部标量寄存器、最后写 ap_start;下一帧前等 ap_idle。s_axilite 大数组是 FF 黑洞(每元素 64 位槽),权重表必须走流。
14. **fpga 下载前必须先停 A9**:旧程序若在轮询 PL 侧寄存器(DMA/引擎),PL 复位瞬间的未完成 AXI 事务会挂死总线并**毒化 DAP**(之后一切 `dow` 报 "MMU section translation fault",只有断电 POR 能恢复)。所有驱动脚本顺序:`stop A9 → fpga → ps7_init → ps7_post_config`。
15. **ps7_init.tcl 只定义函数**:断电后必须**显式调 `ps7_init`** 再 `ps7_post_config`,否则 DDR 控制器保持复位("Cannot access DDR: the controller is held in reset")。
16. **邮箱参数读前必须 `Xil_DCacheInvalidateRange`**:A9 复用上次运行的 D-cache 行,命令块参数会读到陈旧值(magic 等待循环本身恰好也常命中旧 magic,掩盖此坑)。
17. **永远别写 SCU 私有/全局定时器寄存器**(0xF8F00200 GTCR / 0xF8F00600 系列):写后当次挂死,且**持久毒化板级状态**(rst-processor 无效,只能断电 POR)——之后的运行全部产出确定性错误结果,极具迷惑性。计时标定改用主机时间戳或纯 PMCCNTR 比值法。
18. **M5.5 性能实测要点**:PMCCNTR 默认 ÷64 分频(1 拍≈96ns,别当 CPU 拍算);HLS 里**独立的瘦流循环**(只读/只写流的循环)实测 ~17 拍/拍,而读写算一体的胖循环可到 ~2.6 拍/拍——性能结构先把计算融进流循环,别拆成纯搬运阶段。
19. **时序报告全绿 ≠ 被检查过**:读报告必须先看 Unconstrained Path Table 和 unconstrained_internal_endpoints——"没约束的路径不会被检查,自然满分"。本工程已查:无未约束路径(2026-09-24)。
20. **ILA 会改变布局布线 → 时序表现会变**("加 ILA 病就好了/好板子加 ILA 反而坏"都是同一原理):所以"带 ILA 的 bit 能跑、不带就挂"不能证明逻辑无辜,只能证明临界路径对布局敏感。判案要用不带 ILA 的构建,或接受 ILA 版结论只能当线索。同理,"同一源码两次构建一致性不同"是边际时序的典型特征。
21. **上板疑难排查顺序**(别上来就加 ILA):① Timing Summary(WNS/TNS + 未约束路径)→ ② CDC(本工程单钟域,免)→ ③ 复位释放(异步复位同步释放,proc_sys_reset 已处理)→ ④ 关键状态寄存器初始化 → ⑤ ILA 少而精(握手/FIFO 标志/状态机,别塞 500 根信号)。

### 1.2b 手写 RTL 时代(M6,2026-09-27 实证)

22. **乘法操作数位宽决定 DSP 数**:`(x-xzp)` 被符号扩展成 32 位后,每个 8×32 乘法吃 2 个 DSP48(加法链还会被吸进 DSP ALU);把被乘数窄到真实值域(如 10 位)再乘,每路 1 个。两核互斥的引擎把乘法集中到 wrapper 共享池(72 路 10×8 + 8 路 32×32),DSP 从 339 降到 35。
23. **数据通路时序三忌**(各坑掉一轮构建):① 禁止运行时 `%`/`/`——取模是 76 级 CARRY 组合除法器,换计数器比较(等语义);② 准静态派生量(如 requant 的 `half=1<<(shift-1)`、`mask=(1<<shift)-1`)必须**寄存一次**,别在多路循环里逐拍重算移位;③ "乘→求和→requant 乘→移位舍入"塞一拍必炸(68 级),乘法 2 拍化(输入寄存+积寄存,全关进 DSP AREG/MREG),舍入再拆两级——**吞吐不降,只加延迟**,控制流水对齐即可。`frac = t48 & mask` 与 `t48 - (vf<<shift)` 恒等,可省一条移位链。
24. **module reference 陈旧产物三连环**:改 RTL 后出的 bit 可能是旧 RTL——① `bd/mref/` 缓存;② `bd/system/ip/<cell>_*/` 的 OOC 综合 DCP(同名新 cell 直接复用);③ **工程 IP cache**(`<proj>.cache/ip/...`,缓存键只含端口配置不含 RTL 内容,最阴)。三层全清后,**在新网表里 grep 一个只有新代码才有的信号名**做验收;WNS 与上次逐位相同 = 用了旧 RTL。
25. **源文件也会被"幽灵回写"**:构建前对关键源 grep 特征串确认版本(本轮 dw_core_rtl.sv 在构建前被不明进程还原成旧版,xsim 过了但集成报错才暴露)。
26. **流水寄存器在 backpressure 下必须用使能冻结**:输出停顿期间 cnt 冻结但管道寄存器若继续移位,恢复时跳字(1 拍停顿跳 1 字;xsim 恒 TREADY 照不到)。TB 必须加**随机反压**(`out_tready <= ($urandom_range(0,3) != 0)`),共享乘法单元的输入/输出寄存器接 `pipe_en`。
27. **非阻塞赋值的"旧值"陷阱(最难自查的一类)**:同一 always 块里 `addr_r <= new; rd <= ram[addr_r]` —— rd 采到的是**旧** addr。读地址必须用当拍组合值(`rd <= ram[lb_addr_c]`),或提前一级寄存地址。症状:数据"大体对但普遍小偏差",xsim/板上完全一致地错。
28. **数值契约逐字节核对**:int8 像素必须 `$signed(byte)`(零扩展会让所有负像素偏 +256);宽字装配的**末组不满**要在计数终点右移补齐写回(否则高组永远缺载);组索引位宽按最大组数算(`cnt[6:2]` 只能数到 31)。

### 1.3 DMA 驱动要点

- simple 模式单次 LENGTH ≤ 16383(14 位)。大张量**分块**(按算子像素对齐选块长);块间无需重新软复位。
- S2MM 先挂、MM2S 后发;Busy 轮询要带超时上限;错误通道 Halted 后 Idle 永不置位(轮询死等 → 超时返回)。
- `XAxiDma_CfgInitialize` 会做软复位并等 ResetIsDone,**它返回成功 = 复位完成**(据此可区分"复位没完成"与"别的错")。
- tlast:MM2S 每块尾拍自动生成;S2MM simple 模式按字节数完成,**tlast 提前 = DMAIntErr**,tlast 与块尾对齐是设计责任(见 §2.4)。

## 2. HLS 算子开发(2023.2,Vivado IP Flow)

### 2.1 文件与仿真

- 源文件用 **.cpp**(用 .c 会被当 C 编,ap_int 模板直接炸)
- csim 会"make up to date"**不重建** —— 改源后必须 `rm -rf <proj>/<sol>/csim` 再跑,否则在跑旧二进制
- TB 直接读黄金文件(input/expected/weights/bias 的 .bin),软件模型对拍并打印 mismatch/max|d|/first_bad;**tlast 也要校验**(分块周期)
- 中文路径(如用户名含中文)会让部分工具链临时目录出问题,工程路径全 ASCII

### 2.2 结构三定律(三次失败换来)

1. **不要在内层循环放 PIPELINE**:会被拆成数据流子块(Pipeline_VITIS_LOOP_x),子块间通道在**帧重启时残留令牌**,下一帧全面错位。特征:单块全对、跨块全错。
   **2026-09-24 补刀:Vitis HLS 2023.2 会自动流水化循环**(日志 `HLS 214-376 automatically set the pipeline`),包括含 `in.read()` 的装载循环——**csim/cosim 全绿、上板 100% 挂/全错**(DW/PW 一起死,卡在装载阶段)。即使你不写 PIPELINE 编译指示,自动流水化也会偷偷违反本定律。**防御:① 装载/读写流循环显式 `#pragma HLS PIPELINE off`;② 每次 csynth 后 grep 日志 `214-376`,确认只有验证过的循环(如像素读循环)被自动流水化。** 本次事故:M5.5 撤掉装载循环的 PIPELINE off(想提速),csim/cosim 双绿骗过所有人,导出即全灭。
   **2026-09-26 精修(POR 后健康板实证)**:① 含 `in.read()` 的读循环流水化 → 上板挂(B3 实证),**流操作(读/写流)不许进 PIPELINE 循环**;② 纯计算循环(MAC)流水化 → 安全且快(B2' 实证 62/62);③ 由此引擎定式 = **顺序流循环 + 缓冲 + 流水计算循环**;④ 构建 hold 余量 WHS <0.05ns 时,数据会确定性出错(同位置复现)——换 `Performance_ExploreWithHoldFix` strategy 重出,别怀疑逻辑。
2. **不要用 `while(true)` 自由运行**:flow_control_loop_pipe_sequential_init 在该结构下可能不产生读使能,引擎上板即死(csim 全对也救不了)。
3. **防展开**:HLS 默认完全展开小循环(576 DSP 爆炸)。定版结构:节拍循环全部显式
   `#pragma HLS UNROLL factor=1`(读/算/写每个内层都要,**漏一个外层 i 主循环就会被整体
   流水化、内部全部展开**——M5.2 DW 实测漏标后 288 DSP 超编,补齐后 11 DSP):

```cpp
for (ap_uint<16> i = 0; i < n; i++) {        // 单 FSM、顺序执行、无 PIPELINE
    // 内层局部并行用 UNROLL(如 4 通道),节拍循环用 UNROLL factor=1 禁展开
}
// ap_ctrl_none + for(n) 帧;算子帧长 = DMA 块长(如 256 像素)
```

### 2.3 资源与接口

- 权重/偏置小表(≤几 KB)走 s_axilite 数组(偏移 `hw.h` 查:int8 元素 @0x10+i·8);大表后面必须改 DDR 直读
- **换引擎/改参数表后必须重对生成的 `x*_hw.h` 偏移**——旧偏移不会报错,会静默写进别的参数槽位
  (M5.2 实测:旧 mul@0x990 落进新引擎 bias[16] 槽位,csim 直传参数根本照不到);同理,灌数据地址
  与 harness 的垫区 memset 不能重叠(input.bin 要灌在 `IN_ADDR + 前垫字节数`)
- `ap_int<N>` 三目运算类型严格(ap_int<48> vs ap_int<49> 编译错)——用 if/else 别用 ?:
- `ARRAY_PARTITION complete` 于窗口/累加器(寄存器);行缓存(>KB)留默认(BRAM)
- 综合报告必看:DSP 数(≤220)、估时、Latency;**DSP 爆掉先查循环展开**

### 2.4 tlast 契约(跨块稳定的关键)

- **tlast 透传**:输入像素尾拍的 tlast → 该像素输出尾拍。DMA 块边界(MM2S 按字节生成的 tlast)与 S2MM 块尾**结构性对齐**,引擎无帧概念处不再出错
- 需要引擎自产 tlast 时(如整图一帧),确保位置与 S2MM 最后一块的字节数精确一致

### 2.5 导出与集成

- `export_design -output <path>`:若 `<path>` 是已存在的解包目录,**重导出只刷 zip 不刷目录** —— 集成前 `stat` 校验 IP 内容版本,或先 `rm -rf` 目录和 zip
- BD 集成批处理五件套:IP repo 路径 → 删旧单元 → 建单元连线(注意 HLS 流口名是 `in_r/out_r`!)→ 单针桩网清理循环 → **HDL 自检**(读 synth/system.v 搜绑死)

## 3. int8 QDQ requant(逐层通用)

```
acc = bias_int32 + Σ (x_int8 - x_zp)·w_int8      # 减 x_zp 不可省!漏减 = 每层偏 128·Σw
y   = round_half_even(acc·M) + y_zp,  M = x_scale·w_scale/y_scale
```

- 定点:`mul = round(M·2^26)`,`acc·mul` 用 **ap_int<48>**(防溢出);**恰半向偶**:`vf = t>>shift; frac = t - (vf<<shift); frac>half→+1; ==half→向偶; <half→floor`。别用"+0.5 取整"(负数全偏 1)
- bias 是 **int32**(scale = xs·ws,与 acc 同域),从 `<conv>.weight_bias_quantized` 取;**不是 fp32**
- **边界填充 = 量化零点 x_zp**(填充贡献 (x_zp - x_zp)=0),不是 0
- 从 QDQ 图抽层参数:激活 DQ 输入=int8 激活,DQ 的 scale/zp;Conv 输出后的 Q 节点=y 的 scale/zp;权重 DQ 输入=int8 权重;bias 经其 DQ 取 int32 与 scale
- 因果流式卷积 vs SAME 卷积对齐:因果(右下锚定)DW 的输出 (r,c) 要等消费完 real (r+1,c+1) 才就绪,**天然延迟 W+1 像素**。正确契约:**前置 W+1 + 尾部 W+1 个 x_zp 值像素**(垫值是 x_zp 不是 0!),**输出跳过前 2(W+1) 拍**;边界强制**只在计算时选择、不写回移位寄存器**(W=200 时:col==2 拍窗左列取 x_zp,col==1 拍窗右列取 x_zp——在错误的拍写回会通过移位传播污染相邻三列输出)。行缓存历史全由前置垫真实提供,无需额外的首行强制

## 4. 验证基建(黄金对拍流水线)

0. **TB 自身三宗罪(2026-09-27 血泪:xsim 假绿数月,板上全灭才暴露)**:
   ① `$fscanf(...%s..., dir)` 读进宽 `reg [8*N:1]` 会**左补零**,`$sformat` 拼出的路径
   前导全是 NUL/空格 → `fopen` 静默失败 → golden 全 X → **X!==X 为假,比对永远"通过"**!
   修法:用 `string` 类型。**验收 TB 的第一课:display 一个 golden 读回值,非 X 才算数。**
   ② `$fread` 进 `reg [31:0]` 数组会**字节交换**(小端文件被反转)→ bias 全错但形似"数值偏差"。
   修法:按字节读进 `reg [7:0]` 数组,手工 `{b3,b2,b1,b0}` 装配。
   ③ 捕获计数器(如 cap_n)不初始化 → X → `while (X < k)` 条件为 X 按假处理 → 静默零比对。
1. **抽层**:`scripts/extract_golden_layers_v1.0.py` —— int8 ONNX 全节点输出 + QDQ 参数 → 每层 `input/expected/weights/bias_int32.bin`(NHWC int8)+ meta.json
2. **裸机 harness**:命令块(地址/长度/模式)+ 邮箱结果(mismatch/max|d|/first_bad/耗时)+ 分块 DMA + PS 对拍;串口仅辅助
3. **驱动**:xsct 灌张量(dow -data)→ 写命令 → con → 轮询完成哨兵(注意 mrd 返回带前导零,比较用完整 `0000600D`)
4. **板级对拍先看第一错字节位置**(chunk 边界?起始?)再决定怀疑对象

## 5. 性能与计时

- **PMCCNTR 在本板读数偏小约 10 倍**(未校准);性能结论前先用已知工作量标定
- 估延迟先看 HLS Latency(max 行),上板再看 DMASR 完成与计数器;别在计时器未校准前下性能结论

## 6. 命令速查

```bash
# HLS 全流程(建工程+仿真+综合+导出)
cd <hls_dir> && D:/Xilinx/Vitis_HLS/2023.2/bin/vitis_hls.bat -f run_hls.tcl
# 只跑 csim(改源后先删旧产物)
rm -rf <proj>/<sol>/csim && D:/Xilinx/Vitis_HLS/2023.2/bin/vitis_hls.bat -f run_csim.tcl
# Vivado 批处理(集成/修线/出 bit)
D:/Xilinx/Vivado/2023.2/bin/vivado.bat -mode batch -source <script>.tcl
# 硬件操作(xsct 脚本)
D:/Xilinx/Vitis/2023.2/bin/xsct.bat <script>.tcl [args]
# 裸机 gcc(复用平台 spec,无需 IDE)
"$GCC" -O2 -DSDT -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -specs=<platform>/Xilinx.spec -I<platform>/include -c main.c -o main.o
"$GCC" ... main.o -o app.elf -Wl,-T -Wl,lscript.ld -L<platform>/lib -Wl,--start-group,-lxilstandalone -lxil -lxiltimer -lgcc -lc -Wl,--end-group
```

## 7. 调试优先级口诀

数据不对先对拍(C 模型 vs 黄金);拍不上先数拍(进出拍数);引擎不动作查启动(控制口回读 + TREADY);跨块错查重启残留与 tlast 对齐;资源爆查展开;连不上查桩网与偏移;死了先断电。
