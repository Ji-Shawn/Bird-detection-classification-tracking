/* PW 核心(纯数据通路,无 AXI-Lite)—— 与 pw_engine_rtl.sv 验证版同逻辑。
 * 存储纪律(2026-09-27 资源爆炸教训):所有数组 = 宽字 1D,每拍整字访问,不造索引 mux。
 *   wbank:16 个 1D block RAM(u=o%16);acc_w/bb_w:按 og 组的 512 位 FF 字;
 *   xbuf:1D LUTRAM。参数由 wrapper 以导线提供;ap_start 为电平(帧内保持 1)。
 * 流水纪律(2026-09-27 时序三连坑:-29.9 组合链 / -22.6 取模 / -10 跨模块布线):
 *   乘法全部外置共享池,操作数与积均寄存(2 拍乘法)。MAC = 4 级流水:
 *   地址拍 → 操作数拍(_q)→ 积寄存拍(_qq)→ 累加拍(_qqq)。
 *   issue 用 cnt<macsteps 门控(末拍不发射,消除伪退休);S_MAC→S_DRAIN(2 拍)
 *   等末尾两笔累加落盘 → S_WRITE 流水输出(requant 同为 2 拍,TVALID 迟 2 拍)。 */
`timescale 1ns/1ps
module pw_core_rtl (
    input  wire        ap_clk,
    input  wire        ap_rst_n,
    input  wire        ap_start,
    input  wire [31:0] r_mul,
    input  wire [7:0]  r_shift,
    input  wire [15:0] r_xzp,
    input  wire [15:0] r_yzp,
    input  wire [15:0] r_n,
    input  wire [15:0] r_c,
    input  wire [15:0] r_coutt,
    input  wire [15:0] r_ww,
    input  wire [15:0] r_bw,
    input  wire [63:0] in_r_TDATA,
    input  wire        in_r_TVALID,
    output wire        in_r_TREADY,
    input  wire        in_r_TLAST,
    output reg  [63:0] out_r_TDATA,
    output reg         out_r_TVALID,
    input  wire        out_r_TREADY,
    output reg         out_r_TLAST,
    output wire        done,
    /* 共享乘法池接口(wrapper 内 mac_pool_rtl / rq_mult_rtl,输入与积均已寄存) */
    output wire [639:0]  mp_a,    /* 64 × 10b signed (x - xzp) */
    output wire [511:0]  mp_b,    /* 64 × 8b  signed (w)       */
    input  wire [1151:0] mp_p,    /* 64 × 18b signed 积(寄存) */
    output wire [255:0]  rq_acc,  /* 8 × 32b signed(requant 被乘数) */
    input  wire [511:0]  rq_t,    /* 8 × 64b signed(acc*mul,寄存) */
    output wire          pipe_en  /* S_WRITE 输出级前进(供共享 rq 冻结管道) */
);
    wire running = ap_start;

    /* ---- 资源:16 个独立权重 bank(BRAM)+ 宽字 acc/bb + xbuf ---- */
    (* ram_style = "block" *) reg [63:0] wb0 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb1 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb2 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb3 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb4 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb5 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb6 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb7 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb8 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb9 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb10 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb11 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb12 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb13 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb14 [0:1023];
    (* ram_style = "block" *) reg [63:0] wb15 [0:1023];
    reg [511:0] bb_w  [0:15];            /* og 组的 16 通道 bias(FF) */
    reg [511:0] acc_w0 [0:15];
    reg [511:0] acc_w1 [0:15];
    reg [63:0] xbuf0 [0:159], xbuf1 [0:159];

    localparam S_IDLE = 0, S_LOADW = 1, S_LOADB = 2, S_STREAM = 3, S_DONE = 4;
    localparam C_IDLE = 0, C_MAC = 1, C_DRAIN = 2;
    localparam O_IDLE = 0, O_WRITE = 1;
    reg [2:0] st;
    reg [1:0] c_st;
    reg o_st;
    assign done = (st == S_DONE);

    reg [15:0] cnt, in_j, mac_cnt, out_cnt, j;
    reg [15:0] input_count, compute_count, output_count;
    reg [15:0] lo, lj, lbase;
    reg [7:0] og;
    reg hf;
    reg [1:0] last_buf, last_acc;
    reg [15:0] cb, ogmax, macsteps, obc;

    // bias 装载:512 位移位收集,8 拍(16 通道)写一个字
    reg [511:0] bb_shift;

    // MAC 流水:stage0 地址(og/j/hf)→ stage1 操作数(_q,BRAM 数据)→
    //          stage2 积寄存(_qq)→ stage3 累加(_qqq)
    reg [7:0]  og_q;   reg [15:0] j_q;   reg hf_q;   reg mac_vld_q;
    reg [7:0]  og_qq;  reg [15:0] j_qq;  reg hf_qq;  reg mac_vld_qq;
    reg [7:0]  og_qqq; reg [15:0] j_qqq; reg hf_qqq; reg mac_vld_qqq;
    wire [15:0] wa_cur = og * cb + j;
    reg [63:0] wbank_rd [0:15];
    wire [9:0] wa10 = wa_cur[9:0];
    always @(posedge ap_clk) begin
        wbank_rd[0]  <= wb0[wa10];  wbank_rd[1]  <= wb1[wa10];
        wbank_rd[2]  <= wb2[wa10];  wbank_rd[3]  <= wb3[wa10];
        wbank_rd[4]  <= wb4[wa10];  wbank_rd[5]  <= wb5[wa10];
        wbank_rd[6]  <= wb6[wa10];  wbank_rd[7]  <= wb7[wa10];
        wbank_rd[8]  <= wb8[wa10];  wbank_rd[9]  <= wb9[wa10];
        wbank_rd[10] <= wb10[wa10]; wbank_rd[11] <= wb11[wa10];
        wbank_rd[12] <= wb12[wa10]; wbank_rd[13] <= wb13[wa10];
        wbank_rd[14] <= wb14[wa10]; wbank_rd[15] <= wb15[wa10];
    end

    // stage1 操作数:16 bank × 4 lane = 64 路 → 共享乘法池(减法在核内,池只乘)
    integer u;
    (* use_dsp = "no" *) reg [31:0] s_bank [0:15];
    wire [63:0] xword = compute_count[0] ? xbuf1[j_q] : xbuf0[j_q];
    wire [31:0] xw = hf_q ? xword[63:32] : xword[31:0];
    genvar gu, gl;
    generate
        for (gu = 0; gu < 16; gu = gu + 1) begin : gbank
            for (gl = 0; gl < 4; gl = gl + 1) begin : glane
                // ★x 必须按 int8 有符号取(曾误用 {1'b0,byte} 零扩展,
                //   负数像素全偏 +256,被坏 TB 掩盖;2026-09-27 实证)
                assign mp_a[(gu*4+gl)*10 +: 10] =
                    $signed(xw[8*gl +: 8]) - $signed(r_xzp);
                assign mp_b[(gu*4+gl)*8 +: 8] =
                    hf_q ? wbank_rd[gu][32 + 8*gl +: 8] : wbank_rd[gu][8*gl +: 8];
            end
        end
    endgenerate
    // stage3:积求和(序同原版 l=0..3)+ acc RMW,全部 LUT
    always @(*) begin
        for (u = 0; u < 16; u = u + 1)
            s_bank[u] = $signed(mp_p[(u*4+0)*18 +: 18]) + $signed(mp_p[(u*4+1)*18 +: 18])
                      + $signed(mp_p[(u*4+2)*18 +: 18]) + $signed(mp_p[(u*4+3)*18 +: 18]);
    end

    // requant(写阶段,8 路;乘法走共享 rq_mult_rtl 2 拍,舍入再拆两级流水)
    //   准静态 half/mask 寄存一次(别再每路重算移位);frac = t48 & mask(与 t48-(vf<<shift) 恒等)
    //   ★停顿铁律(2026-09-27 板上跳字实证):整条管道只在输出级前进时移位,
    //     否则 1 拍 backpressure 就跳 1 个字(xsim 恒 TREADY 照不到!)
    assign pipe_en = (st == S_STREAM) && (o_st == O_WRITE) &&
                     (!out_r_TVALID || out_r_TREADY);
    reg [63:0] half_rr, mask_rr;
    reg [63:0] vf_r [0:7], frac_r [0:7];
    integer l7;
    always @(posedge ap_clk) begin
        half_rr <= 64'sd1 <<< (r_shift - 1);
        mask_rr <= (64'sd1 <<< r_shift) - 1;
        if (pipe_en)
            for (l7 = 0; l7 < 8; l7 = l7 + 1) begin
                vf_r[l7]   <= $signed(rq_t[l7*64 +: 64]) >>> r_shift;
                frac_r[l7] <= rq_t[l7*64 +: 64] & mask_rr;
            end
    end
    reg [63:0] od2_c;
    integer l2;
    reg signed [63:0] vf, frac;
    reg signed [31:0] y32;
    genvar gl2;
    generate
        for (gl2 = 0; gl2 < 8; gl2 = gl2 + 1) begin : grq
            wire [7:0] oi = out_cnt[4:0]*8 + gl2;
            assign rq_acc[gl2*32 +: 32] = output_count[0]
                ? acc_w1[oi[7:4]][oi[3:0]*32 +: 32]
                : acc_w0[oi[7:4]][oi[3:0]*32 +: 32];
        end
    endgenerate
    always @(*) begin
        od2_c = 64'd0;
        for (l2 = 0; l2 < 8; l2 = l2 + 1) begin
            vf   = vf_r[l2];
            frac = frac_r[l2];
            if (frac > half_rr)       y32 = vf[31:0] + 1;
            else if (frac < half_rr)  y32 = vf[31:0];
            else if (vf[0])           y32 = vf[31:0] + 1;
            else                      y32 = vf[31:0];
            y32 = y32 + $signed(r_yzp);
            od2_c[8*l2 +: 8] = (y32 > 127) ? 8'd127 : (y32 < -128) ? 8'h80 : y32[7:0];
        end
    end

    assign in_r_TREADY = (st == S_LOADW) || (st == S_LOADB) ||
        ((st == S_STREAM) && (input_count < r_n) &&
         ((input_count - compute_count) < 16'd2));

    integer u2;
    (* use_dsp = "no" *) reg [511:0] acc_nw;
    always @(posedge ap_clk) begin
        if (!ap_rst_n) begin
            st <= S_IDLE; c_st <= C_IDLE; o_st <= O_IDLE;
            cnt <= 0; in_j <= 0; mac_cnt <= 0; out_cnt <= 0; j <= 0;
            input_count <= 0; compute_count <= 0; output_count <= 0;
            og <= 0; hf <= 0; lo <= 0; lj <= 0; lbase <= 0;
            bb_shift <= 0; last_buf <= 0; last_acc <= 0;
            cb <= 0; ogmax <= 0; macsteps <= 0; obc <= 0;
            out_r_TVALID <= 0; out_r_TDATA <= 0; out_r_TLAST <= 0;
            og_q <= 0; j_q <= 0; hf_q <= 0; mac_vld_q <= 0;
            og_qq <= 0; j_qq <= 0; hf_qq <= 0; mac_vld_qq <= 0;
            og_qqq <= 0; j_qqq <= 0; hf_qqq <= 0; mac_vld_qqq <= 0;
        end else begin
            og_q <= og[7:0]; j_q <= j; hf_q <= hf;
            mac_vld_q <= (st == S_STREAM) && (c_st == C_MAC) &&
                         (mac_cnt < macsteps);
            og_qq <= og_q; j_qq <= j_q; hf_qq <= hf_q;
            mac_vld_qq <= mac_vld_q;
            og_qqq <= og_qq; j_qqq <= j_qq; hf_qqq <= hf_qq;
            mac_vld_qqq <= mac_vld_qq;
            if (mac_vld_qqq) begin
                for (u2 = 0; u2 < 16; u2 = u2 + 1)
                    acc_nw[u2*32 +: 32] = (j_qqq == 0 && hf_qqq == 0)
                        ? bb_w[og_qqq[3:0]][u2*32 +: 32] + s_bank[u2]
                        : (compute_count[0]
                            ? acc_w1[og_qqq[3:0]][u2*32 +: 32]
                            : acc_w0[og_qqq[3:0]][u2*32 +: 32]) + s_bank[u2];
                if (compute_count[0]) acc_w1[og_qqq[3:0]] <= acc_nw;
                else                  acc_w0[og_qqq[3:0]] <= acc_nw;
            end

            case (st)
            S_IDLE: begin
                out_r_TVALID <= 0;
                if (ap_start) begin
                    cb <= r_c >> 3; ogmax <= (r_coutt + 15) >> 4;
                    macsteps <= ((r_coutt + 15) >> 4) * (r_c >> 3) * 2;
                    obc <= r_coutt >> 3;
                    cnt <= 0; in_j <= 0; mac_cnt <= 0; out_cnt <= 0;
                    input_count <= 0; compute_count <= 0; output_count <= 0;
                    lo <= 0; lj <= 0; lbase <= 0;
                    c_st <= C_IDLE; o_st <= O_IDLE;
                    st <= (r_ww != 0) ? S_LOADW : S_LOADB;
                end
            end
            S_LOADW: if (in_r_TVALID) begin
                case (lo[3:0])
                    4'd0:  wb0[lbase + lj]  <= in_r_TDATA;
                    4'd1:  wb1[lbase + lj]  <= in_r_TDATA;
                    4'd2:  wb2[lbase + lj]  <= in_r_TDATA;
                    4'd3:  wb3[lbase + lj]  <= in_r_TDATA;
                    4'd4:  wb4[lbase + lj]  <= in_r_TDATA;
                    4'd5:  wb5[lbase + lj]  <= in_r_TDATA;
                    4'd6:  wb6[lbase + lj]  <= in_r_TDATA;
                    4'd7:  wb7[lbase + lj]  <= in_r_TDATA;
                    4'd8:  wb8[lbase + lj]  <= in_r_TDATA;
                    4'd9:  wb9[lbase + lj]  <= in_r_TDATA;
                    4'd10: wb10[lbase + lj] <= in_r_TDATA;
                    4'd11: wb11[lbase + lj] <= in_r_TDATA;
                    4'd12: wb12[lbase + lj] <= in_r_TDATA;
                    4'd13: wb13[lbase + lj] <= in_r_TDATA;
                    4'd14: wb14[lbase + lj] <= in_r_TDATA;
                    default: wb15[lbase + lj] <= in_r_TDATA;
                endcase
                if (lj == cb - 1) begin
                    lj <= 0; lo <= lo + 1;
                    if (lo[3:0] == 4'd15) lbase <= lbase + cb;
                end else lj <= lj + 1;
                if (cnt == r_ww - 1) begin cnt <= 0; st <= S_LOADB; end
                else cnt <= cnt + 1;
            end
            S_LOADB: if (in_r_TVALID) begin
                // 每拍 2 个 int32;8 拍凑满一个 og 组(16 通道)写 bb_w
                // ★cout_t 非 16 倍数时末组不足 8 拍,必须在 r_bw-1 拍右移补齐写回,
                //   否则高组 bias 永远缺载(cout=24 层全灭;2026-09-27 实证)
                bb_shift <= { in_r_TDATA, bb_shift[511:64] };
                if (cnt[2:0] == 3'd7)
                    bb_w[cnt[6:3]] <= { in_r_TDATA, bb_shift[511:64] };
                else if (cnt == r_bw - 1)
                    bb_w[cnt[6:3]] <= { in_r_TDATA, bb_shift[511:64] } >> (64 * (7 - cnt[2:0]));
                if (cnt == r_bw - 1) begin cnt <= 0; in_j <= 0; st <= S_STREAM; end
                else cnt <= cnt + 1;
            end
            S_STREAM: begin
                // Ping-pong input buffers: producer never writes the bank in MAC.
                if (in_r_TVALID && in_r_TREADY) begin
                    if (input_count[0]) xbuf1[in_j] <= in_r_TDATA;
                    else                xbuf0[in_j] <= in_r_TDATA;
                    if (in_j == cb - 1) begin
                        last_buf[input_count[0]] <= in_r_TLAST;
                        input_count <= input_count + 1;
                        in_j <= 0;
                    end else in_j <= in_j + 1;
                end

                case (c_st)
                C_IDLE: if ((input_count > compute_count) &&
                           ((compute_count - output_count) < 16'd2)) begin
                    og <= 0; j <= 0; hf <= 0; mac_cnt <= 0; c_st <= C_MAC;
                end
                C_MAC: begin
                    if (!hf) hf <= 1;
                    else begin
                        hf <= 0;
                        if (j == cb - 1) begin j <= 0; og <= og + 1; end
                        else j <= j + 1;
                    end
                    if (mac_cnt == macsteps) begin mac_cnt <= 0; c_st <= C_DRAIN; end
                    else mac_cnt <= mac_cnt + 1;
                end
                C_DRAIN: begin
                    if (mac_cnt == 1) begin
                        mac_cnt <= 0;
                        last_acc[compute_count[0]] <= last_buf[compute_count[0]];
                        compute_count <= compute_count + 1;
                        c_st <= C_IDLE;
                    end else mac_cnt <= mac_cnt + 1;
                end
                endcase

                case (o_st)
                O_IDLE: if (compute_count > output_count) begin
                    out_cnt <= 0; o_st <= O_WRITE;
                end
                O_WRITE: if (!out_r_TVALID || out_r_TREADY) begin
                    if (out_cnt <= obc + 2) begin
                        out_r_TDATA <= od2_c;
                        out_r_TVALID <= (out_cnt >= 3);
                        out_r_TLAST <= (out_cnt == obc + 2)
                            ? last_acc[output_count[0]] : 1'b0;
                        out_cnt <= out_cnt + 1;
                    end else begin
                        out_r_TVALID <= 0;
                        output_count <= output_count + 1;
                        o_st <= O_IDLE;
                    end
                end
                endcase
                if ((output_count == r_n) && !out_r_TVALID) st <= S_DONE;
            end
            S_DONE: begin
                out_r_TVALID <= 0;
                st <= S_IDLE;
            end
            default: st <= S_IDLE;
            endcase
        end
    end
endmodule
