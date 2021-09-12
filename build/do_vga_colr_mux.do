add log -r sim:/vga_colr_mux_tb/*

add wave -position insertpoint  \
-divider " - GENERICS - " \
sim:/vga_colr_mux_tb/depth_colr_g \
-divider " - DUT_SIGNALS - " \
sim:/vga_colr_mux_tb/colr_i_s \
sim:/vga_colr_mux_tb/colr_o_s \
sim:/vga_colr_mux_tb/en_i_s

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run -all
wave zoom full
config wave -signalnamewidth 1