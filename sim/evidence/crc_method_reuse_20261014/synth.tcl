set here [file dirname [file normalize [info script]]]
cd $here
read_verilog -sv crc16_stream.sv
synth_design -top crc16_stream -part xc7z020clg400-2 -mode out_of_context
create_clock -name clk -period 10 [get_ports clk]
report_utilization -file crc_utilization.rpt
opt_design
place_design
route_design
report_timing_summary -file crc_timing.rpt
write_checkpoint -force crc_routed.dcp
exit
