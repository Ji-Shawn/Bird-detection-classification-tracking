# AX7020 PL KEY1..KEY4: low-active, board pull-ups, no expansion wiring.
set_property PACKAGE_PIN N15 [get_ports {board_keys_n[0]}]
set_property PACKAGE_PIN N16 [get_ports {board_keys_n[1]}]
set_property PACKAGE_PIN T17 [get_ports {board_keys_n[2]}]
set_property PACKAGE_PIN R17 [get_ports {board_keys_n[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {board_keys_n[*]}]
# Only asynchronous input -> first FF is excepted. FF1 -> FF2 remains timed.
set key_sync_first [get_cells -hier -quiet -filter {NAME =~ *audio/inst/board_keys_sync1_reg*}]
if {[llength $key_sync_first]!=4} {error "Expected four first-stage PL key synchronizers"}
set_false_path -from [get_ports {board_keys_n[*]}] -to $key_sync_first
