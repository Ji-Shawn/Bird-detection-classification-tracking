`timescale 1ns/1ps

module box_mean_stream #(
    parameter integer WINDOW = 5,
    parameter integer AREA = 25
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        in_valid,
    input  wire [13:0] in_vertical_sum,
    input  wire [10:0] in_x,
    input  wire        in_sof,
    input  wire        in_eol,
    output reg         out_valid,
    output reg [7:0]   out_mean,
    output reg         out_sof,
    output reg         out_eol
);
    reg [13:0] history [0:WINDOW-1];
    reg [13:0] first_sum;
    reg [19:0] running_sum;
    reg [43:0] product_stage;
    reg [19:0] sum_stage;
    reg [19:0] pre_sum;
    reg s0_valid;
    reg [13:0] s0_vertical_sum;
    reg [10:0] s0_x;
    reg s0_sof;
    reg s0_eol;
    reg calc_valid;
    reg [13:0] calc_vertical_sum;
    reg [10:0] calc_x;
    reg [13:0] calc_leaving_sum;
    reg calc_sof;
    reg calc_eol;
    reg pre_valid;
    reg pre_sof;
    reg pre_eol;
    reg stage_valid;
    reg stage_sof;
    reg stage_eol;
    integer slot;
    integer next_sum;
    integer leaving_sum;
    reg [19:0] sum_for_mean;
    integer quotient_i;
    integer corrected_i;
    localparam [23:0] RECIP_Q24 = 16777216 / AREA;

    always @* begin
        slot = s0_x % WINDOW;
        leaving_sum = (s0_x == 0) ? s0_vertical_sum :
                      ((s0_x < WINDOW) ? first_sum : history[slot]);
        next_sum = running_sum + calc_vertical_sum - calc_leaving_sum;
        sum_for_mean = (calc_x == 0) ? (calc_vertical_sum * WINDOW) : next_sum;
        quotient_i = product_stage >> 24;
        if (((quotient_i + 1) * AREA) <= sum_stage)
            corrected_i = quotient_i + 1;
        else
            corrected_i = quotient_i;
    end

    always @(posedge clk) begin
        if (rst) begin
            out_valid   <= 1'b0;
            out_mean    <= 8'd0;
            out_sof     <= 1'b0;
            out_eol     <= 1'b0;
            first_sum   <= 14'd0;
            running_sum <= 20'd0;
            product_stage <= 44'd0;
            sum_stage <= 20'd0;
            pre_sum <= 20'd0;
            s0_valid <= 1'b0;
            s0_vertical_sum <= 14'd0;
            s0_x <= 11'd0;
            s0_sof <= 1'b0;
            s0_eol <= 1'b0;
            calc_valid <= 1'b0;
            calc_vertical_sum <= 14'd0;
            calc_x <= 11'd0;
            calc_leaving_sum <= 14'd0;
            calc_sof <= 1'b0;
            calc_eol <= 1'b0;
            pre_valid <= 1'b0;
            pre_sof <= 1'b0;
            pre_eol <= 1'b0;
            stage_valid <= 1'b0;
            stage_sof <= 1'b0;
            stage_eol <= 1'b0;
        end else begin
            out_valid <= stage_valid;
            out_sof   <= stage_valid && stage_sof;
            out_eol   <= stage_valid && stage_eol;
            stage_valid <= pre_valid;
            stage_sof <= pre_valid && pre_sof;
            stage_eol <= pre_valid && pre_eol;
            s0_valid <= in_valid;
            s0_vertical_sum <= in_vertical_sum;
            s0_x <= in_x;
            s0_sof <= in_valid && in_sof;
            s0_eol <= in_valid && in_eol;
            calc_valid <= s0_valid;
            calc_vertical_sum <= s0_vertical_sum;
            calc_x <= s0_x;
            calc_leaving_sum <= leaving_sum[13:0];
            calc_sof <= s0_valid && s0_sof;
            calc_eol <= s0_valid && s0_eol;
            pre_valid <= calc_valid;
            pre_sof <= calc_valid && calc_sof;
            pre_eol <= calc_valid && calc_eol;
            if (stage_valid)
                out_mean <= corrected_i[7:0];
            if (pre_valid) begin
                product_stage <= pre_sum * RECIP_Q24;
                sum_stage <= pre_sum;
            end
            if (s0_valid) begin
                history[slot] <= s0_vertical_sum;
                if (s0_x == 0)
                    first_sum <= s0_vertical_sum;
            end
            if (calc_valid) begin
                pre_sum <= sum_for_mean;
                if (calc_x == 0) begin
                    running_sum <= calc_vertical_sum * WINDOW;
                end else begin
                    running_sum <= next_sum;
                end
            end
        end
    end
endmodule
