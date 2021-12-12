add log -r sim:/vga_tb/*

add wave -position insertpoint  \
-divider " - GENERICS - " \
sim:/vga_tb/ref_clk_perd_g \
sim:/vga_tb/max_sim_time_g \
sim:/vga_tb/CONF_SIM \
sim:/vga_tb/CONF_TEST_PATT \
-divider " - TB SIGNALS - " \
sim:/vga_tb/clk \
sim:/vga_tb/rst_n \
sim:/vga_tb/dut_v_sync_out \
sim:/vga_tb/dut_h_sync_out \
sim:/vga_tb/dut_r_colr_out \
sim:/vga_tb/dut_g_colr_out \
sim:/vga_tb/dut_b_colr_out

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

#run 500 ms
run -all
wave zoom full
config wave -signalnamewidth 1
