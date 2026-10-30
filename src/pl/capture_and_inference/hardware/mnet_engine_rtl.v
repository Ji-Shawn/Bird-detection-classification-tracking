/* ==========================================================================
 * mnet_engine_rtl —— 手写双模式引擎顶层(mode 0=DW 1=PW),接替 HLS mnet_engine。
 * 寄存器图与 HLS 版完全一致(main.c 不变);流 64 位 HWC8。
 * 验证过的 pw_core_rtl / dw_core_rtl 直接例化,模式选择由 wrapper 完成。
 * ========================================================================== */
`timescale 1ns/1ps
module mnet_engine_rtl (
    input  wire        ap_clk,
    input  wire        ap_rst_n,
    input  wire [6:0]  s_axi_control_AWADDR,
    input  wire        s_axi_control_AWVALID,
    output reg         s_axi_control_AWREADY,
    input  wire [31:0] s_axi_control_WDATA,
    input  wire [3:0]  s_axi_control_WSTRB,
    input  wire        s_axi_control_WVALID,
    output reg         s_axi_control_WREADY,
    output reg         s_axi_control_BVALID,
    output wire [1:0]  s_axi_control_BRESP,
    input  wire        s_axi_control_BREADY,
    input  wire [6:0]  s_axi_control_ARADDR,
    input  wire        s_axi_control_ARVALID,
    output reg         s_axi_control_ARREADY,
    output reg         s_axi_control_RVALID,
    output reg  [31:0] s_axi_control_RDATA,
    output wire [1:0]  s_axi_control_RRESP,
    input  wire        s_axi_control_RREADY,
    input  wire [63:0] in_r_TDATA,
    input  wire        in_r_TVALID,
    output wire        in_r_TREADY,
    input  wire        in_r_TLAST,
    input  wire [7:0]  in_r_TKEEP,
    output wire [63:0] out_r_TDATA,
    output wire        out_r_TVALID,
    input  wire        out_r_TREADY,
    output wire        out_r_TLAST
);
    assign s_axi_control_BRESP = 2'b00;
    assign s_axi_control_RRESP = 2'b00;

    /* ---------------- 参数寄存器 ---------------- */
    reg        r_mode;           // 0=DW 1=PW
    reg [31:0] r_mul;
    reg [7:0]  r_shift;
    reg [15:0] r_xzp, r_yzp, r_n, r_c, r_w, r_coutt, r_ww, r_bw, r_ochunk;
    reg        r_str2;
    reg        ap_start;

    wire pw_done, dw_done;
    wire running = ap_start;

    /* ---------------- AXI-Lite 写(AW/W 独立捕获) ---------------- */
    reg [6:0] awr_addr; reg awr_got; reg [31:0] wdat_r; reg w_got;
    always @(posedge ap_clk) begin
        if (!ap_rst_n) begin
            s_axi_control_AWREADY <= 1; s_axi_control_WREADY <= 1; s_axi_control_BVALID <= 0;
            awr_got <= 0; w_got <= 0; awr_addr <= 0; wdat_r <= 0;
            r_mode <= 0; r_mul <= 0; r_shift <= 8'd28; r_xzp <= 0; r_yzp <= 0;
            r_n <= 0; r_c <= 0; r_w <= 0; r_coutt <= 0; r_ww <= 0; r_bw <= 0;
            r_ochunk <= 0; r_str2 <= 0; ap_start <= 0;
        end else begin
            if ((r_mode && pw_done) || (!r_mode && dw_done)) ap_start <= 0;  // 帧完自清
            if (s_axi_control_AWREADY && s_axi_control_AWVALID) begin
                awr_addr <= s_axi_control_AWADDR; awr_got <= 1; s_axi_control_AWREADY <= 0;
            end
            if (s_axi_control_WREADY && s_axi_control_WVALID) begin
                wdat_r <= s_axi_control_WDATA; w_got <= 1; s_axi_control_WREADY <= 0;
            end
            if (awr_got && w_got) begin
                case (awr_addr)
                    7'h00: ap_start  <= wdat_r[0];
                    7'h10: r_mode    <= wdat_r[0];
                    7'h18: r_mul     <= wdat_r;
                    7'h20: r_shift   <= wdat_r[7:0];
                    7'h28: r_xzp     <= wdat_r[15:0];
                    7'h30: r_yzp     <= wdat_r[15:0];
                    7'h38: r_n       <= wdat_r[15:0];
                    7'h40: r_c       <= wdat_r[15:0];
                    7'h48: r_w       <= wdat_r[15:0];
                    7'h50: r_coutt   <= wdat_r[15:0];
                    7'h58: r_ww      <= wdat_r[15:0];
                    7'h60: r_bw      <= wdat_r[15:0];
                    7'h68: r_str2    <= wdat_r[0];
                    7'h70: r_ochunk  <= wdat_r[15:0];
                    default: ;
                endcase
                awr_got <= 0; w_got <= 0;
                s_axi_control_AWREADY <= 1; s_axi_control_WREADY <= 1;
                s_axi_control_BVALID <= 1;
            end
            if (s_axi_control_BVALID && s_axi_control_BREADY)
                s_axi_control_BVALID <= 0;
        end
    end

    /* ---------------- AXI-Lite 读 ---------------- */
    always @(posedge ap_clk) begin
        if (!ap_rst_n) begin
            s_axi_control_ARREADY <= 1; s_axi_control_RVALID <= 0; s_axi_control_RDATA <= 0;
        end else begin
            if (s_axi_control_ARREADY && s_axi_control_ARVALID) begin
                s_axi_control_ARREADY <= 0; s_axi_control_RVALID <= 1;
                case (s_axi_control_ARADDR)
                    7'h00:   s_axi_control_RDATA <= {29'd0, ~running, 1'b0, running};
                    7'h10:   s_axi_control_RDATA <= {31'd0, r_mode};
                    7'h18:   s_axi_control_RDATA <= r_mul;
                    default: s_axi_control_RDATA <= 32'hDEAD_0000;
                endcase
            end else if (s_axi_control_RVALID && s_axi_control_RREADY) begin
                s_axi_control_RVALID <= 0; s_axi_control_ARREADY <= 1;
            end
        end
    end

    /* ---------------- 流分发 ---------------- */
    wire        pw_in_tready, dw_in_tready;
    wire [63:0] pw_out_tdata, dw_out_tdata;
    wire        pw_out_tvalid, dw_out_tvalid, pw_out_tlast, dw_out_tlast;

    assign in_r_TREADY = r_mode ? pw_in_tready : dw_in_tready;

    assign out_r_TDATA  = r_mode ? pw_out_tdata  : dw_out_tdata;
    assign out_r_TVALID = r_mode ? pw_out_tvalid : dw_out_tvalid;
    assign out_r_TLAST  = r_mode ? pw_out_tlast  : dw_out_tlast;

    /* ---------------- 共享乘法池(两核互斥,r_mode 二选一) ---------------- */
    wire [639:0]  pw_mp_a;  wire [511:0] pw_mp_b;
    wire [719:0]  dw_mp_a;  wire [575:0] dw_mp_b;
    wire [1295:0] pool_p;
    wire [255:0]  pw_rq_acc, dw_rq_acc;
    wire [511:0]  rq_t;

    wire [719:0]  pool_a = r_mode ? {80'd0, pw_mp_a} : dw_mp_a;
    wire [575:0]  pool_b = r_mode ? {64'd0, pw_mp_b} : dw_mp_b;
    wire [255:0]  rq_acc = r_mode ? pw_rq_acc : dw_rq_acc;
    wire          pw_pipe_en, dw_pipe_en;
    wire          pool_en = r_mode ? 1'b1 : dw_pipe_en;

    mac_pool_rtl u_pool (.ap_clk(ap_clk), .en(pool_en), .a(pool_a), .b(pool_b), .p(pool_p));
    rq_mult_rtl  u_rq   (.ap_clk(ap_clk), .en(r_mode ? pw_pipe_en : dw_pipe_en),
                         .acc(rq_acc), .mul(r_mul), .t(rq_t));

    pw_core_rtl u_pw (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .ap_start(ap_start &  r_mode),
        .r_mul(r_mul), .r_shift(r_shift), .r_xzp(r_xzp), .r_yzp(r_yzp),
        .r_n(r_n), .r_c(r_c), .r_coutt(r_coutt), .r_ww(r_ww), .r_bw(r_bw),
        .in_r_TDATA(in_r_TDATA),
        .in_r_TVALID(in_r_TVALID &  r_mode),
        .in_r_TREADY(pw_in_tready),
        .in_r_TLAST(in_r_TLAST),
        .out_r_TDATA(pw_out_tdata), .out_r_TVALID(pw_out_tvalid),
        .out_r_TREADY(out_r_TREADY &  r_mode), .out_r_TLAST(pw_out_tlast),
        .done(pw_done),
        .mp_a(pw_mp_a), .mp_b(pw_mp_b), .mp_p(pool_p[1151:0]),
        .rq_acc(pw_rq_acc), .rq_t(rq_t), .pipe_en(pw_pipe_en)
    );

    dw_core_rtl u_dw (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .ap_start(ap_start & ~r_mode),
        .r_mul(r_mul), .r_shift(r_shift), .r_xzp(r_xzp), .r_yzp(r_yzp),
        .r_n(r_n), .r_c(r_c), .r_w(r_w), .r_ww(r_ww), .r_bw(r_bw),
        .r_ochunk(r_ochunk), .r_str2(r_str2),
        .in_r_TDATA(in_r_TDATA),
        .in_r_TVALID(in_r_TVALID & ~r_mode),
        .in_r_TREADY(dw_in_tready),
        .in_r_TLAST(in_r_TLAST),
        .out_r_TDATA(dw_out_tdata), .out_r_TVALID(dw_out_tvalid),
        .out_r_TREADY(out_r_TREADY & ~r_mode), .out_r_TLAST(dw_out_tlast),
        .done(dw_done),
        .mp_a(dw_mp_a), .mp_b(dw_mp_b), .mp_p(pool_p),
        .rq_acc(dw_rq_acc), .rq_t(rq_t), .pipe_en(dw_pipe_en)
    );
endmodule
