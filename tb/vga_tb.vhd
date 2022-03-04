-------------------------------------------------------------------------------
-- Title      : VGA Controller Testbench
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_tb.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-06-25
-- Design     : vga_tb
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Testbench for VGA controller
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-25  1.0      TZS     Created
-- 2021-07-19  1.1      TZS     Updated TB to match latest design
--                              Removed signals related to DE2 board
-- 2021-12-12  1.2      TZS     Updated signals to use most recent interfaces
-- 2022-03-04  1.3      TZS     Removed unused switches
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE WORK.VGA_PKG.ALL;
USE STD.ENV.FINISH;

ENTITY vga_tb IS
  GENERIC (
            ref_clk_perd_g : TIME    := 10 ns;
            max_sim_time_g : TIME    :=  3 sec;
            CONF_SIM       : INTEGER := 1;
            CONF_TEST_PATT : INTEGER := 1
  );
END ENTITY vga_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb OF vga_tb IS 

  COMPONENT vga_top IS 
    GENERIC (
              CONF_SIM       : INTEGER     := 1;
              CONF_TEST_PATT : INTEGER     := 1
            );
    
    PORT (
           clk    : IN STD_LOGIC;
           rst_n  : IN STD_LOGIC; 

           v_sync_out  : OUT STD_LOGIC;
           h_sync_out  : OUT STD_LOGIC;
           r_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_c-1 DOWNTO 0);
           g_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_c-1 DOWNTO 0);
           b_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_c-1 DOWNTO 0)
         );
  END COMPONENT;

  SIGNAL clk   : STD_LOGIC := '0';
  SIGNAL rst_n : STD_LOGIC := '0';

  SIGNAL dut_v_sync_out  : STD_LOGIC;
  SIGNAL dut_h_sync_out  : STD_LOGIC;
  SIGNAL dut_r_colr_out  : STD_LOGIC_VECTOR(depth_colr_c-1 DOWNTO 0);
  SIGNAL dut_g_colr_out  : STD_LOGIC_VECTOR(depth_colr_c-1 DOWNTO 0);
  SIGNAL dut_b_colr_out  : STD_LOGIC_VECTOR(depth_colr_c-1 DOWNTO 0);

BEGIN 

  i_DUT : vga_top
    GENERIC MAP (
      CONF_SIM       => CONF_SIM, 
      CONF_TEST_PATT => CONF_TEST_PATT      
    )
    PORT MAP (
      clk         => clk,
      rst_n       => rst_n,

      v_sync_out  => dut_v_sync_out,
      h_sync_out  => dut_h_sync_out,
      r_colr_out  => dut_r_colr_out,
      g_colr_out  => dut_g_colr_out,
      b_colr_out  => dut_b_colr_out
    );

  rst_n <= '1' AFTER (4 * ref_clk_perd_g); -- de-assert reset after 4 cycles 

  clk_gen : PROCESS IS 
  BEGIN
  
    WHILE NOW < max_sim_time_g LOOP 
      clk <= NOT clk;
      WAIT FOR ref_clk_perd_g / 2;
    END LOOP;

    ASSERT now < max_sim_time_g
      REPORT "SIMULATION COMPLETE!"
      SEVERITY FAILURE;

    FINISH;
  
  END PROCESS clk_gen;

END ARCHITECTURE tb;
