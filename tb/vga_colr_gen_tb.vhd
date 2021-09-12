-------------------------------------------------------------------------------
-- Title      : VGA Colour Generator Testbench
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_colr_gen_tb.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-09-11
-- Design     : vga_colr_gen_tb
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Testbench for VGA Colour Generator
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-09-11  1.0      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE STD.ENV.FINISH;

ENTITY vga_colr_gen_tb IS 
  GENERIC (
    frame_rate_g : INTEGER := 60;
    depth_colr_g : INTEGER := 4
  );
END ENTITY vga_colr_gen_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb of vga_colr_gen_tb IS 

  COMPONENT vga_colr_gen
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
  END COMPONENT;

  SIGNAL clk, rst_n : STD_LOGIC := '0';
  SIGNAL r_colr_out_tb, g_colr_out_tb, b_colr_out_tb : STD_LOGIC_VECTOR(
                                    depth_colr_g-1 DOWNTO 0) := (OTHERS => '0'); 

BEGIN 

  i_vga_colr_gen : vga_colr_gen
    GENERIC MAP (
      frame_rate_g => frame_rate_g,
      depth_colr_g => depth_colr_g
    )
    PORT MAP (
      clk        => clk,
      rst_n      => rst_n,
      r_colr_out => r_colr_out_tb,
      g_colr_out => g_colr_out_tb,
      b_colr_out => b_colr_out_tb
    );

    -- ADD TEST LOGIC HERE!!!

  TEST_MNGR : PROCESS 
  BEGIN 
  
    WAIT UNTIL (NOW > 50 NS) AND (clk = '1'); 
    REPORT "Calling 'FINISH'";
    FINISH;
    
  END PROCESS;

END ARCHITECTURE tb;
--------------------------------------------------------------------------------