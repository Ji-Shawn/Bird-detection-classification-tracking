`timescale 1ns/1ps

module ov5640_dvp_rx #(
    parameter integer FRAME_WIDTH  = 1280,
    parameter integer FRAME_HEIGHT = 720
) (
    input  wire        pclk,
    input  wire        rst,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  d,
    output reg         pixel_valid,
    output reg  [15:0] pixel_rgb565,
    output reg         sof,
    output reg         eol,
    output reg         frame_good,
    output reg         frame_abort,
    output reg  [10:0] x,
    output reg  [9:0]  y
);
    reg        vsync_d;
    reg        href_d;
    reg        frame_active;
    reg        sof_pending;
    reg        any_pixel;
    reg        byte_phase;
    reg [7:0]  high_byte;
    reg [11:0] line_pixels;
    reg [10:0] line_count;

    // Hold the newest complete pixel for one clock. The verified ALINX
    // receiver derives TLAST from the HREF falling edge, so only that edge
    // can identify the actual last pixel of a sensor line.
    reg        pending_valid;
    reg [15:0] pending_pixel;
    reg        pending_sof;
    reg [10:0] pending_x;
    reg [9:0]  pending_y;

    wire vsync_fall = !vsync && vsync_d;
    wire vsync_rise =  vsync && !vsync_d;
    wire href_assert   = href && !href_d;
    wire href_deassert = !href && href_d;

    always @(posedge pclk) begin
        if (rst) begin
            vsync_d       <= 1'b0;
            href_d        <= 1'b0;
            frame_active  <= 1'b0;
            sof_pending   <= 1'b0;
            any_pixel     <= 1'b0;
            byte_phase    <= 1'b0;
            high_byte     <= 8'h00;
            line_pixels   <= 12'd0;
            line_count    <= 11'd0;
            pending_valid <= 1'b0;
            pending_pixel <= 16'h0000;
            pending_sof   <= 1'b0;
            pending_x     <= 11'd0;
            pending_y     <= 10'd0;
            pixel_valid   <= 1'b0;
            pixel_rgb565  <= 16'h0000;
            sof           <= 1'b0;
            eol           <= 1'b0;
            frame_good    <= 1'b0;
            frame_abort   <= 1'b0;
            x             <= 11'd0;
            y             <= 10'd0;
        end else begin
            vsync_d <= vsync;
            href_d  <= href;
            pixel_valid <= 1'b0;
            sof <= 1'b0;
            eol <= 1'b0;
            frame_good <= 1'b0;

            // A falling VSYNC edge is the vendor receiver's frame marker.
            // Pixel capture itself is qualified only by HREF, independent of
            // VSYNC polarity, so both OV5640 timing profiles remain valid.
            if (vsync_fall) begin
                if (frame_active && any_pixel) begin
                    if (!frame_abort && !href && !byte_phase &&
                        !pending_valid && (line_count == FRAME_HEIGHT))
                        frame_good <= 1'b1;
                end
                frame_active <= 1'b1;
                sof_pending <= 1'b1;
                any_pixel <= 1'b0;
                byte_phase <= 1'b0;
                line_pixels <= 12'd0;
                line_count <= 11'd0;
                pending_valid <= 1'b0;
                frame_abort <= 1'b0;
            end else if (vsync_rise && frame_active && any_pixel) begin
                if (frame_abort || href || byte_phase || pending_valid ||
                    (line_count != FRAME_HEIGHT))
                    frame_abort <= 1'b1;
                else
                    frame_good <= 1'b1;
                frame_active <= 1'b0;
            end

            if (href_assert) begin
                high_byte <= d;
                byte_phase <= 1'b1;
                line_pixels <= 12'd0;
                if (pending_valid)
                    frame_abort <= 1'b1;
            end else if (href) begin
                if (!byte_phase) begin
                    high_byte <= d;
                    byte_phase <= 1'b1;
                end else begin
                    byte_phase <= 1'b0;
                    // Once the next pixel exists, the prior pixel cannot be
                    // the end of line and may be released immediately.
                    if (pending_valid) begin
                        pixel_valid <= 1'b1;
                        pixel_rgb565 <= pending_pixel;
                        sof <= pending_sof;
                        eol <= 1'b0;
                        x <= pending_x;
                        y <= pending_y;
                    end
                    pending_valid <= 1'b1;
                    pending_pixel <= {high_byte, d};
                    pending_sof <= sof_pending;
                    pending_x <= line_pixels[10:0];
                    pending_y <= line_count[9:0];
                    sof_pending <= 1'b0;
                    any_pixel <= 1'b1;
                    line_pixels <= line_pixels + 1'b1;
                end
            end

            if (href_deassert) begin
                // Release the held last pixel with TLAST exactly where the
                // sensor ends HREF, matching the verified vendor mechanism.
                if (pending_valid) begin
                    pixel_valid <= 1'b1;
                    pixel_rgb565 <= pending_pixel;
                    sof <= pending_sof;
                    eol <= 1'b1;
                    x <= pending_x;
                    y <= pending_y;
                end
                if (byte_phase || !pending_valid ||
                    (line_pixels != FRAME_WIDTH) ||
                    (line_count >= FRAME_HEIGHT))
                    frame_abort <= 1'b1;
                byte_phase <= 1'b0;
                pending_valid <= 1'b0;
                line_count <= line_count + 1'b1;
            end
        end
    end
endmodule
