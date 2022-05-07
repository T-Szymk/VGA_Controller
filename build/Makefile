.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := default

MSIM = ~/intelFPGA/20.1/modelsim_ase/bin
#MSIM = /home/tom/questa2019/questasim/linux_x86_64

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

.PHONY: lib
lib:
	vlib vga_lib
	vmap work vga_lib

.PHONY: compile
compile: lib
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
	vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_pkg.vhd \
	                                            $(RTL)/vga_controller.vhd \
	                                            $(TB)/vga_controller_tb.vhd

.PHONY: sim_vga_controller
sim_vga_controller: compile_vga_controller
	vsim -voptargs="+acc" -c -onfinish exit vga_controller_tb -do \
	"do_vga_controller.do"
	
.PHONY: sim_vga_controller_gui
sim_vga_controller_gui: compile_vga_controller
	vsim -voptargs="+acc" -onfinish stop vga_controller_tb -do \
	"do_vga_controller_gui.do"


# FIFO TESTING #################################################################

.PHONY: compile_fifo
compile_fifo:
	vcom -pedanticerrors -check_synthesis -2008 $(RTL)/sync_fifo.vhd
	vlog -sv -pedanticerrors $(TB)/sync_fifo_tb.sv

.PHONY: sim_fifo
sim_fifo: compile_fifo
	vsim -voptargs="+acc" -c -onfinish exit sync_fifo_tb -do "run -all;quit"

.PHONY: sim_fifo_gui
sim_fifo_gui: compile_fifo
	vsim -voptargs="+acc" -onfinish stop sync_fifo_tb -do "fifo.do"

# AXI MASTER TESTING ###########################################################

.PHONY: compile_axi_master
compile_axi_master:
	$(MSIM)/vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_pkg.vhd \
	                                                    $(RTL)/vga_axi_lite_master.vhd
	$(MSIM)/vlog -sv -pedanticerrors $(TB)/tb_vga_axi_lite_master.sv

.PHONY: sim_axi_master_gui
sim_axi_master_gui: compile_axi_master
	$(MSIM)/vsim -voptargs="+acc" -onfinish stop tb_vga_axi_lite_master -do "do_axi_master.do"

# AXI SLAVE TESTING #################################################

.PHONY: compile_axi_slave
compile_axi_slave:
	$(MSIM)/vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_pkg.vhd \
																											$(RTL)/vga_axi_lite_slave.vhd \
	                                                    $(RTL)/vga_axi_lite_master.vhd
	$(MSIM)/vlog -sv -pedanticerrors $(TB)/tb_vga_axi_lite_slave.sv

.PHONY: sim_axi_slave_gui
sim_axi_slave_gui: compile_axi_slave
	$(MSIM)/vsim -voptargs="+acc" -onfinish stop tb_vga_axi_lite_slave -do "do_axi_slave.do"

# MEM INTF TESTING #################################################
.PHONY: compile_mem_intf_model
compile_mem_intf_model:
	$(MSIM)/vlog -sv -pedanticerrors $(TB)/vga_mem_intf_model.sv

.PHONY: sim_mem_intf_model
sim_mem_intf_model: compile_mem_intf_model
	$(MSIM)/vsim -voptargs="+acc" -c -onfinish stop vga_mem_intf_model -do "run -all"

.PHONY: sim_mem_intf_model_gui
sim_mem_intf_model_gui: compile_mem_intf_model
	$(MSIM)/vsim -voptargs="+acc" -onfinish stop vga_mem_intf_model -do "add log -r /*; run 100ms"

# FPGA BUILD ###################################################################

.PHONY: fpga
fpga:
	vivado -mode batch -source ./fpga_build.tcl

.PHONY: clean_fpga
clean_fpga:
	rm -rf $(PROJECT)
