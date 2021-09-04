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
-- 2021-09-04  1.2      TZS     Set mux to change all colour signals instead of
--                              individual colours separately.
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_colr_mux IS
  GENERIC (depth_colr_g : INTEGER := 4);
  PORT (
    colr_in : IN STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0);
    en_in   : IN STD_LOGIC;
  
    colr_out : OUT STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0)
  );
END ENTITY vga_colr_mux;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_colr_mux IS 
BEGIN 

  WITH en_in SELECT colr_out <= colr_in WHEN '1',
                                (OTHERS => '0') WHEN OTHERS;
  
END ARCHITECTURE rtl; 

--------------------------------------------------------------------------------
