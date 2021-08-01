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
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY vga_colr_gen IS 
GENERIC (
          r_cntr_inc_g : INTEGER := 10;
          g_cntr_inc_g : INTEGER := 5;
          b_cntr_inc_g : INTEGER := 15
        );
PORT (
       clk       : IN STD_LOGIC;
       rst_n     : IN STD_LOGIC;
       trig_in   : IN STD_LOGIC; -- take from v_sync

       r_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
       g_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
       b_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0)
     );
END ENTITY vga_colr_gen;

--------------------------------------------------------------------------------
ARCHITECTURE rtl OF vga_colr_gen IS

  SIGNAL en_r, trig_old_r : STD_LOGIC;
  SIGNAL r_colr_s, g_colr_s, b_colr_s : UNSIGNED(10-1 DOWNTO 0);
  SIGNAL r_colr_r, g_colr_r, b_colr_r : UNSIGNED(10-1 DOWNTO 0);
  

BEGIN

  PROCESS(clk, rst_n) IS
  BEGIN 

    IF rst_n = '0' THEN

      trig_old_r <= '1';
      r_colr_r <= (OTHERS => '0');
      g_colr_r <= (OTHERS => '0');
      b_colr_r <= (OTHERS => '0');


    ELSIF RISING_EDGE(clk) THEN

      IF trig_old_r = '1' AND trig_in = '0' THEN -- falling edge of v_sync
        
		  en_r <= '1';
		  
		ELSE 
		  
		  en_r <= '0';
      
		END IF;
		
		r_colr_r <= r_colr_s;
      g_colr_r <= g_colr_s;
      b_colr_r <= b_colr_s;

      trig_old_r <= trig_in;

    END IF;
  END PROCESS;

  PROCESS(r_colr_r, g_colr_r, b_colr_r, en_r) IS
  BEGIN
  
    IF en_r = '1' THEN
	 
  	   r_colr_s <= r_colr_r + r_cntr_inc_g;
  	   g_colr_s <= g_colr_r + g_cntr_inc_g;
  	   b_colr_s <= b_colr_r + b_cntr_inc_g;
		
    ELSE 
	 
	   r_colr_s <= r_colr_r;
		g_colr_s <= g_colr_r;
		b_colr_s <= b_colr_r;
	 
	 END IF;
  END PROCESS;
  
  r_colr_out <= STD_LOGIC_VECTOR(r_colr_r);
  g_colr_out <= STD_LOGIC_VECTOR(g_colr_r);
  b_colr_out <= STD_LOGIC_VECTOR(b_colr_r);

END ARCHITECTURE rtl;
--------------------------------------------------------------------------------