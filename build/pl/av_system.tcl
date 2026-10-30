# Proc to create BD av_system
proc cr_bd_av_system { parentCell } {
# The design that will be created by this Tcl proc contains the following 
# module references:
# camera_pipeline_top, audio_control_top, gamma_event_cdc, av_status_cdc, camera_ctrl_io, camera_input_probe, model_ingress_stub, mnet_engine_rtl, logmel_axis_wrap, ssd_axis_wrap, rgb565_axis, hdmi_raster, hdmi_status_cdc, board_osd



  # CHANGE DESIGN NAME HERE
  set design_name av_system

  common::send_gid_msg -ssname BD::TCL -id 2010 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:processing_system7:5.5\
  xilinx.com:ip:clk_wiz:6.0\
  xilinx.com:ip:xlconstant:1.1\
  xilinx.com:ip:proc_sys_reset:5.0\
  xilinx.com:ip:axi_vdma:6.3\
  xilinx.com:ip:axis_clock_converter:1.1\
  xilinx.com:ip:axi_dma:7.1\
  xilinx.com:ip:axi_clock_converter:2.1\
  xilinx.com:ip:axi_gpio:2.0\
  xilinx.com:ip:axi_protocol_converter:2.1\
  xilinx.com:ip:axi_dwidth_converter:2.1\
  xilinx.com:ip:xlconcat:2.1\
  xilinx.com:ip:v_axi4s_vid_out:4.0\
  digilentinc.com:ip:rgb2dvi:1.4\
  "

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

  }

  ##################################################################
  # CHECK Modules
  ##################################################################
  set bCheckModules 1
  if { $bCheckModules == 1 } {
     set list_check_mods "\ 
  camera_pipeline_top\
  audio_control_top\
  gamma_event_cdc\
  av_status_cdc\
  camera_ctrl_io\
  camera_input_probe\
  model_ingress_stub\
  mnet_engine_rtl\
  logmel_axis_wrap\
  ssd_axis_wrap\
  rgb565_axis\
  hdmi_raster\
  hdmi_status_cdc\
  board_osd\
  "

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

  if { $bCheckIPsPassed != 1 } {
    common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 3
  }

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]

  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]


  # Create ports
  set cam_pclk [ create_bd_port -dir I -type clk -freq_hz 84000000 cam_pclk ]
  set cam_vsync [ create_bd_port -dir I cam_vsync ]
  set cam_href [ create_bd_port -dir I cam_href ]
  set cam_d [ create_bd_port -dir I -from 7 -to 0 cam_d ]
  set mic_sd_0 [ create_bd_port -dir I mic_sd_0 ]
  set mic_sd_1 [ create_bd_port -dir I mic_sd_1 ]
  set mic_sd_2 [ create_bd_port -dir I mic_sd_2 ]
  set mic_sd_3 [ create_bd_port -dir I mic_sd_3 ]
  set mic_sck [ create_bd_port -dir O mic_sck ]
  set mic_ws [ create_bd_port -dir O mic_ws ]
  set cam_scl [ create_bd_port -dir IO cam_scl ]
  set cam_sda [ create_bd_port -dir IO cam_sda ]
  set cam_reset_n [ create_bd_port -dir O cam_reset_n ]
  set cam_pwdn [ create_bd_port -dir O cam_pwdn ]
  set enhance_led_n [ create_bd_port -dir O enhance_led_n ]
  set servo_pan [ create_bd_port -dir O servo_pan ]
  set servo_tilt [ create_bd_port -dir O servo_tilt ]
  set hdmi_clk_p [ create_bd_port -dir O hdmi_clk_p ]
  set hdmi_clk_n [ create_bd_port -dir O hdmi_clk_n ]
  set hdmi_data_p [ create_bd_port -dir O -from 2 -to 0 hdmi_data_p ]
  set hdmi_data_n [ create_bd_port -dir O -from 2 -to 0 hdmi_data_n ]
  set hdmi_out_en [ create_bd_port -dir O hdmi_out_en ]
  set hdmi_hpd [ create_bd_port -dir I hdmi_hpd ]
  set board_keys_n [ create_bd_port -dir I -from 3 -to 0 board_keys_n ]

  # Create instance: ps7, and set properties
  set ps7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7 ]
  set_property -dict [list \
    CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
    CONFIG.PCW_ACT_CAN0_PERIPHERAL_FREQMHZ {23.8095} \
    CONFIG.PCW_ACT_CAN1_PERIPHERAL_FREQMHZ {23.8095} \
    CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
    CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
    CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
    CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_I2C_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
    CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
    CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {100.000000} \
    CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {10.000000} \
    CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
    CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_ACT_TTC_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
    CONFIG.PCW_ACT_USB0_PERIPHERAL_FREQMHZ {60} \
    CONFIG.PCW_ACT_USB1_PERIPHERAL_FREQMHZ {60} \
    CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
    CONFIG.PCW_APU_CLK_RATIO_ENABLE {6:2:1} \
    CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666666} \
    CONFIG.PCW_CAN0_PERIPHERAL_CLKSRC {External} \
    CONFIG.PCW_CAN0_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_CAN1_PERIPHERAL_CLKSRC {External} \
    CONFIG.PCW_CAN1_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_CAN_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_CAN_PERIPHERAL_VALID {0} \
    CONFIG.PCW_CLK0_FREQ {100000000} \
    CONFIG.PCW_CLK1_FREQ {10000000} \
    CONFIG.PCW_CLK2_FREQ {10000000} \
    CONFIG.PCW_CLK3_FREQ {10000000} \
    CONFIG.PCW_CORE0_FIQ_INTR {0} \
    CONFIG.PCW_CORE0_IRQ_INTR {0} \
    CONFIG.PCW_CORE1_FIQ_INTR {0} \
    CONFIG.PCW_CORE1_IRQ_INTR {0} \
    CONFIG.PCW_CPU_CPU_6X4X_MAX_RANGE {767} \
    CONFIG.PCW_CPU_PERIPHERAL_CLKSRC {ARM PLL} \
    CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {33.333333} \
    CONFIG.PCW_DCI_PERIPHERAL_CLKSRC {DDR PLL} \
    CONFIG.PCW_DCI_PERIPHERAL_FREQMHZ {10.159} \
    CONFIG.PCW_DDR_PERIPHERAL_CLKSRC {DDR PLL} \
    CONFIG.PCW_DDR_RAM_BASEADDR {0x00100000} \
    CONFIG.PCW_DDR_RAM_HIGHADDR {0x3FFFFFFF} \
    CONFIG.PCW_DM_WIDTH {4} \
    CONFIG.PCW_DQS_WIDTH {4} \
    CONFIG.PCW_DQ_WIDTH {32} \
    CONFIG.PCW_ENET0_BASEADDR {0xE000B000} \
    CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
    CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
    CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
    CONFIG.PCW_ENET0_HIGHADDR {0xE000BFFF} \
    CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
    CONFIG.PCW_ENET0_RESET_ENABLE {0} \
    CONFIG.PCW_ENET1_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_ENET1_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_ENET_RESET_ENABLE {1} \
    CONFIG.PCW_ENET_RESET_POLARITY {Active Low} \
    CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} \
    CONFIG.PCW_EN_4K_TIMER {0} \
    CONFIG.PCW_EN_CAN0 {0} \
    CONFIG.PCW_EN_CAN1 {0} \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_EN_CLK1_PORT {0} \
    CONFIG.PCW_EN_CLK2_PORT {0} \
    CONFIG.PCW_EN_CLK3_PORT {0} \
    CONFIG.PCW_EN_CLKTRIG0_PORT {0} \
    CONFIG.PCW_EN_CLKTRIG1_PORT {0} \
    CONFIG.PCW_EN_CLKTRIG2_PORT {0} \
    CONFIG.PCW_EN_CLKTRIG3_PORT {0} \
    CONFIG.PCW_EN_DDR {1} \
    CONFIG.PCW_EN_EMIO_CAN0 {0} \
    CONFIG.PCW_EN_EMIO_CAN1 {0} \
    CONFIG.PCW_EN_EMIO_CD_SDIO0 {0} \
    CONFIG.PCW_EN_EMIO_CD_SDIO1 {0} \
    CONFIG.PCW_EN_EMIO_ENET0 {0} \
    CONFIG.PCW_EN_EMIO_ENET1 {0} \
    CONFIG.PCW_EN_EMIO_GPIO {0} \
    CONFIG.PCW_EN_EMIO_I2C0 {0} \
    CONFIG.PCW_EN_EMIO_I2C1 {0} \
    CONFIG.PCW_EN_EMIO_MODEM_UART0 {0} \
    CONFIG.PCW_EN_EMIO_MODEM_UART1 {0} \
    CONFIG.PCW_EN_EMIO_PJTAG {0} \
    CONFIG.PCW_EN_EMIO_SDIO0 {0} \
    CONFIG.PCW_EN_EMIO_SDIO1 {0} \
    CONFIG.PCW_EN_EMIO_SPI0 {0} \
    CONFIG.PCW_EN_EMIO_SPI1 {0} \
    CONFIG.PCW_EN_EMIO_SRAM_INT {0} \
    CONFIG.PCW_EN_EMIO_TRACE {0} \
    CONFIG.PCW_EN_EMIO_TTC0 {0} \
    CONFIG.PCW_EN_EMIO_TTC1 {0} \
    CONFIG.PCW_EN_EMIO_UART0 {0} \
    CONFIG.PCW_EN_EMIO_UART1 {0} \
    CONFIG.PCW_EN_EMIO_WDT {0} \
    CONFIG.PCW_EN_EMIO_WP_SDIO0 {0} \
    CONFIG.PCW_EN_EMIO_WP_SDIO1 {0} \
    CONFIG.PCW_EN_ENET0 {1} \
    CONFIG.PCW_EN_ENET1 {0} \
    CONFIG.PCW_EN_GPIO {1} \
    CONFIG.PCW_EN_I2C0 {0} \
    CONFIG.PCW_EN_I2C1 {0} \
    CONFIG.PCW_EN_MODEM_UART0 {0} \
    CONFIG.PCW_EN_MODEM_UART1 {0} \
    CONFIG.PCW_EN_PJTAG {0} \
    CONFIG.PCW_EN_PTP_ENET0 {0} \
    CONFIG.PCW_EN_PTP_ENET1 {0} \
    CONFIG.PCW_EN_QSPI {1} \
    CONFIG.PCW_EN_RST0_PORT {1} \
    CONFIG.PCW_EN_RST1_PORT {0} \
    CONFIG.PCW_EN_RST2_PORT {0} \
    CONFIG.PCW_EN_RST3_PORT {0} \
    CONFIG.PCW_EN_SDIO0 {1} \
    CONFIG.PCW_EN_SDIO1 {0} \
    CONFIG.PCW_EN_SMC {0} \
    CONFIG.PCW_EN_SPI0 {0} \
    CONFIG.PCW_EN_SPI1 {0} \
    CONFIG.PCW_EN_TRACE {0} \
    CONFIG.PCW_EN_TTC0 {0} \
    CONFIG.PCW_EN_TTC1 {0} \
    CONFIG.PCW_EN_UART0 {0} \
    CONFIG.PCW_EN_UART1 {1} \
    CONFIG.PCW_EN_USB0 {1} \
    CONFIG.PCW_EN_USB1 {0} \
    CONFIG.PCW_EN_WDT {0} \
    CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_FCLK_CLK0_BUF {TRUE} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
    CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
    CONFIG.PCW_GP0_EN_MODIFIABLE_TXN {1} \
    CONFIG.PCW_GP0_NUM_READ_THREADS {4} \
    CONFIG.PCW_GP0_NUM_WRITE_THREADS {4} \
    CONFIG.PCW_GP1_EN_MODIFIABLE_TXN {1} \
    CONFIG.PCW_GP1_NUM_READ_THREADS {4} \
    CONFIG.PCW_GP1_NUM_WRITE_THREADS {4} \
    CONFIG.PCW_GPIO_BASEADDR {0xE000A000} \
    CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {0} \
    CONFIG.PCW_GPIO_HIGHADDR {0xE000AFFF} \
    CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
    CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO} \
    CONFIG.PCW_GPIO_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_I2C_RESET_ENABLE {1} \
    CONFIG.PCW_I2C_RESET_POLARITY {Active Low} \
    CONFIG.PCW_IMPORT_BOARD_PRESET {None} \
    CONFIG.PCW_INCLUDE_ACP_TRANS_CHECK {0} \
    CONFIG.PCW_IRQ_F2P_INTR {1} \
    CONFIG.PCW_IRQ_F2P_MODE {DIRECT} \
    CONFIG.PCW_MIO_0_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_0_PULLUP {enabled} \
    CONFIG.PCW_MIO_0_SLEW {slow} \
    CONFIG.PCW_MIO_10_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_10_PULLUP {enabled} \
    CONFIG.PCW_MIO_10_SLEW {slow} \
    CONFIG.PCW_MIO_11_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_11_PULLUP {enabled} \
    CONFIG.PCW_MIO_11_SLEW {slow} \
    CONFIG.PCW_MIO_12_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_12_PULLUP {enabled} \
    CONFIG.PCW_MIO_12_SLEW {slow} \
    CONFIG.PCW_MIO_13_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_13_PULLUP {enabled} \
    CONFIG.PCW_MIO_13_SLEW {slow} \
    CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_14_PULLUP {enabled} \
    CONFIG.PCW_MIO_14_SLEW {slow} \
    CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_15_PULLUP {enabled} \
    CONFIG.PCW_MIO_15_SLEW {slow} \
    CONFIG.PCW_MIO_16_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_16_PULLUP {enabled} \
    CONFIG.PCW_MIO_16_SLEW {fast} \
    CONFIG.PCW_MIO_17_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_17_PULLUP {enabled} \
    CONFIG.PCW_MIO_17_SLEW {fast} \
    CONFIG.PCW_MIO_18_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_18_PULLUP {enabled} \
    CONFIG.PCW_MIO_18_SLEW {fast} \
    CONFIG.PCW_MIO_19_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_19_PULLUP {enabled} \
    CONFIG.PCW_MIO_19_SLEW {fast} \
    CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_1_PULLUP {enabled} \
    CONFIG.PCW_MIO_1_SLEW {slow} \
    CONFIG.PCW_MIO_20_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_20_PULLUP {enabled} \
    CONFIG.PCW_MIO_20_SLEW {fast} \
    CONFIG.PCW_MIO_21_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_21_PULLUP {enabled} \
    CONFIG.PCW_MIO_21_SLEW {fast} \
    CONFIG.PCW_MIO_22_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_22_PULLUP {enabled} \
    CONFIG.PCW_MIO_22_SLEW {fast} \
    CONFIG.PCW_MIO_23_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_23_PULLUP {enabled} \
    CONFIG.PCW_MIO_23_SLEW {fast} \
    CONFIG.PCW_MIO_24_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_24_PULLUP {enabled} \
    CONFIG.PCW_MIO_24_SLEW {fast} \
    CONFIG.PCW_MIO_25_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_25_PULLUP {enabled} \
    CONFIG.PCW_MIO_25_SLEW {fast} \
    CONFIG.PCW_MIO_26_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_26_PULLUP {enabled} \
    CONFIG.PCW_MIO_26_SLEW {fast} \
    CONFIG.PCW_MIO_27_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_27_PULLUP {enabled} \
    CONFIG.PCW_MIO_27_SLEW {fast} \
    CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_28_PULLUP {enabled} \
    CONFIG.PCW_MIO_28_SLEW {slow} \
    CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_29_PULLUP {enabled} \
    CONFIG.PCW_MIO_29_SLEW {slow} \
    CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_2_SLEW {slow} \
    CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_30_PULLUP {enabled} \
    CONFIG.PCW_MIO_30_SLEW {slow} \
    CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_31_PULLUP {enabled} \
    CONFIG.PCW_MIO_31_SLEW {slow} \
    CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_32_PULLUP {enabled} \
    CONFIG.PCW_MIO_32_SLEW {slow} \
    CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_33_PULLUP {enabled} \
    CONFIG.PCW_MIO_33_SLEW {slow} \
    CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_34_PULLUP {enabled} \
    CONFIG.PCW_MIO_34_SLEW {slow} \
    CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_35_PULLUP {enabled} \
    CONFIG.PCW_MIO_35_SLEW {slow} \
    CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_36_PULLUP {enabled} \
    CONFIG.PCW_MIO_36_SLEW {slow} \
    CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_37_PULLUP {enabled} \
    CONFIG.PCW_MIO_37_SLEW {slow} \
    CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_38_PULLUP {enabled} \
    CONFIG.PCW_MIO_38_SLEW {slow} \
    CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_39_PULLUP {enabled} \
    CONFIG.PCW_MIO_39_SLEW {slow} \
    CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_3_SLEW {slow} \
    CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_40_PULLUP {enabled} \
    CONFIG.PCW_MIO_40_SLEW {slow} \
    CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_41_PULLUP {enabled} \
    CONFIG.PCW_MIO_41_SLEW {slow} \
    CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_42_PULLUP {enabled} \
    CONFIG.PCW_MIO_42_SLEW {slow} \
    CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_43_PULLUP {enabled} \
    CONFIG.PCW_MIO_43_SLEW {slow} \
    CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_44_PULLUP {enabled} \
    CONFIG.PCW_MIO_44_SLEW {slow} \
    CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_45_PULLUP {enabled} \
    CONFIG.PCW_MIO_45_SLEW {slow} \
    CONFIG.PCW_MIO_46_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_46_PULLUP {enabled} \
    CONFIG.PCW_MIO_46_SLEW {slow} \
    CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_47_PULLUP {enabled} \
    CONFIG.PCW_MIO_47_SLEW {slow} \
    CONFIG.PCW_MIO_48_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_48_PULLUP {enabled} \
    CONFIG.PCW_MIO_48_SLEW {slow} \
    CONFIG.PCW_MIO_49_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_49_PULLUP {enabled} \
    CONFIG.PCW_MIO_49_SLEW {slow} \
    CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_4_SLEW {slow} \
    CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_50_PULLUP {enabled} \
    CONFIG.PCW_MIO_50_SLEW {slow} \
    CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 1.8V} \
    CONFIG.PCW_MIO_51_PULLUP {enabled} \
    CONFIG.PCW_MIO_51_SLEW {slow} \
    CONFIG.PCW_MIO_52_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_52_PULLUP {enabled} \
    CONFIG.PCW_MIO_52_SLEW {fast} \
    CONFIG.PCW_MIO_53_IOTYPE {HSTL 1.8V} \
    CONFIG.PCW_MIO_53_PULLUP {enabled} \
    CONFIG.PCW_MIO_53_SLEW {fast} \
    CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_5_SLEW {slow} \
    CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_6_SLEW {slow} \
    CONFIG.PCW_MIO_7_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_7_SLEW {slow} \
    CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_8_SLEW {slow} \
    CONFIG.PCW_MIO_9_IOTYPE {LVCMOS 3.3V} \
    CONFIG.PCW_MIO_9_PULLUP {enabled} \
    CONFIG.PCW_MIO_9_SLEW {slow} \
    CONFIG.PCW_MIO_PRIMITIVE {54} \
    CONFIG.PCW_MIO_TREE_PERIPHERALS {GPIO#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#Enet 0#Enet 0#Enet 0#Enet\
0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#USB Reset#SD 0#UART 1#UART 1#GPIO#GPIO#Enet\
0#Enet 0} \
    CONFIG.PCW_MIO_TREE_SIGNALS {gpio[0]#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]/HOLD_B#qspi0_sclk#gpio[7]#gpio[8]#gpio[9]#gpio[10]#gpio[11]#gpio[12]#gpio[13]#gpio[14]#gpio[15]#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#reset#cd#tx#rx#gpio[50]#gpio[51]#mdc#mdio}\
\
    CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {0} \
    CONFIG.PCW_M_AXI_GP0_ID_WIDTH {12} \
    CONFIG.PCW_M_AXI_GP0_SUPPORT_NARROW_BURST {0} \
    CONFIG.PCW_M_AXI_GP0_THREAD_ID_WIDTH {12} \
    CONFIG.PCW_NAND_CYCLES_T_AR {1} \
    CONFIG.PCW_NAND_CYCLES_T_CLR {1} \
    CONFIG.PCW_NAND_CYCLES_T_RC {11} \
    CONFIG.PCW_NAND_CYCLES_T_REA {1} \
    CONFIG.PCW_NAND_CYCLES_T_RR {1} \
    CONFIG.PCW_NAND_CYCLES_T_WC {11} \
    CONFIG.PCW_NAND_CYCLES_T_WP {1} \
    CONFIG.PCW_NOR_CS0_T_CEOE {1} \
    CONFIG.PCW_NOR_CS0_T_PC {1} \
    CONFIG.PCW_NOR_CS0_T_RC {11} \
    CONFIG.PCW_NOR_CS0_T_TR {1} \
    CONFIG.PCW_NOR_CS0_T_WC {11} \
    CONFIG.PCW_NOR_CS0_T_WP {1} \
    CONFIG.PCW_NOR_CS0_WE_TIME {0} \
    CONFIG.PCW_NOR_CS1_T_CEOE {1} \
    CONFIG.PCW_NOR_CS1_T_PC {1} \
    CONFIG.PCW_NOR_CS1_T_RC {11} \
    CONFIG.PCW_NOR_CS1_T_TR {1} \
    CONFIG.PCW_NOR_CS1_T_WC {11} \
    CONFIG.PCW_NOR_CS1_T_WP {1} \
    CONFIG.PCW_NOR_CS1_WE_TIME {0} \
    CONFIG.PCW_NOR_SRAM_CS0_T_CEOE {1} \
    CONFIG.PCW_NOR_SRAM_CS0_T_PC {1} \
    CONFIG.PCW_NOR_SRAM_CS0_T_RC {11} \
    CONFIG.PCW_NOR_SRAM_CS0_T_TR {1} \
    CONFIG.PCW_NOR_SRAM_CS0_T_WC {11} \
    CONFIG.PCW_NOR_SRAM_CS0_T_WP {1} \
    CONFIG.PCW_NOR_SRAM_CS0_WE_TIME {0} \
    CONFIG.PCW_NOR_SRAM_CS1_T_CEOE {1} \
    CONFIG.PCW_NOR_SRAM_CS1_T_PC {1} \
    CONFIG.PCW_NOR_SRAM_CS1_T_RC {11} \
    CONFIG.PCW_NOR_SRAM_CS1_T_TR {1} \
    CONFIG.PCW_NOR_SRAM_CS1_T_WC {11} \
    CONFIG.PCW_NOR_SRAM_CS1_T_WP {1} \
    CONFIG.PCW_NOR_SRAM_CS1_WE_TIME {0} \
    CONFIG.PCW_OVERRIDE_BASIC_CLOCK {0} \
    CONFIG.PCW_P2F_ENET0_INTR {0} \
    CONFIG.PCW_P2F_GPIO_INTR {0} \
    CONFIG.PCW_P2F_QSPI_INTR {0} \
    CONFIG.PCW_P2F_SDIO0_INTR {0} \
    CONFIG.PCW_P2F_UART1_INTR {0} \
    CONFIG.PCW_P2F_USB0_INTR {0} \
    CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY0 {0.089} \
    CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY1 {0.075} \
    CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY2 {0.085} \
    CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY3 {0.092} \
    CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_0 {-0.025} \
    CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_1 {0.014} \
    CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_2 {-0.009} \
    CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_3 {-0.033} \
    CONFIG.PCW_PACKAGE_NAME {clg400} \
    CONFIG.PCW_PCAP_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_PCAP_PERIPHERAL_FREQMHZ {200} \
    CONFIG.PCW_PERIPHERAL_BOARD_PRESET {None} \
    CONFIG.PCW_PJTAG_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_PLL_BYPASSMODE_ENABLE {0} \
    CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
    CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
    CONFIG.PCW_PS7_SI_REV {PRODUCTION} \
    CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {0} \
    CONFIG.PCW_QSPI_GRP_IO1_ENABLE {0} \
    CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
    CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
    CONFIG.PCW_QSPI_GRP_SS1_ENABLE {0} \
    CONFIG.PCW_QSPI_INTERNAL_HIGHADDRESS {0xFCFFFFFF} \
    CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
    CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
    CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
    CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} \
    CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
    CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
    CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
    CONFIG.PCW_SD1_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_SDIO0_BASEADDR {0xE0100000} \
    CONFIG.PCW_SDIO0_HIGHADDR {0xE0100FFF} \
    CONFIG.PCW_SDIO_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
    CONFIG.PCW_SINGLE_QSPI_DATA_MODE {x4} \
    CONFIG.PCW_SMC_CYCLE_T0 {NA} \
    CONFIG.PCW_SMC_CYCLE_T1 {NA} \
    CONFIG.PCW_SMC_CYCLE_T2 {NA} \
    CONFIG.PCW_SMC_CYCLE_T3 {NA} \
    CONFIG.PCW_SMC_CYCLE_T4 {NA} \
    CONFIG.PCW_SMC_CYCLE_T5 {NA} \
    CONFIG.PCW_SMC_CYCLE_T6 {NA} \
    CONFIG.PCW_SMC_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_SMC_PERIPHERAL_VALID {0} \
    CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_SPI_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_SPI_PERIPHERAL_VALID {0} \
    CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} \
    CONFIG.PCW_S_AXI_HP0_ID_WIDTH {6} \
    CONFIG.PCW_S_AXI_HP1_DATA_WIDTH {64} \
    CONFIG.PCW_S_AXI_HP1_ID_WIDTH {6} \
    CONFIG.PCW_S_AXI_HP2_DATA_WIDTH {64} \
    CONFIG.PCW_S_AXI_HP2_ID_WIDTH {6} \
    CONFIG.PCW_S_AXI_HP3_DATA_WIDTH {64} \
    CONFIG.PCW_S_AXI_HP3_ID_WIDTH {6} \
    CONFIG.PCW_TPIU_PERIPHERAL_CLKSRC {External} \
    CONFIG.PCW_TRACE_INTERNAL_WIDTH {2} \
    CONFIG.PCW_TRACE_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_TTC0_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
    CONFIG.PCW_TTC0_CLK0_PERIPHERAL_DIVISOR0 {1} \
    CONFIG.PCW_TTC0_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
    CONFIG.PCW_TTC0_CLK1_PERIPHERAL_DIVISOR0 {1} \
    CONFIG.PCW_TTC0_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
    CONFIG.PCW_TTC0_CLK2_PERIPHERAL_DIVISOR0 {1} \
    CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_TTC1_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
    CONFIG.PCW_TTC1_CLK0_PERIPHERAL_DIVISOR0 {1} \
    CONFIG.PCW_TTC1_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
    CONFIG.PCW_TTC1_CLK1_PERIPHERAL_DIVISOR0 {1} \
    CONFIG.PCW_TTC1_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
    CONFIG.PCW_TTC1_CLK2_PERIPHERAL_DIVISOR0 {1} \
    CONFIG.PCW_TTC1_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_UART0_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_UART1_BASEADDR {0xE0001000} \
    CONFIG.PCW_UART1_BAUD_RATE {115200} \
    CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
    CONFIG.PCW_UART1_HIGHADDR {0xE0001FFF} \
    CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
    CONFIG.PCW_UART_PERIPHERAL_CLKSRC {IO PLL} \
    CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
    CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
    CONFIG.PCW_UIPARAM_DDR_ADV_ENABLE {0} \
    CONFIG.PCW_UIPARAM_DDR_AL {0} \
    CONFIG.PCW_UIPARAM_DDR_BL {8} \
    CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.25} \
    CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.25} \
    CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.25} \
    CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.25} \
    CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {32 Bit} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH {80.4535} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH {80.4535} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH {80.4535} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH {80.4535} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_CLOCK_STOP_EN {0} \
    CONFIG.PCW_UIPARAM_DDR_DQS_0_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH {105.056} \
    CONFIG.PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_DQS_1_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH {66.904} \
    CONFIG.PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_DQS_2_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH {89.1715} \
    CONFIG.PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_DQS_3_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH {113.63} \
    CONFIG.PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0.0} \
    CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0.0} \
    CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0.0} \
    CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0.0} \
    CONFIG.PCW_UIPARAM_DDR_DQ_0_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH {98.503} \
    CONFIG.PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_DQ_1_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH {68.5855} \
    CONFIG.PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_DQ_2_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH {90.295} \
    CONFIG.PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_DQ_3_LENGTH_MM {0} \
    CONFIG.PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH {103.977} \
    CONFIG.PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY {160} \
    CONFIG.PCW_UIPARAM_DDR_ENABLE {1} \
    CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {533.333333} \
    CONFIG.PCW_UIPARAM_DDR_HIGH_TEMP {Normal (0-85)} \
    CONFIG.PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3} \
    CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M16 RE-125} \
    CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
    CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
    CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
    CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {0} \
    CONFIG.PCW_UIPARAM_GENERATE_SUMMARY {NA} \
    CONFIG.PCW_USB0_BASEADDR {0xE0102000} \
    CONFIG.PCW_USB0_HIGHADDR {0xE0102fff} \
    CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_USB0_RESET_ENABLE {1} \
    CONFIG.PCW_USB0_RESET_IO {MIO 46} \
    CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
    CONFIG.PCW_USB1_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_USB_RESET_ENABLE {1} \
    CONFIG.PCW_USB_RESET_POLARITY {Active Low} \
    CONFIG.PCW_USB_RESET_SELECT {Share reset pin} \
    CONFIG.PCW_USE_AXI_FABRIC_IDLE {0} \
    CONFIG.PCW_USE_AXI_NONSECURE {0} \
    CONFIG.PCW_USE_CORESIGHT {0} \
    CONFIG.PCW_USE_CROSS_TRIGGER {0} \
    CONFIG.PCW_USE_CR_FABRIC {1} \
    CONFIG.PCW_USE_DDR_BYPASS {0} \
    CONFIG.PCW_USE_DEBUG {0} \
    CONFIG.PCW_USE_DMA0 {0} \
    CONFIG.PCW_USE_DMA1 {0} \
    CONFIG.PCW_USE_DMA2 {0} \
    CONFIG.PCW_USE_DMA3 {0} \
    CONFIG.PCW_USE_EXPANDED_IOP {0} \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_USE_HIGH_OCM {0} \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_USE_M_AXI_GP1 {0} \
    CONFIG.PCW_USE_PROC_EVENT_BUS {0} \
    CONFIG.PCW_USE_PS_SLCR_REGISTERS {0} \
    CONFIG.PCW_USE_S_AXI_ACP {0} \
    CONFIG.PCW_USE_S_AXI_GP0 {0} \
    CONFIG.PCW_USE_S_AXI_GP1 {0} \
    CONFIG.PCW_USE_S_AXI_HP0 {1} \
    CONFIG.PCW_USE_S_AXI_HP1 {1} \
    CONFIG.PCW_USE_S_AXI_HP2 {1} \
    CONFIG.PCW_USE_S_AXI_HP3 {1} \
    CONFIG.PCW_USE_TRACE {0} \
    CONFIG.PCW_VALUE_SILVERSION {3} \
    CONFIG.PCW_WDT_PERIPHERAL_CLKSRC {CPU_1X} \
    CONFIG.PCW_WDT_PERIPHERAL_DIVISOR0 {1} \
    CONFIG.PCW_WDT_PERIPHERAL_ENABLE {0} \
    CONFIG.preset {None} \
  ] $ps7


  # Create instance: clk_audio, and set properties
  set clk_audio [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_audio ]
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {98.304} \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.USE_RESET {false} \
  ] $clk_audio


  # Create instance: const_one, and set properties
  set const_one [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_one ]
  set_property CONFIG.CONST_VAL {1} $const_one


  # Create instance: const_zero, and set properties
  set const_zero [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_zero ]
  set_property CONFIG.CONST_VAL {0} $const_zero


  # Create instance: rst_fclk, and set properties
  set rst_fclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_fclk ]

  # Create instance: rst_audio, and set properties
  set rst_audio [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_audio ]

  # Create instance: rst_pixel, and set properties
  set rst_pixel [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pixel ]

  # Create instance: camera, and set properties
  set block_name camera_pipeline_top
  set block_cell_name camera
  if { [catch {set camera [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $camera eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.FRAME_HEIGHT {1080} \
    CONFIG.FRAME_WIDTH {1920} \
  ] $camera


  # Create instance: audio, and set properties
  set block_name audio_control_top
  set block_cell_name audio
  if { [catch {set audio [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $audio eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: gamma_cdc, and set properties
  set block_name gamma_event_cdc
  set block_cell_name gamma_cdc
  if { [catch {set gamma_cdc [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $gamma_cdc eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: status_cdc, and set properties
  set block_name av_status_cdc
  set block_cell_name status_cdc
  if { [catch {set status_cdc [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $status_cdc eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: vdma, and set properties
  set vdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 vdma ]
  set_property -dict [list \
    CONFIG.c_include_internal_genlock {1} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_mm2s_dre {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_m_axis_mm2s_tdata_width {16} \
    CONFIG.c_mm2s_genlock_mode {3} \
    CONFIG.c_mm2s_linebuffer_depth {2048} \
    CONFIG.c_mm2s_max_burst_length {16} \
    CONFIG.c_num_fstores {3} \
    CONFIG.c_s2mm_genlock_mode {2} \
    CONFIG.c_use_mm2s_fsync {1} \
  ] $vdma


  # Create instance: video_cdc, and set properties
  set video_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 video_cdc ]

  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_m_axi_s2mm_data_width {128} \
  ] $dma


  # Create instance: pcm_cdc, and set properties
  set pcm_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 pcm_cdc ]

  # Create instance: ctrl_ic, and set properties
  set ctrl_ic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ctrl_ic ]
  set_property -dict [list \
    CONFIG.NUM_MI {9} \
    CONFIG.NUM_SI {1} \
  ] $ctrl_ic


  # Create instance: ctrl_cdc, and set properties
  set ctrl_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 ctrl_cdc ]

  # Create instance: cam_gpio, and set properties
  set cam_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 cam_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {0} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_ALL_OUTPUTS {0} \
    CONFIG.C_GPIO2_WIDTH {32} \
    CONFIG.C_GPIO_WIDTH {6} \
    CONFIG.C_IS_DUAL {1} \
  ] $cam_gpio


  # Create instance: cam_io, and set properties
  set block_name camera_ctrl_io
  set block_cell_name cam_io
  if { [catch {set cam_io [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $cam_io eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: camera_probe, and set properties
  set block_name camera_input_probe
  set block_cell_name camera_probe
  if { [catch {set camera_probe [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $camera_probe eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: vdma_proto, and set properties
  set vdma_proto [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 vdma_proto ]

  # Create instance: dma_proto, and set properties
  set dma_proto [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 dma_proto ]

  # Create instance: dma_width, and set properties
  set dma_width [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 dma_width ]
  set_property -dict [list \
    CONFIG.MI_DATA_WIDTH {64} \
    CONFIG.SI_DATA_WIDTH {128} \
  ] $dma_width


  # Create instance: irq_concat, and set properties
  set irq_concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 irq_concat ]
  set_property CONFIG.NUM_PORTS {2} $irq_concat


  # Create instance: model_ingress, and set properties
  set block_name model_ingress_stub
  set block_cell_name model_ingress
  if { [catch {set model_ingress [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $model_ingress eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: infer_dma, and set properties
  set infer_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 infer_dma ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_m_axis_mm2s_tdata_width {64} \
    CONFIG.c_mm2s_burst_size {16} \
    CONFIG.c_s2mm_burst_size {16} \
    CONFIG.c_s_axis_s2mm_tdata_width {64} \
    CONFIG.c_sg_length_width {14} \
  ] $infer_dma


  # Create instance: inference_engine, and set properties
  set block_name mnet_engine_rtl
  set block_cell_name inference_engine
  if { [catch {set inference_engine [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $inference_engine eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: inference_memory, and set properties
  set inference_memory [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 inference_memory ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {2} \
  ] $inference_memory


  # Create instance: mel_dma, and set properties
  set mel_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 mel_dma ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_m_axi_mm2s_data_width {32} \
    CONFIG.c_m_axi_s2mm_data_width {32} \
    CONFIG.c_m_axis_mm2s_tdata_width {32} \
    CONFIG.c_mm2s_burst_size {16} \
    CONFIG.c_s2mm_burst_size {16} \
    CONFIG.c_s_axis_s2mm_tdata_width {32} \
    CONFIG.c_sg_length_width {14} \
  ] $mel_dma


  # Create instance: mel_core, and set properties
  set block_name logmel_axis_wrap
  set block_cell_name mel_core
  if { [catch {set mel_core [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $mel_core eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: mel_memory, and set properties
  set mel_memory [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 mel_memory ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {4} \
  ] $mel_memory


  # Create instance: ssd_dma, and set properties
  set ssd_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 ssd_dma ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_m_axi_mm2s_data_width {32} \
    CONFIG.c_m_axi_s2mm_data_width {32} \
    CONFIG.c_m_axis_mm2s_tdata_width {32} \
    CONFIG.c_mm2s_burst_size {16} \
    CONFIG.c_s2mm_burst_size {16} \
    CONFIG.c_s_axis_s2mm_tdata_width {32} \
    CONFIG.c_sg_length_width {23} \
  ] $ssd_dma


  # Create instance: ssd_preprocess_core, and set properties
  set block_name ssd_axis_wrap
  set block_cell_name ssd_preprocess_core
  if { [catch {set ssd_preprocess_core [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ssd_preprocess_core eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: hdmi_memory, and set properties
  set hdmi_memory [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 hdmi_memory ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {2} \
  ] $hdmi_memory


  # Create instance: clk_hdmi, and set properties
  set clk_hdmi [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_hdmi ]
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {115.0} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {575.0} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {143.75} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.PRIM_IN_FREQ {100} \
    CONFIG.USE_RESET {false} \
  ] $clk_hdmi


  # Create instance: rst_hdmi, and set properties
  set rst_hdmi [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_hdmi ]

  # Create instance: hdmi_rgb, and set properties
  set block_name rgb565_axis
  set block_cell_name hdmi_rgb
  if { [catch {set hdmi_rgb [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hdmi_rgb eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: hdmi_raster, and set properties
  set block_name hdmi_raster
  set block_cell_name hdmi_raster
  if { [catch {set hdmi_raster [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hdmi_raster eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: hdmi_video_out, and set properties
  set hdmi_video_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out:4.0 hdmi_video_out ]
  set_property -dict [list \
    CONFIG.C_ADDR_WIDTH {11} \
    CONFIG.C_HAS_ASYNC_CLK {0} \
    CONFIG.C_NATIVE_COMPONENT_WIDTH {8} \
    CONFIG.C_PIXELS_PER_CLOCK {1} \
    CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {8} \
    CONFIG.C_S_AXIS_VIDEO_FORMAT {2} \
    CONFIG.C_VTG_MASTER_SLAVE {1} \
  ] $hdmi_video_out


  # Create instance: hdmi_encoder, and set properties
  set hdmi_encoder [ create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 hdmi_encoder ]
  set_property -dict [list \
    CONFIG.kGenerateSerialClk {false} \
    CONFIG.kRstActiveHigh {true} \
  ] $hdmi_encoder


  # Create instance: hdmi_status, and set properties
  set block_name hdmi_status_cdc
  set block_cell_name hdmi_status
  if { [catch {set hdmi_status [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hdmi_status eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.WIDTH {32} $hdmi_status


  # Create instance: rst_hdmi_read, and set properties
  set rst_hdmi_read [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_hdmi_read ]

  # Create instance: hdmi_osd, and set properties
  set block_name board_osd
  set block_cell_name hdmi_osd
  if { [catch {set hdmi_osd [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hdmi_osd eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net audio_m_axis_model_mel [get_bd_intf_pins audio/m_axis_model_mel] [get_bd_intf_pins model_ingress/s_axis_mel]
  connect_bd_intf_net -intf_net audio_m_axis_pcm [get_bd_intf_pins audio/m_axis_pcm] [get_bd_intf_pins pcm_cdc/S_AXIS]
  connect_bd_intf_net -intf_net camera_m_axis_model_video [get_bd_intf_pins camera/m_axis_model_video] [get_bd_intf_pins model_ingress/s_axis_video]
  connect_bd_intf_net -intf_net camera_m_axis_video [get_bd_intf_pins camera/m_axis_video] [get_bd_intf_pins video_cdc/S_AXIS]
  connect_bd_intf_net -intf_net ctrl_cdc_M_AXI [get_bd_intf_pins ctrl_cdc/M_AXI] [get_bd_intf_pins audio/S_AXI]
  connect_bd_intf_net -intf_net ctrl_ic_M00_AXI [get_bd_intf_pins ctrl_ic/M00_AXI] [get_bd_intf_pins vdma/S_AXI_LITE]
  connect_bd_intf_net -intf_net ctrl_ic_M01_AXI [get_bd_intf_pins ctrl_ic/M01_AXI] [get_bd_intf_pins dma/S_AXI_LITE]
  connect_bd_intf_net -intf_net ctrl_ic_M02_AXI [get_bd_intf_pins ctrl_ic/M02_AXI] [get_bd_intf_pins cam_gpio/S_AXI]
  connect_bd_intf_net -intf_net ctrl_ic_M03_AXI [get_bd_intf_pins ctrl_ic/M03_AXI] [get_bd_intf_pins ctrl_cdc/S_AXI]
  connect_bd_intf_net -intf_net ctrl_ic_M04_AXI [get_bd_intf_pins ctrl_ic/M04_AXI] [get_bd_intf_pins infer_dma/S_AXI_LITE]
  connect_bd_intf_net -intf_net ctrl_ic_M05_AXI [get_bd_intf_pins ctrl_ic/M05_AXI] [get_bd_intf_pins inference_engine/s_axi_control]
  connect_bd_intf_net -intf_net ctrl_ic_M06_AXI [get_bd_intf_pins ctrl_ic/M06_AXI] [get_bd_intf_pins mel_dma/S_AXI_LITE]
  connect_bd_intf_net -intf_net ctrl_ic_M07_AXI [get_bd_intf_pins ctrl_ic/M07_AXI] [get_bd_intf_pins ssd_dma/S_AXI_LITE]
  connect_bd_intf_net -intf_net ctrl_ic_M08_AXI [get_bd_intf_pins ctrl_ic/M08_AXI] [get_bd_intf_pins hdmi_osd/S_AXI]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins dma/M_AXI_S2MM] [get_bd_intf_pins dma_width/S_AXI]
  connect_bd_intf_net -intf_net dma_proto_M_AXI [get_bd_intf_pins dma_proto/M_AXI] [get_bd_intf_pins ps7/S_AXI_HP1]
  connect_bd_intf_net -intf_net dma_width_M_AXI [get_bd_intf_pins dma_width/M_AXI] [get_bd_intf_pins dma_proto/S_AXI]
  connect_bd_intf_net -intf_net hdmi_memory_M00_AXI [get_bd_intf_pins hdmi_memory/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP0]
  connect_bd_intf_net -intf_net hdmi_rgb_m_axis [get_bd_intf_pins hdmi_rgb/m_axis] [get_bd_intf_pins hdmi_video_out/video_in]
  connect_bd_intf_net -intf_net infer_dma_M_AXIS_MM2S [get_bd_intf_pins infer_dma/M_AXIS_MM2S] [get_bd_intf_pins inference_engine/in_r]
  connect_bd_intf_net -intf_net infer_dma_M_AXI_MM2S [get_bd_intf_pins infer_dma/M_AXI_MM2S] [get_bd_intf_pins inference_memory/S00_AXI]
  connect_bd_intf_net -intf_net infer_dma_M_AXI_S2MM [get_bd_intf_pins infer_dma/M_AXI_S2MM] [get_bd_intf_pins inference_memory/S01_AXI]
  connect_bd_intf_net -intf_net inference_engine_out_r [get_bd_intf_pins inference_engine/out_r] [get_bd_intf_pins infer_dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net inference_memory_M00_AXI [get_bd_intf_pins inference_memory/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP2]
  connect_bd_intf_net -intf_net mel_core_M_AXIS [get_bd_intf_pins mel_core/M_AXIS] [get_bd_intf_pins mel_dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net mel_dma_M_AXIS_MM2S [get_bd_intf_pins mel_dma/M_AXIS_MM2S] [get_bd_intf_pins mel_core/S_AXIS]
  connect_bd_intf_net -intf_net mel_dma_M_AXI_MM2S [get_bd_intf_pins mel_dma/M_AXI_MM2S] [get_bd_intf_pins mel_memory/S00_AXI]
  connect_bd_intf_net -intf_net mel_dma_M_AXI_S2MM [get_bd_intf_pins mel_dma/M_AXI_S2MM] [get_bd_intf_pins mel_memory/S01_AXI]
  connect_bd_intf_net -intf_net mel_memory_M00_AXI [get_bd_intf_pins mel_memory/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP3]
  connect_bd_intf_net -intf_net pcm_cdc_M_AXIS [get_bd_intf_pins pcm_cdc/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net ps7_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins ps7/DDR]
  connect_bd_intf_net -intf_net ps7_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins ps7/FIXED_IO]
  connect_bd_intf_net -intf_net ps7_M_AXI_GP0 [get_bd_intf_pins ps7/M_AXI_GP0] [get_bd_intf_pins ctrl_ic/S00_AXI]
  connect_bd_intf_net -intf_net ssd_dma_M_AXIS_MM2S [get_bd_intf_pins ssd_dma/M_AXIS_MM2S] [get_bd_intf_pins ssd_preprocess_core/S_AXIS]
  connect_bd_intf_net -intf_net ssd_dma_M_AXI_MM2S [get_bd_intf_pins ssd_dma/M_AXI_MM2S] [get_bd_intf_pins mel_memory/S02_AXI]
  connect_bd_intf_net -intf_net ssd_dma_M_AXI_S2MM [get_bd_intf_pins ssd_dma/M_AXI_S2MM] [get_bd_intf_pins mel_memory/S03_AXI]
  connect_bd_intf_net -intf_net ssd_preprocess_core_M_AXIS [get_bd_intf_pins ssd_preprocess_core/M_AXIS] [get_bd_intf_pins ssd_dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net vdma_M_AXIS_MM2S [get_bd_intf_pins vdma/M_AXIS_MM2S] [get_bd_intf_pins hdmi_rgb/s_axis]
  connect_bd_intf_net -intf_net vdma_M_AXI_MM2S [get_bd_intf_pins vdma/M_AXI_MM2S] [get_bd_intf_pins hdmi_memory/S01_AXI]
  connect_bd_intf_net -intf_net vdma_M_AXI_S2MM [get_bd_intf_pins vdma/M_AXI_S2MM] [get_bd_intf_pins vdma_proto/S_AXI]
  connect_bd_intf_net -intf_net vdma_proto_M_AXI [get_bd_intf_pins vdma_proto/M_AXI] [get_bd_intf_pins hdmi_memory/S00_AXI]
  connect_bd_intf_net -intf_net video_cdc_M_AXIS [get_bd_intf_pins video_cdc/M_AXIS] [get_bd_intf_pins vdma/S_AXIS_S2MM]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports cam_scl] [get_bd_pins cam_io/cam_scl]
  connect_bd_net -net Net1 [get_bd_ports cam_sda] [get_bd_pins cam_io/cam_sda]
  connect_bd_net -net audio_enhance_master_enable [get_bd_pins audio/enhance_master_enable] [get_bd_pins camera/enhance_master_enable]
  connect_bd_net -net audio_gamma_event_data [get_bd_pins audio/gamma_event_data] [get_bd_pins gamma_cdc/src_data]
  connect_bd_net -net audio_gamma_event_valid [get_bd_pins audio/gamma_event_valid] [get_bd_pins gamma_cdc/src_valid]
  connect_bd_net -net audio_mic_sck [get_bd_pins audio/mic_sck] [get_bd_ports mic_sck]
  connect_bd_net -net audio_mic_ws [get_bd_pins audio/mic_ws] [get_bd_ports mic_ws]
  connect_bd_net -net audio_servo_pan [get_bd_pins audio/servo_pan] [get_bd_ports servo_pan]
  connect_bd_net -net audio_servo_tilt [get_bd_pins audio/servo_tilt] [get_bd_ports servo_tilt]
  connect_bd_net -net board_keys_n [get_bd_ports board_keys_n] [get_bd_pins audio/board_keys_n]
  connect_bd_net -net cam_d_1 [get_bd_ports cam_d] [get_bd_pins camera_probe/cam_d] [get_bd_pins camera/cam_d]
  connect_bd_net -net cam_gpio_gpio_io_o [get_bd_pins cam_gpio/gpio_io_o] [get_bd_pins cam_io/gpio_o]
  connect_bd_net -net cam_gpio_gpio_io_t [get_bd_pins cam_gpio/gpio_io_t] [get_bd_pins cam_io/gpio_t]
  connect_bd_net -net cam_href_1 [get_bd_ports cam_href] [get_bd_pins camera_probe/cam_href] [get_bd_pins camera/cam_href]
  connect_bd_net -net cam_io_cam_pwdn [get_bd_pins cam_io/cam_pwdn] [get_bd_ports cam_pwdn]
  connect_bd_net -net cam_io_cam_reset_n [get_bd_pins cam_io/cam_reset_n] [get_bd_ports cam_reset_n]
  connect_bd_net -net cam_io_camera_configured [get_bd_pins cam_io/camera_configured] [get_bd_pins camera/camera_configured]
  connect_bd_net -net cam_io_camera_test_pattern [get_bd_pins cam_io/camera_test_pattern] [get_bd_pins camera/camera_test_pattern]
  connect_bd_net -net cam_io_gpio_i [get_bd_pins cam_io/gpio_i] [get_bd_pins cam_gpio/gpio_io_i]
  connect_bd_net -net cam_pclk_1 [get_bd_ports cam_pclk] [get_bd_pins rst_pixel/slowest_sync_clk] [get_bd_pins gamma_cdc/dst_clk] [get_bd_pins status_cdc/src_clk] [get_bd_pins video_cdc/s_axis_aclk] [get_bd_pins model_ingress/video_clk] [get_bd_pins camera_probe/cam_pclk] [get_bd_pins camera/cam_pclk]
  connect_bd_net -net cam_vsync_1 [get_bd_ports cam_vsync] [get_bd_pins camera_probe/cam_vsync] [get_bd_pins camera/cam_vsync]
  connect_bd_net -net camera_dark_ratio_q15 [get_bd_pins camera/dark_ratio_q15] [get_bd_pins status_cdc/src_dark_ratio]
  connect_bd_net -net camera_enhance_led_n [get_bd_pins camera/enhance_led_n] [get_bd_ports enhance_led_n]
  connect_bd_net -net camera_enhancement_debug [get_bd_pins camera/enhancement_debug] [get_bd_pins camera_probe/enhancement_debug]
  connect_bd_net -net camera_frame_count [get_bd_pins camera/frame_count] [get_bd_pins status_cdc/src_frame_count]
  connect_bd_net -net camera_frame_start [get_bd_pins camera/frame_start] [get_bd_pins status_cdc/src_strobe] [get_bd_pins camera_probe/debug_strobe]
  connect_bd_net -net camera_mean_y [get_bd_pins camera/mean_y] [get_bd_pins status_cdc/src_mean_y]
  connect_bd_net -net camera_probe_probe_data [get_bd_pins camera_probe/probe_data] [get_bd_pins cam_gpio/gpio2_io_i]
  connect_bd_net -net camera_video_drop_count [get_bd_pins camera/video_drop_count] [get_bd_pins status_cdc/src_video_drop]
  connect_bd_net -net clk_audio_clk_out1 [get_bd_pins clk_audio/clk_out1] [get_bd_pins rst_audio/slowest_sync_clk] [get_bd_pins gamma_cdc/src_clk] [get_bd_pins status_cdc/dst_clk] [get_bd_pins pcm_cdc/s_axis_aclk] [get_bd_pins ctrl_cdc/m_axi_aclk] [get_bd_pins model_ingress/mel_clk] [get_bd_pins audio/clk_98m304]
  connect_bd_net -net clk_audio_locked [get_bd_pins clk_audio/locked] [get_bd_pins rst_audio/dcm_locked]
  connect_bd_net -net clk_hdmi_clk_out1 [get_bd_pins clk_hdmi/clk_out1] [get_bd_pins rst_hdmi/slowest_sync_clk] [get_bd_pins vdma/m_axis_mm2s_aclk] [get_bd_pins hdmi_video_out/aclk] [get_bd_pins hdmi_encoder/PixelClk] [get_bd_pins hdmi_status/src_clk] [get_bd_pins hdmi_raster/pixel_clk] [get_bd_pins hdmi_rgb/aclk] [get_bd_pins hdmi_osd/pixel_clk]
  connect_bd_net -net clk_hdmi_clk_out2 [get_bd_pins clk_hdmi/clk_out2] [get_bd_pins hdmi_encoder/SerialClk]
  connect_bd_net -net clk_hdmi_clk_out3 [get_bd_pins clk_hdmi/clk_out3] [get_bd_pins rst_hdmi_read/slowest_sync_clk] [get_bd_pins vdma/m_axi_mm2s_aclk] [get_bd_pins hdmi_memory/S01_ACLK]
  connect_bd_net -net clk_hdmi_locked [get_bd_pins clk_hdmi/locked] [get_bd_pins rst_hdmi/dcm_locked] [get_bd_pins rst_hdmi_read/dcm_locked]
  connect_bd_net -net const_one_dout [get_bd_pins const_one/dout] [get_bd_pins rst_fclk/dcm_locked] [get_bd_pins rst_fclk/aux_reset_in] [get_bd_pins rst_audio/aux_reset_in] [get_bd_pins rst_pixel/aux_reset_in] [get_bd_pins rst_pixel/dcm_locked] [get_bd_pins rst_hdmi/aux_reset_in] [get_bd_pins hdmi_video_out/aclken] [get_bd_pins hdmi_video_out/vid_io_out_ce] [get_bd_pins rst_hdmi_read/aux_reset_in]
  connect_bd_net -net const_zero_dout [get_bd_pins const_zero/dout] [get_bd_pins rst_fclk/mb_debug_sys_rst] [get_bd_pins rst_audio/mb_debug_sys_rst] [get_bd_pins rst_pixel/mb_debug_sys_rst] [get_bd_pins rst_hdmi/mb_debug_sys_rst] [get_bd_pins hdmi_video_out/fid] [get_bd_pins hdmi_video_out/vtg_field_id] [get_bd_pins rst_hdmi_read/mb_debug_sys_rst]
  connect_bd_net -net dma_s2mm_introut [get_bd_pins dma/s2mm_introut] [get_bd_pins irq_concat/In1]
  connect_bd_net -net gamma_cdc_gamma_commit [get_bd_pins gamma_cdc/gamma_commit] [get_bd_pins camera/gamma_commit]
  connect_bd_net -net gamma_cdc_gamma_wr_addr [get_bd_pins gamma_cdc/gamma_wr_addr] [get_bd_pins camera/gamma_wr_addr]
  connect_bd_net -net gamma_cdc_gamma_wr_data [get_bd_pins gamma_cdc/gamma_wr_data] [get_bd_pins camera/gamma_wr_data]
  connect_bd_net -net gamma_cdc_gamma_wr_en [get_bd_pins gamma_cdc/gamma_wr_en] [get_bd_pins camera/gamma_wr_en]
  connect_bd_net -net hdmi_encoder_TMDS_Clk_n [get_bd_pins hdmi_encoder/TMDS_Clk_n] [get_bd_ports hdmi_clk_n]
  connect_bd_net -net hdmi_encoder_TMDS_Clk_p [get_bd_pins hdmi_encoder/TMDS_Clk_p] [get_bd_ports hdmi_clk_p]
  connect_bd_net -net hdmi_encoder_TMDS_Data_n [get_bd_pins hdmi_encoder/TMDS_Data_n] [get_bd_ports hdmi_data_n]
  connect_bd_net -net hdmi_encoder_TMDS_Data_p [get_bd_pins hdmi_encoder/TMDS_Data_p] [get_bd_ports hdmi_data_p]
  connect_bd_net -net hdmi_gpio_gpio_io_o [get_bd_pins hdmi_osd/force_bars] [get_bd_pins hdmi_raster/force_bars]
  connect_bd_net -net hdmi_hpd_1 [get_bd_ports hdmi_hpd] [get_bd_pins hdmi_raster/hpd]
  connect_bd_net -net hdmi_osd_out_data [get_bd_pins hdmi_osd/out_data] [get_bd_pins hdmi_encoder/vid_pData]
  connect_bd_net -net hdmi_osd_out_de [get_bd_pins hdmi_osd/out_de] [get_bd_pins hdmi_encoder/vid_pVDE]
  connect_bd_net -net hdmi_osd_out_hsync [get_bd_pins hdmi_osd/out_hsync] [get_bd_pins hdmi_encoder/vid_pHSync]
  connect_bd_net -net hdmi_osd_out_vsync [get_bd_pins hdmi_osd/out_vsync] [get_bd_pins hdmi_encoder/vid_pVSync]
  connect_bd_net -net hdmi_raster_frame_sync [get_bd_pins hdmi_raster/frame_sync] [get_bd_pins vdma/mm2s_fsync] [get_bd_pins hdmi_osd/frame_boundary]
  connect_bd_net -net hdmi_raster_hdmi_out_en [get_bd_pins hdmi_raster/hdmi_out_en] [get_bd_ports hdmi_out_en]
  connect_bd_net -net hdmi_raster_status [get_bd_pins hdmi_raster/status] [get_bd_pins hdmi_status/src_data]
  connect_bd_net -net hdmi_raster_status_strobe [get_bd_pins hdmi_raster/status_strobe] [get_bd_pins hdmi_status/src_strobe]
  connect_bd_net -net hdmi_raster_timing_de [get_bd_pins hdmi_raster/timing_de] [get_bd_pins hdmi_video_out/vtg_active_video]
  connect_bd_net -net hdmi_raster_timing_hblank [get_bd_pins hdmi_raster/timing_hblank] [get_bd_pins hdmi_video_out/vtg_hblank]
  connect_bd_net -net hdmi_raster_timing_hsync [get_bd_pins hdmi_raster/timing_hsync] [get_bd_pins hdmi_video_out/vtg_hsync]
  connect_bd_net -net hdmi_raster_timing_vblank [get_bd_pins hdmi_raster/timing_vblank] [get_bd_pins hdmi_video_out/vtg_vblank]
  connect_bd_net -net hdmi_raster_timing_vsync [get_bd_pins hdmi_raster/timing_vsync] [get_bd_pins hdmi_video_out/vtg_vsync]
  connect_bd_net -net hdmi_raster_video_data [get_bd_pins hdmi_raster/video_data] [get_bd_pins hdmi_osd/video_data]
  connect_bd_net -net hdmi_raster_video_de [get_bd_pins hdmi_raster/video_de] [get_bd_pins hdmi_osd/video_de]
  connect_bd_net -net hdmi_raster_video_hsync [get_bd_pins hdmi_raster/video_hsync] [get_bd_pins hdmi_osd/video_hsync]
  connect_bd_net -net hdmi_raster_video_vsync [get_bd_pins hdmi_raster/video_vsync] [get_bd_pins hdmi_osd/video_vsync]
  connect_bd_net -net hdmi_status_dst_data [get_bd_pins hdmi_status/dst_data] [get_bd_pins hdmi_osd/status_in]
  connect_bd_net -net hdmi_video_out_locked [get_bd_pins hdmi_video_out/locked] [get_bd_pins hdmi_raster/stream_locked]
  connect_bd_net -net hdmi_video_out_overflow [get_bd_pins hdmi_video_out/overflow] [get_bd_pins hdmi_raster/overflow]
  connect_bd_net -net hdmi_video_out_underflow [get_bd_pins hdmi_video_out/underflow] [get_bd_pins hdmi_raster/underflow]
  connect_bd_net -net hdmi_video_out_vid_active_video [get_bd_pins hdmi_video_out/vid_active_video] [get_bd_pins hdmi_raster/stream_de]
  connect_bd_net -net hdmi_video_out_vid_data [get_bd_pins hdmi_video_out/vid_data] [get_bd_pins hdmi_raster/stream_data]
  connect_bd_net -net hdmi_video_out_vid_hsync [get_bd_pins hdmi_video_out/vid_hsync] [get_bd_pins hdmi_raster/stream_hsync]
  connect_bd_net -net hdmi_video_out_vid_vsync [get_bd_pins hdmi_video_out/vid_vsync] [get_bd_pins hdmi_raster/stream_vsync]
  connect_bd_net -net irq_concat_dout [get_bd_pins irq_concat/dout] [get_bd_pins ps7/IRQ_F2P]
  connect_bd_net -net mic_sd_0_1 [get_bd_ports mic_sd_0] [get_bd_pins audio/mic_sd_0]
  connect_bd_net -net mic_sd_1_1 [get_bd_ports mic_sd_1] [get_bd_pins audio/mic_sd_1]
  connect_bd_net -net mic_sd_2_1 [get_bd_ports mic_sd_2] [get_bd_pins audio/mic_sd_2]
  connect_bd_net -net mic_sd_3_1 [get_bd_ports mic_sd_3] [get_bd_pins audio/mic_sd_3]
  connect_bd_net -net ps7_FCLK_CLK0 [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins clk_audio/clk_in1] [get_bd_pins rst_fclk/slowest_sync_clk] [get_bd_pins video_cdc/m_axis_aclk] [get_bd_pins vdma/s_axis_s2mm_aclk] [get_bd_pins pcm_cdc/m_axis_aclk] [get_bd_pins ps7/M_AXI_GP0_ACLK] [get_bd_pins ps7/S_AXI_HP0_ACLK] [get_bd_pins ps7/S_AXI_HP1_ACLK] [get_bd_pins ctrl_ic/ACLK] [get_bd_pins ctrl_ic/S00_ACLK] [get_bd_pins ctrl_ic/M00_ACLK] [get_bd_pins ctrl_ic/M01_ACLK] [get_bd_pins ctrl_ic/M02_ACLK] [get_bd_pins ctrl_ic/M03_ACLK] [get_bd_pins ctrl_cdc/s_axi_aclk] [get_bd_pins cam_gpio/s_axi_aclk] [get_bd_pins vdma/s_axi_lite_aclk] [get_bd_pins vdma/m_axi_s2mm_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins vdma_proto/aclk] [get_bd_pins dma_proto/aclk] [get_bd_pins dma_width/s_axi_aclk] [get_bd_pins ps7/S_AXI_HP2_ACLK] [get_bd_pins infer_dma/s_axi_lite_aclk] [get_bd_pins infer_dma/m_axi_mm2s_aclk] [get_bd_pins infer_dma/m_axi_s2mm_aclk] [get_bd_pins ctrl_ic/M04_ACLK] [get_bd_pins ctrl_ic/M05_ACLK] [get_bd_pins inference_memory/ACLK] [get_bd_pins inference_memory/S00_ACLK] [get_bd_pins inference_memory/S01_ACLK] [get_bd_pins inference_memory/M00_ACLK] [get_bd_pins ps7/S_AXI_HP3_ACLK] [get_bd_pins mel_dma/s_axi_lite_aclk] [get_bd_pins mel_dma/m_axi_mm2s_aclk] [get_bd_pins mel_dma/m_axi_s2mm_aclk] [get_bd_pins mel_core/aclk] [get_bd_pins ctrl_ic/M06_ACLK] [get_bd_pins mel_memory/ACLK] [get_bd_pins mel_memory/S00_ACLK] [get_bd_pins mel_memory/S01_ACLK] [get_bd_pins mel_memory/M00_ACLK] [get_bd_pins ssd_dma/s_axi_lite_aclk] [get_bd_pins ssd_dma/m_axi_mm2s_aclk] [get_bd_pins ssd_dma/m_axi_s2mm_aclk] [get_bd_pins ssd_preprocess_core/aclk] [get_bd_pins ctrl_ic/M07_ACLK] [get_bd_pins mel_memory/S02_ACLK] [get_bd_pins mel_memory/S03_ACLK] [get_bd_pins camera_probe/clk] [get_bd_pins inference_engine/ap_clk] [get_bd_pins hdmi_memory/ACLK] [get_bd_pins hdmi_memory/S00_ACLK] [get_bd_pins hdmi_memory/M00_ACLK] [get_bd_pins clk_hdmi/clk_in1] [get_bd_pins hdmi_status/dst_clk] [get_bd_pins ctrl_ic/M08_ACLK] [get_bd_pins hdmi_osd/s_axi_aclk]
  connect_bd_net -net ps7_FCLK_RESET0_N [get_bd_pins ps7/FCLK_RESET0_N] [get_bd_pins rst_fclk/ext_reset_in] [get_bd_pins rst_audio/ext_reset_in] [get_bd_pins rst_pixel/ext_reset_in] [get_bd_pins rst_hdmi/ext_reset_in] [get_bd_pins rst_hdmi_read/ext_reset_in]
  connect_bd_net -net rst_audio_peripheral_aresetn [get_bd_pins rst_audio/peripheral_aresetn] [get_bd_pins pcm_cdc/s_axis_aresetn] [get_bd_pins ctrl_cdc/m_axi_aresetn] [get_bd_pins model_ingress/mel_resetn] [get_bd_pins audio/resetn]
  connect_bd_net -net rst_audio_peripheral_reset [get_bd_pins rst_audio/peripheral_reset] [get_bd_pins gamma_cdc/src_rst] [get_bd_pins status_cdc/dst_rst]
  connect_bd_net -net rst_fclk_interconnect_aresetn [get_bd_pins rst_fclk/interconnect_aresetn] [get_bd_pins ctrl_ic/ARESETN] [get_bd_pins inference_memory/ARESETN] [get_bd_pins mel_memory/ARESETN] [get_bd_pins hdmi_memory/ARESETN]
  connect_bd_net -net rst_fclk_peripheral_aresetn [get_bd_pins rst_fclk/peripheral_aresetn] [get_bd_pins video_cdc/m_axis_aresetn] [get_bd_pins pcm_cdc/m_axis_aresetn] [get_bd_pins ctrl_ic/S00_ARESETN] [get_bd_pins ctrl_ic/M00_ARESETN] [get_bd_pins ctrl_ic/M01_ARESETN] [get_bd_pins ctrl_ic/M02_ARESETN] [get_bd_pins ctrl_ic/M03_ARESETN] [get_bd_pins ctrl_cdc/s_axi_aresetn] [get_bd_pins vdma/axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins cam_gpio/s_axi_aresetn] [get_bd_pins vdma_proto/aresetn] [get_bd_pins dma_proto/aresetn] [get_bd_pins dma_width/s_axi_aresetn] [get_bd_pins infer_dma/axi_resetn] [get_bd_pins ctrl_ic/M04_ARESETN] [get_bd_pins ctrl_ic/M05_ARESETN] [get_bd_pins inference_memory/S00_ARESETN] [get_bd_pins inference_memory/S01_ARESETN] [get_bd_pins inference_memory/M00_ARESETN] [get_bd_pins mel_dma/axi_resetn] [get_bd_pins mel_core/aresetn] [get_bd_pins ctrl_ic/M06_ARESETN] [get_bd_pins mel_memory/S00_ARESETN] [get_bd_pins mel_memory/S01_ARESETN] [get_bd_pins mel_memory/M00_ARESETN] [get_bd_pins ssd_dma/axi_resetn] [get_bd_pins ssd_preprocess_core/aresetn] [get_bd_pins ctrl_ic/M07_ARESETN] [get_bd_pins mel_memory/S02_ARESETN] [get_bd_pins mel_memory/S03_ARESETN] [get_bd_pins camera_probe/resetn] [get_bd_pins inference_engine/ap_rst_n] [get_bd_pins hdmi_memory/S00_ARESETN] [get_bd_pins hdmi_memory/M00_ARESETN] [get_bd_pins ctrl_ic/M08_ARESETN] [get_bd_pins hdmi_osd/s_axi_aresetn]
  connect_bd_net -net rst_fclk_peripheral_reset [get_bd_pins rst_fclk/peripheral_reset] [get_bd_pins hdmi_status/dst_rst]
  connect_bd_net -net rst_hdmi_peripheral_aresetn [get_bd_pins rst_hdmi/peripheral_aresetn] [get_bd_pins hdmi_video_out/aresetn] [get_bd_pins hdmi_raster/resetn] [get_bd_pins hdmi_rgb/aresetn] [get_bd_pins hdmi_osd/pixel_resetn]
  connect_bd_net -net rst_hdmi_peripheral_reset [get_bd_pins rst_hdmi/peripheral_reset] [get_bd_pins hdmi_encoder/aRst] [get_bd_pins hdmi_status/src_rst]
  connect_bd_net -net rst_hdmi_read_peripheral_aresetn [get_bd_pins rst_hdmi_read/peripheral_aresetn] [get_bd_pins hdmi_memory/S01_ARESETN]
  connect_bd_net -net rst_pixel_peripheral_aresetn [get_bd_pins rst_pixel/peripheral_aresetn] [get_bd_pins video_cdc/s_axis_aresetn] [get_bd_pins model_ingress/video_resetn] [get_bd_pins camera/resetn]
  connect_bd_net -net rst_pixel_peripheral_reset [get_bd_pins rst_pixel/peripheral_reset] [get_bd_pins gamma_cdc/dst_rst] [get_bd_pins status_cdc/src_rst] [get_bd_pins camera_probe/pixel_reset]
  connect_bd_net -net status_cdc_dst_dark_ratio [get_bd_pins status_cdc/dst_dark_ratio] [get_bd_pins audio/stat_dark_ratio_q15]
  connect_bd_net -net status_cdc_dst_frame_count [get_bd_pins status_cdc/dst_frame_count] [get_bd_pins audio/stat_frame_count]
  connect_bd_net -net status_cdc_dst_mean_y [get_bd_pins status_cdc/dst_mean_y] [get_bd_pins audio/stat_mean_y]
  connect_bd_net -net status_cdc_dst_strobe [get_bd_pins status_cdc/dst_strobe] [get_bd_pins audio/stat_frame_strobe]
  connect_bd_net -net status_cdc_dst_video_drop [get_bd_pins status_cdc/dst_video_drop] [get_bd_pins audio/stat_video_drop_count]
  connect_bd_net -net vdma_s2mm_introut [get_bd_pins vdma/s2mm_introut] [get_bd_pins irq_concat/In0]

  # Create address segments
  assign_bd_address -offset 0x43C00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs audio/S_AXI/reg0] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs cam_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x40400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x41210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs hdmi_osd/S_AXI/reg0] -force
  assign_bd_address -offset 0x40410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs infer_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x43C20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs inference_engine/s_axi_control/reg0] -force
  assign_bd_address -offset 0x40420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs mel_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs ssd_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x43000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs vdma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces vdma/Data_MM2S] [get_bd_addr_segs ps7/S_AXI_HP0/HP0_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces vdma/Data_S2MM] [get_bd_addr_segs ps7/S_AXI_HP0/HP0_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces dma/Data_S2MM] [get_bd_addr_segs ps7/S_AXI_HP1/HP1_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces infer_dma/Data_MM2S] [get_bd_addr_segs ps7/S_AXI_HP2/HP2_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces infer_dma/Data_S2MM] [get_bd_addr_segs ps7/S_AXI_HP2/HP2_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces mel_dma/Data_MM2S] [get_bd_addr_segs ps7/S_AXI_HP3/HP3_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces mel_dma/Data_S2MM] [get_bd_addr_segs ps7/S_AXI_HP3/HP3_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces ssd_dma/Data_MM2S] [get_bd_addr_segs ps7/S_AXI_HP3/HP3_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces ssd_dma/Data_S2MM] [get_bd_addr_segs ps7/S_AXI_HP3/HP3_DDR_LOWOCM] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_av_system()


