.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := default

USE_MSIM = 1
#MSIM_CMD = ~/intelFPGA/20.1/modelsim_ase/bin
MSIM_CMD = /home/tom/questa2019/questasim/linux_x86_64
GHDL_CMD = ghdl
GHDL_OPT = --std=08 -fsynopsys -v

RTL = $(PWD)/../rtl
TB  = $(PWD)/../tb
MEM_DIR = $(PWD)/../supporting_apps/mem_file_gen
RTL_FILES_VHDL = $(RTL)/vga_pkg.vhd \
                 $(RTL)/input_dbounce.vhd \
                 $(RTL)/vga_clk_div.vhd \
                 $(RTL)/vga_controller.vhd \
                 $(RTL)/vga_colr_mux.vhd \
                 $(RTL)/xilinx_top_clk.vhd \
                 $(RTL)/vga_pxl_counter.vhd \
                 $(RTL)/vga_pattern_gen.vhd \
                 $(RTL)/vga_memory_intf.vhd \
						     $(RTL)/vga_frame_buffer.vhd \
                 $(RTL)/vga_line_buff_ctrl.vhd \
                 $(RTL)/vga_line_buffers.vhd \
                 $(RTL)/rst_sync.vhd \
                 $(RTL)/vga_top.vhd 
RTL_VILES_SV  =  $(RTL)/xilinx_sp_BRAM.sv
TB_FILES_VHDL =  $(TB)/vga_tb.vhd

PROJECT = vga_controller

# TOP LEVEL TESTING ############################################################

.PHONY: default
default: clean compile

.PHONY: clean
clean:
	rm -rf vga_top

.PHONY: lib
lib:
ifdef USE_MSIM
	mkdir vga_top && cd vga_top && \
	$(MSIM_CMD)/vlib vga_lib
	$(MSIM_CMD)/vmap work vga_lib
endif

.PHONY: compile
compile: clean lib
ifdef USE_MSIM
	cd vga_top && \
	$(MSIM_CMD)/vlog -sv -pedanticerrors $(RTL_VILES_SV) &&\
	$(MSIM_CMD)/vcom -pedanticerrors -check_synthesis -2008 $(RTL_FILES_VHDL) &&\
	$(MSIM_CMD)/vcom -pedanticerrors -check_synthesis -2008 $(TB_FILES_VHDL)
else
	@mkdir -p vga_top && cd vga_top && \
	$(GHDL_CMD) -a $(GHDL_OPT) $(RTL_FILES_VHDL) $(TB_FILES_VHDL)
endif

.PHONY: sim_vga_top
sim_vga_top: compile
	cd vga_top && \
	vsim -voptargs="+acc" \
	-Ginit_file_g="$(MEM_DIR)/pulla.mem" \
	-c -onfinish exit vga_tb -do "../do_vga_top.do"
	
.PHONY: sim_vga_top_gui
sim_vga_top_gui: compile
ifdef USE_MSIM
	cd vga_top && \
	vsim -voptargs="+acc" \
	-Ginit_file_g="$(MEM_DIR)/pulla.mem" \
	-onfinish stop vga_tb -do "../do_vga_top_gui.do"
else 
	cd vga_top && \
	$(GHDL_CMD) --elab-run $(GHDL_OPT) vga_tb --stop-time=50ms --wave=vga_tb.ghw && \
	gtkwave vga_tb.ghw -c 16
endif

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

# AXI MASTER TESTING ###########################################################

.PHONY: compile_axi_master
compile_axi_master:
	$(MSIM_CMD)/vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_pkg.vhd \
	                                                    $(RTL)/vga_axi_lite_master.vhd
	$(MSIM_CMD)/vlog -sv -pedanticerrors $(TB)/tb_vga_axi_lite_master.sv

.PHONY: sim_axi_master_gui
sim_axi_master_gui: compile_axi_master
	$(MSIM_CMD)/vsim -voptargs="+acc" -onfinish stop tb_vga_axi_lite_master -do "do_axi_master.do"

# AXI SLAVE TESTING #################################################

.PHONY: compile_axi_slave
compile_axi_slave:
	$(MSIM_CMD)/vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_pkg.vhd \
																											$(RTL)/vga_axi_lite_slave.vhd \
	                                                    $(RTL)/vga_axi_lite_master.vhd
	$(MSIM_CMD)/vlog -sv -pedanticerrors $(TB)/tb_vga_axi_lite_slave.sv

.PHONY: sim_axi_slave_gui
sim_axi_slave_gui: compile_axi_slave
	$(MSIM_CMD)/vsim -voptargs="+acc" -onfinish stop tb_vga_axi_lite_slave -do "do_axi_slave.do"

# MEM INTF MODEL TESTING #################################################
.PHONY: clean_mem_intf_model
clean_mem_intf_model:
	rm -rf mem_intf_model

.PHONY: compile_mem_intf_model
compile_mem_intf_model: clean_mem_intf_model
	mkdir mem_intf_model && cd mem_intf_model && \
	$(MSIM_CMD)/vlib vga_lib && \
	$(MSIM_CMD)/vmap work vga_lib && \
	$(MSIM_CMD)/vcom -pedanticerrors -check_synthesis -2008 \
	                                      $(RTL)/vga_pkg.vhd \
                                        $(RTL)/vga_clk_div.vhd \
                                        $(RTL)/vga_controller.vhd \
                                        $(RTL)/vga_colr_mux.vhd \
                                        $(RTL)/xilinx_top_clk.vhd \
                                        $(RTL)/vga_pxl_counter.vhd \
                                        $(RTL)/vga_pattern_gen.vhd \
						                            $(RTL)/rst_sync.vhd \
																				$(RTL)/vga_frame_buffer.vhd \
                                        $(RTL)/vga_line_buff_ctrl.vhd \
                                        $(RTL)/vga_line_buffers.vhd && \
	$(MSIM_CMD)/vlog -dpiheader $(TB)/models/dpi/includes/dpiheader.h \
	                 -sv -pedanticerrors $(RTL)/xilinx_sp_BRAM.sv \
									                     $(TB)/models/line_ctrl_model/frame_buffer.sv \
																			 $(TB)/models/line_ctrl_model/line_buff_ctrl.sv \
																			 $(TB)/models/line_ctrl_model/line_buffers.sv \
									                     $(TB)/models/vga_mem_intf_model.sv && \
	$(MSIM_CMD)/vlog $(TB)/models/dpi/src/vga_dpi.c

.PHONY: sim_mem_intf_model
sim_mem_intf_model: compile_mem_intf_model
	cd mem_intf_model && \
	$(MSIM_CMD)/vsim -voptargs="+acc" -c -onfinish stop vga_model -do "run 16 ms"

.PHONY: sim_mem_intf_model_gui
sim_mem_intf_model_gui: compile_mem_intf_model
	python3 ../supporting_apps/vga_sim/vga_sim_server.py &
	cd mem_intf_model && \
	$(MSIM_CMD)/vsim -voptargs="+acc" -onfinish stop vga_model -do ../../build/mem_intf_model.do

# MEM INTF TESTING #################################################
.PHONY: clean_mem_intf
clean_mem_intf:
	rm -rf mem_intf

.PHONY: compile_mem_intf
compile_mem_intf: clean_mem_intf
	mkdir mem_intf && cd mem_intf && \
	$(MSIM_CMD)/vlib mem_intf && \
	$(MSIM_CMD)/vmap work mem_intf && \
	$(MSIM_CMD)/vcom -pedanticerrors -check_synthesis -2008 \
	                           $(RTL)/vga_pkg.vhd \
	                           $(RTL)/vga_line_buff_ctrl.vhd \
														 $(RTL)/xilinx_sp_BRAM.vhd \
														 $(RTL)/vga_frame_buffer.vhd \
														 $(RTL)/vga_line_buffers.vhd \
														 $(RTL)/vga_memory_intf.vhd && \
	$(MSIM_CMD)/vlog -sv -pedanticerrors \
	                           $(TB)/tb_vga_memory_intf.sv

.PHONY: sim_mem_intf
sim_mem_intf: compile_mem_intf
	cd mem_intf && \
	$(MSIM_CMD)/vsim -voptargs="+acc" -c tb_vga_memory_intf -do "run -all"

.PHONY: sim_mem_intf_gui
sim_mem_intf_gui: compile_mem_intf
	cd mem_intf && \
	$(MSIM_CMD)/vsim -voptargs="+acc" -do ../do_vga_mem_intf.do -onfinish stop tb_vga_memory_intf

# MEM ADDR TESTING #################################################
.PHONY: clean_mem_addr_control
clean_mem_addr_control:
	rm -rf ./mem_addr_control

.PHONY: check_mem_addr_control
check_mem_addr_control:
	$(GHDL_CMD) -s $(GHDL_OPT) $(RTL)/vga_pkg.vhd \
	                       $(RTL)/vga_mem_addr_ctrl.vhd \
												 $(TB)/tb_vga_mem_addr_ctrl.vhd

.PHONY: compile_mem_addr_control
compile_mem_addr_control: clean_mem_addr_control
	@mkdir -p mem_addr_control && cd mem_addr_control && \
	$(GHDL_CMD) -a $(GHDL_OPT) ../$(RTL)/vga_pkg.vhd \
	                       ../$(RTL)/vga_mem_addr_ctrl.vhd

.PHONY: sim_mem_addr_control
sim_mem_addr_control: clean_mem_addr_control compile_mem_addr_control
	cd mem_addr_control && \
	$(GHDL_CMD) -a $(GHDL_OPT) ../$(TB)/tb_vga_mem_addr_ctrl.vhd && \
	$(GHDL_CMD) --elab-run $(GHDL_OPT) tb_vga_mem_addr_ctrl --stop-time=200ms --wave=tb_vga_mem_addr_ctrl.ghw && \
	gtkwave tb_vga_mem_addr_ctrl.ghw -c 16

# FPGA BUILD ###################################################################

.PHONY: fpga
fpga: clean_fpga
	mkdir -p fpga_build
	cd fpga_build && \
	vivado -mode batch -notrace -source ../fpga_build.tcl

.PHONY: clean_fpga
clean_fpga:
	rm -rf fpga_build
