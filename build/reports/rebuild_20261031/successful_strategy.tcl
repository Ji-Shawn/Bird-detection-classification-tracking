# Reuse the fresh synthesis result; keep the GitHub RTL, IP and constraints unchanged.
set_param general.maxThreads 8
set m51_pl_out [file normalize [file dirname [info script]]]
set m51_root [file normalize [file join $m51_pl_out ../../..]]
cd [file join $m51_pl_out rom]
open_checkpoint [file join $m51_pl_out synth.dcp]
if {[llength [get_cells -hier -filter {NAME =~ *u_pool* && REF_NAME == DSP48E1}]] != 72} {error "DSP pool changed"}
opt_design
reset_property PACKAGE_PIN [get_ports {cam_vsync cam_href cam_reset_n}]
reset_property LOC [get_ports {cam_vsync cam_href cam_reset_n}]
read_xdc [file join $m51_root src/pl/board_constraints/camera_adapter/j11_adapter.xdc]
read_xdc [file join $m51_root src/pl/board_constraints/buttons/hardware/board_keys.xdc]
source [file join $m51_root build/pl/normalize_timing.tcl]
set key_sync_first [get_cells -hier -quiet -filter {NAME =~ *audio/inst/board_keys_sync1_reg*}]
if {[llength $key_sync_first] != 4} {error "Expected four first-stage PL key synchronizers"}
place_design -directive Explore
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
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
set f [open [file join $m51_pl_out timing.rpt]]; set timing [read $f]; close $f
if {[string first {All user specified timing constraints are met.} $timing] < 0} {error "Timing failed"}
foreach check {no_clock unconstrained_internal_endpoints} {
    if {![regexp [format {checking %s \(([0-9]+)\)} $check] $timing unused count] || $count != 0} {error "Timing coverage failed: $check"}
}
foreach name {drc methodology} {
    set f [open [file join $m51_pl_out $name.rpt]]; set text [read $f]; close $f
    if {[regexp {\|\s+Error\s+\|} $text] || [string first {Critical Warning} $text] >= 0} {error "Blocking finding: $name"}
}
set f [open [file join $m51_pl_out bus_skew.rpt]]; set text [read $f]; close $f
if {[string first VIOLATED $text] >= 0} {error "Bus skew violation"}
write_bitstream -force [file join $m51_pl_out adapter_system.bit]
puts GITHUB_EXPLORE_BUILD_PASS
exit
