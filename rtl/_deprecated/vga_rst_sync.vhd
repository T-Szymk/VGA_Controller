-------------------------------------------------------------------------------
-- Title      : VGA Controller Reset Synchroniser
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_rst_sync.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-06-26
-- Design     : vga_rst_sync
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Synchroniser for async reset of VGA controller
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-26  1.0      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_rst_sync IS 
  PORT (
         clk       : IN STD_LOGIC;
         rst_n_in  : IN STD_LOGIC;

         rst_n_out : OUT STD_LOGIC
  );
END ENTITY vga_rst_sync;

--------------------------------------------------------------------------------

ARCHITECTURE rtl of vga_rst_sync IS 

  SIGNAL rst_ff1 : STD_LOGIC;
  SIGNAL rst_ff2 : STD_LOGIC;
  SIGNAL rst_ff3 : STD_LOGIC := '0'; 

BEGIN 
  
  --TODO: Look at design of reset synchronisers and apply here
  
  --rst_sync : PROCESS (clk) IS 
  --BEGIN 
  --
  --  IF RISING_EDGE(clk) THEN 
  --  
  --    rst_ff1   <= rst_n_in;
  --    rst_ff2   <= rst_ff1;
  --    rst_ff3   <= rst_ff2;
  --    rst_n_out <= rst_ff3;
  --  
  --  END IF;
  --
  --END PROCESS rst_sync;

  rst_n_out <= rst_n_in;

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------