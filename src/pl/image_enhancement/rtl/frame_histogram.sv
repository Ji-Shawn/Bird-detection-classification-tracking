`timescale 1ns/1ps
module frame_histogram #(
 parameter integer WIDTH=1920,HEIGHT=1080,
 parameter integer CW=$clog2(WIDTH*HEIGHT+1)
)(input wire clk,rst,pixel_valid,sof,eof,input wire[15:0]rgb565,
 input wire release_frame,bin_read,input wire[7:0]bin_addr,
 output wire ready,output reg done,error,bin_valid,
 output wire[CW-1:0]bin_count,output reg[7:0]mean_y,output reg[8:0]dark_ratio);
 localparam integer N=WIDTH*HEIGHT;
 localparam CLEAR=0,COLLECT=1,DRAIN=2,HOLD=3;
 reg[1:0]state;reg[7:0]clear_addr;reg[2:0]drain_count;
 (* ram_style="block" *) reg[CW-1:0]mem[0:255];
 reg[CW-1:0]mem_q,forward_value,write_value,count,dark_count;
 reg forward_valid;
 wire[CW-1:0]read_value=forward_valid?forward_value:mem_q;
 assign bin_count=mem_q;
 reg[CW+7:0]sum_y;
 reg read_valid,write_valid;reg[7:0]read_addr,write_addr;
 wire[7:0]r={rgb565[15:11],rgb565[15:13]};
 wire[7:0]g={rgb565[10:5],rgb565[10:9]};
 wire[7:0]b={rgb565[4:0],rgb565[4:2]};
 wire[7:0]v=(r>g) ? ((r>b)?r:b) : ((g>b)?g:b);
 wire[7:0]mem_addr=(state==HOLD)?bin_addr:v;
 wire[17:0]ys=18'd77*r+18'd150*g+18'd29*b;
 wire[7:0]yv=ys[15:8];
 wire[CW-1:0]increment=((write_valid && write_addr==read_addr)?write_value:read_value)+1'b1;
 wire[7:0]mem_wa=state==CLEAR?clear_addr:write_addr;
 wire[CW-1:0]mem_wd=state==CLEAR?0:write_value;
 assign ready=state==COLLECT && !error;
 // Read and write ports intentionally separate. Pending write forwarding
 // removes dependence on synchronous RAM read-during-write behaviour.
 always @(posedge clk)begin
  if(state==CLEAR || write_valid)mem[mem_wa]<=mem_wd;
  mem_q<=mem[mem_addr];
  forward_valid<=write_valid && write_addr==mem_addr;
  forward_value<=write_value;
 end
 always @(posedge clk)begin
  if(rst)begin
   state<=CLEAR;clear_addr<=0;done<=0;error<=0;bin_valid<=0;
   read_valid<=0;write_valid<=0;count<=0;dark_count<=0;sum_y<=0;mean_y<=0;dark_ratio<=0;drain_count<=0;
   read_addr<=0;write_addr<=0;write_value<=0;
  end else begin
   done<=0;bin_valid<=bin_read && state==HOLD;
   read_valid<=pixel_valid && ready;
   write_valid<=read_valid;
   if(read_valid)begin write_addr<=read_addr;write_value<=increment;end
   if(pixel_valid && ready)begin
    read_addr<=v;
    if(sof!=(count==0) || eof!=(count==N-1))error<=1;
    count<=count+1'b1;sum_y<=sum_y+yv;
    if(yv<40)dark_count<=dark_count+1'b1;
    if(eof || count==N-1)begin state<=DRAIN;drain_count<=0;end
   end
   case(state)
    CLEAR:begin
     read_valid<=0;write_valid<=0;
     if(clear_addr==255)begin state<=COLLECT;count<=0;sum_y<=0;dark_count<=0;end
     else clear_addr<=clear_addr+1'b1;
    end
    DRAIN:begin
     drain_count<=drain_count+1'b1;
     if(drain_count==3)begin
      state<=HOLD;
      if(!error && count==N)begin
       mean_y<=sum_y/N;dark_ratio<=({dark_count,8'b0})/N;done<=1;
      end else error<=1;
     end
    end
    HOLD:if(release_frame && !error)begin state<=CLEAR;clear_addr<=0;end
    default:;
   endcase
  end
 end
endmodule
