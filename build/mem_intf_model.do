set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

add log -r /*

onerror {resume}

add wave -noupdate -expand -group top_level /vga_model/*
add wave -noupdate -group colr_mux /vga_model/i_vga_colr_mux/*
add wave -noupdate -group line_buff_ctrl /vga_model/i_line_buff_ctrl/*
add wave -noupdate -group line_buffers /vga_model/i_line_buffers/*
add wave -noupdate -group line_buffers -label BRAM_A {/vga_model/i_line_buffers/generate_frame_buffs[0]/i_line_buffer/BRAM}
add wave -noupdate -group line_buffers -label BRAM_B {/vga_model/i_line_buffers/generate_frame_buffs[1]/i_line_buffer/BRAM}
add wave -noupdate -group frame_buff /vga_model/i_frame_buffer/*
add wave -position insertpoint sim:/vga_model/kill_simulation_s

run 40ms

set RunLength 10ms

wave zoom full
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1
configure wave -timelineunits us
update