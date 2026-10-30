`timescale 1ns/1ps

module rgb_ycbcr (
    input  wire              clk,
    input  wire              rst,
    input  wire              in_valid,
    input  wire [15:0]       in_rgb565,
    input  wire              in_sof,
    input  wire              in_eol,
    output reg               out_valid,
    output reg [7:0]         out_y,
    output reg signed [8:0]  out_cb,
    output reg signed [8:0]  out_cr,
    output reg               out_sof,
    output reg               out_eol
);
    integer r_value;
    integer g_value;
    integer b_value;
    integer y_acc;
    integer cb_acc;
    integer cr_acc;
    integer y_shifted;
    integer cb_shifted;
    integer cr_shifted;
    reg [7:0] y_next;
    reg signed [8:0] cb_next;
    reg signed [8:0] cr_next;

    always @* begin
        r_value = {in_rgb565[15:11], in_rgb565[15:13]};
        g_value = {in_rgb565[10:5], in_rgb565[10:9]};
        b_value = {in_rgb565[4:0], in_rgb565[4:2]};

        y_acc  = 77 * r_value + 150 * g_value + 29 * b_value + 128;
        cb_acc = -43 * r_value - 85 * g_value + 128 * b_value + 128;
        cr_acc = 128 * r_value - 107 * g_value - 21 * b_value + 128;
        y_shifted  = y_acc >>> 8;
        cb_shifted = cb_acc >>> 8;
        cr_shifted = cr_acc >>> 8;

        if (y_shifted < 0)
            y_next = 8'd0;
        else if (y_shifted > 255)
            y_next = 8'd255;
        else
            y_next = y_shifted[7:0];

        if (cb_shifted < -128)
            cb_next = -9'sd128;
        else if (cb_shifted > 127)
            cb_next = 9'sd127;
        else
            cb_next = cb_shifted[8:0];

        if (cr_shifted < -128)
            cr_next = -9'sd128;
        else if (cr_shifted > 127)
            cr_next = 9'sd127;
        else
            cr_next = cr_shifted[8:0];
    end

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_y     <= 8'd0;
            out_cb    <= 9'sd0;
            out_cr    <= 9'sd0;
            out_sof   <= 1'b0;
            out_eol   <= 1'b0;
        end else begin
            out_valid <= in_valid;
            out_sof   <= in_valid && in_sof;
            out_eol   <= in_valid && in_eol;
            if (in_valid) begin
                out_y  <= y_next;
                out_cb <= cb_next;
                out_cr <= cr_next;
            end
        end
    end
endmodule
