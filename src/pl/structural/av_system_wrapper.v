//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
//Date        : Tue Oct 27 11:21:17 2026
//Command     : generate_target av_system_wrapper.bd
//Design      : av_system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module av_system_wrapper
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
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  input [3:0]board_keys_n;
  input [7:0]cam_d;
  input cam_href;
  input cam_pclk;
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

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [3:0]board_keys_n;
  wire [7:0]cam_d;
  wire cam_href;
  wire cam_pclk;
  wire cam_pwdn;
  wire cam_reset_n;
  wire cam_scl;
  wire cam_sda;
  wire cam_vsync;
  wire enhance_led_n;
  wire hdmi_clk_n;
  wire hdmi_clk_p;
  wire [2:0]hdmi_data_n;
  wire [2:0]hdmi_data_p;
  wire hdmi_hpd;
  wire hdmi_out_en;
  wire mic_sck;
  wire mic_sd_0;
  wire mic_sd_1;
  wire mic_sd_2;
  wire mic_sd_3;
  wire mic_ws;
  wire servo_pan;
  wire servo_tilt;

  av_system av_system_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .board_keys_n(board_keys_n),
        .cam_d(cam_d),
        .cam_href(cam_href),
        .cam_pclk(cam_pclk),
        .cam_pwdn(cam_pwdn),
        .cam_reset_n(cam_reset_n),
        .cam_scl(cam_scl),
        .cam_sda(cam_sda),
        .cam_vsync(cam_vsync),
        .enhance_led_n(enhance_led_n),
        .hdmi_clk_n(hdmi_clk_n),
        .hdmi_clk_p(hdmi_clk_p),
        .hdmi_data_n(hdmi_data_n),
        .hdmi_data_p(hdmi_data_p),
        .hdmi_hpd(hdmi_hpd),
        .hdmi_out_en(hdmi_out_en),
        .mic_sck(mic_sck),
        .mic_sd_0(mic_sd_0),
        .mic_sd_1(mic_sd_1),
        .mic_sd_2(mic_sd_2),
        .mic_sd_3(mic_sd_3),
        .mic_ws(mic_ws),
        .servo_pan(servo_pan),
        .servo_tilt(servo_tilt));
endmodule
