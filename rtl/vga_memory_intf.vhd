-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_memory_intf.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-04-26
-- Design     : vga_memory_intf
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to contain logic related to reading image data from BRAM
--              and returning it for use by the VGA controller
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-03-25  1.0      TZS     Created
--------------------------------------------------------------------------------
-- DELETE BELOW
library IEEE;
use IEEE.std_logic_1164.ALL;
USE IEEE.MATH_REAL.ALL;

PACKAGE vga_pkg IS

  -- clk frequencies
  CONSTANT ref_clk_freq_c  : INTEGER := 100_000_000; -- input osc. on arty-a7
  CONSTANT px_clk_freq_c   : INTEGER := 25_000_000; -- 40ns period
  -- screen dimensions
  CONSTANT height_px_c     : INTEGER := 480;
  CONSTANT width_px_c      : INTEGER := 640;
  -- depth of each colour
  CONSTANT depth_colr_c    : INTEGER := 4;
  -- number of pixels in each v_sync period
  CONSTANT h_sync_px_c     : INTEGER := 96;
  -- number of pixels in each horiz. back porch period
  CONSTANT h_b_porch_px_c  : INTEGER := 48;
   -- number of pixels in each horiz. front porch period
  CONSTANT h_f_porch_px_c  : INTEGER := 16;
  -- number of lines in each v_sync period
  CONSTANT v_sync_lns_c    : INTEGER := 2;
  -- number of lines in each vert. back porch period
  CONSTANT v_b_porch_lns_c : INTEGER := 33;
  -- number of lines in each vert. front porch period
  CONSTANT v_f_porch_lns_c : INTEGER := 10;
  -- counter max and associated valueswidths
  CONSTANT pxl_ctr_max_c   : INTEGER := h_f_porch_px_c + width_px_c + 
                                       h_b_porch_px_c + h_sync_px_c;
  CONSTANT line_ctr_max_c  : INTEGER := v_f_porch_lns_c + height_px_c + 
                                       v_b_porch_lns_c + v_sync_lns_c;
  -- use max value to calculate bit width of counter
  CONSTANT pxl_ctr_width_c  : INTEGER := INTEGER(CEIL(
                                         LOG2(REAL(pxl_ctr_max_c - 1))));
  CONSTANT line_ctr_width_c : INTEGER := INTEGER(CEIL(
                                         LOG2(REAL(line_ctr_max_c - 1))));
  -- cumulative counter values used to determine line/pxl counter at each state
  -- within the vga controller
  CONSTANT v_sync_max_lns_c    : INTEGER := v_sync_lns_c;
  CONSTANT v_b_porch_max_lns_c : INTEGER := v_sync_max_lns_c + v_b_porch_lns_c;
  CONSTANT v_disp_max_lns_c    : INTEGER := v_b_porch_max_lns_c + height_px_c;
  CONSTANT v_f_porch_max_lns_c : INTEGER := v_disp_max_lns_c + v_f_porch_lns_c;
  CONSTANT h_sync_max_px_c     : INTEGER := h_sync_px_c;
  CONSTANT h_b_porch_max_px_c  : INTEGER := h_sync_max_px_c + h_b_porch_px_c;
  CONSTANT h_disp_max_px_c     : INTEGER := h_b_porch_max_px_c + width_px_c;
  CONSTANT h_f_porch_max_px_c  : INTEGER := h_disp_max_px_c + h_f_porch_px_c;
  
    -- using subtypes so attributes can be utilised
  SUBTYPE pxl_ctr_t  IS INTEGER RANGE (pxl_ctr_max_c - 1) DOWNTO 0;
  SUBTYPE line_ctr_t IS INTEGER RANGE (line_ctr_max_c - 1) DOWNTO 0;
  
  -- array to contain colours(RGB) in integer format
  TYPE colr_arr_t IS ARRAY (2 DOWNTO 0) OF INTEGER RANGE ((2**depth_colr_c) - 1)
                                                         DOWNTO 0;

END PACKAGE vga_pkg;
-- DELETE ABOVE
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use work.vga_pkg.all;


ENTITY vga_memory_intf IS 
  PORT (
    clk_i : in std_logic;
    rst_n : in std_logic
  );
END ENTITY vga_memory_intf;

--------------------------------------------------------------------------------
ARCHITECTURE rtl OF vga_memory_intf IS 
BEGIN

  process (clk_i, rst_n) is 
  begin 
  end process;

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------