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
    h_f_porch_px_g  : INTEGER := 16;
    v_sync_lns_g    : INTEGER := 2;
    v_b_porch_lns_g : INTEGER := 33;
    v_f_porch_lns_g : INTEGER := 10;
    disp_freq_g     : INTEGER := 60;
    clk_period_g    : TIME    := 40 ns; -- 25MHz
    v_sync_time_g   : TIME    := 64 us;
    vb_porch_time_g : TIME    := 1.056 ms;
    h_sync_time_g   : TIME    := 3.84 us;
    hb_porch_time_g : TIME    := 1.92 us;
    display_time_g  : TIME    := 25.6 us;
    vf_porch_time_g : TIME    := 320.64 us; -- combined vf and hf porch
    hf_porch_time_g : TIME    := 0.64 us
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

  SIGNAL clk, rst_n      : STD_LOGIC := '0';
  
  SIGNAL h_sync_out_dut_old  : STD_LOGIC;
  SIGNAL v_sync_out_dut_old  : STD_LOGIC;
  SIGNAL colr_en_out_dut_old : STD_LOGIC_VECTOR(3-1 DOWNTO 0);

  SIGNAL h_sync_out_dut  : STD_LOGIC;
  SIGNAL v_sync_out_dut  : STD_LOGIC; 
  SIGNAL colr_en_out_dut : STD_LOGIC_VECTOR(3-1 DOWNTO 0);

  SIGNAL frame_tmr_start    : TIME := 0 ms;
  SIGNAL v_sync_tmr_start   : TIME := 0 us;
  SIGNAL vb_porch_tmr_start : TIME := 0 ms;
  SIGNAL h_sync_tmr_start   : TIME := 0 us;
  SIGNAL hb_porch_tmr_start : TIME := 0 us;
  SIGNAL display_tmr_start  : TIME := 0 us;
  SIGNAL f_porch_tmr_start  : TIME := 0 us;

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

  -- RESET ---------------------------------------------------------------------

  rst_n <= '1' AFTER 2 * clk_period_g;

  clk_gen : PROCESS IS -- 50Hz clk generator -----------------------------------
  BEGIN

    WHILE NOW < max_sim_time_c LOOP
      clk <= NOT clk;
      WAIT FOR clk_period_g / 2;
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

        IF rst_n = '1' THEN 
          
          v_sync_tmr_start <= NOW; -- start v_sync timer
          frame_tmr_start  <= NOW; -- start frame timer

        END IF;

      WHEN V_SYNC =>

        IF rising_edge_detect(v_sync_out_dut, v_sync_out_dut_old) = '1' THEN
          
          next_state <= V_B_PORCH;

          ASSERT (NOW - v_sync_tmr_start) = v_sync_time_g
            REPORT "FAIL@ " & TO_STRING(NOW) & ": In state '" & TO_STRING(curr_state) & 
            "', V_SYNC time != " & TO_STRING(v_sync_time_g) & ", time: " & 
            TO_STRING(NOW - v_sync_tmr_start)
            SEVERITY WARNING;

          vb_porch_tmr_start <= NOW; -- start v_b_porch timer    

        END IF;    

      WHEN V_B_PORCH =>    ----------------

        IF falling_edge_detect(h_sync_out_dut, h_sync_out_dut_old) = '1' THEN

          next_state <= H_SYNC;
          
          ASSERT (NOW - vb_porch_tmr_start) = vb_porch_time_g -- stop v_b_porch timer and assert time 1.048 ms
            REPORT "FAIL@ " & TO_STRING(NOW) & ": In state '" & TO_STRING(curr_state) & 
            "', V_B_PORCH time != " & TO_STRING(vb_porch_time_g) & ", time: " & 
            TO_STRING(NOW - vb_porch_tmr_start)
            SEVERITY WARNING;

          h_sync_tmr_start <= NOW;

        END IF;

      WHEN H_SYNC =>    ----------------

        IF rising_edge_detect(h_sync_out_dut, h_sync_out_dut_old) = '1' THEN

          next_state <= H_B_PORCH;

          ASSERT (NOW - h_sync_tmr_start) = h_sync_time_g -- stop h_sync timer and assert time 3.84 us
            REPORT "FAIL@ " & TO_STRING(NOW) & ": In state '" & TO_STRING(curr_state) & 
            "', H_SYNC time != " & TO_STRING(h_sync_time_g) & ", time: " & 
            TO_STRING(NOW - h_sync_tmr_start)
            SEVERITY WARNING;

          hb_porch_tmr_start <= NOW;

        END IF;

      WHEN H_B_PORCH =>    ----------------

        IF rising_edge_detect(h_sync_out_dut, h_sync_out_dut_old) = '1' THEN

          next_state <= H_B_PORCH;

          ASSERT (NOW - hb_porch_tmr_start) = hb_porch_time_g -- stop h_b_porch timer and assert time 1.92 us
            REPORT "FAIL@ " & TO_STRING(NOW) & ": In state '" & TO_STRING(curr_state) & 
            "', H_B_PORCH time != " & TO_STRING(hb_porch_time_g) & ", time: " & 
            TO_STRING(NOW - hb_porch_tmr_start)
            SEVERITY WARNING;

          display_tmr_start <= NOW;

        END IF;

      WHEN DISPLAY =>    ----------------

        IF falling_edge_detect(colr_en_out_dut(0), colr_en_out_dut_old(0)) THEN

          next_state <= F_PORCH;

          ASSERT (NOW - display_tmr_start) = display_time_g -- stop display timer and assert time 25.6 us
            REPORT "FAIL@ " & TO_STRING(NOW) & ": In state '" & TO_STRING(curr_state) & 
            "', DISPLAY time != " & TO_STRING(display_time_g) & ", time: " & 
            TO_STRING(NOW - display_tmr_start)
            SEVERITY WARNING;

          f_porch_tmr_start <= NOW;

        END IF;

      WHEN F_PORCH => -- this could be the horizontal or vertical front porch

        IF falling_edge_detect(h_sync_out_dut, h_sync_out_dut_old) = '1' THEN

          next_state <= H_SYNC;

         ASSERT (NOW - f_porch_tmr_start) = hf_porch_time_g -- stop display timer and assert time 0.64 us
            REPORT "FAIL@ " & TO_STRING(NOW) & ": In state '" & TO_STRING(curr_state) & 
            "', H_F_PORCH time != " & TO_STRING(hf_porch_time_g) & ", time: " & 
            TO_STRING(NOW - f_porch_tmr_start)
            SEVERITY WARNING;

          h_sync_tmr_start <= NOW;

        ELSIF falling_edge_detect(v_sync_out_dut, v_sync_out_dut_old) = '1' THEN

          next_state <= V_SYNC;

         ASSERT (NOW - f_porch_tmr_start) = vf_porch_time_g -- stop display timer and assert time 320.64 us
            REPORT "FAIL@ " & TO_STRING(NOW) & ": In state '" & TO_STRING(curr_state) & 
            "', V_F_PORCH + H_F_PORCH time != " & TO_STRING(vf_porch_time_g) & ", time: " & 
            TO_STRING(NOW - f_porch_tmr_start)
            SEVERITY WARNING;

          v_sync_tmr_start <= NOW;

        END IF;

      WHEN OTHERS =>    ----------------

        next_state <= IDLE;

    END CASE;
  END PROCESS tb_next_state; ---------------------------------------------------

END ARCHITECTURE tb;
