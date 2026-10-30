/* 共享乘法池 —— pw/dw 两核互斥运行,乘法器全部集中到此,wrapper 按 r_mode 二选一驱动。
 * 关键教训(2026-09-27 综合实测):乘法操作数必须窄!原核内 (x-xzp) 被扩成 32 位,
 * 每个 8x32 乘法吃 2 个 DSP48(pw 162 + dw 177 = 339 > 220 超编)。
 * 这里 a=10b signed(x-xzp 真值域 [-255,383])、b=8b signed,每路 1 个 DSP48。
 *   mac_pool_rtl: 72 路 10x8(>= pw 64 路 / dw 72 路需求)
 *   rq_mult_rtl : 8 路 32x32 requant 共享(两核各 8 路 → 合一)
 * 时序纪律(2026-09-27 WNS 三连坑:-29.9 组合链 / -22.6 取模除法器 / -10 跨模块布线):
 * 输入操作数与积全部寄存(2 拍乘法,乘积路径完全关在 DSP 内部),
 * 两核各自的控制流水已对齐该延迟;累加与舍入留在核内 LUT。 */
`timescale 1ns/1ps

// Keep all 72 lanes in DSP48E1 without changing enable or pipeline latency.
(* use_dsp = "yes" *)
module mac_pool_rtl (
    input  wire         ap_clk,
    input  wire         en,
    input  wire [719:0]  a,    /* 72 × 10b signed (x - xzp) */
    input  wire [575:0]  b,    /* 72 × 8b  signed (w/k)     */
    output reg  [1295:0] p     /* 72 × 18b signed 积(寄存) */
);
    reg [719:0] a_r;
    reg [575:0] b_r;
    integer g;
    always @(posedge ap_clk) begin
        if (en) begin
            a_r <= a;
            b_r <= b;
            for (g = 0; g < 72; g = g + 1)
                p[g*18 +: 18] <= $signed(a_r[g*10 +: 10]) * $signed(b_r[g*8 +: 8]);
        end
    end
endmodule

module rq_mult_rtl (
    input  wire         ap_clk,
    input  wire         en,      /* 管道冻结使能(pw 模式接 pipe_en,dw 模式恒 1) */
    input  wire [255:0] acc,   /* 8 × 32b signed 累加值 */
    input  wire [31:0]  mul,   /* requant 乘数(两核共用 r_mul) */
    output reg  [511:0] t      /* 8 × 64b signed 积(寄存) */
);
    reg [255:0] acc_r;
    reg [31:0]  mul_r;
    integer g;
    always @(posedge ap_clk) begin
        if (en) begin
            acc_r <= acc;
            mul_r <= mul;
            for (g = 0; g < 8; g = g + 1)
                t[g*64 +: 64] <= $signed(acc_r[g*32 +: 32]) * $signed(mul_r);
        end
    end
endmodule
