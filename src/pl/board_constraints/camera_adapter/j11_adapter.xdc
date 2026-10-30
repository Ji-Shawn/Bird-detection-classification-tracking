# Adapter J1 plugs into AX7020 J11 pins 1..18, with matching pin-1 orientation.
# The PCB connects J1-13=VSYNC, J1-15=HREF, J1-17=RESET_N.
# Apply after the baseline ax7020_av.xdc; all other camera/servo pins are retained.
set_property PACKAGE_PIN M20 [get_ports cam_vsync]
set_property PACKAGE_PIN K18 [get_ports cam_href]
set_property PACKAGE_PIN J19 [get_ports cam_reset_n]
