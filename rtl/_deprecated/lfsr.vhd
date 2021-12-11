-------------------------------------------------------------------------------
-- Title      : Linear Feedback Shift Register
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : lfsr.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-09-06
-- Design     : lfsr
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Variable width_g linear feedback shift register. Bit 0 and 1 XORd.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-09-06  1.0      TZS     Created
-- 2021-09-16  1.1      TZS     Modified shift en to be edge sensitive rather 
--                              than level sensitive
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY lfsr IS
  GENERIC (
    -- width of shift register
    width_g : INTEGER := 6
  );
  PORT (
    -- clock and reset
  	clk      : IN STD_LOGIC;
  	rst_n    : IN STD_LOGIC;
    -- lfsr enable
  	shift_en : IN STD_LOGIC;
    -- lfsr output
    lfsr_out : OUT STD_LOGIC_VECTOR(width_g-1 DOWNTO 0)
  );
END ENTITY lfsr;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF lfsr IS 
  -- lfsr 
  SIGNAL lfsr_r       : UNSIGNED(width_g-1 DOWNTO 0);
  -- value of shift enable dealyed by 1 cycle to allow edge detection
  SIGNAL shift_en_old : STD_LOGIC;

BEGIN

  PROCESS (clk, rst_n) IS 
  BEGIN 

    IF rst_n = '0' THEN -- async reset

      lfsr_r       <= ('0') & (width_g-2 DOWNTO 0 => '1');
      shift_en_old <= '0';

    
    ELSIF RISING_EDGE(clk) THEN -- rising clk
      
      -- shift lfsr 1 place when rising edge of shift enable is detected
      IF shift_en = '1' AND shift_en_old = '0' THEN
        lfsr_r <= lfsr_r srl 1;
      -- pseudorandom feedback of lsfr
        lfsr_r(width_g-1) <= lfsr_r(0) XOR lfsr_r(1);
      END IF;
      
      -- registered enable to detect rising edge
      shift_en_old <= shift_en; 
      
    END IF;

  END PROCESS;

  -- output assignment 
  lfsr_out <= STD_LOGIC_VECTOR(lfsr_r);

END ARCHITECTURE rtl;
--------------------------------------------------------------------------------