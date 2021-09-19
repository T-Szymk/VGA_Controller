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
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE STD.ENV.FINISH;

ENTITY vga_tb IS
  GENERIC (
            ref_clk_perd_g : TIME    := 10 ns;
            max_sim_time_g : TIME    :=  3 sec;
            CONF_SIM       : BIT     := '1';
            CONF_PATT_GEN  : BIT     := '1';
            ref_clk_freq_g : INTEGER := 100_000_000; -- input osc. on arty-a7
            px_clk_freq_g  : INTEGER :=  25_000_000;
            height_px_g    : INTEGER :=         480;
            width_px_g     : INTEGER :=         680;
            depth_colr_g   : INTEGER :=           4
  );
END ENTITY vga_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb OF vga_tb IS 

  COMPONENT vga_top IS 
    GENERIC (
              CONF_SIM       : BIT     := '1';
              CONF_PATT_GEN  : BIT     := '1';
              ref_clk_freq_g : INTEGER := 100_000_000;
              px_clk_freq_g  : INTEGER := 25_000_000;
              height_px_g    : INTEGER := 480;
              width_px_g     : INTEGER := 680;
              depth_colr_g   : INTEGER := 4

            );
    
    PORT (
           clk    : IN STD_LOGIC;
           rst_n  : IN STD_LOGIC;
           sw_in  : IN STD_LOGIC_VECTOR(3-1 DOWNTO 0); 

           v_sync_out  : OUT STD_LOGIC;
           h_sync_out  : OUT STD_LOGIC;
           clk_px_out  : OUT STD_LOGIC;
           r_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
           g_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
           b_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0)
         );
  END COMPONENT;

  SIGNAL clk   : STD_LOGIC := '0';
  SIGNAL rst_n : STD_LOGIC := '0';

  SIGNAL dut_sw_in       : STD_LOGIC_VECTOR(3-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL dut_v_sync_out  : STD_LOGIC;
  SIGNAL dut_h_sync_out  : STD_LOGIC;
  SIGNAL dut_clk_px_out  : STD_LOGIC;
  SIGNAL dut_r_colr_out  : STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
  SIGNAL dut_g_colr_out  : STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
  SIGNAL dut_b_colr_out  : STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);

BEGIN 

  i_DUT : vga_top
    GENERIC MAP (
      CONF_SIM       => CONF_SIM, 
      CONF_PATT_GEN  => CONF_PATT_GEN,  
      ref_clk_freq_g => ref_clk_freq_g,         
      px_clk_freq_g  => px_clk_freq_g,      
      height_px_g    => height_px_g,     
      width_px_g     => width_px_g,    
      depth_colr_g   => depth_colr_g      
    )
    PORT MAP (
      clk         => clk,
      rst_n       => rst_n,
      sw_in       => dut_sw_in,

      v_sync_out  => dut_v_sync_out,
      h_sync_out  => dut_h_sync_out,
      clk_px_out  => dut_clk_px_out,
      r_colr_out  => dut_r_colr_out,
      g_colr_out  => dut_g_colr_out,
      b_colr_out  => dut_b_colr_out
    );

  rst_n <= '1' AFTER (4 * ref_clk_perd_g); -- de-assert reset after 4 cycles 
  
  dut_sw_in <= (OTHERS => '1') AFTER 1.5 sec;

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
