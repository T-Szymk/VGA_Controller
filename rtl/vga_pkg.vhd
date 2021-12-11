-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Package
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_pkg.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-12-11
-- Design     : vga_pkg
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Package to contain definitions used for VGA
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-12-11  1.1      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.MATH_REAL.ALL;

PACKAGE vga_pkg IS

  -- clk frequencies
  CONSTANT ref_clk_freq_c  : INTEGER := 100_000_000; -- input osc. on arty-a7
  CONSTANT px_clk_freq_c   : INTEGER := 25_000_000;
  -- screen dimensions
  CONSTANT height_px_c     : INTEGER := 480;
  CONSTANT width_px_c      : INTEGER := 680;
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
  CONSTANT pxl_ctr_max_c  : INTEGER := h_f_porch_px_c + width_px_c + 
                                       h_b_porch_px_c + h_sync_px_c;
  CONSTANT line_ctr_max_c : INTEGER := v_f_porch_lns_c + height_px_c + 
                                       v_b_porch_lns_c + v_sync_lns_c;
  -- use max value to calculate bit width of counter
  CONSTANT pxl_ctr_width_c : INTEGER :=  INTEGER(CEIL(
                                         LOG2(REAL(pxl_ctr_max_c - 1))));
  CONSTANT line_ctr_width_c : INTEGER := INTEGER(CEIL(
                                         LOG2(REAL(line_ctr_max_c - 1))));

    -- using subtypes so attributes can be utilised
  SUBTYPE pxl_ctr_t  IS INTEGER RANGE (pxl_ctr_max_c - 1) DOWNTO 0;
  SUBTYPE line_ctr_t IS INTEGER RANGE (line_ctr_max_c - 1) DOWNTO 0;

END PACKAGE vga_pkg;