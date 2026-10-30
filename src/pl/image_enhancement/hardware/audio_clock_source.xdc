# The audio Clocking Wizard input is driven directly by PS FCLK0, not a board
# oscillator. Override its generated IP XDC's duplicate primary clock with a
# 1:1 derived clock, retaining its name and inheriting PS clock latency/jitter.
# Verified fan-in: av_system_i/ps7/inst/PS7_i/FCLKCLK[0].
create_generated_clock -name av_system_i/clk_audio/inst/clk_in1 -source [get_pins {av_system_i/ps7/inst/PS7_i/FCLKCLK[0]}] -divide_by 1 [get_pins av_system_i/clk_audio/inst/clk_in1]
set_clock_uncertainty -hold 0.200 [all_clocks]
