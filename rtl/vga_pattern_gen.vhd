-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Test Pattern Generator
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_patter_gen.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-12-12
-- Design     : vga_pattern_gen
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module containing bevioural implementation of a test pattern
--              generator which can be used to verify VGA operation.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-12-12  1.1      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.VGA_PKG.ALL;

ENTITY vga_pattern_gen IS 
  PORT (
    pxl_ctr_i  : IN STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
    line_ctr_i : IN STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0);
    -- output is aggregate RGB array
    colr_out   : OUT STD_LOGIC_VECTOR(((3*depth_colr_c) - 1) DOWNTO 0)
  );
END ENTITY vga_pattern_gen;

--------------------------------------------------------------------------------

ARCHITECTURE behavioral OF vga_pattern_gen IS 

  -- TODO: Calculate constants required to determine whether colours need to change.
  --       Try to calculate values in a generic fashion
  --       Do this in the VGA_PKG

  CONSTANT colr_col_width_c : INTEGER := (width_px_c / 7);
  CONSTANT grey_col_width_c : INTEGER := (width_px_c / 16);

  SIGNAL colr_s         : colr_arr_t;
  SIGNAL pxl_ctr_int_s  : INTEGER RANGE (pxl_ctr_max_c - 1) DOWNTO 0;
  SIGNAL line_ctr_int_s : INTEGER RANGE (line_ctr_max_c - 1) DOWNTO 0; 

BEGIN 
  -- convert to integer to make assignment expressions more compact
  pxl_ctr_int_s  <= TO_INTEGER(UNSIGNED(pxl_ctr_i));
  line_ctr_int_s <= TO_INTEGER(UNSIGNED(line_ctr_i));

  colr_s <= 
    -- white
    (15, 15, 15) WHEN line_ctr_int_s < (height_px_c / 2) AND 
                      pxl_ctr_int_s < colr_col_width_c ELSE
    -- yellow 
    (15, 15,  0) WHEN line_ctr_int_s < (height_px_c / 2) AND
                      pxl_ctr_int_s < (colr_col_width_c * 2) ELSE
    -- cyan
    ( 0, 15, 15) WHEN line_ctr_int_s < (height_px_c / 2) AND
                      pxl_ctr_int_s < (colr_col_width_c * 3) ELSE 
    -- green
    ( 0, 15,  0) WHEN line_ctr_int_s < (height_px_c / 2) AND
                      pxl_ctr_int_s < (colr_col_width_c * 4) ELSE
    -- magenta
    (15,  0, 15) WHEN line_ctr_int_s < (height_px_c / 2) AND
                      pxl_ctr_int_s < (colr_col_width_c * 5) ELSE
    -- red
    (15,  0,  0) WHEN line_ctr_int_s < (height_px_c / 2) AND
                      pxl_ctr_int_s < (colr_col_width_c * 6) ELSE
    -- blue
    ( 0,  0, 15) WHEN line_ctr_int_s < (height_px_c / 2) AND
                      pxl_ctr_int_s < width_px_c ELSE 
    -- black
    ( 0,  0,  0) WHEN line_ctr_int_s < ((height_px_c / 4) * 3) AND
                      pxl_ctr_int_s < colr_col_width_c ELSE
    -- blue
    ( 0,  0, 15) WHEN line_ctr_int_s < ((height_px_c / 4) * 3) AND
                      pxl_ctr_int_s < (colr_col_width_c * 2) ELSE
    -- red
    (15,  0,  0) WHEN line_ctr_int_s < ((height_px_c / 4) * 3) AND
                      pxl_ctr_int_s < (colr_col_width_c * 3) ELSE
    -- magenta
    (15,  0, 15) WHEN line_ctr_int_s < ((height_px_c / 4) * 3) AND
                      pxl_ctr_int_s < (colr_col_width_c * 4) ELSE
    -- green
    ( 0, 15,  0) WHEN line_ctr_int_s < ((height_px_c / 4) * 3) AND
                      pxl_ctr_int_s < (colr_col_width_c * 5) ELSE
    -- cyan
    ( 0, 15, 15) WHEN line_ctr_int_s < ((height_px_c / 4) * 3) AND
                      pxl_ctr_int_s < (colr_col_width_c * 6) ELSE 
    -- yellow
    (15, 15,  0) WHEN line_ctr_int_s < ((height_px_c / 4) * 3) AND
                      pxl_ctr_int_s < width_px_c ELSE
    -- greyscale 1-16
    ( 0,  0,  0) WHEN pxl_ctr_int_s < grey_col_width_c ELSE
    ( 1,  1,  1) WHEN pxl_ctr_int_s < (grey_col_width_c * 2) ELSE
    ( 2,  2,  2) WHEN pxl_ctr_int_s < (grey_col_width_c * 3) ELSE
    ( 3,  3,  3) WHEN pxl_ctr_int_s < (grey_col_width_c * 4) ELSE
    ( 4,  4,  4) WHEN pxl_ctr_int_s < (grey_col_width_c * 5) ELSE
    ( 5,  5,  5) WHEN pxl_ctr_int_s < (grey_col_width_c * 6) ELSE
    ( 6,  6,  6) WHEN pxl_ctr_int_s < (grey_col_width_c * 7) ELSE
    ( 7,  7,  7) WHEN pxl_ctr_int_s < (grey_col_width_c * 8) ELSE
    ( 8,  8,  8) WHEN pxl_ctr_int_s < (grey_col_width_c * 9) ELSE
    ( 9,  9,  9) WHEN pxl_ctr_int_s < (grey_col_width_c * 10) ELSE
    (10, 10, 10) WHEN pxl_ctr_int_s < (grey_col_width_c * 11) ELSE
    (11, 11, 11) WHEN pxl_ctr_int_s < (grey_col_width_c * 12) ELSE
    (12, 12, 12) WHEN pxl_ctr_int_s < (grey_col_width_c * 13) ELSE
    (13, 13, 13) WHEN pxl_ctr_int_s < (grey_col_width_c * 14) ELSE
    (14, 14, 14) WHEN pxl_ctr_int_s < (grey_col_width_c * 15) ELSE
    (15, 15, 15) WHEN pxl_ctr_int_s < width_px_c ELSE
    ( 0,  0,  0); 

  colr_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(colr_s(2), depth_colr_c)) & 
              STD_LOGIC_VECTOR(TO_UNSIGNED(colr_s(1), depth_colr_c)) & 
              STD_LOGIC_VECTOR(TO_UNSIGNED(colr_s(0), depth_colr_c)); 

END ARCHITECTURE behavioral;

--------------------------------------------------------------------------------