
-------------------------------------------------------------------------------
-- Title      : VGA Controller Top
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_top.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-07-04
-- Design     : vga_top
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Top level design for vga controller to be used with the 
--              Xilinx Arty-A7 development board
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-07-04  1.0      TZS     Created
-- 2021-09-01  1.1      TZS     Updated top level as component ports were moded
-- 2021-09-06  1.2      TZS     Added Xilinx MMCM component
-- 2021-09-19  1.3      TZS     Reintroduced updated colr_gen block
-- 2021-11-01  1.4      TZS     Renamed to vga_top.vhd
--                              Removed unused reset block
-- 2021-12-11  1.5      TZS     Removed colour generation and switch sync blocks
--                              Added VGA timing generics/constants to top level
-- 2021-12-12  1.6      TZS     Added test pattern generator                                
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE WORK.VGA_PKG.ALL;

ENTITY vga_top IS
  GENERIC (
    -- 1 for simulation, 0 for synthesis
    CONF_SIM : INTEGER := 1;
    CONF_TEST_PATT : INTEGER := 1
  );
  PORT (
    -- clock and asynch reset
    clk    : IN STD_LOGIC;
    rst_n  : IN STD_LOGIC;
    -- VGA signals
    v_sync_out  : OUT STD_LOGIC;
    h_sync_out  : OUT STD_LOGIC;
    r_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_c - 1 DOWNTO 0);
    g_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_c - 1 DOWNTO 0);
    b_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_c - 1 DOWNTO 0)
  );
END ENTITY vga_top;

--------------------------------------------------------------------------------

ARCHITECTURE structural of vga_top IS 

-- COMPONENT DECLARATIONS ------------------------------------------------------

  -- clock divider components to generate the pixel clock
  -- if simulating, use vga_clk_div, for synthesis use clk_gen
  
  COMPONENT vga_clk_div -- FOR SIM ****
    GENERIC (
      ref_clk_freq_g : INTEGER;
      px_clk_freq_g  : INTEGER
    );
    PORT ( 
      clk        : IN STD_LOGIC;
      rst_n      : IN STD_LOGIC;
  
      clk_px_out : OUT STD_LOGIC
    );
  END COMPONENT; -- FOR SIM ****
  
  COMPONENT clk_gen -- FOR FPGA ****
    PORT (
      clk        : IN  STD_LOGIC;
      rst_n      : IN  STD_LOGIC;
    
      clk_px_out : OUT STD_LOGIC
    );
  END COMPONENT; -- FOR FPGA ****

  -- counter to generate pixel and line counter values

  COMPONENT vga_pxl_counter
    PORT (
      clk        : IN STD_LOGIC;
      rst_n      : IN STD_LOGIC;
      
      pxl_ctr_o  : OUT STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
      line_ctr_o : OUT STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0)
    );
  END COMPONENT;  

  -- controller to generate VGA sigals

  COMPONENT vga_controller IS
    PORT(
      clk         : IN STD_LOGIC;
      rst_n       : IN STD_LOGIC;
      pxl_ctr_i   : IN STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
      line_ctr_i  : IN STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0);

      colr_en_out : OUT STD_LOGIC;
      v_sync_out  : OUT STD_LOGIC;
      h_sync_out  : OUT STD_LOGIC
    );
  END COMPONENT vga_controller;

  -- colour mux use to blank colour signals

  COMPONENT vga_colr_mux IS 
    GENERIC (
      depth_colr_g : INTEGER
    );
    PORT (
      colr_in  : IN STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0);
      en_in    : IN STD_LOGIC;
    
      colr_out : OUT STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0)
    );
  END COMPONENT;
  
  -- Component to generate the test pattern if required

  COMPONENT vga_pattern_gen IS
    PORT (
      pxl_ctr_i  : IN STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
      line_ctr_i : IN STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0);
      
      colr_out   : OUT STD_LOGIC_VECTOR(((3*depth_colr_c) - 1) DOWNTO 0)
    ); 
  END COMPONENT;

-- VARIABLES / CONSTANTS / TYPES -----------------------------------------------

  -- intermediate signals between components
  SIGNAL pxl_clk_s      : STD_LOGIC;
  SIGNAL v_sync_s       : STD_LOGIC;
  SIGNAL h_sync_s       : STD_LOGIC;
  SIGNAL colr_en_s      : STD_LOGIC;
  SIGNAL pxl_ctr_s      : STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
  SIGNAL line_ctr_s     : STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0);
  SIGNAL colr_arr_s     : STD_LOGIC_VECTOR((3*depth_colr_c)-1 DOWNTO 0);
  SIGNAL colr_mux_arr_s : STD_LOGIC_VECTOR((3*depth_colr_c)-1 DOWNTO 0);

BEGIN --------------------------------------------------------------------------

  gen_clk_src: IF CONF_SIM = 1 GENERATE -- Used in simulation ****************

    i_vga_clk_div : vga_clk_div 
      GENERIC MAP (
                    ref_clk_freq_g => ref_clk_freq_c, 
                    px_clk_freq_g  => px_clk_freq_c
      )
      PORT MAP    (
                    clk        => clk,
                    rst_n      => rst_n,
                    clk_px_out => pxl_clk_s
      ); 
  ELSE GENERATE --************************************************************** 
      i_clk_gen : clk_gen 
      	PORT MAP (
      	    	     clk        => clk,
      	    	     rst_n      => rst_n,
      	    	     clk_px_out	=> pxl_clk_s
      	); 
  END GENERATE gen_clk_src; -- Used in synthesis *******************************

  i_vga_pxl_counter : vga_pxl_counter
    PORT MAP (
      clk        => pxl_clk_s,
      rst_n      => rst_n,
      pxl_ctr_o  => pxl_ctr_s,
      line_ctr_o => line_ctr_s
    );

  i_vga_controller : vga_controller
    PORT MAP (
      clk         => pxl_clk_s,
      rst_n       => rst_n,
      pxl_ctr_i   => pxl_ctr_s,
      line_ctr_i  => line_ctr_s,
      colr_en_out => colr_en_s,
      v_sync_out  => v_sync_s,
      h_sync_out  => h_sync_s
    );

  i_vga_colr_mux : vga_colr_mux
    GENERIC MAP (
      depth_colr_g => depth_colr_c)
    PORT MAP (
      colr_in  => colr_arr_s,
      en_in    => colr_en_s,
      colr_out => colr_mux_arr_s
    );
  
  gen_test_patt : IF CONF_TEST_PATT = 1 GENERATE -- pattern gen required *****
  
    i_vga_pattern_gen : vga_pattern_gen
      PORT MAP (
        pxl_ctr_i  => pxl_ctr_s,   
        line_ctr_i => line_ctr_s,    
        colr_out   => colr_arr_s  
      );

  END GENERATE gen_test_patt; --************************************************

   -- output assignments
  v_sync_out <= v_sync_s;
  h_sync_out <= h_sync_s;

  r_colr_out <= colr_mux_arr_s(((3*depth_colr_c) - 1) DOWNTO (2*depth_colr_c));
  g_colr_out <= colr_mux_arr_s(((2*depth_colr_c) - 1) DOWNTO depth_colr_c);
  b_colr_out <= colr_mux_arr_s((depth_colr_c - 1)  DOWNTO 0);

END ARCHITECTURE structural;

--------------------------------------------------------------------------------
