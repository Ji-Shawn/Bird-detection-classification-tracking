# AX7020 J11 — OV5640 DVP, approved greenfield wiring.
# Board LED1, verified by diagnostics/led_on: active LOW, not an expansion pin.
set_property PACKAGE_PIN M14 [get_ports enhance_led_n]
set_property IOSTANDARD LVCMOS33 [get_ports enhance_led_n]
set_property SLEW SLOW [get_ports enhance_led_n]
set_property DRIVE 8 [get_ports enhance_led_n]
# Human-visible status only; there is no external synchronous receiver.
set_false_path -to [get_ports enhance_led_n]
set_property PACKAGE_PIN F17 [get_ports {cam_d[0]}]
set_property PACKAGE_PIN F16 [get_ports {cam_d[1]}]
set_property PACKAGE_PIN F20 [get_ports {cam_d[2]}]
set_property PACKAGE_PIN F19 [get_ports {cam_d[3]}]
set_property PACKAGE_PIN G20 [get_ports {cam_d[4]}]
set_property PACKAGE_PIN G19 [get_ports {cam_d[5]}]
# Camera P1-13 (D6) -> J11-9 -> H18.  Bench weak-pull testing showed this
# lane lacks a reliable external drive; do not hide it with a pin swap.
set_property PACKAGE_PIN H18 [get_ports {cam_d[6]}]
set_property PACKAGE_PIN J18 [get_ports {cam_d[7]}]
set_property PACKAGE_PIN L20 [get_ports cam_scl]
set_property PACKAGE_PIN L19 [get_ports cam_sda]
set_property PACKAGE_PIN M20 [get_ports cam_reset_n]
set_property PACKAGE_PIN M19 [get_ports cam_pwdn]
set_property PACKAGE_PIN K18 [get_ports cam_vsync]
set_property PACKAGE_PIN K17 [get_ports cam_pclk]
set_property PACKAGE_PIN J19 [get_ports cam_href]

# AX7020 J10 — four INMP441 microphones with independent Left-slot SD lines.
set_property PACKAGE_PIN W19 [get_ports mic_sck]
set_property PACKAGE_PIN W18 [get_ports mic_ws]
set_property PACKAGE_PIN R14 [get_ports mic_sd_0]
set_property PACKAGE_PIN P14 [get_ports mic_sd_1]
set_property PACKAGE_PIN Y17 [get_ports mic_sd_2]
set_property PACKAGE_PIN Y16 [get_ports mic_sd_3]

# Servo signals have moved away from microphone pins, confirmed by user.
set_property PACKAGE_PIN Y14 [get_ports servo_pan]
set_property PACKAGE_PIN W14 [get_ports servo_tilt]
set_property IOSTANDARD LVCMOS33 [get_ports {servo_pan servo_tilt}]
set_property SLEW SLOW [get_ports {servo_pan servo_tilt}]
set_property DRIVE 8 [get_ports {servo_pan servo_tilt}]
# Asynchronous servo inputs: bound only the final registered output path.
set servo_output_regs [get_cells -hier -quiet -filter {
    NAME =~ *u_servo/servo_pan_reg || NAME =~ *u_servo/servo_tilt_reg
}]
set_max_delay -datapath_only 20.000 -from $servo_output_regs -to [get_ports {servo_pan servo_tilt}]

set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_scl cam_sda cam_reset_n cam_pwdn cam_vsync cam_pclk cam_href}]
# ATK-MC5640 exposes SCCB directly and has no SCL/SDA pull-up resistors.
# Keep both lines at a defined high level while their IOBUFs are tri-stated.
set_property PULLUP true [get_ports {cam_scl cam_sda}]
set_property IOSTANDARD LVCMOS33 [get_ports {mic_sck mic_ws mic_sd_0 mic_sd_1 mic_sd_2 mic_sd_3}]
set_property SLEW SLOW [get_ports {cam_scl cam_sda cam_reset_n cam_pwdn mic_sck mic_ws}]
set_property DRIVE 8 [get_ports {cam_scl cam_sda cam_reset_n cam_pwdn mic_sck mic_ws}]

# The 30-fps OV5640 profile doubles the vendor 15-fps RGB565 pixel clock to
# approximately 84 MHz. Constrain that worst case rather than the 74.25 MHz
# nominal video rate.
create_clock -name cam_pclk -period 11.904 [get_ports cam_pclk]
set_input_delay -clock cam_pclk -min -1.000 [get_ports {cam_d[*] cam_vsync cam_href}]
set_input_delay -clock cam_pclk -max  3.000 [get_ports {cam_d[*] cam_vsync cam_href}]

# INMP441 changes SD after the falling edge of the board-generated SCK and the
# receiver samples it sixteen 98.304 MHz cycles later. Limit only the physical
# SD input path; a virtual unrelated clock would incorrectly require capture on
# the immediately following fabric-clock edge.
set mic_sd_ports [get_ports -quiet {mic_sd_0 mic_sd_1 mic_sd_2 mic_sd_3}]
# Endpoint assertions run in hardware/validate_native_constraints.tcl;
# Vivado 2018.3 XDC reader does not execute Tcl 'if' commands.
set mic_capture_regs [get_cells -hier -quiet -filter {
    NAME =~ *u_i2s/shift_0_reg* || NAME =~ *u_i2s/shift_1_reg* ||
    NAME =~ *u_i2s/shift_2_reg* || NAME =~ *u_i2s/shift_3_reg* ||
    NAME =~ *u_i2s/left_0_reg*  || NAME =~ *u_i2s/left_1_reg*  ||
    NAME =~ *u_i2s/left_2_reg*  || NAME =~ *u_i2s/left_3_reg*
}]
set_max_delay -datapath_only 20.000 -from $mic_sd_ports -to $mic_capture_regs

# proc_sys_reset deasserts synchronously in each destination domain. Its output
# is nevertheless connected to asynchronous reset pins, so recovery/removal
# timing from the reset generator's own clock pin is intentionally excluded.
set reset_launch_pins [get_pins -hier -quiet -filter {
    NAME =~ *rst_*/U0/ACTIVE_LOW_PR_OUT_DFF*/C
}]
set_false_path -from $reset_launch_pins

# Targeted exceptions for the custom CDC primitives. These cover only first
# synchronizer stages and data buses protected by their toggle/Gray handshakes.
set cdc_first_stage [get_cells -hier -quiet -filter {
    NAME =~ *u_snapshot/toggle_s1_reg ||
    NAME =~ *u_fifo/rd_gray_s1_reg* || NAME =~ *u_fifo/wr_gray_s1_reg* ||
    NAME =~ *camera/inst/enhance_enable_s1_reg
}]
set_false_path -to $cdc_first_stage

# Raw camera pins are observed by a 100 MHz diagnostic sampler.  Only its
# first metastability-catching stage is asynchronous; later stages remain
# timed normally in the FCLK domain.
set camera_probe_first_stage [get_cells -hier -quiet -filter {
    NAME =~ *camera_probe* && (
        NAME =~ *pclk_sync_reg?0? ||
        NAME =~ *vsync_sync_reg?0? ||
        NAME =~ *href_sync_reg?0? ||
        NAME =~ *data_meta_reg*
    )
}]
set_false_path -to $camera_probe_first_stage

# Camera-only PS GPIO completion/test levels: constrain only first FFs.
set camera_config_first_stage [get_cells -hier -quiet -filter {
    NAME =~ *u_config/done_sync_reg?0? || NAME =~ *u_config/test_sync_reg?0?
}]
set_false_path -to $camera_config_first_stage

set snapshot_src [get_cells -hier -quiet -filter {NAME =~ *u_snapshot/held_data_reg*}]
set snapshot_dst [get_cells -hier -quiet -filter {NAME =~ *u_snapshot/dst_data_reg*}]
set_false_path -from $snapshot_src -to $snapshot_dst

set event_dst [get_cells -hier -quiet -filter {NAME =~ *gamma_cdc*/u_fifo/dst_data_reg*}]
# The RAM word is sampled only after the synchronized Gray pointer proves that
# entry stable.  The RAM32M output has no legal timing startpoint in 2018.3, so
# constrain the bundle at its dedicated destination registers.  No functional
# path other than the protected FIFO data bus terminates at these registers.
set_false_path -to $event_dst
