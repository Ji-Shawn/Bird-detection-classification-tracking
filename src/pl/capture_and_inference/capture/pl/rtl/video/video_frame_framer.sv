`timescale 1ns/1ps

// Normalize AXI4-Stream video framing after a latency-heavy pixel pipeline.
// A propagated SOF acquires alignment and every later real SOF restores it.
// Geometry remains authoritative between source frame markers so malformed
// line markers cannot poison VDMA.
module video_frame_framer #(
    parameter integer FRAME_WIDTH = 1280,
    parameter integer FRAME_HEIGHT = 720
) (
    input wire clk,
    input wire rst,
    input wire s_valid,
    input wire [15:0] s_data,
    input wire s_sof,
    input wire s_eol,
    output wire m_valid,
    output wire [15:0] m_data,
    output wire m_sof,
    output wire m_eol
);
    reg locked;
    reg [10:0] x;
    reg [9:0] y;
    wire acquire = !locked && s_sof;
    wire accept = locked || acquire;
    wire consume = s_valid && accept;
    wire [10:0] active_x = s_sof ? 11'd0 : x;

    assign m_valid = consume;
    assign m_data = s_data;
    assign m_sof = consume && s_sof;
    assign m_eol = consume && (active_x == FRAME_WIDTH - 1);

    // s_eol is intentionally diagnostic-only: output line boundaries are
    // regenerated from the verified 1280x720 pixel geometry.
    wire unused_s_eol = s_eol;

    always @(posedge clk) begin
        if (rst) begin
            locked <= 1'b0;
            x <= 11'd0;
            y <= 10'd0;
        end else if (consume) begin
            locked <= 1'b1;
            if (s_sof) begin
                y <= 10'd0;
                if (FRAME_WIDTH == 1) begin
                    x <= 11'd0;
                    if (FRAME_HEIGHT != 1)
                        y <= 10'd1;
                end else begin
                    x <= 11'd1;
                end
            end else if (x == FRAME_WIDTH - 1) begin
                x <= 11'd0;
                if (y == FRAME_HEIGHT - 1)
                    y <= 10'd0;
                else
                    y <= y + 1'b1;
            end else begin
                x <= x + 1'b1;
            end
        end
    end
endmodule
