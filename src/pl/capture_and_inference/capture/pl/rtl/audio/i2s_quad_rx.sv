`timescale 1ns/1ps

module i2s_quad_rx #(
    parameter integer SCK_HALF_DIV = 24
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     sd_0,
    input  wire                     sd_1,
    input  wire                     sd_2,
    input  wire                     sd_3,
    output reg                      i2s_sck,
    output reg                      i2s_ws,
    output reg signed [23:0]         sample_0,
    output reg signed [23:0]         sample_1,
    output reg signed [23:0]         sample_2,
    output reg signed [23:0]         sample_3,
    output reg                      quad_valid,
    output reg [31:0]               sample_index
);
    localparam integer DIV_W = (SCK_HALF_DIV <= 2) ? 1 : $clog2(SCK_HALF_DIV);

    reg [DIV_W-1:0] div_count;
    reg [5:0] bit_pos;
    reg [23:0] shift_0;
    reg [23:0] shift_1;
    reg [23:0] shift_2;
    reg [23:0] shift_3;
    reg [23:0] left_0;
    reg [23:0] left_1;
    reg [23:0] left_2;
    reg [23:0] left_3;
    // Discard startup frame: resetting WS in the middle of a physical slot
    // does not guarantee that the microphone saw a complete left boundary.
    reg armed;
    reg [31:0] next_sample_index;

    always @(posedge clk) begin
        if (rst) begin
            div_count  <= {DIV_W{1'b0}};
            i2s_sck    <= 1'b0;
            i2s_ws     <= 1'b0;
            bit_pos    <= 6'd0;
            shift_0    <= 24'd0;
            shift_1    <= 24'd0;
            shift_2    <= 24'd0;
            shift_3    <= 24'd0;
            left_0     <= 24'd0;
            left_1     <= 24'd0;
            left_2     <= 24'd0;
            left_3     <= 24'd0;
            sample_0   <= 24'sd0;
            sample_1   <= 24'sd0;
            sample_2   <= 24'sd0;
            sample_3   <= 24'sd0;
            quad_valid <= 1'b0;
            armed <= 1'b0;
            sample_index <= 32'd0;
            next_sample_index <= 32'd0;
        end else begin
            quad_valid <= 1'b0;
            if (div_count == SCK_HALF_DIV-1) begin
                div_count <= {DIV_W{1'b0}};
                i2s_sck <= ~i2s_sck;

                // Capture on the generated SCK rising edge. Position zero is
                // the I2S one-bit delay; positions 1..24 carry signed PCM.
                if (!i2s_sck) begin
                    if (!i2s_ws && (bit_pos >= 6'd1) && (bit_pos <= 6'd24)) begin
                        shift_0 <= {shift_0[22:0], sd_0};
                        shift_1 <= {shift_1[22:0], sd_1};
                        shift_2 <= {shift_2[22:0], sd_2};
                        shift_3 <= {shift_3[22:0], sd_3};
                    end

                    if (!i2s_ws && (bit_pos == 6'd24)) begin
                        left_0 <= {shift_0[22:0], sd_0};
                        left_1 <= {shift_1[22:0], sd_1};
                        left_2 <= {shift_2[22:0], sd_2};
                        left_3 <= {shift_3[22:0], sd_3};
                    end

                    if (bit_pos == 6'd31) begin
                        bit_pos <= 6'd0;
                        if (i2s_ws) begin
                            armed <= 1'b1;
                            sample_0 <= $signed(left_0);
                            sample_1 <= $signed(left_1);
                            sample_2 <= $signed(left_2);
                            sample_3 <= $signed(left_3);
                            quad_valid <= armed;
                            if (armed) begin
                                sample_index <= next_sample_index;
                                next_sample_index <= next_sample_index + 1'b1;
                            end
                        end
                    end else begin
                        bit_pos <= bit_pos + 1'b1;
                    end
                end else if (bit_pos == 6'd0) begin
                    // WS changes only on falling SCK. INMP441 requires 20 ns
                    // hold after rising SCK; changing both together gave 0 ns.
                    // Counter already wrapped at the preceding rising edge;
                    // next rising edge is the new slot's I2S dummy bit.
                    i2s_ws <= ~i2s_ws;
                end
            end else begin
                div_count <= div_count + 1'b1;
            end
        end
    end
endmodule
