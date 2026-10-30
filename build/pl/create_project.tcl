# Fresh project from current M51/M50 four-key sources. No cached IP or checkpoints.
set m51_root [file normalize [file join [file dirname [info script]] ../..]]
if {![info exists m51_pl_out]} {set m51_pl_out [file join $m51_root build/out/pl]}
file mkdir $m51_pl_out
create_project m51_pl [file join $m51_pl_out project] -part xc7z020clg400-2 -force
config_ip_cache -disable_cache
set_property ip_repo_paths [list [file join $m51_root src/pl/ip_repo]] [current_project]
update_ip_catalog
set_property include_dirs [list [file join $m51_root src/pl/logmel/rom]] [get_filesets sources_1]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/camera_cdc_or_fifo.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/camera_cdc_or_fifo.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/camera_eth_adapter.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/camera_eth_adapter.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/model_video_axis.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/model_video_axis.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/ov5640_dvp_capture.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/ov5640_dvp_capture.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/ov5640_sccb_config.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/ov5640_sccb_config.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/video_axis_fifo565.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/video_axis_fifo565.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/auto_vision_top.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/auto_vision_top.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/frame_histogram.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/frame_histogram.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/gamma_rom.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/gamma_rom.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/hist_gain_pipeline.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/hist_gain_pipeline.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/hist_lut_builder.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/hist_lut_builder.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/hist_mode_ctrl.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/hist_mode_ctrl.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/live_frame_stats.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/live_frame_stats.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/unsigned_divider.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/unsigned_divider.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/camera_pipeline_top.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/camera_pipeline_top.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/audio_dma_axis.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/audio_dma_axis.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/audio_frontend_top.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/audio_frontend_top.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/av_regs.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/av_regs.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/beam_sum_sat.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/beam_sum_sat.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/beamformer4.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/beamformer4.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/fractional_delay.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/fractional_delay.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/i2s_quad_rx.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/i2s_quad_rx.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/model_mel_axis.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/model_mel_axis.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/servo_pwm_pair.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/servo_pwm_pair.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/audio_control_top.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/audio/audio_control_top.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/async_event_fifo.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/async_event_fifo.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/gamma_event_cdc.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/gamma_event_cdc.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/cdc_snapshot.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/cdc_snapshot.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/av_status_cdc.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/av_status_cdc.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/camera_ctrl_io.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/camera_ctrl_io.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/camera_input_probe.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/control/camera_input_probe.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/model/model_ingress_stub.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/model/model_ingress_stub.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/hardware/dw_core_rtl.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/capture_and_inference/hardware/dw_core_rtl.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/hardware/mac_pool_rtl.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/capture_and_inference/hardware/mac_pool_rtl.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/hardware/pw_core_rtl.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/capture_and_inference/hardware/pw_core_rtl.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/hardware/mnet_engine_rtl.v]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/hardware/mnet_engine_rtl.v]]
add_files -norecurse [file join $m51_root src/pl/logmel/rom/config.vh]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/logmel/rom/config.vh]]
add_files -norecurse [file join $m51_root src/pl/logmel/rtl/logmel_frame.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/logmel/rtl/logmel_frame.sv]]
add_files -norecurse [file join $m51_root src/pl/logmel/rtl/logmel_axis_wrap.v]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/logmel/rtl/logmel_axis_wrap.v]]
add_files -norecurse [file join $m51_root src/pl/ssd_preprocess/rtl/ssd_preprocess.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/ssd_preprocess/rtl/ssd_preprocess.sv]]
add_files -norecurse [file join $m51_root src/pl/ssd_preprocess/rtl/ssd_axis_wrap.v]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/ssd_preprocess/rtl/ssd_axis_wrap.v]]
add_files -norecurse [file join $m51_root src/pl/hdmi/rtl/rgb565_axis.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/hdmi/rtl/rgb565_axis.sv]]
add_files -norecurse [file join $m51_root src/pl/hdmi/rtl/hdmi_raster.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/hdmi/rtl/hdmi_raster.sv]]
add_files -norecurse [file join $m51_root src/pl/hdmi/rtl/hdmi_status_cdc.v]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/hdmi/rtl/hdmi_status_cdc.v]]
add_files -norecurse [file join $m51_root src/pl/on_screen_display/rtl/board_osd.v]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/on_screen_display/rtl/board_osd.v]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/ov5640_dvp_rx.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/ov5640_dvp_rx.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/rgb_ycbcr.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/rgb_ycbcr.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/luma_stats.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/luma_stats.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/box_mean_stream.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/box_mean_stream.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/multiscale_illum.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/multiscale_illum.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/luma_enhance.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/luma_enhance.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/video_enhance_top.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/video_enhance_top.sv]]
add_files -norecurse [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/video_frame_framer.sv]
set_property file_type {Verilog} [get_files [file join $m51_root src/pl/capture_and_inference/capture/pl/rtl/video/video_frame_framer.sv]]
add_files -norecurse [file join $m51_root src/pl/image_enhancement/rtl/histogram_vision_top.sv]
set_property file_type {SystemVerilog} [get_files [file join $m51_root src/pl/image_enhancement/rtl/histogram_vision_top.sv]]
add_files -norecurse [file join $m51_root src/pl/logmel/rom/hann.hex]
add_files -norecurse [file join $m51_root src/pl/logmel/rom/log.hex]
add_files -norecurse [file join $m51_root src/pl/logmel/rom/mel_ops.hex]
add_files -norecurse [file join $m51_root src/pl/logmel/rom/tw_im.hex]
add_files -norecurse [file join $m51_root src/pl/logmel/rom/tw_re.hex]
add_files -norecurse [file join $m51_root src/pl/ssd_preprocess/rom/quant0.hex]
add_files -norecurse [file join $m51_root src/pl/ssd_preprocess/rom/quant1.hex]
add_files -norecurse [file join $m51_root src/pl/ssd_preprocess/rom/quant2.hex]
add_files -norecurse [file join $m51_root src/pl/on_screen_display/rtl/font.hex]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/capture_and_inference/capture/vivado/constraints/ax7020_av.xdc]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/image_enhancement/hardware/logmel_hold.xdc]
set_property used_in_synthesis false [get_files [file join $m51_root src/pl/image_enhancement/hardware/logmel_hold.xdc]]
set_property processing_order LATE [get_files [file join $m51_root src/pl/image_enhancement/hardware/logmel_hold.xdc]]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/image_enhancement/hardware/audio_clock_source.xdc]
set_property used_in_synthesis false [get_files [file join $m51_root src/pl/image_enhancement/hardware/audio_clock_source.xdc]]
set_property processing_order LATE [get_files [file join $m51_root src/pl/image_enhancement/hardware/audio_clock_source.xdc]]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/hdmi/hardware/hdmi.xdc]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/hdmi/hardware/hdmi_clock_source.xdc]
set_property used_in_synthesis false [get_files [file join $m51_root src/pl/hdmi/hardware/hdmi_clock_source.xdc]]
set_property processing_order LATE [get_files [file join $m51_root src/pl/hdmi/hardware/hdmi_clock_source.xdc]]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/display_constraints/hardware/osd_cdc.xdc]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/display_constraints/hardware/hdmi_clock_source.xdc]
set_property used_in_synthesis false [get_files [file join $m51_root src/pl/display_constraints/hardware/hdmi_clock_source.xdc]]
set_property processing_order LATE [get_files [file join $m51_root src/pl/display_constraints/hardware/hdmi_clock_source.xdc]]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/on_screen_display/hardware/hdmi_clock_source.xdc]
set_property used_in_synthesis false [get_files [file join $m51_root src/pl/on_screen_display/hardware/hdmi_clock_source.xdc]]
set_property processing_order LATE [get_files [file join $m51_root src/pl/on_screen_display/hardware/hdmi_clock_source.xdc]]
add_files -fileset constrs_1 -norecurse [file join $m51_root src/pl/board_constraints/buttons/hardware/board_keys.xdc]
set_property used_in_synthesis false [get_files [file join $m51_root src/pl/board_constraints/buttons/hardware/board_keys.xdc]]
set_property processing_order LATE [get_files [file join $m51_root src/pl/board_constraints/buttons/hardware/board_keys.xdc]]
add_files -norecurse [file join $m51_root src/pl/structural/av_system.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_wrapper.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_audio_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_cam_io_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_camera_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_camera_probe_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_gamma_cdc_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_hdmi_osd_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_hdmi_raster_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_hdmi_rgb_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_hdmi_status_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_inference_engine_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_mel_core_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_model_ingress_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_ssd_preprocess_core_0.v]
add_files -norecurse [file join $m51_root src/pl/structural/av_system_status_cdc_0.v]
# Copy configuration into ignored output; generation never changes packaged sources.
set ip_out [file join $m51_pl_out ip]
file mkdir $ip_out
file mkdir [file join $ip_out av_system_auto_cc_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_cc_0/av_system_auto_cc_0.xci] [file join $ip_out av_system_auto_cc_0 av_system_auto_cc_0.xci]
read_ip [file join $ip_out av_system_auto_cc_0 av_system_auto_cc_0.xci]
file mkdir [file join $ip_out av_system_auto_pc_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_pc_0/av_system_auto_pc_0.xci] [file join $ip_out av_system_auto_pc_0 av_system_auto_pc_0.xci]
read_ip [file join $ip_out av_system_auto_pc_0 av_system_auto_pc_0.xci]
file mkdir [file join $ip_out av_system_auto_pc_1]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_pc_1/av_system_auto_pc_1.xci] [file join $ip_out av_system_auto_pc_1 av_system_auto_pc_1.xci]
read_ip [file join $ip_out av_system_auto_pc_1 av_system_auto_pc_1.xci]
file mkdir [file join $ip_out av_system_auto_pc_2]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_pc_2/av_system_auto_pc_2.xci] [file join $ip_out av_system_auto_pc_2 av_system_auto_pc_2.xci]
read_ip [file join $ip_out av_system_auto_pc_2 av_system_auto_pc_2.xci]
file mkdir [file join $ip_out av_system_auto_pc_3]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_pc_3/av_system_auto_pc_3.xci] [file join $ip_out av_system_auto_pc_3 av_system_auto_pc_3.xci]
read_ip [file join $ip_out av_system_auto_pc_3 av_system_auto_pc_3.xci]
file mkdir [file join $ip_out av_system_auto_pc_4]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_pc_4/av_system_auto_pc_4.xci] [file join $ip_out av_system_auto_pc_4 av_system_auto_pc_4.xci]
read_ip [file join $ip_out av_system_auto_pc_4 av_system_auto_pc_4.xci]
file mkdir [file join $ip_out av_system_auto_us_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_us_0/av_system_auto_us_0.xci] [file join $ip_out av_system_auto_us_0 av_system_auto_us_0.xci]
read_ip [file join $ip_out av_system_auto_us_0 av_system_auto_us_0.xci]
file mkdir [file join $ip_out av_system_auto_us_1]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_us_1/av_system_auto_us_1.xci] [file join $ip_out av_system_auto_us_1 av_system_auto_us_1.xci]
read_ip [file join $ip_out av_system_auto_us_1 av_system_auto_us_1.xci]
file mkdir [file join $ip_out av_system_auto_us_2]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_us_2/av_system_auto_us_2.xci] [file join $ip_out av_system_auto_us_2 av_system_auto_us_2.xci]
read_ip [file join $ip_out av_system_auto_us_2 av_system_auto_us_2.xci]
file mkdir [file join $ip_out av_system_auto_us_3]
file copy -force [file join $m51_root src/pl/ip_config/av_system_auto_us_3/av_system_auto_us_3.xci] [file join $ip_out av_system_auto_us_3 av_system_auto_us_3.xci]
read_ip [file join $ip_out av_system_auto_us_3 av_system_auto_us_3.xci]
file mkdir [file join $ip_out av_system_cam_gpio_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_cam_gpio_0/av_system_cam_gpio_0.xci] [file join $ip_out av_system_cam_gpio_0 av_system_cam_gpio_0.xci]
read_ip [file join $ip_out av_system_cam_gpio_0 av_system_cam_gpio_0.xci]
file mkdir [file join $ip_out av_system_clk_audio_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_clk_audio_0/av_system_clk_audio_0.xci] [file join $ip_out av_system_clk_audio_0 av_system_clk_audio_0.xci]
read_ip [file join $ip_out av_system_clk_audio_0 av_system_clk_audio_0.xci]
file mkdir [file join $ip_out av_system_clk_hdmi_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_clk_hdmi_0/av_system_clk_hdmi_0.xci] [file join $ip_out av_system_clk_hdmi_0 av_system_clk_hdmi_0.xci]
read_ip [file join $ip_out av_system_clk_hdmi_0 av_system_clk_hdmi_0.xci]
file mkdir [file join $ip_out av_system_const_one_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_const_one_0/av_system_const_one_0.xci] [file join $ip_out av_system_const_one_0 av_system_const_one_0.xci]
read_ip [file join $ip_out av_system_const_one_0 av_system_const_one_0.xci]
file mkdir [file join $ip_out av_system_const_zero_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_const_zero_0/av_system_const_zero_0.xci] [file join $ip_out av_system_const_zero_0 av_system_const_zero_0.xci]
read_ip [file join $ip_out av_system_const_zero_0 av_system_const_zero_0.xci]
file mkdir [file join $ip_out av_system_ctrl_cdc_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_ctrl_cdc_0/av_system_ctrl_cdc_0.xci] [file join $ip_out av_system_ctrl_cdc_0 av_system_ctrl_cdc_0.xci]
read_ip [file join $ip_out av_system_ctrl_cdc_0 av_system_ctrl_cdc_0.xci]
file mkdir [file join $ip_out av_system_dma_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_dma_0/av_system_dma_0.xci] [file join $ip_out av_system_dma_0 av_system_dma_0.xci]
read_ip [file join $ip_out av_system_dma_0 av_system_dma_0.xci]
file mkdir [file join $ip_out av_system_dma_proto_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_dma_proto_0/av_system_dma_proto_0.xci] [file join $ip_out av_system_dma_proto_0 av_system_dma_proto_0.xci]
read_ip [file join $ip_out av_system_dma_proto_0 av_system_dma_proto_0.xci]
file mkdir [file join $ip_out av_system_dma_width_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_dma_width_0/av_system_dma_width_0.xci] [file join $ip_out av_system_dma_width_0 av_system_dma_width_0.xci]
read_ip [file join $ip_out av_system_dma_width_0 av_system_dma_width_0.xci]
file mkdir [file join $ip_out av_system_hdmi_encoder_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_hdmi_encoder_0/av_system_hdmi_encoder_0.xci] [file join $ip_out av_system_hdmi_encoder_0 av_system_hdmi_encoder_0.xci]
read_ip [file join $ip_out av_system_hdmi_encoder_0 av_system_hdmi_encoder_0.xci]
file mkdir [file join $ip_out av_system_hdmi_video_out_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_hdmi_video_out_0/av_system_hdmi_video_out_0.xci] [file join $ip_out av_system_hdmi_video_out_0 av_system_hdmi_video_out_0.xci]
read_ip [file join $ip_out av_system_hdmi_video_out_0 av_system_hdmi_video_out_0.xci]
file mkdir [file join $ip_out av_system_infer_dma_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_infer_dma_0/av_system_infer_dma_0.xci] [file join $ip_out av_system_infer_dma_0 av_system_infer_dma_0.xci]
read_ip [file join $ip_out av_system_infer_dma_0 av_system_infer_dma_0.xci]
file mkdir [file join $ip_out av_system_irq_concat_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_irq_concat_0/av_system_irq_concat_0.xci] [file join $ip_out av_system_irq_concat_0 av_system_irq_concat_0.xci]
read_ip [file join $ip_out av_system_irq_concat_0 av_system_irq_concat_0.xci]
file mkdir [file join $ip_out av_system_mel_dma_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_mel_dma_0/av_system_mel_dma_0.xci] [file join $ip_out av_system_mel_dma_0 av_system_mel_dma_0.xci]
read_ip [file join $ip_out av_system_mel_dma_0 av_system_mel_dma_0.xci]
file mkdir [file join $ip_out av_system_pcm_cdc_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_pcm_cdc_0/av_system_pcm_cdc_0.xci] [file join $ip_out av_system_pcm_cdc_0 av_system_pcm_cdc_0.xci]
read_ip [file join $ip_out av_system_pcm_cdc_0 av_system_pcm_cdc_0.xci]
file mkdir [file join $ip_out av_system_ps7_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_ps7_0/av_system_ps7_0.xci] [file join $ip_out av_system_ps7_0 av_system_ps7_0.xci]
read_ip [file join $ip_out av_system_ps7_0 av_system_ps7_0.xci]
file mkdir [file join $ip_out av_system_rst_audio_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_rst_audio_0/av_system_rst_audio_0.xci] [file join $ip_out av_system_rst_audio_0 av_system_rst_audio_0.xci]
read_ip [file join $ip_out av_system_rst_audio_0 av_system_rst_audio_0.xci]
file mkdir [file join $ip_out av_system_rst_fclk_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_rst_fclk_0/av_system_rst_fclk_0.xci] [file join $ip_out av_system_rst_fclk_0 av_system_rst_fclk_0.xci]
read_ip [file join $ip_out av_system_rst_fclk_0 av_system_rst_fclk_0.xci]
file mkdir [file join $ip_out av_system_rst_hdmi_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_rst_hdmi_0/av_system_rst_hdmi_0.xci] [file join $ip_out av_system_rst_hdmi_0 av_system_rst_hdmi_0.xci]
read_ip [file join $ip_out av_system_rst_hdmi_0 av_system_rst_hdmi_0.xci]
file mkdir [file join $ip_out av_system_rst_hdmi_read_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_rst_hdmi_read_0/av_system_rst_hdmi_read_0.xci] [file join $ip_out av_system_rst_hdmi_read_0 av_system_rst_hdmi_read_0.xci]
read_ip [file join $ip_out av_system_rst_hdmi_read_0 av_system_rst_hdmi_read_0.xci]
file mkdir [file join $ip_out av_system_rst_pixel_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_rst_pixel_0/av_system_rst_pixel_0.xci] [file join $ip_out av_system_rst_pixel_0 av_system_rst_pixel_0.xci]
read_ip [file join $ip_out av_system_rst_pixel_0 av_system_rst_pixel_0.xci]
file mkdir [file join $ip_out av_system_ssd_dma_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_ssd_dma_0/av_system_ssd_dma_0.xci] [file join $ip_out av_system_ssd_dma_0 av_system_ssd_dma_0.xci]
read_ip [file join $ip_out av_system_ssd_dma_0 av_system_ssd_dma_0.xci]
file mkdir [file join $ip_out av_system_vdma_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_vdma_0/av_system_vdma_0.xci] [file join $ip_out av_system_vdma_0 av_system_vdma_0.xci]
read_ip [file join $ip_out av_system_vdma_0 av_system_vdma_0.xci]
file mkdir [file join $ip_out av_system_vdma_proto_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_vdma_proto_0/av_system_vdma_proto_0.xci] [file join $ip_out av_system_vdma_proto_0 av_system_vdma_proto_0.xci]
read_ip [file join $ip_out av_system_vdma_proto_0 av_system_vdma_proto_0.xci]
file mkdir [file join $ip_out av_system_video_cdc_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_video_cdc_0/av_system_video_cdc_0.xci] [file join $ip_out av_system_video_cdc_0 av_system_video_cdc_0.xci]
read_ip [file join $ip_out av_system_video_cdc_0 av_system_video_cdc_0.xci]
file mkdir [file join $ip_out av_system_xbar_0]
file copy -force [file join $m51_root src/pl/ip_config/av_system_xbar_0/av_system_xbar_0.xci] [file join $ip_out av_system_xbar_0 av_system_xbar_0.xci]
read_ip [file join $ip_out av_system_xbar_0 av_system_xbar_0.xci]
file mkdir [file join $ip_out av_system_xbar_1]
file copy -force [file join $m51_root src/pl/ip_config/av_system_xbar_1/av_system_xbar_1.xci] [file join $ip_out av_system_xbar_1 av_system_xbar_1.xci]
read_ip [file join $ip_out av_system_xbar_1 av_system_xbar_1.xci]
file mkdir [file join $ip_out av_system_xbar_2]
file copy -force [file join $m51_root src/pl/ip_config/av_system_xbar_2/av_system_xbar_2.xci] [file join $ip_out av_system_xbar_2 av_system_xbar_2.xci]
read_ip [file join $ip_out av_system_xbar_2 av_system_xbar_2.xci]
file mkdir [file join $ip_out av_system_xbar_3]
file copy -force [file join $m51_root src/pl/ip_config/av_system_xbar_3/av_system_xbar_3.xci] [file join $ip_out av_system_xbar_3 av_system_xbar_3.xci]
read_ip [file join $ip_out av_system_xbar_3 av_system_xbar_3.xci]
set_property generate_synth_checkpoint false [get_files -all *.xci]
generate_target all [get_files -all *.xci]
set_property top av_system_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
puts M51_STRUCTURAL_PROJECT_AND_IP_GENERATION_PASS
