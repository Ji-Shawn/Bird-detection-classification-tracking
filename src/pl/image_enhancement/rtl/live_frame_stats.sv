`timescale 1ns/1ps
// Exact per-frame raw Y statistics, independent of histogram builder occupancy.
module live_frame_stats #(parameter WIDTH=1920,HEIGHT=1080)(
 input wire clk,rst,valid,sof,eof,eol,input wire[10:0]x,y,input wire[15:0]rgb,
 output reg[7:0]mean,output reg[8:0]dark,output reg done,error);
 localparam N=WIDTH*HEIGHT;
 reg[31:0]count,darks,sum;
 wire[7:0]r={rgb[15:11],rgb[15:13]},g={rgb[10:5],rgb[10:9]},b={rgb[4:0],rgb[4:2]};
 wire[15:0]ys=16'd77*r+16'd150*g+16'd29*b;
 wire[7:0]yv=ys[15:8];
 reg[31:0]sum_snapshot,dark_snapshot;
 reg[1:0]stage;reg start;reg[47:0]numerator;
 wire busy,finished,zero;wire[47:0]quotient;
 unsigned_divider div(.clk(clk),.rst(rst),.start(start),.numerator(numerator),.denominator(N),.busy(busy),.done(finished),.zero_error(zero),.quotient(quotient));
 always @(posedge clk)begin
  if(rst)begin count<=0;darks<=0;sum<=0;mean<=0;dark<=0;done<=0;error<=0;stage<=0;start<=0;numerator<=0;sum_snapshot<=0;dark_snapshot<=0;end
  else begin
   start<=0;done<=0;
   if(valid)begin
    if(sof!=(count==0) || eof!=(count==N-1) || eol!=(x==WIDTH-1) || x>=WIDTH || y>=HEIGHT)error<=1;
    count<=eof?0:count+1'b1;sum<=eof?0:sum+yv;darks<=eof?0:darks+(yv<40);
    if(eof && count==N-1)begin
     if(stage!=0)error<=1;
     else begin sum_snapshot<=sum+yv;dark_snapshot<=darks+(yv<40);stage<=1;end
    end
   end
   if(stage==1 && !busy && !start)begin numerator<=sum_snapshot;start<=1;stage<=2;end
   if(stage==2 && finished)begin mean<=quotient[7:0];numerator<={dark_snapshot,8'b0};start<=1;stage<=3;end
   if(stage==3 && finished)begin dark<=quotient[8:0];done<=!error;stage<=0;end
   if(zero)error<=1;
  end
 end
endmodule
