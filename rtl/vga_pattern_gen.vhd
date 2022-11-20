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
-- 2022-06-27  1.2      TZS     Added 1-bit colour depth implementation
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity vga_pattern_gen is 
  port (
    pxl_ctr_i  : in std_logic_vector((pxl_ctr_width_c - 1) downto 0);
    line_ctr_i : in std_logic_vector((line_ctr_width_c - 1) downto 0);
    -- output is aggregate rgb array
    colr_out   : out pixel_t
  );
end entity vga_pattern_gen;

----------------------------------------------------------------------------------
ARCHITECTURE behavioral OF vga_pattern_gen IS 

  TYPE pattern_arr_7_t  IS ARRAY((7 - 1)  DOWNTO 0) OF INTEGER;
  TYPE pattern_arr_16_t IS ARRAY((16 - 1) DOWNTO 0) OF INTEGER;

  CONSTANT pattern_arr_7_c : pattern_arr_7_t := 
                                   (
                                    h_b_porch_max_px_c + (width_px_c  / 7),
                                    h_b_porch_max_px_c + ((width_px_c / 7) * 2),
                                    h_b_porch_max_px_c + ((width_px_c / 7) * 3),
                                    h_b_porch_max_px_c + ((width_px_c / 7) * 4),
                                    h_b_porch_max_px_c + ((width_px_c / 7) * 5),
                                    h_b_porch_max_px_c + ((width_px_c / 7) * 6),
                                    h_b_porch_max_px_c + (width_px_c)
                                   );
  CONSTANT pattern_arr_16_c : pattern_arr_16_t := 
                                 (
                                  h_b_porch_max_px_c + (width_px_c  / 16),
                                  h_b_porch_max_px_c + ((width_px_c / 16) *  2),
                                  h_b_porch_max_px_c + ((width_px_c / 16) *  3),
                                  h_b_porch_max_px_c + ((width_px_c / 16) *  4),
                                  h_b_porch_max_px_c + ((width_px_c / 16) *  5),
                                  h_b_porch_max_px_c + ((width_px_c / 16) *  6),
                                  h_b_porch_max_px_c + ((width_px_c / 16) *  7),
                                  h_b_porch_max_px_c + ((width_px_c / 16) *  8),
                                  h_b_porch_max_px_c + ((width_px_c / 16) *  9),
                                  h_b_porch_max_px_c + ((width_px_c / 16) * 10),
                                  h_b_porch_max_px_c + ((width_px_c / 16) * 11),
                                  h_b_porch_max_px_c + ((width_px_c / 16) * 12),
                                  h_b_porch_max_px_c + ((width_px_c / 16) * 13),
                                  h_b_porch_max_px_c + ((width_px_c / 16) * 14),
                                  h_b_porch_max_px_c + ((width_px_c / 16) * 15),
                                  h_b_porch_max_px_c + (width_px_c)
                                 );
  CONSTANT patt_colr_split_height_c : INTEGER := (v_b_porch_max_lns_c + 
                                                 (height_px_c) / 2);
  CONSTANT patt_grey_split_height_c : INTEGER := (v_b_porch_max_lns_c + 
                                                 ((height_px_c) / 4) * 3);
  
  TYPE rgb_4_arr_t IS  ARRAY (2 DOWNTO 0) OF INTEGER;
  SIGNAL colr_rgb_4 : rgb_4_arr_t;

  SIGNAL colr_s         : pixel_t;
  SIGNAL pxl_ctr_int_s  : INTEGER RANGE (pxl_ctr_max_c - 1) DOWNTO 0;
  SIGNAL line_ctr_int_s : INTEGER RANGE (line_ctr_max_c - 1) DOWNTO 0; 

BEGIN 

--------------------------------------------------------------------------------
-- RGB DEPTH = 4 Implementation
--------------------------------------------------------------------------------
  gen_RGB_depth_4 : if monochrome_en_c = 0 and depth_colr_c = 4 generate
    -- convert to integer to make assignment expressions more compact
    pxl_ctr_int_s  <= TO_INTEGER(UNSIGNED(pxl_ctr_i));
    line_ctr_int_s <= TO_INTEGER(UNSIGNED(line_ctr_i));
  
    colr_rgb_4 <= 
      -- white
      (15, 15, 15) WHEN line_ctr_int_s < (patt_colr_split_height_c) AND 
                        pxl_ctr_int_s <  pattern_arr_7_c(6) ELSE
      -- yellow 
      (15, 15,  0) WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
                        pxl_ctr_int_s <  pattern_arr_7_c(5) ELSE
      -- cyan
      ( 0, 15, 15) WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
                        pxl_ctr_int_s <  pattern_arr_7_c(4) ELSE 
      -- green
      ( 0, 15,  0) WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
                        pxl_ctr_int_s <  pattern_arr_7_c(3) ELSE
      -- magenta
      (15,  0, 15) WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
                        pxl_ctr_int_s <  pattern_arr_7_c(2) ELSE
      -- red
      (15,  0,  0) WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
                        pxl_ctr_int_s <  pattern_arr_7_c(1) ELSE
      -- blue
      ( 0,  0, 15) WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
                        pxl_ctr_int_s <  pattern_arr_7_c(0) ELSE 
    -- second colour section
      -- black
      ( 0,  0,  0) WHEN line_ctr_int_s < patt_grey_split_height_c AND
                        pxl_ctr_int_s < pattern_arr_7_c(6) ELSE
      -- blue
      ( 0,  0, 15) WHEN line_ctr_int_s < patt_grey_split_height_c AND
                        pxl_ctr_int_s < pattern_arr_7_c(5) ELSE
      -- red
      (15,  0,  0) WHEN line_ctr_int_s < patt_grey_split_height_c AND
                        pxl_ctr_int_s < pattern_arr_7_c(4) ELSE
      -- magenta
      (15,  0, 15) WHEN line_ctr_int_s < patt_grey_split_height_c AND
                        pxl_ctr_int_s < pattern_arr_7_c(3) ELSE
      -- green
      ( 0, 15,  0) WHEN line_ctr_int_s < patt_grey_split_height_c AND
                        pxl_ctr_int_s < pattern_arr_7_c(2) ELSE
      -- cyan
      ( 0, 15, 15) WHEN line_ctr_int_s < patt_grey_split_height_c AND
                        pxl_ctr_int_s < pattern_arr_7_c(1) ELSE 
      -- yellow
      (15, 15,  0) WHEN line_ctr_int_s < patt_grey_split_height_c AND
                        pxl_ctr_int_s < pattern_arr_7_c(0) ELSE
    -- greyscale 3/4 down the screen
      -- greyscale 1-16
      ( 0,  0,  0) WHEN pxl_ctr_int_s < (pattern_arr_16_c(15)) ELSE
      ( 1,  1,  1) WHEN pxl_ctr_int_s < (pattern_arr_16_c(14)) ELSE
      ( 2,  2,  2) WHEN pxl_ctr_int_s < (pattern_arr_16_c(13)) ELSE
      ( 3,  3,  3) WHEN pxl_ctr_int_s < (pattern_arr_16_c(12)) ELSE
      ( 4,  4,  4) WHEN pxl_ctr_int_s < (pattern_arr_16_c(11)) ELSE
      ( 5,  5,  5) WHEN pxl_ctr_int_s < (pattern_arr_16_c(10)) ELSE
      ( 6,  6,  6) WHEN pxl_ctr_int_s < (pattern_arr_16_c(9)) ELSE
      ( 7,  7,  7) WHEN pxl_ctr_int_s < (pattern_arr_16_c(8)) ELSE
      ( 8,  8,  8) WHEN pxl_ctr_int_s < (pattern_arr_16_c(7)) ELSE
      ( 9,  9,  9) WHEN pxl_ctr_int_s < (pattern_arr_16_c(6)) ELSE
      (10, 10, 10) WHEN pxl_ctr_int_s < (pattern_arr_16_c(5)) ELSE
      (11, 11, 11) WHEN pxl_ctr_int_s < (pattern_arr_16_c(4)) ELSE
      (12, 12, 12) WHEN pxl_ctr_int_s < (pattern_arr_16_c(3)) ELSE
      (13, 13, 13) WHEN pxl_ctr_int_s < (pattern_arr_16_c(2)) ELSE
      (14, 14, 14) WHEN pxl_ctr_int_s < (pattern_arr_16_c(1)) ELSE
      (15, 15, 15) WHEN pxl_ctr_int_s < (pattern_arr_16_c(0)) ELSE
      ( 0,  0,  0); 
  
    colr_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(colr_rgb_4(2), 4)) & 
                STD_LOGIC_VECTOR(TO_UNSIGNED(colr_rgb_4(1), 4)) & 
                STD_LOGIC_VECTOR(TO_UNSIGNED(colr_rgb_4(0), 4)); 
  end generate gen_RGB_depth_4;
--------------------------------------------------------------------------------
-- RGB DEPTH = 1 Implementation
--------------------------------------------------------------------------------
  gen_RGB_depth_1 : if monochrome_en_c = 0 and depth_colr_c = 1 generate
     -- convert to integer to make assignment expressions more compact
     pxl_ctr_int_s  <= TO_INTEGER(UNSIGNED(pxl_ctr_i));
     line_ctr_int_s <= TO_INTEGER(UNSIGNED(line_ctr_i));
   
     colr_s <= 
       -- white
       ('1', '1', '1') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND 
       pxl_ctr_int_s <  pattern_arr_7_c(6) ELSE
       -- yellow 
       ('1', '1', '0') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
       pxl_ctr_int_s <  pattern_arr_7_c(5) ELSE
       -- cyan
       ('0', '1', '1') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
       pxl_ctr_int_s <  pattern_arr_7_c(4) ELSE 
       -- green
       ('0', '1',  '0') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
       pxl_ctr_int_s <  pattern_arr_7_c(3) ELSE
       -- magenta
       ('1', '0', '1') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
       pxl_ctr_int_s <  pattern_arr_7_c(2) ELSE
       -- red
       ('1', '0',  '0') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
       pxl_ctr_int_s <  pattern_arr_7_c(1) ELSE
       -- blue
       ('0', '0', '1') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
       pxl_ctr_int_s <  pattern_arr_7_c(0) ELSE 
       -- second colour section
       -- black
       ('0', '0', '0') WHEN line_ctr_int_s < patt_grey_split_height_c AND
       pxl_ctr_int_s < pattern_arr_7_c(6) ELSE
       -- blue
       ('0', '0', '1') WHEN line_ctr_int_s < patt_grey_split_height_c AND
       pxl_ctr_int_s < pattern_arr_7_c(5) ELSE
       -- red
       ('1', '0', '0') WHEN line_ctr_int_s < patt_grey_split_height_c AND
       pxl_ctr_int_s < pattern_arr_7_c(4) ELSE
       -- magenta
       ('1', '0', '1') WHEN line_ctr_int_s < patt_grey_split_height_c AND
       pxl_ctr_int_s < pattern_arr_7_c(3) ELSE
       -- green
       ('0', '1', '0') WHEN line_ctr_int_s < patt_grey_split_height_c AND
       pxl_ctr_int_s < pattern_arr_7_c(2) ELSE
       -- cyan
       ('0', '1', '1') WHEN line_ctr_int_s < patt_grey_split_height_c AND
       pxl_ctr_int_s < pattern_arr_7_c(1) ELSE 
       -- yellow
       ('1', '1', '0') WHEN line_ctr_int_s < patt_grey_split_height_c AND
       pxl_ctr_int_s < pattern_arr_7_c(0) ELSE
       -- greyscale 3/4 down the screen
       -- greyscale 1-16
       ( '0',  '0',  '0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(15)) ELSE
       ( '1',  '1',  '1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(14)) ELSE
       ( '0',  '0',  '0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(13)) ELSE
       ( '1',  '1',  '1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(12)) ELSE
       ( '0',  '0',  '0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(11)) ELSE
       ( '1',  '1',  '1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(10)) ELSE
       ( '0',  '0',  '0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(9)) ELSE
       ( '1',  '1',  '1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(8)) ELSE
       ( '0',  '0',  '0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(7)) ELSE
       ( '1',  '1',  '1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(6)) ELSE
       ( '0',  '0',  '0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(5)) ELSE
       ( '1',  '1',  '1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(4)) ELSE
       ( '0',  '0',  '0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(3)) ELSE
       ( '1',  '1',  '1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(2)) ELSE
       ( '0',  '0',  '0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(1)) ELSE
       ( '1',  '1',  '1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(0)) ELSE
       ( '0',  '0',  '0'); 
   
     colr_out <= (colr_s(2), 
                  colr_s(1), 
                  colr_s(0)); 
  end generate gen_RGB_depth_1;
--------------------------------------------------------------------------------
-- Monochrome Implementation
--------------------------------------------------------------------------------
  
  gen_monochrome : if monochrome_en_c = 1 generate 
    -- convert to integer to make assignment expressions more compact
    pxl_ctr_int_s  <= TO_INTEGER(UNSIGNED(pxl_ctr_i));
    line_ctr_int_s <= TO_INTEGER(UNSIGNED(line_ctr_i));
  
    colr_s(0) <= 
      -- white
      ('0') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND 
      pxl_ctr_int_s <  pattern_arr_7_c(6) ELSE
      -- yellow 
      ('1') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
      pxl_ctr_int_s <  pattern_arr_7_c(5) ELSE
      -- cyan
      ('0') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
      pxl_ctr_int_s <  pattern_arr_7_c(4) ELSE 
      -- green
      ('1') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
      pxl_ctr_int_s <  pattern_arr_7_c(3) ELSE
      -- magenta
      ('0') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
      pxl_ctr_int_s <  pattern_arr_7_c(2) ELSE
      -- red
      ('1') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
      pxl_ctr_int_s <  pattern_arr_7_c(1) ELSE
      -- blue
      ('0') WHEN line_ctr_int_s < (patt_colr_split_height_c) AND
      pxl_ctr_int_s <  pattern_arr_7_c(0) ELSE 
      -- second colour section
      -- black
      ('1') WHEN line_ctr_int_s < patt_grey_split_height_c AND
      pxl_ctr_int_s < pattern_arr_7_c(6) ELSE
      -- blue
      ('0') WHEN line_ctr_int_s < patt_grey_split_height_c AND
      pxl_ctr_int_s < pattern_arr_7_c(5) ELSE
      -- red
      ('1') WHEN line_ctr_int_s < patt_grey_split_height_c AND
      pxl_ctr_int_s < pattern_arr_7_c(4) ELSE
      -- magenta
      ('0') WHEN line_ctr_int_s < patt_grey_split_height_c AND
      pxl_ctr_int_s < pattern_arr_7_c(3) ELSE
      -- green
      ('1') WHEN line_ctr_int_s < patt_grey_split_height_c AND
      pxl_ctr_int_s < pattern_arr_7_c(2) ELSE
      -- cyan
      ('0') WHEN line_ctr_int_s < patt_grey_split_height_c AND
      pxl_ctr_int_s < pattern_arr_7_c(1) ELSE 
      -- yellow
      ('1') WHEN line_ctr_int_s < patt_grey_split_height_c AND
      pxl_ctr_int_s < pattern_arr_7_c(0) ELSE
      -- greyscale 3/4 down the screen
      -- greyscale 1-16
      ('0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(15)) ELSE
      ('1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(14)) ELSE
      ('0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(13)) ELSE
      ('1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(12)) ELSE
      ('0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(11)) ELSE
      ('1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(10)) ELSE
      ('0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(9)) ELSE
      ('1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(8)) ELSE
      ('0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(7)) ELSE
      ('1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(6)) ELSE
      ('0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(5)) ELSE
      ('1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(4)) ELSE
      ('0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(3)) ELSE
      ('1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(2)) ELSE
      ('0') WHEN pxl_ctr_int_s < (pattern_arr_16_c(1)) ELSE
      ('1') WHEN pxl_ctr_int_s < (pattern_arr_16_c(0)) ELSE
      ('0'); 
     
    colr_out <= colr_s; 

  end generate gen_monochrome;


END ARCHITECTURE behavioral;