add wave -position insertpoint  \
sim:/vga_axi_mem_ctrl/AXI_ADDR_WIDTH \
sim:/vga_axi_mem_ctrl/AXI_DATA_WIDTH \
sim:/vga_axi_mem_ctrl/clk \
sim:/vga_axi_mem_ctrl/rst_n \
sim:/vga_axi_mem_ctrl/m_aclk_o \
-divider "ADDRESS READ SIGNALS" \
sim:/vga_axi_mem_ctrl/m_arstn_o \
sim:/vga_axi_mem_ctrl/m_araddr_o \
sim:/vga_axi_mem_ctrl/m_arprot_o \
sim:/vga_axi_mem_ctrl/m_arvalid_o \
sim:/vga_axi_mem_ctrl/m_arrdy_i \
-divider "READ SIGNALS" \
sim:/vga_axi_mem_ctrl/m_rdata_i \
sim:/vga_axi_mem_ctrl/m_rvalid_i \
sim:/vga_axi_mem_ctrl/m_rrdy_o \
sim:/vga_axi_mem_ctrl/m_rresp_i \
-divider "OTHER SIGNALS" \
sim:/vga_axi_mem_ctrl/c_state \
sim:/vga_axi_mem_ctrl/n_state \
sim:/vga_axi_mem_ctrl/m_arvalid_r \
sim:/vga_axi_mem_ctrl/req_data_s \
sim:/vga_axi_mem_ctrl/addr_r0 \
sim:/vga_axi_mem_ctrl/addr_r \
sim:/vga_axi_mem_ctrl/data_r

force -freeze sim:/vga_axi_mem_ctrl/m_rdata_i 64'hAAAAAAAAAAAAAAAA 0
force -freeze sim:/vga_axi_mem_ctrl/m_arrdy_i 0 0
force -freeze sim:/vga_axi_mem_ctrl/m_rvalid_i 0 0
force -freeze sim:/vga_axi_mem_ctrl/m_rresp_i 2'h00 0

force -freeze sim:/vga_axi_mem_ctrl/clk 1 0, 0 {5 ns} -r {10 ns}
force -freeze sim:/vga_axi_mem_ctrl/rst_n 0 0

run 100 ns

force -freeze sim:/vga_axi_mem_ctrl/rst_n 1 0

run 100 ns

force -freeze sim:/vga_axi_mem_ctrl/req_data_s 1 0
force -freeze sim:/vga_axi_mem_ctrl/m_arrdy_i 1 0
run 20 ns
force -freeze sim:/vga_axi_mem_ctrl/m_rvalid_i 1 0
run 10 ns
force -freeze sim:/vga_axi_mem_ctrl/m_rvalid_i 0 0
run 20 ns
force -freeze sim:/vga_axi_mem_ctrl/m_rvalid_i 1 0
run 10 ns
force -freeze sim:/vga_axi_mem_ctrl/m_rvalid_i 0 0
run 20 ns

wave zoom full
config wave -signalnamewidth 1