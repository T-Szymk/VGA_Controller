set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

add log -r /*

onerror {resume}

add wave -noupdate -expand -group top_level /vga_model/clk_s
add wave -noupdate -expand -group top_level /vga_model/clk_px_s
add wave -noupdate -expand -group top_level /vga_model/rstn_s
add wave -noupdate -expand -group top_level /vga_model/rst_sync_s
add wave -noupdate -expand -group counters /vga_model/pxl_ctr_s
add wave -noupdate -expand -group counters /vga_model/line_ctr_s
add wave -noupdate -expand -group vga_out /vga_model/v_sync_s
add wave -noupdate -expand -group vga_out /vga_model/h_sync_s
add wave -noupdate -expand -group vga_out /vga_model/disp_pxl_s
add wave -noupdate -group colr_mux /vga_model/i_vga_colr_mux/test_colr_i
add wave -noupdate -group colr_mux /vga_model/i_vga_colr_mux/mem_colr_i
add wave -noupdate -group colr_mux /vga_model/i_vga_colr_mux/en_i
add wave -noupdate -group colr_mux /vga_model/i_vga_colr_mux/blank_i
add wave -noupdate -group colr_mux /vga_model/i_vga_colr_mux/colr_out
add wave -noupdate -group colr_mux /vga_model/i_vga_colr_mux/pxl_s
add wave -noupdate -group colr_mux /vga_model/i_vga_colr_mux/int_pxl_s
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/clk_i
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/rstn_i
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/buff_fill_done_i
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/pxl_cntr_i
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/ln_cntr_i
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/buff_fill_req_o
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/buff_sel_o
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/disp_pxl_id_o
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/last_disp_pixel_s
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/counter_en_s
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/buff_sel_s
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/buff_fill_req_r
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/buff_full_r
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/disp_pxl_id_r
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/tile_pxl_cntr_r
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/tile_lns_cntr_r
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/read_buff_state_r
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/fill_buff_state_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/clk_i
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/rstn_i
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/buff_fill_req_i
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/buff_sel_i
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/disp_pxl_id_i
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fbuff_data_i
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fbuff_rd_rsp_i
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/buff_fill_done_o
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/disp_pxl_o
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fbuff_rd_req_o
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fbuff_addra_o
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fill_lbuff_c_state_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fill_in_progress_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_fill_done_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fill_select_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_addra_s
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_wr_addra_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_rd_addra_s
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_dina_s
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_wea_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_ena_s
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_douta_s
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_cntr_en_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/lbuff_tile_cntr_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fbuff_rd_req_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fbuff_pxl_s
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fbuff_addra_r
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/fbuff_data_r
add wave -noupdate -group line_buffers -label BRAM_A {/vga_model/i_line_buffers/generate_frame_buffs[1]/i_line_buffer/BRAM}
add wave -noupdate -group line_buffers -label BRAM_B {/vga_model/i_line_buffers/generate_frame_buffs[0]/i_line_buffer/BRAM}
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/clk_i
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/rstn_i
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/addra_i
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/dina_i
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/wea_i
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/ena_i
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/rd_req_i
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/rd_rsp_o
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/douta
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/mem_state_r
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/rd_rsp_r
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/douta_s
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/i_xilinx_sp_ram/BRAM
add wave -position insertpoint sim:/vga_model/kill_simulation_s

run 20ms

wave zoom full
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1
configure wave -timelineunits us
update