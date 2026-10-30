/* DW 核心(纯数据通路)—— 与 dw_engine_rtl.sv 验证版同语义,存储改宽字 1D。
 * 存储纪律:kbank_w[j]=576b(8 通道×9 抽头,字节序=流序 l*9+t);
 *   winb_w[j]=576b((di*8+l) 个 24 位窗);bbank_w[j]=256b(8 通道 bias);
 *   lb0/lb1 行缓存 64 位 block RAM。全部 1R+1W,不造索引 mux。
 * 帧:[k 字 C*9/8][bias 字 C/2][像素 n 个,C/8 拍];契约同 HLS 版(s1/s2/边界强制)。
 * 流水纪律(2026-09-27 时序三连坑:-29.9 组合链 / -22.6 取模除法器 / -10 跨模块布线):
 *   乘法全部外置共享池,操作数与积均寄存(2 拍);
 *   emit_cnt % r_ochunk 组合除法器改为 chunk_cnt 计数比较(等语义);
 *   requant 在 PH3 流水完成:积到齐 → acc_r → rq_t → 舍入 → tvalid(共 5 拍)。
 *   非 emit 拍仍 PH1/PH2 两拍交替,不受影响。 */
`timescale 1ns/1ps
module dw_core_rtl (
    input  wire        ap_clk,
    input  wire        ap_rst_n,
    input  wire        ap_start,
    input  wire [31:0] r_mul,
    input  wire [7:0]  r_shift,
    input  wire [15:0] r_xzp,
    input  wire [15:0] r_yzp,
    input  wire [15:0] r_n,
    input  wire [15:0] r_c,
    input  wire [15:0] r_w,
    input  wire [15:0] r_ww,
    input  wire [15:0] r_bw,
    input  wire [15:0] r_ochunk,
    input  wire        r_str2,
    input  wire [63:0] in_r_TDATA,
    input  wire        in_r_TVALID,
    output wire        in_r_TREADY,
    input  wire        in_r_TLAST,
    input  wire [7:0]  in_r_TKEEP,
    output reg  [63:0] out_r_TDATA,
    output reg         out_r_TVALID,
    input  wire        out_r_TREADY,
    output reg         out_r_TLAST,
    output wire        done,
    /* 共享乘法池接口(wrapper 内 mac_pool_rtl / rq_mult_rtl,输入与积均已寄存) */
    output wire [719:0]  mp_a,    /* 72 × 10b signed (x - xzp;强制边界=0) */
    output wire [575:0]  mp_b,    /* 72 × 8b  signed (k)       */
    input  wire [1295:0] mp_p,    /* 72 × 18b signed 积(寄存) */
    output wire [255:0]  rq_acc,  /* 8 × 32b signed(requant 被乘数) */
    input  wire [511:0]  rq_t,    /* 8 × 64b signed(acc*mul,寄存) */
    output wire         pipe_en  /* freeze every DW pipeline stage on output backpressure */
);
    wire running = ap_start;

    (* ram_style = "block" *)       reg [63:0]  lb0 [0:4095];
    (* ram_style = "block" *)       reg [63:0]  lb1 [0:4095];
    (* ram_style = "distributed" *) reg [575:0] winb_w [0:159];   /* (di*8+l) × 24b */
    (* ram_style = "distributed" *) reg [575:0] kbank_w [0:159];  /* 流序 l*9+t */
    (* ram_style = "distributed" *) reg [255:0] bbank_w [0:159];  /* l*32b */

    localparam S_IDLE = 0, S_LOADK = 1, S_LOADB = 2, S_RUN = 3, S_DONE = 4;
    reg [2:0] st;
    assign done = (st == S_DONE);

    reg [15:0] cnt, i, j, col, row, qc, qr, pad_left, chunk_cnt, cb;
    reg [63:0] xw_r;
    reg [15:0] addr_r, j_r;
    reg fl_r, fr_r;
    reg input_done;
    reg [6:0] vld_pipe, emit_pipe, last_pipe;
    reg [255:0] bbank_sv, bbank_d, acc_r;
    wire accept = (st == S_RUN) && !input_done && in_r_TVALID && pipe_en;
    assign pipe_en = !out_r_TVALID || out_r_TREADY;
    // 装载:k 的 72 字节收集器 / bias 的 32 字节收集器
    reg [575:0] k_shift;
    reg [3:0]  cnt_mod9;
    reg [15:0] kw_idx;
    reg [255:0] b_shift;

    wire is_real  = (pad_left == 0);
    wire emit_c   = r_str2 ? (is_real && qr[0] && qc[0]) : 1'b1;
    wire forceL_c = r_str2 ? (qc == 1) : (col == 2);
    wire forceR_c = r_str2 ? 1'b0      : (col == 1);
    wire [15:0] lb_addr_c = j * r_w + col;

    /* PH1 同步读;PH2 用数。
     * ★读地址必须用当拍组合地址 lb_addr_c,不能用 addr_r——非阻塞语义下
     * `lb0_rd <= lb0[addr_r]` 在 PH1 末沿采到的是上一拍的旧地址(通道组错位),
     * 该 bug 曾长期被坏 TB 掩盖(2026-09-27 实证) */
    reg [63:0]  lb0_rd, lb1_rd;
    reg [575:0] winb_rd, kbank_rd;
    reg [255:0] bbank_rd;
    always @(posedge ap_clk) begin
        if (pipe_en) begin
            lb0_rd   <= lb0[lb_addr_c];
            lb1_rd   <= lb1[lb_addr_c];
            winb_rd  <= winb_w[j];
            kbank_rd <= kbank_w[j];
            bbank_rd <= bbank_w[j];
        end
    end

    /* PH2:72 路操作数 → 共享乘法池(减法在核内,池只乘;输入与积均寄存) */
    genvar gl, gdi, gdj;
    generate
        for (gl = 0; gl < 8; gl = gl + 1) begin : gl_
        for (gdi = 0; gdi < 3; gdi = gdi + 1) begin : gdi_
        for (gdj = 0; gdj < 3; gdj = gdj + 1) begin : gdj_
            wire [7:0] tapb = (gdj == 0) ? winb_rd[(gdi*8+gl)*24 + 8  +: 8]
                            : (gdj == 1) ? winb_rd[(gdi*8+gl)*24 + 16 +: 8]
                            : (gdi == 0) ? lb1_rd[8*gl +: 8]
                            : (gdi == 1) ? lb0_rd[8*gl +: 8]
                            :              xw_r [8*gl +: 8];
            // 原语义:强制边界时 vv=xzp → (vv-xzp)=0
            assign mp_a[(gl*9 + gdi*3 + gdj)*10 +: 10] =
                ((gdj == 0 && fl_r) || (gdj == 2 && fr_r)) ? 10'sd0
                : $signed(tapb) - $signed(r_xzp);
            assign mp_b[(gl*9 + gdi*3 + gdj)*8 +: 8] =
                kbank_rd[(gl*9 + gdi*3 + gdj)*8 +: 8];
        end end end
    endgenerate

    /* 窗口移位写回值(PH2 用,只依赖 PH1 锁存寄存器) */
    integer l, di;
    reg [23:0] went;
    reg [7:0]  nv;
    reg [575:0] winb_nw;
    always @(*) begin
        winb_nw = winb_rd;
        for (l = 0; l < 8; l = l + 1)
            for (di = 0; di < 3; di = di + 1) begin
                went = winb_rd[(di*8+l)*24 +: 24];
                // 新窗口:byte0=旧 byte1, byte1=旧 byte2, byte2=nv(行 di)
                nv = (di == 0) ? lb1_rd[8*l +: 8] :
                     (di == 1) ? lb0_rd[8*l +: 8] : xw_r[8*l +: 8];
                winb_nw[(di*8+l)*24 +: 24] = { nv, went[23:16], went[15:8] };
            end
    end

    /* PH3 流水级 1:9 抽头和(bias 在前,序同原版 t=0..8) */
    integer l3, t3;
    (* use_dsp = "no" *) reg signed [31:0] acc_lane [0:7];
    always @(*) begin
        for (l3 = 0; l3 < 8; l3 = l3 + 1) begin
            acc_lane[l3] = bbank_d[l3*32 +: 32];
            for (t3 = 0; t3 < 9; t3 = t3 + 1)
                acc_lane[l3] = acc_lane[l3] + $signed(mp_p[(l3*9+t3)*18 +: 18]);
        end
    end
    /* PH3 流水级 2:requant 被乘数 = acc_r(共享 rq_mult_rtl,输入与积均寄存) */
    genvar gl4;
    generate
        for (gl4 = 0; gl4 < 8; gl4 = gl4 + 1) begin : grq
            assign rq_acc[gl4*32 +: 32] = acc_r[gl4*32 +: 32];
        end
    endgenerate
    /* PH3 流水级 3:舍入再拆两级 —— vf/frac 寄存(准静态 half/mask 只算一次),
     * 然后比较/加/饱和第二级。frac = t48 & mask(与 t48-(vf<<shift) 恒等) */
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
    integer l5;
    reg signed [63:0] vf, frac;
    reg signed [31:0] y32;
    reg [63:0] od2_c;
    always @(*) begin
        od2_c = 64'd0;
        for (l5 = 0; l5 < 8; l5 = l5 + 1) begin
            vf   = vf_r[l5];
            frac = frac_r[l5];
            if (frac > half_rr)       y32 = vf[31:0] + 1;
            else if (frac < half_rr)  y32 = vf[31:0];
            else if (vf[0])           y32 = vf[31:0] + 1;
            else                      y32 = vf[31:0];
            y32 = y32 + $signed(r_yzp);
            od2_c[8*l5 +: 8] = (y32 > 127) ? 8'd127 : (y32 < -128) ? 8'h80 : y32[7:0];
        end
    end

    assign in_r_TREADY = (st == S_LOADK) || (st == S_LOADB) ||
                         ((st == S_RUN) && !input_done && pipe_en);

    integer l6;
    always @(posedge ap_clk) begin
        if (!ap_rst_n) begin
            st <= S_IDLE; cnt <= 0; i <= 0; j <= 0; col <= 0; row <= 0;
            qc <= 0; qr <= 0; pad_left <= 0; chunk_cnt <= 0; cb <= 0;
            k_shift <= 0; b_shift <= 0; cnt_mod9 <= 0; kw_idx <= 0;
            xw_r <= 0; addr_r <= 0; j_r <= 0; fl_r <= 0; fr_r <= 0;
            input_done <= 0; vld_pipe <= 0; emit_pipe <= 0; last_pipe <= 0;
            bbank_sv <= 0; bbank_d <= 0; acc_r <= 0;
            out_r_TVALID <= 0; out_r_TDATA <= 0; out_r_TLAST <= 0;
        end else begin
            case (st)
            S_IDLE: begin
                out_r_TVALID <= 0;
                if (ap_start) begin
                    cb <= r_c >> 3;
                    cnt <= 0; i <= 0; j <= 0; col <= 0; row <= 0;
                    cnt_mod9 <= 0; kw_idx <= 0; qc <= 0; qr <= 0;
                    pad_left <= r_w + 1; chunk_cnt <= 0;
                    input_done <= 0; vld_pipe <= 0; emit_pipe <= 0; last_pipe <= 0;
                    st <= (r_ww != 0) ? S_LOADK : S_LOADB;
                end
            end
            S_LOADK: if (in_r_TVALID) begin
                if (cnt_mod9 == 4'd8) begin
                    kbank_w[kw_idx] <= { in_r_TDATA, k_shift[575:64] };
                    kw_idx <= kw_idx + 1;
                    cnt_mod9 <= 0;
                end else cnt_mod9 <= cnt_mod9 + 1;
                k_shift <= { in_r_TDATA, k_shift[575:64] };
                if (cnt == r_ww - 1) begin cnt <= 0; st <= S_LOADB; end
                else cnt <= cnt + 1;
            end
            S_LOADB: if (in_r_TVALID) begin
                if (cnt[1:0] == 2'd3)
                    bbank_w[cnt[9:2]] <= { in_r_TDATA, b_shift[255:64] };
                b_shift <= { in_r_TDATA, b_shift[255:64] };
                if (cnt == r_bw - 1) begin cnt <= 0; st <= S_RUN; end
                else cnt <= cnt + 1;
            end
            S_RUN: if (pipe_en) begin
                // A new channel group is accepted each cycle.  All tags advance with
                // the shared MAC and requant stages, including under random stalls.
                vld_pipe  <= {vld_pipe[5:0], accept};
                emit_pipe <= {emit_pipe[5:0], accept && emit_c};
                last_pipe <= {last_pipe[5:0], accept && (j == cb - 1) &&
                    (r_str2 ? ((chunk_cnt == r_ochunk - 1) || (i == r_n - 1))
                            : in_r_TLAST)};

                // E1: prior read data writes row/window state and enters MAC pool.
                if (vld_pipe[0]) begin
                    lb1[addr_r] <= lb0_rd;
                    lb0[addr_r] <= xw_r;
                    winb_w[j_r] <= winb_nw;
                    bbank_sv <= bbank_rd;
                end
                // E2: bias follows the pool product by one more register.
                if (vld_pipe[1]) bbank_d <= bbank_sv;
                // E3: products are ready; E4/E5 are the shared rq registers.
                if (vld_pipe[2])
                    for (l6 = 0; l6 < 8; l6 = l6 + 1)
                        acc_r[l6*32 +: 32] <= acc_lane[l6];
                // E6: vf/frac registers; E7: rounded output register.
                out_r_TVALID <= vld_pipe[6] && emit_pipe[6];
                if (vld_pipe[6] && emit_pipe[6]) begin
                    out_r_TDATA <= od2_c;
                    out_r_TLAST <= last_pipe[6];
                end

                if (accept) begin
                    xw_r <= in_r_TDATA;
                    addr_r <= lb_addr_c;
                    j_r <= j;
                    fl_r <= forceL_c;
                    fr_r <= forceR_c;
                    if (j == cb - 1) begin
                        j <= 0;
                        if (emit_c)
                            chunk_cnt <= (chunk_cnt == r_ochunk - 1) ? 16'd0 : chunk_cnt + 1;
                        if (pad_left > 0) pad_left <= pad_left - 1;
                        else if (qc == r_w - 1) begin qc <= 0; qr <= qr + 1; end
                        else qc <= qc + 1;
                        if (col == r_w - 1) begin col <= 0; row <= row + 1; end
                        else col <= col + 1;
                        i <= i + 1;
                        if (i == r_n - 1) input_done <= 1;
                    end else j <= j + 1;
                end
                if (input_done && vld_pipe == 0 && !out_r_TVALID)
                    st <= S_DONE;
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
