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
-- 2022-06-27  1.3      TZS     Updated types to use pixels
-- 2022-07-02  1.4      TZS     Fixed missing output assignment
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.vga_pkg.all;

entity vga_colr_mux is
  port (
    test_colr_i : in  pixel_t;
    mem_colr_i  : in  pixel_t;
    en_i        : in  std_logic;
    blank_i     : in  std_logic;
    colr_out    : out pixel_t
  );
end entity vga_colr_mux;

--------------------------------------------------------------------------------

architecture rtl of vga_colr_mux is 

  signal pxl_s     : pixel_t;
  signal int_pxl_s : pixel_t;

begin 

  with en_i select int_pxl_s <= test_colr_i  when '0',
                                mem_colr_i   when others;

  with blank_i select pxl_s <= int_pxl_s       when '0',
                               (others => '0') when others;
                               
  colr_out <= pxl_s;
  
end architecture rtl;

--------------------------------------------------------------------------------
