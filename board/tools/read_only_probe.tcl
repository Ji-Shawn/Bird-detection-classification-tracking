# Host-side memmap declarations permit reads; no reset/stop/download/mwr is used.
if {![info exists ::env(M51_PACKAGE_VERIFIED)] || $::env(M51_PACKAGE_VERIFIED) ne "1"} {
    error "Use launch.py sdcheck after offline package verification"
}
source [file join [file dirname [info script]] select_cable.tcl]
connect -url tcp:127.0.0.1:3121
m51_select_cable
m51_apu
set bootmode [mrd -value 0xf800025c]
puts "M51_BOOT_MODE=$bootmode"
if {($bootmode & 7) != 5} {error "Board boot selection is not SD"}
set pcfg [mrd -value 0xf800700c]
puts "M51_PCFG=$pcfg"
if {($pcfg & 4) == 0} {error "SD programmable logic configuration is incomplete"}
memmap -addr 0x43c00000 -size 0x10000 -flags 3
puts "M51_PL_ID=[mrd -value 0x43c00000]"
puts "M51_PL_VERSION=[mrd -value 0x43c00004]"
puts "M51_SERVO_ID=[mrd -value 0x43c00088]"
puts "M51_FRAME_FIRST=[mrd -value 0x43c0001c]"
puts "M51_SHARED_READY=[mrd -value 0x3003f000]"
puts "M51_SHARED_BOOT=[mrd -value 0x3003f040]"
puts "M51_SD_MAILBOX=[mrd -value 0x3003f200 32]"
after 1000
puts "M51_FRAME_SECOND=[mrd -value 0x43c0001c]"
puts "M51_READ_ONLY_PROBE_COMPLETE=1"
disconnect
exit 0
