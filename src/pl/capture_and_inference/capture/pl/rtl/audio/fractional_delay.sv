`timescale 1ns/1ps

module fractional_delay (
    input wire clk, input wire rst, input wire sample_valid,
    input wire signed [23:0] sample_in,
    input wire [5:0] delay_samples, input wire [14:0] fraction_q15,
    output reg signed [23:0] sample_out, output reg sample_out_valid
);
    integer index;
    reg signed [23:0] history [0:39];
    reg signed [23:0] selected_newer, selected_older;
    reg signed [23:0] newer_pipe, older_pipe;
    reg [14:0] fraction_pipe;
    reg tap_valid, mixed_valid;
    reg signed [24:0] delta;
    reg signed [40:0] correction, base_q15;
    reg signed [41:0] mixed_q15, mixed_pipe, magnitude, rounded;
    reg signed [23:0] interpolated;

    always @* begin
        if (delay_samples == 0) begin
            selected_newer = sample_in;
            selected_older = history[0];
        end else if (delay_samples <= 38) begin
            selected_newer = history[delay_samples-1'b1];
            selected_older = history[delay_samples];
        end else begin
            selected_newer = history[37];
            selected_older = history[38];
        end
        delta = $signed(older_pipe) - $signed(newer_pipe);
        correction = delta * $signed({1'b0, fraction_pipe});
        base_q15 = $signed(newer_pipe) <<< 15;
        mixed_q15 = $signed(base_q15) + $signed(correction);
        if (mixed_pipe < 0) begin
            magnitude = -mixed_pipe;
            rounded = -((magnitude + 42'sd16384) >>> 15);
        end else begin
            rounded = (mixed_pipe + 42'sd16384) >>> 15;
        end
        if (rounded > 42'sd8388607)
            interpolated = 24'sh7fffff;
        else if (rounded < -42'sd8388608)
            interpolated = -24'sd8388608;
        else
            interpolated = rounded[23:0];
    end

    always @(posedge clk) begin
        if (rst) begin
            for (index = 0; index < 40; index = index + 1)
                history[index] <= 24'sd0;
            newer_pipe <= 0; older_pipe <= 0; fraction_pipe <= 0;
            tap_valid <= 0; mixed_valid <= 0; mixed_pipe <= 0;
            sample_out <= 0; sample_out_valid <= 0;
        end else begin
            tap_valid <= sample_valid;
            mixed_valid <= tap_valid;
            sample_out_valid <= mixed_valid;
            if (sample_valid) begin
                newer_pipe <= selected_newer;
                older_pipe <= selected_older;
                fraction_pipe <= fraction_q15;
                for (index = 39; index > 0; index = index - 1)
                    history[index] <= history[index-1];
                history[0] <= sample_in;
            end
            if (tap_valid)
                mixed_pipe <= mixed_q15;
            if (mixed_valid)
                sample_out <= interpolated;
        end
    end
endmodule
