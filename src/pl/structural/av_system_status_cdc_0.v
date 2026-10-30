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


// IP VLNV: xilinx.com:module_ref:av_status_cdc:1.0
// IP Revision: 1

(* X_CORE_INFO = "av_status_cdc,Vivado 2023.2" *)
(* CHECK_LICENSE_TYPE = "av_system_status_cdc_0,av_status_cdc,{}" *)
(* CORE_GENERATION_INFO = "av_system_status_cdc_0,av_status_cdc,{x_ipProduct=Vivado 2023.2,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=av_status_cdc,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module av_system_status_cdc_0 (
  src_clk,
  src_rst,
  src_strobe,
  src_mean_y,
  src_dark_ratio,
  src_frame_count,
  src_video_drop,
  dst_clk,
  dst_rst,
  dst_strobe,
  dst_mean_y,
  dst_dark_ratio,
  dst_frame_count,
  dst_video_drop
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME src_clk, ASSOCIATED_RESET src_rst, FREQ_HZ 84000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN av_system_cam_pclk, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 src_clk CLK" *)
input wire src_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME src_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 src_rst RST" *)
input wire src_rst;
input wire src_strobe;
input wire [7 : 0] src_mean_y;
input wire [15 : 0] src_dark_ratio;
input wire [31 : 0] src_frame_count;
input wire [31 : 0] src_video_drop;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME dst_clk, ASSOCIATED_RESET dst_rst, FREQ_HZ 98305084, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_audio_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 dst_clk CLK" *)
input wire dst_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME dst_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 dst_rst RST" *)
input wire dst_rst;
output wire dst_strobe;
output wire [7 : 0] dst_mean_y;
output wire [15 : 0] dst_dark_ratio;
output wire [31 : 0] dst_frame_count;
output wire [31 : 0] dst_video_drop;

  av_status_cdc inst (
    .src_clk(src_clk),
    .src_rst(src_rst),
    .src_strobe(src_strobe),
    .src_mean_y(src_mean_y),
    .src_dark_ratio(src_dark_ratio),
    .src_frame_count(src_frame_count),
    .src_video_drop(src_video_drop),
    .dst_clk(dst_clk),
    .dst_rst(dst_rst),
    .dst_strobe(dst_strobe),
    .dst_mean_y(dst_mean_y),
    .dst_dark_ratio(dst_dark_ratio),
    .dst_frame_count(dst_frame_count),
    .dst_video_drop(dst_video_drop)
  );
endmodule
