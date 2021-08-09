-------------------------------------------------------------------------------
-- Title      : VGA Controller - Main Controller Testbench
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_controller_tb.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-08-09
-- Design     : vga_controller_tb
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Testbench for main controller
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-08-09  1.0      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_controller_tb IS 
  GENERIC (
    width_g         : INTEGER := 640,
    height_g        : INTEGER := 480,
    h_sync_px_g     : INTEGER := 95,
    h_b_porch_px_g  : INTEGER := 48,
    h_f_porch_px_g  : INTEGER := 15,
    v_sync_lns_g    : INTEGER := 2,
    v_b_porch_lns_g : INTEGER := 33,
    v_f_porch_lns_g : INTEGER := 10
  	);
END ENTITY vga_controller_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb OF vga_controller_tb IS 

  COMPONENT vga_controller IS -- DUT
    GENERIC (
      width_g         : INTEGER;
      height_g        : INTEGER;
      h_sync_px_g     : INTEGER;
      h_b_porch_px_g  : INTEGER;
      h_f_porch_px_g  : INTEGER;
      v_sync_lns_g    : INTEGER;
      v_b_porch_lns_g : INTEGER;
      v_f_porch_lns_g : INTEGER
    );
    PORT (
      clk   : IN STD_LOGIC;
      rst_n : IN STD_LOGIC;

      colr_en_out : OUT STD_LOGIC_VECTOR(3-1 DOWNTO 0);
      v_sync_out  : OUT STD_LOGIC;
      h_sync_out  : OUT STD_LOGIC

    );
  END COMPONENT; 

  TYPE state_t IS (IDLE, V_SYNC, V_B_PORCH, H_SYNC, H_B_PORCH, DISPLAY,
  	               H_F_PORCH, V_F_PORCH);

  SIGNAL curr_state, next_state : state_t;

  SIGNAL clk, rst_n : STD_LOGIC;
  SIGNAL colr_en_out_dut : STD_LOGIC_VECTOR(3-1 DOWNTO 0);
  SIGNAL h_sync_out_dut  : STD_LOGIC;
  SIGNAL v_sync_out_dut  : STD_LOGIC; 

  BEGIN

  i_DUT : vga_controller  
    GENERIC MAP(
    	width_g         => width_g,   
        height_g        => height_g,    
        h_sync_px_g     => h_sync_px_g,       
        h_b_porch_px_g  => h_b_porch_px_g,          
        h_f_porch_px_g  => h_f_porch_px_g,          
        v_sync_lns_g    => v_sync_lns_g,        
        v_b_porch_lns_g => v_b_porch_lns_g,           
        v_f_porch_lns_g => v_f_porch_lns_g          
    )
    PORT MAP (
      clk         => clk,
      rst_n       => rst_n,  
      colr_en_out => colr_en_out_dut,        
      v_sync_out  => v_sync_out_dut,       
      h_sync_out  => h_sync_out_dut       
    );


END ARCHITECTURE tb;
