.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := default

#MSIM_CMD = ~/intelFPGA/20.1/modelsim_ase/bin
MSIM_CMD = /home/tom/questa2019/questasim/linux_x86_64
GHDL_CMD = ghdl
GHDL_OPT = --std=08 -fsynopsys -v

#MODELSIM ?=

RTL = ../../rtl
TB  = ../../tb
RTL_FILES = $(RTL)/vga_pkg.vhd \
            $(RTL)/ram_pkg.vhd \
            $(RTL)/vga_clk_div.vhd \
            $(RTL)/vga_controller.vhd \
            $(RTL)/vga_colr_mux.vhd \
            $(RTL)/xilinx_top_clk.vhd \
            $(RTL)/vga_pxl_counter.vhd \
            $(RTL)/vga_pattern_gen.vhd \
						$(RTL)/vga_memory_intf.vhd \
						$(RTL)/vga_mem_addr_ctrl.vhd \
						$(RTL)/vga_mem_buff.vhd \
						$(RTL)/xilinx_dp_BRAM.vhd \
						$(RTL)/rst_sync.vhd \
            $(RTL)/vga_top.vhd 
TB_FILES =  $(TB)/vga_tb.vhd \
            $(TB)/vga_colr_mux_tb.vhd \
            $(TB)/vga_controller_tb.vhd

PROJECT = vga_controller

# TOP LEVEL TESTING ############################################################

.PHONY: default
default: clean compile

.PHONY: clean
clean:
	rm -rf vga_lib
	rm -rf vga_top

.PHONY: lib
lib:
ifdef MODELSIM
	vlib vga_lib
	vmap work vga_lib
endif

.PHONY: compile
compile: clean lib
ifdef MODELSIM
	vcom -pedanticerrors -check_synthesis -2008 $(RTL_FILES)
	vcom -pedanticerrors -check_synthesis -2008 $(TB_FILES)
else
	@mkdir -p vga_top && cd vga_top && \
	$(GHDL_CMD) -a $(GHDL_OPT) $(RTL_FILES) $(TB_FILES)
endif

.PHONY: sim_vga_top
sim_vga_top: compile
	vsim -voptargs="+acc" -c -onfinish exit vga_tb -do "do_vga_top.do"
	
.PHONY: sim_vga_top_gui
sim_vga_top_gui: compile
ifdef MODELSIM
	vsim -voptargs="+acc" -onfinish stop vga_tb -do "do_vga_top_gui.do"
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
	vlib vga_lib && vmap work vga_lib && \
	$(MSIM_CMD)/vcom -pedanticerrors -check_synthesis -2008 $(RTL)/vga_pkg.vhd \
                                                          $(RTL)/ram_pkg.vhd \
                                                          $(RTL)/vga_clk_div.vhd \
                                                          $(RTL)/vga_controller.vhd \
                                                          $(RTL)/vga_colr_mux.vhd \
                                                          $(RTL)/xilinx_top_clk.vhd \
                                                          $(RTL)/vga_pxl_counter.vhd \
                                                          $(RTL)/vga_pattern_gen.vhd \
						                                              $(RTL)/vga_memory_intf.vhd \
						                                              $(RTL)/vga_mem_addr_ctrl.vhd \
						                                              $(RTL)/vga_mem_buff.vhd \
						                                              $(RTL)/xilinx_dp_BRAM.vhd \
						                                              $(RTL)/rst_sync.vhd && \
	$(MSIM_CMD)/vlog -dpiheader ../../tb/models/dpi/includes/dpiheader.h -sv -pedanticerrors $(TB)/models/vga_mem_intf_model.sv && \
	$(MSIM_CMD)/vlog ../../tb/models/dpi/src/vga_dpi.c

.PHONY: sim_mem_intf_model
sim_mem_intf_model: compile_mem_intf_model
	cd mem_intf_model && \
	vsim -voptargs="+acc" -c -onfinish stop vga_model

.PHONY: sim_mem_intf_model_gui
sim_mem_intf_model_gui: compile_mem_intf_model
	cd mem_intf_model && \
	vsim -voptargs="+acc" -onfinish stop vga_model -do ../../build/mem_intf_model.do

# MEM INTF TESTING #################################################
.PHONY: clean_mem_intf
clean_mem_intf:
	rm -rf mem_intf

.PHONY: compile_mem_intf
compile_mem_intf: clean_mem_intf
	mkdir mem_intf && cd mem_intf && \
	$(GHDL_CMD) -a $(GHDL_OPT) $(RTL)/vga_pkg.vhd \
	                           $(RTL)/vga_mem_addr_ctrl.vhd \
														 $(RTL)/vga_mem_buff.vhd \
														 $(RTL)/xilinx_dp_BRAM.vhd \
														 $(RTL)/vga_memory_intf.vhd \
												     $(TB)/tb_vga_memory_intf.vhd

.PHONY: sim_mem_intf
sim_mem_intf: compile_mem_intf
	cd mem_intf && \
	$(GHDL_CMD) --elab-run $(GHDL_OPT) tb_vga_memory_intf --stop-time=20ms --wave=tb_vga_memory_intf.ghw && \
	gtkwave tb_vga_memory_intf.ghw -c 16


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

# MEM BUFF TESTING #################################################
.PHONY: sim_mem_buff
sim_mem_buff: clean_mem_buff compile_mem_buff
	cd mem_buff && \
	$(GHDL_CMD) -a $(GHDL_OPT) ../$(TB)/tb_vga_mem_buff.vhd && \
	$(GHDL_CMD) --elab-run $(GHDL_OPT) tb_vga_mem_buff --stop-time=50ms --wave=tb_vga_mem_buff.ghw && \
	gtkwave tb_vga_mem_buff.ghw -c 16

.PHONY: compile_mem_buff
compile_mem_buff: clean_mem_buff
	@mkdir -p mem_buff && cd mem_buff && \
	$(GHDL_CMD) -a $(GHDL_OPT) ../$(RTL)/vga_pkg.vhd \
	                           ../$(RTL)/vga_mem_buff.vhd

.PHONY: clean_mem_buff
clean_mem_buff:
	rm -rf ./mem_addr_control

.PHONY: check_mem_buff
check_mem_buff:
	$(GHDL_CMD) -s $(GHDL_OPT) $(RTL)/vga_pkg.vhd \
	                       $(RTL)/vga_mem_buff.vhd \
												 $(TB)/tb_vga_mem_buff.vhd

# FPGA BUILD ###################################################################

.PHONY: fpga
fpga:
	vivado -mode batch -source ./fpga_build.tcl

.PHONY: clean_fpga
clean_fpga:
	rm -rf $(PROJECT)
