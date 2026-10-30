`timescale 1ns/1ps
// SSN-24 verified 1920x1080 reduced blanking: 2080x1106, 115MHz, H+/V-, 49.9896Hz.
module hdmi_raster #(
 parameter integer HACTIVE=1920,HFRONT=48,HSYNC=32,HBACK=80,
 parameter integer VACTIVE=1080,VFRONT=3,VSYNC=5,VBACK=18
)(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 pixel_clk CLK", X_INTERFACE_PARAMETER="ASSOCIATED_RESET resetn, FREQ_HZ 115000000" *) input wire pixel_clk,
 (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 resetn RST", X_INTERFACE_PARAMETER="POLARITY ACTIVE_LOW" *) input wire resetn,
 input wire force_bars,input wire hpd,input wire stream_locked,underflow,overflow,
 input wire[23:0]stream_data,input wire stream_de,stream_hsync,stream_vsync,
 output wire timing_hsync,timing_vsync,timing_hblank,timing_vblank,timing_de,frame_sync,
 output wire[23:0]video_data,output wire video_de,video_hsync,video_vsync,
 output wire hdmi_out_en,output wire[31:0]status,output wire status_strobe
);
 localparam HTOTAL=HACTIVE+HFRONT+HSYNC+HBACK;
 localparam VTOTAL=VACTIVE+VFRONT+VSYNC+VBACK;
 reg[11:0]x,y;reg[15:0]frames;
 (* ASYNC_REG="TRUE" *) reg[1:0]force_sync,hpd_sync;
 reg bars_selected,underflow_seen,overflow_seen;
 assign timing_hblank=x>=HACTIVE;assign timing_vblank=y>=VACTIVE;
 assign timing_de=!timing_hblank && !timing_vblank;
 assign timing_hsync=x>=HACTIVE+HFRONT && x<HACTIVE+HFRONT+HSYNC;
 assign timing_vsync=y>=VACTIVE+VFRONT && y<VACTIVE+VFRONT+VSYNC;
 // A read frame is requested at the start of vertical blanking, with time to prefetch.
 assign frame_sync=x==0 && y==VACTIVE;
 assign status_strobe=frame_sync;
 always @(posedge pixel_clk)begin
  if(!resetn)begin
   x<=0;y<=0;frames<=0;force_sync<=0;hpd_sync<=0;bars_selected<=1;
   underflow_seen<=0;overflow_seen<=0;
  end else begin
   force_sync<={force_sync[0],force_bars};hpd_sync<={hpd_sync[0],hpd};
   if(x==HTOTAL-1)begin x<=0;if(y==VTOTAL-1)begin y<=0;frames<=frames+1'b1;end else y<=y+1'b1;end
   else x<=x+1'b1;
   if(frame_sync)bars_selected<=force_sync[1] || !stream_locked;
   if(underflow)underflow_seen<=1;if(overflow)overflow_seen<=1;
  end
 end
 reg[23:0]bar_rgb;
 always @*begin
  // Constant thresholds avoid a general divider in the pixel path.
  if(x<HACTIVE/8)bar_rgb=24'hffffff;
  else if(x<HACTIVE*2/8)bar_rgb=24'hffff00;
  else if(x<HACTIVE*3/8)bar_rgb=24'h00ffff;
  else if(x<HACTIVE*4/8)bar_rgb=24'h00ff00;
  else if(x<HACTIVE*5/8)bar_rgb=24'hff00ff;
  else if(x<HACTIVE*6/8)bar_rgb=24'hff0000;
  else if(x<HACTIVE*7/8)bar_rgb=24'h0000ff;
  else bar_rgb=0;
 end
 assign video_data=bars_selected?{bar_rgb[23:16],bar_rgb[7:0],bar_rgb[15:8]}:stream_data;
 assign video_de=bars_selected?timing_de:stream_de;
 assign video_hsync=bars_selected?timing_hsync:stream_hsync;
 assign video_vsync=!(bars_selected?timing_vsync:stream_vsync);
 assign hdmi_out_en=1'b1;
 assign status={frames,8'h18,2'b00,overflow_seen,underflow_seen,bars_selected,hpd_sync[1],stream_locked,resetn};
endmodule
