# Script to build VGA_controller project on FPGA
# Target platform: Digilent Arty A7-100

set PROJECT $::env(PROJECT)
set PROJECT_DIR [pwd]/${PROJECT}

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
  CONF_SIM=0 \
  CONF_TEST_PATT=1
"

create_project ${PROJECT} ./${PROJECT} -part xc7a100tcsg324-1 -force

add_files -norecurse ${SRC_FILES}
add_files -norecurse -fileset sim_1 ${SIM_FILES}
add_files -fileset constrs_1 "../constraints/Arty-A7-100-Master.xdc"

set_property top vga_top [current_fileset]
set_property top vga_tb [current_fileset -simset]

set_property file_type {VHDL 2008} [get_files "*.vhd"]

# generate clock wizard 
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} \
                         CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.000} \
                         CONFIG.USE_LOCKED {false} \
                         CONFIG.RESET_TYPE {ACTIVE_LOW} \
                         CONFIG.CLKIN1_JITTER_PS {80.0} \
                         CONFIG.MMCM_DIVCLK_DIVIDE {5} \
                         CONFIG.MMCM_CLKFBOUT_MULT_F {36.500} \
                         CONFIG.MMCM_CLKIN1_PERIOD {8.000} \
                         CONFIG.MMCM_CLKOUT0_DIVIDE_F {36.500} \
                         CONFIG.RESET_PORT {resetn} \
                         CONFIG.CLKOUT1_JITTER {312.659} \
                         CONFIG.CLKOUT1_PHASE_ERROR {245.713}] \
                         [get_ips clk_wiz_0]

generate_target {instantiation_template} [get_files ${PROJECT_DIR}/${PROJECT}.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
update_compile_order -fileset sources_1
set_property generate_synth_checkpoint false [get_files ${PROJECT_DIR}/${PROJECT}.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]

# set synthesis generics
set_property generic ${SYNTH_GENERICS} [current_fileset]

# elaborate 
synth_design -rtl -name rtl_1

# synthesis settings
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE RuntimeOptimized [get_runs synth_1]
launch_runs synth_1
wait_on_run synth_1

# implementation settings
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE RuntimeOptimized      [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE RuntimeOptimized    [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE RuntimeOptimized [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE RuntimeOptimized    [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true      [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name timing_1
report_power -name {power_1}