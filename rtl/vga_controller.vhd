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
            h_sync_px_g     : INTEGER := 95;
            h_b_porch_px_g  : INTEGER := 48;
            h_f_porch_px_g  : INTEGER := 15;
            v_sync_lns_g    : INTEGER := 2;
            v_b_porch_lns_g : INTEGER := 33;
            v_f_porch_lns_g : INTEGER := 10
  );
  PORT (
         clk   : IN STD_LOGIC;
         rst_n : IN STD_LOGIC;

         colr_en_out : OUT STD_LOGIC_VECTOR(3-1 DOWNTO 0); -- (2, 1, 0) = (b_en, g_en, r_en),
         v_sync_out  : OUT STD_LOGIC;
         h_sync_out  : OUT STD_LOGIC
  );
END ENTITY vga_controller;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF vga_controller IS 

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

  SIGNAL v_sync_s : STD_LOGIC;
  SIGNAL h_sync_s : STD_LOGIC;

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

  comb_h_sync : PROCESS (pixel_ctr_r) IS  -- TODO: make this synchronous
  BEGIN
	
    IF pixel_ctr_r < h_sync_px_g THEN
      h_sync_s <= '0';
	  ELSE 
	    h_sync_s <= '1';
	  END IF;


  END PROCESS comb_h_sync; -- TODO: make this synchronous

  comb_v_sync : PROCESS (line_ctr_r) IS 
  BEGIN
	
    IF line_ctr_r < v_sync_lns_g THEN
      v_sync_s <= '0';
    ELSE 
      v_sync_s <= '1';
    END IF;

  END PROCESS comb_v_sync; 

  comb_enable : PROCESS (pixel_ctr_r, line_ctr_r) IS -- TODO: make this synchronous
  BEGIN
    -- only disable colours when counters are outside of the "displayable range" i.e. not in the sync region or porch region
    -- TODO: Simplify the fuck out of this...
    IF ((pixel_ctr_r >= h_sync_px_g + h_b_porch_px_g - 1)  AND (pixel_ctr_r < h_sync_px_g + h_b_porch_px_g + width_g)) AND 
       ((line_ctr_r >= v_sync_lns_g + v_b_porch_lns_g)     AND (line_ctr_r < v_sync_lns_g + v_b_porch_lns_g + height_g)) THEN
      colr_en_out <= (OTHERS => '1');
	 ELSE 
	    colr_en_out <= (OTHERS => '0');
	 END IF;

  END PROCESS comb_enable;

  h_sync_out <= h_sync_s;
  v_sync_out <= v_sync_s;

END ARCHITECTURE rtl;