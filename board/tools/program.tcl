# Published M51 JTAG bootstrap, with checkout-relative paths and cable selection.
if {![info exists ::env(M51_PACKAGE_VERIFIED)] || $::env(M51_PACKAGE_VERIFIED) ne "1"} {
    error "Use launch.py program --program after offline package verification"
}
set root [file normalize $::env(M51_PACKAGE_ROOT)]
set fw [file join $root board firmware]
source [file join [file dirname [info script]] select_cable.tcl]
connect -url tcp:127.0.0.1:3121
m51_select_cable
puts "JTAG_HZ=[jtag frequency 1000000]"
foreach core {0 1} {
    m51_cpu $core
    if {[catch {stop} msg] && $msg ne "Already stopped"} {error $msg}
}
m51_apu
memmap -addr 0x43C00000 -size 0x10000 -flags 3
set tilt_us 1140
set servo_seed [list 0x53525032 170000 170000 0 $tilt_us 0 0]
set seed_check 0xa5a55a5a
foreach word $servo_seed {set seed_check [expr {$seed_check ^ $word}]}
lappend servo_seed $seed_check
puts "M51_START_TILT_US=$tilt_us START_TILT_DEG=60 AUTO_TRACKING_OFF=1 YAW_REFERENCE_INVALID=1"
rst -system
after 500
puts "RESET_TARGETS=[targets]"
foreach core {0 1} {
    m51_cpu $core
    if {[catch {stop} msg] && $msg ne "Already stopped"} {error $msg}
    puts "POST_RESET_CORE_${core}_STOPPED"
}
m51_apu
source [file join $fw ps7_init.tcl]
# Host delays preserve the original SCU global timer rule.
proc mask_delay {address milliseconds} {after $milliseconds}
ps7_init
fpga -file [file join $fw system.bit]
ps7_post_config
memmap -addr 0x43C00000 -size 0x10000 -flags 3
if {[mrd -value 0x43C00004] != 0x0001000A ||
    [mrd -value 0x43C00088] != 0x53525631} {error "Wrong servo register version"}
mwr 0x43C00080 2
set saved_tilt [lindex $servo_seed 4]
if {$saved_tilt<540 || $saved_tilt>2281} {error "Invalid saved tilt"}
mwr 0x43C0007C [expr {wide(round(98305085.0*$saved_tilt/1000000.0))}]
mwr 0x43C00080 6
memmap -addr 0x41210000 -size 0x10000 -flags 3
mwr 0x41210000 1
after 100
puts "HDMI_INITIAL_STATUS=[mrd -value 0x41210008]"
puts "SERVO_PL_CAPABILITY_VERIFIED"
m51_cpu 0
mwr 0x30F01008 0
mwr 0x30F01004 0
mwr 0x30F01000 0
mwr 0x3003F000 0
for {set i 0} {$i<8} {incr i} {
    set word [expr {$i<[llength $servo_seed]?[lindex $servo_seed $i]:0}]
    mwr [expr {0x30F01100+4*$i}] $word
}
source $::env(M51_ASSET_SCRIPT)
dow [file join $fw core0.elf]
m51_cpu 1
dow [file join $fw core1.elf]
m51_cpu 0
# This address is valid only for the hash-pinned published Core0 ELF.
mwr 0x00165808 10
puts "VIDEO_GAP_US=10"
mwr 0x30F01000 0x4D313157
con
after 200
m51_cpu 1
con
puts "M51_PROGRAM_COMPLETE=1"
disconnect
exit 0
