//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
//Date        : Tue Oct 27 11:21:16 2026
//Command     : generate_target av_system.bd
//Design      : av_system
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "av_system,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=av_system,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=78,numReposBlks=53,numNonXlnxBlks=1,numHierBlks=25,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=14,numPkgbdBlks=0,bdsource=USER,synth_mode=None}" *) (* HW_HANDOFF = "av_system.hwdef" *) 
module av_system
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    board_keys_n,
    cam_d,
    cam_href,
    cam_pclk,
    cam_pwdn,
    cam_reset_n,
    cam_scl,
    cam_sda,
    cam_vsync,
    enhance_led_n,
    hdmi_clk_n,
    hdmi_clk_p,
    hdmi_data_n,
    hdmi_data_p,
    hdmi_hpd,
    hdmi_out_en,
    mic_sck,
    mic_sd_0,
    mic_sd_1,
    mic_sd_2,
    mic_sd_3,
    mic_ws,
    servo_pan,
    servo_tilt);
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR ADDR" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DDR, AXI_ARBITRATION_SCHEME TDM, BURST_LENGTH 8, CAN_DEBUG false, CAS_LATENCY 11, CAS_WRITE_LATENCY 11, CS_ENABLED true, DATA_MASK_ENABLED true, DATA_WIDTH 8, MEMORY_TYPE COMPONENTS, MEM_ADDR_MAP ROW_COLUMN_BANK, SLOT Single, TIMEPERIOD_PS 1250" *) inout [14:0]DDR_addr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR BA" *) inout [2:0]DDR_ba;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CAS_N" *) inout DDR_cas_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CK_N" *) inout DDR_ck_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CK_P" *) inout DDR_ck_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CKE" *) inout DDR_cke;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CS_N" *) inout DDR_cs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DM" *) inout [3:0]DDR_dm;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQ" *) inout [31:0]DDR_dq;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQS_N" *) inout [3:0]DDR_dqs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQS_P" *) inout [3:0]DDR_dqs_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR ODT" *) inout DDR_odt;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR RAS_N" *) inout DDR_ras_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR RESET_N" *) inout DDR_reset_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR WE_N" *) inout DDR_we_n;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO DDR_VRN" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIXED_IO, CAN_DEBUG false" *) inout FIXED_IO_ddr_vrn;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO DDR_VRP" *) inout FIXED_IO_ddr_vrp;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO MIO" *) inout [53:0]FIXED_IO_mio;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_CLK" *) inout FIXED_IO_ps_clk;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_PORB" *) inout FIXED_IO_ps_porb;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_SRSTB" *) inout FIXED_IO_ps_srstb;
  input [3:0]board_keys_n;
  input [7:0]cam_d;
  input cam_href;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CAM_PCLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CAM_PCLK, CLK_DOMAIN av_system_cam_pclk, FREQ_HZ 84000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input cam_pclk;
  output cam_pwdn;
  output cam_reset_n;
  inout cam_scl;
  inout cam_sda;
  input cam_vsync;
  output enhance_led_n;
  output hdmi_clk_n;
  output hdmi_clk_p;
  output [2:0]hdmi_data_n;
  output [2:0]hdmi_data_p;
  input hdmi_hpd;
  output hdmi_out_en;
  output mic_sck;
  input mic_sd_0;
  input mic_sd_1;
  input mic_sd_2;
  input mic_sd_3;
  output mic_ws;
  output servo_pan;
  output servo_tilt;

  wire Net;
  wire Net1;
  wire audio_enhance_master_enable;
  wire [16:0]audio_gamma_event_data;
  wire audio_gamma_event_valid;
  wire [15:0]audio_m_axis_model_mel_TDATA;
  wire audio_m_axis_model_mel_TLAST;
  wire audio_m_axis_model_mel_TREADY;
  wire audio_m_axis_model_mel_TUSER;
  wire audio_m_axis_model_mel_TVALID;
  wire [127:0]audio_m_axis_pcm_TDATA;
  wire [15:0]audio_m_axis_pcm_TKEEP;
  wire audio_m_axis_pcm_TLAST;
  wire audio_m_axis_pcm_TREADY;
  wire audio_m_axis_pcm_TVALID;
  wire audio_mic_sck;
  wire audio_mic_ws;
  wire audio_servo_pan;
  wire audio_servo_tilt;
  wire [3:0]board_keys_n;
  wire [7:0]cam_d_1;
  wire [5:0]cam_gpio_gpio_io_o;
  wire [5:0]cam_gpio_gpio_io_t;
  wire cam_href_1;
  wire cam_io_cam_pwdn;
  wire cam_io_cam_reset_n;
  wire cam_io_camera_configured;
  wire cam_io_camera_test_pattern;
  wire [5:0]cam_io_gpio_i;
  wire cam_pclk_1;
  wire cam_vsync_1;
  wire [15:0]camera_dark_ratio_q15;
  wire camera_enhance_led_n;
  wire [15:0]camera_enhancement_debug;
  wire [31:0]camera_frame_count;
  wire camera_frame_start;
  wire [23:0]camera_m_axis_model_video_TDATA;
  wire camera_m_axis_model_video_TLAST;
  wire camera_m_axis_model_video_TREADY;
  wire camera_m_axis_model_video_TUSER;
  wire camera_m_axis_model_video_TVALID;
  wire [15:0]camera_m_axis_video_TDATA;
  wire [1:0]camera_m_axis_video_TKEEP;
  wire camera_m_axis_video_TLAST;
  wire camera_m_axis_video_TREADY;
  wire camera_m_axis_video_TUSER;
  wire camera_m_axis_video_TVALID;
  wire [7:0]camera_mean_y;
  wire [31:0]camera_probe_probe_data;
  wire [31:0]camera_video_drop_count;
  wire clk_audio_clk_out1;
  wire clk_audio_locked;
  wire clk_hdmi_clk_out1;
  wire clk_hdmi_clk_out2;
  wire clk_hdmi_clk_out3;
  wire clk_hdmi_locked;
  wire [0:0]const_one_dout;
  wire [0:0]const_zero_dout;
  wire [7:0]ctrl_cdc_M_AXI_ARADDR;
  wire [2:0]ctrl_cdc_M_AXI_ARPROT;
  wire ctrl_cdc_M_AXI_ARREADY;
  wire ctrl_cdc_M_AXI_ARVALID;
  wire [7:0]ctrl_cdc_M_AXI_AWADDR;
  wire [2:0]ctrl_cdc_M_AXI_AWPROT;
  wire ctrl_cdc_M_AXI_AWREADY;
  wire ctrl_cdc_M_AXI_AWVALID;
  wire ctrl_cdc_M_AXI_BREADY;
  wire [1:0]ctrl_cdc_M_AXI_BRESP;
  wire ctrl_cdc_M_AXI_BVALID;
  wire [31:0]ctrl_cdc_M_AXI_RDATA;
  wire ctrl_cdc_M_AXI_RREADY;
  wire [1:0]ctrl_cdc_M_AXI_RRESP;
  wire ctrl_cdc_M_AXI_RVALID;
  wire [31:0]ctrl_cdc_M_AXI_WDATA;
  wire ctrl_cdc_M_AXI_WREADY;
  wire [3:0]ctrl_cdc_M_AXI_WSTRB;
  wire ctrl_cdc_M_AXI_WVALID;
  wire [31:0]ctrl_ic_M00_AXI_ARADDR;
  wire ctrl_ic_M00_AXI_ARREADY;
  wire [0:0]ctrl_ic_M00_AXI_ARVALID;
  wire [31:0]ctrl_ic_M00_AXI_AWADDR;
  wire ctrl_ic_M00_AXI_AWREADY;
  wire [0:0]ctrl_ic_M00_AXI_AWVALID;
  wire [0:0]ctrl_ic_M00_AXI_BREADY;
  wire [1:0]ctrl_ic_M00_AXI_BRESP;
  wire ctrl_ic_M00_AXI_BVALID;
  wire [31:0]ctrl_ic_M00_AXI_RDATA;
  wire [0:0]ctrl_ic_M00_AXI_RREADY;
  wire [1:0]ctrl_ic_M00_AXI_RRESP;
  wire ctrl_ic_M00_AXI_RVALID;
  wire [31:0]ctrl_ic_M00_AXI_WDATA;
  wire ctrl_ic_M00_AXI_WREADY;
  wire [0:0]ctrl_ic_M00_AXI_WVALID;
  wire [31:0]ctrl_ic_M01_AXI_ARADDR;
  wire ctrl_ic_M01_AXI_ARREADY;
  wire [0:0]ctrl_ic_M01_AXI_ARVALID;
  wire [31:0]ctrl_ic_M01_AXI_AWADDR;
  wire ctrl_ic_M01_AXI_AWREADY;
  wire [0:0]ctrl_ic_M01_AXI_AWVALID;
  wire [0:0]ctrl_ic_M01_AXI_BREADY;
  wire [1:0]ctrl_ic_M01_AXI_BRESP;
  wire ctrl_ic_M01_AXI_BVALID;
  wire [31:0]ctrl_ic_M01_AXI_RDATA;
  wire [0:0]ctrl_ic_M01_AXI_RREADY;
  wire [1:0]ctrl_ic_M01_AXI_RRESP;
  wire ctrl_ic_M01_AXI_RVALID;
  wire [31:0]ctrl_ic_M01_AXI_WDATA;
  wire ctrl_ic_M01_AXI_WREADY;
  wire [0:0]ctrl_ic_M01_AXI_WVALID;
  wire [31:0]ctrl_ic_M02_AXI_ARADDR;
  wire ctrl_ic_M02_AXI_ARREADY;
  wire ctrl_ic_M02_AXI_ARVALID;
  wire [31:0]ctrl_ic_M02_AXI_AWADDR;
  wire ctrl_ic_M02_AXI_AWREADY;
  wire ctrl_ic_M02_AXI_AWVALID;
  wire ctrl_ic_M02_AXI_BREADY;
  wire [1:0]ctrl_ic_M02_AXI_BRESP;
  wire ctrl_ic_M02_AXI_BVALID;
  wire [31:0]ctrl_ic_M02_AXI_RDATA;
  wire ctrl_ic_M02_AXI_RREADY;
  wire [1:0]ctrl_ic_M02_AXI_RRESP;
  wire ctrl_ic_M02_AXI_RVALID;
  wire [31:0]ctrl_ic_M02_AXI_WDATA;
  wire ctrl_ic_M02_AXI_WREADY;
  wire [3:0]ctrl_ic_M02_AXI_WSTRB;
  wire ctrl_ic_M02_AXI_WVALID;
  wire [31:0]ctrl_ic_M03_AXI_ARADDR;
  wire [2:0]ctrl_ic_M03_AXI_ARPROT;
  wire ctrl_ic_M03_AXI_ARREADY;
  wire ctrl_ic_M03_AXI_ARVALID;
  wire [31:0]ctrl_ic_M03_AXI_AWADDR;
  wire [2:0]ctrl_ic_M03_AXI_AWPROT;
  wire ctrl_ic_M03_AXI_AWREADY;
  wire ctrl_ic_M03_AXI_AWVALID;
  wire ctrl_ic_M03_AXI_BREADY;
  wire [1:0]ctrl_ic_M03_AXI_BRESP;
  wire ctrl_ic_M03_AXI_BVALID;
  wire [31:0]ctrl_ic_M03_AXI_RDATA;
  wire ctrl_ic_M03_AXI_RREADY;
  wire [1:0]ctrl_ic_M03_AXI_RRESP;
  wire ctrl_ic_M03_AXI_RVALID;
  wire [31:0]ctrl_ic_M03_AXI_WDATA;
  wire ctrl_ic_M03_AXI_WREADY;
  wire [3:0]ctrl_ic_M03_AXI_WSTRB;
  wire ctrl_ic_M03_AXI_WVALID;
  wire [31:0]ctrl_ic_M04_AXI_ARADDR;
  wire ctrl_ic_M04_AXI_ARREADY;
  wire ctrl_ic_M04_AXI_ARVALID;
  wire [31:0]ctrl_ic_M04_AXI_AWADDR;
  wire ctrl_ic_M04_AXI_AWREADY;
  wire ctrl_ic_M04_AXI_AWVALID;
  wire ctrl_ic_M04_AXI_BREADY;
  wire [1:0]ctrl_ic_M04_AXI_BRESP;
  wire ctrl_ic_M04_AXI_BVALID;
  wire [31:0]ctrl_ic_M04_AXI_RDATA;
  wire ctrl_ic_M04_AXI_RREADY;
  wire [1:0]ctrl_ic_M04_AXI_RRESP;
  wire ctrl_ic_M04_AXI_RVALID;
  wire [31:0]ctrl_ic_M04_AXI_WDATA;
  wire ctrl_ic_M04_AXI_WREADY;
  wire ctrl_ic_M04_AXI_WVALID;
  wire [31:0]ctrl_ic_M05_AXI_ARADDR;
  wire ctrl_ic_M05_AXI_ARREADY;
  wire ctrl_ic_M05_AXI_ARVALID;
  wire [31:0]ctrl_ic_M05_AXI_AWADDR;
  wire ctrl_ic_M05_AXI_AWREADY;
  wire ctrl_ic_M05_AXI_AWVALID;
  wire ctrl_ic_M05_AXI_BREADY;
  wire [1:0]ctrl_ic_M05_AXI_BRESP;
  wire ctrl_ic_M05_AXI_BVALID;
  wire [31:0]ctrl_ic_M05_AXI_RDATA;
  wire ctrl_ic_M05_AXI_RREADY;
  wire [1:0]ctrl_ic_M05_AXI_RRESP;
  wire ctrl_ic_M05_AXI_RVALID;
  wire [31:0]ctrl_ic_M05_AXI_WDATA;
  wire ctrl_ic_M05_AXI_WREADY;
  wire [3:0]ctrl_ic_M05_AXI_WSTRB;
  wire ctrl_ic_M05_AXI_WVALID;
  wire [31:0]ctrl_ic_M06_AXI_ARADDR;
  wire ctrl_ic_M06_AXI_ARREADY;
  wire ctrl_ic_M06_AXI_ARVALID;
  wire [31:0]ctrl_ic_M06_AXI_AWADDR;
  wire ctrl_ic_M06_AXI_AWREADY;
  wire ctrl_ic_M06_AXI_AWVALID;
  wire ctrl_ic_M06_AXI_BREADY;
  wire [1:0]ctrl_ic_M06_AXI_BRESP;
  wire ctrl_ic_M06_AXI_BVALID;
  wire [31:0]ctrl_ic_M06_AXI_RDATA;
  wire ctrl_ic_M06_AXI_RREADY;
  wire [1:0]ctrl_ic_M06_AXI_RRESP;
  wire ctrl_ic_M06_AXI_RVALID;
  wire [31:0]ctrl_ic_M06_AXI_WDATA;
  wire ctrl_ic_M06_AXI_WREADY;
  wire ctrl_ic_M06_AXI_WVALID;
  wire [31:0]ctrl_ic_M07_AXI_ARADDR;
  wire ctrl_ic_M07_AXI_ARREADY;
  wire ctrl_ic_M07_AXI_ARVALID;
  wire [31:0]ctrl_ic_M07_AXI_AWADDR;
  wire ctrl_ic_M07_AXI_AWREADY;
  wire ctrl_ic_M07_AXI_AWVALID;
  wire ctrl_ic_M07_AXI_BREADY;
  wire [1:0]ctrl_ic_M07_AXI_BRESP;
  wire ctrl_ic_M07_AXI_BVALID;
  wire [31:0]ctrl_ic_M07_AXI_RDATA;
  wire ctrl_ic_M07_AXI_RREADY;
  wire [1:0]ctrl_ic_M07_AXI_RRESP;
  wire ctrl_ic_M07_AXI_RVALID;
  wire [31:0]ctrl_ic_M07_AXI_WDATA;
  wire ctrl_ic_M07_AXI_WREADY;
  wire ctrl_ic_M07_AXI_WVALID;
  wire [31:0]ctrl_ic_M08_AXI_ARADDR;
  wire ctrl_ic_M08_AXI_ARREADY;
  wire ctrl_ic_M08_AXI_ARVALID;
  wire [31:0]ctrl_ic_M08_AXI_AWADDR;
  wire ctrl_ic_M08_AXI_AWREADY;
  wire ctrl_ic_M08_AXI_AWVALID;
  wire ctrl_ic_M08_AXI_BREADY;
  wire [1:0]ctrl_ic_M08_AXI_BRESP;
  wire ctrl_ic_M08_AXI_BVALID;
  wire [31:0]ctrl_ic_M08_AXI_RDATA;
  wire ctrl_ic_M08_AXI_RREADY;
  wire [1:0]ctrl_ic_M08_AXI_RRESP;
  wire ctrl_ic_M08_AXI_RVALID;
  wire [31:0]ctrl_ic_M08_AXI_WDATA;
  wire ctrl_ic_M08_AXI_WREADY;
  wire [3:0]ctrl_ic_M08_AXI_WSTRB;
  wire ctrl_ic_M08_AXI_WVALID;
  wire [31:0]dma_M_AXI_S2MM_AWADDR;
  wire [1:0]dma_M_AXI_S2MM_AWBURST;
  wire [3:0]dma_M_AXI_S2MM_AWCACHE;
  wire [7:0]dma_M_AXI_S2MM_AWLEN;
  wire [2:0]dma_M_AXI_S2MM_AWPROT;
  wire dma_M_AXI_S2MM_AWREADY;
  wire [2:0]dma_M_AXI_S2MM_AWSIZE;
  wire dma_M_AXI_S2MM_AWVALID;
  wire dma_M_AXI_S2MM_BREADY;
  wire [1:0]dma_M_AXI_S2MM_BRESP;
  wire dma_M_AXI_S2MM_BVALID;
  wire [127:0]dma_M_AXI_S2MM_WDATA;
  wire dma_M_AXI_S2MM_WLAST;
  wire dma_M_AXI_S2MM_WREADY;
  wire [15:0]dma_M_AXI_S2MM_WSTRB;
  wire dma_M_AXI_S2MM_WVALID;
  wire [31:0]dma_proto_M_AXI_AWADDR;
  wire [1:0]dma_proto_M_AXI_AWBURST;
  wire [3:0]dma_proto_M_AXI_AWCACHE;
  wire [3:0]dma_proto_M_AXI_AWLEN;
  wire [1:0]dma_proto_M_AXI_AWLOCK;
  wire [2:0]dma_proto_M_AXI_AWPROT;
  wire [3:0]dma_proto_M_AXI_AWQOS;
  wire dma_proto_M_AXI_AWREADY;
  wire [2:0]dma_proto_M_AXI_AWSIZE;
  wire dma_proto_M_AXI_AWVALID;
  wire dma_proto_M_AXI_BREADY;
  wire [1:0]dma_proto_M_AXI_BRESP;
  wire dma_proto_M_AXI_BVALID;
  wire [63:0]dma_proto_M_AXI_WDATA;
  wire dma_proto_M_AXI_WLAST;
  wire dma_proto_M_AXI_WREADY;
  wire [7:0]dma_proto_M_AXI_WSTRB;
  wire dma_proto_M_AXI_WVALID;
  wire dma_s2mm_introut;
  wire [31:0]dma_width_M_AXI_AWADDR;
  wire [1:0]dma_width_M_AXI_AWBURST;
  wire [3:0]dma_width_M_AXI_AWCACHE;
  wire [7:0]dma_width_M_AXI_AWLEN;
  wire [0:0]dma_width_M_AXI_AWLOCK;
  wire [2:0]dma_width_M_AXI_AWPROT;
  wire [3:0]dma_width_M_AXI_AWQOS;
  wire dma_width_M_AXI_AWREADY;
  wire [3:0]dma_width_M_AXI_AWREGION;
  wire [2:0]dma_width_M_AXI_AWSIZE;
  wire dma_width_M_AXI_AWVALID;
  wire dma_width_M_AXI_BREADY;
  wire [1:0]dma_width_M_AXI_BRESP;
  wire dma_width_M_AXI_BVALID;
  wire [63:0]dma_width_M_AXI_WDATA;
  wire dma_width_M_AXI_WLAST;
  wire dma_width_M_AXI_WREADY;
  wire [7:0]dma_width_M_AXI_WSTRB;
  wire dma_width_M_AXI_WVALID;
  wire gamma_cdc_gamma_commit;
  wire [7:0]gamma_cdc_gamma_wr_addr;
  wire [7:0]gamma_cdc_gamma_wr_data;
  wire gamma_cdc_gamma_wr_en;
  wire hdmi_encoder_TMDS_Clk_n;
  wire hdmi_encoder_TMDS_Clk_p;
  wire [2:0]hdmi_encoder_TMDS_Data_n;
  wire [2:0]hdmi_encoder_TMDS_Data_p;
  wire hdmi_gpio_gpio_io_o;
  wire hdmi_hpd_1;
  wire [31:0]hdmi_memory_M00_AXI_ARADDR;
  wire [1:0]hdmi_memory_M00_AXI_ARBURST;
  wire [3:0]hdmi_memory_M00_AXI_ARCACHE;
  wire [0:0]hdmi_memory_M00_AXI_ARID;
  wire [3:0]hdmi_memory_M00_AXI_ARLEN;
  wire [1:0]hdmi_memory_M00_AXI_ARLOCK;
  wire [2:0]hdmi_memory_M00_AXI_ARPROT;
  wire [3:0]hdmi_memory_M00_AXI_ARQOS;
  wire hdmi_memory_M00_AXI_ARREADY;
  wire [2:0]hdmi_memory_M00_AXI_ARSIZE;
  wire hdmi_memory_M00_AXI_ARVALID;
  wire [31:0]hdmi_memory_M00_AXI_AWADDR;
  wire [1:0]hdmi_memory_M00_AXI_AWBURST;
  wire [3:0]hdmi_memory_M00_AXI_AWCACHE;
  wire [0:0]hdmi_memory_M00_AXI_AWID;
  wire [3:0]hdmi_memory_M00_AXI_AWLEN;
  wire [1:0]hdmi_memory_M00_AXI_AWLOCK;
  wire [2:0]hdmi_memory_M00_AXI_AWPROT;
  wire [3:0]hdmi_memory_M00_AXI_AWQOS;
  wire hdmi_memory_M00_AXI_AWREADY;
  wire [2:0]hdmi_memory_M00_AXI_AWSIZE;
  wire hdmi_memory_M00_AXI_AWVALID;
  wire [5:0]hdmi_memory_M00_AXI_BID;
  wire hdmi_memory_M00_AXI_BREADY;
  wire [1:0]hdmi_memory_M00_AXI_BRESP;
  wire hdmi_memory_M00_AXI_BVALID;
  wire [63:0]hdmi_memory_M00_AXI_RDATA;
  wire [5:0]hdmi_memory_M00_AXI_RID;
  wire hdmi_memory_M00_AXI_RLAST;
  wire hdmi_memory_M00_AXI_RREADY;
  wire [1:0]hdmi_memory_M00_AXI_RRESP;
  wire hdmi_memory_M00_AXI_RVALID;
  wire [63:0]hdmi_memory_M00_AXI_WDATA;
  wire [0:0]hdmi_memory_M00_AXI_WID;
  wire hdmi_memory_M00_AXI_WLAST;
  wire hdmi_memory_M00_AXI_WREADY;
  wire [7:0]hdmi_memory_M00_AXI_WSTRB;
  wire hdmi_memory_M00_AXI_WVALID;
  wire [23:0]hdmi_osd_out_data;
  wire hdmi_osd_out_de;
  wire hdmi_osd_out_hsync;
  wire hdmi_osd_out_vsync;
  wire hdmi_raster_frame_sync;
  wire hdmi_raster_hdmi_out_en;
  wire [31:0]hdmi_raster_status;
  wire hdmi_raster_status_strobe;
  wire hdmi_raster_timing_de;
  wire hdmi_raster_timing_hblank;
  wire hdmi_raster_timing_hsync;
  wire hdmi_raster_timing_vblank;
  wire hdmi_raster_timing_vsync;
  wire [23:0]hdmi_raster_video_data;
  wire hdmi_raster_video_de;
  wire hdmi_raster_video_hsync;
  wire hdmi_raster_video_vsync;
  wire [23:0]hdmi_rgb_m_axis_TDATA;
  wire hdmi_rgb_m_axis_TLAST;
  wire hdmi_rgb_m_axis_TREADY;
  wire hdmi_rgb_m_axis_TUSER;
  wire hdmi_rgb_m_axis_TVALID;
  wire [31:0]hdmi_status_dst_data;
  wire hdmi_video_out_locked;
  wire hdmi_video_out_overflow;
  wire hdmi_video_out_underflow;
  wire hdmi_video_out_vid_active_video;
  wire [23:0]hdmi_video_out_vid_data;
  wire hdmi_video_out_vid_hsync;
  wire hdmi_video_out_vid_vsync;
  wire [63:0]infer_dma_M_AXIS_MM2S_TDATA;
  wire [7:0]infer_dma_M_AXIS_MM2S_TKEEP;
  wire infer_dma_M_AXIS_MM2S_TLAST;
  wire infer_dma_M_AXIS_MM2S_TREADY;
  wire infer_dma_M_AXIS_MM2S_TVALID;
  wire [31:0]infer_dma_M_AXI_MM2S_ARADDR;
  wire [1:0]infer_dma_M_AXI_MM2S_ARBURST;
  wire [3:0]infer_dma_M_AXI_MM2S_ARCACHE;
  wire [7:0]infer_dma_M_AXI_MM2S_ARLEN;
  wire [2:0]infer_dma_M_AXI_MM2S_ARPROT;
  wire [0:0]infer_dma_M_AXI_MM2S_ARREADY;
  wire [2:0]infer_dma_M_AXI_MM2S_ARSIZE;
  wire infer_dma_M_AXI_MM2S_ARVALID;
  wire [63:0]infer_dma_M_AXI_MM2S_RDATA;
  wire [0:0]infer_dma_M_AXI_MM2S_RLAST;
  wire infer_dma_M_AXI_MM2S_RREADY;
  wire [1:0]infer_dma_M_AXI_MM2S_RRESP;
  wire [0:0]infer_dma_M_AXI_MM2S_RVALID;
  wire [31:0]infer_dma_M_AXI_S2MM_AWADDR;
  wire [1:0]infer_dma_M_AXI_S2MM_AWBURST;
  wire [3:0]infer_dma_M_AXI_S2MM_AWCACHE;
  wire [7:0]infer_dma_M_AXI_S2MM_AWLEN;
  wire [2:0]infer_dma_M_AXI_S2MM_AWPROT;
  wire [0:0]infer_dma_M_AXI_S2MM_AWREADY;
  wire [2:0]infer_dma_M_AXI_S2MM_AWSIZE;
  wire infer_dma_M_AXI_S2MM_AWVALID;
  wire infer_dma_M_AXI_S2MM_BREADY;
  wire [1:0]infer_dma_M_AXI_S2MM_BRESP;
  wire [0:0]infer_dma_M_AXI_S2MM_BVALID;
  wire [63:0]infer_dma_M_AXI_S2MM_WDATA;
  wire infer_dma_M_AXI_S2MM_WLAST;
  wire [0:0]infer_dma_M_AXI_S2MM_WREADY;
  wire [7:0]infer_dma_M_AXI_S2MM_WSTRB;
  wire infer_dma_M_AXI_S2MM_WVALID;
  wire [63:0]inference_engine_out_r_TDATA;
  wire inference_engine_out_r_TLAST;
  wire inference_engine_out_r_TREADY;
  wire inference_engine_out_r_TVALID;
  wire [31:0]inference_memory_M00_AXI_ARADDR;
  wire [1:0]inference_memory_M00_AXI_ARBURST;
  wire [3:0]inference_memory_M00_AXI_ARCACHE;
  wire [0:0]inference_memory_M00_AXI_ARID;
  wire [3:0]inference_memory_M00_AXI_ARLEN;
  wire [1:0]inference_memory_M00_AXI_ARLOCK;
  wire [2:0]inference_memory_M00_AXI_ARPROT;
  wire [3:0]inference_memory_M00_AXI_ARQOS;
  wire inference_memory_M00_AXI_ARREADY;
  wire [2:0]inference_memory_M00_AXI_ARSIZE;
  wire inference_memory_M00_AXI_ARVALID;
  wire [31:0]inference_memory_M00_AXI_AWADDR;
  wire [1:0]inference_memory_M00_AXI_AWBURST;
  wire [3:0]inference_memory_M00_AXI_AWCACHE;
  wire [0:0]inference_memory_M00_AXI_AWID;
  wire [3:0]inference_memory_M00_AXI_AWLEN;
  wire [1:0]inference_memory_M00_AXI_AWLOCK;
  wire [2:0]inference_memory_M00_AXI_AWPROT;
  wire [3:0]inference_memory_M00_AXI_AWQOS;
  wire inference_memory_M00_AXI_AWREADY;
  wire [2:0]inference_memory_M00_AXI_AWSIZE;
  wire inference_memory_M00_AXI_AWVALID;
  wire [5:0]inference_memory_M00_AXI_BID;
  wire inference_memory_M00_AXI_BREADY;
  wire [1:0]inference_memory_M00_AXI_BRESP;
  wire inference_memory_M00_AXI_BVALID;
  wire [63:0]inference_memory_M00_AXI_RDATA;
  wire [5:0]inference_memory_M00_AXI_RID;
  wire inference_memory_M00_AXI_RLAST;
  wire inference_memory_M00_AXI_RREADY;
  wire [1:0]inference_memory_M00_AXI_RRESP;
  wire inference_memory_M00_AXI_RVALID;
  wire [63:0]inference_memory_M00_AXI_WDATA;
  wire [0:0]inference_memory_M00_AXI_WID;
  wire inference_memory_M00_AXI_WLAST;
  wire inference_memory_M00_AXI_WREADY;
  wire [7:0]inference_memory_M00_AXI_WSTRB;
  wire inference_memory_M00_AXI_WVALID;
  wire [1:0]irq_concat_dout;
  wire [31:0]mel_core_M_AXIS_TDATA;
  wire mel_core_M_AXIS_TLAST;
  wire mel_core_M_AXIS_TREADY;
  wire mel_core_M_AXIS_TVALID;
  wire [31:0]mel_dma_M_AXIS_MM2S_TDATA;
  wire mel_dma_M_AXIS_MM2S_TLAST;
  wire mel_dma_M_AXIS_MM2S_TREADY;
  wire mel_dma_M_AXIS_MM2S_TVALID;
  wire [31:0]mel_dma_M_AXI_MM2S_ARADDR;
  wire [1:0]mel_dma_M_AXI_MM2S_ARBURST;
  wire [3:0]mel_dma_M_AXI_MM2S_ARCACHE;
  wire [7:0]mel_dma_M_AXI_MM2S_ARLEN;
  wire [2:0]mel_dma_M_AXI_MM2S_ARPROT;
  wire mel_dma_M_AXI_MM2S_ARREADY;
  wire [2:0]mel_dma_M_AXI_MM2S_ARSIZE;
  wire mel_dma_M_AXI_MM2S_ARVALID;
  wire [31:0]mel_dma_M_AXI_MM2S_RDATA;
  wire mel_dma_M_AXI_MM2S_RLAST;
  wire mel_dma_M_AXI_MM2S_RREADY;
  wire [1:0]mel_dma_M_AXI_MM2S_RRESP;
  wire mel_dma_M_AXI_MM2S_RVALID;
  wire [31:0]mel_dma_M_AXI_S2MM_AWADDR;
  wire [1:0]mel_dma_M_AXI_S2MM_AWBURST;
  wire [3:0]mel_dma_M_AXI_S2MM_AWCACHE;
  wire [7:0]mel_dma_M_AXI_S2MM_AWLEN;
  wire [2:0]mel_dma_M_AXI_S2MM_AWPROT;
  wire mel_dma_M_AXI_S2MM_AWREADY;
  wire [2:0]mel_dma_M_AXI_S2MM_AWSIZE;
  wire mel_dma_M_AXI_S2MM_AWVALID;
  wire mel_dma_M_AXI_S2MM_BREADY;
  wire [1:0]mel_dma_M_AXI_S2MM_BRESP;
  wire mel_dma_M_AXI_S2MM_BVALID;
  wire [31:0]mel_dma_M_AXI_S2MM_WDATA;
  wire mel_dma_M_AXI_S2MM_WLAST;
  wire mel_dma_M_AXI_S2MM_WREADY;
  wire [3:0]mel_dma_M_AXI_S2MM_WSTRB;
  wire mel_dma_M_AXI_S2MM_WVALID;
  wire [31:0]mel_memory_M00_AXI_ARADDR;
  wire [1:0]mel_memory_M00_AXI_ARBURST;
  wire [3:0]mel_memory_M00_AXI_ARCACHE;
  wire [1:0]mel_memory_M00_AXI_ARID;
  wire [3:0]mel_memory_M00_AXI_ARLEN;
  wire [1:0]mel_memory_M00_AXI_ARLOCK;
  wire [2:0]mel_memory_M00_AXI_ARPROT;
  wire [3:0]mel_memory_M00_AXI_ARQOS;
  wire mel_memory_M00_AXI_ARREADY;
  wire [2:0]mel_memory_M00_AXI_ARSIZE;
  wire mel_memory_M00_AXI_ARVALID;
  wire [31:0]mel_memory_M00_AXI_AWADDR;
  wire [1:0]mel_memory_M00_AXI_AWBURST;
  wire [3:0]mel_memory_M00_AXI_AWCACHE;
  wire [1:0]mel_memory_M00_AXI_AWID;
  wire [3:0]mel_memory_M00_AXI_AWLEN;
  wire [1:0]mel_memory_M00_AXI_AWLOCK;
  wire [2:0]mel_memory_M00_AXI_AWPROT;
  wire [3:0]mel_memory_M00_AXI_AWQOS;
  wire mel_memory_M00_AXI_AWREADY;
  wire [2:0]mel_memory_M00_AXI_AWSIZE;
  wire mel_memory_M00_AXI_AWVALID;
  wire [5:0]mel_memory_M00_AXI_BID;
  wire mel_memory_M00_AXI_BREADY;
  wire [1:0]mel_memory_M00_AXI_BRESP;
  wire mel_memory_M00_AXI_BVALID;
  wire [63:0]mel_memory_M00_AXI_RDATA;
  wire [5:0]mel_memory_M00_AXI_RID;
  wire mel_memory_M00_AXI_RLAST;
  wire mel_memory_M00_AXI_RREADY;
  wire [1:0]mel_memory_M00_AXI_RRESP;
  wire mel_memory_M00_AXI_RVALID;
  wire [63:0]mel_memory_M00_AXI_WDATA;
  wire [1:0]mel_memory_M00_AXI_WID;
  wire mel_memory_M00_AXI_WLAST;
  wire mel_memory_M00_AXI_WREADY;
  wire [7:0]mel_memory_M00_AXI_WSTRB;
  wire mel_memory_M00_AXI_WVALID;
  wire mic_sd_0_1;
  wire mic_sd_1_1;
  wire mic_sd_2_1;
  wire mic_sd_3_1;
  wire [127:0]pcm_cdc_M_AXIS_TDATA;
  wire [15:0]pcm_cdc_M_AXIS_TKEEP;
  wire pcm_cdc_M_AXIS_TLAST;
  wire pcm_cdc_M_AXIS_TREADY;
  wire pcm_cdc_M_AXIS_TVALID;
  wire [14:0]ps7_DDR_ADDR;
  wire [2:0]ps7_DDR_BA;
  wire ps7_DDR_CAS_N;
  wire ps7_DDR_CKE;
  wire ps7_DDR_CK_N;
  wire ps7_DDR_CK_P;
  wire ps7_DDR_CS_N;
  wire [3:0]ps7_DDR_DM;
  wire [31:0]ps7_DDR_DQ;
  wire [3:0]ps7_DDR_DQS_N;
  wire [3:0]ps7_DDR_DQS_P;
  wire ps7_DDR_ODT;
  wire ps7_DDR_RAS_N;
  wire ps7_DDR_RESET_N;
  wire ps7_DDR_WE_N;
  wire ps7_FCLK_CLK0;
  wire ps7_FCLK_RESET0_N;
  wire ps7_FIXED_IO_DDR_VRN;
  wire ps7_FIXED_IO_DDR_VRP;
  wire [53:0]ps7_FIXED_IO_MIO;
  wire ps7_FIXED_IO_PS_CLK;
  wire ps7_FIXED_IO_PS_PORB;
  wire ps7_FIXED_IO_PS_SRSTB;
  wire [31:0]ps7_M_AXI_GP0_ARADDR;
  wire [1:0]ps7_M_AXI_GP0_ARBURST;
  wire [3:0]ps7_M_AXI_GP0_ARCACHE;
  wire [11:0]ps7_M_AXI_GP0_ARID;
  wire [3:0]ps7_M_AXI_GP0_ARLEN;
  wire [1:0]ps7_M_AXI_GP0_ARLOCK;
  wire [2:0]ps7_M_AXI_GP0_ARPROT;
  wire [3:0]ps7_M_AXI_GP0_ARQOS;
  wire ps7_M_AXI_GP0_ARREADY;
  wire [2:0]ps7_M_AXI_GP0_ARSIZE;
  wire ps7_M_AXI_GP0_ARVALID;
  wire [31:0]ps7_M_AXI_GP0_AWADDR;
  wire [1:0]ps7_M_AXI_GP0_AWBURST;
  wire [3:0]ps7_M_AXI_GP0_AWCACHE;
  wire [11:0]ps7_M_AXI_GP0_AWID;
  wire [3:0]ps7_M_AXI_GP0_AWLEN;
  wire [1:0]ps7_M_AXI_GP0_AWLOCK;
  wire [2:0]ps7_M_AXI_GP0_AWPROT;
  wire [3:0]ps7_M_AXI_GP0_AWQOS;
  wire ps7_M_AXI_GP0_AWREADY;
  wire [2:0]ps7_M_AXI_GP0_AWSIZE;
  wire ps7_M_AXI_GP0_AWVALID;
  wire [11:0]ps7_M_AXI_GP0_BID;
  wire ps7_M_AXI_GP0_BREADY;
  wire [1:0]ps7_M_AXI_GP0_BRESP;
  wire ps7_M_AXI_GP0_BVALID;
  wire [31:0]ps7_M_AXI_GP0_RDATA;
  wire [11:0]ps7_M_AXI_GP0_RID;
  wire ps7_M_AXI_GP0_RLAST;
  wire ps7_M_AXI_GP0_RREADY;
  wire [1:0]ps7_M_AXI_GP0_RRESP;
  wire ps7_M_AXI_GP0_RVALID;
  wire [31:0]ps7_M_AXI_GP0_WDATA;
  wire [11:0]ps7_M_AXI_GP0_WID;
  wire ps7_M_AXI_GP0_WLAST;
  wire ps7_M_AXI_GP0_WREADY;
  wire [3:0]ps7_M_AXI_GP0_WSTRB;
  wire ps7_M_AXI_GP0_WVALID;
  wire [0:0]rst_audio_peripheral_aresetn;
  wire [0:0]rst_audio_peripheral_reset;
  wire [0:0]rst_fclk_interconnect_aresetn;
  wire [0:0]rst_fclk_peripheral_aresetn;
  wire [0:0]rst_fclk_peripheral_reset;
  wire [0:0]rst_hdmi_peripheral_aresetn;
  wire [0:0]rst_hdmi_peripheral_reset;
  wire [0:0]rst_hdmi_read_peripheral_aresetn;
  wire [0:0]rst_pixel_peripheral_aresetn;
  wire [0:0]rst_pixel_peripheral_reset;
  wire [31:0]ssd_dma_M_AXIS_MM2S_TDATA;
  wire ssd_dma_M_AXIS_MM2S_TLAST;
  wire ssd_dma_M_AXIS_MM2S_TREADY;
  wire ssd_dma_M_AXIS_MM2S_TVALID;
  wire [31:0]ssd_dma_M_AXI_MM2S_ARADDR;
  wire [1:0]ssd_dma_M_AXI_MM2S_ARBURST;
  wire [3:0]ssd_dma_M_AXI_MM2S_ARCACHE;
  wire [7:0]ssd_dma_M_AXI_MM2S_ARLEN;
  wire [2:0]ssd_dma_M_AXI_MM2S_ARPROT;
  wire ssd_dma_M_AXI_MM2S_ARREADY;
  wire [2:0]ssd_dma_M_AXI_MM2S_ARSIZE;
  wire ssd_dma_M_AXI_MM2S_ARVALID;
  wire [31:0]ssd_dma_M_AXI_MM2S_RDATA;
  wire ssd_dma_M_AXI_MM2S_RLAST;
  wire ssd_dma_M_AXI_MM2S_RREADY;
  wire [1:0]ssd_dma_M_AXI_MM2S_RRESP;
  wire ssd_dma_M_AXI_MM2S_RVALID;
  wire [31:0]ssd_dma_M_AXI_S2MM_AWADDR;
  wire [1:0]ssd_dma_M_AXI_S2MM_AWBURST;
  wire [3:0]ssd_dma_M_AXI_S2MM_AWCACHE;
  wire [7:0]ssd_dma_M_AXI_S2MM_AWLEN;
  wire [2:0]ssd_dma_M_AXI_S2MM_AWPROT;
  wire ssd_dma_M_AXI_S2MM_AWREADY;
  wire [2:0]ssd_dma_M_AXI_S2MM_AWSIZE;
  wire ssd_dma_M_AXI_S2MM_AWVALID;
  wire ssd_dma_M_AXI_S2MM_BREADY;
  wire [1:0]ssd_dma_M_AXI_S2MM_BRESP;
  wire ssd_dma_M_AXI_S2MM_BVALID;
  wire [31:0]ssd_dma_M_AXI_S2MM_WDATA;
  wire ssd_dma_M_AXI_S2MM_WLAST;
  wire ssd_dma_M_AXI_S2MM_WREADY;
  wire [3:0]ssd_dma_M_AXI_S2MM_WSTRB;
  wire ssd_dma_M_AXI_S2MM_WVALID;
  wire [31:0]ssd_preprocess_core_M_AXIS_TDATA;
  wire [3:0]ssd_preprocess_core_M_AXIS_TKEEP;
  wire ssd_preprocess_core_M_AXIS_TLAST;
  wire ssd_preprocess_core_M_AXIS_TREADY;
  wire ssd_preprocess_core_M_AXIS_TVALID;
  wire [15:0]status_cdc_dst_dark_ratio;
  wire [31:0]status_cdc_dst_frame_count;
  wire [7:0]status_cdc_dst_mean_y;
  wire status_cdc_dst_strobe;
  wire [31:0]status_cdc_dst_video_drop;
  wire [15:0]vdma_M_AXIS_MM2S_TDATA;
  wire [1:0]vdma_M_AXIS_MM2S_TKEEP;
  wire vdma_M_AXIS_MM2S_TLAST;
  wire vdma_M_AXIS_MM2S_TREADY;
  wire [0:0]vdma_M_AXIS_MM2S_TUSER;
  wire vdma_M_AXIS_MM2S_TVALID;
  wire [31:0]vdma_M_AXI_MM2S_ARADDR;
  wire [1:0]vdma_M_AXI_MM2S_ARBURST;
  wire [3:0]vdma_M_AXI_MM2S_ARCACHE;
  wire [7:0]vdma_M_AXI_MM2S_ARLEN;
  wire [2:0]vdma_M_AXI_MM2S_ARPROT;
  wire vdma_M_AXI_MM2S_ARREADY;
  wire [2:0]vdma_M_AXI_MM2S_ARSIZE;
  wire vdma_M_AXI_MM2S_ARVALID;
  wire [63:0]vdma_M_AXI_MM2S_RDATA;
  wire vdma_M_AXI_MM2S_RLAST;
  wire vdma_M_AXI_MM2S_RREADY;
  wire [1:0]vdma_M_AXI_MM2S_RRESP;
  wire vdma_M_AXI_MM2S_RVALID;
  wire [31:0]vdma_M_AXI_S2MM_AWADDR;
  wire [1:0]vdma_M_AXI_S2MM_AWBURST;
  wire [3:0]vdma_M_AXI_S2MM_AWCACHE;
  wire [7:0]vdma_M_AXI_S2MM_AWLEN;
  wire [2:0]vdma_M_AXI_S2MM_AWPROT;
  wire vdma_M_AXI_S2MM_AWREADY;
  wire [2:0]vdma_M_AXI_S2MM_AWSIZE;
  wire vdma_M_AXI_S2MM_AWVALID;
  wire vdma_M_AXI_S2MM_BREADY;
  wire [1:0]vdma_M_AXI_S2MM_BRESP;
  wire vdma_M_AXI_S2MM_BVALID;
  wire [63:0]vdma_M_AXI_S2MM_WDATA;
  wire vdma_M_AXI_S2MM_WLAST;
  wire vdma_M_AXI_S2MM_WREADY;
  wire [7:0]vdma_M_AXI_S2MM_WSTRB;
  wire vdma_M_AXI_S2MM_WVALID;
  wire [31:0]vdma_proto_M_AXI_AWADDR;
  wire [1:0]vdma_proto_M_AXI_AWBURST;
  wire [3:0]vdma_proto_M_AXI_AWCACHE;
  wire [3:0]vdma_proto_M_AXI_AWLEN;
  wire [1:0]vdma_proto_M_AXI_AWLOCK;
  wire [2:0]vdma_proto_M_AXI_AWPROT;
  wire [3:0]vdma_proto_M_AXI_AWQOS;
  wire vdma_proto_M_AXI_AWREADY;
  wire [2:0]vdma_proto_M_AXI_AWSIZE;
  wire vdma_proto_M_AXI_AWVALID;
  wire vdma_proto_M_AXI_BREADY;
  wire [1:0]vdma_proto_M_AXI_BRESP;
  wire vdma_proto_M_AXI_BVALID;
  wire [63:0]vdma_proto_M_AXI_WDATA;
  wire vdma_proto_M_AXI_WLAST;
  wire vdma_proto_M_AXI_WREADY;
  wire [7:0]vdma_proto_M_AXI_WSTRB;
  wire vdma_proto_M_AXI_WVALID;
  wire vdma_s2mm_introut;
  wire [15:0]video_cdc_M_AXIS_TDATA;
  wire [1:0]video_cdc_M_AXIS_TKEEP;
  wire video_cdc_M_AXIS_TLAST;
  wire video_cdc_M_AXIS_TREADY;
  wire [0:0]video_cdc_M_AXIS_TUSER;
  wire video_cdc_M_AXIS_TVALID;

  assign cam_d_1 = cam_d[7:0];
  assign cam_href_1 = cam_href;
  assign cam_pclk_1 = cam_pclk;
  assign cam_pwdn = cam_io_cam_pwdn;
  assign cam_reset_n = cam_io_cam_reset_n;
  assign cam_vsync_1 = cam_vsync;
  assign enhance_led_n = camera_enhance_led_n;
  assign hdmi_clk_n = hdmi_encoder_TMDS_Clk_n;
  assign hdmi_clk_p = hdmi_encoder_TMDS_Clk_p;
  assign hdmi_data_n[2:0] = hdmi_encoder_TMDS_Data_n;
  assign hdmi_data_p[2:0] = hdmi_encoder_TMDS_Data_p;
  assign hdmi_hpd_1 = hdmi_hpd;
  assign hdmi_out_en = hdmi_raster_hdmi_out_en;
  assign mic_sck = audio_mic_sck;
  assign mic_sd_0_1 = mic_sd_0;
  assign mic_sd_1_1 = mic_sd_1;
  assign mic_sd_2_1 = mic_sd_2;
  assign mic_sd_3_1 = mic_sd_3;
  assign mic_ws = audio_mic_ws;
  assign servo_pan = audio_servo_pan;
  assign servo_tilt = audio_servo_tilt;
  av_system_audio_0 audio
       (.board_keys_n(board_keys_n),
        .clk_98m304(clk_audio_clk_out1),
        .enhance_master_enable(audio_enhance_master_enable),
        .gamma_event_data(audio_gamma_event_data),
        .gamma_event_valid(audio_gamma_event_valid),
        .m_axis_model_mel_tdata(audio_m_axis_model_mel_TDATA),
        .m_axis_model_mel_tlast(audio_m_axis_model_mel_TLAST),
        .m_axis_model_mel_tready(audio_m_axis_model_mel_TREADY),
        .m_axis_model_mel_tuser(audio_m_axis_model_mel_TUSER),
        .m_axis_model_mel_tvalid(audio_m_axis_model_mel_TVALID),
        .m_axis_pcm_tdata(audio_m_axis_pcm_TDATA),
        .m_axis_pcm_tkeep(audio_m_axis_pcm_TKEEP),
        .m_axis_pcm_tlast(audio_m_axis_pcm_TLAST),
        .m_axis_pcm_tready(audio_m_axis_pcm_TREADY),
        .m_axis_pcm_tvalid(audio_m_axis_pcm_TVALID),
        .mic_sck(audio_mic_sck),
        .mic_sd_0(mic_sd_0_1),
        .mic_sd_1(mic_sd_1_1),
        .mic_sd_2(mic_sd_2_1),
        .mic_sd_3(mic_sd_3_1),
        .mic_ws(audio_mic_ws),
        .resetn(rst_audio_peripheral_aresetn),
        .s_axi_araddr(ctrl_cdc_M_AXI_ARADDR),
        .s_axi_arprot(ctrl_cdc_M_AXI_ARPROT),
        .s_axi_arready(ctrl_cdc_M_AXI_ARREADY),
        .s_axi_arvalid(ctrl_cdc_M_AXI_ARVALID),
        .s_axi_awaddr(ctrl_cdc_M_AXI_AWADDR),
        .s_axi_awprot(ctrl_cdc_M_AXI_AWPROT),
        .s_axi_awready(ctrl_cdc_M_AXI_AWREADY),
        .s_axi_awvalid(ctrl_cdc_M_AXI_AWVALID),
        .s_axi_bready(ctrl_cdc_M_AXI_BREADY),
        .s_axi_bresp(ctrl_cdc_M_AXI_BRESP),
        .s_axi_bvalid(ctrl_cdc_M_AXI_BVALID),
        .s_axi_rdata(ctrl_cdc_M_AXI_RDATA),
        .s_axi_rready(ctrl_cdc_M_AXI_RREADY),
        .s_axi_rresp(ctrl_cdc_M_AXI_RRESP),
        .s_axi_rvalid(ctrl_cdc_M_AXI_RVALID),
        .s_axi_wdata(ctrl_cdc_M_AXI_WDATA),
        .s_axi_wready(ctrl_cdc_M_AXI_WREADY),
        .s_axi_wstrb(ctrl_cdc_M_AXI_WSTRB),
        .s_axi_wvalid(ctrl_cdc_M_AXI_WVALID),
        .servo_pan(audio_servo_pan),
        .servo_tilt(audio_servo_tilt),
        .stat_dark_ratio_q15(status_cdc_dst_dark_ratio),
        .stat_frame_count(status_cdc_dst_frame_count),
        .stat_frame_strobe(status_cdc_dst_strobe),
        .stat_mean_y(status_cdc_dst_mean_y),
        .stat_video_drop_count(status_cdc_dst_video_drop));
  av_system_cam_gpio_0 cam_gpio
       (.gpio2_io_i(camera_probe_probe_data),
        .gpio_io_i(cam_io_gpio_i),
        .gpio_io_o(cam_gpio_gpio_io_o),
        .gpio_io_t(cam_gpio_gpio_io_t),
        .s_axi_aclk(ps7_FCLK_CLK0),
        .s_axi_araddr(ctrl_ic_M02_AXI_ARADDR[8:0]),
        .s_axi_aresetn(rst_fclk_peripheral_aresetn),
        .s_axi_arready(ctrl_ic_M02_AXI_ARREADY),
        .s_axi_arvalid(ctrl_ic_M02_AXI_ARVALID),
        .s_axi_awaddr(ctrl_ic_M02_AXI_AWADDR[8:0]),
        .s_axi_awready(ctrl_ic_M02_AXI_AWREADY),
        .s_axi_awvalid(ctrl_ic_M02_AXI_AWVALID),
        .s_axi_bready(ctrl_ic_M02_AXI_BREADY),
        .s_axi_bresp(ctrl_ic_M02_AXI_BRESP),
        .s_axi_bvalid(ctrl_ic_M02_AXI_BVALID),
        .s_axi_rdata(ctrl_ic_M02_AXI_RDATA),
        .s_axi_rready(ctrl_ic_M02_AXI_RREADY),
        .s_axi_rresp(ctrl_ic_M02_AXI_RRESP),
        .s_axi_rvalid(ctrl_ic_M02_AXI_RVALID),
        .s_axi_wdata(ctrl_ic_M02_AXI_WDATA),
        .s_axi_wready(ctrl_ic_M02_AXI_WREADY),
        .s_axi_wstrb(ctrl_ic_M02_AXI_WSTRB),
        .s_axi_wvalid(ctrl_ic_M02_AXI_WVALID));
  av_system_cam_io_0 cam_io
       (.cam_pwdn(cam_io_cam_pwdn),
        .cam_reset_n(cam_io_cam_reset_n),
        .cam_scl(cam_scl),
        .cam_sda(cam_sda),
        .camera_configured(cam_io_camera_configured),
        .camera_test_pattern(cam_io_camera_test_pattern),
        .gpio_i(cam_io_gpio_i),
        .gpio_o(cam_gpio_gpio_io_o),
        .gpio_t(cam_gpio_gpio_io_t));
  av_system_camera_0 camera
       (.cam_d(cam_d_1),
        .cam_href(cam_href_1),
        .cam_pclk(cam_pclk_1),
        .cam_vsync(cam_vsync_1),
        .camera_configured(cam_io_camera_configured),
        .camera_test_pattern(cam_io_camera_test_pattern),
        .dark_ratio_q15(camera_dark_ratio_q15),
        .enhance_led_n(camera_enhance_led_n),
        .enhance_master_enable(audio_enhance_master_enable),
        .enhancement_debug(camera_enhancement_debug),
        .frame_count(camera_frame_count),
        .frame_start(camera_frame_start),
        .gamma_commit(gamma_cdc_gamma_commit),
        .gamma_wr_addr(gamma_cdc_gamma_wr_addr),
        .gamma_wr_data(gamma_cdc_gamma_wr_data),
        .gamma_wr_en(gamma_cdc_gamma_wr_en),
        .m_axis_model_video_tdata(camera_m_axis_model_video_TDATA),
        .m_axis_model_video_tlast(camera_m_axis_model_video_TLAST),
        .m_axis_model_video_tready(camera_m_axis_model_video_TREADY),
        .m_axis_model_video_tuser(camera_m_axis_model_video_TUSER),
        .m_axis_model_video_tvalid(camera_m_axis_model_video_TVALID),
        .m_axis_video_tdata(camera_m_axis_video_TDATA),
        .m_axis_video_tkeep(camera_m_axis_video_TKEEP),
        .m_axis_video_tlast(camera_m_axis_video_TLAST),
        .m_axis_video_tready(camera_m_axis_video_TREADY),
        .m_axis_video_tuser(camera_m_axis_video_TUSER),
        .m_axis_video_tvalid(camera_m_axis_video_TVALID),
        .mean_y(camera_mean_y),
        .resetn(rst_pixel_peripheral_aresetn),
        .video_drop_count(camera_video_drop_count));
  av_system_camera_probe_0 camera_probe
       (.cam_d(cam_d_1),
        .cam_href(cam_href_1),
        .cam_pclk(cam_pclk_1),
        .cam_vsync(cam_vsync_1),
        .clk(ps7_FCLK_CLK0),
        .debug_strobe(camera_frame_start),
        .enhancement_debug(camera_enhancement_debug),
        .pixel_reset(rst_pixel_peripheral_reset),
        .probe_data(camera_probe_probe_data),
        .resetn(rst_fclk_peripheral_aresetn));
  av_system_clk_audio_0 clk_audio
       (.clk_in1(ps7_FCLK_CLK0),
        .clk_out1(clk_audio_clk_out1),
        .locked(clk_audio_locked));
  av_system_clk_hdmi_0 clk_hdmi
       (.clk_in1(ps7_FCLK_CLK0),
        .clk_out1(clk_hdmi_clk_out1),
        .clk_out2(clk_hdmi_clk_out2),
        .clk_out3(clk_hdmi_clk_out3),
        .locked(clk_hdmi_locked));
  av_system_const_one_0 const_one
       (.dout(const_one_dout));
  av_system_const_zero_0 const_zero
       (.dout(const_zero_dout));
  av_system_ctrl_cdc_0 ctrl_cdc
       (.m_axi_aclk(clk_audio_clk_out1),
        .m_axi_araddr(ctrl_cdc_M_AXI_ARADDR),
        .m_axi_aresetn(rst_audio_peripheral_aresetn),
        .m_axi_arprot(ctrl_cdc_M_AXI_ARPROT),
        .m_axi_arready(ctrl_cdc_M_AXI_ARREADY),
        .m_axi_arvalid(ctrl_cdc_M_AXI_ARVALID),
        .m_axi_awaddr(ctrl_cdc_M_AXI_AWADDR),
        .m_axi_awprot(ctrl_cdc_M_AXI_AWPROT),
        .m_axi_awready(ctrl_cdc_M_AXI_AWREADY),
        .m_axi_awvalid(ctrl_cdc_M_AXI_AWVALID),
        .m_axi_bready(ctrl_cdc_M_AXI_BREADY),
        .m_axi_bresp(ctrl_cdc_M_AXI_BRESP),
        .m_axi_bvalid(ctrl_cdc_M_AXI_BVALID),
        .m_axi_rdata(ctrl_cdc_M_AXI_RDATA),
        .m_axi_rready(ctrl_cdc_M_AXI_RREADY),
        .m_axi_rresp(ctrl_cdc_M_AXI_RRESP),
        .m_axi_rvalid(ctrl_cdc_M_AXI_RVALID),
        .m_axi_wdata(ctrl_cdc_M_AXI_WDATA),
        .m_axi_wready(ctrl_cdc_M_AXI_WREADY),
        .m_axi_wstrb(ctrl_cdc_M_AXI_WSTRB),
        .m_axi_wvalid(ctrl_cdc_M_AXI_WVALID),
        .s_axi_aclk(ps7_FCLK_CLK0),
        .s_axi_araddr(ctrl_ic_M03_AXI_ARADDR[7:0]),
        .s_axi_aresetn(rst_fclk_peripheral_aresetn),
        .s_axi_arprot(ctrl_ic_M03_AXI_ARPROT),
        .s_axi_arready(ctrl_ic_M03_AXI_ARREADY),
        .s_axi_arvalid(ctrl_ic_M03_AXI_ARVALID),
        .s_axi_awaddr(ctrl_ic_M03_AXI_AWADDR[7:0]),
        .s_axi_awprot(ctrl_ic_M03_AXI_AWPROT),
        .s_axi_awready(ctrl_ic_M03_AXI_AWREADY),
        .s_axi_awvalid(ctrl_ic_M03_AXI_AWVALID),
        .s_axi_bready(ctrl_ic_M03_AXI_BREADY),
        .s_axi_bresp(ctrl_ic_M03_AXI_BRESP),
        .s_axi_bvalid(ctrl_ic_M03_AXI_BVALID),
        .s_axi_rdata(ctrl_ic_M03_AXI_RDATA),
        .s_axi_rready(ctrl_ic_M03_AXI_RREADY),
        .s_axi_rresp(ctrl_ic_M03_AXI_RRESP),
        .s_axi_rvalid(ctrl_ic_M03_AXI_RVALID),
        .s_axi_wdata(ctrl_ic_M03_AXI_WDATA),
        .s_axi_wready(ctrl_ic_M03_AXI_WREADY),
        .s_axi_wstrb(ctrl_ic_M03_AXI_WSTRB),
        .s_axi_wvalid(ctrl_ic_M03_AXI_WVALID));
  av_system_ctrl_ic_0 ctrl_ic
       (.ACLK(ps7_FCLK_CLK0),
        .ARESETN(rst_fclk_interconnect_aresetn),
        .M00_ACLK(ps7_FCLK_CLK0),
        .M00_ARESETN(rst_fclk_peripheral_aresetn),
        .M00_AXI_araddr(ctrl_ic_M00_AXI_ARADDR),
        .M00_AXI_arready(ctrl_ic_M00_AXI_ARREADY),
        .M00_AXI_arvalid(ctrl_ic_M00_AXI_ARVALID),
        .M00_AXI_awaddr(ctrl_ic_M00_AXI_AWADDR),
        .M00_AXI_awready(ctrl_ic_M00_AXI_AWREADY),
        .M00_AXI_awvalid(ctrl_ic_M00_AXI_AWVALID),
        .M00_AXI_bready(ctrl_ic_M00_AXI_BREADY),
        .M00_AXI_bresp(ctrl_ic_M00_AXI_BRESP),
        .M00_AXI_bvalid(ctrl_ic_M00_AXI_BVALID),
        .M00_AXI_rdata(ctrl_ic_M00_AXI_RDATA),
        .M00_AXI_rready(ctrl_ic_M00_AXI_RREADY),
        .M00_AXI_rresp(ctrl_ic_M00_AXI_RRESP),
        .M00_AXI_rvalid(ctrl_ic_M00_AXI_RVALID),
        .M00_AXI_wdata(ctrl_ic_M00_AXI_WDATA),
        .M00_AXI_wready(ctrl_ic_M00_AXI_WREADY),
        .M00_AXI_wvalid(ctrl_ic_M00_AXI_WVALID),
        .M01_ACLK(ps7_FCLK_CLK0),
        .M01_ARESETN(rst_fclk_peripheral_aresetn),
        .M01_AXI_araddr(ctrl_ic_M01_AXI_ARADDR),
        .M01_AXI_arready(ctrl_ic_M01_AXI_ARREADY),
        .M01_AXI_arvalid(ctrl_ic_M01_AXI_ARVALID),
        .M01_AXI_awaddr(ctrl_ic_M01_AXI_AWADDR),
        .M01_AXI_awready(ctrl_ic_M01_AXI_AWREADY),
        .M01_AXI_awvalid(ctrl_ic_M01_AXI_AWVALID),
        .M01_AXI_bready(ctrl_ic_M01_AXI_BREADY),
        .M01_AXI_bresp(ctrl_ic_M01_AXI_BRESP),
        .M01_AXI_bvalid(ctrl_ic_M01_AXI_BVALID),
        .M01_AXI_rdata(ctrl_ic_M01_AXI_RDATA),
        .M01_AXI_rready(ctrl_ic_M01_AXI_RREADY),
        .M01_AXI_rresp(ctrl_ic_M01_AXI_RRESP),
        .M01_AXI_rvalid(ctrl_ic_M01_AXI_RVALID),
        .M01_AXI_wdata(ctrl_ic_M01_AXI_WDATA),
        .M01_AXI_wready(ctrl_ic_M01_AXI_WREADY),
        .M01_AXI_wvalid(ctrl_ic_M01_AXI_WVALID),
        .M02_ACLK(ps7_FCLK_CLK0),
        .M02_ARESETN(rst_fclk_peripheral_aresetn),
        .M02_AXI_araddr(ctrl_ic_M02_AXI_ARADDR),
        .M02_AXI_arready(ctrl_ic_M02_AXI_ARREADY),
        .M02_AXI_arvalid(ctrl_ic_M02_AXI_ARVALID),
        .M02_AXI_awaddr(ctrl_ic_M02_AXI_AWADDR),
        .M02_AXI_awready(ctrl_ic_M02_AXI_AWREADY),
        .M02_AXI_awvalid(ctrl_ic_M02_AXI_AWVALID),
        .M02_AXI_bready(ctrl_ic_M02_AXI_BREADY),
        .M02_AXI_bresp(ctrl_ic_M02_AXI_BRESP),
        .M02_AXI_bvalid(ctrl_ic_M02_AXI_BVALID),
        .M02_AXI_rdata(ctrl_ic_M02_AXI_RDATA),
        .M02_AXI_rready(ctrl_ic_M02_AXI_RREADY),
        .M02_AXI_rresp(ctrl_ic_M02_AXI_RRESP),
        .M02_AXI_rvalid(ctrl_ic_M02_AXI_RVALID),
        .M02_AXI_wdata(ctrl_ic_M02_AXI_WDATA),
        .M02_AXI_wready(ctrl_ic_M02_AXI_WREADY),
        .M02_AXI_wstrb(ctrl_ic_M02_AXI_WSTRB),
        .M02_AXI_wvalid(ctrl_ic_M02_AXI_WVALID),
        .M03_ACLK(ps7_FCLK_CLK0),
        .M03_ARESETN(rst_fclk_peripheral_aresetn),
        .M03_AXI_araddr(ctrl_ic_M03_AXI_ARADDR),
        .M03_AXI_arprot(ctrl_ic_M03_AXI_ARPROT),
        .M03_AXI_arready(ctrl_ic_M03_AXI_ARREADY),
        .M03_AXI_arvalid(ctrl_ic_M03_AXI_ARVALID),
        .M03_AXI_awaddr(ctrl_ic_M03_AXI_AWADDR),
        .M03_AXI_awprot(ctrl_ic_M03_AXI_AWPROT),
        .M03_AXI_awready(ctrl_ic_M03_AXI_AWREADY),
        .M03_AXI_awvalid(ctrl_ic_M03_AXI_AWVALID),
        .M03_AXI_bready(ctrl_ic_M03_AXI_BREADY),
        .M03_AXI_bresp(ctrl_ic_M03_AXI_BRESP),
        .M03_AXI_bvalid(ctrl_ic_M03_AXI_BVALID),
        .M03_AXI_rdata(ctrl_ic_M03_AXI_RDATA),
        .M03_AXI_rready(ctrl_ic_M03_AXI_RREADY),
        .M03_AXI_rresp(ctrl_ic_M03_AXI_RRESP),
        .M03_AXI_rvalid(ctrl_ic_M03_AXI_RVALID),
        .M03_AXI_wdata(ctrl_ic_M03_AXI_WDATA),
        .M03_AXI_wready(ctrl_ic_M03_AXI_WREADY),
        .M03_AXI_wstrb(ctrl_ic_M03_AXI_WSTRB),
        .M03_AXI_wvalid(ctrl_ic_M03_AXI_WVALID),
        .M04_ACLK(ps7_FCLK_CLK0),
        .M04_ARESETN(rst_fclk_peripheral_aresetn),
        .M04_AXI_araddr(ctrl_ic_M04_AXI_ARADDR),
        .M04_AXI_arready(ctrl_ic_M04_AXI_ARREADY),
        .M04_AXI_arvalid(ctrl_ic_M04_AXI_ARVALID),
        .M04_AXI_awaddr(ctrl_ic_M04_AXI_AWADDR),
        .M04_AXI_awready(ctrl_ic_M04_AXI_AWREADY),
        .M04_AXI_awvalid(ctrl_ic_M04_AXI_AWVALID),
        .M04_AXI_bready(ctrl_ic_M04_AXI_BREADY),
        .M04_AXI_bresp(ctrl_ic_M04_AXI_BRESP),
        .M04_AXI_bvalid(ctrl_ic_M04_AXI_BVALID),
        .M04_AXI_rdata(ctrl_ic_M04_AXI_RDATA),
        .M04_AXI_rready(ctrl_ic_M04_AXI_RREADY),
        .M04_AXI_rresp(ctrl_ic_M04_AXI_RRESP),
        .M04_AXI_rvalid(ctrl_ic_M04_AXI_RVALID),
        .M04_AXI_wdata(ctrl_ic_M04_AXI_WDATA),
        .M04_AXI_wready(ctrl_ic_M04_AXI_WREADY),
        .M04_AXI_wvalid(ctrl_ic_M04_AXI_WVALID),
        .M05_ACLK(ps7_FCLK_CLK0),
        .M05_ARESETN(rst_fclk_peripheral_aresetn),
        .M05_AXI_araddr(ctrl_ic_M05_AXI_ARADDR),
        .M05_AXI_arready(ctrl_ic_M05_AXI_ARREADY),
        .M05_AXI_arvalid(ctrl_ic_M05_AXI_ARVALID),
        .M05_AXI_awaddr(ctrl_ic_M05_AXI_AWADDR),
        .M05_AXI_awready(ctrl_ic_M05_AXI_AWREADY),
        .M05_AXI_awvalid(ctrl_ic_M05_AXI_AWVALID),
        .M05_AXI_bready(ctrl_ic_M05_AXI_BREADY),
        .M05_AXI_bresp(ctrl_ic_M05_AXI_BRESP),
        .M05_AXI_bvalid(ctrl_ic_M05_AXI_BVALID),
        .M05_AXI_rdata(ctrl_ic_M05_AXI_RDATA),
        .M05_AXI_rready(ctrl_ic_M05_AXI_RREADY),
        .M05_AXI_rresp(ctrl_ic_M05_AXI_RRESP),
        .M05_AXI_rvalid(ctrl_ic_M05_AXI_RVALID),
        .M05_AXI_wdata(ctrl_ic_M05_AXI_WDATA),
        .M05_AXI_wready(ctrl_ic_M05_AXI_WREADY),
        .M05_AXI_wstrb(ctrl_ic_M05_AXI_WSTRB),
        .M05_AXI_wvalid(ctrl_ic_M05_AXI_WVALID),
        .M06_ACLK(ps7_FCLK_CLK0),
        .M06_ARESETN(rst_fclk_peripheral_aresetn),
        .M06_AXI_araddr(ctrl_ic_M06_AXI_ARADDR),
        .M06_AXI_arready(ctrl_ic_M06_AXI_ARREADY),
        .M06_AXI_arvalid(ctrl_ic_M06_AXI_ARVALID),
        .M06_AXI_awaddr(ctrl_ic_M06_AXI_AWADDR),
        .M06_AXI_awready(ctrl_ic_M06_AXI_AWREADY),
        .M06_AXI_awvalid(ctrl_ic_M06_AXI_AWVALID),
        .M06_AXI_bready(ctrl_ic_M06_AXI_BREADY),
        .M06_AXI_bresp(ctrl_ic_M06_AXI_BRESP),
        .M06_AXI_bvalid(ctrl_ic_M06_AXI_BVALID),
        .M06_AXI_rdata(ctrl_ic_M06_AXI_RDATA),
        .M06_AXI_rready(ctrl_ic_M06_AXI_RREADY),
        .M06_AXI_rresp(ctrl_ic_M06_AXI_RRESP),
        .M06_AXI_rvalid(ctrl_ic_M06_AXI_RVALID),
        .M06_AXI_wdata(ctrl_ic_M06_AXI_WDATA),
        .M06_AXI_wready(ctrl_ic_M06_AXI_WREADY),
        .M06_AXI_wvalid(ctrl_ic_M06_AXI_WVALID),
        .M07_ACLK(ps7_FCLK_CLK0),
        .M07_ARESETN(rst_fclk_peripheral_aresetn),
        .M07_AXI_araddr(ctrl_ic_M07_AXI_ARADDR),
        .M07_AXI_arready(ctrl_ic_M07_AXI_ARREADY),
        .M07_AXI_arvalid(ctrl_ic_M07_AXI_ARVALID),
        .M07_AXI_awaddr(ctrl_ic_M07_AXI_AWADDR),
        .M07_AXI_awready(ctrl_ic_M07_AXI_AWREADY),
        .M07_AXI_awvalid(ctrl_ic_M07_AXI_AWVALID),
        .M07_AXI_bready(ctrl_ic_M07_AXI_BREADY),
        .M07_AXI_bresp(ctrl_ic_M07_AXI_BRESP),
        .M07_AXI_bvalid(ctrl_ic_M07_AXI_BVALID),
        .M07_AXI_rdata(ctrl_ic_M07_AXI_RDATA),
        .M07_AXI_rready(ctrl_ic_M07_AXI_RREADY),
        .M07_AXI_rresp(ctrl_ic_M07_AXI_RRESP),
        .M07_AXI_rvalid(ctrl_ic_M07_AXI_RVALID),
        .M07_AXI_wdata(ctrl_ic_M07_AXI_WDATA),
        .M07_AXI_wready(ctrl_ic_M07_AXI_WREADY),
        .M07_AXI_wvalid(ctrl_ic_M07_AXI_WVALID),
        .M08_ACLK(ps7_FCLK_CLK0),
        .M08_ARESETN(rst_fclk_peripheral_aresetn),
        .M08_AXI_araddr(ctrl_ic_M08_AXI_ARADDR),
        .M08_AXI_arready(ctrl_ic_M08_AXI_ARREADY),
        .M08_AXI_arvalid(ctrl_ic_M08_AXI_ARVALID),
        .M08_AXI_awaddr(ctrl_ic_M08_AXI_AWADDR),
        .M08_AXI_awready(ctrl_ic_M08_AXI_AWREADY),
        .M08_AXI_awvalid(ctrl_ic_M08_AXI_AWVALID),
        .M08_AXI_bready(ctrl_ic_M08_AXI_BREADY),
        .M08_AXI_bresp(ctrl_ic_M08_AXI_BRESP),
        .M08_AXI_bvalid(ctrl_ic_M08_AXI_BVALID),
        .M08_AXI_rdata(ctrl_ic_M08_AXI_RDATA),
        .M08_AXI_rready(ctrl_ic_M08_AXI_RREADY),
        .M08_AXI_rresp(ctrl_ic_M08_AXI_RRESP),
        .M08_AXI_rvalid(ctrl_ic_M08_AXI_RVALID),
        .M08_AXI_wdata(ctrl_ic_M08_AXI_WDATA),
        .M08_AXI_wready(ctrl_ic_M08_AXI_WREADY),
        .M08_AXI_wstrb(ctrl_ic_M08_AXI_WSTRB),
        .M08_AXI_wvalid(ctrl_ic_M08_AXI_WVALID),
        .S00_ACLK(ps7_FCLK_CLK0),
        .S00_ARESETN(rst_fclk_peripheral_aresetn),
        .S00_AXI_araddr(ps7_M_AXI_GP0_ARADDR),
        .S00_AXI_arburst(ps7_M_AXI_GP0_ARBURST),
        .S00_AXI_arcache(ps7_M_AXI_GP0_ARCACHE),
        .S00_AXI_arid(ps7_M_AXI_GP0_ARID),
        .S00_AXI_arlen(ps7_M_AXI_GP0_ARLEN),
        .S00_AXI_arlock(ps7_M_AXI_GP0_ARLOCK),
        .S00_AXI_arprot(ps7_M_AXI_GP0_ARPROT),
        .S00_AXI_arqos(ps7_M_AXI_GP0_ARQOS),
        .S00_AXI_arready(ps7_M_AXI_GP0_ARREADY),
        .S00_AXI_arsize(ps7_M_AXI_GP0_ARSIZE),
        .S00_AXI_arvalid(ps7_M_AXI_GP0_ARVALID),
        .S00_AXI_awaddr(ps7_M_AXI_GP0_AWADDR),
        .S00_AXI_awburst(ps7_M_AXI_GP0_AWBURST),
        .S00_AXI_awcache(ps7_M_AXI_GP0_AWCACHE),
        .S00_AXI_awid(ps7_M_AXI_GP0_AWID),
        .S00_AXI_awlen(ps7_M_AXI_GP0_AWLEN),
        .S00_AXI_awlock(ps7_M_AXI_GP0_AWLOCK),
        .S00_AXI_awprot(ps7_M_AXI_GP0_AWPROT),
        .S00_AXI_awqos(ps7_M_AXI_GP0_AWQOS),
        .S00_AXI_awready(ps7_M_AXI_GP0_AWREADY),
        .S00_AXI_awsize(ps7_M_AXI_GP0_AWSIZE),
        .S00_AXI_awvalid(ps7_M_AXI_GP0_AWVALID),
        .S00_AXI_bid(ps7_M_AXI_GP0_BID),
        .S00_AXI_bready(ps7_M_AXI_GP0_BREADY),
        .S00_AXI_bresp(ps7_M_AXI_GP0_BRESP),
        .S00_AXI_bvalid(ps7_M_AXI_GP0_BVALID),
        .S00_AXI_rdata(ps7_M_AXI_GP0_RDATA),
        .S00_AXI_rid(ps7_M_AXI_GP0_RID),
        .S00_AXI_rlast(ps7_M_AXI_GP0_RLAST),
        .S00_AXI_rready(ps7_M_AXI_GP0_RREADY),
        .S00_AXI_rresp(ps7_M_AXI_GP0_RRESP),
        .S00_AXI_rvalid(ps7_M_AXI_GP0_RVALID),
        .S00_AXI_wdata(ps7_M_AXI_GP0_WDATA),
        .S00_AXI_wid(ps7_M_AXI_GP0_WID),
        .S00_AXI_wlast(ps7_M_AXI_GP0_WLAST),
        .S00_AXI_wready(ps7_M_AXI_GP0_WREADY),
        .S00_AXI_wstrb(ps7_M_AXI_GP0_WSTRB),
        .S00_AXI_wvalid(ps7_M_AXI_GP0_WVALID));
  av_system_dma_0 dma
       (.axi_resetn(rst_fclk_peripheral_aresetn),
        .m_axi_s2mm_aclk(ps7_FCLK_CLK0),
        .m_axi_s2mm_awaddr(dma_M_AXI_S2MM_AWADDR),
        .m_axi_s2mm_awburst(dma_M_AXI_S2MM_AWBURST),
        .m_axi_s2mm_awcache(dma_M_AXI_S2MM_AWCACHE),
        .m_axi_s2mm_awlen(dma_M_AXI_S2MM_AWLEN),
        .m_axi_s2mm_awprot(dma_M_AXI_S2MM_AWPROT),
        .m_axi_s2mm_awready(dma_M_AXI_S2MM_AWREADY),
        .m_axi_s2mm_awsize(dma_M_AXI_S2MM_AWSIZE),
        .m_axi_s2mm_awvalid(dma_M_AXI_S2MM_AWVALID),
        .m_axi_s2mm_bready(dma_M_AXI_S2MM_BREADY),
        .m_axi_s2mm_bresp(dma_M_AXI_S2MM_BRESP),
        .m_axi_s2mm_bvalid(dma_M_AXI_S2MM_BVALID),
        .m_axi_s2mm_wdata(dma_M_AXI_S2MM_WDATA),
        .m_axi_s2mm_wlast(dma_M_AXI_S2MM_WLAST),
        .m_axi_s2mm_wready(dma_M_AXI_S2MM_WREADY),
        .m_axi_s2mm_wstrb(dma_M_AXI_S2MM_WSTRB),
        .m_axi_s2mm_wvalid(dma_M_AXI_S2MM_WVALID),
        .s2mm_introut(dma_s2mm_introut),
        .s_axi_lite_aclk(ps7_FCLK_CLK0),
        .s_axi_lite_araddr(ctrl_ic_M01_AXI_ARADDR[9:0]),
        .s_axi_lite_arready(ctrl_ic_M01_AXI_ARREADY),
        .s_axi_lite_arvalid(ctrl_ic_M01_AXI_ARVALID),
        .s_axi_lite_awaddr(ctrl_ic_M01_AXI_AWADDR[9:0]),
        .s_axi_lite_awready(ctrl_ic_M01_AXI_AWREADY),
        .s_axi_lite_awvalid(ctrl_ic_M01_AXI_AWVALID),
        .s_axi_lite_bready(ctrl_ic_M01_AXI_BREADY),
        .s_axi_lite_bresp(ctrl_ic_M01_AXI_BRESP),
        .s_axi_lite_bvalid(ctrl_ic_M01_AXI_BVALID),
        .s_axi_lite_rdata(ctrl_ic_M01_AXI_RDATA),
        .s_axi_lite_rready(ctrl_ic_M01_AXI_RREADY),
        .s_axi_lite_rresp(ctrl_ic_M01_AXI_RRESP),
        .s_axi_lite_rvalid(ctrl_ic_M01_AXI_RVALID),
        .s_axi_lite_wdata(ctrl_ic_M01_AXI_WDATA),
        .s_axi_lite_wready(ctrl_ic_M01_AXI_WREADY),
        .s_axi_lite_wvalid(ctrl_ic_M01_AXI_WVALID),
        .s_axis_s2mm_tdata(pcm_cdc_M_AXIS_TDATA),
        .s_axis_s2mm_tkeep(pcm_cdc_M_AXIS_TKEEP),
        .s_axis_s2mm_tlast(pcm_cdc_M_AXIS_TLAST),
        .s_axis_s2mm_tready(pcm_cdc_M_AXIS_TREADY),
        .s_axis_s2mm_tvalid(pcm_cdc_M_AXIS_TVALID));
  av_system_dma_proto_0 dma_proto
       (.aclk(ps7_FCLK_CLK0),
        .aresetn(rst_fclk_peripheral_aresetn),
        .m_axi_awaddr(dma_proto_M_AXI_AWADDR),
        .m_axi_awburst(dma_proto_M_AXI_AWBURST),
        .m_axi_awcache(dma_proto_M_AXI_AWCACHE),
        .m_axi_awlen(dma_proto_M_AXI_AWLEN),
        .m_axi_awlock(dma_proto_M_AXI_AWLOCK),
        .m_axi_awprot(dma_proto_M_AXI_AWPROT),
        .m_axi_awqos(dma_proto_M_AXI_AWQOS),
        .m_axi_awready(dma_proto_M_AXI_AWREADY),
        .m_axi_awsize(dma_proto_M_AXI_AWSIZE),
        .m_axi_awvalid(dma_proto_M_AXI_AWVALID),
        .m_axi_bready(dma_proto_M_AXI_BREADY),
        .m_axi_bresp(dma_proto_M_AXI_BRESP),
        .m_axi_bvalid(dma_proto_M_AXI_BVALID),
        .m_axi_wdata(dma_proto_M_AXI_WDATA),
        .m_axi_wlast(dma_proto_M_AXI_WLAST),
        .m_axi_wready(dma_proto_M_AXI_WREADY),
        .m_axi_wstrb(dma_proto_M_AXI_WSTRB),
        .m_axi_wvalid(dma_proto_M_AXI_WVALID),
        .s_axi_awaddr(dma_width_M_AXI_AWADDR),
        .s_axi_awburst(dma_width_M_AXI_AWBURST),
        .s_axi_awcache(dma_width_M_AXI_AWCACHE),
        .s_axi_awlen(dma_width_M_AXI_AWLEN),
        .s_axi_awlock(dma_width_M_AXI_AWLOCK),
        .s_axi_awprot(dma_width_M_AXI_AWPROT),
        .s_axi_awqos(dma_width_M_AXI_AWQOS),
        .s_axi_awready(dma_width_M_AXI_AWREADY),
        .s_axi_awregion(dma_width_M_AXI_AWREGION),
        .s_axi_awsize(dma_width_M_AXI_AWSIZE),
        .s_axi_awvalid(dma_width_M_AXI_AWVALID),
        .s_axi_bready(dma_width_M_AXI_BREADY),
        .s_axi_bresp(dma_width_M_AXI_BRESP),
        .s_axi_bvalid(dma_width_M_AXI_BVALID),
        .s_axi_wdata(dma_width_M_AXI_WDATA),
        .s_axi_wlast(dma_width_M_AXI_WLAST),
        .s_axi_wready(dma_width_M_AXI_WREADY),
        .s_axi_wstrb(dma_width_M_AXI_WSTRB),
        .s_axi_wvalid(dma_width_M_AXI_WVALID));
  av_system_dma_width_0 dma_width
       (.m_axi_awaddr(dma_width_M_AXI_AWADDR),
        .m_axi_awburst(dma_width_M_AXI_AWBURST),
        .m_axi_awcache(dma_width_M_AXI_AWCACHE),
        .m_axi_awlen(dma_width_M_AXI_AWLEN),
        .m_axi_awlock(dma_width_M_AXI_AWLOCK),
        .m_axi_awprot(dma_width_M_AXI_AWPROT),
        .m_axi_awqos(dma_width_M_AXI_AWQOS),
        .m_axi_awready(dma_width_M_AXI_AWREADY),
        .m_axi_awregion(dma_width_M_AXI_AWREGION),
        .m_axi_awsize(dma_width_M_AXI_AWSIZE),
        .m_axi_awvalid(dma_width_M_AXI_AWVALID),
        .m_axi_bready(dma_width_M_AXI_BREADY),
        .m_axi_bresp(dma_width_M_AXI_BRESP),
        .m_axi_bvalid(dma_width_M_AXI_BVALID),
        .m_axi_wdata(dma_width_M_AXI_WDATA),
        .m_axi_wlast(dma_width_M_AXI_WLAST),
        .m_axi_wready(dma_width_M_AXI_WREADY),
        .m_axi_wstrb(dma_width_M_AXI_WSTRB),
        .m_axi_wvalid(dma_width_M_AXI_WVALID),
        .s_axi_aclk(ps7_FCLK_CLK0),
        .s_axi_aresetn(rst_fclk_peripheral_aresetn),
        .s_axi_awaddr(dma_M_AXI_S2MM_AWADDR),
        .s_axi_awburst(dma_M_AXI_S2MM_AWBURST),
        .s_axi_awcache(dma_M_AXI_S2MM_AWCACHE),
        .s_axi_awlen(dma_M_AXI_S2MM_AWLEN),
        .s_axi_awlock(1'b0),
        .s_axi_awprot(dma_M_AXI_S2MM_AWPROT),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(dma_M_AXI_S2MM_AWREADY),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize(dma_M_AXI_S2MM_AWSIZE),
        .s_axi_awvalid(dma_M_AXI_S2MM_AWVALID),
        .s_axi_bready(dma_M_AXI_S2MM_BREADY),
        .s_axi_bresp(dma_M_AXI_S2MM_BRESP),
        .s_axi_bvalid(dma_M_AXI_S2MM_BVALID),
        .s_axi_wdata(dma_M_AXI_S2MM_WDATA),
        .s_axi_wlast(dma_M_AXI_S2MM_WLAST),
        .s_axi_wready(dma_M_AXI_S2MM_WREADY),
        .s_axi_wstrb(dma_M_AXI_S2MM_WSTRB),
        .s_axi_wvalid(dma_M_AXI_S2MM_WVALID));
  av_system_gamma_cdc_0 gamma_cdc
       (.dst_clk(cam_pclk_1),
        .dst_rst(rst_pixel_peripheral_reset),
        .gamma_commit(gamma_cdc_gamma_commit),
        .gamma_wr_addr(gamma_cdc_gamma_wr_addr),
        .gamma_wr_data(gamma_cdc_gamma_wr_data),
        .gamma_wr_en(gamma_cdc_gamma_wr_en),
        .src_clk(clk_audio_clk_out1),
        .src_data(audio_gamma_event_data),
        .src_rst(rst_audio_peripheral_reset),
        .src_valid(audio_gamma_event_valid));
  av_system_hdmi_encoder_0 hdmi_encoder
       (.PixelClk(clk_hdmi_clk_out1),
        .SerialClk(clk_hdmi_clk_out2),
        .TMDS_Clk_n(hdmi_encoder_TMDS_Clk_n),
        .TMDS_Clk_p(hdmi_encoder_TMDS_Clk_p),
        .TMDS_Data_n(hdmi_encoder_TMDS_Data_n),
        .TMDS_Data_p(hdmi_encoder_TMDS_Data_p),
        .aRst(rst_hdmi_peripheral_reset),
        .vid_pData(hdmi_osd_out_data),
        .vid_pHSync(hdmi_osd_out_hsync),
        .vid_pVDE(hdmi_osd_out_de),
        .vid_pVSync(hdmi_osd_out_vsync));
  av_system_hdmi_memory_0 hdmi_memory
       (.ACLK(ps7_FCLK_CLK0),
        .ARESETN(rst_fclk_interconnect_aresetn),
        .M00_ACLK(ps7_FCLK_CLK0),
        .M00_ARESETN(rst_fclk_peripheral_aresetn),
        .M00_AXI_araddr(hdmi_memory_M00_AXI_ARADDR),
        .M00_AXI_arburst(hdmi_memory_M00_AXI_ARBURST),
        .M00_AXI_arcache(hdmi_memory_M00_AXI_ARCACHE),
        .M00_AXI_arid(hdmi_memory_M00_AXI_ARID),
        .M00_AXI_arlen(hdmi_memory_M00_AXI_ARLEN),
        .M00_AXI_arlock(hdmi_memory_M00_AXI_ARLOCK),
        .M00_AXI_arprot(hdmi_memory_M00_AXI_ARPROT),
        .M00_AXI_arqos(hdmi_memory_M00_AXI_ARQOS),
        .M00_AXI_arready(hdmi_memory_M00_AXI_ARREADY),
        .M00_AXI_arsize(hdmi_memory_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(hdmi_memory_M00_AXI_ARVALID),
        .M00_AXI_awaddr(hdmi_memory_M00_AXI_AWADDR),
        .M00_AXI_awburst(hdmi_memory_M00_AXI_AWBURST),
        .M00_AXI_awcache(hdmi_memory_M00_AXI_AWCACHE),
        .M00_AXI_awid(hdmi_memory_M00_AXI_AWID),
        .M00_AXI_awlen(hdmi_memory_M00_AXI_AWLEN),
        .M00_AXI_awlock(hdmi_memory_M00_AXI_AWLOCK),
        .M00_AXI_awprot(hdmi_memory_M00_AXI_AWPROT),
        .M00_AXI_awqos(hdmi_memory_M00_AXI_AWQOS),
        .M00_AXI_awready(hdmi_memory_M00_AXI_AWREADY),
        .M00_AXI_awsize(hdmi_memory_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(hdmi_memory_M00_AXI_AWVALID),
        .M00_AXI_bid(hdmi_memory_M00_AXI_BID),
        .M00_AXI_bready(hdmi_memory_M00_AXI_BREADY),
        .M00_AXI_bresp(hdmi_memory_M00_AXI_BRESP),
        .M00_AXI_bvalid(hdmi_memory_M00_AXI_BVALID),
        .M00_AXI_rdata(hdmi_memory_M00_AXI_RDATA),
        .M00_AXI_rid(hdmi_memory_M00_AXI_RID),
        .M00_AXI_rlast(hdmi_memory_M00_AXI_RLAST),
        .M00_AXI_rready(hdmi_memory_M00_AXI_RREADY),
        .M00_AXI_rresp(hdmi_memory_M00_AXI_RRESP),
        .M00_AXI_rvalid(hdmi_memory_M00_AXI_RVALID),
        .M00_AXI_wdata(hdmi_memory_M00_AXI_WDATA),
        .M00_AXI_wid(hdmi_memory_M00_AXI_WID),
        .M00_AXI_wlast(hdmi_memory_M00_AXI_WLAST),
        .M00_AXI_wready(hdmi_memory_M00_AXI_WREADY),
        .M00_AXI_wstrb(hdmi_memory_M00_AXI_WSTRB),
        .M00_AXI_wvalid(hdmi_memory_M00_AXI_WVALID),
        .S00_ACLK(ps7_FCLK_CLK0),
        .S00_ARESETN(rst_fclk_peripheral_aresetn),
        .S00_AXI_awaddr(vdma_proto_M_AXI_AWADDR),
        .S00_AXI_awburst(vdma_proto_M_AXI_AWBURST),
        .S00_AXI_awcache(vdma_proto_M_AXI_AWCACHE),
        .S00_AXI_awlen(vdma_proto_M_AXI_AWLEN),
        .S00_AXI_awlock(vdma_proto_M_AXI_AWLOCK),
        .S00_AXI_awprot(vdma_proto_M_AXI_AWPROT),
        .S00_AXI_awqos(vdma_proto_M_AXI_AWQOS),
        .S00_AXI_awready(vdma_proto_M_AXI_AWREADY),
        .S00_AXI_awsize(vdma_proto_M_AXI_AWSIZE),
        .S00_AXI_awvalid(vdma_proto_M_AXI_AWVALID),
        .S00_AXI_bready(vdma_proto_M_AXI_BREADY),
        .S00_AXI_bresp(vdma_proto_M_AXI_BRESP),
        .S00_AXI_bvalid(vdma_proto_M_AXI_BVALID),
        .S00_AXI_wdata(vdma_proto_M_AXI_WDATA),
        .S00_AXI_wlast(vdma_proto_M_AXI_WLAST),
        .S00_AXI_wready(vdma_proto_M_AXI_WREADY),
        .S00_AXI_wstrb(vdma_proto_M_AXI_WSTRB),
        .S00_AXI_wvalid(vdma_proto_M_AXI_WVALID),
        .S01_ACLK(clk_hdmi_clk_out3),
        .S01_ARESETN(rst_hdmi_read_peripheral_aresetn),
        .S01_AXI_araddr(vdma_M_AXI_MM2S_ARADDR),
        .S01_AXI_arburst(vdma_M_AXI_MM2S_ARBURST),
        .S01_AXI_arcache(vdma_M_AXI_MM2S_ARCACHE),
        .S01_AXI_arlen(vdma_M_AXI_MM2S_ARLEN),
        .S01_AXI_arprot(vdma_M_AXI_MM2S_ARPROT),
        .S01_AXI_arready(vdma_M_AXI_MM2S_ARREADY),
        .S01_AXI_arsize(vdma_M_AXI_MM2S_ARSIZE),
        .S01_AXI_arvalid(vdma_M_AXI_MM2S_ARVALID),
        .S01_AXI_rdata(vdma_M_AXI_MM2S_RDATA),
        .S01_AXI_rlast(vdma_M_AXI_MM2S_RLAST),
        .S01_AXI_rready(vdma_M_AXI_MM2S_RREADY),
        .S01_AXI_rresp(vdma_M_AXI_MM2S_RRESP),
        .S01_AXI_rvalid(vdma_M_AXI_MM2S_RVALID));
  av_system_hdmi_osd_0 hdmi_osd
       (.force_bars(hdmi_gpio_gpio_io_o),
        .frame_boundary(hdmi_raster_frame_sync),
        .out_data(hdmi_osd_out_data),
        .out_de(hdmi_osd_out_de),
        .out_hsync(hdmi_osd_out_hsync),
        .out_vsync(hdmi_osd_out_vsync),
        .pixel_clk(clk_hdmi_clk_out1),
        .pixel_resetn(rst_hdmi_peripheral_aresetn),
        .s_axi_aclk(ps7_FCLK_CLK0),
        .s_axi_araddr(ctrl_ic_M08_AXI_ARADDR[7:0]),
        .s_axi_aresetn(rst_fclk_peripheral_aresetn),
        .s_axi_arready(ctrl_ic_M08_AXI_ARREADY),
        .s_axi_arvalid(ctrl_ic_M08_AXI_ARVALID),
        .s_axi_awaddr(ctrl_ic_M08_AXI_AWADDR[7:0]),
        .s_axi_awready(ctrl_ic_M08_AXI_AWREADY),
        .s_axi_awvalid(ctrl_ic_M08_AXI_AWVALID),
        .s_axi_bready(ctrl_ic_M08_AXI_BREADY),
        .s_axi_bresp(ctrl_ic_M08_AXI_BRESP),
        .s_axi_bvalid(ctrl_ic_M08_AXI_BVALID),
        .s_axi_rdata(ctrl_ic_M08_AXI_RDATA),
        .s_axi_rready(ctrl_ic_M08_AXI_RREADY),
        .s_axi_rresp(ctrl_ic_M08_AXI_RRESP),
        .s_axi_rvalid(ctrl_ic_M08_AXI_RVALID),
        .s_axi_wdata(ctrl_ic_M08_AXI_WDATA),
        .s_axi_wready(ctrl_ic_M08_AXI_WREADY),
        .s_axi_wstrb(ctrl_ic_M08_AXI_WSTRB),
        .s_axi_wvalid(ctrl_ic_M08_AXI_WVALID),
        .status_in(hdmi_status_dst_data),
        .video_data(hdmi_raster_video_data),
        .video_de(hdmi_raster_video_de),
        .video_hsync(hdmi_raster_video_hsync),
        .video_vsync(hdmi_raster_video_vsync));
  av_system_hdmi_raster_0 hdmi_raster
       (.force_bars(hdmi_gpio_gpio_io_o),
        .frame_sync(hdmi_raster_frame_sync),
        .hdmi_out_en(hdmi_raster_hdmi_out_en),
        .hpd(hdmi_hpd_1),
        .overflow(hdmi_video_out_overflow),
        .pixel_clk(clk_hdmi_clk_out1),
        .resetn(rst_hdmi_peripheral_aresetn),
        .status(hdmi_raster_status),
        .status_strobe(hdmi_raster_status_strobe),
        .stream_data(hdmi_video_out_vid_data),
        .stream_de(hdmi_video_out_vid_active_video),
        .stream_hsync(hdmi_video_out_vid_hsync),
        .stream_locked(hdmi_video_out_locked),
        .stream_vsync(hdmi_video_out_vid_vsync),
        .timing_de(hdmi_raster_timing_de),
        .timing_hblank(hdmi_raster_timing_hblank),
        .timing_hsync(hdmi_raster_timing_hsync),
        .timing_vblank(hdmi_raster_timing_vblank),
        .timing_vsync(hdmi_raster_timing_vsync),
        .underflow(hdmi_video_out_underflow),
        .video_data(hdmi_raster_video_data),
        .video_de(hdmi_raster_video_de),
        .video_hsync(hdmi_raster_video_hsync),
        .video_vsync(hdmi_raster_video_vsync));
  av_system_hdmi_rgb_0 hdmi_rgb
       (.aclk(clk_hdmi_clk_out1),
        .aresetn(rst_hdmi_peripheral_aresetn),
        .m_axis_tdata(hdmi_rgb_m_axis_TDATA),
        .m_axis_tlast(hdmi_rgb_m_axis_TLAST),
        .m_axis_tready(hdmi_rgb_m_axis_TREADY),
        .m_axis_tuser(hdmi_rgb_m_axis_TUSER),
        .m_axis_tvalid(hdmi_rgb_m_axis_TVALID),
        .s_axis_tdata(vdma_M_AXIS_MM2S_TDATA),
        .s_axis_tkeep(vdma_M_AXIS_MM2S_TKEEP),
        .s_axis_tlast(vdma_M_AXIS_MM2S_TLAST),
        .s_axis_tready(vdma_M_AXIS_MM2S_TREADY),
        .s_axis_tuser(vdma_M_AXIS_MM2S_TUSER),
        .s_axis_tvalid(vdma_M_AXIS_MM2S_TVALID));
  av_system_hdmi_status_0 hdmi_status
       (.dst_clk(ps7_FCLK_CLK0),
        .dst_data(hdmi_status_dst_data),
        .dst_rst(rst_fclk_peripheral_reset),
        .src_clk(clk_hdmi_clk_out1),
        .src_data(hdmi_raster_status),
        .src_rst(rst_hdmi_peripheral_reset),
        .src_strobe(hdmi_raster_status_strobe));
  av_system_hdmi_video_out_0 hdmi_video_out
       (.aclk(clk_hdmi_clk_out1),
        .aclken(const_one_dout),
        .aresetn(rst_hdmi_peripheral_aresetn),
        .fid(const_zero_dout),
        .locked(hdmi_video_out_locked),
        .overflow(hdmi_video_out_overflow),
        .s_axis_video_tdata(hdmi_rgb_m_axis_TDATA),
        .s_axis_video_tlast(hdmi_rgb_m_axis_TLAST),
        .s_axis_video_tready(hdmi_rgb_m_axis_TREADY),
        .s_axis_video_tuser(hdmi_rgb_m_axis_TUSER),
        .s_axis_video_tvalid(hdmi_rgb_m_axis_TVALID),
        .underflow(hdmi_video_out_underflow),
        .vid_active_video(hdmi_video_out_vid_active_video),
        .vid_data(hdmi_video_out_vid_data),
        .vid_hsync(hdmi_video_out_vid_hsync),
        .vid_io_out_ce(const_one_dout),
        .vid_vsync(hdmi_video_out_vid_vsync),
        .vtg_active_video(hdmi_raster_timing_de),
        .vtg_field_id(const_zero_dout),
        .vtg_hblank(hdmi_raster_timing_hblank),
        .vtg_hsync(hdmi_raster_timing_hsync),
        .vtg_vblank(hdmi_raster_timing_vblank),
        .vtg_vsync(hdmi_raster_timing_vsync));
  av_system_infer_dma_0 infer_dma
       (.axi_resetn(rst_fclk_peripheral_aresetn),
        .m_axi_mm2s_aclk(ps7_FCLK_CLK0),
        .m_axi_mm2s_araddr(infer_dma_M_AXI_MM2S_ARADDR),
        .m_axi_mm2s_arburst(infer_dma_M_AXI_MM2S_ARBURST),
        .m_axi_mm2s_arcache(infer_dma_M_AXI_MM2S_ARCACHE),
        .m_axi_mm2s_arlen(infer_dma_M_AXI_MM2S_ARLEN),
        .m_axi_mm2s_arprot(infer_dma_M_AXI_MM2S_ARPROT),
        .m_axi_mm2s_arready(infer_dma_M_AXI_MM2S_ARREADY),
        .m_axi_mm2s_arsize(infer_dma_M_AXI_MM2S_ARSIZE),
        .m_axi_mm2s_arvalid(infer_dma_M_AXI_MM2S_ARVALID),
        .m_axi_mm2s_rdata(infer_dma_M_AXI_MM2S_RDATA),
        .m_axi_mm2s_rlast(infer_dma_M_AXI_MM2S_RLAST),
        .m_axi_mm2s_rready(infer_dma_M_AXI_MM2S_RREADY),
        .m_axi_mm2s_rresp(infer_dma_M_AXI_MM2S_RRESP),
        .m_axi_mm2s_rvalid(infer_dma_M_AXI_MM2S_RVALID),
        .m_axi_s2mm_aclk(ps7_FCLK_CLK0),
        .m_axi_s2mm_awaddr(infer_dma_M_AXI_S2MM_AWADDR),
        .m_axi_s2mm_awburst(infer_dma_M_AXI_S2MM_AWBURST),
        .m_axi_s2mm_awcache(infer_dma_M_AXI_S2MM_AWCACHE),
        .m_axi_s2mm_awlen(infer_dma_M_AXI_S2MM_AWLEN),
        .m_axi_s2mm_awprot(infer_dma_M_AXI_S2MM_AWPROT),
        .m_axi_s2mm_awready(infer_dma_M_AXI_S2MM_AWREADY),
        .m_axi_s2mm_awsize(infer_dma_M_AXI_S2MM_AWSIZE),
        .m_axi_s2mm_awvalid(infer_dma_M_AXI_S2MM_AWVALID),
        .m_axi_s2mm_bready(infer_dma_M_AXI_S2MM_BREADY),
        .m_axi_s2mm_bresp(infer_dma_M_AXI_S2MM_BRESP),
        .m_axi_s2mm_bvalid(infer_dma_M_AXI_S2MM_BVALID),
        .m_axi_s2mm_wdata(infer_dma_M_AXI_S2MM_WDATA),
        .m_axi_s2mm_wlast(infer_dma_M_AXI_S2MM_WLAST),
        .m_axi_s2mm_wready(infer_dma_M_AXI_S2MM_WREADY),
        .m_axi_s2mm_wstrb(infer_dma_M_AXI_S2MM_WSTRB),
        .m_axi_s2mm_wvalid(infer_dma_M_AXI_S2MM_WVALID),
        .m_axis_mm2s_tdata(infer_dma_M_AXIS_MM2S_TDATA),
        .m_axis_mm2s_tkeep(infer_dma_M_AXIS_MM2S_TKEEP),
        .m_axis_mm2s_tlast(infer_dma_M_AXIS_MM2S_TLAST),
        .m_axis_mm2s_tready(infer_dma_M_AXIS_MM2S_TREADY),
        .m_axis_mm2s_tvalid(infer_dma_M_AXIS_MM2S_TVALID),
        .s_axi_lite_aclk(ps7_FCLK_CLK0),
        .s_axi_lite_araddr(ctrl_ic_M04_AXI_ARADDR[9:0]),
        .s_axi_lite_arready(ctrl_ic_M04_AXI_ARREADY),
        .s_axi_lite_arvalid(ctrl_ic_M04_AXI_ARVALID),
        .s_axi_lite_awaddr(ctrl_ic_M04_AXI_AWADDR[9:0]),
        .s_axi_lite_awready(ctrl_ic_M04_AXI_AWREADY),
        .s_axi_lite_awvalid(ctrl_ic_M04_AXI_AWVALID),
        .s_axi_lite_bready(ctrl_ic_M04_AXI_BREADY),
        .s_axi_lite_bresp(ctrl_ic_M04_AXI_BRESP),
        .s_axi_lite_bvalid(ctrl_ic_M04_AXI_BVALID),
        .s_axi_lite_rdata(ctrl_ic_M04_AXI_RDATA),
        .s_axi_lite_rready(ctrl_ic_M04_AXI_RREADY),
        .s_axi_lite_rresp(ctrl_ic_M04_AXI_RRESP),
        .s_axi_lite_rvalid(ctrl_ic_M04_AXI_RVALID),
        .s_axi_lite_wdata(ctrl_ic_M04_AXI_WDATA),
        .s_axi_lite_wready(ctrl_ic_M04_AXI_WREADY),
        .s_axi_lite_wvalid(ctrl_ic_M04_AXI_WVALID),
        .s_axis_s2mm_tdata(inference_engine_out_r_TDATA),
        .s_axis_s2mm_tkeep({1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .s_axis_s2mm_tlast(inference_engine_out_r_TLAST),
        .s_axis_s2mm_tready(inference_engine_out_r_TREADY),
        .s_axis_s2mm_tvalid(inference_engine_out_r_TVALID));
  av_system_inference_engine_0 inference_engine
       (.ap_clk(ps7_FCLK_CLK0),
        .ap_rst_n(rst_fclk_peripheral_aresetn),
        .in_r_TDATA(infer_dma_M_AXIS_MM2S_TDATA),
        .in_r_TKEEP(infer_dma_M_AXIS_MM2S_TKEEP),
        .in_r_TLAST(infer_dma_M_AXIS_MM2S_TLAST),
        .in_r_TREADY(infer_dma_M_AXIS_MM2S_TREADY),
        .in_r_TVALID(infer_dma_M_AXIS_MM2S_TVALID),
        .out_r_TDATA(inference_engine_out_r_TDATA),
        .out_r_TLAST(inference_engine_out_r_TLAST),
        .out_r_TREADY(inference_engine_out_r_TREADY),
        .out_r_TVALID(inference_engine_out_r_TVALID),
        .s_axi_control_ARADDR(ctrl_ic_M05_AXI_ARADDR[6:0]),
        .s_axi_control_ARREADY(ctrl_ic_M05_AXI_ARREADY),
        .s_axi_control_ARVALID(ctrl_ic_M05_AXI_ARVALID),
        .s_axi_control_AWADDR(ctrl_ic_M05_AXI_AWADDR[6:0]),
        .s_axi_control_AWREADY(ctrl_ic_M05_AXI_AWREADY),
        .s_axi_control_AWVALID(ctrl_ic_M05_AXI_AWVALID),
        .s_axi_control_BREADY(ctrl_ic_M05_AXI_BREADY),
        .s_axi_control_BRESP(ctrl_ic_M05_AXI_BRESP),
        .s_axi_control_BVALID(ctrl_ic_M05_AXI_BVALID),
        .s_axi_control_RDATA(ctrl_ic_M05_AXI_RDATA),
        .s_axi_control_RREADY(ctrl_ic_M05_AXI_RREADY),
        .s_axi_control_RRESP(ctrl_ic_M05_AXI_RRESP),
        .s_axi_control_RVALID(ctrl_ic_M05_AXI_RVALID),
        .s_axi_control_WDATA(ctrl_ic_M05_AXI_WDATA),
        .s_axi_control_WREADY(ctrl_ic_M05_AXI_WREADY),
        .s_axi_control_WSTRB(ctrl_ic_M05_AXI_WSTRB),
        .s_axi_control_WVALID(ctrl_ic_M05_AXI_WVALID));
  av_system_inference_memory_0 inference_memory
       (.ACLK(ps7_FCLK_CLK0),
        .ARESETN(rst_fclk_interconnect_aresetn),
        .M00_ACLK(ps7_FCLK_CLK0),
        .M00_ARESETN(rst_fclk_peripheral_aresetn),
        .M00_AXI_araddr(inference_memory_M00_AXI_ARADDR),
        .M00_AXI_arburst(inference_memory_M00_AXI_ARBURST),
        .M00_AXI_arcache(inference_memory_M00_AXI_ARCACHE),
        .M00_AXI_arid(inference_memory_M00_AXI_ARID),
        .M00_AXI_arlen(inference_memory_M00_AXI_ARLEN),
        .M00_AXI_arlock(inference_memory_M00_AXI_ARLOCK),
        .M00_AXI_arprot(inference_memory_M00_AXI_ARPROT),
        .M00_AXI_arqos(inference_memory_M00_AXI_ARQOS),
        .M00_AXI_arready(inference_memory_M00_AXI_ARREADY),
        .M00_AXI_arsize(inference_memory_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(inference_memory_M00_AXI_ARVALID),
        .M00_AXI_awaddr(inference_memory_M00_AXI_AWADDR),
        .M00_AXI_awburst(inference_memory_M00_AXI_AWBURST),
        .M00_AXI_awcache(inference_memory_M00_AXI_AWCACHE),
        .M00_AXI_awid(inference_memory_M00_AXI_AWID),
        .M00_AXI_awlen(inference_memory_M00_AXI_AWLEN),
        .M00_AXI_awlock(inference_memory_M00_AXI_AWLOCK),
        .M00_AXI_awprot(inference_memory_M00_AXI_AWPROT),
        .M00_AXI_awqos(inference_memory_M00_AXI_AWQOS),
        .M00_AXI_awready(inference_memory_M00_AXI_AWREADY),
        .M00_AXI_awsize(inference_memory_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(inference_memory_M00_AXI_AWVALID),
        .M00_AXI_bid(inference_memory_M00_AXI_BID),
        .M00_AXI_bready(inference_memory_M00_AXI_BREADY),
        .M00_AXI_bresp(inference_memory_M00_AXI_BRESP),
        .M00_AXI_bvalid(inference_memory_M00_AXI_BVALID),
        .M00_AXI_rdata(inference_memory_M00_AXI_RDATA),
        .M00_AXI_rid(inference_memory_M00_AXI_RID),
        .M00_AXI_rlast(inference_memory_M00_AXI_RLAST),
        .M00_AXI_rready(inference_memory_M00_AXI_RREADY),
        .M00_AXI_rresp(inference_memory_M00_AXI_RRESP),
        .M00_AXI_rvalid(inference_memory_M00_AXI_RVALID),
        .M00_AXI_wdata(inference_memory_M00_AXI_WDATA),
        .M00_AXI_wid(inference_memory_M00_AXI_WID),
        .M00_AXI_wlast(inference_memory_M00_AXI_WLAST),
        .M00_AXI_wready(inference_memory_M00_AXI_WREADY),
        .M00_AXI_wstrb(inference_memory_M00_AXI_WSTRB),
        .M00_AXI_wvalid(inference_memory_M00_AXI_WVALID),
        .S00_ACLK(ps7_FCLK_CLK0),
        .S00_ARESETN(rst_fclk_peripheral_aresetn),
        .S00_AXI_araddr(infer_dma_M_AXI_MM2S_ARADDR),
        .S00_AXI_arburst(infer_dma_M_AXI_MM2S_ARBURST),
        .S00_AXI_arcache(infer_dma_M_AXI_MM2S_ARCACHE),
        .S00_AXI_arlen(infer_dma_M_AXI_MM2S_ARLEN),
        .S00_AXI_arprot(infer_dma_M_AXI_MM2S_ARPROT),
        .S00_AXI_arready(infer_dma_M_AXI_MM2S_ARREADY),
        .S00_AXI_arsize(infer_dma_M_AXI_MM2S_ARSIZE),
        .S00_AXI_arvalid(infer_dma_M_AXI_MM2S_ARVALID),
        .S00_AXI_rdata(infer_dma_M_AXI_MM2S_RDATA),
        .S00_AXI_rlast(infer_dma_M_AXI_MM2S_RLAST),
        .S00_AXI_rready(infer_dma_M_AXI_MM2S_RREADY),
        .S00_AXI_rresp(infer_dma_M_AXI_MM2S_RRESP),
        .S00_AXI_rvalid(infer_dma_M_AXI_MM2S_RVALID),
        .S01_ACLK(ps7_FCLK_CLK0),
        .S01_ARESETN(rst_fclk_peripheral_aresetn),
        .S01_AXI_awaddr(infer_dma_M_AXI_S2MM_AWADDR),
        .S01_AXI_awburst(infer_dma_M_AXI_S2MM_AWBURST),
        .S01_AXI_awcache(infer_dma_M_AXI_S2MM_AWCACHE),
        .S01_AXI_awlen(infer_dma_M_AXI_S2MM_AWLEN),
        .S01_AXI_awprot(infer_dma_M_AXI_S2MM_AWPROT),
        .S01_AXI_awready(infer_dma_M_AXI_S2MM_AWREADY),
        .S01_AXI_awsize(infer_dma_M_AXI_S2MM_AWSIZE),
        .S01_AXI_awvalid(infer_dma_M_AXI_S2MM_AWVALID),
        .S01_AXI_bready(infer_dma_M_AXI_S2MM_BREADY),
        .S01_AXI_bresp(infer_dma_M_AXI_S2MM_BRESP),
        .S01_AXI_bvalid(infer_dma_M_AXI_S2MM_BVALID),
        .S01_AXI_wdata(infer_dma_M_AXI_S2MM_WDATA),
        .S01_AXI_wlast(infer_dma_M_AXI_S2MM_WLAST),
        .S01_AXI_wready(infer_dma_M_AXI_S2MM_WREADY),
        .S01_AXI_wstrb(infer_dma_M_AXI_S2MM_WSTRB),
        .S01_AXI_wvalid(infer_dma_M_AXI_S2MM_WVALID));
  av_system_irq_concat_0 irq_concat
       (.In0(vdma_s2mm_introut),
        .In1(dma_s2mm_introut),
        .dout(irq_concat_dout));
  av_system_mel_core_0 mel_core
       (.aclk(ps7_FCLK_CLK0),
        .aresetn(rst_fclk_peripheral_aresetn),
        .m_axis_tdata(mel_core_M_AXIS_TDATA),
        .m_axis_tlast(mel_core_M_AXIS_TLAST),
        .m_axis_tready(mel_core_M_AXIS_TREADY),
        .m_axis_tvalid(mel_core_M_AXIS_TVALID),
        .s_axis_tdata(mel_dma_M_AXIS_MM2S_TDATA),
        .s_axis_tlast(mel_dma_M_AXIS_MM2S_TLAST),
        .s_axis_tready(mel_dma_M_AXIS_MM2S_TREADY),
        .s_axis_tvalid(mel_dma_M_AXIS_MM2S_TVALID));
  av_system_mel_dma_0 mel_dma
       (.axi_resetn(rst_fclk_peripheral_aresetn),
        .m_axi_mm2s_aclk(ps7_FCLK_CLK0),
        .m_axi_mm2s_araddr(mel_dma_M_AXI_MM2S_ARADDR),
        .m_axi_mm2s_arburst(mel_dma_M_AXI_MM2S_ARBURST),
        .m_axi_mm2s_arcache(mel_dma_M_AXI_MM2S_ARCACHE),
        .m_axi_mm2s_arlen(mel_dma_M_AXI_MM2S_ARLEN),
        .m_axi_mm2s_arprot(mel_dma_M_AXI_MM2S_ARPROT),
        .m_axi_mm2s_arready(mel_dma_M_AXI_MM2S_ARREADY),
        .m_axi_mm2s_arsize(mel_dma_M_AXI_MM2S_ARSIZE),
        .m_axi_mm2s_arvalid(mel_dma_M_AXI_MM2S_ARVALID),
        .m_axi_mm2s_rdata(mel_dma_M_AXI_MM2S_RDATA),
        .m_axi_mm2s_rlast(mel_dma_M_AXI_MM2S_RLAST),
        .m_axi_mm2s_rready(mel_dma_M_AXI_MM2S_RREADY),
        .m_axi_mm2s_rresp(mel_dma_M_AXI_MM2S_RRESP),
        .m_axi_mm2s_rvalid(mel_dma_M_AXI_MM2S_RVALID),
        .m_axi_s2mm_aclk(ps7_FCLK_CLK0),
        .m_axi_s2mm_awaddr(mel_dma_M_AXI_S2MM_AWADDR),
        .m_axi_s2mm_awburst(mel_dma_M_AXI_S2MM_AWBURST),
        .m_axi_s2mm_awcache(mel_dma_M_AXI_S2MM_AWCACHE),
        .m_axi_s2mm_awlen(mel_dma_M_AXI_S2MM_AWLEN),
        .m_axi_s2mm_awprot(mel_dma_M_AXI_S2MM_AWPROT),
        .m_axi_s2mm_awready(mel_dma_M_AXI_S2MM_AWREADY),
        .m_axi_s2mm_awsize(mel_dma_M_AXI_S2MM_AWSIZE),
        .m_axi_s2mm_awvalid(mel_dma_M_AXI_S2MM_AWVALID),
        .m_axi_s2mm_bready(mel_dma_M_AXI_S2MM_BREADY),
        .m_axi_s2mm_bresp(mel_dma_M_AXI_S2MM_BRESP),
        .m_axi_s2mm_bvalid(mel_dma_M_AXI_S2MM_BVALID),
        .m_axi_s2mm_wdata(mel_dma_M_AXI_S2MM_WDATA),
        .m_axi_s2mm_wlast(mel_dma_M_AXI_S2MM_WLAST),
        .m_axi_s2mm_wready(mel_dma_M_AXI_S2MM_WREADY),
        .m_axi_s2mm_wstrb(mel_dma_M_AXI_S2MM_WSTRB),
        .m_axi_s2mm_wvalid(mel_dma_M_AXI_S2MM_WVALID),
        .m_axis_mm2s_tdata(mel_dma_M_AXIS_MM2S_TDATA),
        .m_axis_mm2s_tlast(mel_dma_M_AXIS_MM2S_TLAST),
        .m_axis_mm2s_tready(mel_dma_M_AXIS_MM2S_TREADY),
        .m_axis_mm2s_tvalid(mel_dma_M_AXIS_MM2S_TVALID),
        .s_axi_lite_aclk(ps7_FCLK_CLK0),
        .s_axi_lite_araddr(ctrl_ic_M06_AXI_ARADDR[9:0]),
        .s_axi_lite_arready(ctrl_ic_M06_AXI_ARREADY),
        .s_axi_lite_arvalid(ctrl_ic_M06_AXI_ARVALID),
        .s_axi_lite_awaddr(ctrl_ic_M06_AXI_AWADDR[9:0]),
        .s_axi_lite_awready(ctrl_ic_M06_AXI_AWREADY),
        .s_axi_lite_awvalid(ctrl_ic_M06_AXI_AWVALID),
        .s_axi_lite_bready(ctrl_ic_M06_AXI_BREADY),
        .s_axi_lite_bresp(ctrl_ic_M06_AXI_BRESP),
        .s_axi_lite_bvalid(ctrl_ic_M06_AXI_BVALID),
        .s_axi_lite_rdata(ctrl_ic_M06_AXI_RDATA),
        .s_axi_lite_rready(ctrl_ic_M06_AXI_RREADY),
        .s_axi_lite_rresp(ctrl_ic_M06_AXI_RRESP),
        .s_axi_lite_rvalid(ctrl_ic_M06_AXI_RVALID),
        .s_axi_lite_wdata(ctrl_ic_M06_AXI_WDATA),
        .s_axi_lite_wready(ctrl_ic_M06_AXI_WREADY),
        .s_axi_lite_wvalid(ctrl_ic_M06_AXI_WVALID),
        .s_axis_s2mm_tdata(mel_core_M_AXIS_TDATA),
        .s_axis_s2mm_tkeep({1'b1,1'b1,1'b1,1'b1}),
        .s_axis_s2mm_tlast(mel_core_M_AXIS_TLAST),
        .s_axis_s2mm_tready(mel_core_M_AXIS_TREADY),
        .s_axis_s2mm_tvalid(mel_core_M_AXIS_TVALID));
  av_system_mel_memory_0 mel_memory
       (.ACLK(ps7_FCLK_CLK0),
        .ARESETN(rst_fclk_interconnect_aresetn),
        .M00_ACLK(ps7_FCLK_CLK0),
        .M00_ARESETN(rst_fclk_peripheral_aresetn),
        .M00_AXI_araddr(mel_memory_M00_AXI_ARADDR),
        .M00_AXI_arburst(mel_memory_M00_AXI_ARBURST),
        .M00_AXI_arcache(mel_memory_M00_AXI_ARCACHE),
        .M00_AXI_arid(mel_memory_M00_AXI_ARID),
        .M00_AXI_arlen(mel_memory_M00_AXI_ARLEN),
        .M00_AXI_arlock(mel_memory_M00_AXI_ARLOCK),
        .M00_AXI_arprot(mel_memory_M00_AXI_ARPROT),
        .M00_AXI_arqos(mel_memory_M00_AXI_ARQOS),
        .M00_AXI_arready(mel_memory_M00_AXI_ARREADY),
        .M00_AXI_arsize(mel_memory_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(mel_memory_M00_AXI_ARVALID),
        .M00_AXI_awaddr(mel_memory_M00_AXI_AWADDR),
        .M00_AXI_awburst(mel_memory_M00_AXI_AWBURST),
        .M00_AXI_awcache(mel_memory_M00_AXI_AWCACHE),
        .M00_AXI_awid(mel_memory_M00_AXI_AWID),
        .M00_AXI_awlen(mel_memory_M00_AXI_AWLEN),
        .M00_AXI_awlock(mel_memory_M00_AXI_AWLOCK),
        .M00_AXI_awprot(mel_memory_M00_AXI_AWPROT),
        .M00_AXI_awqos(mel_memory_M00_AXI_AWQOS),
        .M00_AXI_awready(mel_memory_M00_AXI_AWREADY),
        .M00_AXI_awsize(mel_memory_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(mel_memory_M00_AXI_AWVALID),
        .M00_AXI_bid(mel_memory_M00_AXI_BID),
        .M00_AXI_bready(mel_memory_M00_AXI_BREADY),
        .M00_AXI_bresp(mel_memory_M00_AXI_BRESP),
        .M00_AXI_bvalid(mel_memory_M00_AXI_BVALID),
        .M00_AXI_rdata(mel_memory_M00_AXI_RDATA),
        .M00_AXI_rid(mel_memory_M00_AXI_RID),
        .M00_AXI_rlast(mel_memory_M00_AXI_RLAST),
        .M00_AXI_rready(mel_memory_M00_AXI_RREADY),
        .M00_AXI_rresp(mel_memory_M00_AXI_RRESP),
        .M00_AXI_rvalid(mel_memory_M00_AXI_RVALID),
        .M00_AXI_wdata(mel_memory_M00_AXI_WDATA),
        .M00_AXI_wid(mel_memory_M00_AXI_WID),
        .M00_AXI_wlast(mel_memory_M00_AXI_WLAST),
        .M00_AXI_wready(mel_memory_M00_AXI_WREADY),
        .M00_AXI_wstrb(mel_memory_M00_AXI_WSTRB),
        .M00_AXI_wvalid(mel_memory_M00_AXI_WVALID),
        .S00_ACLK(ps7_FCLK_CLK0),
        .S00_ARESETN(rst_fclk_peripheral_aresetn),
        .S00_AXI_araddr(mel_dma_M_AXI_MM2S_ARADDR),
        .S00_AXI_arburst(mel_dma_M_AXI_MM2S_ARBURST),
        .S00_AXI_arcache(mel_dma_M_AXI_MM2S_ARCACHE),
        .S00_AXI_arlen(mel_dma_M_AXI_MM2S_ARLEN),
        .S00_AXI_arprot(mel_dma_M_AXI_MM2S_ARPROT),
        .S00_AXI_arready(mel_dma_M_AXI_MM2S_ARREADY),
        .S00_AXI_arsize(mel_dma_M_AXI_MM2S_ARSIZE),
        .S00_AXI_arvalid(mel_dma_M_AXI_MM2S_ARVALID),
        .S00_AXI_rdata(mel_dma_M_AXI_MM2S_RDATA),
        .S00_AXI_rlast(mel_dma_M_AXI_MM2S_RLAST),
        .S00_AXI_rready(mel_dma_M_AXI_MM2S_RREADY),
        .S00_AXI_rresp(mel_dma_M_AXI_MM2S_RRESP),
        .S00_AXI_rvalid(mel_dma_M_AXI_MM2S_RVALID),
        .S01_ACLK(ps7_FCLK_CLK0),
        .S01_ARESETN(rst_fclk_peripheral_aresetn),
        .S01_AXI_awaddr(mel_dma_M_AXI_S2MM_AWADDR),
        .S01_AXI_awburst(mel_dma_M_AXI_S2MM_AWBURST),
        .S01_AXI_awcache(mel_dma_M_AXI_S2MM_AWCACHE),
        .S01_AXI_awlen(mel_dma_M_AXI_S2MM_AWLEN),
        .S01_AXI_awprot(mel_dma_M_AXI_S2MM_AWPROT),
        .S01_AXI_awready(mel_dma_M_AXI_S2MM_AWREADY),
        .S01_AXI_awsize(mel_dma_M_AXI_S2MM_AWSIZE),
        .S01_AXI_awvalid(mel_dma_M_AXI_S2MM_AWVALID),
        .S01_AXI_bready(mel_dma_M_AXI_S2MM_BREADY),
        .S01_AXI_bresp(mel_dma_M_AXI_S2MM_BRESP),
        .S01_AXI_bvalid(mel_dma_M_AXI_S2MM_BVALID),
        .S01_AXI_wdata(mel_dma_M_AXI_S2MM_WDATA),
        .S01_AXI_wlast(mel_dma_M_AXI_S2MM_WLAST),
        .S01_AXI_wready(mel_dma_M_AXI_S2MM_WREADY),
        .S01_AXI_wstrb(mel_dma_M_AXI_S2MM_WSTRB),
        .S01_AXI_wvalid(mel_dma_M_AXI_S2MM_WVALID),
        .S02_ACLK(ps7_FCLK_CLK0),
        .S02_ARESETN(rst_fclk_peripheral_aresetn),
        .S02_AXI_araddr(ssd_dma_M_AXI_MM2S_ARADDR),
        .S02_AXI_arburst(ssd_dma_M_AXI_MM2S_ARBURST),
        .S02_AXI_arcache(ssd_dma_M_AXI_MM2S_ARCACHE),
        .S02_AXI_arlen(ssd_dma_M_AXI_MM2S_ARLEN),
        .S02_AXI_arprot(ssd_dma_M_AXI_MM2S_ARPROT),
        .S02_AXI_arready(ssd_dma_M_AXI_MM2S_ARREADY),
        .S02_AXI_arsize(ssd_dma_M_AXI_MM2S_ARSIZE),
        .S02_AXI_arvalid(ssd_dma_M_AXI_MM2S_ARVALID),
        .S02_AXI_rdata(ssd_dma_M_AXI_MM2S_RDATA),
        .S02_AXI_rlast(ssd_dma_M_AXI_MM2S_RLAST),
        .S02_AXI_rready(ssd_dma_M_AXI_MM2S_RREADY),
        .S02_AXI_rresp(ssd_dma_M_AXI_MM2S_RRESP),
        .S02_AXI_rvalid(ssd_dma_M_AXI_MM2S_RVALID),
        .S03_ACLK(ps7_FCLK_CLK0),
        .S03_ARESETN(rst_fclk_peripheral_aresetn),
        .S03_AXI_awaddr(ssd_dma_M_AXI_S2MM_AWADDR),
        .S03_AXI_awburst(ssd_dma_M_AXI_S2MM_AWBURST),
        .S03_AXI_awcache(ssd_dma_M_AXI_S2MM_AWCACHE),
        .S03_AXI_awlen(ssd_dma_M_AXI_S2MM_AWLEN),
        .S03_AXI_awprot(ssd_dma_M_AXI_S2MM_AWPROT),
        .S03_AXI_awready(ssd_dma_M_AXI_S2MM_AWREADY),
        .S03_AXI_awsize(ssd_dma_M_AXI_S2MM_AWSIZE),
        .S03_AXI_awvalid(ssd_dma_M_AXI_S2MM_AWVALID),
        .S03_AXI_bready(ssd_dma_M_AXI_S2MM_BREADY),
        .S03_AXI_bresp(ssd_dma_M_AXI_S2MM_BRESP),
        .S03_AXI_bvalid(ssd_dma_M_AXI_S2MM_BVALID),
        .S03_AXI_wdata(ssd_dma_M_AXI_S2MM_WDATA),
        .S03_AXI_wlast(ssd_dma_M_AXI_S2MM_WLAST),
        .S03_AXI_wready(ssd_dma_M_AXI_S2MM_WREADY),
        .S03_AXI_wstrb(ssd_dma_M_AXI_S2MM_WSTRB),
        .S03_AXI_wvalid(ssd_dma_M_AXI_S2MM_WVALID));
  av_system_model_ingress_0 model_ingress
       (.mel_clk(clk_audio_clk_out1),
        .mel_resetn(rst_audio_peripheral_aresetn),
        .s_axis_mel_tdata(audio_m_axis_model_mel_TDATA),
        .s_axis_mel_tlast(audio_m_axis_model_mel_TLAST),
        .s_axis_mel_tready(audio_m_axis_model_mel_TREADY),
        .s_axis_mel_tuser(audio_m_axis_model_mel_TUSER),
        .s_axis_mel_tvalid(audio_m_axis_model_mel_TVALID),
        .s_axis_video_tdata(camera_m_axis_model_video_TDATA),
        .s_axis_video_tlast(camera_m_axis_model_video_TLAST),
        .s_axis_video_tready(camera_m_axis_model_video_TREADY),
        .s_axis_video_tuser(camera_m_axis_model_video_TUSER),
        .s_axis_video_tvalid(camera_m_axis_model_video_TVALID),
        .video_clk(cam_pclk_1),
        .video_resetn(rst_pixel_peripheral_aresetn));
  av_system_pcm_cdc_0 pcm_cdc
       (.m_axis_aclk(ps7_FCLK_CLK0),
        .m_axis_aresetn(rst_fclk_peripheral_aresetn),
        .m_axis_tdata(pcm_cdc_M_AXIS_TDATA),
        .m_axis_tkeep(pcm_cdc_M_AXIS_TKEEP),
        .m_axis_tlast(pcm_cdc_M_AXIS_TLAST),
        .m_axis_tready(pcm_cdc_M_AXIS_TREADY),
        .m_axis_tvalid(pcm_cdc_M_AXIS_TVALID),
        .s_axis_aclk(clk_audio_clk_out1),
        .s_axis_aresetn(rst_audio_peripheral_aresetn),
        .s_axis_tdata(audio_m_axis_pcm_TDATA),
        .s_axis_tkeep(audio_m_axis_pcm_TKEEP),
        .s_axis_tlast(audio_m_axis_pcm_TLAST),
        .s_axis_tready(audio_m_axis_pcm_TREADY),
        .s_axis_tvalid(audio_m_axis_pcm_TVALID));
  av_system_ps7_0 ps7
       (.DDR_Addr(DDR_addr[14:0]),
        .DDR_BankAddr(DDR_ba[2:0]),
        .DDR_CAS_n(DDR_cas_n),
        .DDR_CKE(DDR_cke),
        .DDR_CS_n(DDR_cs_n),
        .DDR_Clk(DDR_ck_p),
        .DDR_Clk_n(DDR_ck_n),
        .DDR_DM(DDR_dm[3:0]),
        .DDR_DQ(DDR_dq[31:0]),
        .DDR_DQS(DDR_dqs_p[3:0]),
        .DDR_DQS_n(DDR_dqs_n[3:0]),
        .DDR_DRSTB(DDR_reset_n),
        .DDR_ODT(DDR_odt),
        .DDR_RAS_n(DDR_ras_n),
        .DDR_VRN(FIXED_IO_ddr_vrn),
        .DDR_VRP(FIXED_IO_ddr_vrp),
        .DDR_WEB(DDR_we_n),
        .FCLK_CLK0(ps7_FCLK_CLK0),
        .FCLK_RESET0_N(ps7_FCLK_RESET0_N),
        .IRQ_F2P(irq_concat_dout),
        .MIO(FIXED_IO_mio[53:0]),
        .M_AXI_GP0_ACLK(ps7_FCLK_CLK0),
        .M_AXI_GP0_ARADDR(ps7_M_AXI_GP0_ARADDR),
        .M_AXI_GP0_ARBURST(ps7_M_AXI_GP0_ARBURST),
        .M_AXI_GP0_ARCACHE(ps7_M_AXI_GP0_ARCACHE),
        .M_AXI_GP0_ARID(ps7_M_AXI_GP0_ARID),
        .M_AXI_GP0_ARLEN(ps7_M_AXI_GP0_ARLEN),
        .M_AXI_GP0_ARLOCK(ps7_M_AXI_GP0_ARLOCK),
        .M_AXI_GP0_ARPROT(ps7_M_AXI_GP0_ARPROT),
        .M_AXI_GP0_ARQOS(ps7_M_AXI_GP0_ARQOS),
        .M_AXI_GP0_ARREADY(ps7_M_AXI_GP0_ARREADY),
        .M_AXI_GP0_ARSIZE(ps7_M_AXI_GP0_ARSIZE),
        .M_AXI_GP0_ARVALID(ps7_M_AXI_GP0_ARVALID),
        .M_AXI_GP0_AWADDR(ps7_M_AXI_GP0_AWADDR),
        .M_AXI_GP0_AWBURST(ps7_M_AXI_GP0_AWBURST),
        .M_AXI_GP0_AWCACHE(ps7_M_AXI_GP0_AWCACHE),
        .M_AXI_GP0_AWID(ps7_M_AXI_GP0_AWID),
        .M_AXI_GP0_AWLEN(ps7_M_AXI_GP0_AWLEN),
        .M_AXI_GP0_AWLOCK(ps7_M_AXI_GP0_AWLOCK),
        .M_AXI_GP0_AWPROT(ps7_M_AXI_GP0_AWPROT),
        .M_AXI_GP0_AWQOS(ps7_M_AXI_GP0_AWQOS),
        .M_AXI_GP0_AWREADY(ps7_M_AXI_GP0_AWREADY),
        .M_AXI_GP0_AWSIZE(ps7_M_AXI_GP0_AWSIZE),
        .M_AXI_GP0_AWVALID(ps7_M_AXI_GP0_AWVALID),
        .M_AXI_GP0_BID(ps7_M_AXI_GP0_BID),
        .M_AXI_GP0_BREADY(ps7_M_AXI_GP0_BREADY),
        .M_AXI_GP0_BRESP(ps7_M_AXI_GP0_BRESP),
        .M_AXI_GP0_BVALID(ps7_M_AXI_GP0_BVALID),
        .M_AXI_GP0_RDATA(ps7_M_AXI_GP0_RDATA),
        .M_AXI_GP0_RID(ps7_M_AXI_GP0_RID),
        .M_AXI_GP0_RLAST(ps7_M_AXI_GP0_RLAST),
        .M_AXI_GP0_RREADY(ps7_M_AXI_GP0_RREADY),
        .M_AXI_GP0_RRESP(ps7_M_AXI_GP0_RRESP),
        .M_AXI_GP0_RVALID(ps7_M_AXI_GP0_RVALID),
        .M_AXI_GP0_WDATA(ps7_M_AXI_GP0_WDATA),
        .M_AXI_GP0_WID(ps7_M_AXI_GP0_WID),
        .M_AXI_GP0_WLAST(ps7_M_AXI_GP0_WLAST),
        .M_AXI_GP0_WREADY(ps7_M_AXI_GP0_WREADY),
        .M_AXI_GP0_WSTRB(ps7_M_AXI_GP0_WSTRB),
        .M_AXI_GP0_WVALID(ps7_M_AXI_GP0_WVALID),
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb),
        .S_AXI_HP0_ACLK(ps7_FCLK_CLK0),
        .S_AXI_HP0_ARADDR(hdmi_memory_M00_AXI_ARADDR),
        .S_AXI_HP0_ARBURST(hdmi_memory_M00_AXI_ARBURST),
        .S_AXI_HP0_ARCACHE(hdmi_memory_M00_AXI_ARCACHE),
        .S_AXI_HP0_ARID({1'b0,1'b0,1'b0,1'b0,1'b0,hdmi_memory_M00_AXI_ARID}),
        .S_AXI_HP0_ARLEN(hdmi_memory_M00_AXI_ARLEN),
        .S_AXI_HP0_ARLOCK(hdmi_memory_M00_AXI_ARLOCK),
        .S_AXI_HP0_ARPROT(hdmi_memory_M00_AXI_ARPROT),
        .S_AXI_HP0_ARQOS(hdmi_memory_M00_AXI_ARQOS),
        .S_AXI_HP0_ARREADY(hdmi_memory_M00_AXI_ARREADY),
        .S_AXI_HP0_ARSIZE(hdmi_memory_M00_AXI_ARSIZE),
        .S_AXI_HP0_ARVALID(hdmi_memory_M00_AXI_ARVALID),
        .S_AXI_HP0_AWADDR(hdmi_memory_M00_AXI_AWADDR),
        .S_AXI_HP0_AWBURST(hdmi_memory_M00_AXI_AWBURST),
        .S_AXI_HP0_AWCACHE(hdmi_memory_M00_AXI_AWCACHE),
        .S_AXI_HP0_AWID({1'b0,1'b0,1'b0,1'b0,1'b0,hdmi_memory_M00_AXI_AWID}),
        .S_AXI_HP0_AWLEN(hdmi_memory_M00_AXI_AWLEN),
        .S_AXI_HP0_AWLOCK(hdmi_memory_M00_AXI_AWLOCK),
        .S_AXI_HP0_AWPROT(hdmi_memory_M00_AXI_AWPROT),
        .S_AXI_HP0_AWQOS(hdmi_memory_M00_AXI_AWQOS),
        .S_AXI_HP0_AWREADY(hdmi_memory_M00_AXI_AWREADY),
        .S_AXI_HP0_AWSIZE(hdmi_memory_M00_AXI_AWSIZE),
        .S_AXI_HP0_AWVALID(hdmi_memory_M00_AXI_AWVALID),
        .S_AXI_HP0_BID(hdmi_memory_M00_AXI_BID),
        .S_AXI_HP0_BREADY(hdmi_memory_M00_AXI_BREADY),
        .S_AXI_HP0_BRESP(hdmi_memory_M00_AXI_BRESP),
        .S_AXI_HP0_BVALID(hdmi_memory_M00_AXI_BVALID),
        .S_AXI_HP0_RDATA(hdmi_memory_M00_AXI_RDATA),
        .S_AXI_HP0_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP0_RID(hdmi_memory_M00_AXI_RID),
        .S_AXI_HP0_RLAST(hdmi_memory_M00_AXI_RLAST),
        .S_AXI_HP0_RREADY(hdmi_memory_M00_AXI_RREADY),
        .S_AXI_HP0_RRESP(hdmi_memory_M00_AXI_RRESP),
        .S_AXI_HP0_RVALID(hdmi_memory_M00_AXI_RVALID),
        .S_AXI_HP0_WDATA(hdmi_memory_M00_AXI_WDATA),
        .S_AXI_HP0_WID({1'b0,1'b0,1'b0,1'b0,1'b0,hdmi_memory_M00_AXI_WID}),
        .S_AXI_HP0_WLAST(hdmi_memory_M00_AXI_WLAST),
        .S_AXI_HP0_WREADY(hdmi_memory_M00_AXI_WREADY),
        .S_AXI_HP0_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP0_WSTRB(hdmi_memory_M00_AXI_WSTRB),
        .S_AXI_HP0_WVALID(hdmi_memory_M00_AXI_WVALID),
        .S_AXI_HP1_ACLK(ps7_FCLK_CLK0),
        .S_AXI_HP1_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP1_ARBURST({1'b0,1'b1}),
        .S_AXI_HP1_ARCACHE({1'b0,1'b0,1'b1,1'b1}),
        .S_AXI_HP1_ARID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP1_ARLEN({1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP1_ARLOCK({1'b0,1'b0}),
        .S_AXI_HP1_ARPROT({1'b0,1'b0,1'b0}),
        .S_AXI_HP1_ARQOS({1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP1_ARSIZE({1'b0,1'b1,1'b1}),
        .S_AXI_HP1_ARVALID(1'b0),
        .S_AXI_HP1_AWADDR(dma_proto_M_AXI_AWADDR),
        .S_AXI_HP1_AWBURST(dma_proto_M_AXI_AWBURST),
        .S_AXI_HP1_AWCACHE(dma_proto_M_AXI_AWCACHE),
        .S_AXI_HP1_AWID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP1_AWLEN(dma_proto_M_AXI_AWLEN),
        .S_AXI_HP1_AWLOCK(dma_proto_M_AXI_AWLOCK),
        .S_AXI_HP1_AWPROT(dma_proto_M_AXI_AWPROT),
        .S_AXI_HP1_AWQOS(dma_proto_M_AXI_AWQOS),
        .S_AXI_HP1_AWREADY(dma_proto_M_AXI_AWREADY),
        .S_AXI_HP1_AWSIZE(dma_proto_M_AXI_AWSIZE),
        .S_AXI_HP1_AWVALID(dma_proto_M_AXI_AWVALID),
        .S_AXI_HP1_BREADY(dma_proto_M_AXI_BREADY),
        .S_AXI_HP1_BRESP(dma_proto_M_AXI_BRESP),
        .S_AXI_HP1_BVALID(dma_proto_M_AXI_BVALID),
        .S_AXI_HP1_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP1_RREADY(1'b0),
        .S_AXI_HP1_WDATA(dma_proto_M_AXI_WDATA),
        .S_AXI_HP1_WID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP1_WLAST(dma_proto_M_AXI_WLAST),
        .S_AXI_HP1_WREADY(dma_proto_M_AXI_WREADY),
        .S_AXI_HP1_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP1_WSTRB(dma_proto_M_AXI_WSTRB),
        .S_AXI_HP1_WVALID(dma_proto_M_AXI_WVALID),
        .S_AXI_HP2_ACLK(ps7_FCLK_CLK0),
        .S_AXI_HP2_ARADDR(inference_memory_M00_AXI_ARADDR),
        .S_AXI_HP2_ARBURST(inference_memory_M00_AXI_ARBURST),
        .S_AXI_HP2_ARCACHE(inference_memory_M00_AXI_ARCACHE),
        .S_AXI_HP2_ARID({1'b0,1'b0,1'b0,1'b0,1'b0,inference_memory_M00_AXI_ARID}),
        .S_AXI_HP2_ARLEN(inference_memory_M00_AXI_ARLEN),
        .S_AXI_HP2_ARLOCK(inference_memory_M00_AXI_ARLOCK),
        .S_AXI_HP2_ARPROT(inference_memory_M00_AXI_ARPROT),
        .S_AXI_HP2_ARQOS(inference_memory_M00_AXI_ARQOS),
        .S_AXI_HP2_ARREADY(inference_memory_M00_AXI_ARREADY),
        .S_AXI_HP2_ARSIZE(inference_memory_M00_AXI_ARSIZE),
        .S_AXI_HP2_ARVALID(inference_memory_M00_AXI_ARVALID),
        .S_AXI_HP2_AWADDR(inference_memory_M00_AXI_AWADDR),
        .S_AXI_HP2_AWBURST(inference_memory_M00_AXI_AWBURST),
        .S_AXI_HP2_AWCACHE(inference_memory_M00_AXI_AWCACHE),
        .S_AXI_HP2_AWID({1'b0,1'b0,1'b0,1'b0,1'b0,inference_memory_M00_AXI_AWID}),
        .S_AXI_HP2_AWLEN(inference_memory_M00_AXI_AWLEN),
        .S_AXI_HP2_AWLOCK(inference_memory_M00_AXI_AWLOCK),
        .S_AXI_HP2_AWPROT(inference_memory_M00_AXI_AWPROT),
        .S_AXI_HP2_AWQOS(inference_memory_M00_AXI_AWQOS),
        .S_AXI_HP2_AWREADY(inference_memory_M00_AXI_AWREADY),
        .S_AXI_HP2_AWSIZE(inference_memory_M00_AXI_AWSIZE),
        .S_AXI_HP2_AWVALID(inference_memory_M00_AXI_AWVALID),
        .S_AXI_HP2_BID(inference_memory_M00_AXI_BID),
        .S_AXI_HP2_BREADY(inference_memory_M00_AXI_BREADY),
        .S_AXI_HP2_BRESP(inference_memory_M00_AXI_BRESP),
        .S_AXI_HP2_BVALID(inference_memory_M00_AXI_BVALID),
        .S_AXI_HP2_RDATA(inference_memory_M00_AXI_RDATA),
        .S_AXI_HP2_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP2_RID(inference_memory_M00_AXI_RID),
        .S_AXI_HP2_RLAST(inference_memory_M00_AXI_RLAST),
        .S_AXI_HP2_RREADY(inference_memory_M00_AXI_RREADY),
        .S_AXI_HP2_RRESP(inference_memory_M00_AXI_RRESP),
        .S_AXI_HP2_RVALID(inference_memory_M00_AXI_RVALID),
        .S_AXI_HP2_WDATA(inference_memory_M00_AXI_WDATA),
        .S_AXI_HP2_WID({1'b0,1'b0,1'b0,1'b0,1'b0,inference_memory_M00_AXI_WID}),
        .S_AXI_HP2_WLAST(inference_memory_M00_AXI_WLAST),
        .S_AXI_HP2_WREADY(inference_memory_M00_AXI_WREADY),
        .S_AXI_HP2_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP2_WSTRB(inference_memory_M00_AXI_WSTRB),
        .S_AXI_HP2_WVALID(inference_memory_M00_AXI_WVALID),
        .S_AXI_HP3_ACLK(ps7_FCLK_CLK0),
        .S_AXI_HP3_ARADDR(mel_memory_M00_AXI_ARADDR),
        .S_AXI_HP3_ARBURST(mel_memory_M00_AXI_ARBURST),
        .S_AXI_HP3_ARCACHE(mel_memory_M00_AXI_ARCACHE),
        .S_AXI_HP3_ARID({1'b0,1'b0,1'b0,1'b0,mel_memory_M00_AXI_ARID}),
        .S_AXI_HP3_ARLEN(mel_memory_M00_AXI_ARLEN),
        .S_AXI_HP3_ARLOCK(mel_memory_M00_AXI_ARLOCK),
        .S_AXI_HP3_ARPROT(mel_memory_M00_AXI_ARPROT),
        .S_AXI_HP3_ARQOS(mel_memory_M00_AXI_ARQOS),
        .S_AXI_HP3_ARREADY(mel_memory_M00_AXI_ARREADY),
        .S_AXI_HP3_ARSIZE(mel_memory_M00_AXI_ARSIZE),
        .S_AXI_HP3_ARVALID(mel_memory_M00_AXI_ARVALID),
        .S_AXI_HP3_AWADDR(mel_memory_M00_AXI_AWADDR),
        .S_AXI_HP3_AWBURST(mel_memory_M00_AXI_AWBURST),
        .S_AXI_HP3_AWCACHE(mel_memory_M00_AXI_AWCACHE),
        .S_AXI_HP3_AWID({1'b0,1'b0,1'b0,1'b0,mel_memory_M00_AXI_AWID}),
        .S_AXI_HP3_AWLEN(mel_memory_M00_AXI_AWLEN),
        .S_AXI_HP3_AWLOCK(mel_memory_M00_AXI_AWLOCK),
        .S_AXI_HP3_AWPROT(mel_memory_M00_AXI_AWPROT),
        .S_AXI_HP3_AWQOS(mel_memory_M00_AXI_AWQOS),
        .S_AXI_HP3_AWREADY(mel_memory_M00_AXI_AWREADY),
        .S_AXI_HP3_AWSIZE(mel_memory_M00_AXI_AWSIZE),
        .S_AXI_HP3_AWVALID(mel_memory_M00_AXI_AWVALID),
        .S_AXI_HP3_BID(mel_memory_M00_AXI_BID),
        .S_AXI_HP3_BREADY(mel_memory_M00_AXI_BREADY),
        .S_AXI_HP3_BRESP(mel_memory_M00_AXI_BRESP),
        .S_AXI_HP3_BVALID(mel_memory_M00_AXI_BVALID),
        .S_AXI_HP3_RDATA(mel_memory_M00_AXI_RDATA),
        .S_AXI_HP3_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP3_RID(mel_memory_M00_AXI_RID),
        .S_AXI_HP3_RLAST(mel_memory_M00_AXI_RLAST),
        .S_AXI_HP3_RREADY(mel_memory_M00_AXI_RREADY),
        .S_AXI_HP3_RRESP(mel_memory_M00_AXI_RRESP),
        .S_AXI_HP3_RVALID(mel_memory_M00_AXI_RVALID),
        .S_AXI_HP3_WDATA(mel_memory_M00_AXI_WDATA),
        .S_AXI_HP3_WID({1'b0,1'b0,1'b0,1'b0,mel_memory_M00_AXI_WID}),
        .S_AXI_HP3_WLAST(mel_memory_M00_AXI_WLAST),
        .S_AXI_HP3_WREADY(mel_memory_M00_AXI_WREADY),
        .S_AXI_HP3_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP3_WSTRB(mel_memory_M00_AXI_WSTRB),
        .S_AXI_HP3_WVALID(mel_memory_M00_AXI_WVALID),
        .USB0_VBUS_PWRFAULT(1'b0));
  av_system_rst_audio_0 rst_audio
       (.aux_reset_in(const_one_dout),
        .dcm_locked(clk_audio_locked),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .mb_debug_sys_rst(const_zero_dout),
        .peripheral_aresetn(rst_audio_peripheral_aresetn),
        .peripheral_reset(rst_audio_peripheral_reset),
        .slowest_sync_clk(clk_audio_clk_out1));
  av_system_rst_fclk_0 rst_fclk
       (.aux_reset_in(const_one_dout),
        .dcm_locked(const_one_dout),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .interconnect_aresetn(rst_fclk_interconnect_aresetn),
        .mb_debug_sys_rst(const_zero_dout),
        .peripheral_aresetn(rst_fclk_peripheral_aresetn),
        .peripheral_reset(rst_fclk_peripheral_reset),
        .slowest_sync_clk(ps7_FCLK_CLK0));
  av_system_rst_hdmi_0 rst_hdmi
       (.aux_reset_in(const_one_dout),
        .dcm_locked(clk_hdmi_locked),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .mb_debug_sys_rst(const_zero_dout),
        .peripheral_aresetn(rst_hdmi_peripheral_aresetn),
        .peripheral_reset(rst_hdmi_peripheral_reset),
        .slowest_sync_clk(clk_hdmi_clk_out1));
  av_system_rst_hdmi_read_0 rst_hdmi_read
       (.aux_reset_in(const_one_dout),
        .dcm_locked(clk_hdmi_locked),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .mb_debug_sys_rst(const_zero_dout),
        .peripheral_aresetn(rst_hdmi_read_peripheral_aresetn),
        .slowest_sync_clk(clk_hdmi_clk_out3));
  av_system_rst_pixel_0 rst_pixel
       (.aux_reset_in(const_one_dout),
        .dcm_locked(const_one_dout),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .mb_debug_sys_rst(const_zero_dout),
        .peripheral_aresetn(rst_pixel_peripheral_aresetn),
        .peripheral_reset(rst_pixel_peripheral_reset),
        .slowest_sync_clk(cam_pclk_1));
  av_system_ssd_dma_0 ssd_dma
       (.axi_resetn(rst_fclk_peripheral_aresetn),
        .m_axi_mm2s_aclk(ps7_FCLK_CLK0),
        .m_axi_mm2s_araddr(ssd_dma_M_AXI_MM2S_ARADDR),
        .m_axi_mm2s_arburst(ssd_dma_M_AXI_MM2S_ARBURST),
        .m_axi_mm2s_arcache(ssd_dma_M_AXI_MM2S_ARCACHE),
        .m_axi_mm2s_arlen(ssd_dma_M_AXI_MM2S_ARLEN),
        .m_axi_mm2s_arprot(ssd_dma_M_AXI_MM2S_ARPROT),
        .m_axi_mm2s_arready(ssd_dma_M_AXI_MM2S_ARREADY),
        .m_axi_mm2s_arsize(ssd_dma_M_AXI_MM2S_ARSIZE),
        .m_axi_mm2s_arvalid(ssd_dma_M_AXI_MM2S_ARVALID),
        .m_axi_mm2s_rdata(ssd_dma_M_AXI_MM2S_RDATA),
        .m_axi_mm2s_rlast(ssd_dma_M_AXI_MM2S_RLAST),
        .m_axi_mm2s_rready(ssd_dma_M_AXI_MM2S_RREADY),
        .m_axi_mm2s_rresp(ssd_dma_M_AXI_MM2S_RRESP),
        .m_axi_mm2s_rvalid(ssd_dma_M_AXI_MM2S_RVALID),
        .m_axi_s2mm_aclk(ps7_FCLK_CLK0),
        .m_axi_s2mm_awaddr(ssd_dma_M_AXI_S2MM_AWADDR),
        .m_axi_s2mm_awburst(ssd_dma_M_AXI_S2MM_AWBURST),
        .m_axi_s2mm_awcache(ssd_dma_M_AXI_S2MM_AWCACHE),
        .m_axi_s2mm_awlen(ssd_dma_M_AXI_S2MM_AWLEN),
        .m_axi_s2mm_awprot(ssd_dma_M_AXI_S2MM_AWPROT),
        .m_axi_s2mm_awready(ssd_dma_M_AXI_S2MM_AWREADY),
        .m_axi_s2mm_awsize(ssd_dma_M_AXI_S2MM_AWSIZE),
        .m_axi_s2mm_awvalid(ssd_dma_M_AXI_S2MM_AWVALID),
        .m_axi_s2mm_bready(ssd_dma_M_AXI_S2MM_BREADY),
        .m_axi_s2mm_bresp(ssd_dma_M_AXI_S2MM_BRESP),
        .m_axi_s2mm_bvalid(ssd_dma_M_AXI_S2MM_BVALID),
        .m_axi_s2mm_wdata(ssd_dma_M_AXI_S2MM_WDATA),
        .m_axi_s2mm_wlast(ssd_dma_M_AXI_S2MM_WLAST),
        .m_axi_s2mm_wready(ssd_dma_M_AXI_S2MM_WREADY),
        .m_axi_s2mm_wstrb(ssd_dma_M_AXI_S2MM_WSTRB),
        .m_axi_s2mm_wvalid(ssd_dma_M_AXI_S2MM_WVALID),
        .m_axis_mm2s_tdata(ssd_dma_M_AXIS_MM2S_TDATA),
        .m_axis_mm2s_tlast(ssd_dma_M_AXIS_MM2S_TLAST),
        .m_axis_mm2s_tready(ssd_dma_M_AXIS_MM2S_TREADY),
        .m_axis_mm2s_tvalid(ssd_dma_M_AXIS_MM2S_TVALID),
        .s_axi_lite_aclk(ps7_FCLK_CLK0),
        .s_axi_lite_araddr(ctrl_ic_M07_AXI_ARADDR[9:0]),
        .s_axi_lite_arready(ctrl_ic_M07_AXI_ARREADY),
        .s_axi_lite_arvalid(ctrl_ic_M07_AXI_ARVALID),
        .s_axi_lite_awaddr(ctrl_ic_M07_AXI_AWADDR[9:0]),
        .s_axi_lite_awready(ctrl_ic_M07_AXI_AWREADY),
        .s_axi_lite_awvalid(ctrl_ic_M07_AXI_AWVALID),
        .s_axi_lite_bready(ctrl_ic_M07_AXI_BREADY),
        .s_axi_lite_bresp(ctrl_ic_M07_AXI_BRESP),
        .s_axi_lite_bvalid(ctrl_ic_M07_AXI_BVALID),
        .s_axi_lite_rdata(ctrl_ic_M07_AXI_RDATA),
        .s_axi_lite_rready(ctrl_ic_M07_AXI_RREADY),
        .s_axi_lite_rresp(ctrl_ic_M07_AXI_RRESP),
        .s_axi_lite_rvalid(ctrl_ic_M07_AXI_RVALID),
        .s_axi_lite_wdata(ctrl_ic_M07_AXI_WDATA),
        .s_axi_lite_wready(ctrl_ic_M07_AXI_WREADY),
        .s_axi_lite_wvalid(ctrl_ic_M07_AXI_WVALID),
        .s_axis_s2mm_tdata(ssd_preprocess_core_M_AXIS_TDATA),
        .s_axis_s2mm_tkeep(ssd_preprocess_core_M_AXIS_TKEEP),
        .s_axis_s2mm_tlast(ssd_preprocess_core_M_AXIS_TLAST),
        .s_axis_s2mm_tready(ssd_preprocess_core_M_AXIS_TREADY),
        .s_axis_s2mm_tvalid(ssd_preprocess_core_M_AXIS_TVALID));
  av_system_ssd_preprocess_core_0 ssd_preprocess_core
       (.aclk(ps7_FCLK_CLK0),
        .aresetn(rst_fclk_peripheral_aresetn),
        .m_axis_tdata(ssd_preprocess_core_M_AXIS_TDATA),
        .m_axis_tkeep(ssd_preprocess_core_M_AXIS_TKEEP),
        .m_axis_tlast(ssd_preprocess_core_M_AXIS_TLAST),
        .m_axis_tready(ssd_preprocess_core_M_AXIS_TREADY),
        .m_axis_tvalid(ssd_preprocess_core_M_AXIS_TVALID),
        .s_axis_tdata(ssd_dma_M_AXIS_MM2S_TDATA),
        .s_axis_tlast(ssd_dma_M_AXIS_MM2S_TLAST),
        .s_axis_tready(ssd_dma_M_AXIS_MM2S_TREADY),
        .s_axis_tvalid(ssd_dma_M_AXIS_MM2S_TVALID));
  av_system_status_cdc_0 status_cdc
       (.dst_clk(clk_audio_clk_out1),
        .dst_dark_ratio(status_cdc_dst_dark_ratio),
        .dst_frame_count(status_cdc_dst_frame_count),
        .dst_mean_y(status_cdc_dst_mean_y),
        .dst_rst(rst_audio_peripheral_reset),
        .dst_strobe(status_cdc_dst_strobe),
        .dst_video_drop(status_cdc_dst_video_drop),
        .src_clk(cam_pclk_1),
        .src_dark_ratio(camera_dark_ratio_q15),
        .src_frame_count(camera_frame_count),
        .src_mean_y(camera_mean_y),
        .src_rst(rst_pixel_peripheral_reset),
        .src_strobe(camera_frame_start),
        .src_video_drop(camera_video_drop_count));
  av_system_vdma_0 vdma
       (.axi_resetn(rst_fclk_peripheral_aresetn),
        .m_axi_mm2s_aclk(clk_hdmi_clk_out3),
        .m_axi_mm2s_araddr(vdma_M_AXI_MM2S_ARADDR),
        .m_axi_mm2s_arburst(vdma_M_AXI_MM2S_ARBURST),
        .m_axi_mm2s_arcache(vdma_M_AXI_MM2S_ARCACHE),
        .m_axi_mm2s_arlen(vdma_M_AXI_MM2S_ARLEN),
        .m_axi_mm2s_arprot(vdma_M_AXI_MM2S_ARPROT),
        .m_axi_mm2s_arready(vdma_M_AXI_MM2S_ARREADY),
        .m_axi_mm2s_arsize(vdma_M_AXI_MM2S_ARSIZE),
        .m_axi_mm2s_arvalid(vdma_M_AXI_MM2S_ARVALID),
        .m_axi_mm2s_rdata(vdma_M_AXI_MM2S_RDATA),
        .m_axi_mm2s_rlast(vdma_M_AXI_MM2S_RLAST),
        .m_axi_mm2s_rready(vdma_M_AXI_MM2S_RREADY),
        .m_axi_mm2s_rresp(vdma_M_AXI_MM2S_RRESP),
        .m_axi_mm2s_rvalid(vdma_M_AXI_MM2S_RVALID),
        .m_axi_s2mm_aclk(ps7_FCLK_CLK0),
        .m_axi_s2mm_awaddr(vdma_M_AXI_S2MM_AWADDR),
        .m_axi_s2mm_awburst(vdma_M_AXI_S2MM_AWBURST),
        .m_axi_s2mm_awcache(vdma_M_AXI_S2MM_AWCACHE),
        .m_axi_s2mm_awlen(vdma_M_AXI_S2MM_AWLEN),
        .m_axi_s2mm_awprot(vdma_M_AXI_S2MM_AWPROT),
        .m_axi_s2mm_awready(vdma_M_AXI_S2MM_AWREADY),
        .m_axi_s2mm_awsize(vdma_M_AXI_S2MM_AWSIZE),
        .m_axi_s2mm_awvalid(vdma_M_AXI_S2MM_AWVALID),
        .m_axi_s2mm_bready(vdma_M_AXI_S2MM_BREADY),
        .m_axi_s2mm_bresp(vdma_M_AXI_S2MM_BRESP),
        .m_axi_s2mm_bvalid(vdma_M_AXI_S2MM_BVALID),
        .m_axi_s2mm_wdata(vdma_M_AXI_S2MM_WDATA),
        .m_axi_s2mm_wlast(vdma_M_AXI_S2MM_WLAST),
        .m_axi_s2mm_wready(vdma_M_AXI_S2MM_WREADY),
        .m_axi_s2mm_wstrb(vdma_M_AXI_S2MM_WSTRB),
        .m_axi_s2mm_wvalid(vdma_M_AXI_S2MM_WVALID),
        .m_axis_mm2s_aclk(clk_hdmi_clk_out1),
        .m_axis_mm2s_tdata(vdma_M_AXIS_MM2S_TDATA),
        .m_axis_mm2s_tkeep(vdma_M_AXIS_MM2S_TKEEP),
        .m_axis_mm2s_tlast(vdma_M_AXIS_MM2S_TLAST),
        .m_axis_mm2s_tready(vdma_M_AXIS_MM2S_TREADY),
        .m_axis_mm2s_tuser(vdma_M_AXIS_MM2S_TUSER),
        .m_axis_mm2s_tvalid(vdma_M_AXIS_MM2S_TVALID),
        .mm2s_fsync(hdmi_raster_frame_sync),
        .s2mm_introut(vdma_s2mm_introut),
        .s_axi_lite_aclk(ps7_FCLK_CLK0),
        .s_axi_lite_araddr(ctrl_ic_M00_AXI_ARADDR[8:0]),
        .s_axi_lite_arready(ctrl_ic_M00_AXI_ARREADY),
        .s_axi_lite_arvalid(ctrl_ic_M00_AXI_ARVALID),
        .s_axi_lite_awaddr(ctrl_ic_M00_AXI_AWADDR[8:0]),
        .s_axi_lite_awready(ctrl_ic_M00_AXI_AWREADY),
        .s_axi_lite_awvalid(ctrl_ic_M00_AXI_AWVALID),
        .s_axi_lite_bready(ctrl_ic_M00_AXI_BREADY),
        .s_axi_lite_bresp(ctrl_ic_M00_AXI_BRESP),
        .s_axi_lite_bvalid(ctrl_ic_M00_AXI_BVALID),
        .s_axi_lite_rdata(ctrl_ic_M00_AXI_RDATA),
        .s_axi_lite_rready(ctrl_ic_M00_AXI_RREADY),
        .s_axi_lite_rresp(ctrl_ic_M00_AXI_RRESP),
        .s_axi_lite_rvalid(ctrl_ic_M00_AXI_RVALID),
        .s_axi_lite_wdata(ctrl_ic_M00_AXI_WDATA),
        .s_axi_lite_wready(ctrl_ic_M00_AXI_WREADY),
        .s_axi_lite_wvalid(ctrl_ic_M00_AXI_WVALID),
        .s_axis_s2mm_aclk(ps7_FCLK_CLK0),
        .s_axis_s2mm_tdata(video_cdc_M_AXIS_TDATA),
        .s_axis_s2mm_tkeep(video_cdc_M_AXIS_TKEEP),
        .s_axis_s2mm_tlast(video_cdc_M_AXIS_TLAST),
        .s_axis_s2mm_tready(video_cdc_M_AXIS_TREADY),
        .s_axis_s2mm_tuser(video_cdc_M_AXIS_TUSER),
        .s_axis_s2mm_tvalid(video_cdc_M_AXIS_TVALID));
  av_system_vdma_proto_0 vdma_proto
       (.aclk(ps7_FCLK_CLK0),
        .aresetn(rst_fclk_peripheral_aresetn),
        .m_axi_awaddr(vdma_proto_M_AXI_AWADDR),
        .m_axi_awburst(vdma_proto_M_AXI_AWBURST),
        .m_axi_awcache(vdma_proto_M_AXI_AWCACHE),
        .m_axi_awlen(vdma_proto_M_AXI_AWLEN),
        .m_axi_awlock(vdma_proto_M_AXI_AWLOCK),
        .m_axi_awprot(vdma_proto_M_AXI_AWPROT),
        .m_axi_awqos(vdma_proto_M_AXI_AWQOS),
        .m_axi_awready(vdma_proto_M_AXI_AWREADY),
        .m_axi_awsize(vdma_proto_M_AXI_AWSIZE),
        .m_axi_awvalid(vdma_proto_M_AXI_AWVALID),
        .m_axi_bready(vdma_proto_M_AXI_BREADY),
        .m_axi_bresp(vdma_proto_M_AXI_BRESP),
        .m_axi_bvalid(vdma_proto_M_AXI_BVALID),
        .m_axi_wdata(vdma_proto_M_AXI_WDATA),
        .m_axi_wlast(vdma_proto_M_AXI_WLAST),
        .m_axi_wready(vdma_proto_M_AXI_WREADY),
        .m_axi_wstrb(vdma_proto_M_AXI_WSTRB),
        .m_axi_wvalid(vdma_proto_M_AXI_WVALID),
        .s_axi_awaddr(vdma_M_AXI_S2MM_AWADDR),
        .s_axi_awburst(vdma_M_AXI_S2MM_AWBURST),
        .s_axi_awcache(vdma_M_AXI_S2MM_AWCACHE),
        .s_axi_awlen(vdma_M_AXI_S2MM_AWLEN),
        .s_axi_awlock(1'b0),
        .s_axi_awprot(vdma_M_AXI_S2MM_AWPROT),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(vdma_M_AXI_S2MM_AWREADY),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize(vdma_M_AXI_S2MM_AWSIZE),
        .s_axi_awvalid(vdma_M_AXI_S2MM_AWVALID),
        .s_axi_bready(vdma_M_AXI_S2MM_BREADY),
        .s_axi_bresp(vdma_M_AXI_S2MM_BRESP),
        .s_axi_bvalid(vdma_M_AXI_S2MM_BVALID),
        .s_axi_wdata(vdma_M_AXI_S2MM_WDATA),
        .s_axi_wlast(vdma_M_AXI_S2MM_WLAST),
        .s_axi_wready(vdma_M_AXI_S2MM_WREADY),
        .s_axi_wstrb(vdma_M_AXI_S2MM_WSTRB),
        .s_axi_wvalid(vdma_M_AXI_S2MM_WVALID));
  av_system_video_cdc_0 video_cdc
       (.m_axis_aclk(ps7_FCLK_CLK0),
        .m_axis_aresetn(rst_fclk_peripheral_aresetn),
        .m_axis_tdata(video_cdc_M_AXIS_TDATA),
        .m_axis_tkeep(video_cdc_M_AXIS_TKEEP),
        .m_axis_tlast(video_cdc_M_AXIS_TLAST),
        .m_axis_tready(video_cdc_M_AXIS_TREADY),
        .m_axis_tuser(video_cdc_M_AXIS_TUSER),
        .m_axis_tvalid(video_cdc_M_AXIS_TVALID),
        .s_axis_aclk(cam_pclk_1),
        .s_axis_aresetn(rst_pixel_peripheral_aresetn),
        .s_axis_tdata(camera_m_axis_video_TDATA),
        .s_axis_tkeep(camera_m_axis_video_TKEEP),
        .s_axis_tlast(camera_m_axis_video_TLAST),
        .s_axis_tready(camera_m_axis_video_TREADY),
        .s_axis_tuser(camera_m_axis_video_TUSER),
        .s_axis_tvalid(camera_m_axis_video_TVALID));
endmodule

module av_system_ctrl_ic_0
   (ACLK,
    ARESETN,
    M00_ACLK,
    M00_ARESETN,
    M00_AXI_araddr,
    M00_AXI_arready,
    M00_AXI_arvalid,
    M00_AXI_awaddr,
    M00_AXI_awready,
    M00_AXI_awvalid,
    M00_AXI_bready,
    M00_AXI_bresp,
    M00_AXI_bvalid,
    M00_AXI_rdata,
    M00_AXI_rready,
    M00_AXI_rresp,
    M00_AXI_rvalid,
    M00_AXI_wdata,
    M00_AXI_wready,
    M00_AXI_wvalid,
    M01_ACLK,
    M01_ARESETN,
    M01_AXI_araddr,
    M01_AXI_arready,
    M01_AXI_arvalid,
    M01_AXI_awaddr,
    M01_AXI_awready,
    M01_AXI_awvalid,
    M01_AXI_bready,
    M01_AXI_bresp,
    M01_AXI_bvalid,
    M01_AXI_rdata,
    M01_AXI_rready,
    M01_AXI_rresp,
    M01_AXI_rvalid,
    M01_AXI_wdata,
    M01_AXI_wready,
    M01_AXI_wvalid,
    M02_ACLK,
    M02_ARESETN,
    M02_AXI_araddr,
    M02_AXI_arready,
    M02_AXI_arvalid,
    M02_AXI_awaddr,
    M02_AXI_awready,
    M02_AXI_awvalid,
    M02_AXI_bready,
    M02_AXI_bresp,
    M02_AXI_bvalid,
    M02_AXI_rdata,
    M02_AXI_rready,
    M02_AXI_rresp,
    M02_AXI_rvalid,
    M02_AXI_wdata,
    M02_AXI_wready,
    M02_AXI_wstrb,
    M02_AXI_wvalid,
    M03_ACLK,
    M03_ARESETN,
    M03_AXI_araddr,
    M03_AXI_arprot,
    M03_AXI_arready,
    M03_AXI_arvalid,
    M03_AXI_awaddr,
    M03_AXI_awprot,
    M03_AXI_awready,
    M03_AXI_awvalid,
    M03_AXI_bready,
    M03_AXI_bresp,
    M03_AXI_bvalid,
    M03_AXI_rdata,
    M03_AXI_rready,
    M03_AXI_rresp,
    M03_AXI_rvalid,
    M03_AXI_wdata,
    M03_AXI_wready,
    M03_AXI_wstrb,
    M03_AXI_wvalid,
    M04_ACLK,
    M04_ARESETN,
    M04_AXI_araddr,
    M04_AXI_arready,
    M04_AXI_arvalid,
    M04_AXI_awaddr,
    M04_AXI_awready,
    M04_AXI_awvalid,
    M04_AXI_bready,
    M04_AXI_bresp,
    M04_AXI_bvalid,
    M04_AXI_rdata,
    M04_AXI_rready,
    M04_AXI_rresp,
    M04_AXI_rvalid,
    M04_AXI_wdata,
    M04_AXI_wready,
    M04_AXI_wvalid,
    M05_ACLK,
    M05_ARESETN,
    M05_AXI_araddr,
    M05_AXI_arready,
    M05_AXI_arvalid,
    M05_AXI_awaddr,
    M05_AXI_awready,
    M05_AXI_awvalid,
    M05_AXI_bready,
    M05_AXI_bresp,
    M05_AXI_bvalid,
    M05_AXI_rdata,
    M05_AXI_rready,
    M05_AXI_rresp,
    M05_AXI_rvalid,
    M05_AXI_wdata,
    M05_AXI_wready,
    M05_AXI_wstrb,
    M05_AXI_wvalid,
    M06_ACLK,
    M06_ARESETN,
    M06_AXI_araddr,
    M06_AXI_arready,
    M06_AXI_arvalid,
    M06_AXI_awaddr,
    M06_AXI_awready,
    M06_AXI_awvalid,
    M06_AXI_bready,
    M06_AXI_bresp,
    M06_AXI_bvalid,
    M06_AXI_rdata,
    M06_AXI_rready,
    M06_AXI_rresp,
    M06_AXI_rvalid,
    M06_AXI_wdata,
    M06_AXI_wready,
    M06_AXI_wvalid,
    M07_ACLK,
    M07_ARESETN,
    M07_AXI_araddr,
    M07_AXI_arready,
    M07_AXI_arvalid,
    M07_AXI_awaddr,
    M07_AXI_awready,
    M07_AXI_awvalid,
    M07_AXI_bready,
    M07_AXI_bresp,
    M07_AXI_bvalid,
    M07_AXI_rdata,
    M07_AXI_rready,
    M07_AXI_rresp,
    M07_AXI_rvalid,
    M07_AXI_wdata,
    M07_AXI_wready,
    M07_AXI_wvalid,
    M08_ACLK,
    M08_ARESETN,
    M08_AXI_araddr,
    M08_AXI_arready,
    M08_AXI_arvalid,
    M08_AXI_awaddr,
    M08_AXI_awready,
    M08_AXI_awvalid,
    M08_AXI_bready,
    M08_AXI_bresp,
    M08_AXI_bvalid,
    M08_AXI_rdata,
    M08_AXI_rready,
    M08_AXI_rresp,
    M08_AXI_rvalid,
    M08_AXI_wdata,
    M08_AXI_wready,
    M08_AXI_wstrb,
    M08_AXI_wvalid,
    S00_ACLK,
    S00_ARESETN,
    S00_AXI_araddr,
    S00_AXI_arburst,
    S00_AXI_arcache,
    S00_AXI_arid,
    S00_AXI_arlen,
    S00_AXI_arlock,
    S00_AXI_arprot,
    S00_AXI_arqos,
    S00_AXI_arready,
    S00_AXI_arsize,
    S00_AXI_arvalid,
    S00_AXI_awaddr,
    S00_AXI_awburst,
    S00_AXI_awcache,
    S00_AXI_awid,
    S00_AXI_awlen,
    S00_AXI_awlock,
    S00_AXI_awprot,
    S00_AXI_awqos,
    S00_AXI_awready,
    S00_AXI_awsize,
    S00_AXI_awvalid,
    S00_AXI_bid,
    S00_AXI_bready,
    S00_AXI_bresp,
    S00_AXI_bvalid,
    S00_AXI_rdata,
    S00_AXI_rid,
    S00_AXI_rlast,
    S00_AXI_rready,
    S00_AXI_rresp,
    S00_AXI_rvalid,
    S00_AXI_wdata,
    S00_AXI_wid,
    S00_AXI_wlast,
    S00_AXI_wready,
    S00_AXI_wstrb,
    S00_AXI_wvalid);
  input ACLK;
  input ARESETN;
  input M00_ACLK;
  input M00_ARESETN;
  output [31:0]M00_AXI_araddr;
  input [0:0]M00_AXI_arready;
  output [0:0]M00_AXI_arvalid;
  output [31:0]M00_AXI_awaddr;
  input [0:0]M00_AXI_awready;
  output [0:0]M00_AXI_awvalid;
  output [0:0]M00_AXI_bready;
  input [1:0]M00_AXI_bresp;
  input [0:0]M00_AXI_bvalid;
  input [31:0]M00_AXI_rdata;
  output [0:0]M00_AXI_rready;
  input [1:0]M00_AXI_rresp;
  input [0:0]M00_AXI_rvalid;
  output [31:0]M00_AXI_wdata;
  input [0:0]M00_AXI_wready;
  output [0:0]M00_AXI_wvalid;
  input M01_ACLK;
  input M01_ARESETN;
  output [31:0]M01_AXI_araddr;
  input [0:0]M01_AXI_arready;
  output [0:0]M01_AXI_arvalid;
  output [31:0]M01_AXI_awaddr;
  input [0:0]M01_AXI_awready;
  output [0:0]M01_AXI_awvalid;
  output [0:0]M01_AXI_bready;
  input [1:0]M01_AXI_bresp;
  input [0:0]M01_AXI_bvalid;
  input [31:0]M01_AXI_rdata;
  output [0:0]M01_AXI_rready;
  input [1:0]M01_AXI_rresp;
  input [0:0]M01_AXI_rvalid;
  output [31:0]M01_AXI_wdata;
  input [0:0]M01_AXI_wready;
  output [0:0]M01_AXI_wvalid;
  input M02_ACLK;
  input M02_ARESETN;
  output [31:0]M02_AXI_araddr;
  input M02_AXI_arready;
  output M02_AXI_arvalid;
  output [31:0]M02_AXI_awaddr;
  input M02_AXI_awready;
  output M02_AXI_awvalid;
  output M02_AXI_bready;
  input [1:0]M02_AXI_bresp;
  input M02_AXI_bvalid;
  input [31:0]M02_AXI_rdata;
  output M02_AXI_rready;
  input [1:0]M02_AXI_rresp;
  input M02_AXI_rvalid;
  output [31:0]M02_AXI_wdata;
  input M02_AXI_wready;
  output [3:0]M02_AXI_wstrb;
  output M02_AXI_wvalid;
  input M03_ACLK;
  input M03_ARESETN;
  output [31:0]M03_AXI_araddr;
  output [2:0]M03_AXI_arprot;
  input M03_AXI_arready;
  output M03_AXI_arvalid;
  output [31:0]M03_AXI_awaddr;
  output [2:0]M03_AXI_awprot;
  input M03_AXI_awready;
  output M03_AXI_awvalid;
  output M03_AXI_bready;
  input [1:0]M03_AXI_bresp;
  input M03_AXI_bvalid;
  input [31:0]M03_AXI_rdata;
  output M03_AXI_rready;
  input [1:0]M03_AXI_rresp;
  input M03_AXI_rvalid;
  output [31:0]M03_AXI_wdata;
  input M03_AXI_wready;
  output [3:0]M03_AXI_wstrb;
  output M03_AXI_wvalid;
  input M04_ACLK;
  input M04_ARESETN;
  output [31:0]M04_AXI_araddr;
  input M04_AXI_arready;
  output M04_AXI_arvalid;
  output [31:0]M04_AXI_awaddr;
  input M04_AXI_awready;
  output M04_AXI_awvalid;
  output M04_AXI_bready;
  input [1:0]M04_AXI_bresp;
  input M04_AXI_bvalid;
  input [31:0]M04_AXI_rdata;
  output M04_AXI_rready;
  input [1:0]M04_AXI_rresp;
  input M04_AXI_rvalid;
  output [31:0]M04_AXI_wdata;
  input M04_AXI_wready;
  output M04_AXI_wvalid;
  input M05_ACLK;
  input M05_ARESETN;
  output [31:0]M05_AXI_araddr;
  input M05_AXI_arready;
  output M05_AXI_arvalid;
  output [31:0]M05_AXI_awaddr;
  input M05_AXI_awready;
  output M05_AXI_awvalid;
  output M05_AXI_bready;
  input [1:0]M05_AXI_bresp;
  input M05_AXI_bvalid;
  input [31:0]M05_AXI_rdata;
  output M05_AXI_rready;
  input [1:0]M05_AXI_rresp;
  input M05_AXI_rvalid;
  output [31:0]M05_AXI_wdata;
  input M05_AXI_wready;
  output [3:0]M05_AXI_wstrb;
  output M05_AXI_wvalid;
  input M06_ACLK;
  input M06_ARESETN;
  output [31:0]M06_AXI_araddr;
  input M06_AXI_arready;
  output M06_AXI_arvalid;
  output [31:0]M06_AXI_awaddr;
  input M06_AXI_awready;
  output M06_AXI_awvalid;
  output M06_AXI_bready;
  input [1:0]M06_AXI_bresp;
  input M06_AXI_bvalid;
  input [31:0]M06_AXI_rdata;
  output M06_AXI_rready;
  input [1:0]M06_AXI_rresp;
  input M06_AXI_rvalid;
  output [31:0]M06_AXI_wdata;
  input M06_AXI_wready;
  output M06_AXI_wvalid;
  input M07_ACLK;
  input M07_ARESETN;
  output [31:0]M07_AXI_araddr;
  input M07_AXI_arready;
  output M07_AXI_arvalid;
  output [31:0]M07_AXI_awaddr;
  input M07_AXI_awready;
  output M07_AXI_awvalid;
  output M07_AXI_bready;
  input [1:0]M07_AXI_bresp;
  input M07_AXI_bvalid;
  input [31:0]M07_AXI_rdata;
  output M07_AXI_rready;
  input [1:0]M07_AXI_rresp;
  input M07_AXI_rvalid;
  output [31:0]M07_AXI_wdata;
  input M07_AXI_wready;
  output M07_AXI_wvalid;
  input M08_ACLK;
  input M08_ARESETN;
  output [31:0]M08_AXI_araddr;
  input M08_AXI_arready;
  output M08_AXI_arvalid;
  output [31:0]M08_AXI_awaddr;
  input M08_AXI_awready;
  output M08_AXI_awvalid;
  output M08_AXI_bready;
  input [1:0]M08_AXI_bresp;
  input M08_AXI_bvalid;
  input [31:0]M08_AXI_rdata;
  output M08_AXI_rready;
  input [1:0]M08_AXI_rresp;
  input M08_AXI_rvalid;
  output [31:0]M08_AXI_wdata;
  input M08_AXI_wready;
  output [3:0]M08_AXI_wstrb;
  output M08_AXI_wvalid;
  input S00_ACLK;
  input S00_ARESETN;
  input [31:0]S00_AXI_araddr;
  input [1:0]S00_AXI_arburst;
  input [3:0]S00_AXI_arcache;
  input [11:0]S00_AXI_arid;
  input [3:0]S00_AXI_arlen;
  input [1:0]S00_AXI_arlock;
  input [2:0]S00_AXI_arprot;
  input [3:0]S00_AXI_arqos;
  output S00_AXI_arready;
  input [2:0]S00_AXI_arsize;
  input S00_AXI_arvalid;
  input [31:0]S00_AXI_awaddr;
  input [1:0]S00_AXI_awburst;
  input [3:0]S00_AXI_awcache;
  input [11:0]S00_AXI_awid;
  input [3:0]S00_AXI_awlen;
  input [1:0]S00_AXI_awlock;
  input [2:0]S00_AXI_awprot;
  input [3:0]S00_AXI_awqos;
  output S00_AXI_awready;
  input [2:0]S00_AXI_awsize;
  input S00_AXI_awvalid;
  output [11:0]S00_AXI_bid;
  input S00_AXI_bready;
  output [1:0]S00_AXI_bresp;
  output S00_AXI_bvalid;
  output [31:0]S00_AXI_rdata;
  output [11:0]S00_AXI_rid;
  output S00_AXI_rlast;
  input S00_AXI_rready;
  output [1:0]S00_AXI_rresp;
  output S00_AXI_rvalid;
  input [31:0]S00_AXI_wdata;
  input [11:0]S00_AXI_wid;
  input S00_AXI_wlast;
  output S00_AXI_wready;
  input [3:0]S00_AXI_wstrb;
  input S00_AXI_wvalid;

  wire M00_ACLK_1;
  wire M00_ARESETN_1;
  wire M01_ACLK_1;
  wire M01_ARESETN_1;
  wire M02_ACLK_1;
  wire M02_ARESETN_1;
  wire M03_ACLK_1;
  wire M03_ARESETN_1;
  wire M04_ACLK_1;
  wire M04_ARESETN_1;
  wire M05_ACLK_1;
  wire M05_ARESETN_1;
  wire M06_ACLK_1;
  wire M06_ARESETN_1;
  wire M07_ACLK_1;
  wire M07_ARESETN_1;
  wire M08_ACLK_1;
  wire M08_ARESETN_1;
  wire S00_ACLK_1;
  wire S00_ARESETN_1;
  wire ctrl_ic_ACLK_net;
  wire ctrl_ic_ARESETN_net;
  wire [31:0]ctrl_ic_to_s00_couplers_ARADDR;
  wire [1:0]ctrl_ic_to_s00_couplers_ARBURST;
  wire [3:0]ctrl_ic_to_s00_couplers_ARCACHE;
  wire [11:0]ctrl_ic_to_s00_couplers_ARID;
  wire [3:0]ctrl_ic_to_s00_couplers_ARLEN;
  wire [1:0]ctrl_ic_to_s00_couplers_ARLOCK;
  wire [2:0]ctrl_ic_to_s00_couplers_ARPROT;
  wire [3:0]ctrl_ic_to_s00_couplers_ARQOS;
  wire ctrl_ic_to_s00_couplers_ARREADY;
  wire [2:0]ctrl_ic_to_s00_couplers_ARSIZE;
  wire ctrl_ic_to_s00_couplers_ARVALID;
  wire [31:0]ctrl_ic_to_s00_couplers_AWADDR;
  wire [1:0]ctrl_ic_to_s00_couplers_AWBURST;
  wire [3:0]ctrl_ic_to_s00_couplers_AWCACHE;
  wire [11:0]ctrl_ic_to_s00_couplers_AWID;
  wire [3:0]ctrl_ic_to_s00_couplers_AWLEN;
  wire [1:0]ctrl_ic_to_s00_couplers_AWLOCK;
  wire [2:0]ctrl_ic_to_s00_couplers_AWPROT;
  wire [3:0]ctrl_ic_to_s00_couplers_AWQOS;
  wire ctrl_ic_to_s00_couplers_AWREADY;
  wire [2:0]ctrl_ic_to_s00_couplers_AWSIZE;
  wire ctrl_ic_to_s00_couplers_AWVALID;
  wire [11:0]ctrl_ic_to_s00_couplers_BID;
  wire ctrl_ic_to_s00_couplers_BREADY;
  wire [1:0]ctrl_ic_to_s00_couplers_BRESP;
  wire ctrl_ic_to_s00_couplers_BVALID;
  wire [31:0]ctrl_ic_to_s00_couplers_RDATA;
  wire [11:0]ctrl_ic_to_s00_couplers_RID;
  wire ctrl_ic_to_s00_couplers_RLAST;
  wire ctrl_ic_to_s00_couplers_RREADY;
  wire [1:0]ctrl_ic_to_s00_couplers_RRESP;
  wire ctrl_ic_to_s00_couplers_RVALID;
  wire [31:0]ctrl_ic_to_s00_couplers_WDATA;
  wire [11:0]ctrl_ic_to_s00_couplers_WID;
  wire ctrl_ic_to_s00_couplers_WLAST;
  wire ctrl_ic_to_s00_couplers_WREADY;
  wire [3:0]ctrl_ic_to_s00_couplers_WSTRB;
  wire ctrl_ic_to_s00_couplers_WVALID;
  wire [31:0]m00_couplers_to_ctrl_ic_ARADDR;
  wire [0:0]m00_couplers_to_ctrl_ic_ARREADY;
  wire [0:0]m00_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m00_couplers_to_ctrl_ic_AWADDR;
  wire [0:0]m00_couplers_to_ctrl_ic_AWREADY;
  wire [0:0]m00_couplers_to_ctrl_ic_AWVALID;
  wire [0:0]m00_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m00_couplers_to_ctrl_ic_BRESP;
  wire [0:0]m00_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m00_couplers_to_ctrl_ic_RDATA;
  wire [0:0]m00_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m00_couplers_to_ctrl_ic_RRESP;
  wire [0:0]m00_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m00_couplers_to_ctrl_ic_WDATA;
  wire [0:0]m00_couplers_to_ctrl_ic_WREADY;
  wire [0:0]m00_couplers_to_ctrl_ic_WVALID;
  wire [31:0]m01_couplers_to_ctrl_ic_ARADDR;
  wire [0:0]m01_couplers_to_ctrl_ic_ARREADY;
  wire [0:0]m01_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m01_couplers_to_ctrl_ic_AWADDR;
  wire [0:0]m01_couplers_to_ctrl_ic_AWREADY;
  wire [0:0]m01_couplers_to_ctrl_ic_AWVALID;
  wire [0:0]m01_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m01_couplers_to_ctrl_ic_BRESP;
  wire [0:0]m01_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m01_couplers_to_ctrl_ic_RDATA;
  wire [0:0]m01_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m01_couplers_to_ctrl_ic_RRESP;
  wire [0:0]m01_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m01_couplers_to_ctrl_ic_WDATA;
  wire [0:0]m01_couplers_to_ctrl_ic_WREADY;
  wire [0:0]m01_couplers_to_ctrl_ic_WVALID;
  wire [31:0]m02_couplers_to_ctrl_ic_ARADDR;
  wire m02_couplers_to_ctrl_ic_ARREADY;
  wire m02_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m02_couplers_to_ctrl_ic_AWADDR;
  wire m02_couplers_to_ctrl_ic_AWREADY;
  wire m02_couplers_to_ctrl_ic_AWVALID;
  wire m02_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m02_couplers_to_ctrl_ic_BRESP;
  wire m02_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m02_couplers_to_ctrl_ic_RDATA;
  wire m02_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m02_couplers_to_ctrl_ic_RRESP;
  wire m02_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m02_couplers_to_ctrl_ic_WDATA;
  wire m02_couplers_to_ctrl_ic_WREADY;
  wire [3:0]m02_couplers_to_ctrl_ic_WSTRB;
  wire m02_couplers_to_ctrl_ic_WVALID;
  wire [31:0]m03_couplers_to_ctrl_ic_ARADDR;
  wire [2:0]m03_couplers_to_ctrl_ic_ARPROT;
  wire m03_couplers_to_ctrl_ic_ARREADY;
  wire m03_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m03_couplers_to_ctrl_ic_AWADDR;
  wire [2:0]m03_couplers_to_ctrl_ic_AWPROT;
  wire m03_couplers_to_ctrl_ic_AWREADY;
  wire m03_couplers_to_ctrl_ic_AWVALID;
  wire m03_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m03_couplers_to_ctrl_ic_BRESP;
  wire m03_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m03_couplers_to_ctrl_ic_RDATA;
  wire m03_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m03_couplers_to_ctrl_ic_RRESP;
  wire m03_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m03_couplers_to_ctrl_ic_WDATA;
  wire m03_couplers_to_ctrl_ic_WREADY;
  wire [3:0]m03_couplers_to_ctrl_ic_WSTRB;
  wire m03_couplers_to_ctrl_ic_WVALID;
  wire [31:0]m04_couplers_to_ctrl_ic_ARADDR;
  wire m04_couplers_to_ctrl_ic_ARREADY;
  wire m04_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m04_couplers_to_ctrl_ic_AWADDR;
  wire m04_couplers_to_ctrl_ic_AWREADY;
  wire m04_couplers_to_ctrl_ic_AWVALID;
  wire m04_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m04_couplers_to_ctrl_ic_BRESP;
  wire m04_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m04_couplers_to_ctrl_ic_RDATA;
  wire m04_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m04_couplers_to_ctrl_ic_RRESP;
  wire m04_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m04_couplers_to_ctrl_ic_WDATA;
  wire m04_couplers_to_ctrl_ic_WREADY;
  wire m04_couplers_to_ctrl_ic_WVALID;
  wire [31:0]m05_couplers_to_ctrl_ic_ARADDR;
  wire m05_couplers_to_ctrl_ic_ARREADY;
  wire m05_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m05_couplers_to_ctrl_ic_AWADDR;
  wire m05_couplers_to_ctrl_ic_AWREADY;
  wire m05_couplers_to_ctrl_ic_AWVALID;
  wire m05_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m05_couplers_to_ctrl_ic_BRESP;
  wire m05_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m05_couplers_to_ctrl_ic_RDATA;
  wire m05_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m05_couplers_to_ctrl_ic_RRESP;
  wire m05_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m05_couplers_to_ctrl_ic_WDATA;
  wire m05_couplers_to_ctrl_ic_WREADY;
  wire [3:0]m05_couplers_to_ctrl_ic_WSTRB;
  wire m05_couplers_to_ctrl_ic_WVALID;
  wire [31:0]m06_couplers_to_ctrl_ic_ARADDR;
  wire m06_couplers_to_ctrl_ic_ARREADY;
  wire m06_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m06_couplers_to_ctrl_ic_AWADDR;
  wire m06_couplers_to_ctrl_ic_AWREADY;
  wire m06_couplers_to_ctrl_ic_AWVALID;
  wire m06_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m06_couplers_to_ctrl_ic_BRESP;
  wire m06_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m06_couplers_to_ctrl_ic_RDATA;
  wire m06_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m06_couplers_to_ctrl_ic_RRESP;
  wire m06_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m06_couplers_to_ctrl_ic_WDATA;
  wire m06_couplers_to_ctrl_ic_WREADY;
  wire m06_couplers_to_ctrl_ic_WVALID;
  wire [31:0]m07_couplers_to_ctrl_ic_ARADDR;
  wire m07_couplers_to_ctrl_ic_ARREADY;
  wire m07_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m07_couplers_to_ctrl_ic_AWADDR;
  wire m07_couplers_to_ctrl_ic_AWREADY;
  wire m07_couplers_to_ctrl_ic_AWVALID;
  wire m07_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m07_couplers_to_ctrl_ic_BRESP;
  wire m07_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m07_couplers_to_ctrl_ic_RDATA;
  wire m07_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m07_couplers_to_ctrl_ic_RRESP;
  wire m07_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m07_couplers_to_ctrl_ic_WDATA;
  wire m07_couplers_to_ctrl_ic_WREADY;
  wire m07_couplers_to_ctrl_ic_WVALID;
  wire [31:0]m08_couplers_to_ctrl_ic_ARADDR;
  wire m08_couplers_to_ctrl_ic_ARREADY;
  wire m08_couplers_to_ctrl_ic_ARVALID;
  wire [31:0]m08_couplers_to_ctrl_ic_AWADDR;
  wire m08_couplers_to_ctrl_ic_AWREADY;
  wire m08_couplers_to_ctrl_ic_AWVALID;
  wire m08_couplers_to_ctrl_ic_BREADY;
  wire [1:0]m08_couplers_to_ctrl_ic_BRESP;
  wire m08_couplers_to_ctrl_ic_BVALID;
  wire [31:0]m08_couplers_to_ctrl_ic_RDATA;
  wire m08_couplers_to_ctrl_ic_RREADY;
  wire [1:0]m08_couplers_to_ctrl_ic_RRESP;
  wire m08_couplers_to_ctrl_ic_RVALID;
  wire [31:0]m08_couplers_to_ctrl_ic_WDATA;
  wire m08_couplers_to_ctrl_ic_WREADY;
  wire [3:0]m08_couplers_to_ctrl_ic_WSTRB;
  wire m08_couplers_to_ctrl_ic_WVALID;
  wire [31:0]s00_couplers_to_xbar_ARADDR;
  wire [2:0]s00_couplers_to_xbar_ARPROT;
  wire [0:0]s00_couplers_to_xbar_ARREADY;
  wire s00_couplers_to_xbar_ARVALID;
  wire [31:0]s00_couplers_to_xbar_AWADDR;
  wire [2:0]s00_couplers_to_xbar_AWPROT;
  wire [0:0]s00_couplers_to_xbar_AWREADY;
  wire s00_couplers_to_xbar_AWVALID;
  wire s00_couplers_to_xbar_BREADY;
  wire [1:0]s00_couplers_to_xbar_BRESP;
  wire [0:0]s00_couplers_to_xbar_BVALID;
  wire [31:0]s00_couplers_to_xbar_RDATA;
  wire s00_couplers_to_xbar_RREADY;
  wire [1:0]s00_couplers_to_xbar_RRESP;
  wire [0:0]s00_couplers_to_xbar_RVALID;
  wire [31:0]s00_couplers_to_xbar_WDATA;
  wire [0:0]s00_couplers_to_xbar_WREADY;
  wire [3:0]s00_couplers_to_xbar_WSTRB;
  wire s00_couplers_to_xbar_WVALID;
  wire [31:0]xbar_to_m00_couplers_ARADDR;
  wire [0:0]xbar_to_m00_couplers_ARREADY;
  wire [0:0]xbar_to_m00_couplers_ARVALID;
  wire [31:0]xbar_to_m00_couplers_AWADDR;
  wire [0:0]xbar_to_m00_couplers_AWREADY;
  wire [0:0]xbar_to_m00_couplers_AWVALID;
  wire [0:0]xbar_to_m00_couplers_BREADY;
  wire [1:0]xbar_to_m00_couplers_BRESP;
  wire [0:0]xbar_to_m00_couplers_BVALID;
  wire [31:0]xbar_to_m00_couplers_RDATA;
  wire [0:0]xbar_to_m00_couplers_RREADY;
  wire [1:0]xbar_to_m00_couplers_RRESP;
  wire [0:0]xbar_to_m00_couplers_RVALID;
  wire [31:0]xbar_to_m00_couplers_WDATA;
  wire [0:0]xbar_to_m00_couplers_WREADY;
  wire [0:0]xbar_to_m00_couplers_WVALID;
  wire [63:32]xbar_to_m01_couplers_ARADDR;
  wire [0:0]xbar_to_m01_couplers_ARREADY;
  wire [1:1]xbar_to_m01_couplers_ARVALID;
  wire [63:32]xbar_to_m01_couplers_AWADDR;
  wire [0:0]xbar_to_m01_couplers_AWREADY;
  wire [1:1]xbar_to_m01_couplers_AWVALID;
  wire [1:1]xbar_to_m01_couplers_BREADY;
  wire [1:0]xbar_to_m01_couplers_BRESP;
  wire [0:0]xbar_to_m01_couplers_BVALID;
  wire [31:0]xbar_to_m01_couplers_RDATA;
  wire [1:1]xbar_to_m01_couplers_RREADY;
  wire [1:0]xbar_to_m01_couplers_RRESP;
  wire [0:0]xbar_to_m01_couplers_RVALID;
  wire [63:32]xbar_to_m01_couplers_WDATA;
  wire [0:0]xbar_to_m01_couplers_WREADY;
  wire [1:1]xbar_to_m01_couplers_WVALID;
  wire [95:64]xbar_to_m02_couplers_ARADDR;
  wire xbar_to_m02_couplers_ARREADY;
  wire [2:2]xbar_to_m02_couplers_ARVALID;
  wire [95:64]xbar_to_m02_couplers_AWADDR;
  wire xbar_to_m02_couplers_AWREADY;
  wire [2:2]xbar_to_m02_couplers_AWVALID;
  wire [2:2]xbar_to_m02_couplers_BREADY;
  wire [1:0]xbar_to_m02_couplers_BRESP;
  wire xbar_to_m02_couplers_BVALID;
  wire [31:0]xbar_to_m02_couplers_RDATA;
  wire [2:2]xbar_to_m02_couplers_RREADY;
  wire [1:0]xbar_to_m02_couplers_RRESP;
  wire xbar_to_m02_couplers_RVALID;
  wire [95:64]xbar_to_m02_couplers_WDATA;
  wire xbar_to_m02_couplers_WREADY;
  wire [11:8]xbar_to_m02_couplers_WSTRB;
  wire [2:2]xbar_to_m02_couplers_WVALID;
  wire [127:96]xbar_to_m03_couplers_ARADDR;
  wire [11:9]xbar_to_m03_couplers_ARPROT;
  wire xbar_to_m03_couplers_ARREADY;
  wire [3:3]xbar_to_m03_couplers_ARVALID;
  wire [127:96]xbar_to_m03_couplers_AWADDR;
  wire [11:9]xbar_to_m03_couplers_AWPROT;
  wire xbar_to_m03_couplers_AWREADY;
  wire [3:3]xbar_to_m03_couplers_AWVALID;
  wire [3:3]xbar_to_m03_couplers_BREADY;
  wire [1:0]xbar_to_m03_couplers_BRESP;
  wire xbar_to_m03_couplers_BVALID;
  wire [31:0]xbar_to_m03_couplers_RDATA;
  wire [3:3]xbar_to_m03_couplers_RREADY;
  wire [1:0]xbar_to_m03_couplers_RRESP;
  wire xbar_to_m03_couplers_RVALID;
  wire [127:96]xbar_to_m03_couplers_WDATA;
  wire xbar_to_m03_couplers_WREADY;
  wire [15:12]xbar_to_m03_couplers_WSTRB;
  wire [3:3]xbar_to_m03_couplers_WVALID;
  wire [159:128]xbar_to_m04_couplers_ARADDR;
  wire xbar_to_m04_couplers_ARREADY;
  wire [4:4]xbar_to_m04_couplers_ARVALID;
  wire [159:128]xbar_to_m04_couplers_AWADDR;
  wire xbar_to_m04_couplers_AWREADY;
  wire [4:4]xbar_to_m04_couplers_AWVALID;
  wire [4:4]xbar_to_m04_couplers_BREADY;
  wire [1:0]xbar_to_m04_couplers_BRESP;
  wire xbar_to_m04_couplers_BVALID;
  wire [31:0]xbar_to_m04_couplers_RDATA;
  wire [4:4]xbar_to_m04_couplers_RREADY;
  wire [1:0]xbar_to_m04_couplers_RRESP;
  wire xbar_to_m04_couplers_RVALID;
  wire [159:128]xbar_to_m04_couplers_WDATA;
  wire xbar_to_m04_couplers_WREADY;
  wire [4:4]xbar_to_m04_couplers_WVALID;
  wire [191:160]xbar_to_m05_couplers_ARADDR;
  wire xbar_to_m05_couplers_ARREADY;
  wire [5:5]xbar_to_m05_couplers_ARVALID;
  wire [191:160]xbar_to_m05_couplers_AWADDR;
  wire xbar_to_m05_couplers_AWREADY;
  wire [5:5]xbar_to_m05_couplers_AWVALID;
  wire [5:5]xbar_to_m05_couplers_BREADY;
  wire [1:0]xbar_to_m05_couplers_BRESP;
  wire xbar_to_m05_couplers_BVALID;
  wire [31:0]xbar_to_m05_couplers_RDATA;
  wire [5:5]xbar_to_m05_couplers_RREADY;
  wire [1:0]xbar_to_m05_couplers_RRESP;
  wire xbar_to_m05_couplers_RVALID;
  wire [191:160]xbar_to_m05_couplers_WDATA;
  wire xbar_to_m05_couplers_WREADY;
  wire [23:20]xbar_to_m05_couplers_WSTRB;
  wire [5:5]xbar_to_m05_couplers_WVALID;
  wire [223:192]xbar_to_m06_couplers_ARADDR;
  wire xbar_to_m06_couplers_ARREADY;
  wire [6:6]xbar_to_m06_couplers_ARVALID;
  wire [223:192]xbar_to_m06_couplers_AWADDR;
  wire xbar_to_m06_couplers_AWREADY;
  wire [6:6]xbar_to_m06_couplers_AWVALID;
  wire [6:6]xbar_to_m06_couplers_BREADY;
  wire [1:0]xbar_to_m06_couplers_BRESP;
  wire xbar_to_m06_couplers_BVALID;
  wire [31:0]xbar_to_m06_couplers_RDATA;
  wire [6:6]xbar_to_m06_couplers_RREADY;
  wire [1:0]xbar_to_m06_couplers_RRESP;
  wire xbar_to_m06_couplers_RVALID;
  wire [223:192]xbar_to_m06_couplers_WDATA;
  wire xbar_to_m06_couplers_WREADY;
  wire [6:6]xbar_to_m06_couplers_WVALID;
  wire [255:224]xbar_to_m07_couplers_ARADDR;
  wire xbar_to_m07_couplers_ARREADY;
  wire [7:7]xbar_to_m07_couplers_ARVALID;
  wire [255:224]xbar_to_m07_couplers_AWADDR;
  wire xbar_to_m07_couplers_AWREADY;
  wire [7:7]xbar_to_m07_couplers_AWVALID;
  wire [7:7]xbar_to_m07_couplers_BREADY;
  wire [1:0]xbar_to_m07_couplers_BRESP;
  wire xbar_to_m07_couplers_BVALID;
  wire [31:0]xbar_to_m07_couplers_RDATA;
  wire [7:7]xbar_to_m07_couplers_RREADY;
  wire [1:0]xbar_to_m07_couplers_RRESP;
  wire xbar_to_m07_couplers_RVALID;
  wire [255:224]xbar_to_m07_couplers_WDATA;
  wire xbar_to_m07_couplers_WREADY;
  wire [7:7]xbar_to_m07_couplers_WVALID;
  wire [287:256]xbar_to_m08_couplers_ARADDR;
  wire xbar_to_m08_couplers_ARREADY;
  wire [8:8]xbar_to_m08_couplers_ARVALID;
  wire [287:256]xbar_to_m08_couplers_AWADDR;
  wire xbar_to_m08_couplers_AWREADY;
  wire [8:8]xbar_to_m08_couplers_AWVALID;
  wire [8:8]xbar_to_m08_couplers_BREADY;
  wire [1:0]xbar_to_m08_couplers_BRESP;
  wire xbar_to_m08_couplers_BVALID;
  wire [31:0]xbar_to_m08_couplers_RDATA;
  wire [8:8]xbar_to_m08_couplers_RREADY;
  wire [1:0]xbar_to_m08_couplers_RRESP;
  wire xbar_to_m08_couplers_RVALID;
  wire [287:256]xbar_to_m08_couplers_WDATA;
  wire xbar_to_m08_couplers_WREADY;
  wire [35:32]xbar_to_m08_couplers_WSTRB;
  wire [8:8]xbar_to_m08_couplers_WVALID;
  wire [26:0]NLW_xbar_m_axi_arprot_UNCONNECTED;
  wire [26:0]NLW_xbar_m_axi_awprot_UNCONNECTED;
  wire [35:0]NLW_xbar_m_axi_wstrb_UNCONNECTED;

  assign M00_ACLK_1 = M00_ACLK;
  assign M00_ARESETN_1 = M00_ARESETN;
  assign M00_AXI_araddr[31:0] = m00_couplers_to_ctrl_ic_ARADDR;
  assign M00_AXI_arvalid[0] = m00_couplers_to_ctrl_ic_ARVALID;
  assign M00_AXI_awaddr[31:0] = m00_couplers_to_ctrl_ic_AWADDR;
  assign M00_AXI_awvalid[0] = m00_couplers_to_ctrl_ic_AWVALID;
  assign M00_AXI_bready[0] = m00_couplers_to_ctrl_ic_BREADY;
  assign M00_AXI_rready[0] = m00_couplers_to_ctrl_ic_RREADY;
  assign M00_AXI_wdata[31:0] = m00_couplers_to_ctrl_ic_WDATA;
  assign M00_AXI_wvalid[0] = m00_couplers_to_ctrl_ic_WVALID;
  assign M01_ACLK_1 = M01_ACLK;
  assign M01_ARESETN_1 = M01_ARESETN;
  assign M01_AXI_araddr[31:0] = m01_couplers_to_ctrl_ic_ARADDR;
  assign M01_AXI_arvalid[0] = m01_couplers_to_ctrl_ic_ARVALID;
  assign M01_AXI_awaddr[31:0] = m01_couplers_to_ctrl_ic_AWADDR;
  assign M01_AXI_awvalid[0] = m01_couplers_to_ctrl_ic_AWVALID;
  assign M01_AXI_bready[0] = m01_couplers_to_ctrl_ic_BREADY;
  assign M01_AXI_rready[0] = m01_couplers_to_ctrl_ic_RREADY;
  assign M01_AXI_wdata[31:0] = m01_couplers_to_ctrl_ic_WDATA;
  assign M01_AXI_wvalid[0] = m01_couplers_to_ctrl_ic_WVALID;
  assign M02_ACLK_1 = M02_ACLK;
  assign M02_ARESETN_1 = M02_ARESETN;
  assign M02_AXI_araddr[31:0] = m02_couplers_to_ctrl_ic_ARADDR;
  assign M02_AXI_arvalid = m02_couplers_to_ctrl_ic_ARVALID;
  assign M02_AXI_awaddr[31:0] = m02_couplers_to_ctrl_ic_AWADDR;
  assign M02_AXI_awvalid = m02_couplers_to_ctrl_ic_AWVALID;
  assign M02_AXI_bready = m02_couplers_to_ctrl_ic_BREADY;
  assign M02_AXI_rready = m02_couplers_to_ctrl_ic_RREADY;
  assign M02_AXI_wdata[31:0] = m02_couplers_to_ctrl_ic_WDATA;
  assign M02_AXI_wstrb[3:0] = m02_couplers_to_ctrl_ic_WSTRB;
  assign M02_AXI_wvalid = m02_couplers_to_ctrl_ic_WVALID;
  assign M03_ACLK_1 = M03_ACLK;
  assign M03_ARESETN_1 = M03_ARESETN;
  assign M03_AXI_araddr[31:0] = m03_couplers_to_ctrl_ic_ARADDR;
  assign M03_AXI_arprot[2:0] = m03_couplers_to_ctrl_ic_ARPROT;
  assign M03_AXI_arvalid = m03_couplers_to_ctrl_ic_ARVALID;
  assign M03_AXI_awaddr[31:0] = m03_couplers_to_ctrl_ic_AWADDR;
  assign M03_AXI_awprot[2:0] = m03_couplers_to_ctrl_ic_AWPROT;
  assign M03_AXI_awvalid = m03_couplers_to_ctrl_ic_AWVALID;
  assign M03_AXI_bready = m03_couplers_to_ctrl_ic_BREADY;
  assign M03_AXI_rready = m03_couplers_to_ctrl_ic_RREADY;
  assign M03_AXI_wdata[31:0] = m03_couplers_to_ctrl_ic_WDATA;
  assign M03_AXI_wstrb[3:0] = m03_couplers_to_ctrl_ic_WSTRB;
  assign M03_AXI_wvalid = m03_couplers_to_ctrl_ic_WVALID;
  assign M04_ACLK_1 = M04_ACLK;
  assign M04_ARESETN_1 = M04_ARESETN;
  assign M04_AXI_araddr[31:0] = m04_couplers_to_ctrl_ic_ARADDR;
  assign M04_AXI_arvalid = m04_couplers_to_ctrl_ic_ARVALID;
  assign M04_AXI_awaddr[31:0] = m04_couplers_to_ctrl_ic_AWADDR;
  assign M04_AXI_awvalid = m04_couplers_to_ctrl_ic_AWVALID;
  assign M04_AXI_bready = m04_couplers_to_ctrl_ic_BREADY;
  assign M04_AXI_rready = m04_couplers_to_ctrl_ic_RREADY;
  assign M04_AXI_wdata[31:0] = m04_couplers_to_ctrl_ic_WDATA;
  assign M04_AXI_wvalid = m04_couplers_to_ctrl_ic_WVALID;
  assign M05_ACLK_1 = M05_ACLK;
  assign M05_ARESETN_1 = M05_ARESETN;
  assign M05_AXI_araddr[31:0] = m05_couplers_to_ctrl_ic_ARADDR;
  assign M05_AXI_arvalid = m05_couplers_to_ctrl_ic_ARVALID;
  assign M05_AXI_awaddr[31:0] = m05_couplers_to_ctrl_ic_AWADDR;
  assign M05_AXI_awvalid = m05_couplers_to_ctrl_ic_AWVALID;
  assign M05_AXI_bready = m05_couplers_to_ctrl_ic_BREADY;
  assign M05_AXI_rready = m05_couplers_to_ctrl_ic_RREADY;
  assign M05_AXI_wdata[31:0] = m05_couplers_to_ctrl_ic_WDATA;
  assign M05_AXI_wstrb[3:0] = m05_couplers_to_ctrl_ic_WSTRB;
  assign M05_AXI_wvalid = m05_couplers_to_ctrl_ic_WVALID;
  assign M06_ACLK_1 = M06_ACLK;
  assign M06_ARESETN_1 = M06_ARESETN;
  assign M06_AXI_araddr[31:0] = m06_couplers_to_ctrl_ic_ARADDR;
  assign M06_AXI_arvalid = m06_couplers_to_ctrl_ic_ARVALID;
  assign M06_AXI_awaddr[31:0] = m06_couplers_to_ctrl_ic_AWADDR;
  assign M06_AXI_awvalid = m06_couplers_to_ctrl_ic_AWVALID;
  assign M06_AXI_bready = m06_couplers_to_ctrl_ic_BREADY;
  assign M06_AXI_rready = m06_couplers_to_ctrl_ic_RREADY;
  assign M06_AXI_wdata[31:0] = m06_couplers_to_ctrl_ic_WDATA;
  assign M06_AXI_wvalid = m06_couplers_to_ctrl_ic_WVALID;
  assign M07_ACLK_1 = M07_ACLK;
  assign M07_ARESETN_1 = M07_ARESETN;
  assign M07_AXI_araddr[31:0] = m07_couplers_to_ctrl_ic_ARADDR;
  assign M07_AXI_arvalid = m07_couplers_to_ctrl_ic_ARVALID;
  assign M07_AXI_awaddr[31:0] = m07_couplers_to_ctrl_ic_AWADDR;
  assign M07_AXI_awvalid = m07_couplers_to_ctrl_ic_AWVALID;
  assign M07_AXI_bready = m07_couplers_to_ctrl_ic_BREADY;
  assign M07_AXI_rready = m07_couplers_to_ctrl_ic_RREADY;
  assign M07_AXI_wdata[31:0] = m07_couplers_to_ctrl_ic_WDATA;
  assign M07_AXI_wvalid = m07_couplers_to_ctrl_ic_WVALID;
  assign M08_ACLK_1 = M08_ACLK;
  assign M08_ARESETN_1 = M08_ARESETN;
  assign M08_AXI_araddr[31:0] = m08_couplers_to_ctrl_ic_ARADDR;
  assign M08_AXI_arvalid = m08_couplers_to_ctrl_ic_ARVALID;
  assign M08_AXI_awaddr[31:0] = m08_couplers_to_ctrl_ic_AWADDR;
  assign M08_AXI_awvalid = m08_couplers_to_ctrl_ic_AWVALID;
  assign M08_AXI_bready = m08_couplers_to_ctrl_ic_BREADY;
  assign M08_AXI_rready = m08_couplers_to_ctrl_ic_RREADY;
  assign M08_AXI_wdata[31:0] = m08_couplers_to_ctrl_ic_WDATA;
  assign M08_AXI_wstrb[3:0] = m08_couplers_to_ctrl_ic_WSTRB;
  assign M08_AXI_wvalid = m08_couplers_to_ctrl_ic_WVALID;
  assign S00_ACLK_1 = S00_ACLK;
  assign S00_ARESETN_1 = S00_ARESETN;
  assign S00_AXI_arready = ctrl_ic_to_s00_couplers_ARREADY;
  assign S00_AXI_awready = ctrl_ic_to_s00_couplers_AWREADY;
  assign S00_AXI_bid[11:0] = ctrl_ic_to_s00_couplers_BID;
  assign S00_AXI_bresp[1:0] = ctrl_ic_to_s00_couplers_BRESP;
  assign S00_AXI_bvalid = ctrl_ic_to_s00_couplers_BVALID;
  assign S00_AXI_rdata[31:0] = ctrl_ic_to_s00_couplers_RDATA;
  assign S00_AXI_rid[11:0] = ctrl_ic_to_s00_couplers_RID;
  assign S00_AXI_rlast = ctrl_ic_to_s00_couplers_RLAST;
  assign S00_AXI_rresp[1:0] = ctrl_ic_to_s00_couplers_RRESP;
  assign S00_AXI_rvalid = ctrl_ic_to_s00_couplers_RVALID;
  assign S00_AXI_wready = ctrl_ic_to_s00_couplers_WREADY;
  assign ctrl_ic_ACLK_net = ACLK;
  assign ctrl_ic_ARESETN_net = ARESETN;
  assign ctrl_ic_to_s00_couplers_ARADDR = S00_AXI_araddr[31:0];
  assign ctrl_ic_to_s00_couplers_ARBURST = S00_AXI_arburst[1:0];
  assign ctrl_ic_to_s00_couplers_ARCACHE = S00_AXI_arcache[3:0];
  assign ctrl_ic_to_s00_couplers_ARID = S00_AXI_arid[11:0];
  assign ctrl_ic_to_s00_couplers_ARLEN = S00_AXI_arlen[3:0];
  assign ctrl_ic_to_s00_couplers_ARLOCK = S00_AXI_arlock[1:0];
  assign ctrl_ic_to_s00_couplers_ARPROT = S00_AXI_arprot[2:0];
  assign ctrl_ic_to_s00_couplers_ARQOS = S00_AXI_arqos[3:0];
  assign ctrl_ic_to_s00_couplers_ARSIZE = S00_AXI_arsize[2:0];
  assign ctrl_ic_to_s00_couplers_ARVALID = S00_AXI_arvalid;
  assign ctrl_ic_to_s00_couplers_AWADDR = S00_AXI_awaddr[31:0];
  assign ctrl_ic_to_s00_couplers_AWBURST = S00_AXI_awburst[1:0];
  assign ctrl_ic_to_s00_couplers_AWCACHE = S00_AXI_awcache[3:0];
  assign ctrl_ic_to_s00_couplers_AWID = S00_AXI_awid[11:0];
  assign ctrl_ic_to_s00_couplers_AWLEN = S00_AXI_awlen[3:0];
  assign ctrl_ic_to_s00_couplers_AWLOCK = S00_AXI_awlock[1:0];
  assign ctrl_ic_to_s00_couplers_AWPROT = S00_AXI_awprot[2:0];
  assign ctrl_ic_to_s00_couplers_AWQOS = S00_AXI_awqos[3:0];
  assign ctrl_ic_to_s00_couplers_AWSIZE = S00_AXI_awsize[2:0];
  assign ctrl_ic_to_s00_couplers_AWVALID = S00_AXI_awvalid;
  assign ctrl_ic_to_s00_couplers_BREADY = S00_AXI_bready;
  assign ctrl_ic_to_s00_couplers_RREADY = S00_AXI_rready;
  assign ctrl_ic_to_s00_couplers_WDATA = S00_AXI_wdata[31:0];
  assign ctrl_ic_to_s00_couplers_WID = S00_AXI_wid[11:0];
  assign ctrl_ic_to_s00_couplers_WLAST = S00_AXI_wlast;
  assign ctrl_ic_to_s00_couplers_WSTRB = S00_AXI_wstrb[3:0];
  assign ctrl_ic_to_s00_couplers_WVALID = S00_AXI_wvalid;
  assign m00_couplers_to_ctrl_ic_ARREADY = M00_AXI_arready[0];
  assign m00_couplers_to_ctrl_ic_AWREADY = M00_AXI_awready[0];
  assign m00_couplers_to_ctrl_ic_BRESP = M00_AXI_bresp[1:0];
  assign m00_couplers_to_ctrl_ic_BVALID = M00_AXI_bvalid[0];
  assign m00_couplers_to_ctrl_ic_RDATA = M00_AXI_rdata[31:0];
  assign m00_couplers_to_ctrl_ic_RRESP = M00_AXI_rresp[1:0];
  assign m00_couplers_to_ctrl_ic_RVALID = M00_AXI_rvalid[0];
  assign m00_couplers_to_ctrl_ic_WREADY = M00_AXI_wready[0];
  assign m01_couplers_to_ctrl_ic_ARREADY = M01_AXI_arready[0];
  assign m01_couplers_to_ctrl_ic_AWREADY = M01_AXI_awready[0];
  assign m01_couplers_to_ctrl_ic_BRESP = M01_AXI_bresp[1:0];
  assign m01_couplers_to_ctrl_ic_BVALID = M01_AXI_bvalid[0];
  assign m01_couplers_to_ctrl_ic_RDATA = M01_AXI_rdata[31:0];
  assign m01_couplers_to_ctrl_ic_RRESP = M01_AXI_rresp[1:0];
  assign m01_couplers_to_ctrl_ic_RVALID = M01_AXI_rvalid[0];
  assign m01_couplers_to_ctrl_ic_WREADY = M01_AXI_wready[0];
  assign m02_couplers_to_ctrl_ic_ARREADY = M02_AXI_arready;
  assign m02_couplers_to_ctrl_ic_AWREADY = M02_AXI_awready;
  assign m02_couplers_to_ctrl_ic_BRESP = M02_AXI_bresp[1:0];
  assign m02_couplers_to_ctrl_ic_BVALID = M02_AXI_bvalid;
  assign m02_couplers_to_ctrl_ic_RDATA = M02_AXI_rdata[31:0];
  assign m02_couplers_to_ctrl_ic_RRESP = M02_AXI_rresp[1:0];
  assign m02_couplers_to_ctrl_ic_RVALID = M02_AXI_rvalid;
  assign m02_couplers_to_ctrl_ic_WREADY = M02_AXI_wready;
  assign m03_couplers_to_ctrl_ic_ARREADY = M03_AXI_arready;
  assign m03_couplers_to_ctrl_ic_AWREADY = M03_AXI_awready;
  assign m03_couplers_to_ctrl_ic_BRESP = M03_AXI_bresp[1:0];
  assign m03_couplers_to_ctrl_ic_BVALID = M03_AXI_bvalid;
  assign m03_couplers_to_ctrl_ic_RDATA = M03_AXI_rdata[31:0];
  assign m03_couplers_to_ctrl_ic_RRESP = M03_AXI_rresp[1:0];
  assign m03_couplers_to_ctrl_ic_RVALID = M03_AXI_rvalid;
  assign m03_couplers_to_ctrl_ic_WREADY = M03_AXI_wready;
  assign m04_couplers_to_ctrl_ic_ARREADY = M04_AXI_arready;
  assign m04_couplers_to_ctrl_ic_AWREADY = M04_AXI_awready;
  assign m04_couplers_to_ctrl_ic_BRESP = M04_AXI_bresp[1:0];
  assign m04_couplers_to_ctrl_ic_BVALID = M04_AXI_bvalid;
  assign m04_couplers_to_ctrl_ic_RDATA = M04_AXI_rdata[31:0];
  assign m04_couplers_to_ctrl_ic_RRESP = M04_AXI_rresp[1:0];
  assign m04_couplers_to_ctrl_ic_RVALID = M04_AXI_rvalid;
  assign m04_couplers_to_ctrl_ic_WREADY = M04_AXI_wready;
  assign m05_couplers_to_ctrl_ic_ARREADY = M05_AXI_arready;
  assign m05_couplers_to_ctrl_ic_AWREADY = M05_AXI_awready;
  assign m05_couplers_to_ctrl_ic_BRESP = M05_AXI_bresp[1:0];
  assign m05_couplers_to_ctrl_ic_BVALID = M05_AXI_bvalid;
  assign m05_couplers_to_ctrl_ic_RDATA = M05_AXI_rdata[31:0];
  assign m05_couplers_to_ctrl_ic_RRESP = M05_AXI_rresp[1:0];
  assign m05_couplers_to_ctrl_ic_RVALID = M05_AXI_rvalid;
  assign m05_couplers_to_ctrl_ic_WREADY = M05_AXI_wready;
  assign m06_couplers_to_ctrl_ic_ARREADY = M06_AXI_arready;
  assign m06_couplers_to_ctrl_ic_AWREADY = M06_AXI_awready;
  assign m06_couplers_to_ctrl_ic_BRESP = M06_AXI_bresp[1:0];
  assign m06_couplers_to_ctrl_ic_BVALID = M06_AXI_bvalid;
  assign m06_couplers_to_ctrl_ic_RDATA = M06_AXI_rdata[31:0];
  assign m06_couplers_to_ctrl_ic_RRESP = M06_AXI_rresp[1:0];
  assign m06_couplers_to_ctrl_ic_RVALID = M06_AXI_rvalid;
  assign m06_couplers_to_ctrl_ic_WREADY = M06_AXI_wready;
  assign m07_couplers_to_ctrl_ic_ARREADY = M07_AXI_arready;
  assign m07_couplers_to_ctrl_ic_AWREADY = M07_AXI_awready;
  assign m07_couplers_to_ctrl_ic_BRESP = M07_AXI_bresp[1:0];
  assign m07_couplers_to_ctrl_ic_BVALID = M07_AXI_bvalid;
  assign m07_couplers_to_ctrl_ic_RDATA = M07_AXI_rdata[31:0];
  assign m07_couplers_to_ctrl_ic_RRESP = M07_AXI_rresp[1:0];
  assign m07_couplers_to_ctrl_ic_RVALID = M07_AXI_rvalid;
  assign m07_couplers_to_ctrl_ic_WREADY = M07_AXI_wready;
  assign m08_couplers_to_ctrl_ic_ARREADY = M08_AXI_arready;
  assign m08_couplers_to_ctrl_ic_AWREADY = M08_AXI_awready;
  assign m08_couplers_to_ctrl_ic_BRESP = M08_AXI_bresp[1:0];
  assign m08_couplers_to_ctrl_ic_BVALID = M08_AXI_bvalid;
  assign m08_couplers_to_ctrl_ic_RDATA = M08_AXI_rdata[31:0];
  assign m08_couplers_to_ctrl_ic_RRESP = M08_AXI_rresp[1:0];
  assign m08_couplers_to_ctrl_ic_RVALID = M08_AXI_rvalid;
  assign m08_couplers_to_ctrl_ic_WREADY = M08_AXI_wready;
  m00_couplers_imp_5K4V01 m00_couplers
       (.M_ACLK(M00_ACLK_1),
        .M_ARESETN(M00_ARESETN_1),
        .M_AXI_araddr(m00_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arready(m00_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m00_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m00_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awready(m00_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m00_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m00_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m00_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m00_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m00_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m00_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m00_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m00_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m00_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m00_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wvalid(m00_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m00_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m00_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m00_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m00_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m00_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m00_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m00_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m00_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m00_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m00_couplers_RDATA),
        .S_AXI_rready(xbar_to_m00_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m00_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m00_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m00_couplers_WDATA),
        .S_AXI_wready(xbar_to_m00_couplers_WREADY),
        .S_AXI_wvalid(xbar_to_m00_couplers_WVALID));
  m01_couplers_imp_1ICZYJT m01_couplers
       (.M_ACLK(M01_ACLK_1),
        .M_ARESETN(M01_ARESETN_1),
        .M_AXI_araddr(m01_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arready(m01_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m01_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m01_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awready(m01_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m01_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m01_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m01_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m01_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m01_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m01_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m01_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m01_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m01_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m01_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wvalid(m01_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m01_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m01_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m01_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m01_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m01_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m01_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m01_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m01_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m01_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m01_couplers_RDATA),
        .S_AXI_rready(xbar_to_m01_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m01_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m01_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m01_couplers_WDATA),
        .S_AXI_wready(xbar_to_m01_couplers_WREADY),
        .S_AXI_wvalid(xbar_to_m01_couplers_WVALID));
  m02_couplers_imp_QUATQ8 m02_couplers
       (.M_ACLK(M02_ACLK_1),
        .M_ARESETN(M02_ARESETN_1),
        .M_AXI_araddr(m02_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arready(m02_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m02_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m02_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awready(m02_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m02_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m02_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m02_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m02_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m02_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m02_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m02_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m02_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m02_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m02_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wstrb(m02_couplers_to_ctrl_ic_WSTRB),
        .M_AXI_wvalid(m02_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m02_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m02_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m02_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m02_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m02_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m02_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m02_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m02_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m02_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m02_couplers_RDATA),
        .S_AXI_rready(xbar_to_m02_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m02_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m02_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m02_couplers_WDATA),
        .S_AXI_wready(xbar_to_m02_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m02_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m02_couplers_WVALID));
  m03_couplers_imp_1EVO5ZS m03_couplers
       (.M_ACLK(M03_ACLK_1),
        .M_ARESETN(M03_ARESETN_1),
        .M_AXI_araddr(m03_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arprot(m03_couplers_to_ctrl_ic_ARPROT),
        .M_AXI_arready(m03_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m03_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m03_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awprot(m03_couplers_to_ctrl_ic_AWPROT),
        .M_AXI_awready(m03_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m03_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m03_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m03_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m03_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m03_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m03_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m03_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m03_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m03_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m03_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wstrb(m03_couplers_to_ctrl_ic_WSTRB),
        .M_AXI_wvalid(m03_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m03_couplers_ARADDR),
        .S_AXI_arprot(xbar_to_m03_couplers_ARPROT),
        .S_AXI_arready(xbar_to_m03_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m03_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m03_couplers_AWADDR),
        .S_AXI_awprot(xbar_to_m03_couplers_AWPROT),
        .S_AXI_awready(xbar_to_m03_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m03_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m03_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m03_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m03_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m03_couplers_RDATA),
        .S_AXI_rready(xbar_to_m03_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m03_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m03_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m03_couplers_WDATA),
        .S_AXI_wready(xbar_to_m03_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m03_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m03_couplers_WVALID));
  m04_couplers_imp_1YAXSER m04_couplers
       (.M_ACLK(M04_ACLK_1),
        .M_ARESETN(M04_ARESETN_1),
        .M_AXI_araddr(m04_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arready(m04_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m04_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m04_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awready(m04_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m04_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m04_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m04_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m04_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m04_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m04_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m04_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m04_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m04_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m04_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wvalid(m04_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m04_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m04_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m04_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m04_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m04_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m04_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m04_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m04_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m04_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m04_couplers_RDATA),
        .S_AXI_rready(xbar_to_m04_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m04_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m04_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m04_couplers_WDATA),
        .S_AXI_wready(xbar_to_m04_couplers_WREADY),
        .S_AXI_wvalid(xbar_to_m04_couplers_WVALID));
  m05_couplers_imp_BSNXAJ m05_couplers
       (.M_ACLK(M05_ACLK_1),
        .M_ARESETN(M05_ARESETN_1),
        .M_AXI_araddr(m05_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arready(m05_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m05_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m05_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awready(m05_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m05_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m05_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m05_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m05_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m05_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m05_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m05_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m05_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m05_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m05_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wstrb(m05_couplers_to_ctrl_ic_WSTRB),
        .M_AXI_wvalid(m05_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m05_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m05_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m05_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m05_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m05_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m05_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m05_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m05_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m05_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m05_couplers_RDATA),
        .S_AXI_rready(xbar_to_m05_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m05_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m05_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m05_couplers_WDATA),
        .S_AXI_wready(xbar_to_m05_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m05_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m05_couplers_WVALID));
  m06_couplers_imp_128RV8I m06_couplers
       (.M_ACLK(M06_ACLK_1),
        .M_ARESETN(M06_ARESETN_1),
        .M_AXI_araddr(m06_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arready(m06_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m06_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m06_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awready(m06_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m06_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m06_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m06_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m06_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m06_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m06_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m06_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m06_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m06_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m06_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wvalid(m06_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m06_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m06_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m06_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m06_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m06_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m06_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m06_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m06_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m06_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m06_couplers_RDATA),
        .S_AXI_rready(xbar_to_m06_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m06_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m06_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m06_couplers_WDATA),
        .S_AXI_wready(xbar_to_m06_couplers_WREADY),
        .S_AXI_wvalid(xbar_to_m06_couplers_WVALID));
  m07_couplers_imp_Q543AY m07_couplers
       (.M_ACLK(M07_ACLK_1),
        .M_ARESETN(M07_ARESETN_1),
        .M_AXI_araddr(m07_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arready(m07_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m07_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m07_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awready(m07_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m07_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m07_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m07_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m07_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m07_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m07_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m07_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m07_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m07_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m07_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wvalid(m07_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m07_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m07_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m07_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m07_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m07_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m07_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m07_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m07_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m07_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m07_couplers_RDATA),
        .S_AXI_rready(xbar_to_m07_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m07_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m07_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m07_couplers_WDATA),
        .S_AXI_wready(xbar_to_m07_couplers_WREADY),
        .S_AXI_wvalid(xbar_to_m07_couplers_WVALID));
  m08_couplers_imp_888DX0 m08_couplers
       (.M_ACLK(M08_ACLK_1),
        .M_ARESETN(M08_ARESETN_1),
        .M_AXI_araddr(m08_couplers_to_ctrl_ic_ARADDR),
        .M_AXI_arready(m08_couplers_to_ctrl_ic_ARREADY),
        .M_AXI_arvalid(m08_couplers_to_ctrl_ic_ARVALID),
        .M_AXI_awaddr(m08_couplers_to_ctrl_ic_AWADDR),
        .M_AXI_awready(m08_couplers_to_ctrl_ic_AWREADY),
        .M_AXI_awvalid(m08_couplers_to_ctrl_ic_AWVALID),
        .M_AXI_bready(m08_couplers_to_ctrl_ic_BREADY),
        .M_AXI_bresp(m08_couplers_to_ctrl_ic_BRESP),
        .M_AXI_bvalid(m08_couplers_to_ctrl_ic_BVALID),
        .M_AXI_rdata(m08_couplers_to_ctrl_ic_RDATA),
        .M_AXI_rready(m08_couplers_to_ctrl_ic_RREADY),
        .M_AXI_rresp(m08_couplers_to_ctrl_ic_RRESP),
        .M_AXI_rvalid(m08_couplers_to_ctrl_ic_RVALID),
        .M_AXI_wdata(m08_couplers_to_ctrl_ic_WDATA),
        .M_AXI_wready(m08_couplers_to_ctrl_ic_WREADY),
        .M_AXI_wstrb(m08_couplers_to_ctrl_ic_WSTRB),
        .M_AXI_wvalid(m08_couplers_to_ctrl_ic_WVALID),
        .S_ACLK(ctrl_ic_ACLK_net),
        .S_ARESETN(ctrl_ic_ARESETN_net),
        .S_AXI_araddr(xbar_to_m08_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m08_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m08_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m08_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m08_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m08_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m08_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m08_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m08_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m08_couplers_RDATA),
        .S_AXI_rready(xbar_to_m08_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m08_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m08_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m08_couplers_WDATA),
        .S_AXI_wready(xbar_to_m08_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m08_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m08_couplers_WVALID));
  s00_couplers_imp_12VR3XP s00_couplers
       (.M_ACLK(ctrl_ic_ACLK_net),
        .M_ARESETN(ctrl_ic_ARESETN_net),
        .M_AXI_araddr(s00_couplers_to_xbar_ARADDR),
        .M_AXI_arprot(s00_couplers_to_xbar_ARPROT),
        .M_AXI_arready(s00_couplers_to_xbar_ARREADY),
        .M_AXI_arvalid(s00_couplers_to_xbar_ARVALID),
        .M_AXI_awaddr(s00_couplers_to_xbar_AWADDR),
        .M_AXI_awprot(s00_couplers_to_xbar_AWPROT),
        .M_AXI_awready(s00_couplers_to_xbar_AWREADY),
        .M_AXI_awvalid(s00_couplers_to_xbar_AWVALID),
        .M_AXI_bready(s00_couplers_to_xbar_BREADY),
        .M_AXI_bresp(s00_couplers_to_xbar_BRESP),
        .M_AXI_bvalid(s00_couplers_to_xbar_BVALID),
        .M_AXI_rdata(s00_couplers_to_xbar_RDATA),
        .M_AXI_rready(s00_couplers_to_xbar_RREADY),
        .M_AXI_rresp(s00_couplers_to_xbar_RRESP),
        .M_AXI_rvalid(s00_couplers_to_xbar_RVALID),
        .M_AXI_wdata(s00_couplers_to_xbar_WDATA),
        .M_AXI_wready(s00_couplers_to_xbar_WREADY),
        .M_AXI_wstrb(s00_couplers_to_xbar_WSTRB),
        .M_AXI_wvalid(s00_couplers_to_xbar_WVALID),
        .S_ACLK(S00_ACLK_1),
        .S_ARESETN(S00_ARESETN_1),
        .S_AXI_araddr(ctrl_ic_to_s00_couplers_ARADDR),
        .S_AXI_arburst(ctrl_ic_to_s00_couplers_ARBURST),
        .S_AXI_arcache(ctrl_ic_to_s00_couplers_ARCACHE),
        .S_AXI_arid(ctrl_ic_to_s00_couplers_ARID),
        .S_AXI_arlen(ctrl_ic_to_s00_couplers_ARLEN),
        .S_AXI_arlock(ctrl_ic_to_s00_couplers_ARLOCK),
        .S_AXI_arprot(ctrl_ic_to_s00_couplers_ARPROT),
        .S_AXI_arqos(ctrl_ic_to_s00_couplers_ARQOS),
        .S_AXI_arready(ctrl_ic_to_s00_couplers_ARREADY),
        .S_AXI_arsize(ctrl_ic_to_s00_couplers_ARSIZE),
        .S_AXI_arvalid(ctrl_ic_to_s00_couplers_ARVALID),
        .S_AXI_awaddr(ctrl_ic_to_s00_couplers_AWADDR),
        .S_AXI_awburst(ctrl_ic_to_s00_couplers_AWBURST),
        .S_AXI_awcache(ctrl_ic_to_s00_couplers_AWCACHE),
        .S_AXI_awid(ctrl_ic_to_s00_couplers_AWID),
        .S_AXI_awlen(ctrl_ic_to_s00_couplers_AWLEN),
        .S_AXI_awlock(ctrl_ic_to_s00_couplers_AWLOCK),
        .S_AXI_awprot(ctrl_ic_to_s00_couplers_AWPROT),
        .S_AXI_awqos(ctrl_ic_to_s00_couplers_AWQOS),
        .S_AXI_awready(ctrl_ic_to_s00_couplers_AWREADY),
        .S_AXI_awsize(ctrl_ic_to_s00_couplers_AWSIZE),
        .S_AXI_awvalid(ctrl_ic_to_s00_couplers_AWVALID),
        .S_AXI_bid(ctrl_ic_to_s00_couplers_BID),
        .S_AXI_bready(ctrl_ic_to_s00_couplers_BREADY),
        .S_AXI_bresp(ctrl_ic_to_s00_couplers_BRESP),
        .S_AXI_bvalid(ctrl_ic_to_s00_couplers_BVALID),
        .S_AXI_rdata(ctrl_ic_to_s00_couplers_RDATA),
        .S_AXI_rid(ctrl_ic_to_s00_couplers_RID),
        .S_AXI_rlast(ctrl_ic_to_s00_couplers_RLAST),
        .S_AXI_rready(ctrl_ic_to_s00_couplers_RREADY),
        .S_AXI_rresp(ctrl_ic_to_s00_couplers_RRESP),
        .S_AXI_rvalid(ctrl_ic_to_s00_couplers_RVALID),
        .S_AXI_wdata(ctrl_ic_to_s00_couplers_WDATA),
        .S_AXI_wid(ctrl_ic_to_s00_couplers_WID),
        .S_AXI_wlast(ctrl_ic_to_s00_couplers_WLAST),
        .S_AXI_wready(ctrl_ic_to_s00_couplers_WREADY),
        .S_AXI_wstrb(ctrl_ic_to_s00_couplers_WSTRB),
        .S_AXI_wvalid(ctrl_ic_to_s00_couplers_WVALID));
  av_system_xbar_0 xbar
       (.aclk(ctrl_ic_ACLK_net),
        .aresetn(ctrl_ic_ARESETN_net),
        .m_axi_araddr({xbar_to_m08_couplers_ARADDR,xbar_to_m07_couplers_ARADDR,xbar_to_m06_couplers_ARADDR,xbar_to_m05_couplers_ARADDR,xbar_to_m04_couplers_ARADDR,xbar_to_m03_couplers_ARADDR,xbar_to_m02_couplers_ARADDR,xbar_to_m01_couplers_ARADDR,xbar_to_m00_couplers_ARADDR}),
        .m_axi_arprot({xbar_to_m03_couplers_ARPROT,NLW_xbar_m_axi_arprot_UNCONNECTED[8:0]}),
        .m_axi_arready({xbar_to_m08_couplers_ARREADY,xbar_to_m07_couplers_ARREADY,xbar_to_m06_couplers_ARREADY,xbar_to_m05_couplers_ARREADY,xbar_to_m04_couplers_ARREADY,xbar_to_m03_couplers_ARREADY,xbar_to_m02_couplers_ARREADY,xbar_to_m01_couplers_ARREADY,xbar_to_m00_couplers_ARREADY}),
        .m_axi_arvalid({xbar_to_m08_couplers_ARVALID,xbar_to_m07_couplers_ARVALID,xbar_to_m06_couplers_ARVALID,xbar_to_m05_couplers_ARVALID,xbar_to_m04_couplers_ARVALID,xbar_to_m03_couplers_ARVALID,xbar_to_m02_couplers_ARVALID,xbar_to_m01_couplers_ARVALID,xbar_to_m00_couplers_ARVALID}),
        .m_axi_awaddr({xbar_to_m08_couplers_AWADDR,xbar_to_m07_couplers_AWADDR,xbar_to_m06_couplers_AWADDR,xbar_to_m05_couplers_AWADDR,xbar_to_m04_couplers_AWADDR,xbar_to_m03_couplers_AWADDR,xbar_to_m02_couplers_AWADDR,xbar_to_m01_couplers_AWADDR,xbar_to_m00_couplers_AWADDR}),
        .m_axi_awprot({xbar_to_m03_couplers_AWPROT,NLW_xbar_m_axi_awprot_UNCONNECTED[8:0]}),
        .m_axi_awready({xbar_to_m08_couplers_AWREADY,xbar_to_m07_couplers_AWREADY,xbar_to_m06_couplers_AWREADY,xbar_to_m05_couplers_AWREADY,xbar_to_m04_couplers_AWREADY,xbar_to_m03_couplers_AWREADY,xbar_to_m02_couplers_AWREADY,xbar_to_m01_couplers_AWREADY,xbar_to_m00_couplers_AWREADY}),
        .m_axi_awvalid({xbar_to_m08_couplers_AWVALID,xbar_to_m07_couplers_AWVALID,xbar_to_m06_couplers_AWVALID,xbar_to_m05_couplers_AWVALID,xbar_to_m04_couplers_AWVALID,xbar_to_m03_couplers_AWVALID,xbar_to_m02_couplers_AWVALID,xbar_to_m01_couplers_AWVALID,xbar_to_m00_couplers_AWVALID}),
        .m_axi_bready({xbar_to_m08_couplers_BREADY,xbar_to_m07_couplers_BREADY,xbar_to_m06_couplers_BREADY,xbar_to_m05_couplers_BREADY,xbar_to_m04_couplers_BREADY,xbar_to_m03_couplers_BREADY,xbar_to_m02_couplers_BREADY,xbar_to_m01_couplers_BREADY,xbar_to_m00_couplers_BREADY}),
        .m_axi_bresp({xbar_to_m08_couplers_BRESP,xbar_to_m07_couplers_BRESP,xbar_to_m06_couplers_BRESP,xbar_to_m05_couplers_BRESP,xbar_to_m04_couplers_BRESP,xbar_to_m03_couplers_BRESP,xbar_to_m02_couplers_BRESP,xbar_to_m01_couplers_BRESP,xbar_to_m00_couplers_BRESP}),
        .m_axi_bvalid({xbar_to_m08_couplers_BVALID,xbar_to_m07_couplers_BVALID,xbar_to_m06_couplers_BVALID,xbar_to_m05_couplers_BVALID,xbar_to_m04_couplers_BVALID,xbar_to_m03_couplers_BVALID,xbar_to_m02_couplers_BVALID,xbar_to_m01_couplers_BVALID,xbar_to_m00_couplers_BVALID}),
        .m_axi_rdata({xbar_to_m08_couplers_RDATA,xbar_to_m07_couplers_RDATA,xbar_to_m06_couplers_RDATA,xbar_to_m05_couplers_RDATA,xbar_to_m04_couplers_RDATA,xbar_to_m03_couplers_RDATA,xbar_to_m02_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m00_couplers_RDATA}),
        .m_axi_rready({xbar_to_m08_couplers_RREADY,xbar_to_m07_couplers_RREADY,xbar_to_m06_couplers_RREADY,xbar_to_m05_couplers_RREADY,xbar_to_m04_couplers_RREADY,xbar_to_m03_couplers_RREADY,xbar_to_m02_couplers_RREADY,xbar_to_m01_couplers_RREADY,xbar_to_m00_couplers_RREADY}),
        .m_axi_rresp({xbar_to_m08_couplers_RRESP,xbar_to_m07_couplers_RRESP,xbar_to_m06_couplers_RRESP,xbar_to_m05_couplers_RRESP,xbar_to_m04_couplers_RRESP,xbar_to_m03_couplers_RRESP,xbar_to_m02_couplers_RRESP,xbar_to_m01_couplers_RRESP,xbar_to_m00_couplers_RRESP}),
        .m_axi_rvalid({xbar_to_m08_couplers_RVALID,xbar_to_m07_couplers_RVALID,xbar_to_m06_couplers_RVALID,xbar_to_m05_couplers_RVALID,xbar_to_m04_couplers_RVALID,xbar_to_m03_couplers_RVALID,xbar_to_m02_couplers_RVALID,xbar_to_m01_couplers_RVALID,xbar_to_m00_couplers_RVALID}),
        .m_axi_wdata({xbar_to_m08_couplers_WDATA,xbar_to_m07_couplers_WDATA,xbar_to_m06_couplers_WDATA,xbar_to_m05_couplers_WDATA,xbar_to_m04_couplers_WDATA,xbar_to_m03_couplers_WDATA,xbar_to_m02_couplers_WDATA,xbar_to_m01_couplers_WDATA,xbar_to_m00_couplers_WDATA}),
        .m_axi_wready({xbar_to_m08_couplers_WREADY,xbar_to_m07_couplers_WREADY,xbar_to_m06_couplers_WREADY,xbar_to_m05_couplers_WREADY,xbar_to_m04_couplers_WREADY,xbar_to_m03_couplers_WREADY,xbar_to_m02_couplers_WREADY,xbar_to_m01_couplers_WREADY,xbar_to_m00_couplers_WREADY}),
        .m_axi_wstrb({xbar_to_m08_couplers_WSTRB,NLW_xbar_m_axi_wstrb_UNCONNECTED[31:24],xbar_to_m05_couplers_WSTRB,NLW_xbar_m_axi_wstrb_UNCONNECTED[19:16],xbar_to_m03_couplers_WSTRB,xbar_to_m02_couplers_WSTRB,NLW_xbar_m_axi_wstrb_UNCONNECTED[7:0]}),
        .m_axi_wvalid({xbar_to_m08_couplers_WVALID,xbar_to_m07_couplers_WVALID,xbar_to_m06_couplers_WVALID,xbar_to_m05_couplers_WVALID,xbar_to_m04_couplers_WVALID,xbar_to_m03_couplers_WVALID,xbar_to_m02_couplers_WVALID,xbar_to_m01_couplers_WVALID,xbar_to_m00_couplers_WVALID}),
        .s_axi_araddr(s00_couplers_to_xbar_ARADDR),
        .s_axi_arprot(s00_couplers_to_xbar_ARPROT),
        .s_axi_arready(s00_couplers_to_xbar_ARREADY),
        .s_axi_arvalid(s00_couplers_to_xbar_ARVALID),
        .s_axi_awaddr(s00_couplers_to_xbar_AWADDR),
        .s_axi_awprot(s00_couplers_to_xbar_AWPROT),
        .s_axi_awready(s00_couplers_to_xbar_AWREADY),
        .s_axi_awvalid(s00_couplers_to_xbar_AWVALID),
        .s_axi_bready(s00_couplers_to_xbar_BREADY),
        .s_axi_bresp(s00_couplers_to_xbar_BRESP),
        .s_axi_bvalid(s00_couplers_to_xbar_BVALID),
        .s_axi_rdata(s00_couplers_to_xbar_RDATA),
        .s_axi_rready(s00_couplers_to_xbar_RREADY),
        .s_axi_rresp(s00_couplers_to_xbar_RRESP),
        .s_axi_rvalid(s00_couplers_to_xbar_RVALID),
        .s_axi_wdata(s00_couplers_to_xbar_WDATA),
        .s_axi_wready(s00_couplers_to_xbar_WREADY),
        .s_axi_wstrb(s00_couplers_to_xbar_WSTRB),
        .s_axi_wvalid(s00_couplers_to_xbar_WVALID));
endmodule

module av_system_hdmi_memory_0
   (ACLK,
    ARESETN,
    M00_ACLK,
    M00_ARESETN,
    M00_AXI_araddr,
    M00_AXI_arburst,
    M00_AXI_arcache,
    M00_AXI_arid,
    M00_AXI_arlen,
    M00_AXI_arlock,
    M00_AXI_arprot,
    M00_AXI_arqos,
    M00_AXI_arready,
    M00_AXI_arsize,
    M00_AXI_arvalid,
    M00_AXI_awaddr,
    M00_AXI_awburst,
    M00_AXI_awcache,
    M00_AXI_awid,
    M00_AXI_awlen,
    M00_AXI_awlock,
    M00_AXI_awprot,
    M00_AXI_awqos,
    M00_AXI_awready,
    M00_AXI_awsize,
    M00_AXI_awvalid,
    M00_AXI_bid,
    M00_AXI_bready,
    M00_AXI_bresp,
    M00_AXI_bvalid,
    M00_AXI_rdata,
    M00_AXI_rid,
    M00_AXI_rlast,
    M00_AXI_rready,
    M00_AXI_rresp,
    M00_AXI_rvalid,
    M00_AXI_wdata,
    M00_AXI_wid,
    M00_AXI_wlast,
    M00_AXI_wready,
    M00_AXI_wstrb,
    M00_AXI_wvalid,
    S00_ACLK,
    S00_ARESETN,
    S00_AXI_awaddr,
    S00_AXI_awburst,
    S00_AXI_awcache,
    S00_AXI_awlen,
    S00_AXI_awlock,
    S00_AXI_awprot,
    S00_AXI_awqos,
    S00_AXI_awready,
    S00_AXI_awsize,
    S00_AXI_awvalid,
    S00_AXI_bready,
    S00_AXI_bresp,
    S00_AXI_bvalid,
    S00_AXI_wdata,
    S00_AXI_wlast,
    S00_AXI_wready,
    S00_AXI_wstrb,
    S00_AXI_wvalid,
    S01_ACLK,
    S01_ARESETN,
    S01_AXI_araddr,
    S01_AXI_arburst,
    S01_AXI_arcache,
    S01_AXI_arlen,
    S01_AXI_arprot,
    S01_AXI_arready,
    S01_AXI_arsize,
    S01_AXI_arvalid,
    S01_AXI_rdata,
    S01_AXI_rlast,
    S01_AXI_rready,
    S01_AXI_rresp,
    S01_AXI_rvalid);
  input ACLK;
  input ARESETN;
  input M00_ACLK;
  input M00_ARESETN;
  output [31:0]M00_AXI_araddr;
  output [1:0]M00_AXI_arburst;
  output [3:0]M00_AXI_arcache;
  output [0:0]M00_AXI_arid;
  output [3:0]M00_AXI_arlen;
  output [1:0]M00_AXI_arlock;
  output [2:0]M00_AXI_arprot;
  output [3:0]M00_AXI_arqos;
  input M00_AXI_arready;
  output [2:0]M00_AXI_arsize;
  output M00_AXI_arvalid;
  output [31:0]M00_AXI_awaddr;
  output [1:0]M00_AXI_awburst;
  output [3:0]M00_AXI_awcache;
  output [0:0]M00_AXI_awid;
  output [3:0]M00_AXI_awlen;
  output [1:0]M00_AXI_awlock;
  output [2:0]M00_AXI_awprot;
  output [3:0]M00_AXI_awqos;
  input M00_AXI_awready;
  output [2:0]M00_AXI_awsize;
  output M00_AXI_awvalid;
  input [5:0]M00_AXI_bid;
  output M00_AXI_bready;
  input [1:0]M00_AXI_bresp;
  input M00_AXI_bvalid;
  input [63:0]M00_AXI_rdata;
  input [5:0]M00_AXI_rid;
  input M00_AXI_rlast;
  output M00_AXI_rready;
  input [1:0]M00_AXI_rresp;
  input M00_AXI_rvalid;
  output [63:0]M00_AXI_wdata;
  output [0:0]M00_AXI_wid;
  output M00_AXI_wlast;
  input M00_AXI_wready;
  output [7:0]M00_AXI_wstrb;
  output M00_AXI_wvalid;
  input S00_ACLK;
  input S00_ARESETN;
  input [31:0]S00_AXI_awaddr;
  input [1:0]S00_AXI_awburst;
  input [3:0]S00_AXI_awcache;
  input [3:0]S00_AXI_awlen;
  input [1:0]S00_AXI_awlock;
  input [2:0]S00_AXI_awprot;
  input [3:0]S00_AXI_awqos;
  output S00_AXI_awready;
  input [2:0]S00_AXI_awsize;
  input S00_AXI_awvalid;
  input S00_AXI_bready;
  output [1:0]S00_AXI_bresp;
  output S00_AXI_bvalid;
  input [63:0]S00_AXI_wdata;
  input S00_AXI_wlast;
  output S00_AXI_wready;
  input [7:0]S00_AXI_wstrb;
  input S00_AXI_wvalid;
  input S01_ACLK;
  input S01_ARESETN;
  input [31:0]S01_AXI_araddr;
  input [1:0]S01_AXI_arburst;
  input [3:0]S01_AXI_arcache;
  input [7:0]S01_AXI_arlen;
  input [2:0]S01_AXI_arprot;
  output S01_AXI_arready;
  input [2:0]S01_AXI_arsize;
  input S01_AXI_arvalid;
  output [63:0]S01_AXI_rdata;
  output S01_AXI_rlast;
  input S01_AXI_rready;
  output [1:0]S01_AXI_rresp;
  output S01_AXI_rvalid;

  wire M00_ACLK_1;
  wire M00_ARESETN_1;
  wire S00_ACLK_1;
  wire S00_ARESETN_1;
  wire S01_ACLK_1;
  wire S01_ARESETN_1;
  wire hdmi_memory_ACLK_net;
  wire hdmi_memory_ARESETN_net;
  wire [31:0]hdmi_memory_to_s00_couplers_AWADDR;
  wire [1:0]hdmi_memory_to_s00_couplers_AWBURST;
  wire [3:0]hdmi_memory_to_s00_couplers_AWCACHE;
  wire [3:0]hdmi_memory_to_s00_couplers_AWLEN;
  wire [1:0]hdmi_memory_to_s00_couplers_AWLOCK;
  wire [2:0]hdmi_memory_to_s00_couplers_AWPROT;
  wire [3:0]hdmi_memory_to_s00_couplers_AWQOS;
  wire hdmi_memory_to_s00_couplers_AWREADY;
  wire [2:0]hdmi_memory_to_s00_couplers_AWSIZE;
  wire hdmi_memory_to_s00_couplers_AWVALID;
  wire hdmi_memory_to_s00_couplers_BREADY;
  wire [1:0]hdmi_memory_to_s00_couplers_BRESP;
  wire hdmi_memory_to_s00_couplers_BVALID;
  wire [63:0]hdmi_memory_to_s00_couplers_WDATA;
  wire hdmi_memory_to_s00_couplers_WLAST;
  wire hdmi_memory_to_s00_couplers_WREADY;
  wire [7:0]hdmi_memory_to_s00_couplers_WSTRB;
  wire hdmi_memory_to_s00_couplers_WVALID;
  wire [31:0]hdmi_memory_to_s01_couplers_ARADDR;
  wire [1:0]hdmi_memory_to_s01_couplers_ARBURST;
  wire [3:0]hdmi_memory_to_s01_couplers_ARCACHE;
  wire [7:0]hdmi_memory_to_s01_couplers_ARLEN;
  wire [2:0]hdmi_memory_to_s01_couplers_ARPROT;
  wire hdmi_memory_to_s01_couplers_ARREADY;
  wire [2:0]hdmi_memory_to_s01_couplers_ARSIZE;
  wire hdmi_memory_to_s01_couplers_ARVALID;
  wire [63:0]hdmi_memory_to_s01_couplers_RDATA;
  wire hdmi_memory_to_s01_couplers_RLAST;
  wire hdmi_memory_to_s01_couplers_RREADY;
  wire [1:0]hdmi_memory_to_s01_couplers_RRESP;
  wire hdmi_memory_to_s01_couplers_RVALID;
  wire [31:0]m00_couplers_to_hdmi_memory_ARADDR;
  wire [1:0]m00_couplers_to_hdmi_memory_ARBURST;
  wire [3:0]m00_couplers_to_hdmi_memory_ARCACHE;
  wire [0:0]m00_couplers_to_hdmi_memory_ARID;
  wire [3:0]m00_couplers_to_hdmi_memory_ARLEN;
  wire [1:0]m00_couplers_to_hdmi_memory_ARLOCK;
  wire [2:0]m00_couplers_to_hdmi_memory_ARPROT;
  wire [3:0]m00_couplers_to_hdmi_memory_ARQOS;
  wire m00_couplers_to_hdmi_memory_ARREADY;
  wire [2:0]m00_couplers_to_hdmi_memory_ARSIZE;
  wire m00_couplers_to_hdmi_memory_ARVALID;
  wire [31:0]m00_couplers_to_hdmi_memory_AWADDR;
  wire [1:0]m00_couplers_to_hdmi_memory_AWBURST;
  wire [3:0]m00_couplers_to_hdmi_memory_AWCACHE;
  wire [0:0]m00_couplers_to_hdmi_memory_AWID;
  wire [3:0]m00_couplers_to_hdmi_memory_AWLEN;
  wire [1:0]m00_couplers_to_hdmi_memory_AWLOCK;
  wire [2:0]m00_couplers_to_hdmi_memory_AWPROT;
  wire [3:0]m00_couplers_to_hdmi_memory_AWQOS;
  wire m00_couplers_to_hdmi_memory_AWREADY;
  wire [2:0]m00_couplers_to_hdmi_memory_AWSIZE;
  wire m00_couplers_to_hdmi_memory_AWVALID;
  wire [5:0]m00_couplers_to_hdmi_memory_BID;
  wire m00_couplers_to_hdmi_memory_BREADY;
  wire [1:0]m00_couplers_to_hdmi_memory_BRESP;
  wire m00_couplers_to_hdmi_memory_BVALID;
  wire [63:0]m00_couplers_to_hdmi_memory_RDATA;
  wire [5:0]m00_couplers_to_hdmi_memory_RID;
  wire m00_couplers_to_hdmi_memory_RLAST;
  wire m00_couplers_to_hdmi_memory_RREADY;
  wire [1:0]m00_couplers_to_hdmi_memory_RRESP;
  wire m00_couplers_to_hdmi_memory_RVALID;
  wire [63:0]m00_couplers_to_hdmi_memory_WDATA;
  wire [0:0]m00_couplers_to_hdmi_memory_WID;
  wire m00_couplers_to_hdmi_memory_WLAST;
  wire m00_couplers_to_hdmi_memory_WREADY;
  wire [7:0]m00_couplers_to_hdmi_memory_WSTRB;
  wire m00_couplers_to_hdmi_memory_WVALID;
  wire [31:0]s00_couplers_to_xbar_AWADDR;
  wire [1:0]s00_couplers_to_xbar_AWBURST;
  wire [3:0]s00_couplers_to_xbar_AWCACHE;
  wire [7:0]s00_couplers_to_xbar_AWLEN;
  wire [0:0]s00_couplers_to_xbar_AWLOCK;
  wire [2:0]s00_couplers_to_xbar_AWPROT;
  wire [3:0]s00_couplers_to_xbar_AWQOS;
  wire [0:0]s00_couplers_to_xbar_AWREADY;
  wire [2:0]s00_couplers_to_xbar_AWSIZE;
  wire s00_couplers_to_xbar_AWVALID;
  wire s00_couplers_to_xbar_BREADY;
  wire [1:0]s00_couplers_to_xbar_BRESP;
  wire [0:0]s00_couplers_to_xbar_BVALID;
  wire [63:0]s00_couplers_to_xbar_WDATA;
  wire s00_couplers_to_xbar_WLAST;
  wire [0:0]s00_couplers_to_xbar_WREADY;
  wire [7:0]s00_couplers_to_xbar_WSTRB;
  wire s00_couplers_to_xbar_WVALID;
  wire [31:0]s01_couplers_to_xbar_ARADDR;
  wire [1:0]s01_couplers_to_xbar_ARBURST;
  wire [3:0]s01_couplers_to_xbar_ARCACHE;
  wire [7:0]s01_couplers_to_xbar_ARLEN;
  wire [0:0]s01_couplers_to_xbar_ARLOCK;
  wire [2:0]s01_couplers_to_xbar_ARPROT;
  wire [3:0]s01_couplers_to_xbar_ARQOS;
  wire [1:1]s01_couplers_to_xbar_ARREADY;
  wire [2:0]s01_couplers_to_xbar_ARSIZE;
  wire s01_couplers_to_xbar_ARVALID;
  wire [127:64]s01_couplers_to_xbar_RDATA;
  wire [1:1]s01_couplers_to_xbar_RLAST;
  wire s01_couplers_to_xbar_RREADY;
  wire [3:2]s01_couplers_to_xbar_RRESP;
  wire [1:1]s01_couplers_to_xbar_RVALID;
  wire [31:0]xbar_to_m00_couplers_ARADDR;
  wire [1:0]xbar_to_m00_couplers_ARBURST;
  wire [3:0]xbar_to_m00_couplers_ARCACHE;
  wire [0:0]xbar_to_m00_couplers_ARID;
  wire [7:0]xbar_to_m00_couplers_ARLEN;
  wire [0:0]xbar_to_m00_couplers_ARLOCK;
  wire [2:0]xbar_to_m00_couplers_ARPROT;
  wire [3:0]xbar_to_m00_couplers_ARQOS;
  wire xbar_to_m00_couplers_ARREADY;
  wire [3:0]xbar_to_m00_couplers_ARREGION;
  wire [2:0]xbar_to_m00_couplers_ARSIZE;
  wire [0:0]xbar_to_m00_couplers_ARVALID;
  wire [31:0]xbar_to_m00_couplers_AWADDR;
  wire [1:0]xbar_to_m00_couplers_AWBURST;
  wire [3:0]xbar_to_m00_couplers_AWCACHE;
  wire [0:0]xbar_to_m00_couplers_AWID;
  wire [7:0]xbar_to_m00_couplers_AWLEN;
  wire [0:0]xbar_to_m00_couplers_AWLOCK;
  wire [2:0]xbar_to_m00_couplers_AWPROT;
  wire [3:0]xbar_to_m00_couplers_AWQOS;
  wire xbar_to_m00_couplers_AWREADY;
  wire [3:0]xbar_to_m00_couplers_AWREGION;
  wire [2:0]xbar_to_m00_couplers_AWSIZE;
  wire [0:0]xbar_to_m00_couplers_AWVALID;
  wire [0:0]xbar_to_m00_couplers_BID;
  wire [0:0]xbar_to_m00_couplers_BREADY;
  wire [1:0]xbar_to_m00_couplers_BRESP;
  wire xbar_to_m00_couplers_BVALID;
  wire [63:0]xbar_to_m00_couplers_RDATA;
  wire [0:0]xbar_to_m00_couplers_RID;
  wire xbar_to_m00_couplers_RLAST;
  wire [0:0]xbar_to_m00_couplers_RREADY;
  wire [1:0]xbar_to_m00_couplers_RRESP;
  wire xbar_to_m00_couplers_RVALID;
  wire [63:0]xbar_to_m00_couplers_WDATA;
  wire [0:0]xbar_to_m00_couplers_WLAST;
  wire xbar_to_m00_couplers_WREADY;
  wire [7:0]xbar_to_m00_couplers_WSTRB;
  wire [0:0]xbar_to_m00_couplers_WVALID;
  wire [1:0]NLW_xbar_s_axi_arready_UNCONNECTED;
  wire [127:0]NLW_xbar_s_axi_rdata_UNCONNECTED;
  wire [1:0]NLW_xbar_s_axi_rlast_UNCONNECTED;
  wire [3:0]NLW_xbar_s_axi_rresp_UNCONNECTED;
  wire [1:0]NLW_xbar_s_axi_rvalid_UNCONNECTED;

  assign M00_ACLK_1 = M00_ACLK;
  assign M00_ARESETN_1 = M00_ARESETN;
  assign M00_AXI_araddr[31:0] = m00_couplers_to_hdmi_memory_ARADDR;
  assign M00_AXI_arburst[1:0] = m00_couplers_to_hdmi_memory_ARBURST;
  assign M00_AXI_arcache[3:0] = m00_couplers_to_hdmi_memory_ARCACHE;
  assign M00_AXI_arid[0] = m00_couplers_to_hdmi_memory_ARID;
  assign M00_AXI_arlen[3:0] = m00_couplers_to_hdmi_memory_ARLEN;
  assign M00_AXI_arlock[1:0] = m00_couplers_to_hdmi_memory_ARLOCK;
  assign M00_AXI_arprot[2:0] = m00_couplers_to_hdmi_memory_ARPROT;
  assign M00_AXI_arqos[3:0] = m00_couplers_to_hdmi_memory_ARQOS;
  assign M00_AXI_arsize[2:0] = m00_couplers_to_hdmi_memory_ARSIZE;
  assign M00_AXI_arvalid = m00_couplers_to_hdmi_memory_ARVALID;
  assign M00_AXI_awaddr[31:0] = m00_couplers_to_hdmi_memory_AWADDR;
  assign M00_AXI_awburst[1:0] = m00_couplers_to_hdmi_memory_AWBURST;
  assign M00_AXI_awcache[3:0] = m00_couplers_to_hdmi_memory_AWCACHE;
  assign M00_AXI_awid[0] = m00_couplers_to_hdmi_memory_AWID;
  assign M00_AXI_awlen[3:0] = m00_couplers_to_hdmi_memory_AWLEN;
  assign M00_AXI_awlock[1:0] = m00_couplers_to_hdmi_memory_AWLOCK;
  assign M00_AXI_awprot[2:0] = m00_couplers_to_hdmi_memory_AWPROT;
  assign M00_AXI_awqos[3:0] = m00_couplers_to_hdmi_memory_AWQOS;
  assign M00_AXI_awsize[2:0] = m00_couplers_to_hdmi_memory_AWSIZE;
  assign M00_AXI_awvalid = m00_couplers_to_hdmi_memory_AWVALID;
  assign M00_AXI_bready = m00_couplers_to_hdmi_memory_BREADY;
  assign M00_AXI_rready = m00_couplers_to_hdmi_memory_RREADY;
  assign M00_AXI_wdata[63:0] = m00_couplers_to_hdmi_memory_WDATA;
  assign M00_AXI_wid[0] = m00_couplers_to_hdmi_memory_WID;
  assign M00_AXI_wlast = m00_couplers_to_hdmi_memory_WLAST;
  assign M00_AXI_wstrb[7:0] = m00_couplers_to_hdmi_memory_WSTRB;
  assign M00_AXI_wvalid = m00_couplers_to_hdmi_memory_WVALID;
  assign S00_ACLK_1 = S00_ACLK;
  assign S00_ARESETN_1 = S00_ARESETN;
  assign S00_AXI_awready = hdmi_memory_to_s00_couplers_AWREADY;
  assign S00_AXI_bresp[1:0] = hdmi_memory_to_s00_couplers_BRESP;
  assign S00_AXI_bvalid = hdmi_memory_to_s00_couplers_BVALID;
  assign S00_AXI_wready = hdmi_memory_to_s00_couplers_WREADY;
  assign S01_ACLK_1 = S01_ACLK;
  assign S01_ARESETN_1 = S01_ARESETN;
  assign S01_AXI_arready = hdmi_memory_to_s01_couplers_ARREADY;
  assign S01_AXI_rdata[63:0] = hdmi_memory_to_s01_couplers_RDATA;
  assign S01_AXI_rlast = hdmi_memory_to_s01_couplers_RLAST;
  assign S01_AXI_rresp[1:0] = hdmi_memory_to_s01_couplers_RRESP;
  assign S01_AXI_rvalid = hdmi_memory_to_s01_couplers_RVALID;
  assign hdmi_memory_ACLK_net = ACLK;
  assign hdmi_memory_ARESETN_net = ARESETN;
  assign hdmi_memory_to_s00_couplers_AWADDR = S00_AXI_awaddr[31:0];
  assign hdmi_memory_to_s00_couplers_AWBURST = S00_AXI_awburst[1:0];
  assign hdmi_memory_to_s00_couplers_AWCACHE = S00_AXI_awcache[3:0];
  assign hdmi_memory_to_s00_couplers_AWLEN = S00_AXI_awlen[3:0];
  assign hdmi_memory_to_s00_couplers_AWLOCK = S00_AXI_awlock[1:0];
  assign hdmi_memory_to_s00_couplers_AWPROT = S00_AXI_awprot[2:0];
  assign hdmi_memory_to_s00_couplers_AWQOS = S00_AXI_awqos[3:0];
  assign hdmi_memory_to_s00_couplers_AWSIZE = S00_AXI_awsize[2:0];
  assign hdmi_memory_to_s00_couplers_AWVALID = S00_AXI_awvalid;
  assign hdmi_memory_to_s00_couplers_BREADY = S00_AXI_bready;
  assign hdmi_memory_to_s00_couplers_WDATA = S00_AXI_wdata[63:0];
  assign hdmi_memory_to_s00_couplers_WLAST = S00_AXI_wlast;
  assign hdmi_memory_to_s00_couplers_WSTRB = S00_AXI_wstrb[7:0];
  assign hdmi_memory_to_s00_couplers_WVALID = S00_AXI_wvalid;
  assign hdmi_memory_to_s01_couplers_ARADDR = S01_AXI_araddr[31:0];
  assign hdmi_memory_to_s01_couplers_ARBURST = S01_AXI_arburst[1:0];
  assign hdmi_memory_to_s01_couplers_ARCACHE = S01_AXI_arcache[3:0];
  assign hdmi_memory_to_s01_couplers_ARLEN = S01_AXI_arlen[7:0];
  assign hdmi_memory_to_s01_couplers_ARPROT = S01_AXI_arprot[2:0];
  assign hdmi_memory_to_s01_couplers_ARSIZE = S01_AXI_arsize[2:0];
  assign hdmi_memory_to_s01_couplers_ARVALID = S01_AXI_arvalid;
  assign hdmi_memory_to_s01_couplers_RREADY = S01_AXI_rready;
  assign m00_couplers_to_hdmi_memory_ARREADY = M00_AXI_arready;
  assign m00_couplers_to_hdmi_memory_AWREADY = M00_AXI_awready;
  assign m00_couplers_to_hdmi_memory_BID = M00_AXI_bid[5:0];
  assign m00_couplers_to_hdmi_memory_BRESP = M00_AXI_bresp[1:0];
  assign m00_couplers_to_hdmi_memory_BVALID = M00_AXI_bvalid;
  assign m00_couplers_to_hdmi_memory_RDATA = M00_AXI_rdata[63:0];
  assign m00_couplers_to_hdmi_memory_RID = M00_AXI_rid[5:0];
  assign m00_couplers_to_hdmi_memory_RLAST = M00_AXI_rlast;
  assign m00_couplers_to_hdmi_memory_RRESP = M00_AXI_rresp[1:0];
  assign m00_couplers_to_hdmi_memory_RVALID = M00_AXI_rvalid;
  assign m00_couplers_to_hdmi_memory_WREADY = M00_AXI_wready;
  m00_couplers_imp_2UGUCW m00_couplers
       (.M_ACLK(M00_ACLK_1),
        .M_ARESETN(M00_ARESETN_1),
        .M_AXI_araddr(m00_couplers_to_hdmi_memory_ARADDR),
        .M_AXI_arburst(m00_couplers_to_hdmi_memory_ARBURST),
        .M_AXI_arcache(m00_couplers_to_hdmi_memory_ARCACHE),
        .M_AXI_arid(m00_couplers_to_hdmi_memory_ARID),
        .M_AXI_arlen(m00_couplers_to_hdmi_memory_ARLEN),
        .M_AXI_arlock(m00_couplers_to_hdmi_memory_ARLOCK),
        .M_AXI_arprot(m00_couplers_to_hdmi_memory_ARPROT),
        .M_AXI_arqos(m00_couplers_to_hdmi_memory_ARQOS),
        .M_AXI_arready(m00_couplers_to_hdmi_memory_ARREADY),
        .M_AXI_arsize(m00_couplers_to_hdmi_memory_ARSIZE),
        .M_AXI_arvalid(m00_couplers_to_hdmi_memory_ARVALID),
        .M_AXI_awaddr(m00_couplers_to_hdmi_memory_AWADDR),
        .M_AXI_awburst(m00_couplers_to_hdmi_memory_AWBURST),
        .M_AXI_awcache(m00_couplers_to_hdmi_memory_AWCACHE),
        .M_AXI_awid(m00_couplers_to_hdmi_memory_AWID),
        .M_AXI_awlen(m00_couplers_to_hdmi_memory_AWLEN),
        .M_AXI_awlock(m00_couplers_to_hdmi_memory_AWLOCK),
        .M_AXI_awprot(m00_couplers_to_hdmi_memory_AWPROT),
        .M_AXI_awqos(m00_couplers_to_hdmi_memory_AWQOS),
        .M_AXI_awready(m00_couplers_to_hdmi_memory_AWREADY),
        .M_AXI_awsize(m00_couplers_to_hdmi_memory_AWSIZE),
        .M_AXI_awvalid(m00_couplers_to_hdmi_memory_AWVALID),
        .M_AXI_bid(m00_couplers_to_hdmi_memory_BID),
        .M_AXI_bready(m00_couplers_to_hdmi_memory_BREADY),
        .M_AXI_bresp(m00_couplers_to_hdmi_memory_BRESP),
        .M_AXI_bvalid(m00_couplers_to_hdmi_memory_BVALID),
        .M_AXI_rdata(m00_couplers_to_hdmi_memory_RDATA),
        .M_AXI_rid(m00_couplers_to_hdmi_memory_RID),
        .M_AXI_rlast(m00_couplers_to_hdmi_memory_RLAST),
        .M_AXI_rready(m00_couplers_to_hdmi_memory_RREADY),
        .M_AXI_rresp(m00_couplers_to_hdmi_memory_RRESP),
        .M_AXI_rvalid(m00_couplers_to_hdmi_memory_RVALID),
        .M_AXI_wdata(m00_couplers_to_hdmi_memory_WDATA),
        .M_AXI_wid(m00_couplers_to_hdmi_memory_WID),
        .M_AXI_wlast(m00_couplers_to_hdmi_memory_WLAST),
        .M_AXI_wready(m00_couplers_to_hdmi_memory_WREADY),
        .M_AXI_wstrb(m00_couplers_to_hdmi_memory_WSTRB),
        .M_AXI_wvalid(m00_couplers_to_hdmi_memory_WVALID),
        .S_ACLK(hdmi_memory_ACLK_net),
        .S_ARESETN(hdmi_memory_ARESETN_net),
        .S_AXI_araddr(xbar_to_m00_couplers_ARADDR),
        .S_AXI_arburst(xbar_to_m00_couplers_ARBURST),
        .S_AXI_arcache(xbar_to_m00_couplers_ARCACHE),
        .S_AXI_arid(xbar_to_m00_couplers_ARID),
        .S_AXI_arlen(xbar_to_m00_couplers_ARLEN),
        .S_AXI_arlock(xbar_to_m00_couplers_ARLOCK),
        .S_AXI_arprot(xbar_to_m00_couplers_ARPROT),
        .S_AXI_arqos(xbar_to_m00_couplers_ARQOS),
        .S_AXI_arready(xbar_to_m00_couplers_ARREADY),
        .S_AXI_arregion(xbar_to_m00_couplers_ARREGION),
        .S_AXI_arsize(xbar_to_m00_couplers_ARSIZE),
        .S_AXI_arvalid(xbar_to_m00_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m00_couplers_AWADDR),
        .S_AXI_awburst(xbar_to_m00_couplers_AWBURST),
        .S_AXI_awcache(xbar_to_m00_couplers_AWCACHE),
        .S_AXI_awid(xbar_to_m00_couplers_AWID),
        .S_AXI_awlen(xbar_to_m00_couplers_AWLEN),
        .S_AXI_awlock(xbar_to_m00_couplers_AWLOCK),
        .S_AXI_awprot(xbar_to_m00_couplers_AWPROT),
        .S_AXI_awqos(xbar_to_m00_couplers_AWQOS),
        .S_AXI_awready(xbar_to_m00_couplers_AWREADY),
        .S_AXI_awregion(xbar_to_m00_couplers_AWREGION),
        .S_AXI_awsize(xbar_to_m00_couplers_AWSIZE),
        .S_AXI_awvalid(xbar_to_m00_couplers_AWVALID),
        .S_AXI_bid(xbar_to_m00_couplers_BID),
        .S_AXI_bready(xbar_to_m00_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m00_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m00_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m00_couplers_RDATA),
        .S_AXI_rid(xbar_to_m00_couplers_RID),
        .S_AXI_rlast(xbar_to_m00_couplers_RLAST),
        .S_AXI_rready(xbar_to_m00_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m00_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m00_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m00_couplers_WDATA),
        .S_AXI_wlast(xbar_to_m00_couplers_WLAST),
        .S_AXI_wready(xbar_to_m00_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m00_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m00_couplers_WVALID));
  s00_couplers_imp_14MGJQK s00_couplers
       (.M_ACLK(hdmi_memory_ACLK_net),
        .M_ARESETN(hdmi_memory_ARESETN_net),
        .M_AXI_awaddr(s00_couplers_to_xbar_AWADDR),
        .M_AXI_awburst(s00_couplers_to_xbar_AWBURST),
        .M_AXI_awcache(s00_couplers_to_xbar_AWCACHE),
        .M_AXI_awlen(s00_couplers_to_xbar_AWLEN),
        .M_AXI_awlock(s00_couplers_to_xbar_AWLOCK),
        .M_AXI_awprot(s00_couplers_to_xbar_AWPROT),
        .M_AXI_awqos(s00_couplers_to_xbar_AWQOS),
        .M_AXI_awready(s00_couplers_to_xbar_AWREADY),
        .M_AXI_awsize(s00_couplers_to_xbar_AWSIZE),
        .M_AXI_awvalid(s00_couplers_to_xbar_AWVALID),
        .M_AXI_bready(s00_couplers_to_xbar_BREADY),
        .M_AXI_bresp(s00_couplers_to_xbar_BRESP),
        .M_AXI_bvalid(s00_couplers_to_xbar_BVALID),
        .M_AXI_wdata(s00_couplers_to_xbar_WDATA),
        .M_AXI_wlast(s00_couplers_to_xbar_WLAST),
        .M_AXI_wready(s00_couplers_to_xbar_WREADY),
        .M_AXI_wstrb(s00_couplers_to_xbar_WSTRB),
        .M_AXI_wvalid(s00_couplers_to_xbar_WVALID),
        .S_ACLK(S00_ACLK_1),
        .S_ARESETN(S00_ARESETN_1),
        .S_AXI_awaddr(hdmi_memory_to_s00_couplers_AWADDR),
        .S_AXI_awburst(hdmi_memory_to_s00_couplers_AWBURST),
        .S_AXI_awcache(hdmi_memory_to_s00_couplers_AWCACHE),
        .S_AXI_awlen(hdmi_memory_to_s00_couplers_AWLEN),
        .S_AXI_awlock(hdmi_memory_to_s00_couplers_AWLOCK),
        .S_AXI_awprot(hdmi_memory_to_s00_couplers_AWPROT),
        .S_AXI_awqos(hdmi_memory_to_s00_couplers_AWQOS),
        .S_AXI_awready(hdmi_memory_to_s00_couplers_AWREADY),
        .S_AXI_awsize(hdmi_memory_to_s00_couplers_AWSIZE),
        .S_AXI_awvalid(hdmi_memory_to_s00_couplers_AWVALID),
        .S_AXI_bready(hdmi_memory_to_s00_couplers_BREADY),
        .S_AXI_bresp(hdmi_memory_to_s00_couplers_BRESP),
        .S_AXI_bvalid(hdmi_memory_to_s00_couplers_BVALID),
        .S_AXI_wdata(hdmi_memory_to_s00_couplers_WDATA),
        .S_AXI_wlast(hdmi_memory_to_s00_couplers_WLAST),
        .S_AXI_wready(hdmi_memory_to_s00_couplers_WREADY),
        .S_AXI_wstrb(hdmi_memory_to_s00_couplers_WSTRB),
        .S_AXI_wvalid(hdmi_memory_to_s00_couplers_WVALID));
  s01_couplers_imp_JAO9TG s01_couplers
       (.M_ACLK(hdmi_memory_ACLK_net),
        .M_ARESETN(hdmi_memory_ARESETN_net),
        .M_AXI_araddr(s01_couplers_to_xbar_ARADDR),
        .M_AXI_arburst(s01_couplers_to_xbar_ARBURST),
        .M_AXI_arcache(s01_couplers_to_xbar_ARCACHE),
        .M_AXI_arlen(s01_couplers_to_xbar_ARLEN),
        .M_AXI_arlock(s01_couplers_to_xbar_ARLOCK),
        .M_AXI_arprot(s01_couplers_to_xbar_ARPROT),
        .M_AXI_arqos(s01_couplers_to_xbar_ARQOS),
        .M_AXI_arready(s01_couplers_to_xbar_ARREADY),
        .M_AXI_arsize(s01_couplers_to_xbar_ARSIZE),
        .M_AXI_arvalid(s01_couplers_to_xbar_ARVALID),
        .M_AXI_rdata(s01_couplers_to_xbar_RDATA),
        .M_AXI_rlast(s01_couplers_to_xbar_RLAST),
        .M_AXI_rready(s01_couplers_to_xbar_RREADY),
        .M_AXI_rresp(s01_couplers_to_xbar_RRESP),
        .M_AXI_rvalid(s01_couplers_to_xbar_RVALID),
        .S_ACLK(S01_ACLK_1),
        .S_ARESETN(S01_ARESETN_1),
        .S_AXI_araddr(hdmi_memory_to_s01_couplers_ARADDR),
        .S_AXI_arburst(hdmi_memory_to_s01_couplers_ARBURST),
        .S_AXI_arcache(hdmi_memory_to_s01_couplers_ARCACHE),
        .S_AXI_arlen(hdmi_memory_to_s01_couplers_ARLEN),
        .S_AXI_arprot(hdmi_memory_to_s01_couplers_ARPROT),
        .S_AXI_arready(hdmi_memory_to_s01_couplers_ARREADY),
        .S_AXI_arsize(hdmi_memory_to_s01_couplers_ARSIZE),
        .S_AXI_arvalid(hdmi_memory_to_s01_couplers_ARVALID),
        .S_AXI_rdata(hdmi_memory_to_s01_couplers_RDATA),
        .S_AXI_rlast(hdmi_memory_to_s01_couplers_RLAST),
        .S_AXI_rready(hdmi_memory_to_s01_couplers_RREADY),
        .S_AXI_rresp(hdmi_memory_to_s01_couplers_RRESP),
        .S_AXI_rvalid(hdmi_memory_to_s01_couplers_RVALID));
  av_system_xbar_3 xbar
       (.aclk(hdmi_memory_ACLK_net),
        .aresetn(hdmi_memory_ARESETN_net),
        .m_axi_araddr(xbar_to_m00_couplers_ARADDR),
        .m_axi_arburst(xbar_to_m00_couplers_ARBURST),
        .m_axi_arcache(xbar_to_m00_couplers_ARCACHE),
        .m_axi_arid(xbar_to_m00_couplers_ARID),
        .m_axi_arlen(xbar_to_m00_couplers_ARLEN),
        .m_axi_arlock(xbar_to_m00_couplers_ARLOCK),
        .m_axi_arprot(xbar_to_m00_couplers_ARPROT),
        .m_axi_arqos(xbar_to_m00_couplers_ARQOS),
        .m_axi_arready(xbar_to_m00_couplers_ARREADY),
        .m_axi_arregion(xbar_to_m00_couplers_ARREGION),
        .m_axi_arsize(xbar_to_m00_couplers_ARSIZE),
        .m_axi_arvalid(xbar_to_m00_couplers_ARVALID),
        .m_axi_awaddr(xbar_to_m00_couplers_AWADDR),
        .m_axi_awburst(xbar_to_m00_couplers_AWBURST),
        .m_axi_awcache(xbar_to_m00_couplers_AWCACHE),
        .m_axi_awid(xbar_to_m00_couplers_AWID),
        .m_axi_awlen(xbar_to_m00_couplers_AWLEN),
        .m_axi_awlock(xbar_to_m00_couplers_AWLOCK),
        .m_axi_awprot(xbar_to_m00_couplers_AWPROT),
        .m_axi_awqos(xbar_to_m00_couplers_AWQOS),
        .m_axi_awready(xbar_to_m00_couplers_AWREADY),
        .m_axi_awregion(xbar_to_m00_couplers_AWREGION),
        .m_axi_awsize(xbar_to_m00_couplers_AWSIZE),
        .m_axi_awvalid(xbar_to_m00_couplers_AWVALID),
        .m_axi_bid(xbar_to_m00_couplers_BID),
        .m_axi_bready(xbar_to_m00_couplers_BREADY),
        .m_axi_bresp(xbar_to_m00_couplers_BRESP),
        .m_axi_bvalid(xbar_to_m00_couplers_BVALID),
        .m_axi_rdata(xbar_to_m00_couplers_RDATA),
        .m_axi_rid(xbar_to_m00_couplers_RID),
        .m_axi_rlast(xbar_to_m00_couplers_RLAST),
        .m_axi_rready(xbar_to_m00_couplers_RREADY),
        .m_axi_rresp(xbar_to_m00_couplers_RRESP),
        .m_axi_rvalid(xbar_to_m00_couplers_RVALID),
        .m_axi_wdata(xbar_to_m00_couplers_WDATA),
        .m_axi_wlast(xbar_to_m00_couplers_WLAST),
        .m_axi_wready(xbar_to_m00_couplers_WREADY),
        .m_axi_wstrb(xbar_to_m00_couplers_WSTRB),
        .m_axi_wvalid(xbar_to_m00_couplers_WVALID),
        .s_axi_araddr({s01_couplers_to_xbar_ARADDR,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({s01_couplers_to_xbar_ARBURST,1'b0,1'b1}),
        .s_axi_arcache({s01_couplers_to_xbar_ARCACHE,1'b0,1'b0,1'b1,1'b1}),
        .s_axi_arid({1'b0,1'b0}),
        .s_axi_arlen({s01_couplers_to_xbar_ARLEN,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlock({s01_couplers_to_xbar_ARLOCK,1'b0}),
        .s_axi_arprot({s01_couplers_to_xbar_ARPROT,1'b0,1'b0,1'b0}),
        .s_axi_arqos({s01_couplers_to_xbar_ARQOS,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready({s01_couplers_to_xbar_ARREADY,NLW_xbar_s_axi_arready_UNCONNECTED[0]}),
        .s_axi_arsize({s01_couplers_to_xbar_ARSIZE,1'b0,1'b1,1'b1}),
        .s_axi_arvalid({s01_couplers_to_xbar_ARVALID,1'b0}),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_AWADDR}),
        .s_axi_awburst({1'b0,1'b0,s00_couplers_to_xbar_AWBURST}),
        .s_axi_awcache({1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_AWCACHE}),
        .s_axi_awid({1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_AWLEN}),
        .s_axi_awlock({1'b0,s00_couplers_to_xbar_AWLOCK}),
        .s_axi_awprot({1'b0,1'b0,1'b0,s00_couplers_to_xbar_AWPROT}),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_AWQOS}),
        .s_axi_awready(s00_couplers_to_xbar_AWREADY),
        .s_axi_awsize({1'b0,1'b0,1'b1,s00_couplers_to_xbar_AWSIZE}),
        .s_axi_awvalid({1'b0,s00_couplers_to_xbar_AWVALID}),
        .s_axi_bready({1'b0,s00_couplers_to_xbar_BREADY}),
        .s_axi_bresp(s00_couplers_to_xbar_BRESP),
        .s_axi_bvalid(s00_couplers_to_xbar_BVALID),
        .s_axi_rdata({s01_couplers_to_xbar_RDATA,NLW_xbar_s_axi_rdata_UNCONNECTED[63:0]}),
        .s_axi_rlast({s01_couplers_to_xbar_RLAST,NLW_xbar_s_axi_rlast_UNCONNECTED[0]}),
        .s_axi_rready({s01_couplers_to_xbar_RREADY,1'b0}),
        .s_axi_rresp({s01_couplers_to_xbar_RRESP,NLW_xbar_s_axi_rresp_UNCONNECTED[1:0]}),
        .s_axi_rvalid({s01_couplers_to_xbar_RVALID,NLW_xbar_s_axi_rvalid_UNCONNECTED[0]}),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_WDATA}),
        .s_axi_wlast({1'b0,s00_couplers_to_xbar_WLAST}),
        .s_axi_wready(s00_couplers_to_xbar_WREADY),
        .s_axi_wstrb({1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,s00_couplers_to_xbar_WSTRB}),
        .s_axi_wvalid({1'b0,s00_couplers_to_xbar_WVALID}));
endmodule

module av_system_inference_memory_0
   (ACLK,
    ARESETN,
    M00_ACLK,
    M00_ARESETN,
    M00_AXI_araddr,
    M00_AXI_arburst,
    M00_AXI_arcache,
    M00_AXI_arid,
    M00_AXI_arlen,
    M00_AXI_arlock,
    M00_AXI_arprot,
    M00_AXI_arqos,
    M00_AXI_arready,
    M00_AXI_arsize,
    M00_AXI_arvalid,
    M00_AXI_awaddr,
    M00_AXI_awburst,
    M00_AXI_awcache,
    M00_AXI_awid,
    M00_AXI_awlen,
    M00_AXI_awlock,
    M00_AXI_awprot,
    M00_AXI_awqos,
    M00_AXI_awready,
    M00_AXI_awsize,
    M00_AXI_awvalid,
    M00_AXI_bid,
    M00_AXI_bready,
    M00_AXI_bresp,
    M00_AXI_bvalid,
    M00_AXI_rdata,
    M00_AXI_rid,
    M00_AXI_rlast,
    M00_AXI_rready,
    M00_AXI_rresp,
    M00_AXI_rvalid,
    M00_AXI_wdata,
    M00_AXI_wid,
    M00_AXI_wlast,
    M00_AXI_wready,
    M00_AXI_wstrb,
    M00_AXI_wvalid,
    S00_ACLK,
    S00_ARESETN,
    S00_AXI_araddr,
    S00_AXI_arburst,
    S00_AXI_arcache,
    S00_AXI_arlen,
    S00_AXI_arprot,
    S00_AXI_arready,
    S00_AXI_arsize,
    S00_AXI_arvalid,
    S00_AXI_rdata,
    S00_AXI_rlast,
    S00_AXI_rready,
    S00_AXI_rresp,
    S00_AXI_rvalid,
    S01_ACLK,
    S01_ARESETN,
    S01_AXI_awaddr,
    S01_AXI_awburst,
    S01_AXI_awcache,
    S01_AXI_awlen,
    S01_AXI_awprot,
    S01_AXI_awready,
    S01_AXI_awsize,
    S01_AXI_awvalid,
    S01_AXI_bready,
    S01_AXI_bresp,
    S01_AXI_bvalid,
    S01_AXI_wdata,
    S01_AXI_wlast,
    S01_AXI_wready,
    S01_AXI_wstrb,
    S01_AXI_wvalid);
  input ACLK;
  input ARESETN;
  input M00_ACLK;
  input M00_ARESETN;
  output [31:0]M00_AXI_araddr;
  output [1:0]M00_AXI_arburst;
  output [3:0]M00_AXI_arcache;
  output [0:0]M00_AXI_arid;
  output [3:0]M00_AXI_arlen;
  output [1:0]M00_AXI_arlock;
  output [2:0]M00_AXI_arprot;
  output [3:0]M00_AXI_arqos;
  input M00_AXI_arready;
  output [2:0]M00_AXI_arsize;
  output M00_AXI_arvalid;
  output [31:0]M00_AXI_awaddr;
  output [1:0]M00_AXI_awburst;
  output [3:0]M00_AXI_awcache;
  output [0:0]M00_AXI_awid;
  output [3:0]M00_AXI_awlen;
  output [1:0]M00_AXI_awlock;
  output [2:0]M00_AXI_awprot;
  output [3:0]M00_AXI_awqos;
  input M00_AXI_awready;
  output [2:0]M00_AXI_awsize;
  output M00_AXI_awvalid;
  input [5:0]M00_AXI_bid;
  output M00_AXI_bready;
  input [1:0]M00_AXI_bresp;
  input M00_AXI_bvalid;
  input [63:0]M00_AXI_rdata;
  input [5:0]M00_AXI_rid;
  input M00_AXI_rlast;
  output M00_AXI_rready;
  input [1:0]M00_AXI_rresp;
  input M00_AXI_rvalid;
  output [63:0]M00_AXI_wdata;
  output [0:0]M00_AXI_wid;
  output M00_AXI_wlast;
  input M00_AXI_wready;
  output [7:0]M00_AXI_wstrb;
  output M00_AXI_wvalid;
  input S00_ACLK;
  input S00_ARESETN;
  input [31:0]S00_AXI_araddr;
  input [1:0]S00_AXI_arburst;
  input [3:0]S00_AXI_arcache;
  input [7:0]S00_AXI_arlen;
  input [2:0]S00_AXI_arprot;
  output [0:0]S00_AXI_arready;
  input [2:0]S00_AXI_arsize;
  input [0:0]S00_AXI_arvalid;
  output [63:0]S00_AXI_rdata;
  output [0:0]S00_AXI_rlast;
  input [0:0]S00_AXI_rready;
  output [1:0]S00_AXI_rresp;
  output [0:0]S00_AXI_rvalid;
  input S01_ACLK;
  input S01_ARESETN;
  input [31:0]S01_AXI_awaddr;
  input [1:0]S01_AXI_awburst;
  input [3:0]S01_AXI_awcache;
  input [7:0]S01_AXI_awlen;
  input [2:0]S01_AXI_awprot;
  output [0:0]S01_AXI_awready;
  input [2:0]S01_AXI_awsize;
  input [0:0]S01_AXI_awvalid;
  input [0:0]S01_AXI_bready;
  output [1:0]S01_AXI_bresp;
  output [0:0]S01_AXI_bvalid;
  input [63:0]S01_AXI_wdata;
  input [0:0]S01_AXI_wlast;
  output [0:0]S01_AXI_wready;
  input [7:0]S01_AXI_wstrb;
  input [0:0]S01_AXI_wvalid;

  wire M00_ACLK_1;
  wire M00_ARESETN_1;
  wire S00_ACLK_1;
  wire S00_ARESETN_1;
  wire S01_ACLK_1;
  wire S01_ARESETN_1;
  wire inference_memory_ACLK_net;
  wire inference_memory_ARESETN_net;
  wire [31:0]inference_memory_to_s00_couplers_ARADDR;
  wire [1:0]inference_memory_to_s00_couplers_ARBURST;
  wire [3:0]inference_memory_to_s00_couplers_ARCACHE;
  wire [7:0]inference_memory_to_s00_couplers_ARLEN;
  wire [2:0]inference_memory_to_s00_couplers_ARPROT;
  wire [0:0]inference_memory_to_s00_couplers_ARREADY;
  wire [2:0]inference_memory_to_s00_couplers_ARSIZE;
  wire [0:0]inference_memory_to_s00_couplers_ARVALID;
  wire [63:0]inference_memory_to_s00_couplers_RDATA;
  wire [0:0]inference_memory_to_s00_couplers_RLAST;
  wire [0:0]inference_memory_to_s00_couplers_RREADY;
  wire [1:0]inference_memory_to_s00_couplers_RRESP;
  wire [0:0]inference_memory_to_s00_couplers_RVALID;
  wire [31:0]inference_memory_to_s01_couplers_AWADDR;
  wire [1:0]inference_memory_to_s01_couplers_AWBURST;
  wire [3:0]inference_memory_to_s01_couplers_AWCACHE;
  wire [7:0]inference_memory_to_s01_couplers_AWLEN;
  wire [2:0]inference_memory_to_s01_couplers_AWPROT;
  wire [0:0]inference_memory_to_s01_couplers_AWREADY;
  wire [2:0]inference_memory_to_s01_couplers_AWSIZE;
  wire [0:0]inference_memory_to_s01_couplers_AWVALID;
  wire [0:0]inference_memory_to_s01_couplers_BREADY;
  wire [1:0]inference_memory_to_s01_couplers_BRESP;
  wire [0:0]inference_memory_to_s01_couplers_BVALID;
  wire [63:0]inference_memory_to_s01_couplers_WDATA;
  wire [0:0]inference_memory_to_s01_couplers_WLAST;
  wire [0:0]inference_memory_to_s01_couplers_WREADY;
  wire [7:0]inference_memory_to_s01_couplers_WSTRB;
  wire [0:0]inference_memory_to_s01_couplers_WVALID;
  wire [31:0]m00_couplers_to_inference_memory_ARADDR;
  wire [1:0]m00_couplers_to_inference_memory_ARBURST;
  wire [3:0]m00_couplers_to_inference_memory_ARCACHE;
  wire [0:0]m00_couplers_to_inference_memory_ARID;
  wire [3:0]m00_couplers_to_inference_memory_ARLEN;
  wire [1:0]m00_couplers_to_inference_memory_ARLOCK;
  wire [2:0]m00_couplers_to_inference_memory_ARPROT;
  wire [3:0]m00_couplers_to_inference_memory_ARQOS;
  wire m00_couplers_to_inference_memory_ARREADY;
  wire [2:0]m00_couplers_to_inference_memory_ARSIZE;
  wire m00_couplers_to_inference_memory_ARVALID;
  wire [31:0]m00_couplers_to_inference_memory_AWADDR;
  wire [1:0]m00_couplers_to_inference_memory_AWBURST;
  wire [3:0]m00_couplers_to_inference_memory_AWCACHE;
  wire [0:0]m00_couplers_to_inference_memory_AWID;
  wire [3:0]m00_couplers_to_inference_memory_AWLEN;
  wire [1:0]m00_couplers_to_inference_memory_AWLOCK;
  wire [2:0]m00_couplers_to_inference_memory_AWPROT;
  wire [3:0]m00_couplers_to_inference_memory_AWQOS;
  wire m00_couplers_to_inference_memory_AWREADY;
  wire [2:0]m00_couplers_to_inference_memory_AWSIZE;
  wire m00_couplers_to_inference_memory_AWVALID;
  wire [5:0]m00_couplers_to_inference_memory_BID;
  wire m00_couplers_to_inference_memory_BREADY;
  wire [1:0]m00_couplers_to_inference_memory_BRESP;
  wire m00_couplers_to_inference_memory_BVALID;
  wire [63:0]m00_couplers_to_inference_memory_RDATA;
  wire [5:0]m00_couplers_to_inference_memory_RID;
  wire m00_couplers_to_inference_memory_RLAST;
  wire m00_couplers_to_inference_memory_RREADY;
  wire [1:0]m00_couplers_to_inference_memory_RRESP;
  wire m00_couplers_to_inference_memory_RVALID;
  wire [63:0]m00_couplers_to_inference_memory_WDATA;
  wire [0:0]m00_couplers_to_inference_memory_WID;
  wire m00_couplers_to_inference_memory_WLAST;
  wire m00_couplers_to_inference_memory_WREADY;
  wire [7:0]m00_couplers_to_inference_memory_WSTRB;
  wire m00_couplers_to_inference_memory_WVALID;
  wire [31:0]s00_couplers_to_xbar_ARADDR;
  wire [1:0]s00_couplers_to_xbar_ARBURST;
  wire [3:0]s00_couplers_to_xbar_ARCACHE;
  wire [7:0]s00_couplers_to_xbar_ARLEN;
  wire [2:0]s00_couplers_to_xbar_ARPROT;
  wire [0:0]s00_couplers_to_xbar_ARREADY;
  wire [2:0]s00_couplers_to_xbar_ARSIZE;
  wire [0:0]s00_couplers_to_xbar_ARVALID;
  wire [63:0]s00_couplers_to_xbar_RDATA;
  wire [0:0]s00_couplers_to_xbar_RLAST;
  wire [0:0]s00_couplers_to_xbar_RREADY;
  wire [1:0]s00_couplers_to_xbar_RRESP;
  wire [0:0]s00_couplers_to_xbar_RVALID;
  wire [31:0]s01_couplers_to_xbar_AWADDR;
  wire [1:0]s01_couplers_to_xbar_AWBURST;
  wire [3:0]s01_couplers_to_xbar_AWCACHE;
  wire [7:0]s01_couplers_to_xbar_AWLEN;
  wire [2:0]s01_couplers_to_xbar_AWPROT;
  wire [1:1]s01_couplers_to_xbar_AWREADY;
  wire [2:0]s01_couplers_to_xbar_AWSIZE;
  wire [0:0]s01_couplers_to_xbar_AWVALID;
  wire [0:0]s01_couplers_to_xbar_BREADY;
  wire [3:2]s01_couplers_to_xbar_BRESP;
  wire [1:1]s01_couplers_to_xbar_BVALID;
  wire [63:0]s01_couplers_to_xbar_WDATA;
  wire [0:0]s01_couplers_to_xbar_WLAST;
  wire [1:1]s01_couplers_to_xbar_WREADY;
  wire [7:0]s01_couplers_to_xbar_WSTRB;
  wire [0:0]s01_couplers_to_xbar_WVALID;
  wire [31:0]xbar_to_m00_couplers_ARADDR;
  wire [1:0]xbar_to_m00_couplers_ARBURST;
  wire [3:0]xbar_to_m00_couplers_ARCACHE;
  wire [0:0]xbar_to_m00_couplers_ARID;
  wire [7:0]xbar_to_m00_couplers_ARLEN;
  wire [0:0]xbar_to_m00_couplers_ARLOCK;
  wire [2:0]xbar_to_m00_couplers_ARPROT;
  wire [3:0]xbar_to_m00_couplers_ARQOS;
  wire xbar_to_m00_couplers_ARREADY;
  wire [3:0]xbar_to_m00_couplers_ARREGION;
  wire [2:0]xbar_to_m00_couplers_ARSIZE;
  wire [0:0]xbar_to_m00_couplers_ARVALID;
  wire [31:0]xbar_to_m00_couplers_AWADDR;
  wire [1:0]xbar_to_m00_couplers_AWBURST;
  wire [3:0]xbar_to_m00_couplers_AWCACHE;
  wire [0:0]xbar_to_m00_couplers_AWID;
  wire [7:0]xbar_to_m00_couplers_AWLEN;
  wire [0:0]xbar_to_m00_couplers_AWLOCK;
  wire [2:0]xbar_to_m00_couplers_AWPROT;
  wire [3:0]xbar_to_m00_couplers_AWQOS;
  wire xbar_to_m00_couplers_AWREADY;
  wire [3:0]xbar_to_m00_couplers_AWREGION;
  wire [2:0]xbar_to_m00_couplers_AWSIZE;
  wire [0:0]xbar_to_m00_couplers_AWVALID;
  wire [0:0]xbar_to_m00_couplers_BID;
  wire [0:0]xbar_to_m00_couplers_BREADY;
  wire [1:0]xbar_to_m00_couplers_BRESP;
  wire xbar_to_m00_couplers_BVALID;
  wire [63:0]xbar_to_m00_couplers_RDATA;
  wire [0:0]xbar_to_m00_couplers_RID;
  wire xbar_to_m00_couplers_RLAST;
  wire [0:0]xbar_to_m00_couplers_RREADY;
  wire [1:0]xbar_to_m00_couplers_RRESP;
  wire xbar_to_m00_couplers_RVALID;
  wire [63:0]xbar_to_m00_couplers_WDATA;
  wire [0:0]xbar_to_m00_couplers_WLAST;
  wire xbar_to_m00_couplers_WREADY;
  wire [7:0]xbar_to_m00_couplers_WSTRB;
  wire [0:0]xbar_to_m00_couplers_WVALID;
  wire [1:0]NLW_xbar_s_axi_awready_UNCONNECTED;
  wire [3:0]NLW_xbar_s_axi_bresp_UNCONNECTED;
  wire [1:0]NLW_xbar_s_axi_bvalid_UNCONNECTED;
  wire [1:0]NLW_xbar_s_axi_wready_UNCONNECTED;

  assign M00_ACLK_1 = M00_ACLK;
  assign M00_ARESETN_1 = M00_ARESETN;
  assign M00_AXI_araddr[31:0] = m00_couplers_to_inference_memory_ARADDR;
  assign M00_AXI_arburst[1:0] = m00_couplers_to_inference_memory_ARBURST;
  assign M00_AXI_arcache[3:0] = m00_couplers_to_inference_memory_ARCACHE;
  assign M00_AXI_arid[0] = m00_couplers_to_inference_memory_ARID;
  assign M00_AXI_arlen[3:0] = m00_couplers_to_inference_memory_ARLEN;
  assign M00_AXI_arlock[1:0] = m00_couplers_to_inference_memory_ARLOCK;
  assign M00_AXI_arprot[2:0] = m00_couplers_to_inference_memory_ARPROT;
  assign M00_AXI_arqos[3:0] = m00_couplers_to_inference_memory_ARQOS;
  assign M00_AXI_arsize[2:0] = m00_couplers_to_inference_memory_ARSIZE;
  assign M00_AXI_arvalid = m00_couplers_to_inference_memory_ARVALID;
  assign M00_AXI_awaddr[31:0] = m00_couplers_to_inference_memory_AWADDR;
  assign M00_AXI_awburst[1:0] = m00_couplers_to_inference_memory_AWBURST;
  assign M00_AXI_awcache[3:0] = m00_couplers_to_inference_memory_AWCACHE;
  assign M00_AXI_awid[0] = m00_couplers_to_inference_memory_AWID;
  assign M00_AXI_awlen[3:0] = m00_couplers_to_inference_memory_AWLEN;
  assign M00_AXI_awlock[1:0] = m00_couplers_to_inference_memory_AWLOCK;
  assign M00_AXI_awprot[2:0] = m00_couplers_to_inference_memory_AWPROT;
  assign M00_AXI_awqos[3:0] = m00_couplers_to_inference_memory_AWQOS;
  assign M00_AXI_awsize[2:0] = m00_couplers_to_inference_memory_AWSIZE;
  assign M00_AXI_awvalid = m00_couplers_to_inference_memory_AWVALID;
  assign M00_AXI_bready = m00_couplers_to_inference_memory_BREADY;
  assign M00_AXI_rready = m00_couplers_to_inference_memory_RREADY;
  assign M00_AXI_wdata[63:0] = m00_couplers_to_inference_memory_WDATA;
  assign M00_AXI_wid[0] = m00_couplers_to_inference_memory_WID;
  assign M00_AXI_wlast = m00_couplers_to_inference_memory_WLAST;
  assign M00_AXI_wstrb[7:0] = m00_couplers_to_inference_memory_WSTRB;
  assign M00_AXI_wvalid = m00_couplers_to_inference_memory_WVALID;
  assign S00_ACLK_1 = S00_ACLK;
  assign S00_ARESETN_1 = S00_ARESETN;
  assign S00_AXI_arready[0] = inference_memory_to_s00_couplers_ARREADY;
  assign S00_AXI_rdata[63:0] = inference_memory_to_s00_couplers_RDATA;
  assign S00_AXI_rlast[0] = inference_memory_to_s00_couplers_RLAST;
  assign S00_AXI_rresp[1:0] = inference_memory_to_s00_couplers_RRESP;
  assign S00_AXI_rvalid[0] = inference_memory_to_s00_couplers_RVALID;
  assign S01_ACLK_1 = S01_ACLK;
  assign S01_ARESETN_1 = S01_ARESETN;
  assign S01_AXI_awready[0] = inference_memory_to_s01_couplers_AWREADY;
  assign S01_AXI_bresp[1:0] = inference_memory_to_s01_couplers_BRESP;
  assign S01_AXI_bvalid[0] = inference_memory_to_s01_couplers_BVALID;
  assign S01_AXI_wready[0] = inference_memory_to_s01_couplers_WREADY;
  assign inference_memory_ACLK_net = ACLK;
  assign inference_memory_ARESETN_net = ARESETN;
  assign inference_memory_to_s00_couplers_ARADDR = S00_AXI_araddr[31:0];
  assign inference_memory_to_s00_couplers_ARBURST = S00_AXI_arburst[1:0];
  assign inference_memory_to_s00_couplers_ARCACHE = S00_AXI_arcache[3:0];
  assign inference_memory_to_s00_couplers_ARLEN = S00_AXI_arlen[7:0];
  assign inference_memory_to_s00_couplers_ARPROT = S00_AXI_arprot[2:0];
  assign inference_memory_to_s00_couplers_ARSIZE = S00_AXI_arsize[2:0];
  assign inference_memory_to_s00_couplers_ARVALID = S00_AXI_arvalid[0];
  assign inference_memory_to_s00_couplers_RREADY = S00_AXI_rready[0];
  assign inference_memory_to_s01_couplers_AWADDR = S01_AXI_awaddr[31:0];
  assign inference_memory_to_s01_couplers_AWBURST = S01_AXI_awburst[1:0];
  assign inference_memory_to_s01_couplers_AWCACHE = S01_AXI_awcache[3:0];
  assign inference_memory_to_s01_couplers_AWLEN = S01_AXI_awlen[7:0];
  assign inference_memory_to_s01_couplers_AWPROT = S01_AXI_awprot[2:0];
  assign inference_memory_to_s01_couplers_AWSIZE = S01_AXI_awsize[2:0];
  assign inference_memory_to_s01_couplers_AWVALID = S01_AXI_awvalid[0];
  assign inference_memory_to_s01_couplers_BREADY = S01_AXI_bready[0];
  assign inference_memory_to_s01_couplers_WDATA = S01_AXI_wdata[63:0];
  assign inference_memory_to_s01_couplers_WLAST = S01_AXI_wlast[0];
  assign inference_memory_to_s01_couplers_WSTRB = S01_AXI_wstrb[7:0];
  assign inference_memory_to_s01_couplers_WVALID = S01_AXI_wvalid[0];
  assign m00_couplers_to_inference_memory_ARREADY = M00_AXI_arready;
  assign m00_couplers_to_inference_memory_AWREADY = M00_AXI_awready;
  assign m00_couplers_to_inference_memory_BID = M00_AXI_bid[5:0];
  assign m00_couplers_to_inference_memory_BRESP = M00_AXI_bresp[1:0];
  assign m00_couplers_to_inference_memory_BVALID = M00_AXI_bvalid;
  assign m00_couplers_to_inference_memory_RDATA = M00_AXI_rdata[63:0];
  assign m00_couplers_to_inference_memory_RID = M00_AXI_rid[5:0];
  assign m00_couplers_to_inference_memory_RLAST = M00_AXI_rlast;
  assign m00_couplers_to_inference_memory_RRESP = M00_AXI_rresp[1:0];
  assign m00_couplers_to_inference_memory_RVALID = M00_AXI_rvalid;
  assign m00_couplers_to_inference_memory_WREADY = M00_AXI_wready;
  m00_couplers_imp_1CBSJ84 m00_couplers
       (.M_ACLK(M00_ACLK_1),
        .M_ARESETN(M00_ARESETN_1),
        .M_AXI_araddr(m00_couplers_to_inference_memory_ARADDR),
        .M_AXI_arburst(m00_couplers_to_inference_memory_ARBURST),
        .M_AXI_arcache(m00_couplers_to_inference_memory_ARCACHE),
        .M_AXI_arid(m00_couplers_to_inference_memory_ARID),
        .M_AXI_arlen(m00_couplers_to_inference_memory_ARLEN),
        .M_AXI_arlock(m00_couplers_to_inference_memory_ARLOCK),
        .M_AXI_arprot(m00_couplers_to_inference_memory_ARPROT),
        .M_AXI_arqos(m00_couplers_to_inference_memory_ARQOS),
        .M_AXI_arready(m00_couplers_to_inference_memory_ARREADY),
        .M_AXI_arsize(m00_couplers_to_inference_memory_ARSIZE),
        .M_AXI_arvalid(m00_couplers_to_inference_memory_ARVALID),
        .M_AXI_awaddr(m00_couplers_to_inference_memory_AWADDR),
        .M_AXI_awburst(m00_couplers_to_inference_memory_AWBURST),
        .M_AXI_awcache(m00_couplers_to_inference_memory_AWCACHE),
        .M_AXI_awid(m00_couplers_to_inference_memory_AWID),
        .M_AXI_awlen(m00_couplers_to_inference_memory_AWLEN),
        .M_AXI_awlock(m00_couplers_to_inference_memory_AWLOCK),
        .M_AXI_awprot(m00_couplers_to_inference_memory_AWPROT),
        .M_AXI_awqos(m00_couplers_to_inference_memory_AWQOS),
        .M_AXI_awready(m00_couplers_to_inference_memory_AWREADY),
        .M_AXI_awsize(m00_couplers_to_inference_memory_AWSIZE),
        .M_AXI_awvalid(m00_couplers_to_inference_memory_AWVALID),
        .M_AXI_bid(m00_couplers_to_inference_memory_BID),
        .M_AXI_bready(m00_couplers_to_inference_memory_BREADY),
        .M_AXI_bresp(m00_couplers_to_inference_memory_BRESP),
        .M_AXI_bvalid(m00_couplers_to_inference_memory_BVALID),
        .M_AXI_rdata(m00_couplers_to_inference_memory_RDATA),
        .M_AXI_rid(m00_couplers_to_inference_memory_RID),
        .M_AXI_rlast(m00_couplers_to_inference_memory_RLAST),
        .M_AXI_rready(m00_couplers_to_inference_memory_RREADY),
        .M_AXI_rresp(m00_couplers_to_inference_memory_RRESP),
        .M_AXI_rvalid(m00_couplers_to_inference_memory_RVALID),
        .M_AXI_wdata(m00_couplers_to_inference_memory_WDATA),
        .M_AXI_wid(m00_couplers_to_inference_memory_WID),
        .M_AXI_wlast(m00_couplers_to_inference_memory_WLAST),
        .M_AXI_wready(m00_couplers_to_inference_memory_WREADY),
        .M_AXI_wstrb(m00_couplers_to_inference_memory_WSTRB),
        .M_AXI_wvalid(m00_couplers_to_inference_memory_WVALID),
        .S_ACLK(inference_memory_ACLK_net),
        .S_ARESETN(inference_memory_ARESETN_net),
        .S_AXI_araddr(xbar_to_m00_couplers_ARADDR),
        .S_AXI_arburst(xbar_to_m00_couplers_ARBURST),
        .S_AXI_arcache(xbar_to_m00_couplers_ARCACHE),
        .S_AXI_arid(xbar_to_m00_couplers_ARID),
        .S_AXI_arlen(xbar_to_m00_couplers_ARLEN),
        .S_AXI_arlock(xbar_to_m00_couplers_ARLOCK),
        .S_AXI_arprot(xbar_to_m00_couplers_ARPROT),
        .S_AXI_arqos(xbar_to_m00_couplers_ARQOS),
        .S_AXI_arready(xbar_to_m00_couplers_ARREADY),
        .S_AXI_arregion(xbar_to_m00_couplers_ARREGION),
        .S_AXI_arsize(xbar_to_m00_couplers_ARSIZE),
        .S_AXI_arvalid(xbar_to_m00_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m00_couplers_AWADDR),
        .S_AXI_awburst(xbar_to_m00_couplers_AWBURST),
        .S_AXI_awcache(xbar_to_m00_couplers_AWCACHE),
        .S_AXI_awid(xbar_to_m00_couplers_AWID),
        .S_AXI_awlen(xbar_to_m00_couplers_AWLEN),
        .S_AXI_awlock(xbar_to_m00_couplers_AWLOCK),
        .S_AXI_awprot(xbar_to_m00_couplers_AWPROT),
        .S_AXI_awqos(xbar_to_m00_couplers_AWQOS),
        .S_AXI_awready(xbar_to_m00_couplers_AWREADY),
        .S_AXI_awregion(xbar_to_m00_couplers_AWREGION),
        .S_AXI_awsize(xbar_to_m00_couplers_AWSIZE),
        .S_AXI_awvalid(xbar_to_m00_couplers_AWVALID),
        .S_AXI_bid(xbar_to_m00_couplers_BID),
        .S_AXI_bready(xbar_to_m00_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m00_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m00_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m00_couplers_RDATA),
        .S_AXI_rid(xbar_to_m00_couplers_RID),
        .S_AXI_rlast(xbar_to_m00_couplers_RLAST),
        .S_AXI_rready(xbar_to_m00_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m00_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m00_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m00_couplers_WDATA),
        .S_AXI_wlast(xbar_to_m00_couplers_WLAST),
        .S_AXI_wready(xbar_to_m00_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m00_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m00_couplers_WVALID));
  s00_couplers_imp_EZP5VS s00_couplers
       (.M_ACLK(inference_memory_ACLK_net),
        .M_ARESETN(inference_memory_ARESETN_net),
        .M_AXI_araddr(s00_couplers_to_xbar_ARADDR),
        .M_AXI_arburst(s00_couplers_to_xbar_ARBURST),
        .M_AXI_arcache(s00_couplers_to_xbar_ARCACHE),
        .M_AXI_arlen(s00_couplers_to_xbar_ARLEN),
        .M_AXI_arprot(s00_couplers_to_xbar_ARPROT),
        .M_AXI_arready(s00_couplers_to_xbar_ARREADY),
        .M_AXI_arsize(s00_couplers_to_xbar_ARSIZE),
        .M_AXI_arvalid(s00_couplers_to_xbar_ARVALID),
        .M_AXI_rdata(s00_couplers_to_xbar_RDATA),
        .M_AXI_rlast(s00_couplers_to_xbar_RLAST),
        .M_AXI_rready(s00_couplers_to_xbar_RREADY),
        .M_AXI_rresp(s00_couplers_to_xbar_RRESP),
        .M_AXI_rvalid(s00_couplers_to_xbar_RVALID),
        .S_ACLK(S00_ACLK_1),
        .S_ARESETN(S00_ARESETN_1),
        .S_AXI_araddr(inference_memory_to_s00_couplers_ARADDR),
        .S_AXI_arburst(inference_memory_to_s00_couplers_ARBURST),
        .S_AXI_arcache(inference_memory_to_s00_couplers_ARCACHE),
        .S_AXI_arlen(inference_memory_to_s00_couplers_ARLEN),
        .S_AXI_arprot(inference_memory_to_s00_couplers_ARPROT),
        .S_AXI_arready(inference_memory_to_s00_couplers_ARREADY),
        .S_AXI_arsize(inference_memory_to_s00_couplers_ARSIZE),
        .S_AXI_arvalid(inference_memory_to_s00_couplers_ARVALID),
        .S_AXI_rdata(inference_memory_to_s00_couplers_RDATA),
        .S_AXI_rlast(inference_memory_to_s00_couplers_RLAST),
        .S_AXI_rready(inference_memory_to_s00_couplers_RREADY),
        .S_AXI_rresp(inference_memory_to_s00_couplers_RRESP),
        .S_AXI_rvalid(inference_memory_to_s00_couplers_RVALID));
  s01_couplers_imp_1QOEV68 s01_couplers
       (.M_ACLK(inference_memory_ACLK_net),
        .M_ARESETN(inference_memory_ARESETN_net),
        .M_AXI_awaddr(s01_couplers_to_xbar_AWADDR),
        .M_AXI_awburst(s01_couplers_to_xbar_AWBURST),
        .M_AXI_awcache(s01_couplers_to_xbar_AWCACHE),
        .M_AXI_awlen(s01_couplers_to_xbar_AWLEN),
        .M_AXI_awprot(s01_couplers_to_xbar_AWPROT),
        .M_AXI_awready(s01_couplers_to_xbar_AWREADY),
        .M_AXI_awsize(s01_couplers_to_xbar_AWSIZE),
        .M_AXI_awvalid(s01_couplers_to_xbar_AWVALID),
        .M_AXI_bready(s01_couplers_to_xbar_BREADY),
        .M_AXI_bresp(s01_couplers_to_xbar_BRESP),
        .M_AXI_bvalid(s01_couplers_to_xbar_BVALID),
        .M_AXI_wdata(s01_couplers_to_xbar_WDATA),
        .M_AXI_wlast(s01_couplers_to_xbar_WLAST),
        .M_AXI_wready(s01_couplers_to_xbar_WREADY),
        .M_AXI_wstrb(s01_couplers_to_xbar_WSTRB),
        .M_AXI_wvalid(s01_couplers_to_xbar_WVALID),
        .S_ACLK(S01_ACLK_1),
        .S_ARESETN(S01_ARESETN_1),
        .S_AXI_awaddr(inference_memory_to_s01_couplers_AWADDR),
        .S_AXI_awburst(inference_memory_to_s01_couplers_AWBURST),
        .S_AXI_awcache(inference_memory_to_s01_couplers_AWCACHE),
        .S_AXI_awlen(inference_memory_to_s01_couplers_AWLEN),
        .S_AXI_awprot(inference_memory_to_s01_couplers_AWPROT),
        .S_AXI_awready(inference_memory_to_s01_couplers_AWREADY),
        .S_AXI_awsize(inference_memory_to_s01_couplers_AWSIZE),
        .S_AXI_awvalid(inference_memory_to_s01_couplers_AWVALID),
        .S_AXI_bready(inference_memory_to_s01_couplers_BREADY),
        .S_AXI_bresp(inference_memory_to_s01_couplers_BRESP),
        .S_AXI_bvalid(inference_memory_to_s01_couplers_BVALID),
        .S_AXI_wdata(inference_memory_to_s01_couplers_WDATA),
        .S_AXI_wlast(inference_memory_to_s01_couplers_WLAST),
        .S_AXI_wready(inference_memory_to_s01_couplers_WREADY),
        .S_AXI_wstrb(inference_memory_to_s01_couplers_WSTRB),
        .S_AXI_wvalid(inference_memory_to_s01_couplers_WVALID));
  av_system_xbar_1 xbar
       (.aclk(inference_memory_ACLK_net),
        .aresetn(inference_memory_ARESETN_net),
        .m_axi_araddr(xbar_to_m00_couplers_ARADDR),
        .m_axi_arburst(xbar_to_m00_couplers_ARBURST),
        .m_axi_arcache(xbar_to_m00_couplers_ARCACHE),
        .m_axi_arid(xbar_to_m00_couplers_ARID),
        .m_axi_arlen(xbar_to_m00_couplers_ARLEN),
        .m_axi_arlock(xbar_to_m00_couplers_ARLOCK),
        .m_axi_arprot(xbar_to_m00_couplers_ARPROT),
        .m_axi_arqos(xbar_to_m00_couplers_ARQOS),
        .m_axi_arready(xbar_to_m00_couplers_ARREADY),
        .m_axi_arregion(xbar_to_m00_couplers_ARREGION),
        .m_axi_arsize(xbar_to_m00_couplers_ARSIZE),
        .m_axi_arvalid(xbar_to_m00_couplers_ARVALID),
        .m_axi_awaddr(xbar_to_m00_couplers_AWADDR),
        .m_axi_awburst(xbar_to_m00_couplers_AWBURST),
        .m_axi_awcache(xbar_to_m00_couplers_AWCACHE),
        .m_axi_awid(xbar_to_m00_couplers_AWID),
        .m_axi_awlen(xbar_to_m00_couplers_AWLEN),
        .m_axi_awlock(xbar_to_m00_couplers_AWLOCK),
        .m_axi_awprot(xbar_to_m00_couplers_AWPROT),
        .m_axi_awqos(xbar_to_m00_couplers_AWQOS),
        .m_axi_awready(xbar_to_m00_couplers_AWREADY),
        .m_axi_awregion(xbar_to_m00_couplers_AWREGION),
        .m_axi_awsize(xbar_to_m00_couplers_AWSIZE),
        .m_axi_awvalid(xbar_to_m00_couplers_AWVALID),
        .m_axi_bid(xbar_to_m00_couplers_BID),
        .m_axi_bready(xbar_to_m00_couplers_BREADY),
        .m_axi_bresp(xbar_to_m00_couplers_BRESP),
        .m_axi_bvalid(xbar_to_m00_couplers_BVALID),
        .m_axi_rdata(xbar_to_m00_couplers_RDATA),
        .m_axi_rid(xbar_to_m00_couplers_RID),
        .m_axi_rlast(xbar_to_m00_couplers_RLAST),
        .m_axi_rready(xbar_to_m00_couplers_RREADY),
        .m_axi_rresp(xbar_to_m00_couplers_RRESP),
        .m_axi_rvalid(xbar_to_m00_couplers_RVALID),
        .m_axi_wdata(xbar_to_m00_couplers_WDATA),
        .m_axi_wlast(xbar_to_m00_couplers_WLAST),
        .m_axi_wready(xbar_to_m00_couplers_WREADY),
        .m_axi_wstrb(xbar_to_m00_couplers_WSTRB),
        .m_axi_wvalid(xbar_to_m00_couplers_WVALID),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARADDR}),
        .s_axi_arburst({1'b0,1'b0,s00_couplers_to_xbar_ARBURST}),
        .s_axi_arcache({1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARCACHE}),
        .s_axi_arid({1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARLEN}),
        .s_axi_arlock({1'b0,1'b0}),
        .s_axi_arprot({1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARPROT}),
        .s_axi_arqos({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(s00_couplers_to_xbar_ARREADY),
        .s_axi_arsize({1'b0,1'b0,1'b1,s00_couplers_to_xbar_ARSIZE}),
        .s_axi_arvalid({1'b0,s00_couplers_to_xbar_ARVALID}),
        .s_axi_awaddr({s01_couplers_to_xbar_AWADDR,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({s01_couplers_to_xbar_AWBURST,1'b0,1'b1}),
        .s_axi_awcache({s01_couplers_to_xbar_AWCACHE,1'b0,1'b0,1'b1,1'b1}),
        .s_axi_awid({1'b0,1'b0}),
        .s_axi_awlen({s01_couplers_to_xbar_AWLEN,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlock({1'b0,1'b0}),
        .s_axi_awprot({s01_couplers_to_xbar_AWPROT,1'b0,1'b0,1'b0}),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready({s01_couplers_to_xbar_AWREADY,NLW_xbar_s_axi_awready_UNCONNECTED[0]}),
        .s_axi_awsize({s01_couplers_to_xbar_AWSIZE,1'b0,1'b1,1'b1}),
        .s_axi_awvalid({s01_couplers_to_xbar_AWVALID,1'b0}),
        .s_axi_bready({s01_couplers_to_xbar_BREADY,1'b0}),
        .s_axi_bresp({s01_couplers_to_xbar_BRESP,NLW_xbar_s_axi_bresp_UNCONNECTED[1:0]}),
        .s_axi_bvalid({s01_couplers_to_xbar_BVALID,NLW_xbar_s_axi_bvalid_UNCONNECTED[0]}),
        .s_axi_rdata(s00_couplers_to_xbar_RDATA),
        .s_axi_rlast(s00_couplers_to_xbar_RLAST),
        .s_axi_rready({1'b0,s00_couplers_to_xbar_RREADY}),
        .s_axi_rresp(s00_couplers_to_xbar_RRESP),
        .s_axi_rvalid(s00_couplers_to_xbar_RVALID),
        .s_axi_wdata({s01_couplers_to_xbar_WDATA,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast({s01_couplers_to_xbar_WLAST,1'b0}),
        .s_axi_wready({s01_couplers_to_xbar_WREADY,NLW_xbar_s_axi_wready_UNCONNECTED[0]}),
        .s_axi_wstrb({s01_couplers_to_xbar_WSTRB,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .s_axi_wvalid({s01_couplers_to_xbar_WVALID,1'b0}));
endmodule

module av_system_mel_memory_0
   (ACLK,
    ARESETN,
    M00_ACLK,
    M00_ARESETN,
    M00_AXI_araddr,
    M00_AXI_arburst,
    M00_AXI_arcache,
    M00_AXI_arid,
    M00_AXI_arlen,
    M00_AXI_arlock,
    M00_AXI_arprot,
    M00_AXI_arqos,
    M00_AXI_arready,
    M00_AXI_arsize,
    M00_AXI_arvalid,
    M00_AXI_awaddr,
    M00_AXI_awburst,
    M00_AXI_awcache,
    M00_AXI_awid,
    M00_AXI_awlen,
    M00_AXI_awlock,
    M00_AXI_awprot,
    M00_AXI_awqos,
    M00_AXI_awready,
    M00_AXI_awsize,
    M00_AXI_awvalid,
    M00_AXI_bid,
    M00_AXI_bready,
    M00_AXI_bresp,
    M00_AXI_bvalid,
    M00_AXI_rdata,
    M00_AXI_rid,
    M00_AXI_rlast,
    M00_AXI_rready,
    M00_AXI_rresp,
    M00_AXI_rvalid,
    M00_AXI_wdata,
    M00_AXI_wid,
    M00_AXI_wlast,
    M00_AXI_wready,
    M00_AXI_wstrb,
    M00_AXI_wvalid,
    S00_ACLK,
    S00_ARESETN,
    S00_AXI_araddr,
    S00_AXI_arburst,
    S00_AXI_arcache,
    S00_AXI_arlen,
    S00_AXI_arprot,
    S00_AXI_arready,
    S00_AXI_arsize,
    S00_AXI_arvalid,
    S00_AXI_rdata,
    S00_AXI_rlast,
    S00_AXI_rready,
    S00_AXI_rresp,
    S00_AXI_rvalid,
    S01_ACLK,
    S01_ARESETN,
    S01_AXI_awaddr,
    S01_AXI_awburst,
    S01_AXI_awcache,
    S01_AXI_awlen,
    S01_AXI_awprot,
    S01_AXI_awready,
    S01_AXI_awsize,
    S01_AXI_awvalid,
    S01_AXI_bready,
    S01_AXI_bresp,
    S01_AXI_bvalid,
    S01_AXI_wdata,
    S01_AXI_wlast,
    S01_AXI_wready,
    S01_AXI_wstrb,
    S01_AXI_wvalid,
    S02_ACLK,
    S02_ARESETN,
    S02_AXI_araddr,
    S02_AXI_arburst,
    S02_AXI_arcache,
    S02_AXI_arlen,
    S02_AXI_arprot,
    S02_AXI_arready,
    S02_AXI_arsize,
    S02_AXI_arvalid,
    S02_AXI_rdata,
    S02_AXI_rlast,
    S02_AXI_rready,
    S02_AXI_rresp,
    S02_AXI_rvalid,
    S03_ACLK,
    S03_ARESETN,
    S03_AXI_awaddr,
    S03_AXI_awburst,
    S03_AXI_awcache,
    S03_AXI_awlen,
    S03_AXI_awprot,
    S03_AXI_awready,
    S03_AXI_awsize,
    S03_AXI_awvalid,
    S03_AXI_bready,
    S03_AXI_bresp,
    S03_AXI_bvalid,
    S03_AXI_wdata,
    S03_AXI_wlast,
    S03_AXI_wready,
    S03_AXI_wstrb,
    S03_AXI_wvalid);
  input ACLK;
  input ARESETN;
  input M00_ACLK;
  input M00_ARESETN;
  output [31:0]M00_AXI_araddr;
  output [1:0]M00_AXI_arburst;
  output [3:0]M00_AXI_arcache;
  output [1:0]M00_AXI_arid;
  output [3:0]M00_AXI_arlen;
  output [1:0]M00_AXI_arlock;
  output [2:0]M00_AXI_arprot;
  output [3:0]M00_AXI_arqos;
  input M00_AXI_arready;
  output [2:0]M00_AXI_arsize;
  output M00_AXI_arvalid;
  output [31:0]M00_AXI_awaddr;
  output [1:0]M00_AXI_awburst;
  output [3:0]M00_AXI_awcache;
  output [1:0]M00_AXI_awid;
  output [3:0]M00_AXI_awlen;
  output [1:0]M00_AXI_awlock;
  output [2:0]M00_AXI_awprot;
  output [3:0]M00_AXI_awqos;
  input M00_AXI_awready;
  output [2:0]M00_AXI_awsize;
  output M00_AXI_awvalid;
  input [5:0]M00_AXI_bid;
  output M00_AXI_bready;
  input [1:0]M00_AXI_bresp;
  input M00_AXI_bvalid;
  input [63:0]M00_AXI_rdata;
  input [5:0]M00_AXI_rid;
  input M00_AXI_rlast;
  output M00_AXI_rready;
  input [1:0]M00_AXI_rresp;
  input M00_AXI_rvalid;
  output [63:0]M00_AXI_wdata;
  output [1:0]M00_AXI_wid;
  output M00_AXI_wlast;
  input M00_AXI_wready;
  output [7:0]M00_AXI_wstrb;
  output M00_AXI_wvalid;
  input S00_ACLK;
  input S00_ARESETN;
  input [31:0]S00_AXI_araddr;
  input [1:0]S00_AXI_arburst;
  input [3:0]S00_AXI_arcache;
  input [7:0]S00_AXI_arlen;
  input [2:0]S00_AXI_arprot;
  output S00_AXI_arready;
  input [2:0]S00_AXI_arsize;
  input S00_AXI_arvalid;
  output [31:0]S00_AXI_rdata;
  output S00_AXI_rlast;
  input S00_AXI_rready;
  output [1:0]S00_AXI_rresp;
  output S00_AXI_rvalid;
  input S01_ACLK;
  input S01_ARESETN;
  input [31:0]S01_AXI_awaddr;
  input [1:0]S01_AXI_awburst;
  input [3:0]S01_AXI_awcache;
  input [7:0]S01_AXI_awlen;
  input [2:0]S01_AXI_awprot;
  output S01_AXI_awready;
  input [2:0]S01_AXI_awsize;
  input S01_AXI_awvalid;
  input S01_AXI_bready;
  output [1:0]S01_AXI_bresp;
  output S01_AXI_bvalid;
  input [31:0]S01_AXI_wdata;
  input S01_AXI_wlast;
  output S01_AXI_wready;
  input [3:0]S01_AXI_wstrb;
  input S01_AXI_wvalid;
  input S02_ACLK;
  input S02_ARESETN;
  input [31:0]S02_AXI_araddr;
  input [1:0]S02_AXI_arburst;
  input [3:0]S02_AXI_arcache;
  input [7:0]S02_AXI_arlen;
  input [2:0]S02_AXI_arprot;
  output S02_AXI_arready;
  input [2:0]S02_AXI_arsize;
  input S02_AXI_arvalid;
  output [31:0]S02_AXI_rdata;
  output S02_AXI_rlast;
  input S02_AXI_rready;
  output [1:0]S02_AXI_rresp;
  output S02_AXI_rvalid;
  input S03_ACLK;
  input S03_ARESETN;
  input [31:0]S03_AXI_awaddr;
  input [1:0]S03_AXI_awburst;
  input [3:0]S03_AXI_awcache;
  input [7:0]S03_AXI_awlen;
  input [2:0]S03_AXI_awprot;
  output S03_AXI_awready;
  input [2:0]S03_AXI_awsize;
  input S03_AXI_awvalid;
  input S03_AXI_bready;
  output [1:0]S03_AXI_bresp;
  output S03_AXI_bvalid;
  input [31:0]S03_AXI_wdata;
  input S03_AXI_wlast;
  output S03_AXI_wready;
  input [3:0]S03_AXI_wstrb;
  input S03_AXI_wvalid;

  wire M00_ACLK_1;
  wire M00_ARESETN_1;
  wire S00_ACLK_1;
  wire S00_ARESETN_1;
  wire S01_ACLK_1;
  wire S01_ARESETN_1;
  wire S02_ACLK_1;
  wire S02_ARESETN_1;
  wire S03_ACLK_1;
  wire S03_ARESETN_1;
  wire [31:0]m00_couplers_to_mel_memory_ARADDR;
  wire [1:0]m00_couplers_to_mel_memory_ARBURST;
  wire [3:0]m00_couplers_to_mel_memory_ARCACHE;
  wire [1:0]m00_couplers_to_mel_memory_ARID;
  wire [3:0]m00_couplers_to_mel_memory_ARLEN;
  wire [1:0]m00_couplers_to_mel_memory_ARLOCK;
  wire [2:0]m00_couplers_to_mel_memory_ARPROT;
  wire [3:0]m00_couplers_to_mel_memory_ARQOS;
  wire m00_couplers_to_mel_memory_ARREADY;
  wire [2:0]m00_couplers_to_mel_memory_ARSIZE;
  wire m00_couplers_to_mel_memory_ARVALID;
  wire [31:0]m00_couplers_to_mel_memory_AWADDR;
  wire [1:0]m00_couplers_to_mel_memory_AWBURST;
  wire [3:0]m00_couplers_to_mel_memory_AWCACHE;
  wire [1:0]m00_couplers_to_mel_memory_AWID;
  wire [3:0]m00_couplers_to_mel_memory_AWLEN;
  wire [1:0]m00_couplers_to_mel_memory_AWLOCK;
  wire [2:0]m00_couplers_to_mel_memory_AWPROT;
  wire [3:0]m00_couplers_to_mel_memory_AWQOS;
  wire m00_couplers_to_mel_memory_AWREADY;
  wire [2:0]m00_couplers_to_mel_memory_AWSIZE;
  wire m00_couplers_to_mel_memory_AWVALID;
  wire [5:0]m00_couplers_to_mel_memory_BID;
  wire m00_couplers_to_mel_memory_BREADY;
  wire [1:0]m00_couplers_to_mel_memory_BRESP;
  wire m00_couplers_to_mel_memory_BVALID;
  wire [63:0]m00_couplers_to_mel_memory_RDATA;
  wire [5:0]m00_couplers_to_mel_memory_RID;
  wire m00_couplers_to_mel_memory_RLAST;
  wire m00_couplers_to_mel_memory_RREADY;
  wire [1:0]m00_couplers_to_mel_memory_RRESP;
  wire m00_couplers_to_mel_memory_RVALID;
  wire [63:0]m00_couplers_to_mel_memory_WDATA;
  wire [1:0]m00_couplers_to_mel_memory_WID;
  wire m00_couplers_to_mel_memory_WLAST;
  wire m00_couplers_to_mel_memory_WREADY;
  wire [7:0]m00_couplers_to_mel_memory_WSTRB;
  wire m00_couplers_to_mel_memory_WVALID;
  wire mel_memory_ACLK_net;
  wire mel_memory_ARESETN_net;
  wire [31:0]mel_memory_to_s00_couplers_ARADDR;
  wire [1:0]mel_memory_to_s00_couplers_ARBURST;
  wire [3:0]mel_memory_to_s00_couplers_ARCACHE;
  wire [7:0]mel_memory_to_s00_couplers_ARLEN;
  wire [2:0]mel_memory_to_s00_couplers_ARPROT;
  wire mel_memory_to_s00_couplers_ARREADY;
  wire [2:0]mel_memory_to_s00_couplers_ARSIZE;
  wire mel_memory_to_s00_couplers_ARVALID;
  wire [31:0]mel_memory_to_s00_couplers_RDATA;
  wire mel_memory_to_s00_couplers_RLAST;
  wire mel_memory_to_s00_couplers_RREADY;
  wire [1:0]mel_memory_to_s00_couplers_RRESP;
  wire mel_memory_to_s00_couplers_RVALID;
  wire [31:0]mel_memory_to_s01_couplers_AWADDR;
  wire [1:0]mel_memory_to_s01_couplers_AWBURST;
  wire [3:0]mel_memory_to_s01_couplers_AWCACHE;
  wire [7:0]mel_memory_to_s01_couplers_AWLEN;
  wire [2:0]mel_memory_to_s01_couplers_AWPROT;
  wire mel_memory_to_s01_couplers_AWREADY;
  wire [2:0]mel_memory_to_s01_couplers_AWSIZE;
  wire mel_memory_to_s01_couplers_AWVALID;
  wire mel_memory_to_s01_couplers_BREADY;
  wire [1:0]mel_memory_to_s01_couplers_BRESP;
  wire mel_memory_to_s01_couplers_BVALID;
  wire [31:0]mel_memory_to_s01_couplers_WDATA;
  wire mel_memory_to_s01_couplers_WLAST;
  wire mel_memory_to_s01_couplers_WREADY;
  wire [3:0]mel_memory_to_s01_couplers_WSTRB;
  wire mel_memory_to_s01_couplers_WVALID;
  wire [31:0]mel_memory_to_s02_couplers_ARADDR;
  wire [1:0]mel_memory_to_s02_couplers_ARBURST;
  wire [3:0]mel_memory_to_s02_couplers_ARCACHE;
  wire [7:0]mel_memory_to_s02_couplers_ARLEN;
  wire [2:0]mel_memory_to_s02_couplers_ARPROT;
  wire mel_memory_to_s02_couplers_ARREADY;
  wire [2:0]mel_memory_to_s02_couplers_ARSIZE;
  wire mel_memory_to_s02_couplers_ARVALID;
  wire [31:0]mel_memory_to_s02_couplers_RDATA;
  wire mel_memory_to_s02_couplers_RLAST;
  wire mel_memory_to_s02_couplers_RREADY;
  wire [1:0]mel_memory_to_s02_couplers_RRESP;
  wire mel_memory_to_s02_couplers_RVALID;
  wire [31:0]mel_memory_to_s03_couplers_AWADDR;
  wire [1:0]mel_memory_to_s03_couplers_AWBURST;
  wire [3:0]mel_memory_to_s03_couplers_AWCACHE;
  wire [7:0]mel_memory_to_s03_couplers_AWLEN;
  wire [2:0]mel_memory_to_s03_couplers_AWPROT;
  wire mel_memory_to_s03_couplers_AWREADY;
  wire [2:0]mel_memory_to_s03_couplers_AWSIZE;
  wire mel_memory_to_s03_couplers_AWVALID;
  wire mel_memory_to_s03_couplers_BREADY;
  wire [1:0]mel_memory_to_s03_couplers_BRESP;
  wire mel_memory_to_s03_couplers_BVALID;
  wire [31:0]mel_memory_to_s03_couplers_WDATA;
  wire mel_memory_to_s03_couplers_WLAST;
  wire mel_memory_to_s03_couplers_WREADY;
  wire [3:0]mel_memory_to_s03_couplers_WSTRB;
  wire mel_memory_to_s03_couplers_WVALID;
  wire [31:0]s00_couplers_to_xbar_ARADDR;
  wire [1:0]s00_couplers_to_xbar_ARBURST;
  wire [3:0]s00_couplers_to_xbar_ARCACHE;
  wire [7:0]s00_couplers_to_xbar_ARLEN;
  wire [0:0]s00_couplers_to_xbar_ARLOCK;
  wire [2:0]s00_couplers_to_xbar_ARPROT;
  wire [3:0]s00_couplers_to_xbar_ARQOS;
  wire [0:0]s00_couplers_to_xbar_ARREADY;
  wire [2:0]s00_couplers_to_xbar_ARSIZE;
  wire s00_couplers_to_xbar_ARVALID;
  wire [63:0]s00_couplers_to_xbar_RDATA;
  wire [0:0]s00_couplers_to_xbar_RLAST;
  wire s00_couplers_to_xbar_RREADY;
  wire [1:0]s00_couplers_to_xbar_RRESP;
  wire [0:0]s00_couplers_to_xbar_RVALID;
  wire [31:0]s01_couplers_to_xbar_AWADDR;
  wire [1:0]s01_couplers_to_xbar_AWBURST;
  wire [3:0]s01_couplers_to_xbar_AWCACHE;
  wire [7:0]s01_couplers_to_xbar_AWLEN;
  wire [0:0]s01_couplers_to_xbar_AWLOCK;
  wire [2:0]s01_couplers_to_xbar_AWPROT;
  wire [3:0]s01_couplers_to_xbar_AWQOS;
  wire [1:1]s01_couplers_to_xbar_AWREADY;
  wire [2:0]s01_couplers_to_xbar_AWSIZE;
  wire s01_couplers_to_xbar_AWVALID;
  wire s01_couplers_to_xbar_BREADY;
  wire [3:2]s01_couplers_to_xbar_BRESP;
  wire [1:1]s01_couplers_to_xbar_BVALID;
  wire [63:0]s01_couplers_to_xbar_WDATA;
  wire s01_couplers_to_xbar_WLAST;
  wire [1:1]s01_couplers_to_xbar_WREADY;
  wire [7:0]s01_couplers_to_xbar_WSTRB;
  wire s01_couplers_to_xbar_WVALID;
  wire [31:0]s02_couplers_to_xbar_ARADDR;
  wire [1:0]s02_couplers_to_xbar_ARBURST;
  wire [3:0]s02_couplers_to_xbar_ARCACHE;
  wire [7:0]s02_couplers_to_xbar_ARLEN;
  wire [0:0]s02_couplers_to_xbar_ARLOCK;
  wire [2:0]s02_couplers_to_xbar_ARPROT;
  wire [3:0]s02_couplers_to_xbar_ARQOS;
  wire [2:2]s02_couplers_to_xbar_ARREADY;
  wire [2:0]s02_couplers_to_xbar_ARSIZE;
  wire s02_couplers_to_xbar_ARVALID;
  wire [191:128]s02_couplers_to_xbar_RDATA;
  wire [2:2]s02_couplers_to_xbar_RLAST;
  wire s02_couplers_to_xbar_RREADY;
  wire [5:4]s02_couplers_to_xbar_RRESP;
  wire [2:2]s02_couplers_to_xbar_RVALID;
  wire [31:0]s03_couplers_to_xbar_AWADDR;
  wire [1:0]s03_couplers_to_xbar_AWBURST;
  wire [3:0]s03_couplers_to_xbar_AWCACHE;
  wire [7:0]s03_couplers_to_xbar_AWLEN;
  wire [0:0]s03_couplers_to_xbar_AWLOCK;
  wire [2:0]s03_couplers_to_xbar_AWPROT;
  wire [3:0]s03_couplers_to_xbar_AWQOS;
  wire [3:3]s03_couplers_to_xbar_AWREADY;
  wire [2:0]s03_couplers_to_xbar_AWSIZE;
  wire s03_couplers_to_xbar_AWVALID;
  wire s03_couplers_to_xbar_BREADY;
  wire [7:6]s03_couplers_to_xbar_BRESP;
  wire [3:3]s03_couplers_to_xbar_BVALID;
  wire [63:0]s03_couplers_to_xbar_WDATA;
  wire s03_couplers_to_xbar_WLAST;
  wire [3:3]s03_couplers_to_xbar_WREADY;
  wire [7:0]s03_couplers_to_xbar_WSTRB;
  wire s03_couplers_to_xbar_WVALID;
  wire [31:0]xbar_to_m00_couplers_ARADDR;
  wire [1:0]xbar_to_m00_couplers_ARBURST;
  wire [3:0]xbar_to_m00_couplers_ARCACHE;
  wire [1:0]xbar_to_m00_couplers_ARID;
  wire [7:0]xbar_to_m00_couplers_ARLEN;
  wire [0:0]xbar_to_m00_couplers_ARLOCK;
  wire [2:0]xbar_to_m00_couplers_ARPROT;
  wire [3:0]xbar_to_m00_couplers_ARQOS;
  wire xbar_to_m00_couplers_ARREADY;
  wire [3:0]xbar_to_m00_couplers_ARREGION;
  wire [2:0]xbar_to_m00_couplers_ARSIZE;
  wire [0:0]xbar_to_m00_couplers_ARVALID;
  wire [31:0]xbar_to_m00_couplers_AWADDR;
  wire [1:0]xbar_to_m00_couplers_AWBURST;
  wire [3:0]xbar_to_m00_couplers_AWCACHE;
  wire [1:0]xbar_to_m00_couplers_AWID;
  wire [7:0]xbar_to_m00_couplers_AWLEN;
  wire [0:0]xbar_to_m00_couplers_AWLOCK;
  wire [2:0]xbar_to_m00_couplers_AWPROT;
  wire [3:0]xbar_to_m00_couplers_AWQOS;
  wire xbar_to_m00_couplers_AWREADY;
  wire [3:0]xbar_to_m00_couplers_AWREGION;
  wire [2:0]xbar_to_m00_couplers_AWSIZE;
  wire [0:0]xbar_to_m00_couplers_AWVALID;
  wire [1:0]xbar_to_m00_couplers_BID;
  wire [0:0]xbar_to_m00_couplers_BREADY;
  wire [1:0]xbar_to_m00_couplers_BRESP;
  wire xbar_to_m00_couplers_BVALID;
  wire [63:0]xbar_to_m00_couplers_RDATA;
  wire [1:0]xbar_to_m00_couplers_RID;
  wire xbar_to_m00_couplers_RLAST;
  wire [0:0]xbar_to_m00_couplers_RREADY;
  wire [1:0]xbar_to_m00_couplers_RRESP;
  wire xbar_to_m00_couplers_RVALID;
  wire [63:0]xbar_to_m00_couplers_WDATA;
  wire [0:0]xbar_to_m00_couplers_WLAST;
  wire xbar_to_m00_couplers_WREADY;
  wire [7:0]xbar_to_m00_couplers_WSTRB;
  wire [0:0]xbar_to_m00_couplers_WVALID;
  wire [3:0]NLW_xbar_s_axi_arready_UNCONNECTED;
  wire [3:0]NLW_xbar_s_axi_awready_UNCONNECTED;
  wire [7:0]NLW_xbar_s_axi_bresp_UNCONNECTED;
  wire [3:0]NLW_xbar_s_axi_bvalid_UNCONNECTED;
  wire [255:0]NLW_xbar_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_xbar_s_axi_rlast_UNCONNECTED;
  wire [7:0]NLW_xbar_s_axi_rresp_UNCONNECTED;
  wire [3:0]NLW_xbar_s_axi_rvalid_UNCONNECTED;
  wire [3:0]NLW_xbar_s_axi_wready_UNCONNECTED;

  assign M00_ACLK_1 = M00_ACLK;
  assign M00_ARESETN_1 = M00_ARESETN;
  assign M00_AXI_araddr[31:0] = m00_couplers_to_mel_memory_ARADDR;
  assign M00_AXI_arburst[1:0] = m00_couplers_to_mel_memory_ARBURST;
  assign M00_AXI_arcache[3:0] = m00_couplers_to_mel_memory_ARCACHE;
  assign M00_AXI_arid[1:0] = m00_couplers_to_mel_memory_ARID;
  assign M00_AXI_arlen[3:0] = m00_couplers_to_mel_memory_ARLEN;
  assign M00_AXI_arlock[1:0] = m00_couplers_to_mel_memory_ARLOCK;
  assign M00_AXI_arprot[2:0] = m00_couplers_to_mel_memory_ARPROT;
  assign M00_AXI_arqos[3:0] = m00_couplers_to_mel_memory_ARQOS;
  assign M00_AXI_arsize[2:0] = m00_couplers_to_mel_memory_ARSIZE;
  assign M00_AXI_arvalid = m00_couplers_to_mel_memory_ARVALID;
  assign M00_AXI_awaddr[31:0] = m00_couplers_to_mel_memory_AWADDR;
  assign M00_AXI_awburst[1:0] = m00_couplers_to_mel_memory_AWBURST;
  assign M00_AXI_awcache[3:0] = m00_couplers_to_mel_memory_AWCACHE;
  assign M00_AXI_awid[1:0] = m00_couplers_to_mel_memory_AWID;
  assign M00_AXI_awlen[3:0] = m00_couplers_to_mel_memory_AWLEN;
  assign M00_AXI_awlock[1:0] = m00_couplers_to_mel_memory_AWLOCK;
  assign M00_AXI_awprot[2:0] = m00_couplers_to_mel_memory_AWPROT;
  assign M00_AXI_awqos[3:0] = m00_couplers_to_mel_memory_AWQOS;
  assign M00_AXI_awsize[2:0] = m00_couplers_to_mel_memory_AWSIZE;
  assign M00_AXI_awvalid = m00_couplers_to_mel_memory_AWVALID;
  assign M00_AXI_bready = m00_couplers_to_mel_memory_BREADY;
  assign M00_AXI_rready = m00_couplers_to_mel_memory_RREADY;
  assign M00_AXI_wdata[63:0] = m00_couplers_to_mel_memory_WDATA;
  assign M00_AXI_wid[1:0] = m00_couplers_to_mel_memory_WID;
  assign M00_AXI_wlast = m00_couplers_to_mel_memory_WLAST;
  assign M00_AXI_wstrb[7:0] = m00_couplers_to_mel_memory_WSTRB;
  assign M00_AXI_wvalid = m00_couplers_to_mel_memory_WVALID;
  assign S00_ACLK_1 = S00_ACLK;
  assign S00_ARESETN_1 = S00_ARESETN;
  assign S00_AXI_arready = mel_memory_to_s00_couplers_ARREADY;
  assign S00_AXI_rdata[31:0] = mel_memory_to_s00_couplers_RDATA;
  assign S00_AXI_rlast = mel_memory_to_s00_couplers_RLAST;
  assign S00_AXI_rresp[1:0] = mel_memory_to_s00_couplers_RRESP;
  assign S00_AXI_rvalid = mel_memory_to_s00_couplers_RVALID;
  assign S01_ACLK_1 = S01_ACLK;
  assign S01_ARESETN_1 = S01_ARESETN;
  assign S01_AXI_awready = mel_memory_to_s01_couplers_AWREADY;
  assign S01_AXI_bresp[1:0] = mel_memory_to_s01_couplers_BRESP;
  assign S01_AXI_bvalid = mel_memory_to_s01_couplers_BVALID;
  assign S01_AXI_wready = mel_memory_to_s01_couplers_WREADY;
  assign S02_ACLK_1 = S02_ACLK;
  assign S02_ARESETN_1 = S02_ARESETN;
  assign S02_AXI_arready = mel_memory_to_s02_couplers_ARREADY;
  assign S02_AXI_rdata[31:0] = mel_memory_to_s02_couplers_RDATA;
  assign S02_AXI_rlast = mel_memory_to_s02_couplers_RLAST;
  assign S02_AXI_rresp[1:0] = mel_memory_to_s02_couplers_RRESP;
  assign S02_AXI_rvalid = mel_memory_to_s02_couplers_RVALID;
  assign S03_ACLK_1 = S03_ACLK;
  assign S03_ARESETN_1 = S03_ARESETN;
  assign S03_AXI_awready = mel_memory_to_s03_couplers_AWREADY;
  assign S03_AXI_bresp[1:0] = mel_memory_to_s03_couplers_BRESP;
  assign S03_AXI_bvalid = mel_memory_to_s03_couplers_BVALID;
  assign S03_AXI_wready = mel_memory_to_s03_couplers_WREADY;
  assign m00_couplers_to_mel_memory_ARREADY = M00_AXI_arready;
  assign m00_couplers_to_mel_memory_AWREADY = M00_AXI_awready;
  assign m00_couplers_to_mel_memory_BID = M00_AXI_bid[5:0];
  assign m00_couplers_to_mel_memory_BRESP = M00_AXI_bresp[1:0];
  assign m00_couplers_to_mel_memory_BVALID = M00_AXI_bvalid;
  assign m00_couplers_to_mel_memory_RDATA = M00_AXI_rdata[63:0];
  assign m00_couplers_to_mel_memory_RID = M00_AXI_rid[5:0];
  assign m00_couplers_to_mel_memory_RLAST = M00_AXI_rlast;
  assign m00_couplers_to_mel_memory_RRESP = M00_AXI_rresp[1:0];
  assign m00_couplers_to_mel_memory_RVALID = M00_AXI_rvalid;
  assign m00_couplers_to_mel_memory_WREADY = M00_AXI_wready;
  assign mel_memory_ACLK_net = ACLK;
  assign mel_memory_ARESETN_net = ARESETN;
  assign mel_memory_to_s00_couplers_ARADDR = S00_AXI_araddr[31:0];
  assign mel_memory_to_s00_couplers_ARBURST = S00_AXI_arburst[1:0];
  assign mel_memory_to_s00_couplers_ARCACHE = S00_AXI_arcache[3:0];
  assign mel_memory_to_s00_couplers_ARLEN = S00_AXI_arlen[7:0];
  assign mel_memory_to_s00_couplers_ARPROT = S00_AXI_arprot[2:0];
  assign mel_memory_to_s00_couplers_ARSIZE = S00_AXI_arsize[2:0];
  assign mel_memory_to_s00_couplers_ARVALID = S00_AXI_arvalid;
  assign mel_memory_to_s00_couplers_RREADY = S00_AXI_rready;
  assign mel_memory_to_s01_couplers_AWADDR = S01_AXI_awaddr[31:0];
  assign mel_memory_to_s01_couplers_AWBURST = S01_AXI_awburst[1:0];
  assign mel_memory_to_s01_couplers_AWCACHE = S01_AXI_awcache[3:0];
  assign mel_memory_to_s01_couplers_AWLEN = S01_AXI_awlen[7:0];
  assign mel_memory_to_s01_couplers_AWPROT = S01_AXI_awprot[2:0];
  assign mel_memory_to_s01_couplers_AWSIZE = S01_AXI_awsize[2:0];
  assign mel_memory_to_s01_couplers_AWVALID = S01_AXI_awvalid;
  assign mel_memory_to_s01_couplers_BREADY = S01_AXI_bready;
  assign mel_memory_to_s01_couplers_WDATA = S01_AXI_wdata[31:0];
  assign mel_memory_to_s01_couplers_WLAST = S01_AXI_wlast;
  assign mel_memory_to_s01_couplers_WSTRB = S01_AXI_wstrb[3:0];
  assign mel_memory_to_s01_couplers_WVALID = S01_AXI_wvalid;
  assign mel_memory_to_s02_couplers_ARADDR = S02_AXI_araddr[31:0];
  assign mel_memory_to_s02_couplers_ARBURST = S02_AXI_arburst[1:0];
  assign mel_memory_to_s02_couplers_ARCACHE = S02_AXI_arcache[3:0];
  assign mel_memory_to_s02_couplers_ARLEN = S02_AXI_arlen[7:0];
  assign mel_memory_to_s02_couplers_ARPROT = S02_AXI_arprot[2:0];
  assign mel_memory_to_s02_couplers_ARSIZE = S02_AXI_arsize[2:0];
  assign mel_memory_to_s02_couplers_ARVALID = S02_AXI_arvalid;
  assign mel_memory_to_s02_couplers_RREADY = S02_AXI_rready;
  assign mel_memory_to_s03_couplers_AWADDR = S03_AXI_awaddr[31:0];
  assign mel_memory_to_s03_couplers_AWBURST = S03_AXI_awburst[1:0];
  assign mel_memory_to_s03_couplers_AWCACHE = S03_AXI_awcache[3:0];
  assign mel_memory_to_s03_couplers_AWLEN = S03_AXI_awlen[7:0];
  assign mel_memory_to_s03_couplers_AWPROT = S03_AXI_awprot[2:0];
  assign mel_memory_to_s03_couplers_AWSIZE = S03_AXI_awsize[2:0];
  assign mel_memory_to_s03_couplers_AWVALID = S03_AXI_awvalid;
  assign mel_memory_to_s03_couplers_BREADY = S03_AXI_bready;
  assign mel_memory_to_s03_couplers_WDATA = S03_AXI_wdata[31:0];
  assign mel_memory_to_s03_couplers_WLAST = S03_AXI_wlast;
  assign mel_memory_to_s03_couplers_WSTRB = S03_AXI_wstrb[3:0];
  assign mel_memory_to_s03_couplers_WVALID = S03_AXI_wvalid;
  m00_couplers_imp_10KKZXR m00_couplers
       (.M_ACLK(M00_ACLK_1),
        .M_ARESETN(M00_ARESETN_1),
        .M_AXI_araddr(m00_couplers_to_mel_memory_ARADDR),
        .M_AXI_arburst(m00_couplers_to_mel_memory_ARBURST),
        .M_AXI_arcache(m00_couplers_to_mel_memory_ARCACHE),
        .M_AXI_arid(m00_couplers_to_mel_memory_ARID),
        .M_AXI_arlen(m00_couplers_to_mel_memory_ARLEN),
        .M_AXI_arlock(m00_couplers_to_mel_memory_ARLOCK),
        .M_AXI_arprot(m00_couplers_to_mel_memory_ARPROT),
        .M_AXI_arqos(m00_couplers_to_mel_memory_ARQOS),
        .M_AXI_arready(m00_couplers_to_mel_memory_ARREADY),
        .M_AXI_arsize(m00_couplers_to_mel_memory_ARSIZE),
        .M_AXI_arvalid(m00_couplers_to_mel_memory_ARVALID),
        .M_AXI_awaddr(m00_couplers_to_mel_memory_AWADDR),
        .M_AXI_awburst(m00_couplers_to_mel_memory_AWBURST),
        .M_AXI_awcache(m00_couplers_to_mel_memory_AWCACHE),
        .M_AXI_awid(m00_couplers_to_mel_memory_AWID),
        .M_AXI_awlen(m00_couplers_to_mel_memory_AWLEN),
        .M_AXI_awlock(m00_couplers_to_mel_memory_AWLOCK),
        .M_AXI_awprot(m00_couplers_to_mel_memory_AWPROT),
        .M_AXI_awqos(m00_couplers_to_mel_memory_AWQOS),
        .M_AXI_awready(m00_couplers_to_mel_memory_AWREADY),
        .M_AXI_awsize(m00_couplers_to_mel_memory_AWSIZE),
        .M_AXI_awvalid(m00_couplers_to_mel_memory_AWVALID),
        .M_AXI_bid(m00_couplers_to_mel_memory_BID),
        .M_AXI_bready(m00_couplers_to_mel_memory_BREADY),
        .M_AXI_bresp(m00_couplers_to_mel_memory_BRESP),
        .M_AXI_bvalid(m00_couplers_to_mel_memory_BVALID),
        .M_AXI_rdata(m00_couplers_to_mel_memory_RDATA),
        .M_AXI_rid(m00_couplers_to_mel_memory_RID),
        .M_AXI_rlast(m00_couplers_to_mel_memory_RLAST),
        .M_AXI_rready(m00_couplers_to_mel_memory_RREADY),
        .M_AXI_rresp(m00_couplers_to_mel_memory_RRESP),
        .M_AXI_rvalid(m00_couplers_to_mel_memory_RVALID),
        .M_AXI_wdata(m00_couplers_to_mel_memory_WDATA),
        .M_AXI_wid(m00_couplers_to_mel_memory_WID),
        .M_AXI_wlast(m00_couplers_to_mel_memory_WLAST),
        .M_AXI_wready(m00_couplers_to_mel_memory_WREADY),
        .M_AXI_wstrb(m00_couplers_to_mel_memory_WSTRB),
        .M_AXI_wvalid(m00_couplers_to_mel_memory_WVALID),
        .S_ACLK(mel_memory_ACLK_net),
        .S_ARESETN(mel_memory_ARESETN_net),
        .S_AXI_araddr(xbar_to_m00_couplers_ARADDR),
        .S_AXI_arburst(xbar_to_m00_couplers_ARBURST),
        .S_AXI_arcache(xbar_to_m00_couplers_ARCACHE),
        .S_AXI_arid(xbar_to_m00_couplers_ARID),
        .S_AXI_arlen(xbar_to_m00_couplers_ARLEN),
        .S_AXI_arlock(xbar_to_m00_couplers_ARLOCK),
        .S_AXI_arprot(xbar_to_m00_couplers_ARPROT),
        .S_AXI_arqos(xbar_to_m00_couplers_ARQOS),
        .S_AXI_arready(xbar_to_m00_couplers_ARREADY),
        .S_AXI_arregion(xbar_to_m00_couplers_ARREGION),
        .S_AXI_arsize(xbar_to_m00_couplers_ARSIZE),
        .S_AXI_arvalid(xbar_to_m00_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m00_couplers_AWADDR),
        .S_AXI_awburst(xbar_to_m00_couplers_AWBURST),
        .S_AXI_awcache(xbar_to_m00_couplers_AWCACHE),
        .S_AXI_awid(xbar_to_m00_couplers_AWID),
        .S_AXI_awlen(xbar_to_m00_couplers_AWLEN),
        .S_AXI_awlock(xbar_to_m00_couplers_AWLOCK),
        .S_AXI_awprot(xbar_to_m00_couplers_AWPROT),
        .S_AXI_awqos(xbar_to_m00_couplers_AWQOS),
        .S_AXI_awready(xbar_to_m00_couplers_AWREADY),
        .S_AXI_awregion(xbar_to_m00_couplers_AWREGION),
        .S_AXI_awsize(xbar_to_m00_couplers_AWSIZE),
        .S_AXI_awvalid(xbar_to_m00_couplers_AWVALID),
        .S_AXI_bid(xbar_to_m00_couplers_BID),
        .S_AXI_bready(xbar_to_m00_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m00_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m00_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m00_couplers_RDATA),
        .S_AXI_rid(xbar_to_m00_couplers_RID),
        .S_AXI_rlast(xbar_to_m00_couplers_RLAST),
        .S_AXI_rready(xbar_to_m00_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m00_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m00_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m00_couplers_WDATA),
        .S_AXI_wlast(xbar_to_m00_couplers_WLAST),
        .S_AXI_wready(xbar_to_m00_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m00_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m00_couplers_WVALID));
  s00_couplers_imp_7QNGDV s00_couplers
       (.M_ACLK(mel_memory_ACLK_net),
        .M_ARESETN(mel_memory_ARESETN_net),
        .M_AXI_araddr(s00_couplers_to_xbar_ARADDR),
        .M_AXI_arburst(s00_couplers_to_xbar_ARBURST),
        .M_AXI_arcache(s00_couplers_to_xbar_ARCACHE),
        .M_AXI_arlen(s00_couplers_to_xbar_ARLEN),
        .M_AXI_arlock(s00_couplers_to_xbar_ARLOCK),
        .M_AXI_arprot(s00_couplers_to_xbar_ARPROT),
        .M_AXI_arqos(s00_couplers_to_xbar_ARQOS),
        .M_AXI_arready(s00_couplers_to_xbar_ARREADY),
        .M_AXI_arsize(s00_couplers_to_xbar_ARSIZE),
        .M_AXI_arvalid(s00_couplers_to_xbar_ARVALID),
        .M_AXI_rdata(s00_couplers_to_xbar_RDATA),
        .M_AXI_rlast(s00_couplers_to_xbar_RLAST),
        .M_AXI_rready(s00_couplers_to_xbar_RREADY),
        .M_AXI_rresp(s00_couplers_to_xbar_RRESP),
        .M_AXI_rvalid(s00_couplers_to_xbar_RVALID),
        .S_ACLK(S00_ACLK_1),
        .S_ARESETN(S00_ARESETN_1),
        .S_AXI_araddr(mel_memory_to_s00_couplers_ARADDR),
        .S_AXI_arburst(mel_memory_to_s00_couplers_ARBURST),
        .S_AXI_arcache(mel_memory_to_s00_couplers_ARCACHE),
        .S_AXI_arlen(mel_memory_to_s00_couplers_ARLEN),
        .S_AXI_arprot(mel_memory_to_s00_couplers_ARPROT),
        .S_AXI_arready(mel_memory_to_s00_couplers_ARREADY),
        .S_AXI_arsize(mel_memory_to_s00_couplers_ARSIZE),
        .S_AXI_arvalid(mel_memory_to_s00_couplers_ARVALID),
        .S_AXI_rdata(mel_memory_to_s00_couplers_RDATA),
        .S_AXI_rlast(mel_memory_to_s00_couplers_RLAST),
        .S_AXI_rready(mel_memory_to_s00_couplers_RREADY),
        .S_AXI_rresp(mel_memory_to_s00_couplers_RRESP),
        .S_AXI_rvalid(mel_memory_to_s00_couplers_RVALID));
  s01_couplers_imp_1KLZ1T7 s01_couplers
       (.M_ACLK(mel_memory_ACLK_net),
        .M_ARESETN(mel_memory_ARESETN_net),
        .M_AXI_awaddr(s01_couplers_to_xbar_AWADDR),
        .M_AXI_awburst(s01_couplers_to_xbar_AWBURST),
        .M_AXI_awcache(s01_couplers_to_xbar_AWCACHE),
        .M_AXI_awlen(s01_couplers_to_xbar_AWLEN),
        .M_AXI_awlock(s01_couplers_to_xbar_AWLOCK),
        .M_AXI_awprot(s01_couplers_to_xbar_AWPROT),
        .M_AXI_awqos(s01_couplers_to_xbar_AWQOS),
        .M_AXI_awready(s01_couplers_to_xbar_AWREADY),
        .M_AXI_awsize(s01_couplers_to_xbar_AWSIZE),
        .M_AXI_awvalid(s01_couplers_to_xbar_AWVALID),
        .M_AXI_bready(s01_couplers_to_xbar_BREADY),
        .M_AXI_bresp(s01_couplers_to_xbar_BRESP),
        .M_AXI_bvalid(s01_couplers_to_xbar_BVALID),
        .M_AXI_wdata(s01_couplers_to_xbar_WDATA),
        .M_AXI_wlast(s01_couplers_to_xbar_WLAST),
        .M_AXI_wready(s01_couplers_to_xbar_WREADY),
        .M_AXI_wstrb(s01_couplers_to_xbar_WSTRB),
        .M_AXI_wvalid(s01_couplers_to_xbar_WVALID),
        .S_ACLK(S01_ACLK_1),
        .S_ARESETN(S01_ARESETN_1),
        .S_AXI_awaddr(mel_memory_to_s01_couplers_AWADDR),
        .S_AXI_awburst(mel_memory_to_s01_couplers_AWBURST),
        .S_AXI_awcache(mel_memory_to_s01_couplers_AWCACHE),
        .S_AXI_awlen(mel_memory_to_s01_couplers_AWLEN),
        .S_AXI_awprot(mel_memory_to_s01_couplers_AWPROT),
        .S_AXI_awready(mel_memory_to_s01_couplers_AWREADY),
        .S_AXI_awsize(mel_memory_to_s01_couplers_AWSIZE),
        .S_AXI_awvalid(mel_memory_to_s01_couplers_AWVALID),
        .S_AXI_bready(mel_memory_to_s01_couplers_BREADY),
        .S_AXI_bresp(mel_memory_to_s01_couplers_BRESP),
        .S_AXI_bvalid(mel_memory_to_s01_couplers_BVALID),
        .S_AXI_wdata(mel_memory_to_s01_couplers_WDATA),
        .S_AXI_wlast(mel_memory_to_s01_couplers_WLAST),
        .S_AXI_wready(mel_memory_to_s01_couplers_WREADY),
        .S_AXI_wstrb(mel_memory_to_s01_couplers_WSTRB),
        .S_AXI_wvalid(mel_memory_to_s01_couplers_WVALID));
  s02_couplers_imp_UVXHKY s02_couplers
       (.M_ACLK(mel_memory_ACLK_net),
        .M_ARESETN(mel_memory_ARESETN_net),
        .M_AXI_araddr(s02_couplers_to_xbar_ARADDR),
        .M_AXI_arburst(s02_couplers_to_xbar_ARBURST),
        .M_AXI_arcache(s02_couplers_to_xbar_ARCACHE),
        .M_AXI_arlen(s02_couplers_to_xbar_ARLEN),
        .M_AXI_arlock(s02_couplers_to_xbar_ARLOCK),
        .M_AXI_arprot(s02_couplers_to_xbar_ARPROT),
        .M_AXI_arqos(s02_couplers_to_xbar_ARQOS),
        .M_AXI_arready(s02_couplers_to_xbar_ARREADY),
        .M_AXI_arsize(s02_couplers_to_xbar_ARSIZE),
        .M_AXI_arvalid(s02_couplers_to_xbar_ARVALID),
        .M_AXI_rdata(s02_couplers_to_xbar_RDATA),
        .M_AXI_rlast(s02_couplers_to_xbar_RLAST),
        .M_AXI_rready(s02_couplers_to_xbar_RREADY),
        .M_AXI_rresp(s02_couplers_to_xbar_RRESP),
        .M_AXI_rvalid(s02_couplers_to_xbar_RVALID),
        .S_ACLK(S02_ACLK_1),
        .S_ARESETN(S02_ARESETN_1),
        .S_AXI_araddr(mel_memory_to_s02_couplers_ARADDR),
        .S_AXI_arburst(mel_memory_to_s02_couplers_ARBURST),
        .S_AXI_arcache(mel_memory_to_s02_couplers_ARCACHE),
        .S_AXI_arlen(mel_memory_to_s02_couplers_ARLEN),
        .S_AXI_arprot(mel_memory_to_s02_couplers_ARPROT),
        .S_AXI_arready(mel_memory_to_s02_couplers_ARREADY),
        .S_AXI_arsize(mel_memory_to_s02_couplers_ARSIZE),
        .S_AXI_arvalid(mel_memory_to_s02_couplers_ARVALID),
        .S_AXI_rdata(mel_memory_to_s02_couplers_RDATA),
        .S_AXI_rlast(mel_memory_to_s02_couplers_RLAST),
        .S_AXI_rready(mel_memory_to_s02_couplers_RREADY),
        .S_AXI_rresp(mel_memory_to_s02_couplers_RRESP),
        .S_AXI_rvalid(mel_memory_to_s02_couplers_RVALID));
  s03_couplers_imp_1F8WSUY s03_couplers
       (.M_ACLK(mel_memory_ACLK_net),
        .M_ARESETN(mel_memory_ARESETN_net),
        .M_AXI_awaddr(s03_couplers_to_xbar_AWADDR),
        .M_AXI_awburst(s03_couplers_to_xbar_AWBURST),
        .M_AXI_awcache(s03_couplers_to_xbar_AWCACHE),
        .M_AXI_awlen(s03_couplers_to_xbar_AWLEN),
        .M_AXI_awlock(s03_couplers_to_xbar_AWLOCK),
        .M_AXI_awprot(s03_couplers_to_xbar_AWPROT),
        .M_AXI_awqos(s03_couplers_to_xbar_AWQOS),
        .M_AXI_awready(s03_couplers_to_xbar_AWREADY),
        .M_AXI_awsize(s03_couplers_to_xbar_AWSIZE),
        .M_AXI_awvalid(s03_couplers_to_xbar_AWVALID),
        .M_AXI_bready(s03_couplers_to_xbar_BREADY),
        .M_AXI_bresp(s03_couplers_to_xbar_BRESP),
        .M_AXI_bvalid(s03_couplers_to_xbar_BVALID),
        .M_AXI_wdata(s03_couplers_to_xbar_WDATA),
        .M_AXI_wlast(s03_couplers_to_xbar_WLAST),
        .M_AXI_wready(s03_couplers_to_xbar_WREADY),
        .M_AXI_wstrb(s03_couplers_to_xbar_WSTRB),
        .M_AXI_wvalid(s03_couplers_to_xbar_WVALID),
        .S_ACLK(S03_ACLK_1),
        .S_ARESETN(S03_ARESETN_1),
        .S_AXI_awaddr(mel_memory_to_s03_couplers_AWADDR),
        .S_AXI_awburst(mel_memory_to_s03_couplers_AWBURST),
        .S_AXI_awcache(mel_memory_to_s03_couplers_AWCACHE),
        .S_AXI_awlen(mel_memory_to_s03_couplers_AWLEN),
        .S_AXI_awprot(mel_memory_to_s03_couplers_AWPROT),
        .S_AXI_awready(mel_memory_to_s03_couplers_AWREADY),
        .S_AXI_awsize(mel_memory_to_s03_couplers_AWSIZE),
        .S_AXI_awvalid(mel_memory_to_s03_couplers_AWVALID),
        .S_AXI_bready(mel_memory_to_s03_couplers_BREADY),
        .S_AXI_bresp(mel_memory_to_s03_couplers_BRESP),
        .S_AXI_bvalid(mel_memory_to_s03_couplers_BVALID),
        .S_AXI_wdata(mel_memory_to_s03_couplers_WDATA),
        .S_AXI_wlast(mel_memory_to_s03_couplers_WLAST),
        .S_AXI_wready(mel_memory_to_s03_couplers_WREADY),
        .S_AXI_wstrb(mel_memory_to_s03_couplers_WSTRB),
        .S_AXI_wvalid(mel_memory_to_s03_couplers_WVALID));
  av_system_xbar_2 xbar
       (.aclk(mel_memory_ACLK_net),
        .aresetn(mel_memory_ARESETN_net),
        .m_axi_araddr(xbar_to_m00_couplers_ARADDR),
        .m_axi_arburst(xbar_to_m00_couplers_ARBURST),
        .m_axi_arcache(xbar_to_m00_couplers_ARCACHE),
        .m_axi_arid(xbar_to_m00_couplers_ARID),
        .m_axi_arlen(xbar_to_m00_couplers_ARLEN),
        .m_axi_arlock(xbar_to_m00_couplers_ARLOCK),
        .m_axi_arprot(xbar_to_m00_couplers_ARPROT),
        .m_axi_arqos(xbar_to_m00_couplers_ARQOS),
        .m_axi_arready(xbar_to_m00_couplers_ARREADY),
        .m_axi_arregion(xbar_to_m00_couplers_ARREGION),
        .m_axi_arsize(xbar_to_m00_couplers_ARSIZE),
        .m_axi_arvalid(xbar_to_m00_couplers_ARVALID),
        .m_axi_awaddr(xbar_to_m00_couplers_AWADDR),
        .m_axi_awburst(xbar_to_m00_couplers_AWBURST),
        .m_axi_awcache(xbar_to_m00_couplers_AWCACHE),
        .m_axi_awid(xbar_to_m00_couplers_AWID),
        .m_axi_awlen(xbar_to_m00_couplers_AWLEN),
        .m_axi_awlock(xbar_to_m00_couplers_AWLOCK),
        .m_axi_awprot(xbar_to_m00_couplers_AWPROT),
        .m_axi_awqos(xbar_to_m00_couplers_AWQOS),
        .m_axi_awready(xbar_to_m00_couplers_AWREADY),
        .m_axi_awregion(xbar_to_m00_couplers_AWREGION),
        .m_axi_awsize(xbar_to_m00_couplers_AWSIZE),
        .m_axi_awvalid(xbar_to_m00_couplers_AWVALID),
        .m_axi_bid(xbar_to_m00_couplers_BID),
        .m_axi_bready(xbar_to_m00_couplers_BREADY),
        .m_axi_bresp(xbar_to_m00_couplers_BRESP),
        .m_axi_bvalid(xbar_to_m00_couplers_BVALID),
        .m_axi_rdata(xbar_to_m00_couplers_RDATA),
        .m_axi_rid(xbar_to_m00_couplers_RID),
        .m_axi_rlast(xbar_to_m00_couplers_RLAST),
        .m_axi_rready(xbar_to_m00_couplers_RREADY),
        .m_axi_rresp(xbar_to_m00_couplers_RRESP),
        .m_axi_rvalid(xbar_to_m00_couplers_RVALID),
        .m_axi_wdata(xbar_to_m00_couplers_WDATA),
        .m_axi_wlast(xbar_to_m00_couplers_WLAST),
        .m_axi_wready(xbar_to_m00_couplers_WREADY),
        .m_axi_wstrb(xbar_to_m00_couplers_WSTRB),
        .m_axi_wvalid(xbar_to_m00_couplers_WVALID),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s02_couplers_to_xbar_ARADDR,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARADDR}),
        .s_axi_arburst({1'b0,1'b0,s02_couplers_to_xbar_ARBURST,1'b0,1'b0,s00_couplers_to_xbar_ARBURST}),
        .s_axi_arcache({1'b0,1'b0,1'b0,1'b0,s02_couplers_to_xbar_ARCACHE,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARCACHE}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s02_couplers_to_xbar_ARLEN,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARLEN}),
        .s_axi_arlock({1'b0,s02_couplers_to_xbar_ARLOCK,1'b0,s00_couplers_to_xbar_ARLOCK}),
        .s_axi_arprot({1'b0,1'b0,1'b0,s02_couplers_to_xbar_ARPROT,1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARPROT}),
        .s_axi_arqos({1'b0,1'b0,1'b0,1'b0,s02_couplers_to_xbar_ARQOS,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_ARQOS}),
        .s_axi_arready({s02_couplers_to_xbar_ARREADY,NLW_xbar_s_axi_arready_UNCONNECTED[1],s00_couplers_to_xbar_ARREADY}),
        .s_axi_arsize({1'b0,1'b0,1'b0,s02_couplers_to_xbar_ARSIZE,1'b0,1'b0,1'b1,s00_couplers_to_xbar_ARSIZE}),
        .s_axi_arvalid({1'b0,s02_couplers_to_xbar_ARVALID,1'b0,s00_couplers_to_xbar_ARVALID}),
        .s_axi_awaddr({s03_couplers_to_xbar_AWADDR,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s01_couplers_to_xbar_AWADDR,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({s03_couplers_to_xbar_AWBURST,1'b0,1'b0,s01_couplers_to_xbar_AWBURST,1'b0,1'b1}),
        .s_axi_awcache({s03_couplers_to_xbar_AWCACHE,1'b0,1'b0,1'b0,1'b0,s01_couplers_to_xbar_AWCACHE,1'b0,1'b0,1'b1,1'b1}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({s03_couplers_to_xbar_AWLEN,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s01_couplers_to_xbar_AWLEN,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlock({s03_couplers_to_xbar_AWLOCK,1'b0,s01_couplers_to_xbar_AWLOCK,1'b0}),
        .s_axi_awprot({s03_couplers_to_xbar_AWPROT,1'b0,1'b0,1'b0,s01_couplers_to_xbar_AWPROT,1'b0,1'b0,1'b0}),
        .s_axi_awqos({s03_couplers_to_xbar_AWQOS,1'b0,1'b0,1'b0,1'b0,s01_couplers_to_xbar_AWQOS,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready({s03_couplers_to_xbar_AWREADY,NLW_xbar_s_axi_awready_UNCONNECTED[2],s01_couplers_to_xbar_AWREADY,NLW_xbar_s_axi_awready_UNCONNECTED[0]}),
        .s_axi_awsize({s03_couplers_to_xbar_AWSIZE,1'b0,1'b0,1'b0,s01_couplers_to_xbar_AWSIZE,1'b0,1'b1,1'b1}),
        .s_axi_awvalid({s03_couplers_to_xbar_AWVALID,1'b0,s01_couplers_to_xbar_AWVALID,1'b0}),
        .s_axi_bready({s03_couplers_to_xbar_BREADY,1'b0,s01_couplers_to_xbar_BREADY,1'b0}),
        .s_axi_bresp({s03_couplers_to_xbar_BRESP,NLW_xbar_s_axi_bresp_UNCONNECTED[5:4],s01_couplers_to_xbar_BRESP,NLW_xbar_s_axi_bresp_UNCONNECTED[1:0]}),
        .s_axi_bvalid({s03_couplers_to_xbar_BVALID,NLW_xbar_s_axi_bvalid_UNCONNECTED[2],s01_couplers_to_xbar_BVALID,NLW_xbar_s_axi_bvalid_UNCONNECTED[0]}),
        .s_axi_rdata({s02_couplers_to_xbar_RDATA,NLW_xbar_s_axi_rdata_UNCONNECTED[127:64],s00_couplers_to_xbar_RDATA}),
        .s_axi_rlast({s02_couplers_to_xbar_RLAST,NLW_xbar_s_axi_rlast_UNCONNECTED[1],s00_couplers_to_xbar_RLAST}),
        .s_axi_rready({1'b0,s02_couplers_to_xbar_RREADY,1'b0,s00_couplers_to_xbar_RREADY}),
        .s_axi_rresp({s02_couplers_to_xbar_RRESP,NLW_xbar_s_axi_rresp_UNCONNECTED[3:2],s00_couplers_to_xbar_RRESP}),
        .s_axi_rvalid({s02_couplers_to_xbar_RVALID,NLW_xbar_s_axi_rvalid_UNCONNECTED[1],s00_couplers_to_xbar_RVALID}),
        .s_axi_wdata({s03_couplers_to_xbar_WDATA,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,s01_couplers_to_xbar_WDATA,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast({s03_couplers_to_xbar_WLAST,1'b0,s01_couplers_to_xbar_WLAST,1'b0}),
        .s_axi_wready({s03_couplers_to_xbar_WREADY,NLW_xbar_s_axi_wready_UNCONNECTED[2],s01_couplers_to_xbar_WREADY,NLW_xbar_s_axi_wready_UNCONNECTED[0]}),
        .s_axi_wstrb({s03_couplers_to_xbar_WSTRB,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,s01_couplers_to_xbar_WSTRB,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .s_axi_wvalid({s03_couplers_to_xbar_WVALID,1'b0,s01_couplers_to_xbar_WVALID,1'b0}));
endmodule

module m00_couplers_imp_10KKZXR
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arid,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awid,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rid,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wid,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arregion,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awregion,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [1:0]M_AXI_arid;
  output [3:0]M_AXI_arlen;
  output [1:0]M_AXI_arlock;
  output [2:0]M_AXI_arprot;
  output [3:0]M_AXI_arqos;
  input M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [1:0]M_AXI_awid;
  output [3:0]M_AXI_awlen;
  output [1:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  input [5:0]M_AXI_bid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [63:0]M_AXI_rdata;
  input [5:0]M_AXI_rid;
  input M_AXI_rlast;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [63:0]M_AXI_wdata;
  output [1:0]M_AXI_wid;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [7:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [1:0]S_AXI_arid;
  input [7:0]S_AXI_arlen;
  input [0:0]S_AXI_arlock;
  input [2:0]S_AXI_arprot;
  input [3:0]S_AXI_arqos;
  output S_AXI_arready;
  input [3:0]S_AXI_arregion;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [1:0]S_AXI_awid;
  input [7:0]S_AXI_awlen;
  input [0:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [3:0]S_AXI_awregion;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  output [1:0]S_AXI_bid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [63:0]S_AXI_rdata;
  output [1:0]S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [63:0]S_AXI_wdata;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [7:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_pc_to_m00_couplers_ARADDR;
  wire [1:0]auto_pc_to_m00_couplers_ARBURST;
  wire [3:0]auto_pc_to_m00_couplers_ARCACHE;
  wire [1:0]auto_pc_to_m00_couplers_ARID;
  wire [3:0]auto_pc_to_m00_couplers_ARLEN;
  wire [1:0]auto_pc_to_m00_couplers_ARLOCK;
  wire [2:0]auto_pc_to_m00_couplers_ARPROT;
  wire [3:0]auto_pc_to_m00_couplers_ARQOS;
  wire auto_pc_to_m00_couplers_ARREADY;
  wire [2:0]auto_pc_to_m00_couplers_ARSIZE;
  wire auto_pc_to_m00_couplers_ARVALID;
  wire [31:0]auto_pc_to_m00_couplers_AWADDR;
  wire [1:0]auto_pc_to_m00_couplers_AWBURST;
  wire [3:0]auto_pc_to_m00_couplers_AWCACHE;
  wire [1:0]auto_pc_to_m00_couplers_AWID;
  wire [3:0]auto_pc_to_m00_couplers_AWLEN;
  wire [1:0]auto_pc_to_m00_couplers_AWLOCK;
  wire [2:0]auto_pc_to_m00_couplers_AWPROT;
  wire [3:0]auto_pc_to_m00_couplers_AWQOS;
  wire auto_pc_to_m00_couplers_AWREADY;
  wire [2:0]auto_pc_to_m00_couplers_AWSIZE;
  wire auto_pc_to_m00_couplers_AWVALID;
  wire [5:0]auto_pc_to_m00_couplers_BID;
  wire auto_pc_to_m00_couplers_BREADY;
  wire [1:0]auto_pc_to_m00_couplers_BRESP;
  wire auto_pc_to_m00_couplers_BVALID;
  wire [63:0]auto_pc_to_m00_couplers_RDATA;
  wire [5:0]auto_pc_to_m00_couplers_RID;
  wire auto_pc_to_m00_couplers_RLAST;
  wire auto_pc_to_m00_couplers_RREADY;
  wire [1:0]auto_pc_to_m00_couplers_RRESP;
  wire auto_pc_to_m00_couplers_RVALID;
  wire [63:0]auto_pc_to_m00_couplers_WDATA;
  wire [1:0]auto_pc_to_m00_couplers_WID;
  wire auto_pc_to_m00_couplers_WLAST;
  wire auto_pc_to_m00_couplers_WREADY;
  wire [7:0]auto_pc_to_m00_couplers_WSTRB;
  wire auto_pc_to_m00_couplers_WVALID;
  wire [31:0]m00_couplers_to_auto_pc_ARADDR;
  wire [1:0]m00_couplers_to_auto_pc_ARBURST;
  wire [3:0]m00_couplers_to_auto_pc_ARCACHE;
  wire [1:0]m00_couplers_to_auto_pc_ARID;
  wire [7:0]m00_couplers_to_auto_pc_ARLEN;
  wire [0:0]m00_couplers_to_auto_pc_ARLOCK;
  wire [2:0]m00_couplers_to_auto_pc_ARPROT;
  wire [3:0]m00_couplers_to_auto_pc_ARQOS;
  wire m00_couplers_to_auto_pc_ARREADY;
  wire [3:0]m00_couplers_to_auto_pc_ARREGION;
  wire [2:0]m00_couplers_to_auto_pc_ARSIZE;
  wire m00_couplers_to_auto_pc_ARVALID;
  wire [31:0]m00_couplers_to_auto_pc_AWADDR;
  wire [1:0]m00_couplers_to_auto_pc_AWBURST;
  wire [3:0]m00_couplers_to_auto_pc_AWCACHE;
  wire [1:0]m00_couplers_to_auto_pc_AWID;
  wire [7:0]m00_couplers_to_auto_pc_AWLEN;
  wire [0:0]m00_couplers_to_auto_pc_AWLOCK;
  wire [2:0]m00_couplers_to_auto_pc_AWPROT;
  wire [3:0]m00_couplers_to_auto_pc_AWQOS;
  wire m00_couplers_to_auto_pc_AWREADY;
  wire [3:0]m00_couplers_to_auto_pc_AWREGION;
  wire [2:0]m00_couplers_to_auto_pc_AWSIZE;
  wire m00_couplers_to_auto_pc_AWVALID;
  wire [1:0]m00_couplers_to_auto_pc_BID;
  wire m00_couplers_to_auto_pc_BREADY;
  wire [1:0]m00_couplers_to_auto_pc_BRESP;
  wire m00_couplers_to_auto_pc_BVALID;
  wire [63:0]m00_couplers_to_auto_pc_RDATA;
  wire [1:0]m00_couplers_to_auto_pc_RID;
  wire m00_couplers_to_auto_pc_RLAST;
  wire m00_couplers_to_auto_pc_RREADY;
  wire [1:0]m00_couplers_to_auto_pc_RRESP;
  wire m00_couplers_to_auto_pc_RVALID;
  wire [63:0]m00_couplers_to_auto_pc_WDATA;
  wire m00_couplers_to_auto_pc_WLAST;
  wire m00_couplers_to_auto_pc_WREADY;
  wire [7:0]m00_couplers_to_auto_pc_WSTRB;
  wire m00_couplers_to_auto_pc_WVALID;

  assign M_AXI_araddr[31:0] = auto_pc_to_m00_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = auto_pc_to_m00_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = auto_pc_to_m00_couplers_ARCACHE;
  assign M_AXI_arid[1:0] = auto_pc_to_m00_couplers_ARID;
  assign M_AXI_arlen[3:0] = auto_pc_to_m00_couplers_ARLEN;
  assign M_AXI_arlock[1:0] = auto_pc_to_m00_couplers_ARLOCK;
  assign M_AXI_arprot[2:0] = auto_pc_to_m00_couplers_ARPROT;
  assign M_AXI_arqos[3:0] = auto_pc_to_m00_couplers_ARQOS;
  assign M_AXI_arsize[2:0] = auto_pc_to_m00_couplers_ARSIZE;
  assign M_AXI_arvalid = auto_pc_to_m00_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = auto_pc_to_m00_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = auto_pc_to_m00_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = auto_pc_to_m00_couplers_AWCACHE;
  assign M_AXI_awid[1:0] = auto_pc_to_m00_couplers_AWID;
  assign M_AXI_awlen[3:0] = auto_pc_to_m00_couplers_AWLEN;
  assign M_AXI_awlock[1:0] = auto_pc_to_m00_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = auto_pc_to_m00_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = auto_pc_to_m00_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = auto_pc_to_m00_couplers_AWSIZE;
  assign M_AXI_awvalid = auto_pc_to_m00_couplers_AWVALID;
  assign M_AXI_bready = auto_pc_to_m00_couplers_BREADY;
  assign M_AXI_rready = auto_pc_to_m00_couplers_RREADY;
  assign M_AXI_wdata[63:0] = auto_pc_to_m00_couplers_WDATA;
  assign M_AXI_wid[1:0] = auto_pc_to_m00_couplers_WID;
  assign M_AXI_wlast = auto_pc_to_m00_couplers_WLAST;
  assign M_AXI_wstrb[7:0] = auto_pc_to_m00_couplers_WSTRB;
  assign M_AXI_wvalid = auto_pc_to_m00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m00_couplers_to_auto_pc_ARREADY;
  assign S_AXI_awready = m00_couplers_to_auto_pc_AWREADY;
  assign S_AXI_bid[1:0] = m00_couplers_to_auto_pc_BID;
  assign S_AXI_bresp[1:0] = m00_couplers_to_auto_pc_BRESP;
  assign S_AXI_bvalid = m00_couplers_to_auto_pc_BVALID;
  assign S_AXI_rdata[63:0] = m00_couplers_to_auto_pc_RDATA;
  assign S_AXI_rid[1:0] = m00_couplers_to_auto_pc_RID;
  assign S_AXI_rlast = m00_couplers_to_auto_pc_RLAST;
  assign S_AXI_rresp[1:0] = m00_couplers_to_auto_pc_RRESP;
  assign S_AXI_rvalid = m00_couplers_to_auto_pc_RVALID;
  assign S_AXI_wready = m00_couplers_to_auto_pc_WREADY;
  assign auto_pc_to_m00_couplers_ARREADY = M_AXI_arready;
  assign auto_pc_to_m00_couplers_AWREADY = M_AXI_awready;
  assign auto_pc_to_m00_couplers_BID = M_AXI_bid[5:0];
  assign auto_pc_to_m00_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_pc_to_m00_couplers_BVALID = M_AXI_bvalid;
  assign auto_pc_to_m00_couplers_RDATA = M_AXI_rdata[63:0];
  assign auto_pc_to_m00_couplers_RID = M_AXI_rid[5:0];
  assign auto_pc_to_m00_couplers_RLAST = M_AXI_rlast;
  assign auto_pc_to_m00_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_pc_to_m00_couplers_RVALID = M_AXI_rvalid;
  assign auto_pc_to_m00_couplers_WREADY = M_AXI_wready;
  assign m00_couplers_to_auto_pc_ARADDR = S_AXI_araddr[31:0];
  assign m00_couplers_to_auto_pc_ARBURST = S_AXI_arburst[1:0];
  assign m00_couplers_to_auto_pc_ARCACHE = S_AXI_arcache[3:0];
  assign m00_couplers_to_auto_pc_ARID = S_AXI_arid[1:0];
  assign m00_couplers_to_auto_pc_ARLEN = S_AXI_arlen[7:0];
  assign m00_couplers_to_auto_pc_ARLOCK = S_AXI_arlock[0];
  assign m00_couplers_to_auto_pc_ARPROT = S_AXI_arprot[2:0];
  assign m00_couplers_to_auto_pc_ARQOS = S_AXI_arqos[3:0];
  assign m00_couplers_to_auto_pc_ARREGION = S_AXI_arregion[3:0];
  assign m00_couplers_to_auto_pc_ARSIZE = S_AXI_arsize[2:0];
  assign m00_couplers_to_auto_pc_ARVALID = S_AXI_arvalid;
  assign m00_couplers_to_auto_pc_AWADDR = S_AXI_awaddr[31:0];
  assign m00_couplers_to_auto_pc_AWBURST = S_AXI_awburst[1:0];
  assign m00_couplers_to_auto_pc_AWCACHE = S_AXI_awcache[3:0];
  assign m00_couplers_to_auto_pc_AWID = S_AXI_awid[1:0];
  assign m00_couplers_to_auto_pc_AWLEN = S_AXI_awlen[7:0];
  assign m00_couplers_to_auto_pc_AWLOCK = S_AXI_awlock[0];
  assign m00_couplers_to_auto_pc_AWPROT = S_AXI_awprot[2:0];
  assign m00_couplers_to_auto_pc_AWQOS = S_AXI_awqos[3:0];
  assign m00_couplers_to_auto_pc_AWREGION = S_AXI_awregion[3:0];
  assign m00_couplers_to_auto_pc_AWSIZE = S_AXI_awsize[2:0];
  assign m00_couplers_to_auto_pc_AWVALID = S_AXI_awvalid;
  assign m00_couplers_to_auto_pc_BREADY = S_AXI_bready;
  assign m00_couplers_to_auto_pc_RREADY = S_AXI_rready;
  assign m00_couplers_to_auto_pc_WDATA = S_AXI_wdata[63:0];
  assign m00_couplers_to_auto_pc_WLAST = S_AXI_wlast;
  assign m00_couplers_to_auto_pc_WSTRB = S_AXI_wstrb[7:0];
  assign m00_couplers_to_auto_pc_WVALID = S_AXI_wvalid;
  av_system_auto_pc_2 auto_pc
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(auto_pc_to_m00_couplers_ARADDR),
        .m_axi_arburst(auto_pc_to_m00_couplers_ARBURST),
        .m_axi_arcache(auto_pc_to_m00_couplers_ARCACHE),
        .m_axi_arid(auto_pc_to_m00_couplers_ARID),
        .m_axi_arlen(auto_pc_to_m00_couplers_ARLEN),
        .m_axi_arlock(auto_pc_to_m00_couplers_ARLOCK),
        .m_axi_arprot(auto_pc_to_m00_couplers_ARPROT),
        .m_axi_arqos(auto_pc_to_m00_couplers_ARQOS),
        .m_axi_arready(auto_pc_to_m00_couplers_ARREADY),
        .m_axi_arsize(auto_pc_to_m00_couplers_ARSIZE),
        .m_axi_arvalid(auto_pc_to_m00_couplers_ARVALID),
        .m_axi_awaddr(auto_pc_to_m00_couplers_AWADDR),
        .m_axi_awburst(auto_pc_to_m00_couplers_AWBURST),
        .m_axi_awcache(auto_pc_to_m00_couplers_AWCACHE),
        .m_axi_awid(auto_pc_to_m00_couplers_AWID),
        .m_axi_awlen(auto_pc_to_m00_couplers_AWLEN),
        .m_axi_awlock(auto_pc_to_m00_couplers_AWLOCK),
        .m_axi_awprot(auto_pc_to_m00_couplers_AWPROT),
        .m_axi_awqos(auto_pc_to_m00_couplers_AWQOS),
        .m_axi_awready(auto_pc_to_m00_couplers_AWREADY),
        .m_axi_awsize(auto_pc_to_m00_couplers_AWSIZE),
        .m_axi_awvalid(auto_pc_to_m00_couplers_AWVALID),
        .m_axi_bid(auto_pc_to_m00_couplers_BID[1:0]),
        .m_axi_bready(auto_pc_to_m00_couplers_BREADY),
        .m_axi_bresp(auto_pc_to_m00_couplers_BRESP),
        .m_axi_bvalid(auto_pc_to_m00_couplers_BVALID),
        .m_axi_rdata(auto_pc_to_m00_couplers_RDATA),
        .m_axi_rid(auto_pc_to_m00_couplers_RID[1:0]),
        .m_axi_rlast(auto_pc_to_m00_couplers_RLAST),
        .m_axi_rready(auto_pc_to_m00_couplers_RREADY),
        .m_axi_rresp(auto_pc_to_m00_couplers_RRESP),
        .m_axi_rvalid(auto_pc_to_m00_couplers_RVALID),
        .m_axi_wdata(auto_pc_to_m00_couplers_WDATA),
        .m_axi_wid(auto_pc_to_m00_couplers_WID),
        .m_axi_wlast(auto_pc_to_m00_couplers_WLAST),
        .m_axi_wready(auto_pc_to_m00_couplers_WREADY),
        .m_axi_wstrb(auto_pc_to_m00_couplers_WSTRB),
        .m_axi_wvalid(auto_pc_to_m00_couplers_WVALID),
        .s_axi_araddr(m00_couplers_to_auto_pc_ARADDR),
        .s_axi_arburst(m00_couplers_to_auto_pc_ARBURST),
        .s_axi_arcache(m00_couplers_to_auto_pc_ARCACHE),
        .s_axi_arid(m00_couplers_to_auto_pc_ARID),
        .s_axi_arlen(m00_couplers_to_auto_pc_ARLEN),
        .s_axi_arlock(m00_couplers_to_auto_pc_ARLOCK),
        .s_axi_arprot(m00_couplers_to_auto_pc_ARPROT),
        .s_axi_arqos(m00_couplers_to_auto_pc_ARQOS),
        .s_axi_arready(m00_couplers_to_auto_pc_ARREADY),
        .s_axi_arregion(m00_couplers_to_auto_pc_ARREGION),
        .s_axi_arsize(m00_couplers_to_auto_pc_ARSIZE),
        .s_axi_arvalid(m00_couplers_to_auto_pc_ARVALID),
        .s_axi_awaddr(m00_couplers_to_auto_pc_AWADDR),
        .s_axi_awburst(m00_couplers_to_auto_pc_AWBURST),
        .s_axi_awcache(m00_couplers_to_auto_pc_AWCACHE),
        .s_axi_awid(m00_couplers_to_auto_pc_AWID),
        .s_axi_awlen(m00_couplers_to_auto_pc_AWLEN),
        .s_axi_awlock(m00_couplers_to_auto_pc_AWLOCK),
        .s_axi_awprot(m00_couplers_to_auto_pc_AWPROT),
        .s_axi_awqos(m00_couplers_to_auto_pc_AWQOS),
        .s_axi_awready(m00_couplers_to_auto_pc_AWREADY),
        .s_axi_awregion(m00_couplers_to_auto_pc_AWREGION),
        .s_axi_awsize(m00_couplers_to_auto_pc_AWSIZE),
        .s_axi_awvalid(m00_couplers_to_auto_pc_AWVALID),
        .s_axi_bid(m00_couplers_to_auto_pc_BID),
        .s_axi_bready(m00_couplers_to_auto_pc_BREADY),
        .s_axi_bresp(m00_couplers_to_auto_pc_BRESP),
        .s_axi_bvalid(m00_couplers_to_auto_pc_BVALID),
        .s_axi_rdata(m00_couplers_to_auto_pc_RDATA),
        .s_axi_rid(m00_couplers_to_auto_pc_RID),
        .s_axi_rlast(m00_couplers_to_auto_pc_RLAST),
        .s_axi_rready(m00_couplers_to_auto_pc_RREADY),
        .s_axi_rresp(m00_couplers_to_auto_pc_RRESP),
        .s_axi_rvalid(m00_couplers_to_auto_pc_RVALID),
        .s_axi_wdata(m00_couplers_to_auto_pc_WDATA),
        .s_axi_wlast(m00_couplers_to_auto_pc_WLAST),
        .s_axi_wready(m00_couplers_to_auto_pc_WREADY),
        .s_axi_wstrb(m00_couplers_to_auto_pc_WSTRB),
        .s_axi_wvalid(m00_couplers_to_auto_pc_WVALID));
endmodule

module m00_couplers_imp_1CBSJ84
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arid,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awid,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rid,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wid,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arregion,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awregion,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [0:0]M_AXI_arid;
  output [3:0]M_AXI_arlen;
  output [1:0]M_AXI_arlock;
  output [2:0]M_AXI_arprot;
  output [3:0]M_AXI_arqos;
  input M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [0:0]M_AXI_awid;
  output [3:0]M_AXI_awlen;
  output [1:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  input [5:0]M_AXI_bid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [63:0]M_AXI_rdata;
  input [5:0]M_AXI_rid;
  input M_AXI_rlast;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [63:0]M_AXI_wdata;
  output [0:0]M_AXI_wid;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [7:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [0:0]S_AXI_arid;
  input [7:0]S_AXI_arlen;
  input [0:0]S_AXI_arlock;
  input [2:0]S_AXI_arprot;
  input [3:0]S_AXI_arqos;
  output S_AXI_arready;
  input [3:0]S_AXI_arregion;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [0:0]S_AXI_awid;
  input [7:0]S_AXI_awlen;
  input [0:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [3:0]S_AXI_awregion;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  output [0:0]S_AXI_bid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [63:0]S_AXI_rdata;
  output [0:0]S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [63:0]S_AXI_wdata;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [7:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_pc_to_m00_couplers_ARADDR;
  wire [1:0]auto_pc_to_m00_couplers_ARBURST;
  wire [3:0]auto_pc_to_m00_couplers_ARCACHE;
  wire [0:0]auto_pc_to_m00_couplers_ARID;
  wire [3:0]auto_pc_to_m00_couplers_ARLEN;
  wire [1:0]auto_pc_to_m00_couplers_ARLOCK;
  wire [2:0]auto_pc_to_m00_couplers_ARPROT;
  wire [3:0]auto_pc_to_m00_couplers_ARQOS;
  wire auto_pc_to_m00_couplers_ARREADY;
  wire [2:0]auto_pc_to_m00_couplers_ARSIZE;
  wire auto_pc_to_m00_couplers_ARVALID;
  wire [31:0]auto_pc_to_m00_couplers_AWADDR;
  wire [1:0]auto_pc_to_m00_couplers_AWBURST;
  wire [3:0]auto_pc_to_m00_couplers_AWCACHE;
  wire [0:0]auto_pc_to_m00_couplers_AWID;
  wire [3:0]auto_pc_to_m00_couplers_AWLEN;
  wire [1:0]auto_pc_to_m00_couplers_AWLOCK;
  wire [2:0]auto_pc_to_m00_couplers_AWPROT;
  wire [3:0]auto_pc_to_m00_couplers_AWQOS;
  wire auto_pc_to_m00_couplers_AWREADY;
  wire [2:0]auto_pc_to_m00_couplers_AWSIZE;
  wire auto_pc_to_m00_couplers_AWVALID;
  wire [5:0]auto_pc_to_m00_couplers_BID;
  wire auto_pc_to_m00_couplers_BREADY;
  wire [1:0]auto_pc_to_m00_couplers_BRESP;
  wire auto_pc_to_m00_couplers_BVALID;
  wire [63:0]auto_pc_to_m00_couplers_RDATA;
  wire [5:0]auto_pc_to_m00_couplers_RID;
  wire auto_pc_to_m00_couplers_RLAST;
  wire auto_pc_to_m00_couplers_RREADY;
  wire [1:0]auto_pc_to_m00_couplers_RRESP;
  wire auto_pc_to_m00_couplers_RVALID;
  wire [63:0]auto_pc_to_m00_couplers_WDATA;
  wire [0:0]auto_pc_to_m00_couplers_WID;
  wire auto_pc_to_m00_couplers_WLAST;
  wire auto_pc_to_m00_couplers_WREADY;
  wire [7:0]auto_pc_to_m00_couplers_WSTRB;
  wire auto_pc_to_m00_couplers_WVALID;
  wire [31:0]m00_couplers_to_auto_pc_ARADDR;
  wire [1:0]m00_couplers_to_auto_pc_ARBURST;
  wire [3:0]m00_couplers_to_auto_pc_ARCACHE;
  wire [0:0]m00_couplers_to_auto_pc_ARID;
  wire [7:0]m00_couplers_to_auto_pc_ARLEN;
  wire [0:0]m00_couplers_to_auto_pc_ARLOCK;
  wire [2:0]m00_couplers_to_auto_pc_ARPROT;
  wire [3:0]m00_couplers_to_auto_pc_ARQOS;
  wire m00_couplers_to_auto_pc_ARREADY;
  wire [3:0]m00_couplers_to_auto_pc_ARREGION;
  wire [2:0]m00_couplers_to_auto_pc_ARSIZE;
  wire m00_couplers_to_auto_pc_ARVALID;
  wire [31:0]m00_couplers_to_auto_pc_AWADDR;
  wire [1:0]m00_couplers_to_auto_pc_AWBURST;
  wire [3:0]m00_couplers_to_auto_pc_AWCACHE;
  wire [0:0]m00_couplers_to_auto_pc_AWID;
  wire [7:0]m00_couplers_to_auto_pc_AWLEN;
  wire [0:0]m00_couplers_to_auto_pc_AWLOCK;
  wire [2:0]m00_couplers_to_auto_pc_AWPROT;
  wire [3:0]m00_couplers_to_auto_pc_AWQOS;
  wire m00_couplers_to_auto_pc_AWREADY;
  wire [3:0]m00_couplers_to_auto_pc_AWREGION;
  wire [2:0]m00_couplers_to_auto_pc_AWSIZE;
  wire m00_couplers_to_auto_pc_AWVALID;
  wire [0:0]m00_couplers_to_auto_pc_BID;
  wire m00_couplers_to_auto_pc_BREADY;
  wire [1:0]m00_couplers_to_auto_pc_BRESP;
  wire m00_couplers_to_auto_pc_BVALID;
  wire [63:0]m00_couplers_to_auto_pc_RDATA;
  wire [0:0]m00_couplers_to_auto_pc_RID;
  wire m00_couplers_to_auto_pc_RLAST;
  wire m00_couplers_to_auto_pc_RREADY;
  wire [1:0]m00_couplers_to_auto_pc_RRESP;
  wire m00_couplers_to_auto_pc_RVALID;
  wire [63:0]m00_couplers_to_auto_pc_WDATA;
  wire m00_couplers_to_auto_pc_WLAST;
  wire m00_couplers_to_auto_pc_WREADY;
  wire [7:0]m00_couplers_to_auto_pc_WSTRB;
  wire m00_couplers_to_auto_pc_WVALID;

  assign M_AXI_araddr[31:0] = auto_pc_to_m00_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = auto_pc_to_m00_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = auto_pc_to_m00_couplers_ARCACHE;
  assign M_AXI_arid[0] = auto_pc_to_m00_couplers_ARID;
  assign M_AXI_arlen[3:0] = auto_pc_to_m00_couplers_ARLEN;
  assign M_AXI_arlock[1:0] = auto_pc_to_m00_couplers_ARLOCK;
  assign M_AXI_arprot[2:0] = auto_pc_to_m00_couplers_ARPROT;
  assign M_AXI_arqos[3:0] = auto_pc_to_m00_couplers_ARQOS;
  assign M_AXI_arsize[2:0] = auto_pc_to_m00_couplers_ARSIZE;
  assign M_AXI_arvalid = auto_pc_to_m00_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = auto_pc_to_m00_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = auto_pc_to_m00_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = auto_pc_to_m00_couplers_AWCACHE;
  assign M_AXI_awid[0] = auto_pc_to_m00_couplers_AWID;
  assign M_AXI_awlen[3:0] = auto_pc_to_m00_couplers_AWLEN;
  assign M_AXI_awlock[1:0] = auto_pc_to_m00_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = auto_pc_to_m00_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = auto_pc_to_m00_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = auto_pc_to_m00_couplers_AWSIZE;
  assign M_AXI_awvalid = auto_pc_to_m00_couplers_AWVALID;
  assign M_AXI_bready = auto_pc_to_m00_couplers_BREADY;
  assign M_AXI_rready = auto_pc_to_m00_couplers_RREADY;
  assign M_AXI_wdata[63:0] = auto_pc_to_m00_couplers_WDATA;
  assign M_AXI_wid[0] = auto_pc_to_m00_couplers_WID;
  assign M_AXI_wlast = auto_pc_to_m00_couplers_WLAST;
  assign M_AXI_wstrb[7:0] = auto_pc_to_m00_couplers_WSTRB;
  assign M_AXI_wvalid = auto_pc_to_m00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m00_couplers_to_auto_pc_ARREADY;
  assign S_AXI_awready = m00_couplers_to_auto_pc_AWREADY;
  assign S_AXI_bid[0] = m00_couplers_to_auto_pc_BID;
  assign S_AXI_bresp[1:0] = m00_couplers_to_auto_pc_BRESP;
  assign S_AXI_bvalid = m00_couplers_to_auto_pc_BVALID;
  assign S_AXI_rdata[63:0] = m00_couplers_to_auto_pc_RDATA;
  assign S_AXI_rid[0] = m00_couplers_to_auto_pc_RID;
  assign S_AXI_rlast = m00_couplers_to_auto_pc_RLAST;
  assign S_AXI_rresp[1:0] = m00_couplers_to_auto_pc_RRESP;
  assign S_AXI_rvalid = m00_couplers_to_auto_pc_RVALID;
  assign S_AXI_wready = m00_couplers_to_auto_pc_WREADY;
  assign auto_pc_to_m00_couplers_ARREADY = M_AXI_arready;
  assign auto_pc_to_m00_couplers_AWREADY = M_AXI_awready;
  assign auto_pc_to_m00_couplers_BID = M_AXI_bid[5:0];
  assign auto_pc_to_m00_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_pc_to_m00_couplers_BVALID = M_AXI_bvalid;
  assign auto_pc_to_m00_couplers_RDATA = M_AXI_rdata[63:0];
  assign auto_pc_to_m00_couplers_RID = M_AXI_rid[5:0];
  assign auto_pc_to_m00_couplers_RLAST = M_AXI_rlast;
  assign auto_pc_to_m00_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_pc_to_m00_couplers_RVALID = M_AXI_rvalid;
  assign auto_pc_to_m00_couplers_WREADY = M_AXI_wready;
  assign m00_couplers_to_auto_pc_ARADDR = S_AXI_araddr[31:0];
  assign m00_couplers_to_auto_pc_ARBURST = S_AXI_arburst[1:0];
  assign m00_couplers_to_auto_pc_ARCACHE = S_AXI_arcache[3:0];
  assign m00_couplers_to_auto_pc_ARID = S_AXI_arid[0];
  assign m00_couplers_to_auto_pc_ARLEN = S_AXI_arlen[7:0];
  assign m00_couplers_to_auto_pc_ARLOCK = S_AXI_arlock[0];
  assign m00_couplers_to_auto_pc_ARPROT = S_AXI_arprot[2:0];
  assign m00_couplers_to_auto_pc_ARQOS = S_AXI_arqos[3:0];
  assign m00_couplers_to_auto_pc_ARREGION = S_AXI_arregion[3:0];
  assign m00_couplers_to_auto_pc_ARSIZE = S_AXI_arsize[2:0];
  assign m00_couplers_to_auto_pc_ARVALID = S_AXI_arvalid;
  assign m00_couplers_to_auto_pc_AWADDR = S_AXI_awaddr[31:0];
  assign m00_couplers_to_auto_pc_AWBURST = S_AXI_awburst[1:0];
  assign m00_couplers_to_auto_pc_AWCACHE = S_AXI_awcache[3:0];
  assign m00_couplers_to_auto_pc_AWID = S_AXI_awid[0];
  assign m00_couplers_to_auto_pc_AWLEN = S_AXI_awlen[7:0];
  assign m00_couplers_to_auto_pc_AWLOCK = S_AXI_awlock[0];
  assign m00_couplers_to_auto_pc_AWPROT = S_AXI_awprot[2:0];
  assign m00_couplers_to_auto_pc_AWQOS = S_AXI_awqos[3:0];
  assign m00_couplers_to_auto_pc_AWREGION = S_AXI_awregion[3:0];
  assign m00_couplers_to_auto_pc_AWSIZE = S_AXI_awsize[2:0];
  assign m00_couplers_to_auto_pc_AWVALID = S_AXI_awvalid;
  assign m00_couplers_to_auto_pc_BREADY = S_AXI_bready;
  assign m00_couplers_to_auto_pc_RREADY = S_AXI_rready;
  assign m00_couplers_to_auto_pc_WDATA = S_AXI_wdata[63:0];
  assign m00_couplers_to_auto_pc_WLAST = S_AXI_wlast;
  assign m00_couplers_to_auto_pc_WSTRB = S_AXI_wstrb[7:0];
  assign m00_couplers_to_auto_pc_WVALID = S_AXI_wvalid;
  av_system_auto_pc_1 auto_pc
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(auto_pc_to_m00_couplers_ARADDR),
        .m_axi_arburst(auto_pc_to_m00_couplers_ARBURST),
        .m_axi_arcache(auto_pc_to_m00_couplers_ARCACHE),
        .m_axi_arid(auto_pc_to_m00_couplers_ARID),
        .m_axi_arlen(auto_pc_to_m00_couplers_ARLEN),
        .m_axi_arlock(auto_pc_to_m00_couplers_ARLOCK),
        .m_axi_arprot(auto_pc_to_m00_couplers_ARPROT),
        .m_axi_arqos(auto_pc_to_m00_couplers_ARQOS),
        .m_axi_arready(auto_pc_to_m00_couplers_ARREADY),
        .m_axi_arsize(auto_pc_to_m00_couplers_ARSIZE),
        .m_axi_arvalid(auto_pc_to_m00_couplers_ARVALID),
        .m_axi_awaddr(auto_pc_to_m00_couplers_AWADDR),
        .m_axi_awburst(auto_pc_to_m00_couplers_AWBURST),
        .m_axi_awcache(auto_pc_to_m00_couplers_AWCACHE),
        .m_axi_awid(auto_pc_to_m00_couplers_AWID),
        .m_axi_awlen(auto_pc_to_m00_couplers_AWLEN),
        .m_axi_awlock(auto_pc_to_m00_couplers_AWLOCK),
        .m_axi_awprot(auto_pc_to_m00_couplers_AWPROT),
        .m_axi_awqos(auto_pc_to_m00_couplers_AWQOS),
        .m_axi_awready(auto_pc_to_m00_couplers_AWREADY),
        .m_axi_awsize(auto_pc_to_m00_couplers_AWSIZE),
        .m_axi_awvalid(auto_pc_to_m00_couplers_AWVALID),
        .m_axi_bid(auto_pc_to_m00_couplers_BID[0]),
        .m_axi_bready(auto_pc_to_m00_couplers_BREADY),
        .m_axi_bresp(auto_pc_to_m00_couplers_BRESP),
        .m_axi_bvalid(auto_pc_to_m00_couplers_BVALID),
        .m_axi_rdata(auto_pc_to_m00_couplers_RDATA),
        .m_axi_rid(auto_pc_to_m00_couplers_RID[0]),
        .m_axi_rlast(auto_pc_to_m00_couplers_RLAST),
        .m_axi_rready(auto_pc_to_m00_couplers_RREADY),
        .m_axi_rresp(auto_pc_to_m00_couplers_RRESP),
        .m_axi_rvalid(auto_pc_to_m00_couplers_RVALID),
        .m_axi_wdata(auto_pc_to_m00_couplers_WDATA),
        .m_axi_wid(auto_pc_to_m00_couplers_WID),
        .m_axi_wlast(auto_pc_to_m00_couplers_WLAST),
        .m_axi_wready(auto_pc_to_m00_couplers_WREADY),
        .m_axi_wstrb(auto_pc_to_m00_couplers_WSTRB),
        .m_axi_wvalid(auto_pc_to_m00_couplers_WVALID),
        .s_axi_araddr(m00_couplers_to_auto_pc_ARADDR),
        .s_axi_arburst(m00_couplers_to_auto_pc_ARBURST),
        .s_axi_arcache(m00_couplers_to_auto_pc_ARCACHE),
        .s_axi_arid(m00_couplers_to_auto_pc_ARID),
        .s_axi_arlen(m00_couplers_to_auto_pc_ARLEN),
        .s_axi_arlock(m00_couplers_to_auto_pc_ARLOCK),
        .s_axi_arprot(m00_couplers_to_auto_pc_ARPROT),
        .s_axi_arqos(m00_couplers_to_auto_pc_ARQOS),
        .s_axi_arready(m00_couplers_to_auto_pc_ARREADY),
        .s_axi_arregion(m00_couplers_to_auto_pc_ARREGION),
        .s_axi_arsize(m00_couplers_to_auto_pc_ARSIZE),
        .s_axi_arvalid(m00_couplers_to_auto_pc_ARVALID),
        .s_axi_awaddr(m00_couplers_to_auto_pc_AWADDR),
        .s_axi_awburst(m00_couplers_to_auto_pc_AWBURST),
        .s_axi_awcache(m00_couplers_to_auto_pc_AWCACHE),
        .s_axi_awid(m00_couplers_to_auto_pc_AWID),
        .s_axi_awlen(m00_couplers_to_auto_pc_AWLEN),
        .s_axi_awlock(m00_couplers_to_auto_pc_AWLOCK),
        .s_axi_awprot(m00_couplers_to_auto_pc_AWPROT),
        .s_axi_awqos(m00_couplers_to_auto_pc_AWQOS),
        .s_axi_awready(m00_couplers_to_auto_pc_AWREADY),
        .s_axi_awregion(m00_couplers_to_auto_pc_AWREGION),
        .s_axi_awsize(m00_couplers_to_auto_pc_AWSIZE),
        .s_axi_awvalid(m00_couplers_to_auto_pc_AWVALID),
        .s_axi_bid(m00_couplers_to_auto_pc_BID),
        .s_axi_bready(m00_couplers_to_auto_pc_BREADY),
        .s_axi_bresp(m00_couplers_to_auto_pc_BRESP),
        .s_axi_bvalid(m00_couplers_to_auto_pc_BVALID),
        .s_axi_rdata(m00_couplers_to_auto_pc_RDATA),
        .s_axi_rid(m00_couplers_to_auto_pc_RID),
        .s_axi_rlast(m00_couplers_to_auto_pc_RLAST),
        .s_axi_rready(m00_couplers_to_auto_pc_RREADY),
        .s_axi_rresp(m00_couplers_to_auto_pc_RRESP),
        .s_axi_rvalid(m00_couplers_to_auto_pc_RVALID),
        .s_axi_wdata(m00_couplers_to_auto_pc_WDATA),
        .s_axi_wlast(m00_couplers_to_auto_pc_WLAST),
        .s_axi_wready(m00_couplers_to_auto_pc_WREADY),
        .s_axi_wstrb(m00_couplers_to_auto_pc_WSTRB),
        .s_axi_wvalid(m00_couplers_to_auto_pc_WVALID));
endmodule

module m00_couplers_imp_2UGUCW
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arid,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awid,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rid,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wid,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arregion,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awregion,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [0:0]M_AXI_arid;
  output [3:0]M_AXI_arlen;
  output [1:0]M_AXI_arlock;
  output [2:0]M_AXI_arprot;
  output [3:0]M_AXI_arqos;
  input M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [0:0]M_AXI_awid;
  output [3:0]M_AXI_awlen;
  output [1:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  input [5:0]M_AXI_bid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [63:0]M_AXI_rdata;
  input [5:0]M_AXI_rid;
  input M_AXI_rlast;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [63:0]M_AXI_wdata;
  output [0:0]M_AXI_wid;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [7:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [0:0]S_AXI_arid;
  input [7:0]S_AXI_arlen;
  input [0:0]S_AXI_arlock;
  input [2:0]S_AXI_arprot;
  input [3:0]S_AXI_arqos;
  output S_AXI_arready;
  input [3:0]S_AXI_arregion;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [0:0]S_AXI_awid;
  input [7:0]S_AXI_awlen;
  input [0:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [3:0]S_AXI_awregion;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  output [0:0]S_AXI_bid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [63:0]S_AXI_rdata;
  output [0:0]S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [63:0]S_AXI_wdata;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [7:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_pc_to_m00_couplers_ARADDR;
  wire [1:0]auto_pc_to_m00_couplers_ARBURST;
  wire [3:0]auto_pc_to_m00_couplers_ARCACHE;
  wire [0:0]auto_pc_to_m00_couplers_ARID;
  wire [3:0]auto_pc_to_m00_couplers_ARLEN;
  wire [1:0]auto_pc_to_m00_couplers_ARLOCK;
  wire [2:0]auto_pc_to_m00_couplers_ARPROT;
  wire [3:0]auto_pc_to_m00_couplers_ARQOS;
  wire auto_pc_to_m00_couplers_ARREADY;
  wire [2:0]auto_pc_to_m00_couplers_ARSIZE;
  wire auto_pc_to_m00_couplers_ARVALID;
  wire [31:0]auto_pc_to_m00_couplers_AWADDR;
  wire [1:0]auto_pc_to_m00_couplers_AWBURST;
  wire [3:0]auto_pc_to_m00_couplers_AWCACHE;
  wire [0:0]auto_pc_to_m00_couplers_AWID;
  wire [3:0]auto_pc_to_m00_couplers_AWLEN;
  wire [1:0]auto_pc_to_m00_couplers_AWLOCK;
  wire [2:0]auto_pc_to_m00_couplers_AWPROT;
  wire [3:0]auto_pc_to_m00_couplers_AWQOS;
  wire auto_pc_to_m00_couplers_AWREADY;
  wire [2:0]auto_pc_to_m00_couplers_AWSIZE;
  wire auto_pc_to_m00_couplers_AWVALID;
  wire [5:0]auto_pc_to_m00_couplers_BID;
  wire auto_pc_to_m00_couplers_BREADY;
  wire [1:0]auto_pc_to_m00_couplers_BRESP;
  wire auto_pc_to_m00_couplers_BVALID;
  wire [63:0]auto_pc_to_m00_couplers_RDATA;
  wire [5:0]auto_pc_to_m00_couplers_RID;
  wire auto_pc_to_m00_couplers_RLAST;
  wire auto_pc_to_m00_couplers_RREADY;
  wire [1:0]auto_pc_to_m00_couplers_RRESP;
  wire auto_pc_to_m00_couplers_RVALID;
  wire [63:0]auto_pc_to_m00_couplers_WDATA;
  wire [0:0]auto_pc_to_m00_couplers_WID;
  wire auto_pc_to_m00_couplers_WLAST;
  wire auto_pc_to_m00_couplers_WREADY;
  wire [7:0]auto_pc_to_m00_couplers_WSTRB;
  wire auto_pc_to_m00_couplers_WVALID;
  wire [31:0]m00_couplers_to_auto_pc_ARADDR;
  wire [1:0]m00_couplers_to_auto_pc_ARBURST;
  wire [3:0]m00_couplers_to_auto_pc_ARCACHE;
  wire [0:0]m00_couplers_to_auto_pc_ARID;
  wire [7:0]m00_couplers_to_auto_pc_ARLEN;
  wire [0:0]m00_couplers_to_auto_pc_ARLOCK;
  wire [2:0]m00_couplers_to_auto_pc_ARPROT;
  wire [3:0]m00_couplers_to_auto_pc_ARQOS;
  wire m00_couplers_to_auto_pc_ARREADY;
  wire [3:0]m00_couplers_to_auto_pc_ARREGION;
  wire [2:0]m00_couplers_to_auto_pc_ARSIZE;
  wire m00_couplers_to_auto_pc_ARVALID;
  wire [31:0]m00_couplers_to_auto_pc_AWADDR;
  wire [1:0]m00_couplers_to_auto_pc_AWBURST;
  wire [3:0]m00_couplers_to_auto_pc_AWCACHE;
  wire [0:0]m00_couplers_to_auto_pc_AWID;
  wire [7:0]m00_couplers_to_auto_pc_AWLEN;
  wire [0:0]m00_couplers_to_auto_pc_AWLOCK;
  wire [2:0]m00_couplers_to_auto_pc_AWPROT;
  wire [3:0]m00_couplers_to_auto_pc_AWQOS;
  wire m00_couplers_to_auto_pc_AWREADY;
  wire [3:0]m00_couplers_to_auto_pc_AWREGION;
  wire [2:0]m00_couplers_to_auto_pc_AWSIZE;
  wire m00_couplers_to_auto_pc_AWVALID;
  wire [0:0]m00_couplers_to_auto_pc_BID;
  wire m00_couplers_to_auto_pc_BREADY;
  wire [1:0]m00_couplers_to_auto_pc_BRESP;
  wire m00_couplers_to_auto_pc_BVALID;
  wire [63:0]m00_couplers_to_auto_pc_RDATA;
  wire [0:0]m00_couplers_to_auto_pc_RID;
  wire m00_couplers_to_auto_pc_RLAST;
  wire m00_couplers_to_auto_pc_RREADY;
  wire [1:0]m00_couplers_to_auto_pc_RRESP;
  wire m00_couplers_to_auto_pc_RVALID;
  wire [63:0]m00_couplers_to_auto_pc_WDATA;
  wire m00_couplers_to_auto_pc_WLAST;
  wire m00_couplers_to_auto_pc_WREADY;
  wire [7:0]m00_couplers_to_auto_pc_WSTRB;
  wire m00_couplers_to_auto_pc_WVALID;

  assign M_AXI_araddr[31:0] = auto_pc_to_m00_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = auto_pc_to_m00_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = auto_pc_to_m00_couplers_ARCACHE;
  assign M_AXI_arid[0] = auto_pc_to_m00_couplers_ARID;
  assign M_AXI_arlen[3:0] = auto_pc_to_m00_couplers_ARLEN;
  assign M_AXI_arlock[1:0] = auto_pc_to_m00_couplers_ARLOCK;
  assign M_AXI_arprot[2:0] = auto_pc_to_m00_couplers_ARPROT;
  assign M_AXI_arqos[3:0] = auto_pc_to_m00_couplers_ARQOS;
  assign M_AXI_arsize[2:0] = auto_pc_to_m00_couplers_ARSIZE;
  assign M_AXI_arvalid = auto_pc_to_m00_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = auto_pc_to_m00_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = auto_pc_to_m00_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = auto_pc_to_m00_couplers_AWCACHE;
  assign M_AXI_awid[0] = auto_pc_to_m00_couplers_AWID;
  assign M_AXI_awlen[3:0] = auto_pc_to_m00_couplers_AWLEN;
  assign M_AXI_awlock[1:0] = auto_pc_to_m00_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = auto_pc_to_m00_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = auto_pc_to_m00_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = auto_pc_to_m00_couplers_AWSIZE;
  assign M_AXI_awvalid = auto_pc_to_m00_couplers_AWVALID;
  assign M_AXI_bready = auto_pc_to_m00_couplers_BREADY;
  assign M_AXI_rready = auto_pc_to_m00_couplers_RREADY;
  assign M_AXI_wdata[63:0] = auto_pc_to_m00_couplers_WDATA;
  assign M_AXI_wid[0] = auto_pc_to_m00_couplers_WID;
  assign M_AXI_wlast = auto_pc_to_m00_couplers_WLAST;
  assign M_AXI_wstrb[7:0] = auto_pc_to_m00_couplers_WSTRB;
  assign M_AXI_wvalid = auto_pc_to_m00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m00_couplers_to_auto_pc_ARREADY;
  assign S_AXI_awready = m00_couplers_to_auto_pc_AWREADY;
  assign S_AXI_bid[0] = m00_couplers_to_auto_pc_BID;
  assign S_AXI_bresp[1:0] = m00_couplers_to_auto_pc_BRESP;
  assign S_AXI_bvalid = m00_couplers_to_auto_pc_BVALID;
  assign S_AXI_rdata[63:0] = m00_couplers_to_auto_pc_RDATA;
  assign S_AXI_rid[0] = m00_couplers_to_auto_pc_RID;
  assign S_AXI_rlast = m00_couplers_to_auto_pc_RLAST;
  assign S_AXI_rresp[1:0] = m00_couplers_to_auto_pc_RRESP;
  assign S_AXI_rvalid = m00_couplers_to_auto_pc_RVALID;
  assign S_AXI_wready = m00_couplers_to_auto_pc_WREADY;
  assign auto_pc_to_m00_couplers_ARREADY = M_AXI_arready;
  assign auto_pc_to_m00_couplers_AWREADY = M_AXI_awready;
  assign auto_pc_to_m00_couplers_BID = M_AXI_bid[5:0];
  assign auto_pc_to_m00_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_pc_to_m00_couplers_BVALID = M_AXI_bvalid;
  assign auto_pc_to_m00_couplers_RDATA = M_AXI_rdata[63:0];
  assign auto_pc_to_m00_couplers_RID = M_AXI_rid[5:0];
  assign auto_pc_to_m00_couplers_RLAST = M_AXI_rlast;
  assign auto_pc_to_m00_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_pc_to_m00_couplers_RVALID = M_AXI_rvalid;
  assign auto_pc_to_m00_couplers_WREADY = M_AXI_wready;
  assign m00_couplers_to_auto_pc_ARADDR = S_AXI_araddr[31:0];
  assign m00_couplers_to_auto_pc_ARBURST = S_AXI_arburst[1:0];
  assign m00_couplers_to_auto_pc_ARCACHE = S_AXI_arcache[3:0];
  assign m00_couplers_to_auto_pc_ARID = S_AXI_arid[0];
  assign m00_couplers_to_auto_pc_ARLEN = S_AXI_arlen[7:0];
  assign m00_couplers_to_auto_pc_ARLOCK = S_AXI_arlock[0];
  assign m00_couplers_to_auto_pc_ARPROT = S_AXI_arprot[2:0];
  assign m00_couplers_to_auto_pc_ARQOS = S_AXI_arqos[3:0];
  assign m00_couplers_to_auto_pc_ARREGION = S_AXI_arregion[3:0];
  assign m00_couplers_to_auto_pc_ARSIZE = S_AXI_arsize[2:0];
  assign m00_couplers_to_auto_pc_ARVALID = S_AXI_arvalid;
  assign m00_couplers_to_auto_pc_AWADDR = S_AXI_awaddr[31:0];
  assign m00_couplers_to_auto_pc_AWBURST = S_AXI_awburst[1:0];
  assign m00_couplers_to_auto_pc_AWCACHE = S_AXI_awcache[3:0];
  assign m00_couplers_to_auto_pc_AWID = S_AXI_awid[0];
  assign m00_couplers_to_auto_pc_AWLEN = S_AXI_awlen[7:0];
  assign m00_couplers_to_auto_pc_AWLOCK = S_AXI_awlock[0];
  assign m00_couplers_to_auto_pc_AWPROT = S_AXI_awprot[2:0];
  assign m00_couplers_to_auto_pc_AWQOS = S_AXI_awqos[3:0];
  assign m00_couplers_to_auto_pc_AWREGION = S_AXI_awregion[3:0];
  assign m00_couplers_to_auto_pc_AWSIZE = S_AXI_awsize[2:0];
  assign m00_couplers_to_auto_pc_AWVALID = S_AXI_awvalid;
  assign m00_couplers_to_auto_pc_BREADY = S_AXI_bready;
  assign m00_couplers_to_auto_pc_RREADY = S_AXI_rready;
  assign m00_couplers_to_auto_pc_WDATA = S_AXI_wdata[63:0];
  assign m00_couplers_to_auto_pc_WLAST = S_AXI_wlast;
  assign m00_couplers_to_auto_pc_WSTRB = S_AXI_wstrb[7:0];
  assign m00_couplers_to_auto_pc_WVALID = S_AXI_wvalid;
  av_system_auto_pc_3 auto_pc
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(auto_pc_to_m00_couplers_ARADDR),
        .m_axi_arburst(auto_pc_to_m00_couplers_ARBURST),
        .m_axi_arcache(auto_pc_to_m00_couplers_ARCACHE),
        .m_axi_arid(auto_pc_to_m00_couplers_ARID),
        .m_axi_arlen(auto_pc_to_m00_couplers_ARLEN),
        .m_axi_arlock(auto_pc_to_m00_couplers_ARLOCK),
        .m_axi_arprot(auto_pc_to_m00_couplers_ARPROT),
        .m_axi_arqos(auto_pc_to_m00_couplers_ARQOS),
        .m_axi_arready(auto_pc_to_m00_couplers_ARREADY),
        .m_axi_arsize(auto_pc_to_m00_couplers_ARSIZE),
        .m_axi_arvalid(auto_pc_to_m00_couplers_ARVALID),
        .m_axi_awaddr(auto_pc_to_m00_couplers_AWADDR),
        .m_axi_awburst(auto_pc_to_m00_couplers_AWBURST),
        .m_axi_awcache(auto_pc_to_m00_couplers_AWCACHE),
        .m_axi_awid(auto_pc_to_m00_couplers_AWID),
        .m_axi_awlen(auto_pc_to_m00_couplers_AWLEN),
        .m_axi_awlock(auto_pc_to_m00_couplers_AWLOCK),
        .m_axi_awprot(auto_pc_to_m00_couplers_AWPROT),
        .m_axi_awqos(auto_pc_to_m00_couplers_AWQOS),
        .m_axi_awready(auto_pc_to_m00_couplers_AWREADY),
        .m_axi_awsize(auto_pc_to_m00_couplers_AWSIZE),
        .m_axi_awvalid(auto_pc_to_m00_couplers_AWVALID),
        .m_axi_bid(auto_pc_to_m00_couplers_BID[0]),
        .m_axi_bready(auto_pc_to_m00_couplers_BREADY),
        .m_axi_bresp(auto_pc_to_m00_couplers_BRESP),
        .m_axi_bvalid(auto_pc_to_m00_couplers_BVALID),
        .m_axi_rdata(auto_pc_to_m00_couplers_RDATA),
        .m_axi_rid(auto_pc_to_m00_couplers_RID[0]),
        .m_axi_rlast(auto_pc_to_m00_couplers_RLAST),
        .m_axi_rready(auto_pc_to_m00_couplers_RREADY),
        .m_axi_rresp(auto_pc_to_m00_couplers_RRESP),
        .m_axi_rvalid(auto_pc_to_m00_couplers_RVALID),
        .m_axi_wdata(auto_pc_to_m00_couplers_WDATA),
        .m_axi_wid(auto_pc_to_m00_couplers_WID),
        .m_axi_wlast(auto_pc_to_m00_couplers_WLAST),
        .m_axi_wready(auto_pc_to_m00_couplers_WREADY),
        .m_axi_wstrb(auto_pc_to_m00_couplers_WSTRB),
        .m_axi_wvalid(auto_pc_to_m00_couplers_WVALID),
        .s_axi_araddr(m00_couplers_to_auto_pc_ARADDR),
        .s_axi_arburst(m00_couplers_to_auto_pc_ARBURST),
        .s_axi_arcache(m00_couplers_to_auto_pc_ARCACHE),
        .s_axi_arid(m00_couplers_to_auto_pc_ARID),
        .s_axi_arlen(m00_couplers_to_auto_pc_ARLEN),
        .s_axi_arlock(m00_couplers_to_auto_pc_ARLOCK),
        .s_axi_arprot(m00_couplers_to_auto_pc_ARPROT),
        .s_axi_arqos(m00_couplers_to_auto_pc_ARQOS),
        .s_axi_arready(m00_couplers_to_auto_pc_ARREADY),
        .s_axi_arregion(m00_couplers_to_auto_pc_ARREGION),
        .s_axi_arsize(m00_couplers_to_auto_pc_ARSIZE),
        .s_axi_arvalid(m00_couplers_to_auto_pc_ARVALID),
        .s_axi_awaddr(m00_couplers_to_auto_pc_AWADDR),
        .s_axi_awburst(m00_couplers_to_auto_pc_AWBURST),
        .s_axi_awcache(m00_couplers_to_auto_pc_AWCACHE),
        .s_axi_awid(m00_couplers_to_auto_pc_AWID),
        .s_axi_awlen(m00_couplers_to_auto_pc_AWLEN),
        .s_axi_awlock(m00_couplers_to_auto_pc_AWLOCK),
        .s_axi_awprot(m00_couplers_to_auto_pc_AWPROT),
        .s_axi_awqos(m00_couplers_to_auto_pc_AWQOS),
        .s_axi_awready(m00_couplers_to_auto_pc_AWREADY),
        .s_axi_awregion(m00_couplers_to_auto_pc_AWREGION),
        .s_axi_awsize(m00_couplers_to_auto_pc_AWSIZE),
        .s_axi_awvalid(m00_couplers_to_auto_pc_AWVALID),
        .s_axi_bid(m00_couplers_to_auto_pc_BID),
        .s_axi_bready(m00_couplers_to_auto_pc_BREADY),
        .s_axi_bresp(m00_couplers_to_auto_pc_BRESP),
        .s_axi_bvalid(m00_couplers_to_auto_pc_BVALID),
        .s_axi_rdata(m00_couplers_to_auto_pc_RDATA),
        .s_axi_rid(m00_couplers_to_auto_pc_RID),
        .s_axi_rlast(m00_couplers_to_auto_pc_RLAST),
        .s_axi_rready(m00_couplers_to_auto_pc_RREADY),
        .s_axi_rresp(m00_couplers_to_auto_pc_RRESP),
        .s_axi_rvalid(m00_couplers_to_auto_pc_RVALID),
        .s_axi_wdata(m00_couplers_to_auto_pc_WDATA),
        .s_axi_wlast(m00_couplers_to_auto_pc_WLAST),
        .s_axi_wready(m00_couplers_to_auto_pc_WREADY),
        .s_axi_wstrb(m00_couplers_to_auto_pc_WSTRB),
        .s_axi_wvalid(m00_couplers_to_auto_pc_WVALID));
endmodule

module m00_couplers_imp_5K4V01
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input [0:0]M_AXI_arready;
  output [0:0]M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input [0:0]M_AXI_awready;
  output [0:0]M_AXI_awvalid;
  output [0:0]M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input [0:0]M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output [0:0]M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input [0:0]M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input [0:0]M_AXI_wready;
  output [0:0]M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output [0:0]S_AXI_arready;
  input [0:0]S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output [0:0]S_AXI_awready;
  input [0:0]S_AXI_awvalid;
  input [0:0]S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output [0:0]S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input [0:0]S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output [0:0]S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output [0:0]S_AXI_wready;
  input [0:0]S_AXI_wvalid;

  wire [31:0]m00_couplers_to_m00_couplers_ARADDR;
  wire [0:0]m00_couplers_to_m00_couplers_ARREADY;
  wire [0:0]m00_couplers_to_m00_couplers_ARVALID;
  wire [31:0]m00_couplers_to_m00_couplers_AWADDR;
  wire [0:0]m00_couplers_to_m00_couplers_AWREADY;
  wire [0:0]m00_couplers_to_m00_couplers_AWVALID;
  wire [0:0]m00_couplers_to_m00_couplers_BREADY;
  wire [1:0]m00_couplers_to_m00_couplers_BRESP;
  wire [0:0]m00_couplers_to_m00_couplers_BVALID;
  wire [31:0]m00_couplers_to_m00_couplers_RDATA;
  wire [0:0]m00_couplers_to_m00_couplers_RREADY;
  wire [1:0]m00_couplers_to_m00_couplers_RRESP;
  wire [0:0]m00_couplers_to_m00_couplers_RVALID;
  wire [31:0]m00_couplers_to_m00_couplers_WDATA;
  wire [0:0]m00_couplers_to_m00_couplers_WREADY;
  wire [0:0]m00_couplers_to_m00_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m00_couplers_to_m00_couplers_ARADDR;
  assign M_AXI_arvalid[0] = m00_couplers_to_m00_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m00_couplers_to_m00_couplers_AWADDR;
  assign M_AXI_awvalid[0] = m00_couplers_to_m00_couplers_AWVALID;
  assign M_AXI_bready[0] = m00_couplers_to_m00_couplers_BREADY;
  assign M_AXI_rready[0] = m00_couplers_to_m00_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m00_couplers_to_m00_couplers_WDATA;
  assign M_AXI_wvalid[0] = m00_couplers_to_m00_couplers_WVALID;
  assign S_AXI_arready[0] = m00_couplers_to_m00_couplers_ARREADY;
  assign S_AXI_awready[0] = m00_couplers_to_m00_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m00_couplers_to_m00_couplers_BRESP;
  assign S_AXI_bvalid[0] = m00_couplers_to_m00_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m00_couplers_to_m00_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m00_couplers_to_m00_couplers_RRESP;
  assign S_AXI_rvalid[0] = m00_couplers_to_m00_couplers_RVALID;
  assign S_AXI_wready[0] = m00_couplers_to_m00_couplers_WREADY;
  assign m00_couplers_to_m00_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m00_couplers_to_m00_couplers_ARREADY = M_AXI_arready[0];
  assign m00_couplers_to_m00_couplers_ARVALID = S_AXI_arvalid[0];
  assign m00_couplers_to_m00_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m00_couplers_to_m00_couplers_AWREADY = M_AXI_awready[0];
  assign m00_couplers_to_m00_couplers_AWVALID = S_AXI_awvalid[0];
  assign m00_couplers_to_m00_couplers_BREADY = S_AXI_bready[0];
  assign m00_couplers_to_m00_couplers_BRESP = M_AXI_bresp[1:0];
  assign m00_couplers_to_m00_couplers_BVALID = M_AXI_bvalid[0];
  assign m00_couplers_to_m00_couplers_RDATA = M_AXI_rdata[31:0];
  assign m00_couplers_to_m00_couplers_RREADY = S_AXI_rready[0];
  assign m00_couplers_to_m00_couplers_RRESP = M_AXI_rresp[1:0];
  assign m00_couplers_to_m00_couplers_RVALID = M_AXI_rvalid[0];
  assign m00_couplers_to_m00_couplers_WDATA = S_AXI_wdata[31:0];
  assign m00_couplers_to_m00_couplers_WREADY = M_AXI_wready[0];
  assign m00_couplers_to_m00_couplers_WVALID = S_AXI_wvalid[0];
endmodule

module m01_couplers_imp_1ICZYJT
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input [0:0]M_AXI_arready;
  output [0:0]M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input [0:0]M_AXI_awready;
  output [0:0]M_AXI_awvalid;
  output [0:0]M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input [0:0]M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output [0:0]M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input [0:0]M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input [0:0]M_AXI_wready;
  output [0:0]M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output [0:0]S_AXI_arready;
  input [0:0]S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output [0:0]S_AXI_awready;
  input [0:0]S_AXI_awvalid;
  input [0:0]S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output [0:0]S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input [0:0]S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output [0:0]S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output [0:0]S_AXI_wready;
  input [0:0]S_AXI_wvalid;

  wire [31:0]m01_couplers_to_m01_couplers_ARADDR;
  wire [0:0]m01_couplers_to_m01_couplers_ARREADY;
  wire [0:0]m01_couplers_to_m01_couplers_ARVALID;
  wire [31:0]m01_couplers_to_m01_couplers_AWADDR;
  wire [0:0]m01_couplers_to_m01_couplers_AWREADY;
  wire [0:0]m01_couplers_to_m01_couplers_AWVALID;
  wire [0:0]m01_couplers_to_m01_couplers_BREADY;
  wire [1:0]m01_couplers_to_m01_couplers_BRESP;
  wire [0:0]m01_couplers_to_m01_couplers_BVALID;
  wire [31:0]m01_couplers_to_m01_couplers_RDATA;
  wire [0:0]m01_couplers_to_m01_couplers_RREADY;
  wire [1:0]m01_couplers_to_m01_couplers_RRESP;
  wire [0:0]m01_couplers_to_m01_couplers_RVALID;
  wire [31:0]m01_couplers_to_m01_couplers_WDATA;
  wire [0:0]m01_couplers_to_m01_couplers_WREADY;
  wire [0:0]m01_couplers_to_m01_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m01_couplers_to_m01_couplers_ARADDR;
  assign M_AXI_arvalid[0] = m01_couplers_to_m01_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m01_couplers_to_m01_couplers_AWADDR;
  assign M_AXI_awvalid[0] = m01_couplers_to_m01_couplers_AWVALID;
  assign M_AXI_bready[0] = m01_couplers_to_m01_couplers_BREADY;
  assign M_AXI_rready[0] = m01_couplers_to_m01_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m01_couplers_to_m01_couplers_WDATA;
  assign M_AXI_wvalid[0] = m01_couplers_to_m01_couplers_WVALID;
  assign S_AXI_arready[0] = m01_couplers_to_m01_couplers_ARREADY;
  assign S_AXI_awready[0] = m01_couplers_to_m01_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m01_couplers_to_m01_couplers_BRESP;
  assign S_AXI_bvalid[0] = m01_couplers_to_m01_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m01_couplers_to_m01_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m01_couplers_to_m01_couplers_RRESP;
  assign S_AXI_rvalid[0] = m01_couplers_to_m01_couplers_RVALID;
  assign S_AXI_wready[0] = m01_couplers_to_m01_couplers_WREADY;
  assign m01_couplers_to_m01_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m01_couplers_to_m01_couplers_ARREADY = M_AXI_arready[0];
  assign m01_couplers_to_m01_couplers_ARVALID = S_AXI_arvalid[0];
  assign m01_couplers_to_m01_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m01_couplers_to_m01_couplers_AWREADY = M_AXI_awready[0];
  assign m01_couplers_to_m01_couplers_AWVALID = S_AXI_awvalid[0];
  assign m01_couplers_to_m01_couplers_BREADY = S_AXI_bready[0];
  assign m01_couplers_to_m01_couplers_BRESP = M_AXI_bresp[1:0];
  assign m01_couplers_to_m01_couplers_BVALID = M_AXI_bvalid[0];
  assign m01_couplers_to_m01_couplers_RDATA = M_AXI_rdata[31:0];
  assign m01_couplers_to_m01_couplers_RREADY = S_AXI_rready[0];
  assign m01_couplers_to_m01_couplers_RRESP = M_AXI_rresp[1:0];
  assign m01_couplers_to_m01_couplers_RVALID = M_AXI_rvalid[0];
  assign m01_couplers_to_m01_couplers_WDATA = S_AXI_wdata[31:0];
  assign m01_couplers_to_m01_couplers_WREADY = M_AXI_wready[0];
  assign m01_couplers_to_m01_couplers_WVALID = S_AXI_wvalid[0];
endmodule

module m02_couplers_imp_QUATQ8
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire [31:0]m02_couplers_to_m02_couplers_ARADDR;
  wire m02_couplers_to_m02_couplers_ARREADY;
  wire m02_couplers_to_m02_couplers_ARVALID;
  wire [31:0]m02_couplers_to_m02_couplers_AWADDR;
  wire m02_couplers_to_m02_couplers_AWREADY;
  wire m02_couplers_to_m02_couplers_AWVALID;
  wire m02_couplers_to_m02_couplers_BREADY;
  wire [1:0]m02_couplers_to_m02_couplers_BRESP;
  wire m02_couplers_to_m02_couplers_BVALID;
  wire [31:0]m02_couplers_to_m02_couplers_RDATA;
  wire m02_couplers_to_m02_couplers_RREADY;
  wire [1:0]m02_couplers_to_m02_couplers_RRESP;
  wire m02_couplers_to_m02_couplers_RVALID;
  wire [31:0]m02_couplers_to_m02_couplers_WDATA;
  wire m02_couplers_to_m02_couplers_WREADY;
  wire [3:0]m02_couplers_to_m02_couplers_WSTRB;
  wire m02_couplers_to_m02_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m02_couplers_to_m02_couplers_ARADDR;
  assign M_AXI_arvalid = m02_couplers_to_m02_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m02_couplers_to_m02_couplers_AWADDR;
  assign M_AXI_awvalid = m02_couplers_to_m02_couplers_AWVALID;
  assign M_AXI_bready = m02_couplers_to_m02_couplers_BREADY;
  assign M_AXI_rready = m02_couplers_to_m02_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m02_couplers_to_m02_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = m02_couplers_to_m02_couplers_WSTRB;
  assign M_AXI_wvalid = m02_couplers_to_m02_couplers_WVALID;
  assign S_AXI_arready = m02_couplers_to_m02_couplers_ARREADY;
  assign S_AXI_awready = m02_couplers_to_m02_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m02_couplers_to_m02_couplers_BRESP;
  assign S_AXI_bvalid = m02_couplers_to_m02_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m02_couplers_to_m02_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m02_couplers_to_m02_couplers_RRESP;
  assign S_AXI_rvalid = m02_couplers_to_m02_couplers_RVALID;
  assign S_AXI_wready = m02_couplers_to_m02_couplers_WREADY;
  assign m02_couplers_to_m02_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m02_couplers_to_m02_couplers_ARREADY = M_AXI_arready;
  assign m02_couplers_to_m02_couplers_ARVALID = S_AXI_arvalid;
  assign m02_couplers_to_m02_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m02_couplers_to_m02_couplers_AWREADY = M_AXI_awready;
  assign m02_couplers_to_m02_couplers_AWVALID = S_AXI_awvalid;
  assign m02_couplers_to_m02_couplers_BREADY = S_AXI_bready;
  assign m02_couplers_to_m02_couplers_BRESP = M_AXI_bresp[1:0];
  assign m02_couplers_to_m02_couplers_BVALID = M_AXI_bvalid;
  assign m02_couplers_to_m02_couplers_RDATA = M_AXI_rdata[31:0];
  assign m02_couplers_to_m02_couplers_RREADY = S_AXI_rready;
  assign m02_couplers_to_m02_couplers_RRESP = M_AXI_rresp[1:0];
  assign m02_couplers_to_m02_couplers_RVALID = M_AXI_rvalid;
  assign m02_couplers_to_m02_couplers_WDATA = S_AXI_wdata[31:0];
  assign m02_couplers_to_m02_couplers_WREADY = M_AXI_wready;
  assign m02_couplers_to_m02_couplers_WSTRB = S_AXI_wstrb[3:0];
  assign m02_couplers_to_m02_couplers_WVALID = S_AXI_wvalid;
endmodule

module m03_couplers_imp_1EVO5ZS
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire [31:0]m03_couplers_to_m03_couplers_ARADDR;
  wire [2:0]m03_couplers_to_m03_couplers_ARPROT;
  wire m03_couplers_to_m03_couplers_ARREADY;
  wire m03_couplers_to_m03_couplers_ARVALID;
  wire [31:0]m03_couplers_to_m03_couplers_AWADDR;
  wire [2:0]m03_couplers_to_m03_couplers_AWPROT;
  wire m03_couplers_to_m03_couplers_AWREADY;
  wire m03_couplers_to_m03_couplers_AWVALID;
  wire m03_couplers_to_m03_couplers_BREADY;
  wire [1:0]m03_couplers_to_m03_couplers_BRESP;
  wire m03_couplers_to_m03_couplers_BVALID;
  wire [31:0]m03_couplers_to_m03_couplers_RDATA;
  wire m03_couplers_to_m03_couplers_RREADY;
  wire [1:0]m03_couplers_to_m03_couplers_RRESP;
  wire m03_couplers_to_m03_couplers_RVALID;
  wire [31:0]m03_couplers_to_m03_couplers_WDATA;
  wire m03_couplers_to_m03_couplers_WREADY;
  wire [3:0]m03_couplers_to_m03_couplers_WSTRB;
  wire m03_couplers_to_m03_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m03_couplers_to_m03_couplers_ARADDR;
  assign M_AXI_arprot[2:0] = m03_couplers_to_m03_couplers_ARPROT;
  assign M_AXI_arvalid = m03_couplers_to_m03_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m03_couplers_to_m03_couplers_AWADDR;
  assign M_AXI_awprot[2:0] = m03_couplers_to_m03_couplers_AWPROT;
  assign M_AXI_awvalid = m03_couplers_to_m03_couplers_AWVALID;
  assign M_AXI_bready = m03_couplers_to_m03_couplers_BREADY;
  assign M_AXI_rready = m03_couplers_to_m03_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m03_couplers_to_m03_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = m03_couplers_to_m03_couplers_WSTRB;
  assign M_AXI_wvalid = m03_couplers_to_m03_couplers_WVALID;
  assign S_AXI_arready = m03_couplers_to_m03_couplers_ARREADY;
  assign S_AXI_awready = m03_couplers_to_m03_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m03_couplers_to_m03_couplers_BRESP;
  assign S_AXI_bvalid = m03_couplers_to_m03_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m03_couplers_to_m03_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m03_couplers_to_m03_couplers_RRESP;
  assign S_AXI_rvalid = m03_couplers_to_m03_couplers_RVALID;
  assign S_AXI_wready = m03_couplers_to_m03_couplers_WREADY;
  assign m03_couplers_to_m03_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m03_couplers_to_m03_couplers_ARPROT = S_AXI_arprot[2:0];
  assign m03_couplers_to_m03_couplers_ARREADY = M_AXI_arready;
  assign m03_couplers_to_m03_couplers_ARVALID = S_AXI_arvalid;
  assign m03_couplers_to_m03_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m03_couplers_to_m03_couplers_AWPROT = S_AXI_awprot[2:0];
  assign m03_couplers_to_m03_couplers_AWREADY = M_AXI_awready;
  assign m03_couplers_to_m03_couplers_AWVALID = S_AXI_awvalid;
  assign m03_couplers_to_m03_couplers_BREADY = S_AXI_bready;
  assign m03_couplers_to_m03_couplers_BRESP = M_AXI_bresp[1:0];
  assign m03_couplers_to_m03_couplers_BVALID = M_AXI_bvalid;
  assign m03_couplers_to_m03_couplers_RDATA = M_AXI_rdata[31:0];
  assign m03_couplers_to_m03_couplers_RREADY = S_AXI_rready;
  assign m03_couplers_to_m03_couplers_RRESP = M_AXI_rresp[1:0];
  assign m03_couplers_to_m03_couplers_RVALID = M_AXI_rvalid;
  assign m03_couplers_to_m03_couplers_WDATA = S_AXI_wdata[31:0];
  assign m03_couplers_to_m03_couplers_WREADY = M_AXI_wready;
  assign m03_couplers_to_m03_couplers_WSTRB = S_AXI_wstrb[3:0];
  assign m03_couplers_to_m03_couplers_WVALID = S_AXI_wvalid;
endmodule

module m04_couplers_imp_1YAXSER
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input S_AXI_wvalid;

  wire [31:0]m04_couplers_to_m04_couplers_ARADDR;
  wire m04_couplers_to_m04_couplers_ARREADY;
  wire m04_couplers_to_m04_couplers_ARVALID;
  wire [31:0]m04_couplers_to_m04_couplers_AWADDR;
  wire m04_couplers_to_m04_couplers_AWREADY;
  wire m04_couplers_to_m04_couplers_AWVALID;
  wire m04_couplers_to_m04_couplers_BREADY;
  wire [1:0]m04_couplers_to_m04_couplers_BRESP;
  wire m04_couplers_to_m04_couplers_BVALID;
  wire [31:0]m04_couplers_to_m04_couplers_RDATA;
  wire m04_couplers_to_m04_couplers_RREADY;
  wire [1:0]m04_couplers_to_m04_couplers_RRESP;
  wire m04_couplers_to_m04_couplers_RVALID;
  wire [31:0]m04_couplers_to_m04_couplers_WDATA;
  wire m04_couplers_to_m04_couplers_WREADY;
  wire m04_couplers_to_m04_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m04_couplers_to_m04_couplers_ARADDR;
  assign M_AXI_arvalid = m04_couplers_to_m04_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m04_couplers_to_m04_couplers_AWADDR;
  assign M_AXI_awvalid = m04_couplers_to_m04_couplers_AWVALID;
  assign M_AXI_bready = m04_couplers_to_m04_couplers_BREADY;
  assign M_AXI_rready = m04_couplers_to_m04_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m04_couplers_to_m04_couplers_WDATA;
  assign M_AXI_wvalid = m04_couplers_to_m04_couplers_WVALID;
  assign S_AXI_arready = m04_couplers_to_m04_couplers_ARREADY;
  assign S_AXI_awready = m04_couplers_to_m04_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m04_couplers_to_m04_couplers_BRESP;
  assign S_AXI_bvalid = m04_couplers_to_m04_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m04_couplers_to_m04_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m04_couplers_to_m04_couplers_RRESP;
  assign S_AXI_rvalid = m04_couplers_to_m04_couplers_RVALID;
  assign S_AXI_wready = m04_couplers_to_m04_couplers_WREADY;
  assign m04_couplers_to_m04_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m04_couplers_to_m04_couplers_ARREADY = M_AXI_arready;
  assign m04_couplers_to_m04_couplers_ARVALID = S_AXI_arvalid;
  assign m04_couplers_to_m04_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m04_couplers_to_m04_couplers_AWREADY = M_AXI_awready;
  assign m04_couplers_to_m04_couplers_AWVALID = S_AXI_awvalid;
  assign m04_couplers_to_m04_couplers_BREADY = S_AXI_bready;
  assign m04_couplers_to_m04_couplers_BRESP = M_AXI_bresp[1:0];
  assign m04_couplers_to_m04_couplers_BVALID = M_AXI_bvalid;
  assign m04_couplers_to_m04_couplers_RDATA = M_AXI_rdata[31:0];
  assign m04_couplers_to_m04_couplers_RREADY = S_AXI_rready;
  assign m04_couplers_to_m04_couplers_RRESP = M_AXI_rresp[1:0];
  assign m04_couplers_to_m04_couplers_RVALID = M_AXI_rvalid;
  assign m04_couplers_to_m04_couplers_WDATA = S_AXI_wdata[31:0];
  assign m04_couplers_to_m04_couplers_WREADY = M_AXI_wready;
  assign m04_couplers_to_m04_couplers_WVALID = S_AXI_wvalid;
endmodule

module m05_couplers_imp_BSNXAJ
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire [31:0]m05_couplers_to_m05_couplers_ARADDR;
  wire m05_couplers_to_m05_couplers_ARREADY;
  wire m05_couplers_to_m05_couplers_ARVALID;
  wire [31:0]m05_couplers_to_m05_couplers_AWADDR;
  wire m05_couplers_to_m05_couplers_AWREADY;
  wire m05_couplers_to_m05_couplers_AWVALID;
  wire m05_couplers_to_m05_couplers_BREADY;
  wire [1:0]m05_couplers_to_m05_couplers_BRESP;
  wire m05_couplers_to_m05_couplers_BVALID;
  wire [31:0]m05_couplers_to_m05_couplers_RDATA;
  wire m05_couplers_to_m05_couplers_RREADY;
  wire [1:0]m05_couplers_to_m05_couplers_RRESP;
  wire m05_couplers_to_m05_couplers_RVALID;
  wire [31:0]m05_couplers_to_m05_couplers_WDATA;
  wire m05_couplers_to_m05_couplers_WREADY;
  wire [3:0]m05_couplers_to_m05_couplers_WSTRB;
  wire m05_couplers_to_m05_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m05_couplers_to_m05_couplers_ARADDR;
  assign M_AXI_arvalid = m05_couplers_to_m05_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m05_couplers_to_m05_couplers_AWADDR;
  assign M_AXI_awvalid = m05_couplers_to_m05_couplers_AWVALID;
  assign M_AXI_bready = m05_couplers_to_m05_couplers_BREADY;
  assign M_AXI_rready = m05_couplers_to_m05_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m05_couplers_to_m05_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = m05_couplers_to_m05_couplers_WSTRB;
  assign M_AXI_wvalid = m05_couplers_to_m05_couplers_WVALID;
  assign S_AXI_arready = m05_couplers_to_m05_couplers_ARREADY;
  assign S_AXI_awready = m05_couplers_to_m05_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m05_couplers_to_m05_couplers_BRESP;
  assign S_AXI_bvalid = m05_couplers_to_m05_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m05_couplers_to_m05_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m05_couplers_to_m05_couplers_RRESP;
  assign S_AXI_rvalid = m05_couplers_to_m05_couplers_RVALID;
  assign S_AXI_wready = m05_couplers_to_m05_couplers_WREADY;
  assign m05_couplers_to_m05_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m05_couplers_to_m05_couplers_ARREADY = M_AXI_arready;
  assign m05_couplers_to_m05_couplers_ARVALID = S_AXI_arvalid;
  assign m05_couplers_to_m05_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m05_couplers_to_m05_couplers_AWREADY = M_AXI_awready;
  assign m05_couplers_to_m05_couplers_AWVALID = S_AXI_awvalid;
  assign m05_couplers_to_m05_couplers_BREADY = S_AXI_bready;
  assign m05_couplers_to_m05_couplers_BRESP = M_AXI_bresp[1:0];
  assign m05_couplers_to_m05_couplers_BVALID = M_AXI_bvalid;
  assign m05_couplers_to_m05_couplers_RDATA = M_AXI_rdata[31:0];
  assign m05_couplers_to_m05_couplers_RREADY = S_AXI_rready;
  assign m05_couplers_to_m05_couplers_RRESP = M_AXI_rresp[1:0];
  assign m05_couplers_to_m05_couplers_RVALID = M_AXI_rvalid;
  assign m05_couplers_to_m05_couplers_WDATA = S_AXI_wdata[31:0];
  assign m05_couplers_to_m05_couplers_WREADY = M_AXI_wready;
  assign m05_couplers_to_m05_couplers_WSTRB = S_AXI_wstrb[3:0];
  assign m05_couplers_to_m05_couplers_WVALID = S_AXI_wvalid;
endmodule

module m06_couplers_imp_128RV8I
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input S_AXI_wvalid;

  wire [31:0]m06_couplers_to_m06_couplers_ARADDR;
  wire m06_couplers_to_m06_couplers_ARREADY;
  wire m06_couplers_to_m06_couplers_ARVALID;
  wire [31:0]m06_couplers_to_m06_couplers_AWADDR;
  wire m06_couplers_to_m06_couplers_AWREADY;
  wire m06_couplers_to_m06_couplers_AWVALID;
  wire m06_couplers_to_m06_couplers_BREADY;
  wire [1:0]m06_couplers_to_m06_couplers_BRESP;
  wire m06_couplers_to_m06_couplers_BVALID;
  wire [31:0]m06_couplers_to_m06_couplers_RDATA;
  wire m06_couplers_to_m06_couplers_RREADY;
  wire [1:0]m06_couplers_to_m06_couplers_RRESP;
  wire m06_couplers_to_m06_couplers_RVALID;
  wire [31:0]m06_couplers_to_m06_couplers_WDATA;
  wire m06_couplers_to_m06_couplers_WREADY;
  wire m06_couplers_to_m06_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m06_couplers_to_m06_couplers_ARADDR;
  assign M_AXI_arvalid = m06_couplers_to_m06_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m06_couplers_to_m06_couplers_AWADDR;
  assign M_AXI_awvalid = m06_couplers_to_m06_couplers_AWVALID;
  assign M_AXI_bready = m06_couplers_to_m06_couplers_BREADY;
  assign M_AXI_rready = m06_couplers_to_m06_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m06_couplers_to_m06_couplers_WDATA;
  assign M_AXI_wvalid = m06_couplers_to_m06_couplers_WVALID;
  assign S_AXI_arready = m06_couplers_to_m06_couplers_ARREADY;
  assign S_AXI_awready = m06_couplers_to_m06_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m06_couplers_to_m06_couplers_BRESP;
  assign S_AXI_bvalid = m06_couplers_to_m06_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m06_couplers_to_m06_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m06_couplers_to_m06_couplers_RRESP;
  assign S_AXI_rvalid = m06_couplers_to_m06_couplers_RVALID;
  assign S_AXI_wready = m06_couplers_to_m06_couplers_WREADY;
  assign m06_couplers_to_m06_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m06_couplers_to_m06_couplers_ARREADY = M_AXI_arready;
  assign m06_couplers_to_m06_couplers_ARVALID = S_AXI_arvalid;
  assign m06_couplers_to_m06_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m06_couplers_to_m06_couplers_AWREADY = M_AXI_awready;
  assign m06_couplers_to_m06_couplers_AWVALID = S_AXI_awvalid;
  assign m06_couplers_to_m06_couplers_BREADY = S_AXI_bready;
  assign m06_couplers_to_m06_couplers_BRESP = M_AXI_bresp[1:0];
  assign m06_couplers_to_m06_couplers_BVALID = M_AXI_bvalid;
  assign m06_couplers_to_m06_couplers_RDATA = M_AXI_rdata[31:0];
  assign m06_couplers_to_m06_couplers_RREADY = S_AXI_rready;
  assign m06_couplers_to_m06_couplers_RRESP = M_AXI_rresp[1:0];
  assign m06_couplers_to_m06_couplers_RVALID = M_AXI_rvalid;
  assign m06_couplers_to_m06_couplers_WDATA = S_AXI_wdata[31:0];
  assign m06_couplers_to_m06_couplers_WREADY = M_AXI_wready;
  assign m06_couplers_to_m06_couplers_WVALID = S_AXI_wvalid;
endmodule

module m07_couplers_imp_Q543AY
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input S_AXI_wvalid;

  wire [31:0]m07_couplers_to_m07_couplers_ARADDR;
  wire m07_couplers_to_m07_couplers_ARREADY;
  wire m07_couplers_to_m07_couplers_ARVALID;
  wire [31:0]m07_couplers_to_m07_couplers_AWADDR;
  wire m07_couplers_to_m07_couplers_AWREADY;
  wire m07_couplers_to_m07_couplers_AWVALID;
  wire m07_couplers_to_m07_couplers_BREADY;
  wire [1:0]m07_couplers_to_m07_couplers_BRESP;
  wire m07_couplers_to_m07_couplers_BVALID;
  wire [31:0]m07_couplers_to_m07_couplers_RDATA;
  wire m07_couplers_to_m07_couplers_RREADY;
  wire [1:0]m07_couplers_to_m07_couplers_RRESP;
  wire m07_couplers_to_m07_couplers_RVALID;
  wire [31:0]m07_couplers_to_m07_couplers_WDATA;
  wire m07_couplers_to_m07_couplers_WREADY;
  wire m07_couplers_to_m07_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m07_couplers_to_m07_couplers_ARADDR;
  assign M_AXI_arvalid = m07_couplers_to_m07_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m07_couplers_to_m07_couplers_AWADDR;
  assign M_AXI_awvalid = m07_couplers_to_m07_couplers_AWVALID;
  assign M_AXI_bready = m07_couplers_to_m07_couplers_BREADY;
  assign M_AXI_rready = m07_couplers_to_m07_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m07_couplers_to_m07_couplers_WDATA;
  assign M_AXI_wvalid = m07_couplers_to_m07_couplers_WVALID;
  assign S_AXI_arready = m07_couplers_to_m07_couplers_ARREADY;
  assign S_AXI_awready = m07_couplers_to_m07_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m07_couplers_to_m07_couplers_BRESP;
  assign S_AXI_bvalid = m07_couplers_to_m07_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m07_couplers_to_m07_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m07_couplers_to_m07_couplers_RRESP;
  assign S_AXI_rvalid = m07_couplers_to_m07_couplers_RVALID;
  assign S_AXI_wready = m07_couplers_to_m07_couplers_WREADY;
  assign m07_couplers_to_m07_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m07_couplers_to_m07_couplers_ARREADY = M_AXI_arready;
  assign m07_couplers_to_m07_couplers_ARVALID = S_AXI_arvalid;
  assign m07_couplers_to_m07_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m07_couplers_to_m07_couplers_AWREADY = M_AXI_awready;
  assign m07_couplers_to_m07_couplers_AWVALID = S_AXI_awvalid;
  assign m07_couplers_to_m07_couplers_BREADY = S_AXI_bready;
  assign m07_couplers_to_m07_couplers_BRESP = M_AXI_bresp[1:0];
  assign m07_couplers_to_m07_couplers_BVALID = M_AXI_bvalid;
  assign m07_couplers_to_m07_couplers_RDATA = M_AXI_rdata[31:0];
  assign m07_couplers_to_m07_couplers_RREADY = S_AXI_rready;
  assign m07_couplers_to_m07_couplers_RRESP = M_AXI_rresp[1:0];
  assign m07_couplers_to_m07_couplers_RVALID = M_AXI_rvalid;
  assign m07_couplers_to_m07_couplers_WDATA = S_AXI_wdata[31:0];
  assign m07_couplers_to_m07_couplers_WREADY = M_AXI_wready;
  assign m07_couplers_to_m07_couplers_WVALID = S_AXI_wvalid;
endmodule

module m08_couplers_imp_888DX0
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire [31:0]m08_couplers_to_m08_couplers_ARADDR;
  wire m08_couplers_to_m08_couplers_ARREADY;
  wire m08_couplers_to_m08_couplers_ARVALID;
  wire [31:0]m08_couplers_to_m08_couplers_AWADDR;
  wire m08_couplers_to_m08_couplers_AWREADY;
  wire m08_couplers_to_m08_couplers_AWVALID;
  wire m08_couplers_to_m08_couplers_BREADY;
  wire [1:0]m08_couplers_to_m08_couplers_BRESP;
  wire m08_couplers_to_m08_couplers_BVALID;
  wire [31:0]m08_couplers_to_m08_couplers_RDATA;
  wire m08_couplers_to_m08_couplers_RREADY;
  wire [1:0]m08_couplers_to_m08_couplers_RRESP;
  wire m08_couplers_to_m08_couplers_RVALID;
  wire [31:0]m08_couplers_to_m08_couplers_WDATA;
  wire m08_couplers_to_m08_couplers_WREADY;
  wire [3:0]m08_couplers_to_m08_couplers_WSTRB;
  wire m08_couplers_to_m08_couplers_WVALID;

  assign M_AXI_araddr[31:0] = m08_couplers_to_m08_couplers_ARADDR;
  assign M_AXI_arvalid = m08_couplers_to_m08_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = m08_couplers_to_m08_couplers_AWADDR;
  assign M_AXI_awvalid = m08_couplers_to_m08_couplers_AWVALID;
  assign M_AXI_bready = m08_couplers_to_m08_couplers_BREADY;
  assign M_AXI_rready = m08_couplers_to_m08_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m08_couplers_to_m08_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = m08_couplers_to_m08_couplers_WSTRB;
  assign M_AXI_wvalid = m08_couplers_to_m08_couplers_WVALID;
  assign S_AXI_arready = m08_couplers_to_m08_couplers_ARREADY;
  assign S_AXI_awready = m08_couplers_to_m08_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = m08_couplers_to_m08_couplers_BRESP;
  assign S_AXI_bvalid = m08_couplers_to_m08_couplers_BVALID;
  assign S_AXI_rdata[31:0] = m08_couplers_to_m08_couplers_RDATA;
  assign S_AXI_rresp[1:0] = m08_couplers_to_m08_couplers_RRESP;
  assign S_AXI_rvalid = m08_couplers_to_m08_couplers_RVALID;
  assign S_AXI_wready = m08_couplers_to_m08_couplers_WREADY;
  assign m08_couplers_to_m08_couplers_ARADDR = S_AXI_araddr[31:0];
  assign m08_couplers_to_m08_couplers_ARREADY = M_AXI_arready;
  assign m08_couplers_to_m08_couplers_ARVALID = S_AXI_arvalid;
  assign m08_couplers_to_m08_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign m08_couplers_to_m08_couplers_AWREADY = M_AXI_awready;
  assign m08_couplers_to_m08_couplers_AWVALID = S_AXI_awvalid;
  assign m08_couplers_to_m08_couplers_BREADY = S_AXI_bready;
  assign m08_couplers_to_m08_couplers_BRESP = M_AXI_bresp[1:0];
  assign m08_couplers_to_m08_couplers_BVALID = M_AXI_bvalid;
  assign m08_couplers_to_m08_couplers_RDATA = M_AXI_rdata[31:0];
  assign m08_couplers_to_m08_couplers_RREADY = S_AXI_rready;
  assign m08_couplers_to_m08_couplers_RRESP = M_AXI_rresp[1:0];
  assign m08_couplers_to_m08_couplers_RVALID = M_AXI_rvalid;
  assign m08_couplers_to_m08_couplers_WDATA = S_AXI_wdata[31:0];
  assign m08_couplers_to_m08_couplers_WREADY = M_AXI_wready;
  assign m08_couplers_to_m08_couplers_WSTRB = S_AXI_wstrb[3:0];
  assign m08_couplers_to_m08_couplers_WVALID = S_AXI_wvalid;
endmodule

module s00_couplers_imp_12VR3XP
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wid,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [11:0]S_AXI_arid;
  input [3:0]S_AXI_arlen;
  input [1:0]S_AXI_arlock;
  input [2:0]S_AXI_arprot;
  input [3:0]S_AXI_arqos;
  output S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [11:0]S_AXI_awid;
  input [3:0]S_AXI_awlen;
  input [1:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  output [11:0]S_AXI_bid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  output [11:0]S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  input [11:0]S_AXI_wid;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_pc_to_s00_couplers_ARADDR;
  wire [2:0]auto_pc_to_s00_couplers_ARPROT;
  wire auto_pc_to_s00_couplers_ARREADY;
  wire auto_pc_to_s00_couplers_ARVALID;
  wire [31:0]auto_pc_to_s00_couplers_AWADDR;
  wire [2:0]auto_pc_to_s00_couplers_AWPROT;
  wire auto_pc_to_s00_couplers_AWREADY;
  wire auto_pc_to_s00_couplers_AWVALID;
  wire auto_pc_to_s00_couplers_BREADY;
  wire [1:0]auto_pc_to_s00_couplers_BRESP;
  wire auto_pc_to_s00_couplers_BVALID;
  wire [31:0]auto_pc_to_s00_couplers_RDATA;
  wire auto_pc_to_s00_couplers_RREADY;
  wire [1:0]auto_pc_to_s00_couplers_RRESP;
  wire auto_pc_to_s00_couplers_RVALID;
  wire [31:0]auto_pc_to_s00_couplers_WDATA;
  wire auto_pc_to_s00_couplers_WREADY;
  wire [3:0]auto_pc_to_s00_couplers_WSTRB;
  wire auto_pc_to_s00_couplers_WVALID;
  wire [31:0]s00_couplers_to_auto_pc_ARADDR;
  wire [1:0]s00_couplers_to_auto_pc_ARBURST;
  wire [3:0]s00_couplers_to_auto_pc_ARCACHE;
  wire [11:0]s00_couplers_to_auto_pc_ARID;
  wire [3:0]s00_couplers_to_auto_pc_ARLEN;
  wire [1:0]s00_couplers_to_auto_pc_ARLOCK;
  wire [2:0]s00_couplers_to_auto_pc_ARPROT;
  wire [3:0]s00_couplers_to_auto_pc_ARQOS;
  wire s00_couplers_to_auto_pc_ARREADY;
  wire [2:0]s00_couplers_to_auto_pc_ARSIZE;
  wire s00_couplers_to_auto_pc_ARVALID;
  wire [31:0]s00_couplers_to_auto_pc_AWADDR;
  wire [1:0]s00_couplers_to_auto_pc_AWBURST;
  wire [3:0]s00_couplers_to_auto_pc_AWCACHE;
  wire [11:0]s00_couplers_to_auto_pc_AWID;
  wire [3:0]s00_couplers_to_auto_pc_AWLEN;
  wire [1:0]s00_couplers_to_auto_pc_AWLOCK;
  wire [2:0]s00_couplers_to_auto_pc_AWPROT;
  wire [3:0]s00_couplers_to_auto_pc_AWQOS;
  wire s00_couplers_to_auto_pc_AWREADY;
  wire [2:0]s00_couplers_to_auto_pc_AWSIZE;
  wire s00_couplers_to_auto_pc_AWVALID;
  wire [11:0]s00_couplers_to_auto_pc_BID;
  wire s00_couplers_to_auto_pc_BREADY;
  wire [1:0]s00_couplers_to_auto_pc_BRESP;
  wire s00_couplers_to_auto_pc_BVALID;
  wire [31:0]s00_couplers_to_auto_pc_RDATA;
  wire [11:0]s00_couplers_to_auto_pc_RID;
  wire s00_couplers_to_auto_pc_RLAST;
  wire s00_couplers_to_auto_pc_RREADY;
  wire [1:0]s00_couplers_to_auto_pc_RRESP;
  wire s00_couplers_to_auto_pc_RVALID;
  wire [31:0]s00_couplers_to_auto_pc_WDATA;
  wire [11:0]s00_couplers_to_auto_pc_WID;
  wire s00_couplers_to_auto_pc_WLAST;
  wire s00_couplers_to_auto_pc_WREADY;
  wire [3:0]s00_couplers_to_auto_pc_WSTRB;
  wire s00_couplers_to_auto_pc_WVALID;

  assign M_AXI_araddr[31:0] = auto_pc_to_s00_couplers_ARADDR;
  assign M_AXI_arprot[2:0] = auto_pc_to_s00_couplers_ARPROT;
  assign M_AXI_arvalid = auto_pc_to_s00_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = auto_pc_to_s00_couplers_AWADDR;
  assign M_AXI_awprot[2:0] = auto_pc_to_s00_couplers_AWPROT;
  assign M_AXI_awvalid = auto_pc_to_s00_couplers_AWVALID;
  assign M_AXI_bready = auto_pc_to_s00_couplers_BREADY;
  assign M_AXI_rready = auto_pc_to_s00_couplers_RREADY;
  assign M_AXI_wdata[31:0] = auto_pc_to_s00_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = auto_pc_to_s00_couplers_WSTRB;
  assign M_AXI_wvalid = auto_pc_to_s00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = s00_couplers_to_auto_pc_ARREADY;
  assign S_AXI_awready = s00_couplers_to_auto_pc_AWREADY;
  assign S_AXI_bid[11:0] = s00_couplers_to_auto_pc_BID;
  assign S_AXI_bresp[1:0] = s00_couplers_to_auto_pc_BRESP;
  assign S_AXI_bvalid = s00_couplers_to_auto_pc_BVALID;
  assign S_AXI_rdata[31:0] = s00_couplers_to_auto_pc_RDATA;
  assign S_AXI_rid[11:0] = s00_couplers_to_auto_pc_RID;
  assign S_AXI_rlast = s00_couplers_to_auto_pc_RLAST;
  assign S_AXI_rresp[1:0] = s00_couplers_to_auto_pc_RRESP;
  assign S_AXI_rvalid = s00_couplers_to_auto_pc_RVALID;
  assign S_AXI_wready = s00_couplers_to_auto_pc_WREADY;
  assign auto_pc_to_s00_couplers_ARREADY = M_AXI_arready;
  assign auto_pc_to_s00_couplers_AWREADY = M_AXI_awready;
  assign auto_pc_to_s00_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_pc_to_s00_couplers_BVALID = M_AXI_bvalid;
  assign auto_pc_to_s00_couplers_RDATA = M_AXI_rdata[31:0];
  assign auto_pc_to_s00_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_pc_to_s00_couplers_RVALID = M_AXI_rvalid;
  assign auto_pc_to_s00_couplers_WREADY = M_AXI_wready;
  assign s00_couplers_to_auto_pc_ARADDR = S_AXI_araddr[31:0];
  assign s00_couplers_to_auto_pc_ARBURST = S_AXI_arburst[1:0];
  assign s00_couplers_to_auto_pc_ARCACHE = S_AXI_arcache[3:0];
  assign s00_couplers_to_auto_pc_ARID = S_AXI_arid[11:0];
  assign s00_couplers_to_auto_pc_ARLEN = S_AXI_arlen[3:0];
  assign s00_couplers_to_auto_pc_ARLOCK = S_AXI_arlock[1:0];
  assign s00_couplers_to_auto_pc_ARPROT = S_AXI_arprot[2:0];
  assign s00_couplers_to_auto_pc_ARQOS = S_AXI_arqos[3:0];
  assign s00_couplers_to_auto_pc_ARSIZE = S_AXI_arsize[2:0];
  assign s00_couplers_to_auto_pc_ARVALID = S_AXI_arvalid;
  assign s00_couplers_to_auto_pc_AWADDR = S_AXI_awaddr[31:0];
  assign s00_couplers_to_auto_pc_AWBURST = S_AXI_awburst[1:0];
  assign s00_couplers_to_auto_pc_AWCACHE = S_AXI_awcache[3:0];
  assign s00_couplers_to_auto_pc_AWID = S_AXI_awid[11:0];
  assign s00_couplers_to_auto_pc_AWLEN = S_AXI_awlen[3:0];
  assign s00_couplers_to_auto_pc_AWLOCK = S_AXI_awlock[1:0];
  assign s00_couplers_to_auto_pc_AWPROT = S_AXI_awprot[2:0];
  assign s00_couplers_to_auto_pc_AWQOS = S_AXI_awqos[3:0];
  assign s00_couplers_to_auto_pc_AWSIZE = S_AXI_awsize[2:0];
  assign s00_couplers_to_auto_pc_AWVALID = S_AXI_awvalid;
  assign s00_couplers_to_auto_pc_BREADY = S_AXI_bready;
  assign s00_couplers_to_auto_pc_RREADY = S_AXI_rready;
  assign s00_couplers_to_auto_pc_WDATA = S_AXI_wdata[31:0];
  assign s00_couplers_to_auto_pc_WID = S_AXI_wid[11:0];
  assign s00_couplers_to_auto_pc_WLAST = S_AXI_wlast;
  assign s00_couplers_to_auto_pc_WSTRB = S_AXI_wstrb[3:0];
  assign s00_couplers_to_auto_pc_WVALID = S_AXI_wvalid;
  av_system_auto_pc_0 auto_pc
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(auto_pc_to_s00_couplers_ARADDR),
        .m_axi_arprot(auto_pc_to_s00_couplers_ARPROT),
        .m_axi_arready(auto_pc_to_s00_couplers_ARREADY),
        .m_axi_arvalid(auto_pc_to_s00_couplers_ARVALID),
        .m_axi_awaddr(auto_pc_to_s00_couplers_AWADDR),
        .m_axi_awprot(auto_pc_to_s00_couplers_AWPROT),
        .m_axi_awready(auto_pc_to_s00_couplers_AWREADY),
        .m_axi_awvalid(auto_pc_to_s00_couplers_AWVALID),
        .m_axi_bready(auto_pc_to_s00_couplers_BREADY),
        .m_axi_bresp(auto_pc_to_s00_couplers_BRESP),
        .m_axi_bvalid(auto_pc_to_s00_couplers_BVALID),
        .m_axi_rdata(auto_pc_to_s00_couplers_RDATA),
        .m_axi_rready(auto_pc_to_s00_couplers_RREADY),
        .m_axi_rresp(auto_pc_to_s00_couplers_RRESP),
        .m_axi_rvalid(auto_pc_to_s00_couplers_RVALID),
        .m_axi_wdata(auto_pc_to_s00_couplers_WDATA),
        .m_axi_wready(auto_pc_to_s00_couplers_WREADY),
        .m_axi_wstrb(auto_pc_to_s00_couplers_WSTRB),
        .m_axi_wvalid(auto_pc_to_s00_couplers_WVALID),
        .s_axi_araddr(s00_couplers_to_auto_pc_ARADDR),
        .s_axi_arburst(s00_couplers_to_auto_pc_ARBURST),
        .s_axi_arcache(s00_couplers_to_auto_pc_ARCACHE),
        .s_axi_arid(s00_couplers_to_auto_pc_ARID),
        .s_axi_arlen(s00_couplers_to_auto_pc_ARLEN),
        .s_axi_arlock(s00_couplers_to_auto_pc_ARLOCK),
        .s_axi_arprot(s00_couplers_to_auto_pc_ARPROT),
        .s_axi_arqos(s00_couplers_to_auto_pc_ARQOS),
        .s_axi_arready(s00_couplers_to_auto_pc_ARREADY),
        .s_axi_arsize(s00_couplers_to_auto_pc_ARSIZE),
        .s_axi_arvalid(s00_couplers_to_auto_pc_ARVALID),
        .s_axi_awaddr(s00_couplers_to_auto_pc_AWADDR),
        .s_axi_awburst(s00_couplers_to_auto_pc_AWBURST),
        .s_axi_awcache(s00_couplers_to_auto_pc_AWCACHE),
        .s_axi_awid(s00_couplers_to_auto_pc_AWID),
        .s_axi_awlen(s00_couplers_to_auto_pc_AWLEN),
        .s_axi_awlock(s00_couplers_to_auto_pc_AWLOCK),
        .s_axi_awprot(s00_couplers_to_auto_pc_AWPROT),
        .s_axi_awqos(s00_couplers_to_auto_pc_AWQOS),
        .s_axi_awready(s00_couplers_to_auto_pc_AWREADY),
        .s_axi_awsize(s00_couplers_to_auto_pc_AWSIZE),
        .s_axi_awvalid(s00_couplers_to_auto_pc_AWVALID),
        .s_axi_bid(s00_couplers_to_auto_pc_BID),
        .s_axi_bready(s00_couplers_to_auto_pc_BREADY),
        .s_axi_bresp(s00_couplers_to_auto_pc_BRESP),
        .s_axi_bvalid(s00_couplers_to_auto_pc_BVALID),
        .s_axi_rdata(s00_couplers_to_auto_pc_RDATA),
        .s_axi_rid(s00_couplers_to_auto_pc_RID),
        .s_axi_rlast(s00_couplers_to_auto_pc_RLAST),
        .s_axi_rready(s00_couplers_to_auto_pc_RREADY),
        .s_axi_rresp(s00_couplers_to_auto_pc_RRESP),
        .s_axi_rvalid(s00_couplers_to_auto_pc_RVALID),
        .s_axi_wdata(s00_couplers_to_auto_pc_WDATA),
        .s_axi_wid(s00_couplers_to_auto_pc_WID),
        .s_axi_wlast(s00_couplers_to_auto_pc_WLAST),
        .s_axi_wready(s00_couplers_to_auto_pc_WREADY),
        .s_axi_wstrb(s00_couplers_to_auto_pc_WSTRB),
        .s_axi_wvalid(s00_couplers_to_auto_pc_WVALID));
endmodule

module s00_couplers_imp_14MGJQK
   (M_ACLK,
    M_ARESETN,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_wdata,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [7:0]M_AXI_awlen;
  output [0:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  output [63:0]M_AXI_wdata;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [7:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [3:0]S_AXI_awlen;
  input [1:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  input [63:0]S_AXI_wdata;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [7:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_pc_to_s00_couplers_AWADDR;
  wire [1:0]auto_pc_to_s00_couplers_AWBURST;
  wire [3:0]auto_pc_to_s00_couplers_AWCACHE;
  wire [7:0]auto_pc_to_s00_couplers_AWLEN;
  wire [0:0]auto_pc_to_s00_couplers_AWLOCK;
  wire [2:0]auto_pc_to_s00_couplers_AWPROT;
  wire [3:0]auto_pc_to_s00_couplers_AWQOS;
  wire auto_pc_to_s00_couplers_AWREADY;
  wire [2:0]auto_pc_to_s00_couplers_AWSIZE;
  wire auto_pc_to_s00_couplers_AWVALID;
  wire auto_pc_to_s00_couplers_BREADY;
  wire [1:0]auto_pc_to_s00_couplers_BRESP;
  wire auto_pc_to_s00_couplers_BVALID;
  wire [63:0]auto_pc_to_s00_couplers_WDATA;
  wire auto_pc_to_s00_couplers_WLAST;
  wire auto_pc_to_s00_couplers_WREADY;
  wire [7:0]auto_pc_to_s00_couplers_WSTRB;
  wire auto_pc_to_s00_couplers_WVALID;
  wire [31:0]s00_couplers_to_auto_pc_AWADDR;
  wire [1:0]s00_couplers_to_auto_pc_AWBURST;
  wire [3:0]s00_couplers_to_auto_pc_AWCACHE;
  wire [3:0]s00_couplers_to_auto_pc_AWLEN;
  wire [1:0]s00_couplers_to_auto_pc_AWLOCK;
  wire [2:0]s00_couplers_to_auto_pc_AWPROT;
  wire [3:0]s00_couplers_to_auto_pc_AWQOS;
  wire s00_couplers_to_auto_pc_AWREADY;
  wire [2:0]s00_couplers_to_auto_pc_AWSIZE;
  wire s00_couplers_to_auto_pc_AWVALID;
  wire s00_couplers_to_auto_pc_BREADY;
  wire [1:0]s00_couplers_to_auto_pc_BRESP;
  wire s00_couplers_to_auto_pc_BVALID;
  wire [63:0]s00_couplers_to_auto_pc_WDATA;
  wire s00_couplers_to_auto_pc_WLAST;
  wire s00_couplers_to_auto_pc_WREADY;
  wire [7:0]s00_couplers_to_auto_pc_WSTRB;
  wire s00_couplers_to_auto_pc_WVALID;

  assign M_AXI_awaddr[31:0] = auto_pc_to_s00_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = auto_pc_to_s00_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = auto_pc_to_s00_couplers_AWCACHE;
  assign M_AXI_awlen[7:0] = auto_pc_to_s00_couplers_AWLEN;
  assign M_AXI_awlock[0] = auto_pc_to_s00_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = auto_pc_to_s00_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = auto_pc_to_s00_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = auto_pc_to_s00_couplers_AWSIZE;
  assign M_AXI_awvalid = auto_pc_to_s00_couplers_AWVALID;
  assign M_AXI_bready = auto_pc_to_s00_couplers_BREADY;
  assign M_AXI_wdata[63:0] = auto_pc_to_s00_couplers_WDATA;
  assign M_AXI_wlast = auto_pc_to_s00_couplers_WLAST;
  assign M_AXI_wstrb[7:0] = auto_pc_to_s00_couplers_WSTRB;
  assign M_AXI_wvalid = auto_pc_to_s00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_awready = s00_couplers_to_auto_pc_AWREADY;
  assign S_AXI_bresp[1:0] = s00_couplers_to_auto_pc_BRESP;
  assign S_AXI_bvalid = s00_couplers_to_auto_pc_BVALID;
  assign S_AXI_wready = s00_couplers_to_auto_pc_WREADY;
  assign auto_pc_to_s00_couplers_AWREADY = M_AXI_awready;
  assign auto_pc_to_s00_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_pc_to_s00_couplers_BVALID = M_AXI_bvalid;
  assign auto_pc_to_s00_couplers_WREADY = M_AXI_wready;
  assign s00_couplers_to_auto_pc_AWADDR = S_AXI_awaddr[31:0];
  assign s00_couplers_to_auto_pc_AWBURST = S_AXI_awburst[1:0];
  assign s00_couplers_to_auto_pc_AWCACHE = S_AXI_awcache[3:0];
  assign s00_couplers_to_auto_pc_AWLEN = S_AXI_awlen[3:0];
  assign s00_couplers_to_auto_pc_AWLOCK = S_AXI_awlock[1:0];
  assign s00_couplers_to_auto_pc_AWPROT = S_AXI_awprot[2:0];
  assign s00_couplers_to_auto_pc_AWQOS = S_AXI_awqos[3:0];
  assign s00_couplers_to_auto_pc_AWSIZE = S_AXI_awsize[2:0];
  assign s00_couplers_to_auto_pc_AWVALID = S_AXI_awvalid;
  assign s00_couplers_to_auto_pc_BREADY = S_AXI_bready;
  assign s00_couplers_to_auto_pc_WDATA = S_AXI_wdata[63:0];
  assign s00_couplers_to_auto_pc_WLAST = S_AXI_wlast;
  assign s00_couplers_to_auto_pc_WSTRB = S_AXI_wstrb[7:0];
  assign s00_couplers_to_auto_pc_WVALID = S_AXI_wvalid;
  av_system_auto_pc_4 auto_pc
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_awaddr(auto_pc_to_s00_couplers_AWADDR),
        .m_axi_awburst(auto_pc_to_s00_couplers_AWBURST),
        .m_axi_awcache(auto_pc_to_s00_couplers_AWCACHE),
        .m_axi_awlen(auto_pc_to_s00_couplers_AWLEN),
        .m_axi_awlock(auto_pc_to_s00_couplers_AWLOCK),
        .m_axi_awprot(auto_pc_to_s00_couplers_AWPROT),
        .m_axi_awqos(auto_pc_to_s00_couplers_AWQOS),
        .m_axi_awready(auto_pc_to_s00_couplers_AWREADY),
        .m_axi_awsize(auto_pc_to_s00_couplers_AWSIZE),
        .m_axi_awvalid(auto_pc_to_s00_couplers_AWVALID),
        .m_axi_bready(auto_pc_to_s00_couplers_BREADY),
        .m_axi_bresp(auto_pc_to_s00_couplers_BRESP),
        .m_axi_bvalid(auto_pc_to_s00_couplers_BVALID),
        .m_axi_wdata(auto_pc_to_s00_couplers_WDATA),
        .m_axi_wlast(auto_pc_to_s00_couplers_WLAST),
        .m_axi_wready(auto_pc_to_s00_couplers_WREADY),
        .m_axi_wstrb(auto_pc_to_s00_couplers_WSTRB),
        .m_axi_wvalid(auto_pc_to_s00_couplers_WVALID),
        .s_axi_awaddr(s00_couplers_to_auto_pc_AWADDR),
        .s_axi_awburst(s00_couplers_to_auto_pc_AWBURST),
        .s_axi_awcache(s00_couplers_to_auto_pc_AWCACHE),
        .s_axi_awlen(s00_couplers_to_auto_pc_AWLEN),
        .s_axi_awlock(s00_couplers_to_auto_pc_AWLOCK),
        .s_axi_awprot(s00_couplers_to_auto_pc_AWPROT),
        .s_axi_awqos(s00_couplers_to_auto_pc_AWQOS),
        .s_axi_awready(s00_couplers_to_auto_pc_AWREADY),
        .s_axi_awsize(s00_couplers_to_auto_pc_AWSIZE),
        .s_axi_awvalid(s00_couplers_to_auto_pc_AWVALID),
        .s_axi_bready(s00_couplers_to_auto_pc_BREADY),
        .s_axi_bresp(s00_couplers_to_auto_pc_BRESP),
        .s_axi_bvalid(s00_couplers_to_auto_pc_BVALID),
        .s_axi_wdata(s00_couplers_to_auto_pc_WDATA),
        .s_axi_wlast(s00_couplers_to_auto_pc_WLAST),
        .s_axi_wready(s00_couplers_to_auto_pc_WREADY),
        .s_axi_wstrb(s00_couplers_to_auto_pc_WSTRB),
        .s_axi_wvalid(s00_couplers_to_auto_pc_WVALID));
endmodule

module s00_couplers_imp_7QNGDV
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_rdata,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arlen,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_rdata,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [7:0]M_AXI_arlen;
  output [0:0]M_AXI_arlock;
  output [2:0]M_AXI_arprot;
  output [3:0]M_AXI_arqos;
  input M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output M_AXI_arvalid;
  input [63:0]M_AXI_rdata;
  input M_AXI_rlast;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [7:0]S_AXI_arlen;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  output [31:0]S_AXI_rdata;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_us_to_s00_couplers_ARADDR;
  wire [1:0]auto_us_to_s00_couplers_ARBURST;
  wire [3:0]auto_us_to_s00_couplers_ARCACHE;
  wire [7:0]auto_us_to_s00_couplers_ARLEN;
  wire [0:0]auto_us_to_s00_couplers_ARLOCK;
  wire [2:0]auto_us_to_s00_couplers_ARPROT;
  wire [3:0]auto_us_to_s00_couplers_ARQOS;
  wire auto_us_to_s00_couplers_ARREADY;
  wire [2:0]auto_us_to_s00_couplers_ARSIZE;
  wire auto_us_to_s00_couplers_ARVALID;
  wire [63:0]auto_us_to_s00_couplers_RDATA;
  wire auto_us_to_s00_couplers_RLAST;
  wire auto_us_to_s00_couplers_RREADY;
  wire [1:0]auto_us_to_s00_couplers_RRESP;
  wire auto_us_to_s00_couplers_RVALID;
  wire [31:0]s00_couplers_to_auto_us_ARADDR;
  wire [1:0]s00_couplers_to_auto_us_ARBURST;
  wire [3:0]s00_couplers_to_auto_us_ARCACHE;
  wire [7:0]s00_couplers_to_auto_us_ARLEN;
  wire [2:0]s00_couplers_to_auto_us_ARPROT;
  wire s00_couplers_to_auto_us_ARREADY;
  wire [2:0]s00_couplers_to_auto_us_ARSIZE;
  wire s00_couplers_to_auto_us_ARVALID;
  wire [31:0]s00_couplers_to_auto_us_RDATA;
  wire s00_couplers_to_auto_us_RLAST;
  wire s00_couplers_to_auto_us_RREADY;
  wire [1:0]s00_couplers_to_auto_us_RRESP;
  wire s00_couplers_to_auto_us_RVALID;

  assign M_AXI_araddr[31:0] = auto_us_to_s00_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = auto_us_to_s00_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = auto_us_to_s00_couplers_ARCACHE;
  assign M_AXI_arlen[7:0] = auto_us_to_s00_couplers_ARLEN;
  assign M_AXI_arlock[0] = auto_us_to_s00_couplers_ARLOCK;
  assign M_AXI_arprot[2:0] = auto_us_to_s00_couplers_ARPROT;
  assign M_AXI_arqos[3:0] = auto_us_to_s00_couplers_ARQOS;
  assign M_AXI_arsize[2:0] = auto_us_to_s00_couplers_ARSIZE;
  assign M_AXI_arvalid = auto_us_to_s00_couplers_ARVALID;
  assign M_AXI_rready = auto_us_to_s00_couplers_RREADY;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = s00_couplers_to_auto_us_ARREADY;
  assign S_AXI_rdata[31:0] = s00_couplers_to_auto_us_RDATA;
  assign S_AXI_rlast = s00_couplers_to_auto_us_RLAST;
  assign S_AXI_rresp[1:0] = s00_couplers_to_auto_us_RRESP;
  assign S_AXI_rvalid = s00_couplers_to_auto_us_RVALID;
  assign auto_us_to_s00_couplers_ARREADY = M_AXI_arready;
  assign auto_us_to_s00_couplers_RDATA = M_AXI_rdata[63:0];
  assign auto_us_to_s00_couplers_RLAST = M_AXI_rlast;
  assign auto_us_to_s00_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_us_to_s00_couplers_RVALID = M_AXI_rvalid;
  assign s00_couplers_to_auto_us_ARADDR = S_AXI_araddr[31:0];
  assign s00_couplers_to_auto_us_ARBURST = S_AXI_arburst[1:0];
  assign s00_couplers_to_auto_us_ARCACHE = S_AXI_arcache[3:0];
  assign s00_couplers_to_auto_us_ARLEN = S_AXI_arlen[7:0];
  assign s00_couplers_to_auto_us_ARPROT = S_AXI_arprot[2:0];
  assign s00_couplers_to_auto_us_ARSIZE = S_AXI_arsize[2:0];
  assign s00_couplers_to_auto_us_ARVALID = S_AXI_arvalid;
  assign s00_couplers_to_auto_us_RREADY = S_AXI_rready;
  av_system_auto_us_0 auto_us
       (.m_axi_araddr(auto_us_to_s00_couplers_ARADDR),
        .m_axi_arburst(auto_us_to_s00_couplers_ARBURST),
        .m_axi_arcache(auto_us_to_s00_couplers_ARCACHE),
        .m_axi_arlen(auto_us_to_s00_couplers_ARLEN),
        .m_axi_arlock(auto_us_to_s00_couplers_ARLOCK),
        .m_axi_arprot(auto_us_to_s00_couplers_ARPROT),
        .m_axi_arqos(auto_us_to_s00_couplers_ARQOS),
        .m_axi_arready(auto_us_to_s00_couplers_ARREADY),
        .m_axi_arsize(auto_us_to_s00_couplers_ARSIZE),
        .m_axi_arvalid(auto_us_to_s00_couplers_ARVALID),
        .m_axi_rdata(auto_us_to_s00_couplers_RDATA),
        .m_axi_rlast(auto_us_to_s00_couplers_RLAST),
        .m_axi_rready(auto_us_to_s00_couplers_RREADY),
        .m_axi_rresp(auto_us_to_s00_couplers_RRESP),
        .m_axi_rvalid(auto_us_to_s00_couplers_RVALID),
        .s_axi_aclk(S_ACLK_1),
        .s_axi_araddr(s00_couplers_to_auto_us_ARADDR),
        .s_axi_arburst(s00_couplers_to_auto_us_ARBURST),
        .s_axi_arcache(s00_couplers_to_auto_us_ARCACHE),
        .s_axi_aresetn(S_ARESETN_1),
        .s_axi_arlen(s00_couplers_to_auto_us_ARLEN),
        .s_axi_arlock(1'b0),
        .s_axi_arprot(s00_couplers_to_auto_us_ARPROT),
        .s_axi_arqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(s00_couplers_to_auto_us_ARREADY),
        .s_axi_arregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arsize(s00_couplers_to_auto_us_ARSIZE),
        .s_axi_arvalid(s00_couplers_to_auto_us_ARVALID),
        .s_axi_rdata(s00_couplers_to_auto_us_RDATA),
        .s_axi_rlast(s00_couplers_to_auto_us_RLAST),
        .s_axi_rready(s00_couplers_to_auto_us_RREADY),
        .s_axi_rresp(s00_couplers_to_auto_us_RRESP),
        .s_axi_rvalid(s00_couplers_to_auto_us_RVALID));
endmodule

module s00_couplers_imp_EZP5VS
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arlen,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_rdata,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arlen,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_rdata,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [7:0]M_AXI_arlen;
  output [2:0]M_AXI_arprot;
  input [0:0]M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output [0:0]M_AXI_arvalid;
  input [63:0]M_AXI_rdata;
  input [0:0]M_AXI_rlast;
  output [0:0]M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input [0:0]M_AXI_rvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [7:0]S_AXI_arlen;
  input [2:0]S_AXI_arprot;
  output [0:0]S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input [0:0]S_AXI_arvalid;
  output [63:0]S_AXI_rdata;
  output [0:0]S_AXI_rlast;
  input [0:0]S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output [0:0]S_AXI_rvalid;

  wire [31:0]s00_couplers_to_s00_couplers_ARADDR;
  wire [1:0]s00_couplers_to_s00_couplers_ARBURST;
  wire [3:0]s00_couplers_to_s00_couplers_ARCACHE;
  wire [7:0]s00_couplers_to_s00_couplers_ARLEN;
  wire [2:0]s00_couplers_to_s00_couplers_ARPROT;
  wire [0:0]s00_couplers_to_s00_couplers_ARREADY;
  wire [2:0]s00_couplers_to_s00_couplers_ARSIZE;
  wire [0:0]s00_couplers_to_s00_couplers_ARVALID;
  wire [63:0]s00_couplers_to_s00_couplers_RDATA;
  wire [0:0]s00_couplers_to_s00_couplers_RLAST;
  wire [0:0]s00_couplers_to_s00_couplers_RREADY;
  wire [1:0]s00_couplers_to_s00_couplers_RRESP;
  wire [0:0]s00_couplers_to_s00_couplers_RVALID;

  assign M_AXI_araddr[31:0] = s00_couplers_to_s00_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = s00_couplers_to_s00_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = s00_couplers_to_s00_couplers_ARCACHE;
  assign M_AXI_arlen[7:0] = s00_couplers_to_s00_couplers_ARLEN;
  assign M_AXI_arprot[2:0] = s00_couplers_to_s00_couplers_ARPROT;
  assign M_AXI_arsize[2:0] = s00_couplers_to_s00_couplers_ARSIZE;
  assign M_AXI_arvalid[0] = s00_couplers_to_s00_couplers_ARVALID;
  assign M_AXI_rready[0] = s00_couplers_to_s00_couplers_RREADY;
  assign S_AXI_arready[0] = s00_couplers_to_s00_couplers_ARREADY;
  assign S_AXI_rdata[63:0] = s00_couplers_to_s00_couplers_RDATA;
  assign S_AXI_rlast[0] = s00_couplers_to_s00_couplers_RLAST;
  assign S_AXI_rresp[1:0] = s00_couplers_to_s00_couplers_RRESP;
  assign S_AXI_rvalid[0] = s00_couplers_to_s00_couplers_RVALID;
  assign s00_couplers_to_s00_couplers_ARADDR = S_AXI_araddr[31:0];
  assign s00_couplers_to_s00_couplers_ARBURST = S_AXI_arburst[1:0];
  assign s00_couplers_to_s00_couplers_ARCACHE = S_AXI_arcache[3:0];
  assign s00_couplers_to_s00_couplers_ARLEN = S_AXI_arlen[7:0];
  assign s00_couplers_to_s00_couplers_ARPROT = S_AXI_arprot[2:0];
  assign s00_couplers_to_s00_couplers_ARREADY = M_AXI_arready[0];
  assign s00_couplers_to_s00_couplers_ARSIZE = S_AXI_arsize[2:0];
  assign s00_couplers_to_s00_couplers_ARVALID = S_AXI_arvalid[0];
  assign s00_couplers_to_s00_couplers_RDATA = M_AXI_rdata[63:0];
  assign s00_couplers_to_s00_couplers_RLAST = M_AXI_rlast[0];
  assign s00_couplers_to_s00_couplers_RREADY = S_AXI_rready[0];
  assign s00_couplers_to_s00_couplers_RRESP = M_AXI_rresp[1:0];
  assign s00_couplers_to_s00_couplers_RVALID = M_AXI_rvalid[0];
endmodule

module s01_couplers_imp_1KLZ1T7
   (M_ACLK,
    M_ARESETN,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_wdata,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awlen,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [7:0]M_AXI_awlen;
  output [0:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  output [63:0]M_AXI_wdata;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [7:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [7:0]S_AXI_awlen;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  input [31:0]S_AXI_wdata;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_us_to_s01_couplers_AWADDR;
  wire [1:0]auto_us_to_s01_couplers_AWBURST;
  wire [3:0]auto_us_to_s01_couplers_AWCACHE;
  wire [7:0]auto_us_to_s01_couplers_AWLEN;
  wire [0:0]auto_us_to_s01_couplers_AWLOCK;
  wire [2:0]auto_us_to_s01_couplers_AWPROT;
  wire [3:0]auto_us_to_s01_couplers_AWQOS;
  wire auto_us_to_s01_couplers_AWREADY;
  wire [2:0]auto_us_to_s01_couplers_AWSIZE;
  wire auto_us_to_s01_couplers_AWVALID;
  wire auto_us_to_s01_couplers_BREADY;
  wire [1:0]auto_us_to_s01_couplers_BRESP;
  wire auto_us_to_s01_couplers_BVALID;
  wire [63:0]auto_us_to_s01_couplers_WDATA;
  wire auto_us_to_s01_couplers_WLAST;
  wire auto_us_to_s01_couplers_WREADY;
  wire [7:0]auto_us_to_s01_couplers_WSTRB;
  wire auto_us_to_s01_couplers_WVALID;
  wire [31:0]s01_couplers_to_auto_us_AWADDR;
  wire [1:0]s01_couplers_to_auto_us_AWBURST;
  wire [3:0]s01_couplers_to_auto_us_AWCACHE;
  wire [7:0]s01_couplers_to_auto_us_AWLEN;
  wire [2:0]s01_couplers_to_auto_us_AWPROT;
  wire s01_couplers_to_auto_us_AWREADY;
  wire [2:0]s01_couplers_to_auto_us_AWSIZE;
  wire s01_couplers_to_auto_us_AWVALID;
  wire s01_couplers_to_auto_us_BREADY;
  wire [1:0]s01_couplers_to_auto_us_BRESP;
  wire s01_couplers_to_auto_us_BVALID;
  wire [31:0]s01_couplers_to_auto_us_WDATA;
  wire s01_couplers_to_auto_us_WLAST;
  wire s01_couplers_to_auto_us_WREADY;
  wire [3:0]s01_couplers_to_auto_us_WSTRB;
  wire s01_couplers_to_auto_us_WVALID;

  assign M_AXI_awaddr[31:0] = auto_us_to_s01_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = auto_us_to_s01_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = auto_us_to_s01_couplers_AWCACHE;
  assign M_AXI_awlen[7:0] = auto_us_to_s01_couplers_AWLEN;
  assign M_AXI_awlock[0] = auto_us_to_s01_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = auto_us_to_s01_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = auto_us_to_s01_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = auto_us_to_s01_couplers_AWSIZE;
  assign M_AXI_awvalid = auto_us_to_s01_couplers_AWVALID;
  assign M_AXI_bready = auto_us_to_s01_couplers_BREADY;
  assign M_AXI_wdata[63:0] = auto_us_to_s01_couplers_WDATA;
  assign M_AXI_wlast = auto_us_to_s01_couplers_WLAST;
  assign M_AXI_wstrb[7:0] = auto_us_to_s01_couplers_WSTRB;
  assign M_AXI_wvalid = auto_us_to_s01_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_awready = s01_couplers_to_auto_us_AWREADY;
  assign S_AXI_bresp[1:0] = s01_couplers_to_auto_us_BRESP;
  assign S_AXI_bvalid = s01_couplers_to_auto_us_BVALID;
  assign S_AXI_wready = s01_couplers_to_auto_us_WREADY;
  assign auto_us_to_s01_couplers_AWREADY = M_AXI_awready;
  assign auto_us_to_s01_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_us_to_s01_couplers_BVALID = M_AXI_bvalid;
  assign auto_us_to_s01_couplers_WREADY = M_AXI_wready;
  assign s01_couplers_to_auto_us_AWADDR = S_AXI_awaddr[31:0];
  assign s01_couplers_to_auto_us_AWBURST = S_AXI_awburst[1:0];
  assign s01_couplers_to_auto_us_AWCACHE = S_AXI_awcache[3:0];
  assign s01_couplers_to_auto_us_AWLEN = S_AXI_awlen[7:0];
  assign s01_couplers_to_auto_us_AWPROT = S_AXI_awprot[2:0];
  assign s01_couplers_to_auto_us_AWSIZE = S_AXI_awsize[2:0];
  assign s01_couplers_to_auto_us_AWVALID = S_AXI_awvalid;
  assign s01_couplers_to_auto_us_BREADY = S_AXI_bready;
  assign s01_couplers_to_auto_us_WDATA = S_AXI_wdata[31:0];
  assign s01_couplers_to_auto_us_WLAST = S_AXI_wlast;
  assign s01_couplers_to_auto_us_WSTRB = S_AXI_wstrb[3:0];
  assign s01_couplers_to_auto_us_WVALID = S_AXI_wvalid;
  av_system_auto_us_1 auto_us
       (.m_axi_awaddr(auto_us_to_s01_couplers_AWADDR),
        .m_axi_awburst(auto_us_to_s01_couplers_AWBURST),
        .m_axi_awcache(auto_us_to_s01_couplers_AWCACHE),
        .m_axi_awlen(auto_us_to_s01_couplers_AWLEN),
        .m_axi_awlock(auto_us_to_s01_couplers_AWLOCK),
        .m_axi_awprot(auto_us_to_s01_couplers_AWPROT),
        .m_axi_awqos(auto_us_to_s01_couplers_AWQOS),
        .m_axi_awready(auto_us_to_s01_couplers_AWREADY),
        .m_axi_awsize(auto_us_to_s01_couplers_AWSIZE),
        .m_axi_awvalid(auto_us_to_s01_couplers_AWVALID),
        .m_axi_bready(auto_us_to_s01_couplers_BREADY),
        .m_axi_bresp(auto_us_to_s01_couplers_BRESP),
        .m_axi_bvalid(auto_us_to_s01_couplers_BVALID),
        .m_axi_wdata(auto_us_to_s01_couplers_WDATA),
        .m_axi_wlast(auto_us_to_s01_couplers_WLAST),
        .m_axi_wready(auto_us_to_s01_couplers_WREADY),
        .m_axi_wstrb(auto_us_to_s01_couplers_WSTRB),
        .m_axi_wvalid(auto_us_to_s01_couplers_WVALID),
        .s_axi_aclk(S_ACLK_1),
        .s_axi_aresetn(S_ARESETN_1),
        .s_axi_awaddr(s01_couplers_to_auto_us_AWADDR),
        .s_axi_awburst(s01_couplers_to_auto_us_AWBURST),
        .s_axi_awcache(s01_couplers_to_auto_us_AWCACHE),
        .s_axi_awlen(s01_couplers_to_auto_us_AWLEN),
        .s_axi_awlock(1'b0),
        .s_axi_awprot(s01_couplers_to_auto_us_AWPROT),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(s01_couplers_to_auto_us_AWREADY),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize(s01_couplers_to_auto_us_AWSIZE),
        .s_axi_awvalid(s01_couplers_to_auto_us_AWVALID),
        .s_axi_bready(s01_couplers_to_auto_us_BREADY),
        .s_axi_bresp(s01_couplers_to_auto_us_BRESP),
        .s_axi_bvalid(s01_couplers_to_auto_us_BVALID),
        .s_axi_wdata(s01_couplers_to_auto_us_WDATA),
        .s_axi_wlast(s01_couplers_to_auto_us_WLAST),
        .s_axi_wready(s01_couplers_to_auto_us_WREADY),
        .s_axi_wstrb(s01_couplers_to_auto_us_WSTRB),
        .s_axi_wvalid(s01_couplers_to_auto_us_WVALID));
endmodule

module s01_couplers_imp_1QOEV68
   (M_ACLK,
    M_ARESETN,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awlen,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_wdata,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awlen,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [7:0]M_AXI_awlen;
  output [2:0]M_AXI_awprot;
  input [0:0]M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output [0:0]M_AXI_awvalid;
  output [0:0]M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input [0:0]M_AXI_bvalid;
  output [63:0]M_AXI_wdata;
  output [0:0]M_AXI_wlast;
  input [0:0]M_AXI_wready;
  output [7:0]M_AXI_wstrb;
  output [0:0]M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [7:0]S_AXI_awlen;
  input [2:0]S_AXI_awprot;
  output [0:0]S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input [0:0]S_AXI_awvalid;
  input [0:0]S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output [0:0]S_AXI_bvalid;
  input [63:0]S_AXI_wdata;
  input [0:0]S_AXI_wlast;
  output [0:0]S_AXI_wready;
  input [7:0]S_AXI_wstrb;
  input [0:0]S_AXI_wvalid;

  wire [31:0]s01_couplers_to_s01_couplers_AWADDR;
  wire [1:0]s01_couplers_to_s01_couplers_AWBURST;
  wire [3:0]s01_couplers_to_s01_couplers_AWCACHE;
  wire [7:0]s01_couplers_to_s01_couplers_AWLEN;
  wire [2:0]s01_couplers_to_s01_couplers_AWPROT;
  wire [0:0]s01_couplers_to_s01_couplers_AWREADY;
  wire [2:0]s01_couplers_to_s01_couplers_AWSIZE;
  wire [0:0]s01_couplers_to_s01_couplers_AWVALID;
  wire [0:0]s01_couplers_to_s01_couplers_BREADY;
  wire [1:0]s01_couplers_to_s01_couplers_BRESP;
  wire [0:0]s01_couplers_to_s01_couplers_BVALID;
  wire [63:0]s01_couplers_to_s01_couplers_WDATA;
  wire [0:0]s01_couplers_to_s01_couplers_WLAST;
  wire [0:0]s01_couplers_to_s01_couplers_WREADY;
  wire [7:0]s01_couplers_to_s01_couplers_WSTRB;
  wire [0:0]s01_couplers_to_s01_couplers_WVALID;

  assign M_AXI_awaddr[31:0] = s01_couplers_to_s01_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = s01_couplers_to_s01_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = s01_couplers_to_s01_couplers_AWCACHE;
  assign M_AXI_awlen[7:0] = s01_couplers_to_s01_couplers_AWLEN;
  assign M_AXI_awprot[2:0] = s01_couplers_to_s01_couplers_AWPROT;
  assign M_AXI_awsize[2:0] = s01_couplers_to_s01_couplers_AWSIZE;
  assign M_AXI_awvalid[0] = s01_couplers_to_s01_couplers_AWVALID;
  assign M_AXI_bready[0] = s01_couplers_to_s01_couplers_BREADY;
  assign M_AXI_wdata[63:0] = s01_couplers_to_s01_couplers_WDATA;
  assign M_AXI_wlast[0] = s01_couplers_to_s01_couplers_WLAST;
  assign M_AXI_wstrb[7:0] = s01_couplers_to_s01_couplers_WSTRB;
  assign M_AXI_wvalid[0] = s01_couplers_to_s01_couplers_WVALID;
  assign S_AXI_awready[0] = s01_couplers_to_s01_couplers_AWREADY;
  assign S_AXI_bresp[1:0] = s01_couplers_to_s01_couplers_BRESP;
  assign S_AXI_bvalid[0] = s01_couplers_to_s01_couplers_BVALID;
  assign S_AXI_wready[0] = s01_couplers_to_s01_couplers_WREADY;
  assign s01_couplers_to_s01_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign s01_couplers_to_s01_couplers_AWBURST = S_AXI_awburst[1:0];
  assign s01_couplers_to_s01_couplers_AWCACHE = S_AXI_awcache[3:0];
  assign s01_couplers_to_s01_couplers_AWLEN = S_AXI_awlen[7:0];
  assign s01_couplers_to_s01_couplers_AWPROT = S_AXI_awprot[2:0];
  assign s01_couplers_to_s01_couplers_AWREADY = M_AXI_awready[0];
  assign s01_couplers_to_s01_couplers_AWSIZE = S_AXI_awsize[2:0];
  assign s01_couplers_to_s01_couplers_AWVALID = S_AXI_awvalid[0];
  assign s01_couplers_to_s01_couplers_BREADY = S_AXI_bready[0];
  assign s01_couplers_to_s01_couplers_BRESP = M_AXI_bresp[1:0];
  assign s01_couplers_to_s01_couplers_BVALID = M_AXI_bvalid[0];
  assign s01_couplers_to_s01_couplers_WDATA = S_AXI_wdata[63:0];
  assign s01_couplers_to_s01_couplers_WLAST = S_AXI_wlast[0];
  assign s01_couplers_to_s01_couplers_WREADY = M_AXI_wready[0];
  assign s01_couplers_to_s01_couplers_WSTRB = S_AXI_wstrb[7:0];
  assign s01_couplers_to_s01_couplers_WVALID = S_AXI_wvalid[0];
endmodule

module s01_couplers_imp_JAO9TG
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_rdata,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arlen,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_rdata,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [7:0]M_AXI_arlen;
  output [0:0]M_AXI_arlock;
  output [2:0]M_AXI_arprot;
  output [3:0]M_AXI_arqos;
  input M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output M_AXI_arvalid;
  input [63:0]M_AXI_rdata;
  input M_AXI_rlast;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [7:0]S_AXI_arlen;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  output [63:0]S_AXI_rdata;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;

  wire M_ACLK_1;
  wire M_ARESETN_1;
  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_cc_to_s01_couplers_ARADDR;
  wire [1:0]auto_cc_to_s01_couplers_ARBURST;
  wire [3:0]auto_cc_to_s01_couplers_ARCACHE;
  wire [7:0]auto_cc_to_s01_couplers_ARLEN;
  wire [0:0]auto_cc_to_s01_couplers_ARLOCK;
  wire [2:0]auto_cc_to_s01_couplers_ARPROT;
  wire [3:0]auto_cc_to_s01_couplers_ARQOS;
  wire auto_cc_to_s01_couplers_ARREADY;
  wire [2:0]auto_cc_to_s01_couplers_ARSIZE;
  wire auto_cc_to_s01_couplers_ARVALID;
  wire [63:0]auto_cc_to_s01_couplers_RDATA;
  wire auto_cc_to_s01_couplers_RLAST;
  wire auto_cc_to_s01_couplers_RREADY;
  wire [1:0]auto_cc_to_s01_couplers_RRESP;
  wire auto_cc_to_s01_couplers_RVALID;
  wire [31:0]s01_couplers_to_auto_cc_ARADDR;
  wire [1:0]s01_couplers_to_auto_cc_ARBURST;
  wire [3:0]s01_couplers_to_auto_cc_ARCACHE;
  wire [7:0]s01_couplers_to_auto_cc_ARLEN;
  wire [2:0]s01_couplers_to_auto_cc_ARPROT;
  wire s01_couplers_to_auto_cc_ARREADY;
  wire [2:0]s01_couplers_to_auto_cc_ARSIZE;
  wire s01_couplers_to_auto_cc_ARVALID;
  wire [63:0]s01_couplers_to_auto_cc_RDATA;
  wire s01_couplers_to_auto_cc_RLAST;
  wire s01_couplers_to_auto_cc_RREADY;
  wire [1:0]s01_couplers_to_auto_cc_RRESP;
  wire s01_couplers_to_auto_cc_RVALID;

  assign M_ACLK_1 = M_ACLK;
  assign M_ARESETN_1 = M_ARESETN;
  assign M_AXI_araddr[31:0] = auto_cc_to_s01_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = auto_cc_to_s01_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = auto_cc_to_s01_couplers_ARCACHE;
  assign M_AXI_arlen[7:0] = auto_cc_to_s01_couplers_ARLEN;
  assign M_AXI_arlock[0] = auto_cc_to_s01_couplers_ARLOCK;
  assign M_AXI_arprot[2:0] = auto_cc_to_s01_couplers_ARPROT;
  assign M_AXI_arqos[3:0] = auto_cc_to_s01_couplers_ARQOS;
  assign M_AXI_arsize[2:0] = auto_cc_to_s01_couplers_ARSIZE;
  assign M_AXI_arvalid = auto_cc_to_s01_couplers_ARVALID;
  assign M_AXI_rready = auto_cc_to_s01_couplers_RREADY;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = s01_couplers_to_auto_cc_ARREADY;
  assign S_AXI_rdata[63:0] = s01_couplers_to_auto_cc_RDATA;
  assign S_AXI_rlast = s01_couplers_to_auto_cc_RLAST;
  assign S_AXI_rresp[1:0] = s01_couplers_to_auto_cc_RRESP;
  assign S_AXI_rvalid = s01_couplers_to_auto_cc_RVALID;
  assign auto_cc_to_s01_couplers_ARREADY = M_AXI_arready;
  assign auto_cc_to_s01_couplers_RDATA = M_AXI_rdata[63:0];
  assign auto_cc_to_s01_couplers_RLAST = M_AXI_rlast;
  assign auto_cc_to_s01_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_cc_to_s01_couplers_RVALID = M_AXI_rvalid;
  assign s01_couplers_to_auto_cc_ARADDR = S_AXI_araddr[31:0];
  assign s01_couplers_to_auto_cc_ARBURST = S_AXI_arburst[1:0];
  assign s01_couplers_to_auto_cc_ARCACHE = S_AXI_arcache[3:0];
  assign s01_couplers_to_auto_cc_ARLEN = S_AXI_arlen[7:0];
  assign s01_couplers_to_auto_cc_ARPROT = S_AXI_arprot[2:0];
  assign s01_couplers_to_auto_cc_ARSIZE = S_AXI_arsize[2:0];
  assign s01_couplers_to_auto_cc_ARVALID = S_AXI_arvalid;
  assign s01_couplers_to_auto_cc_RREADY = S_AXI_rready;
  av_system_auto_cc_0 auto_cc
       (.m_axi_aclk(M_ACLK_1),
        .m_axi_araddr(auto_cc_to_s01_couplers_ARADDR),
        .m_axi_arburst(auto_cc_to_s01_couplers_ARBURST),
        .m_axi_arcache(auto_cc_to_s01_couplers_ARCACHE),
        .m_axi_aresetn(M_ARESETN_1),
        .m_axi_arlen(auto_cc_to_s01_couplers_ARLEN),
        .m_axi_arlock(auto_cc_to_s01_couplers_ARLOCK),
        .m_axi_arprot(auto_cc_to_s01_couplers_ARPROT),
        .m_axi_arqos(auto_cc_to_s01_couplers_ARQOS),
        .m_axi_arready(auto_cc_to_s01_couplers_ARREADY),
        .m_axi_arsize(auto_cc_to_s01_couplers_ARSIZE),
        .m_axi_arvalid(auto_cc_to_s01_couplers_ARVALID),
        .m_axi_rdata(auto_cc_to_s01_couplers_RDATA),
        .m_axi_rlast(auto_cc_to_s01_couplers_RLAST),
        .m_axi_rready(auto_cc_to_s01_couplers_RREADY),
        .m_axi_rresp(auto_cc_to_s01_couplers_RRESP),
        .m_axi_rvalid(auto_cc_to_s01_couplers_RVALID),
        .s_axi_aclk(S_ACLK_1),
        .s_axi_araddr(s01_couplers_to_auto_cc_ARADDR),
        .s_axi_arburst(s01_couplers_to_auto_cc_ARBURST),
        .s_axi_arcache(s01_couplers_to_auto_cc_ARCACHE),
        .s_axi_aresetn(S_ARESETN_1),
        .s_axi_arlen(s01_couplers_to_auto_cc_ARLEN),
        .s_axi_arlock(1'b0),
        .s_axi_arprot(s01_couplers_to_auto_cc_ARPROT),
        .s_axi_arqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(s01_couplers_to_auto_cc_ARREADY),
        .s_axi_arregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arsize(s01_couplers_to_auto_cc_ARSIZE),
        .s_axi_arvalid(s01_couplers_to_auto_cc_ARVALID),
        .s_axi_rdata(s01_couplers_to_auto_cc_RDATA),
        .s_axi_rlast(s01_couplers_to_auto_cc_RLAST),
        .s_axi_rready(s01_couplers_to_auto_cc_RREADY),
        .s_axi_rresp(s01_couplers_to_auto_cc_RRESP),
        .s_axi_rvalid(s01_couplers_to_auto_cc_RVALID));
endmodule

module s02_couplers_imp_UVXHKY
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_rdata,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arlen,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_rdata,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [7:0]M_AXI_arlen;
  output [0:0]M_AXI_arlock;
  output [2:0]M_AXI_arprot;
  output [3:0]M_AXI_arqos;
  input M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output M_AXI_arvalid;
  input [63:0]M_AXI_rdata;
  input M_AXI_rlast;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [7:0]S_AXI_arlen;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  output [31:0]S_AXI_rdata;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_us_to_s02_couplers_ARADDR;
  wire [1:0]auto_us_to_s02_couplers_ARBURST;
  wire [3:0]auto_us_to_s02_couplers_ARCACHE;
  wire [7:0]auto_us_to_s02_couplers_ARLEN;
  wire [0:0]auto_us_to_s02_couplers_ARLOCK;
  wire [2:0]auto_us_to_s02_couplers_ARPROT;
  wire [3:0]auto_us_to_s02_couplers_ARQOS;
  wire auto_us_to_s02_couplers_ARREADY;
  wire [2:0]auto_us_to_s02_couplers_ARSIZE;
  wire auto_us_to_s02_couplers_ARVALID;
  wire [63:0]auto_us_to_s02_couplers_RDATA;
  wire auto_us_to_s02_couplers_RLAST;
  wire auto_us_to_s02_couplers_RREADY;
  wire [1:0]auto_us_to_s02_couplers_RRESP;
  wire auto_us_to_s02_couplers_RVALID;
  wire [31:0]s02_couplers_to_auto_us_ARADDR;
  wire [1:0]s02_couplers_to_auto_us_ARBURST;
  wire [3:0]s02_couplers_to_auto_us_ARCACHE;
  wire [7:0]s02_couplers_to_auto_us_ARLEN;
  wire [2:0]s02_couplers_to_auto_us_ARPROT;
  wire s02_couplers_to_auto_us_ARREADY;
  wire [2:0]s02_couplers_to_auto_us_ARSIZE;
  wire s02_couplers_to_auto_us_ARVALID;
  wire [31:0]s02_couplers_to_auto_us_RDATA;
  wire s02_couplers_to_auto_us_RLAST;
  wire s02_couplers_to_auto_us_RREADY;
  wire [1:0]s02_couplers_to_auto_us_RRESP;
  wire s02_couplers_to_auto_us_RVALID;

  assign M_AXI_araddr[31:0] = auto_us_to_s02_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = auto_us_to_s02_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = auto_us_to_s02_couplers_ARCACHE;
  assign M_AXI_arlen[7:0] = auto_us_to_s02_couplers_ARLEN;
  assign M_AXI_arlock[0] = auto_us_to_s02_couplers_ARLOCK;
  assign M_AXI_arprot[2:0] = auto_us_to_s02_couplers_ARPROT;
  assign M_AXI_arqos[3:0] = auto_us_to_s02_couplers_ARQOS;
  assign M_AXI_arsize[2:0] = auto_us_to_s02_couplers_ARSIZE;
  assign M_AXI_arvalid = auto_us_to_s02_couplers_ARVALID;
  assign M_AXI_rready = auto_us_to_s02_couplers_RREADY;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = s02_couplers_to_auto_us_ARREADY;
  assign S_AXI_rdata[31:0] = s02_couplers_to_auto_us_RDATA;
  assign S_AXI_rlast = s02_couplers_to_auto_us_RLAST;
  assign S_AXI_rresp[1:0] = s02_couplers_to_auto_us_RRESP;
  assign S_AXI_rvalid = s02_couplers_to_auto_us_RVALID;
  assign auto_us_to_s02_couplers_ARREADY = M_AXI_arready;
  assign auto_us_to_s02_couplers_RDATA = M_AXI_rdata[63:0];
  assign auto_us_to_s02_couplers_RLAST = M_AXI_rlast;
  assign auto_us_to_s02_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_us_to_s02_couplers_RVALID = M_AXI_rvalid;
  assign s02_couplers_to_auto_us_ARADDR = S_AXI_araddr[31:0];
  assign s02_couplers_to_auto_us_ARBURST = S_AXI_arburst[1:0];
  assign s02_couplers_to_auto_us_ARCACHE = S_AXI_arcache[3:0];
  assign s02_couplers_to_auto_us_ARLEN = S_AXI_arlen[7:0];
  assign s02_couplers_to_auto_us_ARPROT = S_AXI_arprot[2:0];
  assign s02_couplers_to_auto_us_ARSIZE = S_AXI_arsize[2:0];
  assign s02_couplers_to_auto_us_ARVALID = S_AXI_arvalid;
  assign s02_couplers_to_auto_us_RREADY = S_AXI_rready;
  av_system_auto_us_2 auto_us
       (.m_axi_araddr(auto_us_to_s02_couplers_ARADDR),
        .m_axi_arburst(auto_us_to_s02_couplers_ARBURST),
        .m_axi_arcache(auto_us_to_s02_couplers_ARCACHE),
        .m_axi_arlen(auto_us_to_s02_couplers_ARLEN),
        .m_axi_arlock(auto_us_to_s02_couplers_ARLOCK),
        .m_axi_arprot(auto_us_to_s02_couplers_ARPROT),
        .m_axi_arqos(auto_us_to_s02_couplers_ARQOS),
        .m_axi_arready(auto_us_to_s02_couplers_ARREADY),
        .m_axi_arsize(auto_us_to_s02_couplers_ARSIZE),
        .m_axi_arvalid(auto_us_to_s02_couplers_ARVALID),
        .m_axi_rdata(auto_us_to_s02_couplers_RDATA),
        .m_axi_rlast(auto_us_to_s02_couplers_RLAST),
        .m_axi_rready(auto_us_to_s02_couplers_RREADY),
        .m_axi_rresp(auto_us_to_s02_couplers_RRESP),
        .m_axi_rvalid(auto_us_to_s02_couplers_RVALID),
        .s_axi_aclk(S_ACLK_1),
        .s_axi_araddr(s02_couplers_to_auto_us_ARADDR),
        .s_axi_arburst(s02_couplers_to_auto_us_ARBURST),
        .s_axi_arcache(s02_couplers_to_auto_us_ARCACHE),
        .s_axi_aresetn(S_ARESETN_1),
        .s_axi_arlen(s02_couplers_to_auto_us_ARLEN),
        .s_axi_arlock(1'b0),
        .s_axi_arprot(s02_couplers_to_auto_us_ARPROT),
        .s_axi_arqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(s02_couplers_to_auto_us_ARREADY),
        .s_axi_arregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arsize(s02_couplers_to_auto_us_ARSIZE),
        .s_axi_arvalid(s02_couplers_to_auto_us_ARVALID),
        .s_axi_rdata(s02_couplers_to_auto_us_RDATA),
        .s_axi_rlast(s02_couplers_to_auto_us_RLAST),
        .s_axi_rready(s02_couplers_to_auto_us_RREADY),
        .s_axi_rresp(s02_couplers_to_auto_us_RRESP),
        .s_axi_rvalid(s02_couplers_to_auto_us_RVALID));
endmodule

module s03_couplers_imp_1F8WSUY
   (M_ACLK,
    M_ARESETN,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_wdata,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awlen,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [7:0]M_AXI_awlen;
  output [0:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  output [63:0]M_AXI_wdata;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [7:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [7:0]S_AXI_awlen;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  input [31:0]S_AXI_wdata;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_us_to_s03_couplers_AWADDR;
  wire [1:0]auto_us_to_s03_couplers_AWBURST;
  wire [3:0]auto_us_to_s03_couplers_AWCACHE;
  wire [7:0]auto_us_to_s03_couplers_AWLEN;
  wire [0:0]auto_us_to_s03_couplers_AWLOCK;
  wire [2:0]auto_us_to_s03_couplers_AWPROT;
  wire [3:0]auto_us_to_s03_couplers_AWQOS;
  wire auto_us_to_s03_couplers_AWREADY;
  wire [2:0]auto_us_to_s03_couplers_AWSIZE;
  wire auto_us_to_s03_couplers_AWVALID;
  wire auto_us_to_s03_couplers_BREADY;
  wire [1:0]auto_us_to_s03_couplers_BRESP;
  wire auto_us_to_s03_couplers_BVALID;
  wire [63:0]auto_us_to_s03_couplers_WDATA;
  wire auto_us_to_s03_couplers_WLAST;
  wire auto_us_to_s03_couplers_WREADY;
  wire [7:0]auto_us_to_s03_couplers_WSTRB;
  wire auto_us_to_s03_couplers_WVALID;
  wire [31:0]s03_couplers_to_auto_us_AWADDR;
  wire [1:0]s03_couplers_to_auto_us_AWBURST;
  wire [3:0]s03_couplers_to_auto_us_AWCACHE;
  wire [7:0]s03_couplers_to_auto_us_AWLEN;
  wire [2:0]s03_couplers_to_auto_us_AWPROT;
  wire s03_couplers_to_auto_us_AWREADY;
  wire [2:0]s03_couplers_to_auto_us_AWSIZE;
  wire s03_couplers_to_auto_us_AWVALID;
  wire s03_couplers_to_auto_us_BREADY;
  wire [1:0]s03_couplers_to_auto_us_BRESP;
  wire s03_couplers_to_auto_us_BVALID;
  wire [31:0]s03_couplers_to_auto_us_WDATA;
  wire s03_couplers_to_auto_us_WLAST;
  wire s03_couplers_to_auto_us_WREADY;
  wire [3:0]s03_couplers_to_auto_us_WSTRB;
  wire s03_couplers_to_auto_us_WVALID;

  assign M_AXI_awaddr[31:0] = auto_us_to_s03_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = auto_us_to_s03_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = auto_us_to_s03_couplers_AWCACHE;
  assign M_AXI_awlen[7:0] = auto_us_to_s03_couplers_AWLEN;
  assign M_AXI_awlock[0] = auto_us_to_s03_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = auto_us_to_s03_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = auto_us_to_s03_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = auto_us_to_s03_couplers_AWSIZE;
  assign M_AXI_awvalid = auto_us_to_s03_couplers_AWVALID;
  assign M_AXI_bready = auto_us_to_s03_couplers_BREADY;
  assign M_AXI_wdata[63:0] = auto_us_to_s03_couplers_WDATA;
  assign M_AXI_wlast = auto_us_to_s03_couplers_WLAST;
  assign M_AXI_wstrb[7:0] = auto_us_to_s03_couplers_WSTRB;
  assign M_AXI_wvalid = auto_us_to_s03_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_awready = s03_couplers_to_auto_us_AWREADY;
  assign S_AXI_bresp[1:0] = s03_couplers_to_auto_us_BRESP;
  assign S_AXI_bvalid = s03_couplers_to_auto_us_BVALID;
  assign S_AXI_wready = s03_couplers_to_auto_us_WREADY;
  assign auto_us_to_s03_couplers_AWREADY = M_AXI_awready;
  assign auto_us_to_s03_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_us_to_s03_couplers_BVALID = M_AXI_bvalid;
  assign auto_us_to_s03_couplers_WREADY = M_AXI_wready;
  assign s03_couplers_to_auto_us_AWADDR = S_AXI_awaddr[31:0];
  assign s03_couplers_to_auto_us_AWBURST = S_AXI_awburst[1:0];
  assign s03_couplers_to_auto_us_AWCACHE = S_AXI_awcache[3:0];
  assign s03_couplers_to_auto_us_AWLEN = S_AXI_awlen[7:0];
  assign s03_couplers_to_auto_us_AWPROT = S_AXI_awprot[2:0];
  assign s03_couplers_to_auto_us_AWSIZE = S_AXI_awsize[2:0];
  assign s03_couplers_to_auto_us_AWVALID = S_AXI_awvalid;
  assign s03_couplers_to_auto_us_BREADY = S_AXI_bready;
  assign s03_couplers_to_auto_us_WDATA = S_AXI_wdata[31:0];
  assign s03_couplers_to_auto_us_WLAST = S_AXI_wlast;
  assign s03_couplers_to_auto_us_WSTRB = S_AXI_wstrb[3:0];
  assign s03_couplers_to_auto_us_WVALID = S_AXI_wvalid;
  av_system_auto_us_3 auto_us
       (.m_axi_awaddr(auto_us_to_s03_couplers_AWADDR),
        .m_axi_awburst(auto_us_to_s03_couplers_AWBURST),
        .m_axi_awcache(auto_us_to_s03_couplers_AWCACHE),
        .m_axi_awlen(auto_us_to_s03_couplers_AWLEN),
        .m_axi_awlock(auto_us_to_s03_couplers_AWLOCK),
        .m_axi_awprot(auto_us_to_s03_couplers_AWPROT),
        .m_axi_awqos(auto_us_to_s03_couplers_AWQOS),
        .m_axi_awready(auto_us_to_s03_couplers_AWREADY),
        .m_axi_awsize(auto_us_to_s03_couplers_AWSIZE),
        .m_axi_awvalid(auto_us_to_s03_couplers_AWVALID),
        .m_axi_bready(auto_us_to_s03_couplers_BREADY),
        .m_axi_bresp(auto_us_to_s03_couplers_BRESP),
        .m_axi_bvalid(auto_us_to_s03_couplers_BVALID),
        .m_axi_wdata(auto_us_to_s03_couplers_WDATA),
        .m_axi_wlast(auto_us_to_s03_couplers_WLAST),
        .m_axi_wready(auto_us_to_s03_couplers_WREADY),
        .m_axi_wstrb(auto_us_to_s03_couplers_WSTRB),
        .m_axi_wvalid(auto_us_to_s03_couplers_WVALID),
        .s_axi_aclk(S_ACLK_1),
        .s_axi_aresetn(S_ARESETN_1),
        .s_axi_awaddr(s03_couplers_to_auto_us_AWADDR),
        .s_axi_awburst(s03_couplers_to_auto_us_AWBURST),
        .s_axi_awcache(s03_couplers_to_auto_us_AWCACHE),
        .s_axi_awlen(s03_couplers_to_auto_us_AWLEN),
        .s_axi_awlock(1'b0),
        .s_axi_awprot(s03_couplers_to_auto_us_AWPROT),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(s03_couplers_to_auto_us_AWREADY),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize(s03_couplers_to_auto_us_AWSIZE),
        .s_axi_awvalid(s03_couplers_to_auto_us_AWVALID),
        .s_axi_bready(s03_couplers_to_auto_us_BREADY),
        .s_axi_bresp(s03_couplers_to_auto_us_BRESP),
        .s_axi_bvalid(s03_couplers_to_auto_us_BVALID),
        .s_axi_wdata(s03_couplers_to_auto_us_WDATA),
        .s_axi_wlast(s03_couplers_to_auto_us_WLAST),
        .s_axi_wready(s03_couplers_to_auto_us_WREADY),
        .s_axi_wstrb(s03_couplers_to_auto_us_WSTRB),
        .s_axi_wvalid(s03_couplers_to_auto_us_WVALID));
endmodule
