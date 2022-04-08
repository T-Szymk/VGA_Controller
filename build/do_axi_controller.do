add log -r sim:/tb_vga_axi_mem_ctrl/*

add wave -position insertpoint  \
sim:/tb_vga_axi_mem_ctrl/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_mem_ctrl/AXI_DATA_WITH \
sim:/tb_vga_axi_mem_ctrl/PXL_CTR_WIDTH \
sim:/tb_vga_axi_mem_ctrl/LINE_CTR_WIDTH \
sim:/tb_vga_axi_mem_ctrl/CLOCK_PERIOD_NS \
sim:/tb_vga_axi_mem_ctrl/clk \
sim:/tb_vga_axi_mem_ctrl/rst_n \
sim:/tb_vga_axi_mem_ctrl/pxl_ctr \
sim:/tb_vga_axi_mem_ctrl/line_ctr \
sim:/tb_vga_axi_mem_ctrl/ar_rdy \
sim:/tb_vga_axi_mem_ctrl/ar_rdy_r \
sim:/tb_vga_axi_mem_ctrl/ar_valid \
sim:/tb_vga_axi_mem_ctrl/ar_addr \
sim:/tb_vga_axi_mem_ctrl/ar_prot \
sim:/tb_vga_axi_mem_ctrl/r_rdy \
sim:/tb_vga_axi_mem_ctrl/r_valid \
sim:/tb_vga_axi_mem_ctrl/r_valid_r \
sim:/tb_vga_axi_mem_ctrl/r_data \
sim:/tb_vga_axi_mem_ctrl/r_resp \
sim:/tb_vga_axi_mem_ctrl/c_state \
sim:/tb_vga_axi_mem_ctrl/n_state \
-divider "dut" \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/AXI_DATA_WIDTH \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/clk \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/rst_n \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/pxl_ctr_i \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/line_ctr_i \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_araddr_o \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_arprot_o \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_arrdy_i \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_arvalid_o \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_arvalid_r \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_rdata_i \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_rrdy_o \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_rresp_i \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/c_state \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/n_state \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_rrdy_r \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_rvalid_i \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/req_data_s \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_araddr_r_0 \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_araddr_r \
sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/m_rdata_r

force -freeze sim:/tb_vga_axi_mem_ctrl/i_vga_axi_mem_ctrl/req_data_s 1 0

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 10 us

wave zoom full
config wave -signalnamewidth 1
