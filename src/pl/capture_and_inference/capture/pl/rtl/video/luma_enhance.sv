`timescale 1ns/1ps

module luma_enhance (
    input  wire              clk,
    input  wire              rst,
    input  wire              in_valid,
    input  wire [7:0]        in_y,
    input  wire signed [8:0] in_cb,
    input  wire signed [8:0] in_cr,
    input  wire [7:0]        mean5,
    input  wire [7:0]        mean15,
    input  wire [7:0]        mean33,
    input  wire              in_sof,
    input  wire              in_eol,
    input  wire              enhance_enable,
    input  wire              gamma_wr_en,
    input  wire [7:0]        gamma_wr_addr,
    input  wire [7:0]        gamma_wr_data,
    input  wire              gamma_commit,
    output reg               out_valid,
    output reg [7:0]         out_y,
    output reg signed [8:0]  out_cb,
    output reg signed [8:0]  out_cr,
    output reg               out_sof,
    output reg               out_eol,
    output reg               active_gamma_bank
);
    reg [7:0] gamma_bank0 [0:255];
    reg [7:0] gamma_bank1 [0:255];
    reg commit_pending;
    integer init_index;
    integer illumination_i;
    integer edge_i;
    integer selected_illum_i;
    integer corrected_i;
    integer boost_i;
    integer headroom_i;
    reg selected_bank;
    reg [7:0] enhanced_y;

    reg s1_valid;
    reg [7:0] s1_y;
    reg signed [8:0] s1_cb;
    reg signed [8:0] s1_cr;
    reg [7:0] s1_illum;
    reg s1_sof;
    reg s1_eol;
    reg s1_enable;
    reg s1_bank;

    reg s2_valid;
    reg [7:0] s2_y;
    reg signed [8:0] s2_cb;
    reg signed [8:0] s2_cr;
    reg [24:0] s2_product;
    reg s2_sof;
    reg s2_eol;
    reg s2_enable;
    reg s2_bank;

    initial begin
        for (init_index = 0; init_index < 256; init_index = init_index + 1) begin
            gamma_bank0[init_index] = init_index[7:0];
            gamma_bank1[init_index] = init_index[7:0];
        end
    end

    always @* begin
        illumination_i = (mean5 + (mean15 << 1) + mean33 + 2) >> 2;
        edge_i = (in_y >= mean5) ? (in_y - mean5) : (mean5 - in_y);
        if (edge_i > 24)
            selected_illum_i = ((mean5 * 3) + illumination_i + 2) >> 2;
        else
            selected_illum_i = illumination_i;
        boost_i = s2_product >> 7;
        headroom_i = (255 - s2_y) >> 2;
        if (boost_i > headroom_i)
            boost_i = headroom_i;
        corrected_i = s2_y + boost_i;

        selected_bank = active_gamma_bank;
        if (in_valid && in_sof && commit_pending)
            selected_bank = !active_gamma_bank;
        if (!s2_enable)
            enhanced_y = s2_y;
        else if (s2_bank)
            enhanced_y = gamma_bank1[corrected_i];
        else
            enhanced_y = gamma_bank0[corrected_i];
    end

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_y <= 8'd0;
            out_cb <= 9'sd0;
            out_cr <= 9'sd0;
            out_sof <= 1'b0;
            out_eol <= 1'b0;
            active_gamma_bank <= 1'b0;
            commit_pending <= 1'b0;
            s1_valid <= 1'b0;
            s2_valid <= 1'b0;
        end else begin
            if (gamma_wr_en) begin
                if (active_gamma_bank)
                    gamma_bank0[gamma_wr_addr] <= gamma_wr_data;
                else
                    gamma_bank1[gamma_wr_addr] <= gamma_wr_data;
            end
            if (gamma_commit)
                commit_pending <= 1'b1;
            if (in_valid && in_sof && commit_pending) begin
                active_gamma_bank <= !active_gamma_bank;
                commit_pending <= 1'b0;
            end

            s1_valid <= in_valid;
            if (in_valid) begin
                s1_y <= in_y;
                s1_cb <= in_cb;
                s1_cr <= in_cr;
                s1_illum <= selected_illum_i[7:0];
                s1_sof <= in_sof;
                s1_eol <= in_eol;
                s1_enable <= enhance_enable;
                s1_bank <= selected_bank;
            end

            s2_valid <= s1_valid;
            if (s1_valid) begin
                s2_y <= s1_y;
                s2_cb <= s1_cb;
                s2_cr <= s1_cr;
                // Suppress sensor noise near black and cap shadow lift; retain
                // highlight headroom and leave bright frames on the raw path.
                s2_product <= (s1_illum < 8'd96) ?
                              ((s1_y > 8'd12) ? (s1_y - 8'd12) : 8'd0) *
                              (8'd96 - s1_illum) : 25'd0;
                s2_sof <= s1_sof;
                s2_eol <= s1_eol;
                s2_enable <= s1_enable;
                s2_bank <= s1_bank;
            end

            out_valid <= s2_valid;
            out_sof <= s2_valid && s2_sof;
            out_eol <= s2_valid && s2_eol;
            if (s2_valid) begin
                out_y <= enhanced_y;
                out_cb <= s2_cb;
                out_cr <= s2_cr;
            end
        end
    end
endmodule
