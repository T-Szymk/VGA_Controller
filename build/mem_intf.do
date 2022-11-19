add log -r /*

onerror {resume}

transcript off

set DefaultRadix HEXADECIMAL

add wave -expand -group mem_intf_top   sim:/tb_vga_memory_intf/*
add wave -expand -group line_buff_ctrl sim:/tb_vga_memory_intf/i_line_buff_ctrl/*
add wave -expand -group line_buff_ctrl \
/tb_vga_memory_intf/i_line_buff_ctrl/comb_counter_en/pxl_cntr_v \
/tb_vga_memory_intf/i_line_buff_ctrl/comb_counter_en/ln_cntr_v 

add wave -expand -group line_buffers   sim:/tb_vga_memory_intf/i_line_buffers/*
add wave -expand -group frame_buffer   sim:/tb_vga_memory_intf/i_frame_buffer/*
add wave -group line_buffers -group line_buffer0 sim:/tb_vga_memory_intf/i_line_buffers/generate_lbuffs(0)/i_line_buff/*
add wave -group line_buffers -group line_buffer1 sim:/tb_vga_memory_intf/i_line_buffers/generate_lbuffs(1)/i_line_buff/*

radix signal sim:/tb_vga_memory_intf/pxl_cntr_s -unsigned;
radix signal sim:/tb_vga_memory_intf/ln_cntr_s  -unsigned;  

radix signal sim:/tb_vga_memory_intf/i_line_buff_ctrl/pxl_cntr_i -unsigned;  
radix signal sim:/tb_vga_memory_intf/i_line_buff_ctrl/ln_cntr_i  -unsigned; 

configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1
configure wave -timelineunits us

set RunLength 1us

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run -all

wave zoom full
update