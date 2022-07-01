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
-- Description: Controller to control colr_en, h_sync, v_sync
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-24  1.0      TZS     Created
-- 2021-06-26  1.1      TZS     Added enable signals,
--                              Removed blank control
-- 2021-08-28  1.2      TZS     Refactored to use a state machine
-- 2021-09-01  1.3      TZS     Simplified state machine
-- 2021-12-11  1.4      TZS     Moved counter into top level
-- 2022-07-01  1.5      TZS     Reversed polarity of colr_en signal
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.VGA_PKG.ALL;

ENTITY vga_controller IS 
  PORT (
    clk_i      : IN STD_LOGIC;
    rstn_i     : IN STD_LOGIC;
    pxl_ctr_i  : IN STD_LOGIC_VECTOR((pxl_ctr_width_c - 1) DOWNTO 0);
    line_ctr_i : IN STD_LOGIC_VECTOR((line_ctr_width_c - 1) DOWNTO 0);

    colr_en_out : OUT STD_LOGIC;
    v_sync_out  : OUT STD_LOGIC;
    h_sync_out  : OUT STD_LOGIC
  );
END ENTITY vga_controller;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_controller IS 

-- VARIABLES / CONSTANTS / TYPES -----------------------------------------------
  
  TYPE state_t IS (IDLE, H_SYNC, H_B_PORCH, H_F_PORCH, DISPLAY, 
                   V_SYNC, V_B_PORCH, V_F_PORCH);

  SIGNAL c_state, n_state : state_t;

  SIGNAL pxl_ctr_r  : INTEGER RANGE (pxl_ctr_max_c - 1) DOWNTO 0;
  SIGNAL line_ctr_r : INTEGER RANGE (line_ctr_max_c - 1) DOWNTO 0;

  SIGNAL v_sync_r  : STD_LOGIC;
  SIGNAL h_sync_r  : STD_LOGIC;
  SIGNAL colr_en_r : STD_LOGIC; 

BEGIN 

  sync_cs : PROCESS (clk_i, rstn_i) IS -------------------------------------------
  BEGIN 
  
    IF rstn_i = '0' THEN 
      c_state <= IDLE;
    ELSIF RISING_EDGE(clk_i) THEN
      c_state <= n_state;
    END IF;

  END PROCESS sync_cs;  -------------------------------------------------------

  comb_ns : PROCESS (ALL) IS
  BEGIN

    n_state <= c_state;

    CASE c_state IS 

      WHEN IDLE =>                                                          ----

        n_state <= V_SYNC;

      WHEN V_SYNC =>                                                        ----

        IF (line_ctr_r = (v_sync_max_lns_c - 1) AND 
                         pxl_ctr_r = pxl_ctr_t'HIGH) THEN
          n_state <= V_B_PORCH;
        END IF;

      WHEN V_B_PORCH =>                                                     ----

        IF (line_ctr_r = (v_b_porch_max_lns_c - 1) AND 
           pxl_ctr_r = pxl_ctr_t'HIGH) THEN
          n_state <= H_SYNC;
        END IF;

      WHEN H_SYNC =>                                                        ----

        IF pxl_ctr_r = h_sync_max_px_c - 1 THEN
          n_state <= H_B_PORCH;
        END IF;

      WHEN H_B_PORCH =>                                                     ----

        IF pxl_ctr_r = h_b_porch_max_px_c - 1 THEN
          n_state <= DISPLAY;
        END IF;

      WHEN DISPLAY =>                                                       ----
 
        IF pxl_ctr_r = h_disp_max_px_c - 1 THEN
          n_state <= H_F_PORCH;
        END IF;

      WHEN H_F_PORCH =>                                                     ----

        IF pxl_ctr_r = h_f_porch_max_px_c - 1 THEN
          IF (line_ctr_r = (v_disp_max_lns_c - 1) AND 
             pxl_ctr_r = pxl_ctr_t'HIGH) THEN
            n_state <= V_F_PORCH;
          ELSE
            n_state <= H_SYNC;
          END IF;
        END IF;

      WHEN V_F_PORCH =>                                                     ----

        IF (line_ctr_r = (v_f_porch_max_lns_c - 1) AND 
           pxl_ctr_r = pxl_ctr_t'HIGH) THEN
          n_state <= V_SYNC;
        END IF;

      WHEN OTHERS =>                                                        ----

        n_state <= IDLE;

    END CASE;

  END PROCESS comb_ns;  --------------------------------------------------------

  sync_out : PROCESS (clk_i, rstn_i) IS 
  BEGIN 

    IF rstn_i = '0' THEN 

      h_sync_r <= '1';
      v_sync_r <= '1';
      colr_en_r <= '0';

    ELSIF RISING_EDGE(clk_i) THEN
      
      -- h_sync conditions
      IF pxl_ctr_r = pxl_ctr_t'HIGH THEN
        h_sync_r <= '0';
      ELSIF pxl_ctr_r = (h_sync_max_px_c - 1) THEN
        h_sync_r <= '1';
      END IF;
      
      -- v_sync conditions
      IF (line_ctr_r = (v_f_porch_max_lns_c - 1) AND 
        pxl_ctr_r = pxl_ctr_t'HIGH) THEN
        v_sync_r <= '0';
      ELSIF (line_ctr_r = (v_sync_max_lns_c - 1) AND 
        pxl_ctr_r = pxl_ctr_t'HIGH) THEN
        v_sync_r <= '1';
      END IF;

      -- colr_en conditions
      IF c_state = H_B_PORCH AND pxl_ctr_r = (h_b_porch_max_px_c - 1) THEN
        colr_en_r <= '0';
      ELSIF c_state = DISPLAY AND pxl_ctr_r = (h_disp_max_px_c - 1) THEN
        colr_en_r <= '1';
      END IF;

    END IF;

  END PROCESS sync_out;  -------------------------------------------------------

  h_sync_out  <= h_sync_r;
  v_sync_out  <= v_sync_r;
  colr_en_out <= colr_en_r;
  pxl_ctr_r   <= TO_INTEGER(UNSIGNED(pxl_ctr_i));
  line_ctr_r  <= TO_INTEGER(UNSIGNED(line_ctr_i));
  
END ARCHITECTURE rtl;

