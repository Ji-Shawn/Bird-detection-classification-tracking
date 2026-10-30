# AX7020 V2.0 BANK34; user-confirmed SDA=R16. DDC is not driven in this video-only implementation.
set_property PACKAGE_PIN N18 [get_ports hdmi_clk_p]
set_property PACKAGE_PIN P19 [get_ports hdmi_clk_n]
set_property PACKAGE_PIN V20 [get_ports {hdmi_data_p[0]}]
set_property PACKAGE_PIN W20 [get_ports {hdmi_data_n[0]}]
set_property PACKAGE_PIN T20 [get_ports {hdmi_data_p[1]}]
set_property PACKAGE_PIN U20 [get_ports {hdmi_data_n[1]}]
set_property PACKAGE_PIN N20 [get_ports {hdmi_data_p[2]}]
set_property PACKAGE_PIN P20 [get_ports {hdmi_data_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_clk_p hdmi_clk_n hdmi_data_p[*] hdmi_data_n[*]}]
set_property PACKAGE_PIN V16 [get_ports hdmi_out_en]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_out_en]
set_property PACKAGE_PIN Y19 [get_ports hdmi_hpd]
set_property IOSTANDARD LVCMOS33 [get_ports hdmi_hpd]
# The V2.0 HPD buffer is open-drain; its FPGA side needs an internal pull-up.
set_property PULLUP true [get_ports hdmi_hpd]
# Only asynchronous external HPD -> first synchronizer is excepted.
set_false_path -from [get_ports hdmi_hpd] -to [get_cells -hier -filter {NAME =~ *hpd_sync_reg*0*}]
