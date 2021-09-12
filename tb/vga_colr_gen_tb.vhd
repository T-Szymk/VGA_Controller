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
    frame_period_g : TIME    := 100 ms; -- 25MHz
    frame_rate_g   : INTEGER := 10;
    depth_colr_g   : INTEGER := 4
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

  CONSTANT max_sim_time_c : TIME := 3 SEC;

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

  rst_n <= '1' after 4 * 50 NS;

  TEST_MNGR : PROCESS 
  BEGIN 
  
    WHILE NOW < max_sim_time_c LOOP
      clk <= NOT clk;
      WAIT FOR frame_period_g / 2;
    END LOOP;

    ASSERT now < max_sim_time_c
      REPORT "SIMULATION COMPLETE!"
      SEVERITY NOTE;

    FINISH;
    
  END PROCESS;

END ARCHITECTURE tb;
--------------------------------------------------------------------------------