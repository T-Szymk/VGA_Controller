-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_mem_buff.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-24
-- Design     : vga_mem_buff
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to contain ping-pong buffers and logic to control display
--              datapath between the memory and the VGA controller.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-24  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use work.vga_pkg.all;


ENTITY vga_mem_buff IS 
  PORT (
    clk_i : in std_logic;
    rstn_i : in std_logic
  );
END ENTITY vga_mem_buff;

--------------------------------------------------------------------------------
ARCHITECTURE rtl OF vga_mem_buff IS 
BEGIN

  process (clk_i, rst_n) is 
  begin 
  end process;

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------