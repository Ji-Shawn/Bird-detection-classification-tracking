# Assertions only: no timing exceptions are added or relaxed here.
set mic_ports [get_ports -quiet {mic_sd_0 mic_sd_1 mic_sd_2 mic_sd_3}]
if {[llength $mic_ports] != 4} {error "Expected four microphone SD ports"}
set mic_regs [get_cells -hier -quiet -filter {
 NAME =~ *u_i2s/shift_0_reg* || NAME =~ *u_i2s/shift_1_reg* ||
 NAME =~ *u_i2s/shift_2_reg* || NAME =~ *u_i2s/shift_3_reg* ||
 NAME =~ *u_i2s/left_0_reg* || NAME =~ *u_i2s/left_1_reg* ||
 NAME =~ *u_i2s/left_2_reg* || NAME =~ *u_i2s/left_3_reg*
}]
if {[llength $mic_regs]==0} {error "Microphone timing endpoints missing"}
puts "NATIVE_CONSTRAINT_ENDPOINTS ports=[llength $mic_ports] registers=[llength $mic_regs]"
