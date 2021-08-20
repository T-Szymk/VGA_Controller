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
    h_sync_px_g     : INTEGER := 96;
    h_b_porch_px_g  : INTEGER := 48;
    h_f_porch_px_g  : INTEGER := 15;
    v_sync_lns_g    : INTEGER := 2;
    v_b_porch_lns_g : INTEGER := 33;
    v_f_porch_lns_g : INTEGER := 10;
    disp_freq_g     : INTEGER := 60;
    clk_period      : TIME    := 40 NS -- 25MHz
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

  END rising_edge_detect;

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

  END falling_edge_detect;

  FUNCTION reduce_OR( 
    vec : STD_LOGIC_VECTOR 
  ) RETURN STD_ULOGIC IS 

    VARIABLE result : STD_ULOGIC;
  
  BEGIN
  
    FOR idx IN vec'RANGE LOOP
      
      IF idx = vec'LEFT THEN
        result := vec(idx);
      ELSE 
        result := result OR vec(idx);
      END IF;

      EXIT WHEN result = '1';

    END LOOP;
    
    RETURN result;

  END reduce_OR;

  FUNCTION reduce_AND( 
    vec : STD_LOGIC_VECTOR 
  ) RETURN STD_ULOGIC IS

    VARIABLE result : STD_ULOGIC := '1';

  BEGIN
  
    FOR idx IN vec'RANGE LOOP 
      
      IF idx = vec'LEFT THEN
        result := vec(idx);
      ELSE 
        result := result AND vec(idx);
      END IF;

      EXIT WHEN result = '0';

    END LOOP;

    RETURN result;

  END reduce_AND;

  ------------------------------------------------------------------------------

  -- VARIABLES / CONSTANTS / TYPES ---------------------------------------------

  CONSTANT max_sim_time_c : TIME := 1.2 SEC;
  CONSTANT frame_time_c   : TIME := (1 SEC) / disp_freq_g;
  
  TYPE state_t IS (IDLE, 
                   V_SYNC, V_B_PORCH, 
                   H_SYNC, H_B_PORCH, 
                   DISPLAY,
  	               F_PORCH);

  SIGNAL curr_state, next_state : state_t;

  SIGNAL clk, rst_n      : STD_LOGIC;
  
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

  sync_fsm : PROCESS (clk, rst_n) IS -------------------------------------------
  BEGIN

  IF rst_n = '0' THEN 

    curr_state <= IDLE;

  ELSIF RISING_EDGE(clk) THEN

    curr_state <= next_state;

  END IF;

  END PROCESS sync_fsm; --------------------------------------------------------

  tb_next_state : PROCESS (ALL) IS ---------------------------------------------
  BEGIN

    CASE curr_state IS

      WHEN IDLE =>    ----------------
        
        next_state <= V_SYNC;
        -- start v_sync timer
        -- start frame timer

      WHEN V_SYNC =>

        -- assert v_sync is low
        -- assert h_sync is high
        -- assert reduce_OR of colr_en_out_dut is 0

        IF rising_edge_detect(v_sync_out_dut, v_sync_out_dut_old) = '1' THEN
          next_state <= V_B_PORCH;
          -- stop v_sync timer and assert time 0.064 ms
          -- start v_b_porch timer
        END IF;

      WHEN V_B_PORCH =>    ----------------

        -- assert v_sync is high
        -- assert h_sync is high
        -- assert reduce_OR of colr_en_out_dut is 0

        IF falling_edge_detect(h_sync_out_dut, h_sync_out_dut_old) = '1' THEN
          next_state <= H_SYNC;
          -- stop v_b_porch timer and assert time 1.048 ms
          -- start h_sync timer
        END IF;

      WHEN H_SYNC =>    ----------------

        -- assert h_sync is low
        -- assert v_sync is high
        -- assert reduce_OR of colr_en_out_dut is 0

        IF rising_edge_detect(h_sync_out_dut, h_sync_out_dut_old) = '1' THEN
          next_state <= H_B_PORCH;
          -- stop v_b_porch timer and assert time 3.813 us
          -- start h_b_porch timer 
        END IF;

      WHEN H_B_PORCH =>    ----------------

        -- assert h_sync is high
        -- assert v_sync is high
        -- assert reduce_OR of colr_en_out_dut is 0

        IF rising_edge_detect(colr_en_out_dut(0), colr_en_out_dut_old(0)) = '1' THEN
          next_state <= DISPLAY;
          -- stop h_b_porch timer and assert time 1.907 us
          -- start display timer
        END IF;

      WHEN DISPLAY =>    ----------------

        -- assert h_sync is high
        -- assert v_sync is high
        -- assert that reduce_AND of colr_en_out_dut is 1

        IF falling_edge_detect(colr_en_out_dut(0), colr_en_out_dut_old(0)) THEN
          next_state <= F_PORCH;
          -- stop display timer and assert time 25.422 us
        END IF;

      WHEN F_PORCH => -- this could be the horizontal or vertical front porch

        -- assert h_sync is high
        -- assert v_sync is high
        -- assert reduce_OR of colr_en_out_dut is 0

        IF falling_edge_detect(h_sync_out_dut, h_sync_out_dut_old) = '1' THEN
          next_state <= H_SYNC;
          -- start h_sync timer
        ELSIF falling_edge_detect(v_sync_out_dut, v_sync_out_dut_old) = '1' THEN
          next_state <= V_SYNC;
          -- stop frame timer and assert time 16.67 ms (60Hz)
          -- start v_sync timer
          -- start frame timer
        END IF;

      WHEN OTHERS =>    ----------------

        next_state <= IDLE;

    END CASE;
  END PROCESS tb_next_state; ---------------------------------------------------

END ARCHITECTURE tb;
