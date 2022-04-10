add wave -position insertpoint  \
sim:/tb_vga_axi_mem/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_mem/AXI_DATA_WITH \
sim:/tb_vga_axi_mem/PXL_CTR_WIDTH \
sim:/tb_vga_axi_mem/LINE_CTR_WIDTH \
sim:/tb_vga_axi_mem/CLOCK_PERIOD_NS \
sim:/tb_vga_axi_mem/clk \
sim:/tb_vga_axi_mem/rst_n \
sim:/tb_vga_axi_mem/pxl_ctr \
sim:/tb_vga_axi_mem/line_ctr \
sim:/tb_vga_axi_mem/ar_rdy \
sim:/tb_vga_axi_mem/ar_valid \
sim:/tb_vga_axi_mem/ar_addr \
sim:/tb_vga_axi_mem/ar_prot \
sim:/tb_vga_axi_mem/r_rdy \
sim:/tb_vga_axi_mem/r_valid \
sim:/tb_vga_axi_mem/r_data \
sim:/tb_vga_axi_mem/r_resp \
-divider "master"  \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/AXI_DATA_WIDTH \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_aclk_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_arstn_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/pxl_ctr_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/line_ctr_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_araddr_o \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_arprot_o \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_arvalid_r \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_arvalid_o \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_arrdy_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_araddr_r_0 \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_araddr_r \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_rdata_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_rresp_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_rrdy_r \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_rrdy_o \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_rvalid_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/m_rdata_r \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/c_state \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/n_state \
sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/req_data_s \
-divider "slave" \
sim:/tb_vga_axi_mem/i_vga_axi_mem/AXI_ADDR_WIDTH \
sim:/tb_vga_axi_mem/i_vga_axi_mem/AXI_DATA_WIDTH \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_aclk_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_arstn_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_araddr_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_arprot_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_arrdy_r \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_arrdy_o \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_arvalid_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_rdata_o \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_rrdy_i \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_rvalid_r \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_rvalid_o \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_rresp_o \
sim:/tb_vga_axi_mem/i_vga_axi_mem/c_state \
sim:/tb_vga_axi_mem/i_vga_axi_mem/n_state \
sim:/tb_vga_axi_mem/i_vga_axi_mem/s_rdata_r

force -freeze sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/req_data_s 0 0

run 100 ns

force -freeze sim:/tb_vga_axi_mem/i_vga_axi_mem_ctrl/req_data_s 1 0

run 1 us

wave zoom full
config wave -signalnamewidth 1