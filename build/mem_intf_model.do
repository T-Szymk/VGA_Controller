add log -r /*

add wave -position insertpoint  \
sim:/vga_mem_intf_model/CLK_PERIOD_NS \
sim:/vga_mem_intf_model/SIMULATION_RUNTIME \
sim:/vga_mem_intf_model/DEPTH_COLR \
sim:/vga_mem_intf_model/MEM_WIDTH \
sim:/vga_mem_intf_model/MEM_DEPTH \
sim:/vga_mem_intf_model/PXL_PER_ROW \
sim:/vga_mem_intf_model/HEIGHT_PX \
sim:/vga_mem_intf_model/WIDTH_PX \
sim:/vga_mem_intf_model/H_SYNC_PX \
sim:/vga_mem_intf_model/H_B_PORCH_PX \
sim:/vga_mem_intf_model/H_F_PORCH_PX \
sim:/vga_mem_intf_model/V_SYNC_LNS \
sim:/vga_mem_intf_model/V_B_PORCH_LNS \
sim:/vga_mem_intf_model/V_F_PORCH_LNS \
sim:/vga_mem_intf_model/PXL_CTR_MAX \
sim:/vga_mem_intf_model/LINE_CTR_MAX \
sim:/vga_mem_intf_model/V_SYNC_MAX_LNS \
sim:/vga_mem_intf_model/V_B_PORCH_MAX_LNS \
sim:/vga_mem_intf_model/V_DISP_MAX_LNS \
sim:/vga_mem_intf_model/V_F_PORCH_MAX_LNS \
sim:/vga_mem_intf_model/H_SYNC_MAX_PX \
sim:/vga_mem_intf_model/H_B_PORCH_MAX_PX \
sim:/vga_mem_intf_model/H_DISP_MAX_PX \
sim:/vga_mem_intf_model/H_F_PORCH_MAX_PX \
sim:/vga_mem_intf_model/DISP_PXL_MAX \
sim:/vga_mem_intf_model/PXL_CTR_WIDTH \
sim:/vga_mem_intf_model/LN_CTR_WIDTH \
sim:/vga_mem_intf_model/DISP_PXL_WIDTH \
sim:/vga_mem_intf_model/MEM_DATA_CTR_WIDTH \
sim:/vga_mem_intf_model/MEM_ADDR_WIDTH \
sim:/vga_mem_intf_model/ADDR_FIFO_WIDTH \
sim:/vga_mem_intf_model/DATA_FIFO_WIDTH \
sim:/vga_mem_intf_model/ADDR_FIFO_DEPTH \
sim:/vga_mem_intf_model/DATA_FIFO_DEPTH \
sim:/vga_mem_intf_model/pxl_ctr \
sim:/vga_mem_intf_model/ln_ctr \
sim:/vga_mem_intf_model/disp_ctr \
sim:/vga_mem_intf_model/colr \
sim:/vga_mem_intf_model/clk \
sim:/vga_mem_intf_model/mem_data_ctr \
sim:/vga_mem_intf_model/mem_addr_ctr \
sim:/vga_mem_intf_model/fifo_mem_addr_ctr \
sim:/vga_mem_intf_model/addr_buff_0 \
sim:/vga_mem_intf_model/addr_buff_1 \
sim:/vga_mem_intf_model/display_buff_0 \
sim:/vga_mem_intf_model/display_buff_1 \
sim:/vga_mem_intf_model/intf_model \
sim:/vga_mem_intf_model/intf_model.fifo_data_model.width \
sim:/vga_mem_intf_model/intf_model.fifo_data_model.depth \
sim:/vga_mem_intf_model/intf_model.fifo_data_model.full \
sim:/vga_mem_intf_model/intf_model.fifo_data_model.al_full \
sim:/vga_mem_intf_model/intf_model.fifo_data_model.empty \
sim:/vga_mem_intf_model/intf_model.fifo_data_model.al_empty \
sim:/vga_mem_intf_model/intf_model.fifo_addr_model.width \
sim:/vga_mem_intf_model/intf_model.fifo_addr_model.depth \
sim:/vga_mem_intf_model/intf_model.fifo_addr_model.full \
sim:/vga_mem_intf_model/intf_model.fifo_addr_model.al_full \
sim:/vga_mem_intf_model/intf_model.fifo_addr_model.empty \
sim:/vga_mem_intf_model/intf_model.fifo_addr_model.al_empty

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 100 ms

wave zoom full
config wave -signalnamewidth 1