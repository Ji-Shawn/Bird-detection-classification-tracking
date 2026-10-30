`timescale 1ns/1ps
// RGB565, high byte first (OV5640 0x4300=0x61). All arithmetic is
// unsigned integer counting; no color arithmetic or truncating conversion.
module ov5640_dvp_capture #(
    parameter integer FRAME_WIDTH=1280, FRAME_HEIGHT=720
) (
    input wire pclk, rst, config_done, vsync, href,
    input wire [7:0] d,
    output reg pixel_valid, output reg [15:0] pixel_rgb565,
    output reg frame_start, frame_end, line_end, frame_good,
    output reg frame_size_error, line_size_error, format_error,
    output reg byte_phase, output reg camera_active,
    output reg [31:0] pixel_count, frame_count,
    output reg [15:0] line_count, current_width, current_height,
    output reg [10:0] x, output reg [10:0] y
);
    reg vsync_d,href_d,armed,sof_pending;
    reg [7:0] high_byte;
    reg [15:0] line_pixels;
    reg pending_valid,pending_sof;
    reg [15:0] pending_pixel;
    reg [10:0] pending_x;
    reg [10:0] pending_y;
    wire bad_frame=frame_size_error|line_size_error|format_error;
    always @(posedge pclk) begin
        if(rst || !config_done) begin
            vsync_d<=vsync;href_d<=href;armed<=0;sof_pending<=0;
            pixel_valid<=0;pixel_rgb565<=0;frame_start<=0;frame_end<=0;
            line_end<=0;frame_good<=0;frame_size_error<=0;
            line_size_error<=0;format_error<=0;byte_phase<=0;
            camera_active<=0;pixel_count<=0;frame_count<=0;
            line_count<=0;current_width<=0;current_height<=0;
            x<=0;y<=0;line_pixels<=0;pending_valid<=0;
            pending_pixel<=0;pending_sof<=0;pending_x<=0;pending_y<=0;high_byte<=0;
        end else begin
            vsync_d<=vsync;href_d<=href;
            pixel_valid<=0;frame_start<=0;frame_end<=0;line_end<=0;frame_good<=0;
            // Boundary branches are mutually exclusive with all byte capture.
            if(vsync && !vsync_d) begin
                if(armed) begin
                    frame_end<=1;
                    current_height<=line_count;
                    if(bad_frame || href || href_d || byte_phase || pending_valid ||
                       line_count!=FRAME_HEIGHT || pixel_count!=FRAME_WIDTH*FRAME_HEIGHT)
                        frame_size_error<=1;
                    else begin frame_good<=1;frame_count<=frame_count+1'b1;end
                    if(href || byte_phase) format_error<=1;
                end
                armed<=0;camera_active<=0;byte_phase<=0;pending_valid<=0;
            end else if(!vsync && vsync_d) begin
                armed<=!href;camera_active<=!href;sof_pending<=1;
                byte_phase<=0;line_pixels<=0;line_count<=0;pixel_count<=0;
                pending_valid<=0;frame_size_error<=0;line_size_error<=0;
                format_error<=href; // HREF coincident with VSYNC is not a valid blanking boundary.
            end else if(armed && !vsync && !bad_frame) begin
                if(href) begin
                    if(line_count>=FRAME_HEIGHT) begin
                        frame_size_error<=1;camera_active<=0;pending_valid<=0;byte_phase<=0;
                    end else if(!href_d) begin
                        high_byte<=d;byte_phase<=1;line_pixels<=0;
                    end else if(!byte_phase) begin
                        high_byte<=d;byte_phase<=1;
                    end else begin
                        byte_phase<=0;
                        if(line_pixels>=FRAME_WIDTH) begin
                            line_size_error<=1;pending_valid<=0;camera_active<=0;
                        end else begin
                            if(pending_valid) begin
                                pixel_valid<=1;pixel_rgb565<=pending_pixel;
                                frame_start<=pending_sof;x<=pending_x;y<=pending_y;
                            end
                            pending_valid<=1;pending_pixel<={high_byte,d};
                            pending_sof<=sof_pending;pending_x<=line_pixels[10:0];
                            pending_y<=line_count[10:0];sof_pending<=0;
                            line_pixels<=line_pixels+1'b1;pixel_count<=pixel_count+1'b1;
                        end
                    end
                end else if(href_d) begin
                    current_width<=line_pixels;
                    line_count<=line_count+1'b1;
                    if(byte_phase || !pending_valid || line_pixels!=FRAME_WIDTH) begin
                        line_size_error<=1;format_error<=byte_phase;camera_active<=0;
                    end else begin
                        pixel_valid<=1;pixel_rgb565<=pending_pixel;
                        frame_start<=pending_sof;line_end<=1;x<=pending_x;y<=pending_y;
                    end
                    byte_phase<=0;pending_valid<=0;
                end
            end else begin
                // Once corrupt, discard through VSYNC; never join two lines/frames.
                byte_phase<=0;pending_valid<=0;
            end
        end
    end
endmodule
