`timescale 1ns/1ps
module camera_eth_adapter #(
    parameter integer FRAME_WIDTH=1280, FIFO_DEPTH=2048
) (
    input wire clk,rst,s_valid,s_sof,s_eol,test_pattern,
    input wire [15:0] s_data,input wire[10:0] s_x,
    output wire selected_valid,output wire[15:0] selected_data,
    output wire m_tvalid,input wire m_tready,output wire[15:0] m_tdata,
    output wire[1:0] m_tkeep,output wire m_tuser,m_tlast,
    output wire full,empty,overflow,underflow,output wire[31:0] drop_count
);
    reg bars_active;
    reg [15:0] bar_pixel;
    wire use_bars=s_sof ? test_pattern : bars_active;
    always @(posedge clk) begin
        if(rst) bars_active<=0;
        else if(s_valid && s_sof) bars_active<=test_pattern;
    end
    always @* begin
        if(s_x<FRAME_WIDTH/6) bar_pixel=16'hF800;
        else if(s_x<(FRAME_WIDTH*2)/6) bar_pixel=16'h07E0;
        else if(s_x<(FRAME_WIDTH*3)/6) bar_pixel=16'h001F;
        else if(s_x<(FRAME_WIDTH*4)/6) bar_pixel=16'hFFFF;
        else if(s_x<(FRAME_WIDTH*5)/6) bar_pixel=16'h0000;
        else bar_pixel=16'h8410;
    end
    assign selected_data=use_bars ? bar_pixel : s_data;
    assign selected_valid=s_valid;
    camera_cdc_or_fifo #(.DEPTH(FIFO_DEPTH)) queue(
        .clk(clk),.rst(rst),.s_valid(s_valid),.s_sof(s_sof),.s_eol(s_eol),.s_data(selected_data),
        .m_tvalid(m_tvalid),.m_tready(m_tready),.m_tdata(m_tdata),.m_tkeep(m_tkeep),
        .m_tuser(m_tuser),.m_tlast(m_tlast),.full(full),.empty(empty),
        .overflow(overflow),.underflow(underflow),.drop_count(drop_count));
endmodule
