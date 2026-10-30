`timescale 1ns/1ps

module av_status_cdc(
    input wire src_clk,input wire src_rst,input wire src_strobe,
    input wire [7:0] src_mean_y,input wire [15:0] src_dark_ratio,
    input wire [31:0] src_frame_count,input wire [31:0] src_video_drop,
    input wire dst_clk,input wire dst_rst,output wire dst_strobe,
    output wire [7:0] dst_mean_y,output wire [15:0] dst_dark_ratio,
    output wire [31:0] dst_frame_count,output wire [31:0] dst_video_drop
);
    wire [87:0] dst_bus;
    cdc_snapshot #(.WIDTH(88)) u_snapshot(.src_clk(src_clk),.src_rst(src_rst),
        .src_strobe(src_strobe),.src_data({src_video_drop,src_frame_count,src_dark_ratio,src_mean_y}),
        .dst_clk(dst_clk),.dst_rst(dst_rst),.dst_strobe(dst_strobe),.dst_data(dst_bus));
    assign dst_mean_y=dst_bus[7:0];assign dst_dark_ratio=dst_bus[23:8];
    assign dst_frame_count=dst_bus[55:24];assign dst_video_drop=dst_bus[87:56];
endmodule
