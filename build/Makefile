.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := default

RTL = ../rtl
TB  = ../tb
RTL_FILES = $(RTL)/vga_pkg.vhd \
            $(RTL)/vga_clk_div.vhd \
            $(RTL)/vga_controller.vhd \
            $(RTL)/vga_colr_mux.vhd \
            $(RTL)/xilinx_top_clk.vhd \
            $(RTL)/vga_pxl_counter.vhd \
            $(RTL)/vga_pattern_gen.vhd \
            $(RTL)/vga_top.vhd
TB_FILES =  $(TB)/vga_tb.vhd \
            $(TB)/vga_colr_mux_tb.vhd \
            $(TB)/vga_controller_tb.vhd

PROJECT = vga_controller

# TOP LEVEL TESTING ############################################################

.PHONY: default
default: compile

.PHONY: compile
compile: 
	vlib vga_lib
	vmap work vga_lib
	vcom -pedanticerrors -check_synthesis -2008 $(RTL_FILES) &&\
	vcom -pedanticerrors -check_synthesis -2008 $(TB_FILES)

.PHONY: compile_vga_top
compile_vga_top:
	vcom -pedanticerrors -check_synthesis -2008 $(RTL_FILES) $(TB)/vga_tb.vhd

.PHONY: sim_vga_top
sim_vga_top: compile_vga_top
	vsim -voptargs="+acc" -c -onfinish exit vga_tb -do "do_vga_top.do"
	
.PHONY: sim_vga_top_gui
sim_vga_top_gui: compile_vga_top
	vsim -voptargs="+acc" -onfinish stop vga_tb -do "do_vga_top_gui.do"

# COLR_MUX TESTING #############################################################

.PHONY: compile_vga_colr_mux
compile_vga_colr_mux:
	vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_colr_mux.vhd \
	$(TB)/vga_colr_mux_tb.vhd

.PHONY: sim_vga_colr_mux
sim_vga_colr_mux: compile_vga_colr_mux
	vsim -voptargs="+acc" -c -onfinish exit vga_colr_mux_tb -do \
	"do_vga_colr_mux.do"
	
.PHONY: sim_vga_colr_mux_gui
sim_vga_colr_mux_gui: compile_vga_colr_mux
	vsim -voptargs="+acc" -onfinish stop vga_colr_mux_tb -do \
	"do_vga_colr_mux.do"

# CONTROLLER TESTING ###########################################################

.PHONY: compile_vga_controller
compile_vga_controller:
	vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_controller.vhd \
	$(TB)/vga_controller_tb.vhd

.PHONY: sim_vga_controller
sim_vga_controller: compile_vga_controller
	vsim -voptargs="+acc" -c -onfinish exit vga_controller_tb -do \
	"do_vga_controller.do"
	
.PHONY: sim_vga_controller_gui
sim_vga_controller_gui: compile_vga_controller
	vsim -voptargs="+acc" -onfinish stop vga_controller_tb -do \
	"do_vga_controller_gui.do"

# FPGA BUILD ###################################################################

.PHONY: fpga
fpga:
	vivado -mode batch -source ./fpga_build.tcl

.PHONY: clean_fpga
clean_fpga:
	rm -rf $(PROJECT)