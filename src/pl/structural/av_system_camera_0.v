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


// IP VLNV: xilinx.com:module_ref:camera_pipeline_top:1.0
// IP Revision: 1

(* X_CORE_INFO = "camera_pipeline_top,Vivado 2023.2" *)
(* CHECK_LICENSE_TYPE = "av_system_camera_0,camera_pipeline_top,{}" *)
(* CORE_GENERATION_INFO = "av_system_camera_0,camera_pipeline_top,{x_ipProduct=Vivado 2023.2,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=camera_pipeline_top,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,FRAME_WIDTH=1920,FRAME_HEIGHT=1080}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module av_system_camera_0 (
  cam_pclk,
  resetn,
  cam_vsync,
  cam_href,
  cam_d,
  camera_configured,
  camera_test_pattern,
  enhance_master_enable,
  gamma_wr_en,
  gamma_wr_addr,
  gamma_wr_data,
  gamma_commit,
  m_axis_video_tvalid,
  m_axis_video_tready,
  m_axis_video_tdata,
  m_axis_video_tkeep,
  m_axis_video_tuser,
  m_axis_video_tlast,
  m_axis_model_video_tvalid,
  m_axis_model_video_tready,
  m_axis_model_video_tdata,
  m_axis_model_video_tuser,
  m_axis_model_video_tlast,
  mean_y,
  dark_ratio_q15,
  frame_count,
  video_drop_count,
  model_video_drop_count,
  enhance_active,
  frame_start,
  enhance_led_n,
  enhancement_debug
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME cam_pclk, ASSOCIATED_RESET resetn, ASSOCIATED_BUSIF m_axis_video:m_axis_model_video, FREQ_HZ 84000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN av_system_cam_pclk, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 cam_pclk CLK" *)
input wire cam_pclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn RST" *)
input wire resetn;
input wire cam_vsync;
input wire cam_href;
input wire [7 : 0] cam_d;
input wire camera_configured;
input wire camera_test_pattern;
input wire enhance_master_enable;
input wire gamma_wr_en;
input wire [7 : 0] gamma_wr_addr;
input wire [7 : 0] gamma_wr_data;
input wire gamma_commit;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TVALID" *)
output wire m_axis_video_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TREADY" *)
input wire m_axis_video_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TDATA" *)
output wire [15 : 0] m_axis_video_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TKEEP" *)
output wire [1 : 0] m_axis_video_tkeep;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TUSER" *)
output wire m_axis_video_tuser;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_video, TDATA_NUM_BYTES 2, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 84000000, PHASE 0.0, CLK_DOMAIN av_system_cam_pclk, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TLAST" *)
output wire m_axis_video_tlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_video TVALID" *)
output wire m_axis_model_video_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_video TREADY" *)
input wire m_axis_model_video_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_video TDATA" *)
output wire [23 : 0] m_axis_model_video_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_video TUSER" *)
output wire m_axis_model_video_tuser;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_model_video, TDATA_NUM_BYTES 3, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 1, FREQ_HZ 84000000, PHASE 0.0, CLK_DOMAIN av_system_cam_pclk, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_video TLAST" *)
output wire m_axis_model_video_tlast;
output wire [7 : 0] mean_y;
output wire [15 : 0] dark_ratio_q15;
output wire [31 : 0] frame_count;
output wire [31 : 0] video_drop_count;
output wire [31 : 0] model_video_drop_count;
output wire enhance_active;
output wire frame_start;
output wire enhance_led_n;
output wire [15 : 0] enhancement_debug;

  camera_pipeline_top #(
    .FRAME_WIDTH(1920),
    .FRAME_HEIGHT(1080)
  ) inst (
    .cam_pclk(cam_pclk),
    .resetn(resetn),
    .cam_vsync(cam_vsync),
    .cam_href(cam_href),
    .cam_d(cam_d),
    .camera_configured(camera_configured),
    .camera_test_pattern(camera_test_pattern),
    .enhance_master_enable(enhance_master_enable),
    .gamma_wr_en(gamma_wr_en),
    .gamma_wr_addr(gamma_wr_addr),
    .gamma_wr_data(gamma_wr_data),
    .gamma_commit(gamma_commit),
    .m_axis_video_tvalid(m_axis_video_tvalid),
    .m_axis_video_tready(m_axis_video_tready),
    .m_axis_video_tdata(m_axis_video_tdata),
    .m_axis_video_tkeep(m_axis_video_tkeep),
    .m_axis_video_tuser(m_axis_video_tuser),
    .m_axis_video_tlast(m_axis_video_tlast),
    .m_axis_model_video_tvalid(m_axis_model_video_tvalid),
    .m_axis_model_video_tready(m_axis_model_video_tready),
    .m_axis_model_video_tdata(m_axis_model_video_tdata),
    .m_axis_model_video_tuser(m_axis_model_video_tuser),
    .m_axis_model_video_tlast(m_axis_model_video_tlast),
    .mean_y(mean_y),
    .dark_ratio_q15(dark_ratio_q15),
    .frame_count(frame_count),
    .video_drop_count(video_drop_count),
    .model_video_drop_count(model_video_drop_count),
    .enhance_active(enhance_active),
    .frame_start(frame_start),
    .enhance_led_n(enhance_led_n),
    .enhancement_debug(enhancement_debug)
  );
endmodule
