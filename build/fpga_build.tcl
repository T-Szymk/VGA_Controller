# Script to build VGA_controller project on FPGA
# Target platform: Digilent Arty A7-100

set ARTY_PART xc7a100tcsg324-1

set PROJECT $::env(PROJECT)
set TOP_DIR "[pwd]/../.."

set RTL_DIR    ${TOP_DIR}/rtl
set TB_DIR     ${TOP_DIR}/tb
set BUILD_DIR  ${TOP_DIR}/build
set CONSTR_DIR ${TOP_DIR}/constraints
set PROJECT_DIR ${BUILD_DIR}/fpga_build/${PROJECT}
                               
set BRAM_INIT_FILE "lake.mem"
set CONSTR_FILE "${CONSTR_DIR}/Arty-A7-100-Master.xdc"

set SRC_FILES " \
  ${TOP_DIR}/supporting_apps/mem_file_gen/${BRAM_INIT_FILE} \
	${RTL_DIR}/vga_pkg.vhd \
  ${RTL_DIR}/xilinx_top_clk.vhd \
  ${RTL_DIR}/xilinx_sp_BRAM.sv \
  ${RTL_DIR}/rst_sync.vhd \
  ${RTL_DIR}/input_dbounce.vhd \
  ${RTL_DIR}/vga_controller.vhd \
  ${RTL_DIR}/vga_colr_mux.vhd \
  ${RTL_DIR}/vga_pxl_counter.vhd \
  ${RTL_DIR}/vga_pattern_gen.vhd \
  ${RTL_DIR}/vga_frame_buffer.vhd \
  ${RTL_DIR}/vga_line_buff_ctrl.vhd \
  ${RTL_DIR}/vga_line_buffers.vhd \
  ${RTL_DIR}/vga_memory_intf.vhd \
  ${RTL_DIR}/vga_top.vhd \
"

set SIM_FILES "\
  ${RTL_DIR}/vga_clk_div.vhd \
  ${TB_DIR}/vga_tb.vhd \
"

set SYNTH_GENERICS "
  conf_sim_g=0 \
  init_file_g=${BRAM_INIT_FILE} \
"

create_project ${PROJECT} ./${PROJECT} -part ${ARTY_PART} -force

add_files -norecurse ${SRC_FILES}
add_files -norecurse -fileset sim_1 ${SIM_FILES} ${SRC_FILES}
add_files -fileset constrs_1 ${CONSTR_FILE}

set_property top vga_top [current_fileset]
set_property top vga_tb [current_fileset -simset]

set_property file_type {VHDL 2008} [get_files "*.vhd"]

# configure defualt properties for
set_property -name {xsim.simulate.runtime} -value {0ns} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# generate clock wizard 
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} \
                         CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.000} \
                         CONFIG.USE_LOCKED {true} \
                         CONFIG.RESET_TYPE {ACTIVE_LOW} \
                         CONFIG.CLKIN1_JITTER_PS {80.0} \
                         CONFIG.MMCM_CLKOUT0_DIVIDE_F {36.500} \
                         CONFIG.RESET_PORT {resetn} \
                         CONFIG.CLKOUT1_JITTER {312.659} \
                         CONFIG.CLKOUT1_PHASE_ERROR {245.713}] \
                         [get_ips clk_wiz_0]

generate_target all [get_ips clk_wiz_0]

# set synthesis generics
set_property generic ${SYNTH_GENERICS} [current_fileset]
set_property generic ${SYNTH_GENERICS} [get_filesets sim_1]

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
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true              [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name timing_1
report_power -name {power_1}