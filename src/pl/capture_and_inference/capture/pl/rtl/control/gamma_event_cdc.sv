`timescale 1ns/1ps

module gamma_event_cdc(
    input wire src_clk,input wire src_rst,input wire src_valid,input wire [16:0] src_data,
    output wire src_overflow,
    input wire dst_clk,input wire dst_rst,output wire gamma_wr_en,
    output wire [7:0] gamma_wr_addr,output wire [7:0] gamma_wr_data,output wire gamma_commit
);
    wire event_valid;wire [16:0] event_data;
    async_event_fifo u_fifo(.src_clk(src_clk),.src_rst(src_rst),.src_valid(src_valid),
        .src_data(src_data),.src_overflow(src_overflow),.dst_clk(dst_clk),.dst_rst(dst_rst),
        .dst_valid(event_valid),.dst_data(event_data));
    assign gamma_commit=event_valid&&event_data[16];
    assign gamma_wr_en=event_valid&&!event_data[16];
    assign gamma_wr_addr=event_data[15:8];
    assign gamma_wr_data=event_data[7:0];
endmodule
