-------------------------------------------------------------------------------
-- Title      : VGA Colour Generator Counter
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_colr_gen_cntr.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-09-08
-- Design     : vga_colr_gen_cntr
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Counter used to drive the LFSR of the colour pattern generator
--              which is used in pattern generator mode.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-09-06  1.0      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_colr_gen_cntr IS
GENERIC (
	  frame_rate_g : INTEGER := 60 -- FPS
	);
PORT (
    clk    : IN STD_LOGIC;
    rst_n  : IN STD_LOGIC;

    en_out : OUT STD_LOGIC
  );
END ENTITY vga_colr_gen_cntr;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_colr_gen_cntr IS 

  SIGNAL en_r  : STD_LOGIC;
  SIGNAL ctr_r : INTEGER RANGE frame_rate_g DOWNTO 0;

BEGIN

  PROCESS (clk, rst_n) IS ------------------------------------------------------
  BEGIN
  
    IF rst_n = '0' THEN 

      en_r  <= '0';
      ctr_r <= 0;

    ELSIF RISING_EDGE(clk) THEN

      IF ctr_r = (frame_rate_g - 1) THEN 

        ctr_r <= 0;
        en_r  <= '1';

      ELSE 

        ctr_r <= ctr_r + 1;
        en_r  <= '0';

      END IF;

    END IF;

  END PROCESS; -----------------------------------------------------------------

  en_out <= en_r;

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------