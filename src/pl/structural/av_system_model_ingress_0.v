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


// IP VLNV: xilinx.com:module_ref:model_ingress_stub:1.0
// IP Revision: 1

(* X_CORE_INFO = "model_ingress_stub,Vivado 2023.2" *)
(* CHECK_LICENSE_TYPE = "av_system_model_ingress_0,model_ingress_stub,{}" *)
(* CORE_GENERATION_INFO = "av_system_model_ingress_0,model_ingress_stub,{x_ipProduct=Vivado 2023.2,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=model_ingress_stub,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module av_system_model_ingress_0 (
  video_clk,
  video_resetn,
  s_axis_video_tvalid,
  s_axis_video_tready,
  s_axis_video_tdata,
  s_axis_video_tuser,
  s_axis_video_tlast,
  mel_clk,
  mel_resetn,
  s_axis_mel_tvalid,
  s_axis_mel_tready,
  s_axis_mel_tdata,
  s_axis_mel_tuser,
  s_axis_mel_tlast
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME video_clk, ASSOCIATED_RESET video_resetn, ASSOCIATED_BUSIF S_AXIS_VIDEO, FREQ_HZ 84000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN av_system_cam_pclk, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 video_clk CLK" *)
input wire video_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME video_resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 video_resetn RST" *)
input wire video_resetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TVALID" *)
input wire s_axis_video_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TREADY" *)
output wire s_axis_video_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TDATA" *)
input wire [23 : 0] s_axis_video_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TUSER" *)
input wire s_axis_video_tuser;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axis_video, TDATA_NUM_BYTES 3, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 1, FREQ_HZ 84000000, PHASE 0.0, CLK_DOMAIN av_system_cam_pclk, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TLAST" *)
input wire s_axis_video_tlast;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mel_clk, ASSOCIATED_RESET mel_resetn, ASSOCIATED_BUSIF S_AXIS_MEL, FREQ_HZ 98305084, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_audio_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 mel_clk CLK" *)
input wire mel_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME mel_resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 mel_resetn RST" *)
input wire mel_resetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_mel TVALID" *)
input wire s_axis_mel_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_mel TREADY" *)
output wire s_axis_mel_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_mel TDATA" *)
input wire [15 : 0] s_axis_mel_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_mel TUSER" *)
input wire s_axis_mel_tuser;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axis_mel, TDATA_NUM_BYTES 2, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 1, FREQ_HZ 98305084, PHASE 0.0, CLK_DOMAIN /clk_audio_clk_out1, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_mel TLAST" *)
input wire s_axis_mel_tlast;

  model_ingress_stub inst (
    .video_clk(video_clk),
    .video_resetn(video_resetn),
    .s_axis_video_tvalid(s_axis_video_tvalid),
    .s_axis_video_tready(s_axis_video_tready),
    .s_axis_video_tdata(s_axis_video_tdata),
    .s_axis_video_tuser(s_axis_video_tuser),
    .s_axis_video_tlast(s_axis_video_tlast),
    .mel_clk(mel_clk),
    .mel_resetn(mel_resetn),
    .s_axis_mel_tvalid(s_axis_mel_tvalid),
    .s_axis_mel_tready(s_axis_mel_tready),
    .s_axis_mel_tdata(s_axis_mel_tdata),
    .s_axis_mel_tuser(s_axis_mel_tuser),
    .s_axis_mel_tlast(s_axis_mel_tlast)
  );
endmodule
