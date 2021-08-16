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
USE STD.ENV.FINISH;

ENTITY vga_controller_tb IS 
  GENERIC (
    width_g         : INTEGER := 640;
    height_g        : INTEGER := 480;
    h_sync_px_g     : INTEGER := 95;
    h_b_porch_px_g  : INTEGER := 48;
    h_f_porch_px_g  : INTEGER := 15;
    v_sync_lns_g    : INTEGER := 2;
    v_b_porch_lns_g : INTEGER := 33;
    v_f_porch_lns_g : INTEGER := 10;
    clk_period      : TIME    := 20 NS
  	);
END ENTITY vga_controller_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb OF vga_controller_tb IS ----------------------------------------
  
  -- COMPONENTS ----------------------------------------------------------------

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

  ------------------------------------------------------------------------------
  
  -- SUBROUTINES----------------------------------------------------------------
  
  FUNCTION rising_edge_detect(
    curr_val : STD_LOGIC;
    prev_val : STD_LOGIC
  ) RETURN STD_LOGIC IS

  BEGIN

    IF curr_val = '1' AND prev_val = '0' THEN
      RETURN '1';
    ELSE 
      RETURN '0';
    END IF;

  END;

  FUNCTION falling_edge_detect(
    curr_val : STD_LOGIC;
    prev_val : STD_LOGIC
  ) RETURN STD_LOGIC IS

  BEGIN

    IF curr_val = '0' AND prev_val = '1' THEN
      RETURN '1';
    ELSE 
      RETURN '0';
    END IF;

  END;

  ------------------------------------------------------------------------------

  -- VARIABLES / CONSTANTS / TYPES ---------------------------------------------

  CONSTANT max_sim_time_c : TIME := 1.2 SEC;
  CONSTANT pxl_cntr_max_c   : INTEGER := width_g  + h_sync_px_g  + h_b_porch_px_g  + h_f_porch_px_g - 1;
  CONSTANT ln_cntr_max_c  : INTEGER := height_g + v_sync_lns_g + v_b_porch_lns_g + v_f_porch_lns_g - 1;

  TYPE state_t IS (IDLE, 
                   V_SYNC, V_B_PORCH, 
                   H_SYNC, H_B_PORCH, 
                   DISPLAY,
  	               H_F_PORCH, V_F_PORCH);

  SIGNAL curr_state, next_state : state_t;

  SIGNAL clk, rst_n      : STD_LOGIC;
  
  SIGNAL pxl_cntr, ln_cntr   : INTEGER := 0;
  SIGNAL h_sync_out_dut_old  : STD_LOGIC;
  SIGNAL v_sync_out_dut_old  : STD_LOGIC;
  SIGNAL colr_en_out_dut_old : STD_LOGIC_VECTOR(3-1 DOWNTO 0);

  SIGNAL h_sync_out_dut  : STD_LOGIC;
  SIGNAL v_sync_out_dut  : STD_LOGIC; 
  SIGNAL colr_en_out_dut : STD_LOGIC_VECTOR(3-1 DOWNTO 0);

  ------------------------------------------------------------------------------

  BEGIN ------------------------------------------------------------------------

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

  clk_gen : PROCESS IS -- 50Hz clk generator -----------------------------------
  BEGIN

    WHILE NOW < max_sim_time_c LOOP
      clk <= NOT clk;
      WAIT FOR clk_period / 2;
    END LOOP;

    ASSERT now < max_sim_time_c
      REPORT "SIMULATION COMPLETE!"
      SEVERITY FAILURE;

    FINISH;

  END PROCESS clk_gen; ---------------------------------------------------------

  sync_cntrs : PROCESS (clk, rst_n) IS -----------------------------------------
  BEGIN
  
    IF rst_n = '0' THEN

      pxl_cntr <= 0;
      ln_cntr  <= 0;

    ELSIF RISING_EDGE(clk) THEN 

      IF pxl_cntr = pxl_cntr_max_c THEN

        pxl_cntr <= 0;
        -- increment the line counter
        IF ln_cntr = ln_cntr_max_c THEN

          ln_cntr <= 0;

        ELSE 

          ln_cntr  <= ln_cntr + 1;

        END IF;

      ELSE 

        pxl_cntr <= pxl_cntr + 1;

      END IF;
    END IF;

  END PROCESS sync_cntrs; ------------------------------------------------------

  sync_fsm : PROCESS (clk, rst_n) IS -------------------------------------------
  BEGIN

  IF rst_n = '0' THEN 

    curr_state <= IDLE;

  ELSIF RISING_EDGE(clk) THEN

    curr_state <= next_state;

  END IF;

  END PROCESS sync_fsm; --------------------------------------------------------

  sync_edge_detect : PROCESS (clk, rst_n) IS -----------------------------------
  BEGIN

    IF rst_n = '0' THEN

      h_sync_out_dut_old  <= '0';
      v_sync_out_dut_old  <= '0';
      colr_en_out_dut_old <= (OTHERS => '0');

    ELSIF RISING_EDGE(clk) THEN
  
      h_sync_out_dut_old  <= h_sync_out_dut;
      v_sync_out_dut_old  <= v_sync_out_dut;
      colr_en_out_dut_old <= colr_en_out_dut;

    END IF;

  END PROCESS sync_edge_detect; ------------------------------------------------

  next_state_comb : PROCESS (ALL) IS -------------------------------------------
  BEGIN

    CASE curr_state IS 

      WHEN IDLE =>

        next_state <= V_SYNC;

      WHEN V_SYNC =>

        IF pxl_cntr = pxl_cntr_max_c AND ln_cntr = 1 THEN
          next_state <= V_B_PORCH;
        END IF; 

      WHEN V_B_PORCH =>

        IF pxl_cntr = pxl_cntr_max_c AND ln_cntr = 34 THEN
          next_state <= H_SYNC;
        END IF; 

      WHEN H_SYNC =>

        IF pxl_cntr = 95 THEN
          next_state <= H_B_PORCH;
        END IF;

      WHEN H_B_PORCH =>

        IF pxl_cntr = 143 THEN
          next_state <= DISPLAY;
        END IF;

      WHEN DISPLAY =>

        IF pxl_cntr = 783 THEN
          next_state <= H_F_PORCH;
        END IF;

      WHEN H_F_PORCH =>
          
        IF pxl_cntr = pxl_cntr_max_c THEN
          IF ln_cntr = 515 THEN
            next_state <= V_F_PORCH;
          ELSE 
            next_state <= H_SYNC;
          END IF;
        END IF;

      WHEN V_F_PORCH =>

        IF pxl_cntr = pxl_cntr_max_c AND ln_cntr = 524 THEN
          next_state <= V_SYNC;
        END IF;

      WHEN OTHERS =>

        next_state <= IDLE;

    END CASE;

  END PROCESS next_state_comb; -------------------------------------------------

END ARCHITECTURE tb;
