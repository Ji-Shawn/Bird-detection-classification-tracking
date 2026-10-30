# Bundled data held stable by request/ack; consume only on vertical blank.
set_false_path -to [get_cells -hier -filter {NAME =~ *hdmi_osd*/req_sync_reg*0*}]
set_false_path -to [get_cells -hier -filter {NAME =~ *hdmi_osd*/ack_sync_reg*0*}]
set_max_delay -reset_path -datapath_only 8.0 -from [get_cells -hier -filter {NAME =~ *hdmi_osd*/regs_reg*}] -to [get_cells -hier -filter {NAME =~ *hdmi_osd*/box_live_reg* || NAME =~ *hdmi_osd*/box_on_reg* || NAME =~ *hdmi_osd*/text_live_reg*}]
set_bus_skew 8.0 -from [get_cells -hier -filter {NAME =~ *hdmi_osd*/regs_reg*}] -to [get_cells -hier -filter {NAME =~ *hdmi_osd*/box_live_reg* || NAME =~ *hdmi_osd*/box_on_reg* || NAME =~ *hdmi_osd*/text_live_reg*}]
