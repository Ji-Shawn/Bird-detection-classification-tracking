# Both Clocking Wizard inputs are derived from the same PS FCLK0.
create_generated_clock -name av_system_i/clk_hdmi/inst/clk_in1 -source [get_pins {av_system_i/ps7/inst/PS7_i/FCLKCLK[0]}] -divide_by 1 [get_pins av_system_i/clk_hdmi/inst/clk_in1]
set hdmi_first [get_cells -hier -quiet -filter {NAME =~ *hdmi_status*/toggle_s1_reg || NAME =~ *hdmi_raster*/force_sync_reg?0?}]
set_false_path -to $hdmi_first
# Snapshot bus is held stable until a two-stage toggle has arrived.
set hdmi_snapshot_src [get_cells -hier -filter {NAME =~ *hdmi_status*/held_data_reg*}]
set hdmi_snapshot_dst [get_cells -hier -filter {NAME =~ *hdmi_status*/dst_data_reg*}]
set_max_delay -datapath_only 20.000 -from $hdmi_snapshot_src -to $hdmi_snapshot_dst
set_bus_skew 10.000 -from $hdmi_snapshot_src -to $hdmi_snapshot_dst
