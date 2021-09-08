-------------------------------------------------------------------------------
-- Title      : VGA Controller Colour Generator Block
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_colr_gen.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-06-26
-- Design     : vga_colr_gen
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Block to generate a pattern of colours for the 10-bit RGB
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-24  1.0      TZS     Created
-- 2021-09-08  1.1      TZS     Refactored to use LFSR based generator
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY vga_colr_gen IS 
GENERIC (
          frame_rate_g : INTEGER := 60;
          depth_colr_g : INTEGER := 4
        );
PORT (
       clk       : IN STD_LOGIC;
       rst_n     : IN STD_LOGIC;

       r_colr_out : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
       g_colr_out : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
       b_colr_out : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0)
     );
END ENTITY vga_colr_gen;

--------------------------------------------------------------------------------
ARCHITECTURE rtl OF vga_colr_gen IS

  COMPONENT lfsr
    GENERIC (
      SIZE : INTEGER := 6
    );
    PORT (
      clk      : IN STD_LOGIC;
      rst_n    : IN STD_LOGIC;
      shift_en : IN STD_LOGIC;
      lfsr_out : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT vga_colr_gen_cntr
    GENERIC (
      frame_rate_g : INTEGER := 60 -- FPS
    );
    PORT (
      clk    : IN STD_LOGIC;
      rst_n  : IN STD_LOGIC;
    
      en_out : OUT STD_LOGIC
    );
  END COMPONENT;

  TYPE colr_arr_t IS ARRAY(2 DOWNTO 0) OF STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);

  SIGNAL colr_arr_r : colr_arr_t;

BEGIN

  

END ARCHITECTURE rtl;
--------------------------------------------------------------------------------
