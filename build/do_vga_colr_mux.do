add wave -position insertpoint  \
sim:/vga_colr_mux_tb/depth_colr_g \
sim:/vga_colr_mux_tb/colr_i_s \
sim:/vga_colr_mux_tb/colr_o_s \
sim:/vga_colr_mux_tb/en_i_s
set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0
run -all
wave zoom full