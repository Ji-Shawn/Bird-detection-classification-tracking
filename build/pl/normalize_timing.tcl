# Remove the overridden IP primary-clock statements from the timing database.
# Vivado can retain the old 0.100 ns input jitter after an in-place clock-type
# override. Reloading the complete XDC without those two statements makes the
# audio clock inherit the real PS FCLK0 jitter (0.300 ns) from a clean database.
# m51_pl_out is established by build_pl.tcl.
set norm_root $m51_pl_out
file mkdir $norm_root/results
write_xdc -force -exclude_physical $norm_root/results/constraints_before_normalize.xdc
set fd [open $norm_root/results/constraints_before_normalize.xdc r]
set norm_text [read $fd];close $fd
# Older project snapshots registered the previous full timing export as an XDC.
# Drop that duplicate section, retaining every original IP and user section.
set clean_text ""
set skip_export 0
set exported_bindings [dict create]
foreach line [split $norm_text "\n"] {
 if {[regexp {^# Constraints from file : '(.*)'$} $line unused source_name]} {
  set skip_export [expr {$source_name eq "constraints_normalized.xdc"}]
 }
 if {$skip_export && [regexp {^set (_xlnx_shared_i[0-9]+) (.+)$} $line unused shared_name shared_expression]} {
  if {![string match {*]} $shared_expression]} {error "Inspect multiline shared XDC binding before deduplication"}
  dict set exported_bindings $shared_name $shared_expression
 }
 if {!$skip_export} {append clean_text "$line\n"}
}
dict for {shared_name shared_expression} $exported_bindings {
 set clean_text [string map [list "\$$shared_name" $shared_expression] $clean_text]
}
set norm_text $clean_text
set bad_clock {create_clock -period 10.000 [get_ports -scoped_to_current_instance clk_in1]}
set bad_jitter {set_input_jitter [get_clocks -of_objects [get_ports -scoped_to_current_instance clk_in1]] 0.100}
foreach line [list $bad_clock $bad_jitter] {
 # A previously normalized checkpoint may already have removed this statement.
 if {[string first $line $norm_text] < 0} {continue}
 # Both verified FCLK0-driven clock wizards contain this duplicate primary declaration.
 set norm_text [string map [list "$line\n" ""] $norm_text]
}
set fd [open $norm_root/results/constraints_normalized.xdc w]
puts -nonewline $fd $norm_text;close $fd
reset_timing
set prior_normalized [get_files -all -quiet *constraints_normalized.xdc]
if {[llength $prior_normalized]} {remove_files $prior_normalized}
read_xdc -unmanaged $norm_root/results/constraints_normalized.xdc
set audio_input_clock [get_clocks av_system_i/clk_audio/inst/clk_in1]
if {[llength $audio_input_clock]!=1 || ![get_property IS_GENERATED $audio_input_clock]} {
 error "Audio input must be derived from PS FCLK0"
}
if {[get_property MASTER_CLOCK $audio_input_clock] ne "clk_fpga_0"} {
 error "Unexpected audio master clock"
}
