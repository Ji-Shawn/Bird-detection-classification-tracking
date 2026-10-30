# Run with Vivado 2023.2 -mode batch -source build/pl/build_pl.tcl.
set_param general.maxThreads 8
set m51_root [file normalize [file join [file dirname [info script]] ../..]]
set m51_pl_out [file join $m51_root build/out/pl]
source [file join $m51_root build/pl/create_project.tcl]
# readmemh basenames resolve to these exact copies. Vivado also receives them as sources.
set rom_dir [file join $m51_pl_out rom]
file mkdir $rom_dir
foreach p [get_files -all -quiet *.hex] {file copy -force $p [file join $rom_dir [file tail $p]]}
cd $rom_dir
synth_design -top av_system_wrapper -part xc7z020clg400-2 -flatten_hierarchy rebuilt
if {[llength [get_cells -hier -filter {NAME =~ *u_pool* && REF_NAME == DSP48E1}]]!=72} {error "DSP pool changed"}
write_checkpoint -force [file join $m51_pl_out synth.dcp]
opt_design
reset_property PACKAGE_PIN [get_ports {cam_vsync cam_href cam_reset_n}]
reset_property LOC [get_ports {cam_vsync cam_href cam_reset_n}]
read_xdc [file join $m51_root src/pl/board_constraints/camera_adapter/j11_adapter.xdc]
read_xdc [file join $m51_root src/pl/board_constraints/buttons/hardware/board_keys.xdc]
source [file join $m51_root build/pl/normalize_timing.tcl]
place_design
route_design
phys_opt_design -directive AggressiveExplore
write_checkpoint -force [file join $m51_pl_out adapter_routed.dcp]
source [file join $m51_root build/pl/validate_native_constraints.tcl]
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $m51_pl_out timing.rpt]
report_route_status -file [file join $m51_pl_out route.rpt]
report_drc -file [file join $m51_pl_out drc.rpt]
report_methodology -file [file join $m51_pl_out methodology.rpt]
report_cdc -file [file join $m51_pl_out cdc.rpt]
report_bus_skew -file [file join $m51_pl_out bus_skew.rpt]
report_utilization -hierarchical -hierarchical_depth 6 -file [file join $m51_pl_out utilization.rpt]
set f [open [file join $m51_pl_out timing.rpt]];set timing [read $f];close $f
if {[string first {All user specified timing constraints are met.} $timing]<0} {error "Timing failed"}
foreach check {no_clock unconstrained_internal_endpoints} {
 if {![regexp [format {checking %s \(([0-9]+)\)} $check] $timing unused count] || $count!=0} {error "Timing coverage failed: $check"}
}
foreach name {drc methodology} {
 set f [open [file join $m51_pl_out $name.rpt]];set text [read $f];close $f
 if {[regexp {\|\s+Error\s+\|} $text] || [string first {Critical Warning} $text]>=0} {error "Blocking finding: $name"}
}
set f [open [file join $m51_pl_out bus_skew.rpt]];set text [read $f];close $f
if {[string first VIOLATED $text]>=0} {error "Bus skew violation"}
write_bitstream -force [file join $m51_pl_out adapter_system.bit]
# The released XSA is retained with its exact PS/address descriptor. This
# structural rebuild exports a bitstream; address/PS changes require a new BD handoff.
puts M51_FRESH_PL_BUILD_PASS
exit
