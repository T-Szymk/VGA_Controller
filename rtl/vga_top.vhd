
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
--              ToDo:
--                   1. synchronise IO
--                   2. create module to convert between hardware colour width 
--                      and variable depth_colr_c
--                   3. Tidy up consistent use of pixel_t instead of vectors                 
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
-- 2022-06-26  1.7      TZS     Tidied up formatting in module.
--                              Added reset synchroniser
--                              Added switch for test pattern                          
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.vga_pkg.all;

entity vga_top is
  generic (
    -- 1 for simulation, 0 for synthesis
    CONF_SIM       : integer := 1;
    CONF_TEST_PATT : integer := 1
  );
  port (
    -- clock and asynch reset
    clk_i : in std_logic;
    rst_n : in std_logic;
    -- io
    sw_0_i : in std_logic;
    -- VGA signals
    v_sync_out  : out std_logic;
    h_sync_out  : out std_logic;
    r_colr_out  : out std_logic_vector(depth_colr_c - 1 downto 0);
    g_colr_out  : out std_logic_vector(depth_colr_c - 1 downto 0);
    b_colr_out  : out std_logic_vector(depth_colr_c - 1 downto 0)
  );
end entity vga_top;

--------------------------------------------------------------------------------

ARCHITECTURE structural of vga_top IS 

-- COMPONENT DECLARATIONS ------------------------------------------------------

  -- clock divider components to generate the pixel clock
  -- if simulating, use vga_clk_div, for synthesis use clk_gen
  
  component vga_clk_div is -- FOR SIM ****
    generic (
      ref_clk_freq_g : integer;
      px_clk_freq_g  : integer
    );
    port ( 
      clk_i        : in std_logic;
      rst_n      : in std_logic;
      clk_px_out : out std_logic
    );
  end component; -- FOR SIM ****
  
  component clk_gen -- for fpga ****
    port (
      clk_i      : in  std_logic;
      rst_n      : in  std_logic;
      clk_px_out : out std_logic
    );
  end component; -- for fpga ****

  component rst_sync is
    generic (
      SYNC_STAGES : integer := 3
    );
    port (
      clk_i       : in  std_logic;
      rstn_i      : in  std_logic;
      sync_rstn_o : out std_logic
    );
    end component;

  -- counter to generate pixel and line counter values

  component vga_pxl_counter
    port (
      clk_i        : in std_logic;
      rst_n      : in std_logic;
      pxl_ctr_o  : out std_logic_vector((pxl_ctr_width_c - 1) downto 0);
      line_ctr_o : out std_logic_vector((line_ctr_width_c - 1) downto 0)
    );
  end component;  

  -- controller to generate VGA sigals

  component vga_controller is
    port (
      clk_i       : in  std_logic;
      rst_n       : in  std_logic;
      pxl_ctr_i   : in  std_logic_vector((pxl_ctr_width_c - 1) downto 0);
      line_ctr_i  : in  std_logic_vector((line_ctr_width_c - 1) downto 0);
      colr_en_out : out std_logic;
      v_sync_out  : out std_logic;
      h_sync_out  : out std_logic
    );
  end component vga_controller;

  -- colour mux use to blank colour signals

  component vga_colr_mux is 
    port (
      test_colr_i : in  pixel_t;
      mem_colr_i  : in  pixel_t;
      en_i        : in  std_logic;
      blank_i     : in  std_logic;
      colr_out    : out pixel_t
    );
  end component;
  
  -- Component to generate the test pattern if required

  component vga_pattern_gen is
    port (
      pxl_ctr_i  : in std_logic_vector((pxl_ctr_width_c - 1) downto 0);
      line_ctr_i : in std_logic_vector((line_ctr_width_c - 1) downto 0);
      colr_out   : out std_logic_vector(((3*depth_colr_c) - 1) downto 0)
    ); 
  end component;

-- VARIABLES / CONSTANTS / TYPES -----------------------------------------------

  -- intermediate signals between components
  signal rst_sync_s     : std_logic;
  signal pxl_clk_s      : std_logic;
  signal v_sync_s       : std_logic;
  signal h_sync_s       : std_logic;
  signal colr_en_s      : std_logic;
  signal blank_s        : std_logic;
  signal pxl_ctr_s      : std_logic_vector((pxl_ctr_width_c - 1) downto 0);
  signal line_ctr_s     : std_logic_vector((line_ctr_width_c - 1) downto 0);
  signal test_pxl_s     : pixel_t;
  signal mem_pxl_s      : pixel_t;
  signal colr_mux_arr_s : std_logic_vector((3*depth_colr_c)-1 downto 0);

BEGIN --------------------------------------------------------------------------

  gen_clk_src: IF CONF_SIM = 1 GENERATE -- Used in simulation ****************

    i_vga_clk_div : vga_clk_div 
      generic map (
        ref_clk_freq_g => ref_clk_freq_c, 
        px_clk_freq_g  => px_clk_freq_c
      )
      port map (
        clk        => clk_i,
        rst_n      => rst_n,
        clk_px_out => pxl_clk_s
      ); 

  else generate --************************************************************** 
      
    i_clk_gen : clk_gen 
      port map (
      	clk        => clk_i,
      	rst_n      => rst_n,
      	clk_px_out	=> pxl_clk_s
      );

  end generate gen_clk_src; -- Used in synthesis *******************************

  i_rst_sync : rst_sync
    generic map (
      SYNC_STAGES => 3
    )
    port map (
      clk_i       => pxl_clk_s,
      rstn_i      => rst_n,
      sync_rstn_o => rst_sync_s
    );

  i_vga_pxl_counter : vga_pxl_counter
    port map (
      clk        => pxl_clk_s,
      rst_n      => rst_sync_s,
      pxl_ctr_o  => pxl_ctr_s,
      line_ctr_o => line_ctr_s
    );

  i_vga_controller : vga_controller
    port map (
      clk         => pxl_clk_s,
      rst_n       => rst_sync_s,
      pxl_ctr_i   => pxl_ctr_s,
      line_ctr_i  => line_ctr_s,
      colr_en_out => colr_en_s,
      v_sync_out  => v_sync_s,
      h_sync_out  => h_sync_s
    );

  i_vga_colr_mux : vga_colr_mux
    port map (
      test_colr_i => test_pxl_s,
      mem_colr_i  => mem_pxl_s,
      en_i        => sw_0_i,
      blank_i     => blank_s,
      colr_out    => colr_mux_arr_s
    );
  
  i_vga_pattern_gen : vga_pattern_gen
    port map (
      pxl_ctr_i  => pxl_ctr_s,   
      line_ctr_i => line_ctr_s,    
      colr_out   => test_pxl_s  
    );

  blank_s <= NOT colr_en_s;

   -- output assignments
  v_sync_out <= v_sync_s;
  h_sync_out <= h_sync_s;

  r_colr_out <= colr_mux_arr_s(((3*depth_colr_c) - 1) downto (2*depth_colr_c));
  g_colr_out <= colr_mux_arr_s(((2*depth_colr_c) - 1) downto depth_colr_c);
  b_colr_out <= colr_mux_arr_s((depth_colr_c - 1)  downto 0);

end architecture structural;

--------------------------------------------------------------------------------
