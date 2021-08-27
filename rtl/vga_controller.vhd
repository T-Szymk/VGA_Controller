-------------------------------------------------------------------------------
-- Title      : VGA Controller Main Controller
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_controller.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-06-24
-- Design     : vga_controller
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Controller to control blank_n, h_sync, v_sync
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-24  1.0      TZS     Created
-- 2021-06-26  1.1      TZS     Added enable signals,
--                              Removed blank control
-- 2021-08-26  1.2      TZS     Refactored to use a state machine
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_controller IS 
  GENERIC (
            width_px_g      : INTEGER := 640;
            height_lns_g    : INTEGER := 480;
            h_sync_px_g     : INTEGER := 96;
            h_b_porch_px_g  : INTEGER := 48;
            h_f_porch_px_g  : INTEGER := 16;
            v_sync_lns_g    : INTEGER := 2;
            v_b_porch_lns_g : INTEGER := 33;
            v_f_porch_lns_g : INTEGER := 10
  );
  PORT (
         clk   : IN STD_LOGIC;
         rst_n : IN STD_LOGIC;

         colr_en_out : OUT STD_LOGIC; -- (2, 1, 0) = (b_en, g_en, r_en),
         v_sync_out  : OUT STD_LOGIC;
         h_sync_out  : OUT STD_LOGIC
  );
END ENTITY vga_controller;

  -- VARIABLES / CONSTANTS / TYPES ---------------------------------------------

ARCHITECTURE rtl OF vga_controller IS 

  CONSTANT v_sync_max_lns_c    : INTEGER := v_sync_lns_g;
  CONSTANT v_b_porch_max_lns_c : INTEGER := v_sync_max_lns_c + v_b_porch_lns_g;
  CONSTANT v_disp_max_lns_c    : INTEGER := v_b_porch_max_lns_c + height_lns_g;
  CONSTANT v_f_porch_max_lns_c : INTEGER := v_disp_max_lns_c + v_f_porch_lns_g;
  CONSTANT h_sync_max_px_c     : INTEGER := h_sync_px_g;
  CONSTANT h_b_porch_max_px_c  : INTEGER := h_sync_max_px_c + h_b_porch_px_g;
  CONSTANT h_disp_max_px_c     : INTEGER := h_b_porch_max_px_c + width_px_g;
  CONSTANT h_f_porch_max_px_c  : INTEGER := h_disp_max_px_c + h_f_porch_px_g;

  SUBTYPE pxl_ctr_t  IS INTEGER RANGE (h_f_porch_max_px_c - 1) DOWNTO 0;
  SUBTYPE line_ctr_t IS INTEGER RANGE (v_f_porch_max_lns_c - 1) DOWNTO 0;
  
  TYPE hstate_t IS (H_IDLE, H_SYNC, H_B_PORCH, H_F_PORCH, H_DISPLAY);
  TYPE vstate_t IS (V_IDLE, V_SYNC, V_B_PORCH, V_F_PORCH, V_DISPLAY);

  SIGNAL h_c_state, h_n_state : hstate_t;
  SIGNAL v_c_state, v_n_state : vstate_t;


  SIGNAL pixel_ctr_r : pxl_ctr_t;
  SIGNAL line_ctr_r  : line_ctr_t;

  SIGNAL v_sync_s  : STD_LOGIC;
  SIGNAL h_sync_s  : STD_LOGIC;
  SIGNAL colr_en_s : STD_LOGIC; 
BEGIN 

  sync_cntrs : PROCESS (clk, rst_n) IS -- line/pxl counters --------------------
  BEGIN 

    IF rst_n = '0' THEN 

      pixel_ctr_r <= 0;
      line_ctr_r  <= 0;

    ELSIF RISING_EDGE(clk) THEN 

      IF pixel_ctr_r = pxl_ctr_t'HIGH THEN

        IF line_ctr_r = line_ctr_t'HIGH THEN -- end of frame

          line_ctr_r <=  0; 

        ELSE -- end of line but not frame

          line_ctr_r <= line_ctr_r + 1; 

        END IF;

        pixel_ctr_r <=  0; -- reset px_counter at end of the line

      ELSE 

        pixel_ctr_r <= pixel_ctr_r + 1;

      END IF;
    END IF;
  END PROCESS sync_cntrs; ------------------------------------------------------    

  sync_fsm : PROCESS (clk, rst_n) IS -------------------------------------------
  BEGIN 
  
    IF rst_n = '0' THEN 

      h_c_state <= H_IDLE;
      v_c_state <= V_IDLE;

    ELSIF RISING_EDGE(clk) THEN

      h_c_state <= h_n_state;
      v_c_state <= v_n_state;

    END IF;

  END PROCESS sync_fsm;  -------------------------------------------------------

  comb_ns : PROCESS (ALL) IS 
  BEGIN 

    -- default assignments to avoid latch inference
    h_n_state <= h_c_state;
    v_n_state <= v_c_state;

    -- HORIZONTAL STATES -------------------------------------------------------

    CASE h_c_state IS
      
      WHEN H_IDLE =>

        h_n_state <= H_SYNC;
      
      WHEN H_SYNC =>

        IF pixel_ctr_r = h_sync_max_px_c - 1 THEN
          h_n_state <= H_B_PORCH;
        END IF;

      WHEN H_B_PORCH =>

        IF pixel_ctr_r = h_b_porch_max_px_c - 1 THEN
          h_n_state <= H_DISPLAY;
        END IF;

      WHEN H_DISPLAY =>

        IF pixel_ctr_r = h_disp_max_px_c - 1 THEN
          h_n_state <= H_F_PORCH;
        END IF;

      WHEN H_F_PORCH =>

        IF pixel_ctr_r = h_f_porch_max_px_c - 1 THEN
          h_n_state <= H_SYNC;
        END IF;

      WHEN OTHERS =>

        h_n_state <= H_IDLE;

    END CASE;

    -- VERTICAL STATES ---------------------------------------------------------

    CASE v_c_state IS 

      WHEN V_IDLE =>

        v_n_state <= V_SYNC;
      
      WHEN V_SYNC =>

        IF pixel_ctr_r = v_sync_max_lns_c - 1 THEN
          v_n_state <= V_B_PORCH;
        END IF;

      WHEN V_B_PORCH =>

        IF pixel_ctr_r = v_b_porch_max_lns_c - 1 THEN
          v_n_state <= V_DISPLAY;
        END IF;

      WHEN V_DISPLAY =>

        IF pixel_ctr_r = v_disp_max_lns_c - 1 THEN
          v_n_state <= V_F_PORCH;
        END IF;

      WHEN V_F_PORCH =>

        IF pixel_ctr_r = v_f_porch_max_lns_c - 1 THEN
          v_n_state <= V_SYNC;
        END IF;

      WHEN OTHERS =>

        v_n_state <= V_IDLE;

    END CASE;

  END PROCESS comb_ns; --------------------------------------------------------- 

  -- if v_display && h_display enable output

  h_sync_s  <= '0' WHEN h_c_state = H_SYNC ELSE '1';
  v_sync_s  <= '0' WHEN v_c_state = V_SYNC ELSE '1';
  colr_en_s <= '1' WHEN (h_c_state = H_DISPLAY AND v_c_state = V_DISPLAY) ELSE '0'; 

  h_sync_out  <= h_sync_s;
  v_sync_out  <= v_sync_s;
  colr_en_out <= colr_en_s;
  
END ARCHITECTURE rtl;

