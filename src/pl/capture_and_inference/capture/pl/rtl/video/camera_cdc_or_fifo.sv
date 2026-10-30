`timescale 1ns/1ps
// Camera-side elastic queue. The existing video_cdc AXIS Clock Converter
// performs the asynchronous FIFO crossing AFTER this PCLK-domain queue.
// Do not replace that crossing with direct multi-bit sampling.
module camera_cdc_or_fifo # (parameter integer DEPTH=2048) (
    input wire clk,rst,s_valid,s_sof,s_eol,input wire[15:0] s_data,
    output wire m_tvalid,input wire m_tready,output wire[15:0] m_tdata,
    output wire[1:0] m_tkeep,output wire m_tuser,m_tlast,
    output wire full,empty,overflow,underflow,output wire[31:0] drop_count
);
    video_axis_fifo565 #(.DEPTH(DEPTH)) queue(
        .clk(clk),.rst(rst),.s_valid(s_valid),.s_sof(s_sof),.s_eol(s_eol),.s_data(s_data),
        .m_tvalid(m_tvalid),.m_tready(m_tready),.m_tdata(m_tdata),.m_tkeep(m_tkeep),
        .m_tuser(m_tuser),.m_tlast(m_tlast),.full(full),.empty(empty),
        .overflow(overflow),.underflow(underflow),.drop_count(drop_count));
endmodule
