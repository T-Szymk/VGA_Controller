add wave -position insertpoint  \
sim:/tb_vga_axi_lite_slave/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_lite_slave/AXI_DATA_WITH \
sim:/tb_vga_axi_lite_slave/CLOCK_PERIOD_NS \
sim:/tb_vga_axi_lite_slave/clk \
sim:/tb_vga_axi_lite_slave/rst_n \
sim:/tb_vga_axi_lite_slave/ar_rdy \
sim:/tb_vga_axi_lite_slave/ar_valid \
sim:/tb_vga_axi_lite_slave/addr_r \
sim:/tb_vga_axi_lite_slave/ar_addr \
sim:/tb_vga_axi_lite_slave/ar_prot \
sim:/tb_vga_axi_lite_slave/r_rdy \
sim:/tb_vga_axi_lite_slave/r_valid \
sim:/tb_vga_axi_lite_slave/r_data \
sim:/tb_vga_axi_lite_slave/r_resp \
-divider "master"  \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/AXI_DATA_WIDTH \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/req_data_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/addr_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_aclk_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_arstn_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_araddr_o \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_arprot_o \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_arrdy_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_arvalid_o \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_arvalid_r \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_rdata_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_rrdy_o \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_rresp_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/c_state \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/n_state \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_rrdy_r \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_rvalid_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/req_data_s \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_araddr_r \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_master/m_rdata_r \
-divider "slave" \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/AXI_DATA_WIDTH \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_aclk_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_arstn_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_araddr_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_arprot_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_arrdy_r \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_arrdy_o \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_arvalid_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_rdata_o \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_rrdy_i \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_rvalid_r \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_rvalid_o \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_rresp_o \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/c_state \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/n_state \
sim:/tb_vga_axi_lite_slave/i_vga_axi_lite_slave/s_rdata_r

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 10 us

wave zoom full
config wave -signalnamewidth 1