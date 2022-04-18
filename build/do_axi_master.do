add log -r sim:/tb_vga_axi_lite_master/*

add wave -position insertpoint  \
sim:/tb_vga_axi_lite_master/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_lite_master/AXI_DATA_WITH \
sim:/tb_vga_axi_lite_master/PXL_CTR_WIDTH \
sim:/tb_vga_axi_lite_master/LINE_CTR_WIDTH \
sim:/tb_vga_axi_lite_master/CLOCK_PERIOD_NS \
sim:/tb_vga_axi_lite_master/clk \
sim:/tb_vga_axi_lite_master/rst_n \
sim:/tb_vga_axi_lite_master/ar_rdy \
sim:/tb_vga_axi_lite_master/ar_rdy_r \
sim:/tb_vga_axi_lite_master/ar_valid \
sim:/tb_vga_axi_lite_master/ar_addr \
sim:/tb_vga_axi_lite_master/ar_prot \
sim:/tb_vga_axi_lite_master/r_rdy \
sim:/tb_vga_axi_lite_master/r_valid \
sim:/tb_vga_axi_lite_master/r_valid_r \
sim:/tb_vga_axi_lite_master/r_data \
sim:/tb_vga_axi_lite_master/r_resp \
sim:/tb_vga_axi_lite_master/c_state \
sim:/tb_vga_axi_lite_master/n_state \
-divider "dut" \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/AXI_DATA_WIDTH \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/req_data_i \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/addr_i \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_aclk_i \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_arstn_i \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_araddr_o \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_arprot_o \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_arrdy_i \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_arvalid_o \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_arvalid_r \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_rdata_i \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_rrdy_o \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_rresp_i \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/c_state \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/n_state \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_rrdy_r \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_rvalid_i \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/req_data_s \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_araddr_r \
sim:/tb_vga_axi_lite_master/i_vga_axi_lite_master/m_rdata_r

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 10 us

wave zoom full
config wave -signalnamewidth 1
