
RTL_FILES = ../rtl/vga_clk_div.vhd \
            ../rtl/vga_controller.vhd \
            ../rtl/vga_sw_sync.vhd \
            ../rtl/vga_colr_mux.vhd \
            ../rtl/vga_rst_sync.vhd \
            ../rtl/vga_colr_gen.vhd \
            ../rtl/vga_top.vhd
TB_FILES =  ../tb/vga_tb.vhd      

.PHONY: all
all: compile run

.PHONY: compile
compile: 
	vcom -pedanticerrors -check_synthesis -2008 $(RTL_FILES) $(TB_FILES)

.PHONY: sim
sim:
	vsim -voptargs="+acc" -onfinish stop vga_tb -do "do_vga.do"