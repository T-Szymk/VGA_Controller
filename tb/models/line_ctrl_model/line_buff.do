add log -r sim:/top/*

add wave -group "TOP"  \
sim:/top/clk \
sim:/top/rstn \
-divider "counters" \
-unsigned \
sim:/top/disp_pxl_id_s \
sim:/top/pxl_cntr_s \
sim:/top/ln_cntr_s \
-hex \
sim:/top/disp_pxl_s \
-divider "frame buffer signals" \
sim:/top/fbuff_addr_s \
sim:/top/fbuff_en_s \
sim:/top/fbuff_data_in_s \
sim:/top/fbuff_wen_s \
sim:/top/fbuff_data_out_s \
-divider "debug_values" \
sim:/top/ref_pixel \
-unsigned \
sim:/top/ref_tile_val \
sim:/top/ref_line_val \
sim:/top/frame_counter \
-hex \
sim:/top/ref_fbuff_array

add wave -group "LINE BUFFER CONTROL" \
sim:/top/i_line_buff_ctrl/clk_i \
sim:/top/i_line_buff_ctrl/rstn_i \
sim:/top/i_line_buff_ctrl/buff_fill_done_i \
sim:/top/i_line_buff_ctrl/pxl_cntr_i \
sim:/top/i_line_buff_ctrl/ln_cntr_i \
sim:/top/i_line_buff_ctrl/buff_fill_req_o \
sim:/top/i_line_buff_ctrl/buff_sel_o \
sim:/top/i_line_buff_ctrl/disp_pxl_id_o \
sim:/top/i_line_buff_ctrl/last_disp_pixel_s \
sim:/top/i_line_buff_ctrl/counter_en_s \
sim:/top/i_line_buff_ctrl/buff_sel_s \
sim:/top/i_line_buff_ctrl/buff_fill_req_r \
sim:/top/i_line_buff_ctrl/buff_full_r \
sim:/top/i_line_buff_ctrl/disp_pxl_id_r \
-unsigned \
sim:/top/i_line_buff_ctrl/tile_pxl_cntr_r \
sim:/top/i_line_buff_ctrl/tile_lns_cntr_r \
-symbolic \
sim:/top/i_line_buff_ctrl/read_buff_state_r \
sim:/top/i_line_buff_ctrl/fill_buff_state_r

add wave -group "LINE BUFFERS"  \
sim:/top/i_line_buffers/clk_i \
sim:/top/i_line_buffers/rstn_i \
sim:/top/i_line_buffers/buff_fill_req_i \
sim:/top/i_line_buffers/buff_sel_i \
sim:/top/i_line_buffers/disp_pxl_id_i \
sim:/top/i_line_buffers/fbuff_data_i \
sim:/top/i_line_buffers/fbuff_rd_rsp_i \
sim:/top/i_line_buffers/buff_fill_done_o \
sim:/top/i_line_buffers/disp_pxl_o \
sim:/top/i_line_buffers/fbuff_rd_req_o \
sim:/top/i_line_buffers/fbuff_addra_o \
sim:/top/i_line_buffers/fill_lbuff_c_state_r \
sim:/top/i_line_buffers/fill_in_progress_r \
sim:/top/i_line_buffers/lbuff_fill_done_r \
sim:/top/i_line_buffers/fill_select_r \
sim:/top/i_line_buffers/lbuff_addra_s \
sim:/top/i_line_buffers/lbuff_wr_addra_r \
sim:/top/i_line_buffers/lbuff_rd_addra_s \
sim:/top/i_line_buffers/lbuff_dina_s \
sim:/top/i_line_buffers/lbuff_wea_r \
sim:/top/i_line_buffers/lbuff_ena_s \
sim:/top/i_line_buffers/lbuff_douta_s \
sim:/top/i_line_buffers/lbuff_cntr_en_r \
sim:/top/i_line_buffers/lbuff_tile_cntr_r \
sim:/top/i_line_buffers/fbuff_rd_req_r \
sim:/top/i_line_buffers/fbuff_pxl_s \
sim:/top/i_line_buffers/generate_frame_buffs[0]/i_line_buffer/BRAM \
sim:/top/i_line_buffers/generate_frame_buffs[1]/i_line_buffer/BRAM

add wave -group "FRAME BUFFER"  \
sim:/top/i_frame_buffer/clk_i \
sim:/top/i_frame_buffer/rstn_i \
sim:/top/i_frame_buffer/addra_i \
sim:/top/i_frame_buffer/dina_i \
sim:/top/i_frame_buffer/wea_i \
sim:/top/i_frame_buffer/ena_i \
sim:/top/i_frame_buffer/rd_req_i \
sim:/top/i_frame_buffer/rd_rsp_o \
sim:/top/i_frame_buffer/douta \
sim:/top/i_frame_buffer/mem_state_r \
sim:/top/i_frame_buffer/rd_rsp_r \
sim:/top/i_frame_buffer/douta_s

add wave -group "XILINX_SP_RAM"  \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/RAM_WIDTH \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/RAM_DEPTH \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/INIT_FILE \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/addra \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/dina \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/clka \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/wea \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/ena \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/douta \
sim:/top/i_frame_buffer/i_xilinx_sp_ram/BRAM

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 1445 us

wave zoom full
config wave -signalnamewidth 1
