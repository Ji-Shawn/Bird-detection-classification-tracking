// (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:module_ref:hdmi_raster:1.0
// IP Revision: 1

(* X_CORE_INFO = "hdmi_raster,Vivado 2023.2" *)
(* CHECK_LICENSE_TYPE = "av_system_hdmi_raster_0,hdmi_raster,{}" *)
(* CORE_GENERATION_INFO = "av_system_hdmi_raster_0,hdmi_raster,{x_ipProduct=Vivado 2023.2,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=hdmi_raster,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,HACTIVE=1920,HFRONT=48,HSYNC=32,HBACK=80,VACTIVE=1080,VFRONT=3,VSYNC=5,VBACK=18}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module av_system_hdmi_raster_0 (
  pixel_clk,
  resetn,
  force_bars,
  hpd,
  stream_locked,
  underflow,
  overflow,
  stream_data,
  stream_de,
  stream_hsync,
  stream_vsync,
  timing_hsync,
  timing_vsync,
  timing_hblank,
  timing_vblank,
  timing_de,
  frame_sync,
  video_data,
  video_de,
  video_hsync,
  video_vsync,
  hdmi_out_en,
  status,
  status_strobe
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME pixel_clk, ASSOCIATED_RESET resetn, FREQ_HZ 115000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_hdmi_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 pixel_clk CLK" *)
input wire pixel_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn RST" *)
input wire resetn;
input wire force_bars;
input wire hpd;
input wire stream_locked;
input wire underflow;
input wire overflow;
input wire [23 : 0] stream_data;
input wire stream_de;
input wire stream_hsync;
input wire stream_vsync;
output wire timing_hsync;
output wire timing_vsync;
output wire timing_hblank;
output wire timing_vblank;
output wire timing_de;
output wire frame_sync;
output wire [23 : 0] video_data;
output wire video_de;
output wire video_hsync;
output wire video_vsync;
output wire hdmi_out_en;
output wire [31 : 0] status;
output wire status_strobe;

  hdmi_raster #(
    .HACTIVE(1920),
    .HFRONT(48),
    .HSYNC(32),
    .HBACK(80),
    .VACTIVE(1080),
    .VFRONT(3),
    .VSYNC(5),
    .VBACK(18)
  ) inst (
    .pixel_clk(pixel_clk),
    .resetn(resetn),
    .force_bars(force_bars),
    .hpd(hpd),
    .stream_locked(stream_locked),
    .underflow(underflow),
    .overflow(overflow),
    .stream_data(stream_data),
    .stream_de(stream_de),
    .stream_hsync(stream_hsync),
    .stream_vsync(stream_vsync),
    .timing_hsync(timing_hsync),
    .timing_vsync(timing_vsync),
    .timing_hblank(timing_hblank),
    .timing_vblank(timing_vblank),
    .timing_de(timing_de),
    .frame_sync(frame_sync),
    .video_data(video_data),
    .video_de(video_de),
    .video_hsync(video_hsync),
    .video_vsync(video_vsync),
    .hdmi_out_en(hdmi_out_en),
    .status(status),
    .status_strobe(status_strobe)
  );
endmodule
