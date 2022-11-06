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
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;

PACKAGE vga_pkg IS    

  -- VGA COUNTER CONSTANTS/TYPES ###############################################

  -- clk frequencies
  CONSTANT ref_clk_freq_c  : INTEGER := 100_000_000; -- input osc. on arty-a7
  CONSTANT px_clk_freq_c   : INTEGER := 25_000_000; -- 40ns period
  -- screen dimensions
  CONSTANT height_px_c     : INTEGER := 480;
  CONSTANT width_px_c      : INTEGER := 640;
  -- number of pixels in each h_sync period
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
  --  number of pixels for display (not counting sync and porch pixels) 
  CONSTANT disp_pxl_max_c  : INTEGER := height_px_c * width_px_c;

  -- use max value to calculate bit width of counter
  CONSTANT pxl_ctr_width_c  : INTEGER := INTEGER(CEIL(LOG2(REAL(pxl_ctr_max_c - 1))));
  CONSTANT line_ctr_width_c : INTEGER := INTEGER(CEIL(LOG2(REAL(line_ctr_max_c - 1))));
  CONSTANT disp_pxl_depth_c : INTEGER := INTEGER(CEIL(LOG2(REAL(disp_pxl_max_c - 1))));                                        
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
  
  -- VIDEO MEMORY CONSTANTS/TYPES ##############################################

  TYPE pxl_width_arr_t IS ARRAY(1 DOWNTO 0) OF INTEGER;
  CONSTANT pxl_width_arr_c : pxl_width_arr_t := (1, 3); 
  --!!!
  -- set monochrome_en to 1 and depth_colr_c to 1 to show monochrome, else set monochrome_en_c to 0 and set depth_colr_c as needed 
  CONSTANT monochrome_en_c : integer := 0;
  -- depth of each pxl colour
  CONSTANT depth_colr_c    : INTEGER := 4;
  CONSTANT pxl_width_c     : INTEGER := depth_colr_c * pxl_width_arr_c(monochrome_en_c); -- Monochrome format

  CONSTANT tile_width_c  : INTEGER := 4; -- tile width or height in pixels
  CONSTANT total_tiles_c : INTEGER := (height_px_c * width_px_c) / (tile_width_c**2);
  CONSTANT tiles_per_row_c : INTEGER := 4; -- count of how many tiles are contained in a row of the frame buffer
  CONSTANT fbuff_data_width_c : INTEGER := tiles_per_row_c * pxl_width_c;
  CONSTANT fbuff_depth_c : INTEGER := (total_tiles_c / tiles_per_row_c);
  CONSTANT fbuff_addr_width_c : INTEGER :=  INTEGER(CEIL(LOG2(REAL(fbuff_depth_c - 1))));

  -- array to contain colours(RGB) in integer format
  SUBTYPE pixel_t   IS STD_LOGIC_VECTOR(pxl_width_c - 1 DOWNTO 0);
  TYPE colr_arr_t   IS ARRAY(2 DOWNTO 0) OF INTEGER RANGE ((2**depth_colr_c) - 1) DOWNTO 0;

END PACKAGE vga_pkg;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--PACKAGE BODY vga_pkg IS
--
--END PACKAGE BODY vga_pkg;
