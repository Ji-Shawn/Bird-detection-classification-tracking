`timescale 1ns/1ps
module board_osd(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 s_axi_aclk CLK", X_INTERFACE_PARAMETER="ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn" *) input wire s_axi_aclk,
 (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 s_axi_aresetn RST", X_INTERFACE_PARAMETER="POLARITY ACTIVE_LOW" *) input wire s_axi_aresetn,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *) input wire [7:0]s_axi_awaddr,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *) input wire s_axi_awvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *) output wire s_axi_awready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WDATA" *) input wire [31:0]s_axi_wdata,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *) input wire [3:0]s_axi_wstrb,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WVALID" *) input wire s_axi_wvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WREADY" *) output wire s_axi_wready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BRESP" *) output wire [1:0]s_axi_bresp,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BVALID" *) output reg s_axi_bvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BREADY" *) input wire s_axi_bready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *) input wire [7:0]s_axi_araddr,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *) input wire s_axi_arvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *) output wire s_axi_arready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RDATA" *) output reg [31:0]s_axi_rdata,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RRESP" *) output wire [1:0]s_axi_rresp,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RVALID" *) output reg s_axi_rvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RREADY" *) input wire s_axi_rready,
 input wire pixel_clk,input wire pixel_resetn,input wire frame_boundary,
 input wire[31:0] status_in, output wire force_bars,
 input wire[23:0] video_data,input wire video_de,input wire video_hsync,input wire video_vsync,
 output reg[23:0] out_data,output reg out_de,output reg out_hsync,output reg out_vsync
);

 // AXI shadow registers remain stable until pixel-domain commit acknowledgement.
 reg[31:0] regs[0:23];reg request;reg ack;
 (* ASYNC_REG="TRUE" *) reg[1:0] req_sync,ack_sync;
 wire busy=request!=ack_sync[1];
 reg awheld,wheld;reg[7:0] awaddr;reg[31:0] wdata;reg[3:0] wstrb;
 assign s_axi_awready=!awheld && !s_axi_bvalid;
 assign s_axi_wready=!wheld && !s_axi_bvalid;
 assign s_axi_bresp=0;assign s_axi_rresp=0;
 assign s_axi_arready=!s_axi_rvalid;
 assign force_bars=regs[0][0];
 integer i,j;
 always @(posedge s_axi_aclk)begin
  if(!s_axi_aresetn)begin
   for(i=0;i<24;i=i+1)regs[i]<=0;
   regs[0]<=1;request<=0;ack_sync<=0;awheld<=0;wheld<=0;
   s_axi_bvalid<=0;s_axi_rvalid<=0;s_axi_rdata<=0;
  end else begin
   ack_sync<={ack_sync[0],ack};
   if(s_axi_bvalid && s_axi_bready)s_axi_bvalid<=0;
   if(s_axi_awvalid && s_axi_awready)begin awheld<=1;awaddr<=s_axi_awaddr;end
   if(s_axi_wvalid && s_axi_wready)begin wheld<=1;wdata<=s_axi_wdata;wstrb<=s_axi_wstrb;end
   if(awheld && wheld && !s_axi_bvalid)begin
    awheld<=0;wheld<=0;s_axi_bvalid<=1;
    if(awaddr[7:2]==1)begin if(!busy && wstrb[0])request<=!request;end
    else if(awaddr[7:2]==0 || (!busy && awaddr[7:2]>=4 && awaddr[7:2]<24))begin
     for(j=0;j<4;j=j+1)if(wstrb[j])regs[awaddr[7:2]][j*8+:8]<=wdata[j*8+:8];
    end
   end
   if(s_axi_rvalid && s_axi_rready)s_axi_rvalid<=0;
   if(s_axi_arvalid && s_axi_arready)begin
    s_axi_rvalid<=1;
    case(s_axi_araddr[7:2])
     2:s_axi_rdata<=status_in;
     3:s_axi_rdata<={31'b0,busy};
     default:s_axi_rdata<=s_axi_araddr[7:2]<24?regs[s_axi_araddr[7:2]]:32'b0;
    endcase
   end
  end
 end
 reg[43:0] box_live;reg box_on;reg[511:0] text_live;
 reg[9:0] lifetime;
 always @(posedge pixel_clk)begin
  if(!pixel_resetn)begin req_sync<=0;ack<=0;box_live<=0;box_on<=0;text_live<=0;lifetime<=0;end
  else begin
   req_sync<={req_sync[0],request};
   if(frame_boundary)begin
    if(req_sync[1]!=ack)begin
     box_live<={regs[5][26:16],regs[5][10:0],regs[4][26:16],regs[4][10:0]};
     box_on<=regs[6][0];
     text_live<={regs[23],regs[22],regs[21],regs[20],regs[19],regs[18],regs[17],regs[16],regs[15],regs[14],regs[13],regs[12],regs[11],regs[10],regs[9],regs[8]};
     lifetime<=0;ack<=req_sync[1];
    end else if(lifetime<600)lifetime<=lifetime+1'b1;
    else box_on<=0;
   end
  end
 end
 wire[10:0] x1=box_live[10:0],y1=box_live[21:11],x2=box_live[32:22],y2=box_live[43:33];
 reg[11:0] x,y;reg de_prev,vs_prev;
 always @(posedge pixel_clk)begin
  if(!pixel_resetn)begin x<=0;y<=0;de_prev<=0;vs_prev<=0;end
  else begin
   de_prev<=video_de;vs_prev<=video_vsync;
   if(vs_prev && !video_vsync)begin x<=0;y<=0;end
   else if(video_de)x<=x+1'b1;
   else begin x<=0;if(de_prev)y<=y+1'b1;end
  end
 end
 // 8x16 glyphs at 2x scale. Single synchronous ROM uses one 18Kb BRAM.
 (* rom_style="block" *) reg[7:0] font[0:2047];
 initial $readmemh("font.hex",font);
 wire panel=x>=16 && x<1040 && y>=16 && y<48;
 wire[5:0] char_index=(x-16)>>4;
 wire[7:0] char_code=text_live[char_index*8+:8];
 wire[3:0] glyph_row=(y-16)>>1;
 wire[10:0] glyph_addr={char_code[6:0],glyph_row};
 wire box_edge=box_on && x>=x1 && x<x2 && y>=y1 && y<y2 &&
            (x<x1+3 || x+3>=x2 || y<y1+3 || y+3>=y2);
 // Fixed center region is visible even when no target exists.
 wire center_frame=x>=864 && x<1056 && y>=486 && y<594 &&
                    (x<866 || x>=1054 || y<488 || y>=592);
 wire center_cross=(x>=952 && x<=968 && y>=539 && y<=541) ||
                   (x>=959 && x<=961 && y>=532 && y<=548);
 wire[11:0] target_x=({1'b0,x1}+{1'b0,x2})>>1;
 wire[11:0] target_y=({1'b0,y1}+{1'b0,y2})>>1;
 wire signed[11:0] target_dx=$signed(target_x)-12'sd960;
 wire signed[11:0] target_dy=$signed(target_y)-12'sd540;
 wire signed[11:0] pixel_dx=$signed(x)-12'sd960;
 wire signed[11:0] pixel_dy=$signed(y)-12'sd540;
 wire[11:0] abs_dx=target_dx[11]?-target_dx:target_dx;
 wire[11:0] abs_dy=target_dy[11]?-target_dy:target_dy;
 wire[11:0] abs_px=pixel_dx[11]?-pixel_dx:pixel_dx;
 wire[11:0] abs_py=pixel_dy[11]?-pixel_dy:pixel_dy;
 wire[11:0] min_x=target_x<960?target_x:12'd960;
 wire[11:0] max_x=target_x>960?target_x:12'd960;
 wire[11:0] min_y=target_y<540?target_y:12'd540;
 wire[11:0] max_y=target_y>540?target_y:12'd540;
 wire segment=box_on && (abs_dx!=0 || abs_dy!=0) &&
              x+12'd1>=min_x && x<=max_x+12'd1 &&
              y+12'd1>=min_y && y<=max_y+12'd1;
 wire dash=(abs_dx>=abs_dy)?!abs_px[3]:!abs_py[3];
 wire target_dot=box_on && x+12'd2>=target_x && x<=target_x+12'd2 &&
                             y+12'd2>=target_y && y<=target_y+12'd2;
 // Two DSP products, no runtime division; pipeline matches the existing ROM stage.
 (* use_dsp="yes" *) reg signed[23:0] cross_x,cross_y;
 reg segment_d;reg[11:0] major_d;
 reg center_frame_d,center_cross_d,target_dot_d;
 wire signed[24:0] cross_value=$signed({cross_x[23],cross_x})-$signed({cross_y[23],cross_y});
 wire[24:0] cross_abs=cross_value[24]?-cross_value:cross_value;
 wire dashed_line=segment_d && cross_abs<={13'b0,major_d};
 reg[7:0] glyph;reg[2:0] glyph_col;reg panel_d,edge_d;
 reg[23:0] data_d;reg de_d,hs_d,vs_d;
 always @(posedge pixel_clk)begin
  glyph<=font[glyph_addr];glyph_col<=(x-16)>>1;
  panel_d<=panel;edge_d<=box_edge;data_d<=video_data;de_d<=video_de;hs_d<=video_hsync;vs_d<=video_vsync;
  cross_x<=pixel_dx*target_dy;cross_y<=pixel_dy*target_dx;
  segment_d<=segment && dash;major_d<=abs_dx>=abs_dy?abs_dx:abs_dy;
  center_frame_d<=center_frame;center_cross_d<=center_cross;target_dot_d<=target_dot;
  if(!pixel_resetn)begin out_data<=0;out_de<=0;out_hsync<=0;out_vsync<=1;end
  else begin
   out_de<=de_d;out_hsync<=hs_d;out_vsync<=vs_d;
   // RGB2DVI consumes R,B,G byte order: yellow=ff00ff, magenta=ffff00.
   out_data<=panel_d?(glyph[7-glyph_col]?24'hffffff:24'h101010):
             edge_d?24'h0000ff:center_cross_d?24'hffffff:
             center_frame_d?24'h00ffff:target_dot_d?24'hffff00:
             dashed_line?24'hff00ff:data_d;
  end
 end
endmodule
