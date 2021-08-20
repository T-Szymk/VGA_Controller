add log -r sim:/vga_controller_tb/*

add wave -position insertpoint  \
-divider " - GENERICS - " \
sim:/vga_controller_tb/width_g \
sim:/vga_controller_tb/height_g \
sim:/vga_controller_tb/h_sync_px_g \
sim:/vga_controller_tb/h_b_porch_px_g \
sim:/vga_controller_tb/h_f_porch_px_g \
sim:/vga_controller_tb/v_sync_lns_g \
sim:/vga_controller_tb/v_b_porch_lns_g \
sim:/vga_controller_tb/v_f_porch_lns_g \
sim:/vga_controller_tb/disp_freq_g \
sim:/vga_controller_tb/clk_period_g \
sim:/vga_controller_tb/v_sync_time_g \
sim:/vga_controller_tb/vb_porch_time_g \
-divider " - CONSTANTS - " \
sim:/vga_controller_tb/max_sim_time_c \
sim:/vga_controller_tb/frame_time_c \
-divider " - TB SIGNALS - " \
sim:/vga_controller_tb/rst_n \
sim:/vga_controller_tb/clk \
sim:/vga_controller_tb/curr_state \
sim:/vga_controller_tb/next_state \
sim:/vga_controller_tb/h_sync_out_dut_old \
sim:/vga_controller_tb/v_sync_out_dut_old \
sim:/vga_controller_tb/colr_en_out_dut_old \
sim:/vga_controller_tb/frame_tmr_start \
sim:/vga_controller_tb/v_sync_tmr_start \
sim:/vga_controller_tb/vb_porch_tmr_start \
-divider " - DUT SIGNALS - " \
sim:/vga_controller_tb/h_sync_out_dut \
sim:/vga_controller_tb/v_sync_out_dut \
sim:/vga_controller_tb/colr_en_out_dut

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 65 us
#run -all
wave zoom full
config wave -signalnamewidth 1
