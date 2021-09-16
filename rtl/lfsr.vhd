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
-- Description: Variable size linear feedback shift register. Bit 0 and 1 XORd.
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
    SIZE : INTEGER := 6
  );
  PORT (
  	clk      : IN STD_LOGIC;
  	rst_n    : IN STD_LOGIC;
  	shift_en : IN STD_LOGIC;
    lfsr_out : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0)
  );
END ENTITY lfsr;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF lfsr IS 

  SIGNAL lfsr_r       : UNSIGNED(SIZE-1 DOWNTO 0);
  SIGNAL shift_en_old : STD_LOGIC;

BEGIN

  PROCESS (clk, rst_n) IS 
  BEGIN 

    IF rst_n = '0' THEN

      lfsr_r       <= ('0') & (SIZE-2 DOWNTO 0 => '1');
      shift_en_old <= '0';

    
    ELSIF RISING_EDGE(clk) THEN
      
      IF shift_en = '1' AND shift_en_old = '0' THEN
        lfsr_r <= lfsr_r srl 1;
        lfsr_r(SIZE-1) <= lfsr_r(0) XOR lfsr_r(1);
      END IF;

      shift_en_old <= shift_en;
      
    END IF;

  END PROCESS;

  lfsr_out <= STD_LOGIC_VECTOR(lfsr_r);

END ARCHITECTURE rtl;
--------------------------------------------------------------------------------