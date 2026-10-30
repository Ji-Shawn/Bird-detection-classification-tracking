`timescale 1ns/1ps

module audio_frontend_top #(
    parameter integer SCK_HALF_DIV = 24
) (
    input  wire                     clk_98m304,
    input  wire                     rst,
    input  wire                     mic_sd_0,
    input  wire                     mic_sd_1,
    input  wire                     mic_sd_2,
    input  wire                     mic_sd_3,
    input  wire                     config_apply,
    output wire                     mic_sck,
    output wire                     mic_ws,
    input  wire [5:0]               shadow_delay_0,
    input  wire [5:0]               shadow_delay_1,
    input  wire [5:0]               shadow_delay_2,
    input  wire [5:0]               shadow_delay_3,
    input  wire [14:0]              shadow_frac_0,
    input  wire [14:0]              shadow_frac_1,
    input  wire [14:0]              shadow_frac_2,
    input  wire [14:0]              shadow_frac_3,
    input  wire signed [15:0]        shadow_weight_0,
    input  wire signed [15:0]        shadow_weight_1,
    input  wire signed [15:0]        shadow_weight_2,
    input  wire signed [15:0]        shadow_weight_3,
    output wire signed [23:0]        raw_0,
    output wire signed [23:0]        raw_1,
    output wire signed [23:0]        raw_2,
    output wire signed [23:0]        raw_3,
    output wire                     raw_valid,
    output wire                     block_start,
    output wire signed [23:0]        beam_sample,
    output wire                     beam_valid,
    output wire                     beam_overflow,
    output reg                      overflow_sticky
);
    wire quad_valid;
    (* mark_debug = "true", keep = "true" *) wire [31:0] sample_index;
    (* mark_debug = "true", keep = "true" *) wire audio_clk_locked = !rst;
    reg [8:0] sample_count;

    i2s_quad_rx #(.SCK_HALF_DIV(SCK_HALF_DIV)) u_i2s (
        .clk(clk_98m304), .rst(rst),
        .sd_0(mic_sd_0), .sd_1(mic_sd_1), .sd_2(mic_sd_2), .sd_3(mic_sd_3),
        .i2s_sck(mic_sck), .i2s_ws(mic_ws),
        .sample_0(raw_0), .sample_1(raw_1), .sample_2(raw_2), .sample_3(raw_3),
        .quad_valid(quad_valid), .sample_index(sample_index)
    );

    assign raw_valid = quad_valid;
    assign block_start = quad_valid && (sample_count == 0);

    beamformer4 u_beam (
        .clk(clk_98m304), .rst(rst), .sample_valid(quad_valid), .block_start(config_apply),
        .sample_0(raw_0), .sample_1(raw_1), .sample_2(raw_2), .sample_3(raw_3),
        .shadow_delay_0(shadow_delay_0), .shadow_delay_1(shadow_delay_1),
        .shadow_delay_2(shadow_delay_2), .shadow_delay_3(shadow_delay_3),
        .shadow_frac_0(shadow_frac_0), .shadow_frac_1(shadow_frac_1),
        .shadow_frac_2(shadow_frac_2), .shadow_frac_3(shadow_frac_3),
        .shadow_weight_0(shadow_weight_0), .shadow_weight_1(shadow_weight_1),
        .shadow_weight_2(shadow_weight_2), .shadow_weight_3(shadow_weight_3),
        .beam_sample(beam_sample), .beam_valid(beam_valid), .overflow(beam_overflow)
    );

    always @(posedge clk_98m304) begin
        if (rst) begin
            sample_count <= 9'd0;
            overflow_sticky <= 1'b0;
        end else begin
            if (quad_valid) begin
                if (sample_count == 9'd479)
                    sample_count <= 9'd0;
                else
                    sample_count <= sample_count + 1'b1;
            end
            if (beam_overflow)
                overflow_sticky <= 1'b1;
        end
    end
endmodule
