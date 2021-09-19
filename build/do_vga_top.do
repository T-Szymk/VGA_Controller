add log -r sim:/vga_tb/*

set StdArithNoWarnings 1 
run 0 ns 
set StdArithNoWarnings 0

run -all
