-------------------------------------------------------------------------------
-- Title      : VGA Clock Divider
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_clk_div.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-06-24
-- Design     : vga_clk_div
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Clock divider for vga controller
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-24  1.0      TZS     Created
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_clk_div IS 
  GENERIC (
            ref_clk_freq_g : INTEGER := 50_000_000;
            px_clk_freq_g  : INTEGER := 25_000_000
          );
  PORT ( 
         clk   : IN STD_LOGIC;
         rst_n : IN STD_LOGIC;

         clk_px_out : OUT STD_LOGIC
       );
END ENTITY vga_clk_div;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_clk_div IS

  CONSTANT px_clk_cnt_max_c : INTEGER := (ref_clk_freq_g / px_clk_freq_g) / 2;

  SIGNAL px_clk_ctr_r : INTEGER RANGE px_clk_cnt_max_c DOWNTO 0;
  SIGNAL px_clk_r     : STD_LOGIC;

BEGIN
  
  -- check that the frequencies are not incompatible
  ASSERT px_clk_cnt_max_c /= 0
    REPORT "PIXEL CLOCK IS ZERO: Either reference clock is too low or requested pixel frequency is too high"
    SEVERITY FAILURE;

  sync_clk_div : PROCESS (clk, rst_n) IS 
  BEGIN 

    IF rst_n = '0' THEN 
  
      px_clk_ctr_r <=  0;
      px_clk_r     <= '0';
  
    ELSIF RISING_EDGE(clk) THEN 

      IF px_clk_ctr_r = px_clk_cnt_max_c-1 THEN 

        px_clk_ctr_r <= 0;
        px_clk_r     <= NOT px_clk_r;

      ELSE 

        px_clk_ctr_r <= px_clk_ctr_r + 1;

      END IF;
    END IF;
  END PROCESS sync_clk_div; 

  clk_px_out <= px_clk_r;

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------