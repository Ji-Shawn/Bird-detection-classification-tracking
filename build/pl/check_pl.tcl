# Run create_project.tcl first. Elaborate RTL without optimization/place/route.
set m51_root [file normalize [file join [file dirname [info script]] ../..]]
set m51_pl_out [file join $m51_root build/out/pl]
open_project [file join $m51_pl_out project/m51_pl.xpr]
set rom_dir [file join $m51_pl_out rom]
file mkdir $rom_dir
foreach p [get_files -all -quiet *.hex] {file copy -force $p [file join $rom_dir [file tail $p]]}
cd $rom_dir
synth_design -rtl -top av_system_wrapper -part xc7z020clg400-2
if {[llength [get_ports {board_keys_n[*]}]]!=4} {error "Four-key external boundary missing"}
set f [open [file join $m51_pl_out rtl_elaboration.txt] w]
puts $f "top=[current_design]"
puts $f "ports=[llength [get_ports]]"
puts $f "cells=[llength [get_cells -hier]]"
close $f
puts M51_STRUCTURAL_RTL_ELABORATION_PASS
exit
