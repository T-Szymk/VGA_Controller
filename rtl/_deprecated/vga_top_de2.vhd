-------------------------------------------------------------------------------
-- Title      : VGA Controller Top - Intel Cyclone II DE-2 Implementation
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_top_de2.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-06-24
-- Design     : vga_top
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Top level design for vga controller to be used with the 
--              cyclone II DE-2 development board
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-06-24  1.0      TZS     Created
-- 2021-10-09  --       TZS     Moved to deprecated as file no longer in use.
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_top IS
  GENERIC (
            ref_clk_freq_g : INTEGER := 50_000_000;
            px_clk_freq_g  : INTEGER := 25_000_000;
            height_px_g    : INTEGER := 480;
            width_px_g     : INTEGER := 680
          );

  PORT (
         clk    : IN STD_LOGIC;
         rst_n  : IN STD_LOGIC;
         sw_in  : IN STD_LOGIC_VECTOR(3-1 DOWNTO 0); 
         
         sync_n_out  : OUT STD_LOGIC;
         blank_n_out : OUT STD_LOGIC;
         v_sync_out  : OUT STD_LOGIC;
         h_sync_out  : OUT STD_LOGIC;
         clk_px_out  : OUT STD_LOGIC;
         r_colr_out  : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
         g_colr_out  : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
         b_colr_out  : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0)
       );
END ENTITY vga_top;

--------------------------------------------------------------------------------

ARCHITECTURE structural of vga_top IS 

  COMPONENT vga_clk_div -- FOR SIM *********************************************
    GENERIC (
              ref_clk_freq_g : INTEGER := 50_000_000;
              px_clk_freq_g  : INTEGER := 25_000_000
    );
    PORT    ( 
              clk        : IN STD_LOGIC;
              rst_n      : IN STD_LOGIC;
  
              clk_px_out : OUT STD_LOGIC
    );
  END COMPONENT; -- FOR SIM ****************************************************
  
--  COMPONENT clk_gen -- generated using Quartus *********************************
--  	PORT (
--  	    	areset : IN STD_LOGIC;
--  	    	inclk0 : IN STD_LOGIC;
--  	    	c0		 : OUT STD_LOGIC 
--  	     );
--  END COMPONENT; -- generated using Quartus ************************************
  
  COMPONENT vga_rst_sync IS
    PORT (
           clk       : IN STD_LOGIC;
           rst_n_in  : IN STD_LOGIC;
  
           rst_n_out : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT vga_sw_sync
    PORT (
           clk     : IN STD_LOGIC;
           rst_n   : IN STD_LOGIC; 
           sw_in   : IN STD_LOGIC;
           colr_in : IN STD_LOGIC_VECTOR(10-1 DOWNTO 0);
           
           colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0)
    );
    END COMPONENT;

  COMPONENT vga_controller IS
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
    PORT(
        clk   : IN STD_LOGIC;
        rst_n : IN STD_LOGIC;

        colr_en_out : OUT STD_LOGIC_VECTOR(3-1 DOWNTO 0);
        v_sync_out  : OUT STD_LOGIC;
        h_sync_out  : OUT STD_LOGIC
    );
  END COMPONENT vga_controller;

  COMPONENT vga_colr_mux IS 
    PORT (
      r_colr_in : IN STD_LOGIC_VECTOR(10-1 DOWNTO 0);
      g_colr_in : IN STD_LOGIC_VECTOR(10-1 DOWNTO 0);
      b_colr_in : IN STD_LOGIC_VECTOR(10-1 DOWNTO 0);
      r_en_in   : IN STD_LOGIC;
      g_en_in   : IN STD_LOGIC;
      b_en_in   : IN STD_LOGIC;
    
      r_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
      g_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
      b_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT vga_colr_gen IS 
    GENERIC (
              r_cntr_inc_g : INTEGER := 10;
              g_cntr_inc_g : INTEGER := 50;
              b_cntr_inc_g : INTEGER := 15
    );
    PORT (
           clk       : IN STD_LOGIC;
           rst_n     : IN STD_LOGIC;
           trig_in   : IN STD_LOGIC; -- take from v_sync
    
           r_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
           g_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0);
           b_colr_out : OUT STD_LOGIC_VECTOR(10-1 DOWNTO 0)
    );
  END COMPONENT;

  TYPE colr_arr_t IS ARRAY(3-1 DOWNTO 0) OF STD_LOGIC_VECTOR(10-1 DOWNTO 0);

  SIGNAL clk_px_out_s : STD_LOGIC;
  SIGNAL rst_n_s      : STD_LOGIC;
  SIGNAL v_sync_s     : STD_LOGIC;
  SIGNAL h_sync_s     : STD_LOGIC;
  SIGNAL sw_out_s     : STD_LOGIC_VECTOR(3-1 DOWNTO 0);
  SIGNAL colr_en_s    : STD_LOGIC_VECTOR(3-1 DOWNTO 0);

  SIGNAL colr_arr_sw_s : colr_arr_t;
  SIGNAL colr_arr_gen_s : colr_arr_t;

BEGIN ------------------------------------------------------------------

  i_vga_rst_sync : vga_rst_sync
  PORT MAP (
             clk => clk,
             rst_n_in => rst_n,
             rst_n_out => rst_n_s
  );

  i_vga_clk_div : vga_clk_div -- Used in simulation ****************************
    GENERIC MAP (
                  ref_clk_freq_g => ref_clk_freq_g, 
                  px_clk_freq_g  => px_clk_freq_g
    )
    PORT MAP    (
                  clk        => clk,
                  rst_n      => rst_n_s,
                  clk_px_out => clk_px_out_s
    ); -- Used in simulation ***************************************************

--  i_clk_gen : clk_gen -- Used in synthesis *************************************
--  	PORT MAP (
--  	    	     areset => NOT rst_n_s,
--  	    	     inclk0 => clk,
--  	    	     c0	   => clk_px_out_s
--  	); -- Used in synthesis ****************************************************
  
  gen_sync : FOR idx IN (3-1) DOWNTO 0 GENERATE
  BEGIN
    i_sw_sync : vga_sw_sync
      PORT MAP (
                 clk      => clk_px_out_s,
                 rst_n    => rst_n_s,
                 sw_in    => sw_in(idx),
                 colr_in  => colr_arr_gen_s(idx),
                 colr_out => colr_arr_sw_s(idx)
      );
  END GENERATE gen_sync;

  i_vga_controller : vga_controller
    GENERIC MAP ( 
      width_g         => 640,
      height_g        => 480,
      h_sync_px_g     => 95,
      h_b_porch_px_g  => 48,
      h_f_porch_px_g  => 15,
      v_sync_lns_g    => 2,
      v_b_porch_lns_g => 33,
      v_f_porch_lns_g => 10
    )
    PORT MAP (
      clk         => clk_px_out_s,
      rst_n       => rst_n_s,
      colr_en_out => colr_en_s,
      v_sync_out  => v_sync_s,
      h_sync_out  => h_sync_s
    );

  i_vga_colr_mux : vga_colr_mux
   PORT MAP (
    r_colr_in => colr_arr_gen_s(0),
    g_colr_in => colr_arr_gen_s(1),
    b_colr_in => colr_arr_gen_s(2),
    r_en_in   => colr_en_s(0),
    g_en_in   => colr_en_s(1),
    b_en_in   => colr_en_s(2),
    r_colr_out => r_colr_out,
    g_colr_out => g_colr_out,
    b_colr_out => b_colr_out
  );

   i_vga_colr_gen : vga_colr_gen
   GENERIC MAP (
              r_cntr_inc_g => 10,
              g_cntr_inc_g => 5,
              b_cntr_inc_g => 15
    )
    PORT MAP (
           clk       => clk_px_out_s,
           rst_n     => rst_n_s,
           trig_in   => v_sync_s,  
           r_colr_out => colr_arr_gen_s(0),
           g_colr_out => colr_arr_gen_s(1),
           b_colr_out => colr_arr_gen_s(2) 
    );

  sync_n_out  <= '0'; -- no synch info needed on green signal so tied to zero
  blank_n_out <= '1'; -- not used, so tied to 1 to keep current flowing to colr out
  clk_px_out  <= clk_px_out_s;
  v_sync_out  <= v_sync_s;
  h_sync_out  <= h_sync_s;


END ARCHITECTURE structural;

--------------------------------------------------------------------------------