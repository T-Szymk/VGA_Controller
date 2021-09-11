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

ENTITY vga_colr_gen_tb IS 
  GENERIC (
    frame_rate_g : INTEGER := 60
  );
END ENTITY vga_colr_gen_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb of vga_colr_gen_tb IS 
BEGIN 

END ARCHITECTURE tb;
--------------------------------------------------------------------------------