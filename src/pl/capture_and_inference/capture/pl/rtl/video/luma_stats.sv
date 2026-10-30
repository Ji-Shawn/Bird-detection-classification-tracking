`timescale 1ns/1ps

module luma_stats (
    input  wire        clk,
    input  wire        rst,
    input  wire        in_valid,
    input  wire [7:0]  in_y,
    input  wire        in_sof,
    input  wire        frame_good,
    input  wire        frame_abort,
    output reg [31:0]  sum_y,
    output reg [31:0]  dark_count,
    output reg         enhance_active_next
);
    localparam [7:0] DARK_Y_THRESHOLD = 8'd64;
    localparam [31:0] MEAN_ENTER = 32'd70;
    localparam [31:0] MEAN_EXIT = 32'd85;
    localparam [31:0] MEAN_IMMEDIATE_EXIT = 32'd110;
    localparam [31:0] DARK_RATIO_ENTER_Q15 = 32'd19661;

    reg [31:0] current_sum;
    reg [31:0] current_dark;
    reg [31:0] current_pixels;
    reg [2:0] bright_run;
    reg aborted;

    wire [63:0] mean_enter_limit = current_pixels * MEAN_ENTER;
    wire [63:0] mean_exit_limit = current_pixels * MEAN_EXIT;
    wire [63:0] mean_immediate_exit_limit = current_pixels * MEAN_IMMEDIATE_EXIT;
    wire [63:0] dark_scaled = {32'd0, current_dark} << 15;
    wire [63:0] dark_ratio_limit = current_pixels * DARK_RATIO_ENTER_Q15;

    always @(posedge clk) begin
        if (rst) begin
            current_sum        <= 32'd0;
            current_dark       <= 32'd0;
            current_pixels     <= 32'd0;
            sum_y              <= 32'd0;
            dark_count         <= 32'd0;
            enhance_active_next <= 1'b0;
            bright_run         <= 3'd0;
            aborted            <= 1'b0;
        end else begin
            if (in_valid && in_sof) begin
                current_sum    <= frame_abort ? 32'd0 : {24'd0, in_y};
                current_dark   <= (!frame_abort && in_y < DARK_Y_THRESHOLD) ? 32'd1 : 32'd0;
                current_pixels <= frame_abort ? 32'd0 : 32'd1;
                aborted        <= frame_abort;
            end else if (frame_abort) begin
                aborted <= 1'b1;
            end else if (in_valid && !aborted) begin
                current_sum    <= current_sum + in_y;
                current_pixels <= current_pixels + 1'b1;
                if (in_y < DARK_Y_THRESHOLD)
                    current_dark <= current_dark + 1'b1;
            end

            if (frame_good && !frame_abort && !aborted &&
                (current_pixels != 0)) begin
                sum_y      <= current_sum;
                dark_count <= current_dark;
                if (!enhance_active_next) begin
                    bright_run <= 3'd0;
                    if (({32'd0, current_sum} < mean_enter_limit) ||
                        (({32'd0, current_sum} <= mean_exit_limit) &&
                         (dark_scaled > dark_ratio_limit)))
                        enhance_active_next <= 1'b1;
                end else if ({32'd0, current_sum} >= mean_immediate_exit_limit) begin
                    enhance_active_next <= 1'b0;
                    bright_run <= 3'd0;
                end else if ({32'd0, current_sum} > mean_exit_limit) begin
                    if (bright_run == 3'd4) begin
                        enhance_active_next <= 1'b0;
                        bright_run <= 3'd0;
                    end else begin
                        bright_run <= bright_run + 1'b1;
                    end
                end else begin
                    bright_run <= 3'd0;
                end
            end
        end
    end
endmodule
