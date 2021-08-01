-------------------------------------------------------------------------------
-- Title      : VGA Controller Switch Synchroniser
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_sw_sync.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-06-24
-- Design     : vga_sw_sync
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Synchroniser to be used with asynchronous switch inputs to 
--              control colour values sent over VGA
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-24  1.0      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_sw_sync IS 
  PORT (
         clk     : IN STD_LOGIC;
         rst_n   : IN STD_LOGIC; 
         sw_in   : IN STD_LOGIC;
         colr_in : IN STD_LOGIC_VECTOR(10-1 DOWNTO 0);

         colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0)
       );
END ENTITY vga_sw_sync;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_sw_sync IS 

  SIGNAL sw_ff1_r    : STD_LOGIC;
  SIGNAL sw_ff2_r    : STD_LOGIC;
  SIGNAL sw_ff3_r    : STD_LOGIC;

BEGIN 
  -- 3 FF synchroniser
  sync_synch : PROCESS(clk, rst_n) IS

  BEGIN

    IF rst_n = '0' THEN 

      sw_ff1_r <= '0';
      sw_ff2_r <= '0';
      sw_ff3_r <= '0';

    ELSIF RISING_EDGE(clk) THEN 

      sw_ff1_r <= sw_in;
      sw_ff2_r <= sw_ff1_r;
      sw_ff3_r <= sw_ff2_r;

    END IF;

  END PROCESS sync_synch;
  -- use synchronised control signal to drive mux
  colr_out <= colr_in WHEN (sw_ff3_r = '1') ELSE (OTHERS => '0'); 

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------