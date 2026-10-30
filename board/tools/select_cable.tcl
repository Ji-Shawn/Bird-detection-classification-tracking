# Select one explicitly named cable or the only connected cable. No board writes.
proc m51_select_cable {} {
    set cables [jtag targets -target-properties -filter {level == 0}]
    if {[info exists ::env(M51_CABLE)] && $::env(M51_CABLE) ne ""} {
        set selected {}
        foreach candidate $cables {
            if {[dict exists $candidate jtag_cable_serial] &&
                [dict get $candidate jtag_cable_serial] eq $::env(M51_CABLE)} {
                lappend selected $candidate
            }
        }
        set cables $selected
    }
    if {[llength $cables] != 1} {
        error "Expected one JTAG cable; connect one board or specify --cable. Found [llength $cables]."
    }
    set chosen [lindex $cables 0]
    set id [dict get $chosen node_id]
    jtag targets -set $id
    if {![dict exists $chosen jtag_cable_serial]} {error "Cable serial is unavailable"}
    set ::m51_serial [dict get $chosen jtag_cable_serial]
    if {![regexp {^[A-Za-z0-9_-]{1,128}$} $::m51_serial]} {error "Unsupported cable serial format"}
    puts "M51_CABLE_SELECTED=$::m51_serial"
}

proc m51_cpu {core} {
    targets -set -nocase -filter [format {name =~ "*A9*#%d" && jtag_cable_serial == "%s"} $core $::m51_serial]
}

proc m51_apu {} {
    targets -set -nocase -filter [format {name =~ "APU*" && jtag_cable_serial == "%s"} $::m51_serial]
}
