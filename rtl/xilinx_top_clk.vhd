-------------------------------------------------------------------------------
-- Title      : Xilinx MMCM Component Wrapper
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : xilinx_top_clk.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-09-06
-- Design     : clk_gen
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Wrapper to contain instantiation of MMCM IP generated within 
--              Vivado.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-09-06  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity clk_gen is 
  port (
    clk_i        : in  std_logic;
    rstn_i       : in  std_logic;

    clk_px_out : out std_logic
  );
end entity clk_gen;

--------------------------------------------------------------------------------

architecture structural of clk_gen is

component clk_wiz_0
port
 (
  clk_out1 : out std_logic;
  -- status and control signals
  resetn   : in  std_logic;
  clk_in1  : in  std_logic
 );
end component;

begin --------------------------------------------------------------------------

i_clk_wiz_0 : clk_wiz_0
   port map ( 
  -- clock out ports  
   clk_out1 => clk_px_out,
  -- status and control signals                
   resetn => rstn_i,
   -- clock in ports
   clk_in1 => clk_i
 );

end architecture structural;

--------------------------------------------------------------------------------