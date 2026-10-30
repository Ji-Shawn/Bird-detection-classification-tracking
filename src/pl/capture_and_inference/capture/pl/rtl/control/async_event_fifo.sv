`timescale 1ns/1ps

module async_event_fifo #(
    parameter integer WIDTH=17, parameter integer ADDR_WIDTH=3
) (
    input wire src_clk,input wire src_rst,input wire src_valid,input wire [WIDTH-1:0] src_data,
    output reg src_overflow,
    input wire dst_clk,input wire dst_rst,output reg dst_valid,output reg [WIDTH-1:0] dst_data
);
    localparam integer DEPTH=1<<ADDR_WIDTH;
    reg [WIDTH-1:0] mem[0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_bin,wr_gray,rd_bin,rd_gray;
    (* ASYNC_REG="TRUE" *) reg [ADDR_WIDTH:0] rd_gray_s1,rd_gray_s2;
    (* ASYNC_REG="TRUE" *) reg [ADDR_WIDTH:0] wr_gray_s1,wr_gray_s2;
    wire [ADDR_WIDTH:0] wr_bin_next=wr_bin+1'b1;
    wire [ADDR_WIDTH:0] wr_gray_next=(wr_bin_next>>1)^wr_bin_next;
    wire full=(wr_gray_next=={~rd_gray_s2[ADDR_WIDTH:ADDR_WIDTH-1],rd_gray_s2[ADDR_WIDTH-2:0]});
    wire empty=(rd_gray==wr_gray_s2);
    always @(posedge src_clk) begin
        if(src_rst) begin wr_bin<=0;wr_gray<=0;rd_gray_s1<=0;rd_gray_s2<=0;src_overflow<=0;end
        else begin
            rd_gray_s1<=rd_gray;rd_gray_s2<=rd_gray_s1;src_overflow<=0;
            if(src_valid) begin
                if(full) src_overflow<=1;
                else begin mem[wr_bin[ADDR_WIDTH-1:0]]<=src_data;wr_bin<=wr_bin_next;wr_gray<=wr_gray_next;end
            end
        end
    end
    always @(posedge dst_clk) begin
        if(dst_rst) begin rd_bin<=0;rd_gray<=0;wr_gray_s1<=0;wr_gray_s2<=0;dst_valid<=0;dst_data<=0;end
        else begin
            wr_gray_s1<=wr_gray;wr_gray_s2<=wr_gray_s1;dst_valid<=0;
            if(!empty) begin
                dst_data<=mem[rd_bin[ADDR_WIDTH-1:0]];dst_valid<=1;
                rd_bin<=rd_bin+1'b1;rd_gray<=((rd_bin+1'b1)>>1)^(rd_bin+1'b1);
            end
        end
    end
endmodule
