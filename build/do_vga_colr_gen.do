add log -r sim:/vga_colr_gen_tb/*

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

#run 32 ms
run -all
