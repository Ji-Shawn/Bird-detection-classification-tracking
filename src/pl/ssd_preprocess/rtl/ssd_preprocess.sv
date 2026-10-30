`timescale 1ns/1ps
// Fixed 1920x1080 RGB565 (two little-endian pixels/word) -> 320x320 RGB int8.
// Green byte 127 is an internal marker for sum=1453; driver must repair it
// using the original float32 expression before handing the tensor to SSD.
module ssd_preprocess(
 input wire aclk,aresetn,
 input wire [31:0] s_axis_tdata,input wire s_axis_tvalid,s_axis_tlast,
 output wire s_axis_tready,
 output reg [31:0] m_axis_tdata,output reg m_axis_tvalid,m_axis_tlast,
 input wire m_axis_tready,output wire [3:0] m_axis_tkeep,
 output reg protocol_error
);
 wire en=!m_axis_tvalid || m_axis_tready;
 assign s_axis_tready=en && !protocol_error;
 assign m_axis_tkeep=4'hf;
 reg [9:0] ix,sample_word;
 reg [10:0] iy,top_y;
 reg [8:0] column,out_y;
 reg [3:0] fraction;
 reg [8:0] top_r[0:319],top_g[0:319],top_b[0:319];
 function automatic [7:0] red(input [15:0] p);red={p[15:11],p[15:13]};endfunction
 function automatic [7:0] green(input [15:0] p);green={p[10:5],p[10:9]};endfunction
 function automatic [7:0] blue(input [15:0] p);blue={p[4:0],p[4:2]};endfunction
 wire [8:0] sr={1'b0,red(s_axis_tdata[15:0])}+{1'b0,red(s_axis_tdata[31:16])};
 wire [8:0] sg={1'b0,green(s_axis_tdata[15:0])}+{1'b0,green(s_axis_tdata[31:16])};
 wire [8:0] sb={1'b0,blue(s_axis_tdata[15:0])}+{1'b0,blue(s_axis_tdata[31:16])};
 reg v0,v1,v2;
 reg [8:0] ar,ag,ab,br,bg,bb;
 reg [4:0] f0,inv0;
 reg [12:0] wr,wg,wb;
 (* rom_style="block" *) reg [7:0] qr[0:8191],qg[0:8191],qb[0:8191];
 initial begin
  $readmemh("quant0.hex",qr);$readmemh("quant1.hex",qg);$readmemh("quant2.hex",qb);
 end
 reg [23:0] rgb,carry;
 reg [1:0] pack_phase;
 reg [16:0] output_word;
 wire accept=s_axis_tvalid && s_axis_tready;
 wire selected=(ix==sample_word) && (iy==top_y || iy==top_y+1'b1);
 always @(posedge aclk) begin
  if(!aresetn) begin
   ix<=0;iy<=0;sample_word<=1;column<=0;top_y<=1;fraction<=3;out_y<=0;
   v0<=0;v1<=0;v2<=0;ar<=0;ag<=0;ab<=0;br<=0;bg<=0;bb<=0;
   f0<=0;inv0<=0;wr<=0;wg<=0;wb<=0;rgb<=0;carry<=0;pack_phase<=0;output_word<=0;
   m_axis_tdata<=0;m_axis_tvalid<=0;m_axis_tlast<=0;protocol_error<=0;
  end else if(en) begin
   v0<=0;v1<=v0;v2<=v1;m_axis_tvalid<=0;m_axis_tlast<=0;
   if(accept) begin
    if(s_axis_tlast != (ix==959 && iy==1079)) protocol_error<=1;
    if(selected) begin
     if(iy==top_y) begin top_r[column]<=sr;top_g[column]<=sg;top_b[column]<=sb;end
     else begin
      ar<=top_r[column];ag<=top_g[column];ab<=top_b[column];
      br<=sr;bg<=sg;bb<=sb;f0<={1'b0,fraction};inv0<=5'd16-{1'b0,fraction};v0<=1;
     end
     if(column<319) begin column<=column+1'b1;sample_word<=sample_word+3;end
    end
    if(ix==959) begin
     ix<=0;sample_word<=1;column<=0;
     if(iy==top_y+1'b1 && out_y<319) begin
      top_y<=top_y+11'd3+({1'b0,fraction}+5'd6>=16);
      fraction<=fraction+4'd6;out_y<=out_y+1'b1;
     end
     if(iy==1079) begin iy<=0;top_y<=1;fraction<=3;out_y<=0;end
     else iy<=iy+1'b1;
    end else ix<=ix+1'b1;
   end
   if(v0) begin wr<=ar*inv0+br*f0;wg<=ag*inv0+bg*f0;wb<=ab*inv0+bb*f0;end
   if(v1) rgb<={qb[wb],(wg==1453 ? 8'd127:qg[wg]),qr[wr]};
   if(v2) begin
    pack_phase<=pack_phase+1'b1;
    case(pack_phase)
     0:carry<=rgb;
     1:begin m_axis_tdata<={rgb[7:0],carry};carry<={8'b0,rgb[23:8]};end
     2:begin m_axis_tdata<={rgb[15:0],carry[15:0]};carry<={16'b0,rgb[23:16]};end
     3:begin m_axis_tdata<={rgb,carry[7:0]};carry<=0;end
    endcase
    if(pack_phase!=0) begin
     m_axis_tvalid<=1;m_axis_tlast<=(output_word==76799);
     if(output_word==76799)output_word<=0;else output_word<=output_word+1'b1;
    end
   end
  end
 end
endmodule
