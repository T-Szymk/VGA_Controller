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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY clk_gen IS 
  PORT (
    clk        : IN  STD_LOGIC;
    rst_n      : IN  STD_LOGIC;

    clk_px_out : OUT STD_LOGIC
  );
END ENTITY clk_gen;

--------------------------------------------------------------------------------

ARCHITECTURE structural OF clk_gen IS

COMPONENT clk_wiz_0
PORT
 (
  clk_out1 : OUT STD_LOGIC;
  -- Status and control signals
  resetn   : IN  STD_LOGIC;
  clk_in1  : IN  STD_LOGIC
 );
END COMPONENT;

BEGIN --------------------------------------------------------------------------

i_clk_wiz_0 : clk_wiz_0
   port map ( 
  -- Clock out ports  
   clk_out1 => clk_px_out,
  -- Status and control signals                
   resetn => rst_n,
   -- Clock in ports
   clk_in1 => clk
 );

END ARCHITECTURE structural;

--------------------------------------------------------------------------------