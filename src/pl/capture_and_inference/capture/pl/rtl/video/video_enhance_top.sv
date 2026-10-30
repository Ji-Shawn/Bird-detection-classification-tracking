`timescale 1ns/1ps

module video_enhance_top #(
    parameter integer FRAME_WIDTH = 1280,
    parameter integer FRAME_HEIGHT = 720,
    parameter integer MODEL_FIFO_DEPTH = 16,
    parameter integer RAW_FIFO_DEPTH = 32
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        in_valid,
    input  wire [15:0] in_rgb565,
    input  wire        in_sof,
    input  wire        in_eol,
    input  wire [10:0] in_x,
    input  wire [9:0]  in_y,
    input  wire        enhance_enable,
    input  wire        gamma_wr_en,
    input  wire [7:0]  gamma_wr_addr,
    input  wire [7:0]  gamma_wr_data,
    input  wire        gamma_commit,
    output reg         net_valid,
    output reg [15:0]  net_rgb565,
    output reg         net_sof,
    output reg         net_eol,
    output wire        model_tvalid,
    input  wire        model_tready,
    output wire [23:0] model_tdata,
    output wire        model_tuser,
    output wire        model_tlast,
    output wire        model_frame_abort,
    output wire [31:0] model_drop_count,
    output wire        active_gamma_bank
);
    wire colour_valid;
    wire [7:0] colour_y;
    wire signed [8:0] colour_cb;
    wire signed [8:0] colour_cr;
    wire colour_sof;
    wire colour_eol;
    reg [10:0] colour_x;
    reg [9:0] colour_row;

    wire illum_valid;
    wire [7:0] illum_y;
    wire signed [8:0] illum_cb;
    wire signed [8:0] illum_cr;
    wire [7:0] mean5;
    wire [7:0] mean15;
    wire [7:0] mean33;
    wire illum_sof;
    wire illum_eol;

    wire enhanced_valid;
    wire [7:0] enhanced_y;
    wire signed [8:0] enhanced_cb;
    wire signed [8:0] enhanced_cr;
    wire enhanced_sof;
    wire enhanced_eol;

    integer red_i;
    integer green_i;
    integer blue_i;
    reg [7:0] red_clipped;
    reg [7:0] green_clipped;
    reg [7:0] blue_clipped;
    reg [23:0] rgb888;
    reg c1_valid, c1_sof, c1_eol;
    reg [7:0] c1_y;
    reg signed [31:0] c1_r_product, c1_cb_product, c1_crg_product, c1_b_product;
    localparam integer RAW_PTR_WIDTH = $clog2(RAW_FIFO_DEPTH);
    reg [15:0] raw_pixel_fifo [0:RAW_FIFO_DEPTH-1];
    reg raw_enhance_fifo [0:RAW_FIFO_DEPTH-1];
    reg [RAW_PTR_WIDTH-1:0] raw_write_ptr;
    reg [RAW_PTR_WIDTH-1:0] raw_read_ptr;

    function [23:0] expand_rgb565;
        input [15:0] pixel;
        begin
            expand_rgb565 = {
                pixel[15:11], pixel[15:13],
                pixel[10:5], pixel[10:9],
                pixel[4:0], pixel[4:2]
            };
        end
    endfunction

    function integer floor_div256;
        input integer value;
        begin
            if (value >= 0)
                floor_div256 = value / 256;
            else
                floor_div256 = -((-value + 255) / 256);
        end
    endfunction

    rgb_ycbcr colour_transform (
        .clk(clk), .rst(rst), .in_valid(in_valid),
        .in_rgb565(in_rgb565), .in_sof(in_sof), .in_eol(in_eol),
        .out_valid(colour_valid), .out_y(colour_y),
        .out_cb(colour_cb), .out_cr(colour_cr),
        .out_sof(colour_sof), .out_eol(colour_eol)
    );

    always @(posedge clk) begin
        if (rst) begin
            colour_x <= 11'd0;
            colour_row <= 10'd0;
        end else if (in_valid) begin
            colour_x <= in_x;
            colour_row <= in_y;
        end
    end

    multiscale_illum #(.MAX_WIDTH(FRAME_WIDTH)) illumination (
        .clk(clk), .rst(rst), .in_valid(colour_valid),
        .in_y(colour_y), .in_cb(colour_cb), .in_cr(colour_cr),
        .in_sof(colour_sof), .in_eol(colour_eol),
        .in_x(colour_x), .in_row(colour_row),
        .out_valid(illum_valid), .out_y(illum_y),
        .out_cb(illum_cb), .out_cr(illum_cr),
        .mean5(mean5), .mean15(mean15), .mean33(mean33),
        .out_sof(illum_sof), .out_eol(illum_eol)
    );

    luma_enhance enhancer (
        .clk(clk), .rst(rst), .in_valid(illum_valid),
        .in_y(illum_y), .in_cb(illum_cb), .in_cr(illum_cr),
        .mean5(mean5), .mean15(mean15), .mean33(mean33),
        .in_sof(illum_sof), .in_eol(illum_eol),
        .enhance_enable(enhance_enable),
        .gamma_wr_en(gamma_wr_en), .gamma_wr_addr(gamma_wr_addr),
        .gamma_wr_data(gamma_wr_data), .gamma_commit(gamma_commit),
        .out_valid(enhanced_valid), .out_y(enhanced_y),
        .out_cb(enhanced_cb), .out_cr(enhanced_cr),
        .out_sof(enhanced_sof), .out_eol(enhanced_eol),
        .active_gamma_bank(active_gamma_bank)
    );

    always @* begin
        red_i = c1_y + floor_div256(c1_r_product + 128);
        green_i = c1_y - floor_div256(c1_cb_product + c1_crg_product + 128);
        blue_i = c1_y + floor_div256(c1_b_product + 128);

        if (red_i < 0)
            red_clipped = 8'd0;
        else if (red_i > 255)
            red_clipped = 8'd255;
        else
            red_clipped = red_i[7:0];
        if (green_i < 0)
            green_clipped = 8'd0;
        else if (green_i > 255)
            green_clipped = 8'd255;
        else
            green_clipped = green_i[7:0];
        if (blue_i < 0)
            blue_clipped = 8'd0;
        else if (blue_i > 255)
            blue_clipped = 8'd255;
        else
            blue_clipped = blue_i[7:0];
    end

    always @(posedge clk) begin
        if (rst) begin
            net_valid <= 1'b0;
            net_rgb565 <= 16'd0;
            net_sof <= 1'b0;
            net_eol <= 1'b0;
            rgb888 <= 24'd0;
            c1_valid <= 1'b0;
            c1_sof <= 1'b0;
            c1_eol <= 1'b0;
            c1_y <= 8'd0;
            c1_r_product <= 0;
            c1_cb_product <= 0;
            c1_crg_product <= 0;
            c1_b_product <= 0;
            raw_write_ptr <= {RAW_PTR_WIDTH{1'b0}};
            raw_read_ptr <= {RAW_PTR_WIDTH{1'b0}};
        end else begin
            if (in_valid) begin
                raw_pixel_fifo[raw_write_ptr] <= in_rgb565;
                raw_enhance_fifo[raw_write_ptr] <= enhance_enable;
                raw_write_ptr <= raw_write_ptr + 1'b1;
            end
            c1_valid <= enhanced_valid;
            c1_sof <= enhanced_valid && enhanced_sof;
            c1_eol <= enhanced_valid && enhanced_eol;
            if (enhanced_valid) begin
                c1_y <= enhanced_y;
                c1_r_product <= $signed(enhanced_cr) * 359;
                c1_cb_product <= $signed(enhanced_cb) * 88;
                c1_crg_product <= $signed(enhanced_cr) * 183;
                c1_b_product <= $signed(enhanced_cb) * 454;
            end
            net_valid <= c1_valid;
            net_sof <= c1_valid && c1_sof;
            net_eol <= c1_valid && c1_eol;
            if (c1_valid) begin
                raw_read_ptr <= raw_read_ptr + 1'b1;
                if (raw_enhance_fifo[raw_read_ptr]) begin
                    rgb888 <= {red_clipped, green_clipped, blue_clipped};
                    net_rgb565 <= {
                        red_clipped[7:3], green_clipped[7:2], blue_clipped[7:3]
                    };
                end else begin
                    rgb888 <= expand_rgb565(raw_pixel_fifo[raw_read_ptr]);
                    net_rgb565 <= raw_pixel_fifo[raw_read_ptr];
                end
            end
        end
    end

    model_video_axis #(.FIFO_DEPTH(MODEL_FIFO_DEPTH)) model_stream (
        .clk(clk), .rst(rst), .s_valid(net_valid), .s_data(rgb888),
        .s_sof(net_sof), .s_eol(net_eol),
        .m_tvalid(model_tvalid), .m_tready(model_tready),
        .m_tdata(model_tdata), .m_tuser(model_tuser), .m_tlast(model_tlast),
        .frame_abort(model_frame_abort), .drop_count(model_drop_count)
    );
endmodule
