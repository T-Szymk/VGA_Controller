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
  CONSTANT depth_colr_c    : INTEGER := 1;
  CONSTANT pxl_width_c     : INTEGER := depth_colr_c * pxl_width_arr_c(monochrome_en_c); -- Monochrome format


  CONSTANT pxl_per_row_c   : INTEGER := 8;
  -- width of counter used to count current pixel in memory row beign displayed
  CONSTANT row_ctr_width_c : INTEGER := INTEGER(CEIL(LOG2(REAL(pxl_per_row_c - 1))));

  CONSTANT mem_row_width_c : INTEGER := pxl_per_row_c * pxl_width_c;
  CONSTANT mem_depth_c     : INTEGER := INTEGER(CEIL(REAL(disp_pxl_max_c)/REAL(pxl_per_row_c)));
  -- width of memory address signals
  CONSTANT mem_addr_width_c : INTEGER := INTEGER(CEIL(LOG2(REAL(mem_depth_c - 1))));
  -- array to contain colours(RGB) in integer format
  SUBTYPE pixel_t   IS STD_LOGIC_VECTOR(pxl_width_c - 1 DOWNTO 0);
  TYPE pixel_word_t IS ARRAY(pxl_per_row_c - 1 DOWNTO 0) OF pixel_t; 
  TYPE colr_arr_t   IS ARRAY(2 DOWNTO 0) OF INTEGER RANGE ((2**depth_colr_c) - 1) DOWNTO 0;

  -- buffer management subroutines
  PROCEDURE buff_fill ( 
    signal mem_word_i : in  std_logic_vector(mem_row_width_c-1 downto 0);
    signal buff_o     : out pixel_word_t
  );

  PROCEDURE buff_clr ( 
    signal buff_o : out pixel_word_t
  );

END PACKAGE vga_pkg;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

PACKAGE BODY vga_pkg IS

  PROCEDURE buff_fill ( --------------------------------------------------------
    signal mem_word_i : in  std_logic_vector(mem_row_width_c-1 downto 0);
    signal buff_o     : out pixel_word_t ) IS 
  BEGIN 

    FOR i IN pxl_per_row_c-1 DOWNTO 0 LOOP 
      buff_o(i) <= mem_word_i(((i * pxl_width_c) + pxl_width_c)-1 
                              DOWNTO (i * pxl_width_c)); 
    END LOOP;

  END PROCEDURE buff_fill; -----------------------------------------------------


  PROCEDURE buff_clr ( ---------------------------------------------------------
    signal buff_o : out pixel_word_t ) IS 
  BEGIN 

    FOR i IN pxl_per_row_c-1 DOWNTO 0 LOOP 
      buff_o(i) <= (others => '0');
    END LOOP;

  END PROCEDURE buff_clr; ------------------------------------------------------

END PACKAGE BODY vga_pkg;
