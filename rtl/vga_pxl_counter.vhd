-------------------------------------------------------------------------------
-- Title      : VGA Controller Pixel Counter
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_pxl_counter.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-12-11
-- Design     : vga_controller
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Counter to provide pixel and line counter values to be used by
--              VGA controller.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-12-11  1.0      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.VGA_PKG.ALL;

ENTITY vga_pxl_counter IS 
	PORT (
    clk        : IN STD_LOGIC;
    rst_n      : IN STD_LOGIC;
    
    pxl_ctr_o  : OUT STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
    line_ctr_o : OUT STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0)
	);
END ENTITY vga_pxl_counter;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_pxl_counter IS 

-- VARIABLES / CONSTANTS / TYPES -----------------------------------------------

  SIGNAL pxl_ctr_r  : pxl_ctr_t;
  SIGNAL line_ctr_r : line_ctr_t;

BEGIN

  sync_cntrs : PROCESS (clk, rst_n) IS -- line/pxl counters --------------------
  BEGIN 

    IF rst_n = '0' THEN 

      pxl_ctr_r  <= pxl_ctr_t'HIGH;
      line_ctr_r <= line_ctr_t'HIGH;

    ELSIF RISING_EDGE(clk) THEN 

      IF pxl_ctr_r = pxl_ctr_t'HIGH THEN

        IF line_ctr_r = line_ctr_t'HIGH THEN -- end of frame
          line_ctr_r <=  0; 
        ELSE -- end of line but not frame
          line_ctr_r <= line_ctr_r + 1; 
        END IF;

        pxl_ctr_r <=  0; -- reset px_counter at end of the line

      ELSE 

        pxl_ctr_r <= pxl_ctr_r + 1;

      END IF;
    END IF;
  END PROCESS sync_cntrs; ------------------------------------------------------

  pxl_ctr_o  <= STD_LOGIC_VECTOR(TO_UNSIGNED(pxl_ctr_r, pxl_ctr_width_c));
  line_ctr_o <= STD_LOGIC_VECTOR(TO_UNSIGNED(line_ctr_r, line_ctr_width_c));

END ARCHITECTURE;

--------------------------------------------------------------------------------