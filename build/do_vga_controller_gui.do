add log -r sim:/vga_controller_tb/*

add wave -position insertpoint  \
-divider " - GENERICS - " \
sim:/vga_controller_tb/disp_freq_g \
sim:/vga_controller_tb/clk_period_g \
sim:/vga_controller_tb/frame_time_g \
sim:/vga_controller_tb/v_sync_time_g \
sim:/vga_controller_tb/h_sync_time_g \
sim:/vga_controller_tb/display_time_g \
sim:/vga_controller_tb/h_sync_int_time_g \
sim:/vga_controller_tb/display_time_g \
sim:/vga_controller_tb/h_fp_time_g \
sim:/vga_controller_tb/h_bp_time_g \
sim:/vga_controller_tb/v_fp_time_g \
sim:/vga_controller_tb/v_bp_time_g \
sim:/vga_controller_tb/disp_v_syn_time_g \
sim:/vga_controller_tb/v_syn_disp_time_g \
-divider " - CONSTANTS - " \
sim:/vga_controller_tb/max_sim_time_c \
sim:/vga_controller_tb/i_DUT/v_b_porch_max_lns_c \
sim:/vga_controller_tb/i_DUT/v_disp_max_lns_c \
sim:/vga_controller_tb/i_DUT/v_f_porch_max_lns_c \
sim:/vga_controller_tb/i_DUT/h_sync_max_px_c \
sim:/vga_controller_tb/i_DUT/h_b_porch_max_px_c \
sim:/vga_controller_tb/i_DUT/h_disp_max_px_c \
sim:/vga_controller_tb/i_DUT/h_f_porch_max_px_c \
-divider " - TB SIGNALS - " \
sim:/vga_controller_tb/rst_n \
sim:/vga_controller_tb/clk \
sim:/vga_controller_tb/h_sync_out_dut_old \
sim:/vga_controller_tb/v_sync_out_dut_old \
sim:/vga_controller_tb/colr_en_out_dut_old \
sim:/vga_controller_tb/pxl_ctr_s \
sim:/vga_controller_tb/line_ctr_s \
sim:/vga_controller_tb/frame_tmr_start \
sim:/vga_controller_tb/v_sync_tmr_start \
sim:/vga_controller_tb/h_sync_tmr_start \
sim:/vga_controller_tb/h_sync_tmr_int_start \
sim:/vga_controller_tb/display_tmr_start \
sim:/vga_controller_tb/display_tmr_int_start \
sim:/vga_controller_tb/v_syn_disp_tmr_start \
sim:/vga_controller_tb/v_syn_h_syn_tmr_start \
sim:/vga_controller_tb/v_sync_timer_en_s \
sim:/vga_controller_tb/h_sync_timer_en_s \
sim:/vga_controller_tb/display_timer_en_s \
sim:/vga_controller_tb/v_syn_disp_timer_en_s \
sim:/vga_controller_tb/v_syn_h_syn_timer_en_s \
-divider " - DUT SIGNALS - " \
sim:/vga_controller_tb/h_sync_out_dut \
sim:/vga_controller_tb/v_sync_out_dut \
sim:/vga_controller_tb/colr_en_out_dut \
sim:/vga_controller_tb/i_DUT/c_state \
sim:/vga_controller_tb/i_DUT/n_state

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

#run 32 ms
run -all
wave zoom full
config wave -signalnamewidth 1
