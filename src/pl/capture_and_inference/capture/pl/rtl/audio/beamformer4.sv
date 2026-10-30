`timescale 1ns/1ps

module beamformer4 (
    input wire clk, input wire rst, input wire sample_valid, input wire block_start,
    input wire signed [23:0] sample_0, sample_1, sample_2, sample_3,
    input wire [5:0] shadow_delay_0, shadow_delay_1, shadow_delay_2, shadow_delay_3,
    input wire [14:0] shadow_frac_0, shadow_frac_1, shadow_frac_2, shadow_frac_3,
    input wire signed [15:0] shadow_weight_0, shadow_weight_1, shadow_weight_2, shadow_weight_3,
    output reg signed [23:0] beam_sample, output reg beam_valid, output reg overflow
);
    reg [5:0] active_delay_0, active_delay_1, active_delay_2, active_delay_3;
    reg [14:0] active_frac_0, active_frac_1, active_frac_2, active_frac_3;
    reg signed [15:0] active_weight_0, active_weight_1, active_weight_2, active_weight_3;
    wire [5:0] use_delay_0 = block_start ? shadow_delay_0 : active_delay_0;
    wire [5:0] use_delay_1 = block_start ? shadow_delay_1 : active_delay_1;
    wire [5:0] use_delay_2 = block_start ? shadow_delay_2 : active_delay_2;
    wire [5:0] use_delay_3 = block_start ? shadow_delay_3 : active_delay_3;
    wire [14:0] use_frac_0 = block_start ? shadow_frac_0 : active_frac_0;
    wire [14:0] use_frac_1 = block_start ? shadow_frac_1 : active_frac_1;
    wire [14:0] use_frac_2 = block_start ? shadow_frac_2 : active_frac_2;
    wire [14:0] use_frac_3 = block_start ? shadow_frac_3 : active_frac_3;
    wire signed [15:0] use_weight_0 = block_start ? shadow_weight_0 : active_weight_0;
    wire signed [15:0] use_weight_1 = block_start ? shadow_weight_1 : active_weight_1;
    wire signed [15:0] use_weight_2 = block_start ? shadow_weight_2 : active_weight_2;
    wire signed [15:0] use_weight_3 = block_start ? shadow_weight_3 : active_weight_3;

    wire signed [23:0] delayed_0, delayed_1, delayed_2, delayed_3;
    wire delayed_valid_0, delayed_valid_1, delayed_valid_2, delayed_valid_3;
    fractional_delay u_delay_0 (clk, rst, sample_valid, sample_0, use_delay_0, use_frac_0, delayed_0, delayed_valid_0);
    fractional_delay u_delay_1 (clk, rst, sample_valid, sample_1, use_delay_1, use_frac_1, delayed_1, delayed_valid_1);
    fractional_delay u_delay_2 (clk, rst, sample_valid, sample_2, use_delay_2, use_frac_2, delayed_2, delayed_valid_2);
    fractional_delay u_delay_3 (clk, rst, sample_valid, sample_3, use_delay_3, use_frac_3, delayed_3, delayed_valid_3);

    reg signed [15:0] weight_pipe_0, weight_pipe_1, weight_pipe_2, weight_pipe_3;
    reg signed [15:0] weight_align_0, weight_align_1, weight_align_2, weight_align_3;
    reg signed [15:0] weight_final_0, weight_final_1, weight_final_2, weight_final_3;
    reg signed [39:0] product_0, product_1, product_2, product_3;
    reg signed [40:0] pair_01, pair_23;
    reg product_valid, pair_valid;
    wire signed [23:0] saturated;
    wire overflow_comb;
    beam_sum_sat u_sum_sat (pair_01, pair_23, saturated, overflow_comb);

    always @(posedge clk) begin
        if (rst) begin
            active_delay_0 <= 0; active_delay_1 <= 0; active_delay_2 <= 0; active_delay_3 <= 0;
            active_frac_0 <= 0; active_frac_1 <= 0; active_frac_2 <= 0; active_frac_3 <= 0;
            active_weight_0 <= 8192; active_weight_1 <= 8192; active_weight_2 <= 8192; active_weight_3 <= 8192;
            weight_pipe_0 <= 0; weight_pipe_1 <= 0; weight_pipe_2 <= 0; weight_pipe_3 <= 0;
            weight_align_0 <= 0; weight_align_1 <= 0; weight_align_2 <= 0; weight_align_3 <= 0;
            weight_final_0 <= 0; weight_final_1 <= 0; weight_final_2 <= 0; weight_final_3 <= 0;
            product_0 <= 0; product_1 <= 0; product_2 <= 0; product_3 <= 0;
            pair_01 <= 0; pair_23 <= 0;
            product_valid <= 0; pair_valid <= 0;
            beam_sample <= 0; beam_valid <= 0; overflow <= 0;
        end else begin
            if (block_start) begin
                active_delay_0 <= shadow_delay_0; active_delay_1 <= shadow_delay_1;
                active_delay_2 <= shadow_delay_2; active_delay_3 <= shadow_delay_3;
                active_frac_0 <= shadow_frac_0; active_frac_1 <= shadow_frac_1;
                active_frac_2 <= shadow_frac_2; active_frac_3 <= shadow_frac_3;
                active_weight_0 <= shadow_weight_0; active_weight_1 <= shadow_weight_1;
                active_weight_2 <= shadow_weight_2; active_weight_3 <= shadow_weight_3;
            end
            if (sample_valid) begin
                weight_pipe_0 <= use_weight_0; weight_pipe_1 <= use_weight_1;
                weight_pipe_2 <= use_weight_2; weight_pipe_3 <= use_weight_3;
            end
            weight_align_0 <= weight_pipe_0; weight_align_1 <= weight_pipe_1;
            weight_align_2 <= weight_pipe_2; weight_align_3 <= weight_pipe_3;
            weight_final_0 <= weight_align_0; weight_final_1 <= weight_align_1;
            weight_final_2 <= weight_align_2; weight_final_3 <= weight_align_3;
            product_valid <= delayed_valid_0;
            if (delayed_valid_0) begin
                product_0 <= $signed(delayed_0) * $signed(weight_final_0);
                product_1 <= $signed(delayed_1) * $signed(weight_final_1);
                product_2 <= $signed(delayed_2) * $signed(weight_final_2);
                product_3 <= $signed(delayed_3) * $signed(weight_final_3);
            end
            pair_valid <= product_valid;
            if (product_valid) begin
                pair_01 <= $signed(product_0) + $signed(product_1);
                pair_23 <= $signed(product_2) + $signed(product_3);
            end
            beam_valid <= pair_valid;
            overflow <= 0;
            if (pair_valid) begin beam_sample <= saturated; overflow <= overflow_comb; end
        end
    end
endmodule
