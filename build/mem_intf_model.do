add log -r /*

add wave -position insertpoint  \
-divider " - top - " \
sim:/vga_model/clk_s \
sim:/vga_model/clk_px_s \
sim:/vga_model/rstn_s \
sim:/vga_model/rst_sync_s \
sim:/vga_model/pxl_ctr_s \
sim:/vga_model/line_ctr_s \
sim:/vga_model/colr_en_s \
sim:/vga_model/v_sync_s \
sim:/vga_model/h_sync_s \
sim:/vga_model/test_switch_s \
sim:/vga_model/blank_s \
sim:/vga_model/test_pxl_s \
sim:/vga_model/mem_pxl_s \
sim:/vga_model/disp_pxl_s \
sim:/vga_model/mem_addr_ctr_s \
sim:/vga_model/mem_pxl_ctr_s \
-divider " - golden ref signals - " \
sim:/vga_model/blank_golden_s \
sim:/vga_model/mem_pxl_golden_s \
sim:/vga_model/mem_addr_ctr_golden_s \
sim:/vga_model/mem_pxl_ctr_golden_s \
-divider " - mem_buff - " \
sim:/vga_model/run_mem_buff_model/rstn_i \
sim:/vga_model/run_mem_buff_model/mem_addr_ctr_i \
sim:/vga_model/run_mem_buff_model/mem_pxl_ctr_i \
sim:/vga_model/run_mem_buff_model/disp_blank_o \
sim:/vga_model/run_mem_buff_model/disp_pxl_o \
sim:/vga_model/run_mem_buff_model/init \
sim:/vga_model/run_mem_buff_model/buff_sel \
sim:/vga_model/run_mem_buff_model/buff_A_data \
sim:/vga_model/run_mem_buff_model/buff_B_data \
sim:/vga_model/run_mem_buff_model/buff_A_addr \
sim:/vga_model/run_mem_buff_model/buff_B_addr \
sim:/vga_model/run_mem_buff_model/internal_mem_ctr \
-divider " - kill simulation - " \
sim:/vga_model/kill_simulation_s

#-divider " - mem_ctrl - " \
#sim:/vga_model/run_mem_addr_ctrl_model/rstn_i \
#sim:/vga_model/run_mem_addr_ctrl_model/pxl_ctr_i \
#sim:/vga_model/run_mem_addr_ctrl_model/line_ctr_i \
#sim:/vga_model/run_mem_addr_ctrl_model/mem_addr_ctr_o \
#sim:/vga_model/run_mem_addr_ctrl_model/mem_pxl_ctr_o \

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 20ms

wave zoom full
config wave -signalnamewidth 1