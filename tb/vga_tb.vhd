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
-- 2022-05-27  1.4      TZS     Updated testbench to match latest top level
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;
use std.env.finish;

entity vga_tb is
  generic (
            ref_clk_perd_g : time    := 10 ns;
            max_sim_time_g : time    :=  3 sec;
            conf_sim       : integer :=  1;
            conf_test_patt : integer :=  1
  );
end entity vga_tb;

--------------------------------------------------------------------------------

architecture tb of vga_tb is 

  component vga_top is 
    generic (
      CONF_SIM       : integer := 1
    );
    port (
      -- clock and asynch reset
      clk_i  : in std_logic;
      rstn_i : in std_logic;
      -- io
      sw_0_i : in std_logic;
      -- VGA signals
      v_sync_out  : out std_logic;
      h_sync_out  : out std_logic;
      r_colr_out  : out std_logic_vector(depth_colr_c-1 downto 0);
      g_colr_out  : out std_logic_vector(depth_colr_c-1 downto 0);
      b_colr_out  : out std_logic_vector(depth_colr_c-1 downto 0)
    );
  end component;

  signal clk_s             : std_logic := '0';
  signal rstn_s           : std_logic := '0';
  signal sw_0_s          : std_logic := '0';
  signal dut_v_sync_out  : std_logic;
  signal dut_h_sync_out  : std_logic;
  signal dut_r_colr_out  : std_logic_vector(depth_colr_c-1 downto 0);
  signal dut_g_colr_out  : std_logic_vector(depth_colr_c-1 downto 0);
  signal dut_b_colr_out  : std_logic_vector(depth_colr_c-1 downto 0);

begin 

  i_dut : vga_top
    generic map (
      conf_sim       => conf_sim      
    )
    port map (
      clk_i       => clk_s,
      rstn_i      => rstn_s,
      sw_0_i      => sw_0_s,
      v_sync_out  => dut_v_sync_out,
      h_sync_out  => dut_h_sync_out,
      r_colr_out  => dut_r_colr_out,
      g_colr_out  => dut_g_colr_out,
      b_colr_out  => dut_b_colr_out
    );

  rstn_s <= '1' after (10 * ref_clk_perd_g); -- de-assert reset after 4 cycles 

  clk_gen : process is 
  begin
  
    while now < max_sim_time_g loop 
      clk_s <= '0';
      wait for ref_clk_perd_g / 2;
      clk_s <= '1';
      wait for ref_clk_perd_g / 2;
    end loop;

    assert now < max_sim_time_g
      report "Simulation Complete!"
      severity failure;

    finish;
  
  end process clk_gen;

end architecture tb;
