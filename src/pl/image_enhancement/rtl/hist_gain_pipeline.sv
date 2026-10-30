`timescale 1ns/1ps
module hist_gain_pipeline(input wire clk,rst,input wire[74:0]s_token,
 input wire[20:0]gain,input wire[8:0]alpha,input wire bypass,output wire[74:0]m_token);
 localparam[20:0]Q=21'd262144;
 reg[74:0]tokens[0:3];reg[3:0]raw;
 wire[29:0]scaled=(gain-Q)*alpha;
 reg[20:0]effective;
 reg[26:0]pr,pg,pb;
 reg[8:0]r,g,b;reg[15:0]packed_pixel;integer i;
 always @(posedge clk)begin
 if(rst)begin
 for(i=0;i<4;i=i+1)tokens[i]<=0;
 raw<=0;effective<=Q;pr<=0;pg<=0;pb<=0;r<=0;g<=0;b<=0;packed_pixel<=0;
 end else begin
 tokens[0]<=s_token;raw[0]<=bypass;
 for(i=1;i<4;i=i+1)begin tokens[i]<=tokens[i-1];raw[i]<=raw[i-1];end
 effective<=Q+scaled[28:8];
 pr<=tokens[0][15:11]*effective;pg<=tokens[0][10:5]*effective;pb<=tokens[0][4:0]*effective;
 r<=(pr+27'd131072)>>18;g<=(pg+27'd131072)>>18;b<=(pb+27'd131072)>>18;
 packed_pixel<={(r>31?5'd31:r[4:0]),(g>63?6'd63:g[5:0]),(b>31?5'd31:b[4:0])};
 end end
 assign m_token={tokens[3][74:16],raw[3]?tokens[3][15:0]:packed_pixel};
endmodule
