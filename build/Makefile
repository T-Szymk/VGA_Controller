
RTL = ../rtl
TB  = ../tb
RTL_FILES = $(RTL)/vga_clk_div.vhd \
            $(RTL)/vga_controller.vhd \
            $(RTL)/vga_sw_sync.vhd \
            $(RTL)/vga_colr_mux.vhd \
            $(RTL)/vga_rst_sync.vhd \
            $(RTL)/vga_colr_gen.vhd \
            $(RTL)/vga_colr_en.vhd \
            $(RTL)/vga_colr_gen_cntr.vhd \
            $(RTL)/lfsr.vhd \
            $(RTL)/vga_colr_gen.vhd \
            $(RTL)/xilinx_top_clk.vhd \
            $(RTL)/vga_top_arty-a7.vhd 
TB_FILES =  $(TB)/vga_tb.vhd \
            $(TB)/vga_colr_mux_tb.vhd \
            $(TB)/vga_controller_tb.vhd \
            $(TB)/vga_colr_gen_tb.vhd

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
	vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_colr_mux.vhd $(TB)/vga_colr_mux_tb.vhd

.PHONY: sim_vga_colr_mux
sim_vga_colr_mux: compile_vga_colr_mux
	vsim -voptargs="+acc" -c -onfinish exit vga_colr_mux_tb -do "do_vga_colr_mux.do"
	
.PHONY: sim_vga_colr_mux_gui
sim_vga_colr_mux_gui: compile_vga_colr_mux
	vsim -voptargs="+acc" -onfinish stop vga_colr_mux_tb -do "do_vga_colr_mux.do"

# COLR_MUX TESTING #############################################################

.PHONY: compile_vga_controller
compile_vga_controller:
	vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_controller.vhd  $(TB)/vga_controller_tb.vhd

.PHONY: sim_vga_controller
sim_vga_controller: compile_vga_controller
	vsim -voptargs="+acc" -c -onfinish exit vga_controller_tb -do "do_vga_controller.do"
	
.PHONY: sim_vga_controller_gui
sim_vga_controller_gui: compile_vga_controller
	vsim -voptargs="+acc" -onfinish stop vga_controller_tb -do "do_vga_controller_gui.do"

# COLR_GEN TESTING #############################################################

.PHONY: compile_vga_colr_gen
compile_vga_colr_gen:
	vcom -pedanticerrors -check_synthesis -2008 $(RTL)/lfsr.vhd $(RTL)/vga_colr_gen_cntr.vhd $(RTL)/vga_colr_gen.vhd  $(TB)/vga_colr_gen_tb.vhd

.PHONY: sim_vga_colr_gen
sim_vga_colr_gen: compile_vga_colr_gen
	vsim -voptargs="+acc" -c -onfinish exit vga_colr_gen_tb -do "do_vga_colr_gen.do"
	
.PHONY: compile_vga_colr_gen
sim_vga_colr_gen_gui: compile_vga_colr_gen
	vsim -voptargs="+acc" -onfinish stop vga_colr_gen_tb -do "do_vga_colr_gen_gui.do"