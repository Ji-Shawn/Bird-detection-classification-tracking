`timescale 1ns/1ps

(* keep_hierarchy = "yes", use_dsp = "no" *)
module beam_sum_sat (
    input  wire signed [40:0] pair_01,
    input  wire signed [40:0] pair_23,
    output reg  signed [23:0] result,
    output reg                overflow
);
    reg signed [42:0] accumulator;
    reg signed [42:0] magnitude;
    reg signed [42:0] rounded;

    always @* begin
        accumulator = $signed(pair_01) + $signed(pair_23);
        if (accumulator < 0) begin
            magnitude = -accumulator;
            rounded = -((magnitude + 43'sd16384) >>> 15);
        end else begin
            rounded = (accumulator + 43'sd16384) >>> 15;
        end
        overflow = 1'b0;
        if (rounded > 43'sd8388607) begin
            result = 24'sh7fffff;
            overflow = 1'b1;
        end else if (rounded < -43'sd8388608) begin
            result = -24'sd8388608;
            overflow = 1'b1;
        end else begin
            result = rounded[23:0];
        end
    end
endmodule
