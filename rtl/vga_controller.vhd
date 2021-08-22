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
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_controller IS 
  GENERIC (
            width_g         : INTEGER := 640;
            height_g        : INTEGER := 480;
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

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_controller IS 

  CONSTANT h_disp_lo_lim_c : INTEGER := h_sync_px_g + h_b_porch_px_g;
  CONSTANT h_disp_hi_lim_c : INTEGER := h_disp_lo_lim_c + width_g;
  CONSTANT v_disp_lo_lim_c : INTEGER := v_sync_lns_g + v_b_porch_lns_g;
  CONSTANT v_disp_hi_lim_c : INTEGER := v_disp_lo_lim_c + height_g;

  SUBTYPE pxl_ctr_t IS INTEGER RANGE (h_sync_px_g +
                                      h_b_porch_px_g +
                                      h_f_porch_px_g +
                                      width_g - 1) DOWNTO 0;
  SUBTYPE line_ctr_t IS INTEGER RANGE (v_sync_lns_g +
                                      v_b_porch_lns_g +
                                      v_f_porch_lns_g +
                                      height_g - 1) DOWNTO 0;

  SIGNAL pixel_ctr_r : pxl_ctr_t;
  SIGNAL line_ctr_r  : line_ctr_t;

  SIGNAL v_sync_r  : STD_LOGIC;
  SIGNAL h_sync_r  : STD_LOGIC;
  SIGNAL colr_en_r : STD_LOGIC; 
BEGIN 

  sync_cntrs : PROCESS (clk, rst_n) IS 
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
  END PROCESS sync_cntrs;

  sync_h_sync : PROCESS (clk, rst_n) IS
  BEGIN

    IF rst_n = '0' THEN

      h_sync_r <= '1';

    ELSIF RISING_EDGE(clk) THEN
	
      IF (pixel_ctr_r < h_sync_px_g) THEN
        h_sync_r <= '0';
	    ELSE 
	      h_sync_r <= '1';
	    END IF;

    END IF;


  END PROCESS sync_h_sync;

  sync_v_sync : PROCESS (clk, rst_n) IS 
  BEGIN

    IF rst_n = '0' THEN

      v_sync_r <= '1';
  	
    ELSIF RISING_EDGE(clk) THEN  

      IF (line_ctr_r < (v_sync_lns_g )) THEN
        v_sync_r <= '0';
      ELSE 
        v_sync_r <= '1';
      END IF; 
    
    END IF;

  END PROCESS sync_v_sync; 

  sync_enable : PROCESS (clk, rst_n) IS 
  BEGIN

    IF rst_n = '0' THEN

        colr_en_r <= '0';

    ELSIF RISING_EDGE(clk) THEN
    -- only disable colours when counters are outside of the "displayable range" i.e. not in the sync region or porch region
      IF ((pixel_ctr_r >= h_disp_lo_lim_c) AND (pixel_ctr_r < h_disp_hi_lim_c)) AND 
         ((line_ctr_r >= v_disp_lo_lim_c)  AND (line_ctr_r < v_disp_hi_lim_c)) THEN
        
        colr_en_r <= '1';
      ELSE 
        colr_en_r <= '0';
      END IF;

    END IF;
  END PROCESS sync_enable;

  h_sync_out  <= h_sync_r;
  v_sync_out  <= v_sync_r;
  colr_en_out <= colr_en_r;
  
END ARCHITECTURE rtl;

