set m51_pl_out ${reproduction_root}/pl_create
source ${package_root}/build/pl/create_project.tcl
set report [open ${reproduction_root}/pl_create_check.txt w]
puts $report "ip_count=[llength [get_ips]]"
puts $report "cwd=[pwd]"
puts $report "root_summary_exists=[file exists ${package_root}/NA]"
close $report
puts PL_OUTPUT_DIRECTORY_CHECK_PASS
exit
