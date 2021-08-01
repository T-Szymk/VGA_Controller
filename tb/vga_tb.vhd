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
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE STD.ENV.FINISH;

ENTITY vga_tb IS
  GENERIC (
    ref_clk_freq_g   : INTEGER := 50_000_000;
    ref_clk_period_g : TIME := 20 NS;
    max_sim_time_g   : TIME := 1.2 SEC -- 1 frame is 16.67ms ~ 60Hz
  );
END ENTITY vga_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb OF vga_tb IS 

  COMPONENT vga_top IS 
    GENERIC (
              ref_clk_freq_g : INTEGER;
              px_clk_freq_g  : INTEGER;
              height_px_g    : INTEGER;
              width_px_g     : INTEGER
            );
    
    PORT (
           clk    : IN STD_LOGIC;
           rst_n  : IN STD_LOGIC;
           sw_in  : IN STD_LOGIC_VECTOR(3-1 DOWNTO 0); 
           
           sync_n_out  : OUT STD_LOGIC;
           blank_n_out : OUT STD_LOGIC;
           v_sync_out  : OUT STD_LOGIC;
           h_sync_out  : OUT STD_LOGIC;
           clk_px_out  : OUT STD_LOGIC;
           r_colr_out  : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
           g_colr_out  : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
           b_colr_out  : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0)
         );
  END COMPONENT;

  SIGNAL clk   : STD_LOGIC := '0';
  SIGNAL rst_n : STD_LOGIC := '0';

  SIGNAL dut_sw_in       : STD_LOGIC_VECTOR(3-1 DOWNTO 0);
  SIGNAL dut_sync_n_out  : STD_LOGIC;
  SIGNAL dut_blank_n_out : STD_LOGIC;
  SIGNAL dut_v_sync_out  : STD_LOGIC;
  SIGNAL dut_h_sync_out  : STD_LOGIC;
  SIGNAL dut_clk_px_out  : STD_LOGIC;
  SIGNAL dut_r_colr_out  : STD_LOGIC_VECTOR(10-1 DOWNTO 0);
  SIGNAL dut_g_colr_out  : STD_LOGIC_VECTOR(10-1 DOWNTO 0);
  SIGNAL dut_b_colr_out  : STD_LOGIC_VECTOR(10-1 DOWNTO 0);

  SIGNAL test_cntr      : INTEGER := 0;
  SIGNAL test_pxl_cntr  : INTEGER := 0;
  SIGNAL test_ln_cntr   : INTEGER := 0;
  SIGNAL test_fr_cntr   : INTEGER := 0;

  SIGNAL old_v_sync, old_h_sync : STD_LOGIC := '0';

BEGIN 

  i_DUT : vga_top
    GENERIC MAP (
      ref_clk_freq_g => ref_clk_freq_g,
      px_clk_freq_g  => 25_000_000,
      height_px_g    => 480,
      width_px_g     => 680 
    )
    PORT MAP (
      clk         => clk,
      rst_n       => rst_n,
      sw_in       => dut_sw_in,
      sync_n_out  => dut_sync_n_out,
      blank_n_out => dut_blank_n_out,
      v_sync_out  => dut_v_sync_out,
      h_sync_out  => dut_h_sync_out,
      clk_px_out  => dut_clk_px_out,
      r_colr_out  => dut_r_colr_out,
      g_colr_out  => dut_g_colr_out,
      b_colr_out  => dut_b_colr_out
    );

  rst_n <= '1' AFTER (4*ref_clk_period_g); -- de-assert reset after 4 cycles 

  clk_gen : PROCESS IS 
  BEGIN
  
    WHILE NOW < max_sim_time_g LOOP 
      clk <= NOT clk;
      WAIT FOR ref_clk_period_g / 2;
    END LOOP;

    ASSERT now < max_sim_time_g
      REPORT "SIMULATION COMPLETE!"
      SEVERITY FAILURE;

    FINISH;
  
  END PROCESS clk_gen;

  sync_tb : PROCESS (clk, rst_n) IS 
  BEGIN 

    IF rst_n = '0' THEN

      dut_sw_in <= (OTHERS => '0');

    ELSIF RISING_EDGE(clk) THEN 

      CASE (test_cntr) IS 
        WHEN 0 =>
          dut_sw_in(0) <= '1'; 
        WHEN 10 =>
          dut_sw_in(1) <= '1';
        WHEN 20 =>
          dut_sw_in(2) <= '1';
        WHEN OTHERS =>
          dut_sw_in <= dut_sw_in;
      END CASE;   
    END IF;
  END PROCESS sync_tb;

  cntrs : PROCESS (dut_clk_px_out, rst_n) IS -- generate counters used for test calcs
  BEGIN 

    IF rst_n = '0' THEN 

      test_cntr     <= 0;
      test_pxl_cntr <= 0;
      test_ln_cntr  <= 0;
      test_fr_cntr  <= 0;

      old_h_sync    <= '0';
      old_v_sync    <= '0';

    ELSIF RISING_EDGE(dut_clk_px_out) THEN 
      -- 'old' signals used to identify falling edges
      old_h_sync <= dut_h_sync_out;
      old_v_sync <= dut_v_sync_out;

      test_cntr <= test_cntr + 1;

      IF old_v_sync = '1' AND dut_v_sync_out = '0' THEN -- new frame

        test_fr_cntr  <= test_fr_cntr + 1;
        test_ln_cntr  <= 0;
        test_pxl_cntr <= 0;   

      ELSIF old_h_sync = '1' AND dut_h_sync_out = '0' THEN -- new line mid-frame

        test_pxl_cntr <= 0; 
        test_ln_cntr <= test_ln_cntr + 1;

      ELSE 

        test_pxl_cntr <= test_pxl_cntr + 1; -- new pixel mid-line

      END IF;
    END IF;
  END PROCESS cntrs; 

END ARCHITECTURE tb;