-------------------------------------------------------------------------------
-- Title      : VGA Controller Colour Mux
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_colr_mux.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-06-26
-- Design     : vga_colr_mux
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Block to control multiplexing of colour signals for VGA 
--              controller.
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-26  1.0      TZS     Created
-- 2021-07-24  1.1      TZS     Modified inputs and outputs to use single signal
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_colr_mux IS
  GENERIC (depth_colr_g : INTEGER := 4);
  PORT (
    colr_in : IN STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0);
    en_in   : IN STD_LOGIC_VECTOR(3-1 DOWNTO 0);
  
    colr_out : OUT STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0)
  );
END ENTITY vga_colr_mux;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_colr_mux IS 
BEGIN 

  mux_gen : FOR idx IN 3-1 DOWNTO 0 GENERATE

    WITH en_in(idx) SELECT colr_out( ((idx+1) * depth_colr_g)-1 DOWNTO (idx * depth_colr_g) ) <=
    colr_in(((idx+1) * depth_colr_g)-1 DOWNTO (idx * depth_colr_g)) WHEN '1',
    (OTHERS => '0') WHEN OTHERS;

  END GENERATE; 
  
END ARCHITECTURE rtl; 

--------------------------------------------------------------------------------
