`timescale 1ns/1ps

module multiscale_illum #(
    parameter integer MAX_WIDTH = 1280
) (
    input  wire              clk,
    input  wire              rst,
    input  wire              in_valid,
    input  wire [7:0]        in_y,
    input  wire signed [8:0] in_cb,
    input  wire signed [8:0] in_cr,
    input  wire              in_sof,
    input  wire              in_eol,
    input  wire [10:0]       in_x,
    input  wire [9:0]        in_row,
    output wire              out_valid,
    output reg [7:0]         out_y,
    output reg signed [8:0]  out_cb,
    output reg signed [8:0]  out_cr,
    output wire [7:0]        mean5,
    output wire [7:0]        mean15,
    output wire [7:0]        mean33,
    output wire              out_sof,
    output wire              out_eol
);
    (* ram_style = "block" *) reg [300:0] line_history [0:MAX_WIDTH-1];
    reg [300:0] history_word;
    reg s0_valid;
    reg [7:0] s0_y;
    reg signed [8:0] s0_cb;
    reg signed [8:0] s0_cr;
    reg s0_sof;
    reg s0_eol;
    reg [10:0] s0_x;
    reg [9:0] s0_row;

    integer vertical5_i;
    integer vertical15_i;
    integer vertical33_i;
    integer leaving5_i;
    integer leaving15_i;
    integer leaving33_i;
    reg [13:0] vertical5;
    reg [13:0] vertical15;
    reg [13:0] vertical33;
    reg [13:0] vertical5_pipe;
    reg [13:0] vertical15_pipe;
    reg [13:0] vertical33_pipe;
    reg vertical_pipe_valid;
    reg vertical_pipe_sof;
    reg vertical_pipe_eol;
    reg [10:0] vertical_pipe_x;

    wire valid5;
    wire valid15;
    wire valid33;
    wire sof5;
    wire eol5;
    reg [7:0] y_delay;
    reg signed [8:0] cb_delay;
    reg signed [8:0] cr_delay;
    reg [7:0] y_delay2;
    reg signed [8:0] cb_delay2;
    reg signed [8:0] cr_delay2;
    reg [7:0] y_delay3;
    reg signed [8:0] cb_delay3;
    reg signed [8:0] cr_delay3;
    reg [7:0] y_delay4;
    reg signed [8:0] cb_delay4;
    reg signed [8:0] cr_delay4;
    reg [7:0] y_delay5;
    reg signed [8:0] cb_delay5;
    reg signed [8:0] cr_delay5;

    always @* begin
        if (s0_row == 0) begin
            leaving5_i = s0_y;
            leaving15_i = s0_y;
            leaving33_i = s0_y;
            vertical5_i = s0_y * 5;
            vertical15_i = s0_y * 15;
            vertical33_i = s0_y * 33;
        end else begin
            if (s0_row < 5)
                leaving5_i = history_word[((s0_row - 1) * 8) +: 8];
            else
                leaving5_i = history_word[39:32];
            if (s0_row < 15)
                leaving15_i = history_word[((s0_row - 1) * 8) +: 8];
            else
                leaving15_i = history_word[119:112];
            if (s0_row < 33)
                leaving33_i = history_word[((s0_row - 1) * 8) +: 8];
            else
                leaving33_i = history_word[263:256];
            vertical5_i = history_word[274:264] + s0_y - leaving5_i;
            vertical15_i = history_word[286:275] + s0_y - leaving15_i;
            vertical33_i = history_word[300:287] + s0_y - leaving33_i;
        end
        vertical5 = vertical5_i[13:0];
        vertical15 = vertical15_i[13:0];
        vertical33 = vertical33_i[13:0];
    end

    always @(posedge clk) begin
        if (rst) begin
            s0_valid <= 1'b0;
            vertical_pipe_valid <= 1'b0;
            vertical_pipe_sof <= 1'b0;
            vertical_pipe_eol <= 1'b0;
            vertical_pipe_x <= 11'd0;
            vertical5_pipe <= 14'd0;
            vertical15_pipe <= 14'd0;
            vertical33_pipe <= 14'd0;
            out_y <= 8'd0;
            out_cb <= 9'sd0;
            out_cr <= 9'sd0;
            y_delay <= 8'd0;
            cb_delay <= 9'sd0;
            cr_delay <= 9'sd0;
            y_delay2 <= 8'd0;
            cb_delay2 <= 9'sd0;
            cr_delay2 <= 9'sd0;
            y_delay3 <= 8'd0;
            cb_delay3 <= 9'sd0;
            cr_delay3 <= 9'sd0;
            y_delay4 <= 8'd0;
            cb_delay4 <= 9'sd0;
            cr_delay4 <= 9'sd0;
            y_delay5 <= 8'd0;
            cb_delay5 <= 9'sd0;
            cr_delay5 <= 9'sd0;
        end else begin
            s0_valid <= in_valid;
            vertical_pipe_valid <= s0_valid;
            vertical_pipe_sof <= s0_valid && s0_sof;
            vertical_pipe_eol <= s0_valid && s0_eol;
            if (s0_valid) begin
                vertical5_pipe <= vertical5;
                vertical15_pipe <= vertical15;
                vertical33_pipe <= vertical33;
                vertical_pipe_x <= s0_x;
            end
            if (in_valid) begin
                history_word <= line_history[in_x];
                s0_y   <= in_y;
                s0_cb  <= in_cb;
                s0_cr  <= in_cr;
                s0_sof <= in_sof;
                s0_eol <= in_eol;
                s0_x   <= in_x;
                s0_row <= in_row;
            end
            if (s0_valid) begin
                line_history[s0_x] <= {
                    vertical33, vertical15[11:0], vertical5[10:0],
                    history_word[255:0], s0_y
                };
                y_delay  <= s0_y;
                cb_delay <= s0_cb;
                cr_delay <= s0_cr;
            end
            y_delay2 <= y_delay;
            cb_delay2 <= cb_delay;
            cr_delay2 <= cr_delay;
            y_delay3 <= y_delay2;
            cb_delay3 <= cb_delay2;
            cr_delay3 <= cr_delay2;
            y_delay4 <= y_delay3;
            cb_delay4 <= cb_delay3;
            cr_delay4 <= cr_delay3;
            y_delay5 <= y_delay4;
            cb_delay5 <= cb_delay4;
            cr_delay5 <= cr_delay4;
            out_y <= y_delay5;
            out_cb <= cb_delay5;
            out_cr <= cr_delay5;
        end
    end

    box_mean_stream #(.WINDOW(5), .AREA(25)) mean5_filter (
        .clk(clk), .rst(rst), .in_valid(vertical_pipe_valid),
        .in_vertical_sum(vertical5_pipe), .in_x(vertical_pipe_x),
        .in_sof(vertical_pipe_sof), .in_eol(vertical_pipe_eol),
        .out_valid(valid5), .out_mean(mean5),
        .out_sof(sof5), .out_eol(eol5)
    );
    box_mean_stream #(.WINDOW(15), .AREA(225)) mean15_filter (
        .clk(clk), .rst(rst), .in_valid(vertical_pipe_valid),
        .in_vertical_sum(vertical15_pipe), .in_x(vertical_pipe_x),
        .in_sof(vertical_pipe_sof), .in_eol(vertical_pipe_eol),
        .out_valid(valid15), .out_mean(mean15),
        .out_sof(), .out_eol()
    );
    box_mean_stream #(.WINDOW(33), .AREA(1089)) mean33_filter (
        .clk(clk), .rst(rst), .in_valid(vertical_pipe_valid),
        .in_vertical_sum(vertical33_pipe), .in_x(vertical_pipe_x),
        .in_sof(vertical_pipe_sof), .in_eol(vertical_pipe_eol),
        .out_valid(valid33), .out_mean(mean33),
        .out_sof(), .out_eol()
    );

    assign out_valid = valid5 && valid15 && valid33;
    assign out_sof = sof5;
    assign out_eol = eol5;
endmodule
