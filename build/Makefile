
RTL_FILES = ./rtl/vga_clk_div.vhd \
            ./rtl/vga_controller.vhd \
            ./rtl/vga_sw_sync.vhd \
            ./rtl/vga_colr_mux.vhd \
            ./rtl/vga_rst_sync.vhd \
            ./rtl/vga_colr_gen.vhd \
	          ./rtl/vga_colr_en.vhd \
            ./rtl/vga_top_arty-a7.vhd
TB_FILES =  ./tb/vga_tb.vhd \
            ./tb/vga_colr_mux_tb.vhd

# TOP LEVEL TESTING#############################################################

.PHONY: all
all: compile run

.PHONY: compile
compile: 
	vcom -pedanticerrors -check_synthesis -2008 $(RTL_FILES) &&\
	vcom -pedanticerrors -check_synthesis -2008 $(TB_FILES)

.PHONY: sim_vga_top
sim_vga_top:
	vsim -voptargs="+acc" -onfinish stop vga_tb -do "do_vga.do"

# COLR_MUX TESTING #############################################################

.PHONY: compile_vga_colr_mux
compile_vga_colr_mux:
	vcom -pedanticerrors -check_synthesis -2008 ./rtl/vga_colr_mux.vhd  ./tb/vga_colr_mux_tb.vhd

.PHONY: sim_vga_colr_mux
sim_vga_colr_mux: compile_vga_colr_mux
	vsim -voptargs="+acc" -c -onfinish exit vga_colr_mux_tb -do "do_vga_colr_mux.do"
	
.PHONY: sim_vga_colr_mux_gui
sim_vga_colr_mux_gui: compile_vga_colr_mux
	vsim -voptargs="+acc" -onfinish stop vga_colr_mux_tb -do "do_vga_colr_mux.do"
