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
            -- reference clock/primary oscillator/input frequncy
            ref_clk_freq_g : INTEGER := 50_000_000;
            -- VGA pxl clock frequency
            px_clk_freq_g  : INTEGER := 25_000_000
          );
  PORT ( 
         -- clock and reset
         clk_i  : IN STD_LOGIC;
         rstn_i : IN STD_LOGIC;
         -- VGA pixel clock output
         clk_px_out : OUT STD_LOGIC
       );
END ENTITY vga_clk_div;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_clk_div IS
  -- calculate the max counter value using frequncy
  CONSTANT px_clk_cnt_max_c : INTEGER := (ref_clk_freq_g / px_clk_freq_g) / 2;
  
  -- intermediate registers
  SIGNAL px_clk_ctr_r : INTEGER RANGE px_clk_cnt_max_c DOWNTO 0;
  SIGNAL px_clk_r     : STD_LOGIC;

BEGIN
  
  -- check that the frequencies are not incompatible
  ASSERT px_clk_cnt_max_c /= 0
    REPORT "PIXEL CLOCK IS ZERO: Either reference clock is too low or" & 
    "requested pixel frequency is too high"
    SEVERITY FAILURE;

  sync_clk_div : PROCESS (clk_i, rstn_i) IS 
  BEGIN 

    IF rstn_i = '0' THEN -- async reset
  
      px_clk_ctr_r <=  0;
      px_clk_r     <= '0';
  
    ELSIF RISING_EDGE(clk_i) THEN -- rising clk edge
      
      -- implement registered clock divider
      IF px_clk_ctr_r = px_clk_cnt_max_c-1 THEN 

        px_clk_ctr_r <= 0;
        px_clk_r     <= NOT px_clk_r;

      ELSE 

        px_clk_ctr_r <= px_clk_ctr_r + 1;

      END IF;
    END IF;
  END PROCESS sync_clk_div; 
  
  -- output assignment
  clk_px_out <= px_clk_r;

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------