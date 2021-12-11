add log -r sim:/vga_colr_gen_tb/*

add wave -position insertpoint  \
-divider " - GENERICS - " \
sim:/vga_colr_gen_tb/clk_period_g \
sim:/vga_colr_gen_tb/v_syn_period_g \
sim:/vga_colr_gen_tb/frame_rate_g \
sim:/vga_colr_gen_tb/depth_colr_g \
-divider " - CONSTANTS - " \
sim:/vga_colr_gen_tb/max_sim_time_c \
-divider " - TB SIGNALS - " \
sim:/vga_colr_gen_tb/clk \
sim:/vga_colr_gen_tb/rst_n \
sim:/vga_colr_gen_tb/v_sync_tb \
sim:/vga_colr_gen_tb/r_colr_out_tb \
sim:/vga_colr_gen_tb/g_colr_out_tb \
sim:/vga_colr_gen_tb/b_colr_out_tb

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run -all
wave zoom full
config wave -signalnamewidth 1