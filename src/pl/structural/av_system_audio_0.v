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


// IP VLNV: xilinx.com:module_ref:audio_control_top:1.0
// IP Revision: 1

(* X_CORE_INFO = "audio_control_top,Vivado 2023.2" *)
(* CHECK_LICENSE_TYPE = "av_system_audio_0,audio_control_top,{}" *)
(* CORE_GENERATION_INFO = "av_system_audio_0,audio_control_top,{x_ipProduct=Vivado 2023.2,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=audio_control_top,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module av_system_audio_0 (
  clk_98m304,
  resetn,
  board_keys_n,
  mic_sd_0,
  mic_sd_1,
  mic_sd_2,
  mic_sd_3,
  mic_sck,
  mic_ws,
  servo_pan,
  servo_tilt,
  stat_mean_y,
  stat_dark_ratio_q15,
  stat_frame_count,
  stat_video_drop_count,
  stat_frame_strobe,
  s_axi_awaddr,
  s_axi_awprot,
  s_axi_awvalid,
  s_axi_awready,
  s_axi_wdata,
  s_axi_wstrb,
  s_axi_wvalid,
  s_axi_wready,
  s_axi_bresp,
  s_axi_bvalid,
  s_axi_bready,
  s_axi_araddr,
  s_axi_arprot,
  s_axi_arvalid,
  s_axi_arready,
  s_axi_rdata,
  s_axi_rresp,
  s_axi_rvalid,
  s_axi_rready,
  m_axis_pcm_tvalid,
  m_axis_pcm_tready,
  m_axis_pcm_tdata,
  m_axis_pcm_tkeep,
  m_axis_pcm_tlast,
  m_axis_model_mel_tvalid,
  m_axis_model_mel_tready,
  m_axis_model_mel_tdata,
  m_axis_model_mel_tuser,
  m_axis_model_mel_tlast,
  m_axis_model_mel_audio_seq,
  gamma_event_valid,
  gamma_event_data,
  enhance_master_enable,
  audio_overflow_count,
  model_mel_drop_count
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk_98m304, ASSOCIATED_RESET resetn, ASSOCIATED_BUSIF S_AXI:M_AXIS_PCM:M_AXIS_MODEL_MEL, FREQ_HZ 98305084, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_audio_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk_98m304 CLK" *)
input wire clk_98m304;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn RST" *)
input wire resetn;
input wire [3 : 0] board_keys_n;
input wire mic_sd_0;
input wire mic_sd_1;
input wire mic_sd_2;
input wire mic_sd_3;
output wire mic_sck;
output wire mic_ws;
output wire servo_pan;
output wire servo_tilt;
input wire [7 : 0] stat_mean_y;
input wire [15 : 0] stat_dark_ratio_q15;
input wire [31 : 0] stat_frame_count;
input wire [31 : 0] stat_video_drop_count;
input wire stat_frame_strobe;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
input wire [7 : 0] s_axi_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
input wire [2 : 0] s_axi_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
input wire s_axi_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
output wire s_axi_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
input wire [31 : 0] s_axi_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
input wire [3 : 0] s_axi_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
input wire s_axi_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
output wire s_axi_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
output wire [1 : 0] s_axi_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
output wire s_axi_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
input wire s_axi_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
input wire [7 : 0] s_axi_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
input wire [2 : 0] s_axi_arprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
input wire s_axi_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
output wire s_axi_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
output wire [31 : 0] s_axi_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
output wire [1 : 0] s_axi_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
output wire s_axi_rvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 8, FREQ_HZ 98305084, ID_WIDTH 0, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.0, CLK_DOMAIN /clk_audio_clk_out1, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, \
RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
input wire s_axi_rready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_pcm TVALID" *)
output wire m_axis_pcm_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_pcm TREADY" *)
input wire m_axis_pcm_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_pcm TDATA" *)
output wire [127 : 0] m_axis_pcm_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_pcm TKEEP" *)
output wire [15 : 0] m_axis_pcm_tkeep;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_pcm, TDATA_NUM_BYTES 16, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 98305084, PHASE 0.0, CLK_DOMAIN /clk_audio_clk_out1, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_pcm TLAST" *)
output wire m_axis_pcm_tlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_mel TVALID" *)
output wire m_axis_model_mel_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_mel TREADY" *)
input wire m_axis_model_mel_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_mel TDATA" *)
output wire [15 : 0] m_axis_model_mel_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_mel TUSER" *)
output wire m_axis_model_mel_tuser;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_model_mel, TDATA_NUM_BYTES 2, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 1, FREQ_HZ 98305084, PHASE 0.0, CLK_DOMAIN /clk_audio_clk_out1, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_model_mel TLAST" *)
output wire m_axis_model_mel_tlast;
output wire [31 : 0] m_axis_model_mel_audio_seq;
output wire gamma_event_valid;
output wire [16 : 0] gamma_event_data;
output wire enhance_master_enable;
output wire [31 : 0] audio_overflow_count;
output wire [31 : 0] model_mel_drop_count;

  audio_control_top inst (
    .clk_98m304(clk_98m304),
    .resetn(resetn),
    .board_keys_n(board_keys_n),
    .mic_sd_0(mic_sd_0),
    .mic_sd_1(mic_sd_1),
    .mic_sd_2(mic_sd_2),
    .mic_sd_3(mic_sd_3),
    .mic_sck(mic_sck),
    .mic_ws(mic_ws),
    .servo_pan(servo_pan),
    .servo_tilt(servo_tilt),
    .stat_mean_y(stat_mean_y),
    .stat_dark_ratio_q15(stat_dark_ratio_q15),
    .stat_frame_count(stat_frame_count),
    .stat_video_drop_count(stat_video_drop_count),
    .stat_frame_strobe(stat_frame_strobe),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .m_axis_pcm_tvalid(m_axis_pcm_tvalid),
    .m_axis_pcm_tready(m_axis_pcm_tready),
    .m_axis_pcm_tdata(m_axis_pcm_tdata),
    .m_axis_pcm_tkeep(m_axis_pcm_tkeep),
    .m_axis_pcm_tlast(m_axis_pcm_tlast),
    .m_axis_model_mel_tvalid(m_axis_model_mel_tvalid),
    .m_axis_model_mel_tready(m_axis_model_mel_tready),
    .m_axis_model_mel_tdata(m_axis_model_mel_tdata),
    .m_axis_model_mel_tuser(m_axis_model_mel_tuser),
    .m_axis_model_mel_tlast(m_axis_model_mel_tlast),
    .m_axis_model_mel_audio_seq(m_axis_model_mel_audio_seq),
    .gamma_event_valid(gamma_event_valid),
    .gamma_event_data(gamma_event_data),
    .enhance_master_enable(enhance_master_enable),
    .audio_overflow_count(audio_overflow_count),
    .model_mel_drop_count(model_mel_drop_count)
  );
endmodule
