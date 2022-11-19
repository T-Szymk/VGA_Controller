-------------------------------------------------------------------------------
-- Title      : VGA Controller - Main Controller Testbench
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_controller_tb.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-08-22
-- Design     : vga_controller_tb
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Testbench for main controller
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-08-28  1.0      TZS     Created
-- 2021-12-11  1.1      TZS     Modified to use external counter modul
-- 2022-07-19  1.2      TZS     Updated signal names to match latest DUT
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE STD.ENV.FINISH;
USE WORK.VGA_PKG.ALL;

ENTITY vga_controller_tb IS 
  GENERIC (
    disp_freq_g        : INTEGER := 60;
    clk_period_g       : TIME    := 40 ns; -- 25MHz
    frame_time_g       : TIME    := 16.8 ms;
    v_sync_time_g      : TIME    := 64 us;
    h_sync_time_g      : TIME    := 3.84 us;
    h_sync_int_time_g  : TIME    := 32 us;
    display_time_g     : TIME    := 25.6 us;
    h_fp_time_g        : TIME    := 0.64 us;
    h_bp_time_g        : TIME    := 1.92 us;
    v_fp_time_g        : TIME    := 320 us;
    v_bp_time_g        : TIME    := 1.056 ms;
    disp_v_syn_time_g  : TIME    := display_time_g + h_fp_time_g + v_fp_time_g; 
    v_syn_disp_time_g  : TIME    := v_sync_time_g  + v_bp_time_g + 
                                    h_sync_time_g + h_bp_time_g  
    );
END ENTITY vga_controller_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb OF vga_controller_tb IS ----------------------------------------
  
  -- COMPONENTS ----------------------------------------------------------------

  COMPONENT vga_pxl_counter
    PORT (
      clk_i      : IN STD_LOGIC;
      rstn_i     : IN STD_LOGIC;
      
      pxl_ctr_o  : OUT STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
      line_ctr_o : OUT STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0)
    );
  END COMPONENT;  

  COMPONENT vga_controller IS -- DUT
    PORT (
      clk_i      : IN STD_LOGIC;
      rstn_i     : IN STD_LOGIC;
      pxl_ctr_i  : IN STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
      line_ctr_i : IN STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0);

      blank_pxln_o : OUT STD_LOGIC;
      v_sync_o     : OUT STD_LOGIC;
      h_sync_o     : OUT STD_LOGIC
    );
  END COMPONENT; 

  ------------------------------------------------------------------------------
  
  -- SUBROUTINES----------------------------------------------------------------
  
  FUNCTION rising_edge_detect(                                              ----
    curr_val : STD_LOGIC;
    prev_val : STD_LOGIC
  ) RETURN STD_LOGIC IS

  BEGIN

    IF curr_val = '1' AND prev_val = '0' THEN
      RETURN '1';
    ELSE 
      RETURN '0';
    END IF;

  END rising_edge_detect;                                                   ----

  FUNCTION falling_edge_detect(                                             ----
    curr_val : STD_LOGIC;
    prev_val : STD_LOGIC
  ) RETURN STD_LOGIC IS

  BEGIN

    IF curr_val = '0' AND prev_val = '1' THEN
      RETURN '1';
    ELSE 
      RETURN '0';
    END IF;

  END falling_edge_detect;                                                  ----

  FUNCTION reduce_OR(                                                       ----
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

  END reduce_OR;                                                           ----- 

  FUNCTION reduce_AND(                                                     -----
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

  END reduce_AND;                                                           ----

  PROCEDURE assert_time(                                                    ----
    timer     : TIME;
    comp_time : TIME;
    message   : STRING
  ) IS 
  BEGIN 
  
    ASSERT (NOW - timer) = comp_time
      REPORT "FAIL@ " & TO_STRING(NOW) &
      ", " & message & " time != " & TO_STRING(comp_time) & ", time: " & 
      TO_STRING(NOW - timer)
      SEVERITY WARNING;

  END assert_time;                                                          ----

  ------------------------------------------------------------------------------

  -- VARIABLES / CONSTANTS / TYPES ---------------------------------------------

  CONSTANT max_sim_time_c : TIME := 1.5 SEC;

  SIGNAL clk, rst_n      : STD_LOGIC := '0';
  
  SIGNAL h_sync_o_dut_old  : STD_LOGIC := '1';
  SIGNAL v_sync_o_dut_old  : STD_LOGIC := '1';
  SIGNAL colr_en_o_dut_old : STD_LOGIC := '0';

  SIGNAL h_sync_o_dut      : STD_LOGIC := '1';
  SIGNAL v_sync_o_dut      : STD_LOGIC := '1'; 
  SIGNAL colr_en_o_dut     : STD_LOGIC := '0';

  SIGNAL pxl_ctr_s  : STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
  SIGNAL line_ctr_s : STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0);

  SIGNAL frame_tmr_start       : TIME := 0 ms;
  SIGNAL v_sync_tmr_start      : TIME := 0 us;
  SIGNAL h_sync_tmr_start      : TIME := 0 us;
  SIGNAL h_sync_tmr_int_start  : TIME := 0 us;
  SIGNAL display_tmr_start     : TIME := 0 us;
  SIGNAL display_tmr_int_start : TIME := 0 us;
  SIGNAL v_syn_disp_tmr_start  : TIME := 0 us;
  SIGNAL v_syn_h_syn_tmr_start : TIME := 0 us;

  SIGNAL v_sync_timer_en_s, 
         h_sync_timer_en_s, 
         display_timer_en_s,
         v_syn_disp_timer_en_s,
         v_syn_h_syn_timer_en_s  : BIT := '0';

  ------------------------------------------------------------------------------

  BEGIN ------------------------------------------------------------------------

  i_vga_pxl_counter : vga_pxl_counter
    PORT MAP (
      clk_i      => clk,
      rstn_i     => rst_n,
      pxl_ctr_o  => pxl_ctr_s,
      line_ctr_o => line_ctr_s
    );

  i_DUT : vga_controller  
    PORT MAP (
      clk_i       => clk,
      rstn_i      => rst_n,
      pxl_ctr_i   => pxl_ctr_s,  
      line_ctr_i  => line_ctr_s,

      blank_pxln_o => colr_en_o_dut,        
      v_sync_o     => v_sync_o_dut,       
      h_sync_o     => h_sync_o_dut       
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
      SEVERITY NOTE;

    FINISH;

  END PROCESS clk_gen; ---------------------------------------------------------

  sync_edge_detect : PROCESS (clk, rst_n) IS -----------------------------------
  BEGIN

    IF rst_n = '0' THEN

      h_sync_o_dut_old  <= '1';
      v_sync_o_dut_old  <= '1';
      colr_en_o_dut_old <= '0';

    ELSIF RISING_EDGE(clk) THEN
  
      h_sync_o_dut_old  <= h_sync_o_dut;
      v_sync_o_dut_old  <= v_sync_o_dut;
      colr_en_o_dut_old <= colr_en_o_dut;

    END IF;

  END PROCESS sync_edge_detect; ------------------------------------------------

  timing_check : PROCESS (clk, rst_n) IS ---------------------------------------

  BEGIN

    IF rst_n = '0' THEN

      frame_tmr_start        <= 0 SEC;
      v_sync_tmr_start       <= 0 SEC;
      h_sync_tmr_int_start   <= 0 SEC;
      h_sync_tmr_start       <= 0 SEC;
      h_sync_tmr_int_start   <= 0 SEC;
      h_sync_tmr_start       <= 0 SEC;
      v_syn_disp_tmr_start   <= 0 SEC;
      v_syn_h_syn_tmr_start  <= 0 SEC;
      
      v_sync_timer_en_s      <= '0';
      h_sync_timer_en_s      <= '0';
      h_sync_timer_en_s      <= '0';
      v_sync_timer_en_s      <= '0';
      display_timer_en_s     <= '0';
      v_syn_disp_timer_en_s  <= '0';
      v_syn_h_syn_timer_en_s <= '0';

    ELSIF RISING_EDGE(clk) THEN
  
      -- V_SYNC CHECK
      IF falling_edge_detect(v_sync_o_dut, v_sync_o_dut_old) = '1' THEN

        IF v_sync_timer_en_s = '1' THEN 

          -- measure the time between the start of consecutive v_sync pulses
          assert_time(frame_tmr_start, frame_time_g, "V_SYNC_INT");

        ELSE 
          -- use enable to ensure that timing check is not performed on very first pulse following reset
          v_sync_timer_en_s <= '1';

        END IF;

        IF display_timer_en_s = '1' THEN
          
          -- measure the time between the start of final display pulse in a frame and the start of the v_sync pulse
          assert_time(display_tmr_int_start, disp_v_syn_time_g, "DISPLAY");

          display_timer_en_s <= '0'; -- clear enable to ensure timing of display resets as it is the start of a new frame 

        END IF;

        v_syn_disp_timer_en_s  <= '1';
        v_syn_h_syn_timer_en_s <= '1';

        frame_tmr_start       <= NOW; -- start timer for time between v_sync pulses
        v_sync_tmr_start      <= NOW; -- start timer for time between v_sync falling/rising edges
        v_syn_disp_tmr_start  <= NOW; -- start timer for time between v_sync falling edge and display rising edge
        v_syn_h_syn_tmr_start <= NOW; -- start timer for time between v_sync falling edge and following h_sync falling edge

      END IF;
  
      IF rising_edge_detect(v_sync_o_dut, v_sync_o_dut_old) = '1' THEN
        
        -- measure the time between the start and end of v_sync pulse
        assert_time(v_sync_tmr_start, v_sync_time_g, "V_SYNC");
  
      END IF;

      -- H_SYNC CHECK
      IF falling_edge_detect(h_sync_o_dut, h_sync_o_dut_old) = '1' THEN

        IF h_sync_timer_en_s = '1' THEN 
          
          -- measure the time between the start of consecutive h_sync pulses
          assert_time(h_sync_tmr_int_start, h_sync_int_time_g, "H_SYNC_INT");

        ELSE 
          -- use enable to ensure that timing check is not performed on very first pulse following reset
          v_sync_timer_en_s <= '1';

        END IF;

        IF v_syn_h_syn_timer_en_s = '1' THEN 

          -- measure the time between the start of v_sync pulse and the following h_sync pulse
          assert_time(v_syn_h_syn_tmr_start, h_sync_int_time_g, "V_SYNC");

          v_syn_h_syn_timer_en_s <= '0';

        END IF;

        h_sync_tmr_int_start <= NOW; -- start timer for time between h_sync pulses
        h_sync_tmr_start     <= NOW; -- start timer for time between h_sync falling/rising edges

      END IF;
  
      IF rising_edge_detect(h_sync_o_dut, h_sync_o_dut_old) = '1' THEN
        
        -- measure the time between the start and end of h_sync pulse
        assert_time(h_sync_tmr_start, h_sync_time_g, "H_SYNC");
  
      END IF;
      
      -- DISPLAY CHECK
      IF rising_edge_detect(colr_en_o_dut, colr_en_o_dut_old) = '1' THEN

        IF display_timer_en_s = '1' THEN
        
          -- measure the time between the start of consecutive display pulses
          assert_time(display_tmr_int_start, h_sync_int_time_g, "DISPLAY_INT");
         
        ELSE 
          -- use enable to ensure that timing check is not performed on very first pulse following reset
          display_timer_en_s <= '1';
         
        END IF;

        IF v_syn_disp_timer_en_s = '1' THEN 

          -- measure the time between the start of the v_sync pulse and the start of the first display pulse
          assert_time(v_syn_disp_tmr_start, v_syn_disp_time_g, "V_SYNC -> DISPLAY");

          v_syn_disp_timer_en_s <= '0';

        END IF;

        display_tmr_int_start <= NOW; -- start timer for time between intra-frame display pulses 
                                      -- (also measures time between final display pulse of the 
                                      -- frame and the v_sync pulse of the following frame)
        display_tmr_start     <= NOW; -- start timer for time between display falling/rising edges

      END IF; 

      IF falling_edge_detect(colr_en_o_dut, colr_en_o_dut_old) = '1' THEN

        -- measure the time between the start and end of display pulse
        assert_time(display_tmr_start, display_time_g, "DISPLAY");

      END IF;

    END IF;

  END PROCESS timing_check; ----------------------------------------------------

END ARCHITECTURE tb;

--------------------------------------------------------------------------------
