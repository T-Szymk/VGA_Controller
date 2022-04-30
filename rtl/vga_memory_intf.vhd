-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_memory_intf.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-04-26
-- Design     : vga_memory_intf
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to contain logic related to reading image data from BRAM
--              and returning it for use by the VGA controller
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-03-25  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use work.vga_pkg.all;

ENTITY vga_memory_intf IS 
  PORT (
    clk_i : in std_logic;
    rst_n : in std_logic
  );
END ENTITY vga_memory_intf;

--------------------------------------------------------------------------------
ARCHITECTURE rtl OF vga_memory_intf IS 
BEGIN

  process (clk_i, rst_n) is 
  begin 
  end process;

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------