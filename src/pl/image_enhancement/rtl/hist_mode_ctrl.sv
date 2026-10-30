`timescale 1ns/1ps
module hist_mode_ctrl(input wire clk,rst,stats_valid,fault,input wire[7:0]mean_y,
 output reg active);
 reg[2:0]low_streak,high_streak;
 always @(posedge clk)begin
 if(rst || fault)begin active<=0;low_streak<=0;high_streak<=0;end
 else if(stats_valid)begin
 if(mean_y<65)begin
 high_streak<=0;if(low_streak<4)low_streak<=low_streak+1'b1;
 if(low_streak>=3)active<=1;
 end else if(mean_y>85)begin
 low_streak<=0;if(high_streak<4)high_streak<=high_streak+1'b1;
 if(high_streak>=3)active<=0;
 end else begin low_streak<=0;high_streak<=0;end
 end end
endmodule
