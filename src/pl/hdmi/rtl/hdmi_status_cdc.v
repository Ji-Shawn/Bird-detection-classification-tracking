`timescale 1ns/1ps

module hdmi_status_cdc #(parameter integer WIDTH=88)(
    input wire src_clk,input wire src_rst,input wire src_strobe,input wire [WIDTH-1:0] src_data,
    input wire dst_clk,input wire dst_rst,output reg dst_strobe,output reg [WIDTH-1:0] dst_data
);
    reg [WIDTH-1:0] held_data;reg src_toggle;
    (* ASYNC_REG="TRUE" *) reg toggle_s1,toggle_s2;
    reg toggle_seen;
    always @(posedge src_clk) begin
        if(src_rst) begin held_data<=0;src_toggle<=0;end
        else if(src_strobe) begin held_data<=src_data;src_toggle<=~src_toggle;end
    end
    always @(posedge dst_clk) begin
        if(dst_rst) begin toggle_s1<=0;toggle_s2<=0;toggle_seen<=0;dst_strobe<=0;dst_data<=0;end
        else begin
            toggle_s1<=src_toggle;toggle_s2<=toggle_s1;dst_strobe<=0;
            if(toggle_s2!=toggle_seen) begin dst_data<=held_data;dst_strobe<=1;toggle_seen<=toggle_s2;end
        end
    end
endmodule
