# Script to build VGA_controller project on FPGA
# Target platform: Digilent Arty A7-100

set PROJECT $::env(PROJECT)

set SRC_FILES "\
	../rtl/vga_pkg.vhd \
	../rtl/vga_colr_mux.vhd \
	../rtl/xilinx_top_clk.vhd \
	../rtl/vga_pxl_counter.vhd \
	../rtl/vga_pattern_gen.vhd \
	../rtl/vga_controller.vhd \
	../rtl/vga_top.vhd \
"

set SIM_FILES "\
  ../rtl/vga_clk_div.vhd \
  ../tb/vga_tb.vhd \
"

set SYNTH_GENERICS "
  CONF_SIM='0' \
  CONF_TEST_PATT='1'
"

create_project ${PROJECT} ./${PROJECT} -part xc7a100tcsg324-1 -force

add_files -norecurse ${SRC_FILES}
add_files -norecurse -fileset sim_1 ${SIM_FILES}
add_files -fileset constrs_1 "../constraints/Arty-A7-100-Master.xdc"

set_property top vga_top [current_fileset]
set_property top vga_tb [current_fileset -simset]

set_property file_type {VHDL 2008} [get_files "*.vhd"]

set_property generic ${SYNTH_GENERICS} [current_fileset]

# elaborate 
# synth_design -rtl -name rtl_1

# synthesis settings
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE RuntimeOptimized [get_runs synth_1]