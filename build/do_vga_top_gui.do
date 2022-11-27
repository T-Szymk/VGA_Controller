add log -r sim:/vga_tb/*

onerror {resume}
set DefaultRadix HEXADECIMAL

add wave -expand -group vga_tb sim:/vga_tb/i_dut/*
add wave -group mem_intf sim:/vga_tb/i_dut/i_vga_memory_intf/*
add wave -group mem_intf -group line_buff_ctrl sim:/vga_tb/i_dut/i_vga_memory_intf/i_line_buff_ctrl/*
add wave -group mem_intf -group line_buffs sim:/vga_tb/i_dut/i_vga_memory_intf/i_line_buffs/*
add wave -group mem_intf -group line_buffs -group line_buff0_BRAM sim:/vga_tb/i_dut/i_vga_memory_intf/i_line_buffs/generate_lbuffs(0)/i_line_buff0/*
add wave -group mem_intf -group line_buffs -group line_buff1_BRAM sim:/vga_tb/i_dut/i_vga_memory_intf/i_line_buffs/generate_lbuffs(1)/i_line_buff0/*
add wave -group mem_intf -group frame_buff sim:/vga_tb/i_dut/i_vga_memory_intf/i_frame_buff/*
add wave -group mem_intf -group frame_buff -group frame_buff_BRAM sim:/vga_tb/i_dut/i_vga_memory_intf/i_frame_buff/i_sp_ram/*
add wave -group mem_intf -group frame_buff -group frame_buff_BRAM sim:/vga_tb/i_dut/i_vga_memory_intf/i_frame_buff/i_sp_ram/BRAM
add wave -group vga_controller sim:/vga_tb/i_dut/i_vga_controller/*
add wave -group vga_colr_mux sim:/vga_tb/i_dut/i_vga_colr_mux/*

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run 10ms

wave zoom full

configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1
configure wave -timelineunits us

set RunLength 1us