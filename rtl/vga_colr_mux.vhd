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
--              TODO: Make colour width generic
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-26  1.0      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_colr_mux IS
  PORT (
    r_colr_in : IN STD_LOGIC_VECTOR(10-1 DOWNTO 0);
    g_colr_in : IN STD_LOGIC_VECTOR(10-1 DOWNTO 0);
    b_colr_in : IN STD_LOGIC_VECTOR(10-1 DOWNTO 0);
    r_en_in   : IN STD_LOGIC;
    g_en_in   : IN STD_LOGIC;
    b_en_in   : IN STD_LOGIC;
  
    r_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
    g_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
    b_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0)
  );
END ENTITY vga_colr_mux;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_colr_mux IS 
BEGIN 
  
  -- TODO: Use generate to make this a single statement
  WITH r_en_in SELECT r_colr_out <=
    r_colr_in WHEN '1',
    (OTHERS => '0') WHEN OTHERS;

  WITH g_en_in SELECT g_colr_out <=
    g_colr_in WHEN '1',
    (OTHERS => '0') WHEN OTHERS;

  WITH b_en_in SELECT b_colr_out <=
    b_colr_in WHEN '1',
    (OTHERS => '0') WHEN OTHERS;

END ARCHITECTURE rtl; 

--------------------------------------------------------------------------------