add log -r sim:/vga_tb/*

add wave -position insertpoint  \
-divider " - CONSTANTS - " \
sim:/vga_tb/ref_clk_freq_g \
sim:/vga_tb/ref_clk_period_g \
sim:/vga_tb/max_sim_time_g \
-divider " - DUT_SIGNALS - " \
sim:/vga_tb/clk \
sim:/vga_tb/rst_n \
sim:/vga_tb/dut_sw_in \
sim:/vga_tb/dut_v_sync_out \
sim:/vga_tb/dut_h_sync_out \
sim:/vga_tb/dut_clk_px_out \
sim:/vga_tb/dut_r_colr_out \
sim:/vga_tb/dut_g_colr_out \
sim:/vga_tb/dut_b_colr_out \
-divider " - TB_SIGNALS - " \
-unsigned sim:/vga_tb/test_cntr \
sim:/vga_tb/test_pxl_cntr \
sim:/vga_tb/test_ln_cntr \
sim:/vga_tb/test_fr_cntr

run -all
wave zoom full
