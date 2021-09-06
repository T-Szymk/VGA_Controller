-------------------------------------------------------------------------------
-- Title      : VGA Controller Top - Arty-A7 Implementation
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_top_arty-a7.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-07-04
-- Design     : vga_top
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Top level design for vga controller to be used with the 
--              Xilinx Arty-A7 development board
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-07-04  1.0      TZS     Created
-- 2021-09-01  1.1      TZS     Updated top level as component ports were moded
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_top IS
  GENERIC (
            CONF_SIM       : BIT     := '1';
            CONF_PATT_GEN  : BIT     := '1';
            ref_clk_freq_g : INTEGER := 50_000_000;
            px_clk_freq_g  : INTEGER := 25_000_000;
            height_px_g    : INTEGER := 480;
            width_px_g     : INTEGER := 680;
            depth_colr_g   : INTEGER := 4
          );

  PORT (
         clk    : IN STD_LOGIC;
         rst_n  : IN STD_LOGIC;
         sw_in  : IN STD_LOGIC_VECTOR(3-1 DOWNTO 0); 
         
         v_sync_out  : OUT STD_LOGIC;
         h_sync_out  : OUT STD_LOGIC;
         clk_px_out  : OUT STD_LOGIC;
         r_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
         g_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
         b_colr_out  : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0)
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
  
  COMPONENT clk_gen -- FOR FPGA **********************************************
 --TODO: Add XILINX clocking block instantiation
  END COMPONENT; -- FOR FPGA *************************************************
  
  COMPONENT vga_rst_sync IS
    PORT (
           clk       : IN STD_LOGIC;
           rst_n_in  : IN STD_LOGIC;
  
           rst_n_out : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT vga_sw_sync
    GENERIC (depth_colr_g : INTEGER := 4);
    PORT (
           clk     : IN STD_LOGIC;
           rst_n   : IN STD_LOGIC; 
           sw_in   : IN STD_LOGIC;
           colr_in : IN STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
           
           colr_out : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0)
    );
    END COMPONENT;

  COMPONENT vga_controller IS
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
    PORT(
        clk   : IN STD_LOGIC;
        rst_n : IN STD_LOGIC;

        colr_en_out : OUT STD_LOGIC;
        v_sync_out  : OUT STD_LOGIC;
        h_sync_out  : OUT STD_LOGIC
    );
  END COMPONENT vga_controller;

  COMPONENT vga_colr_mux IS 
    GENERIC (depth_colr_g : INTEGER := 4);
    PORT (
      colr_in : IN STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0);
      en_in   : IN STD_LOGIC;
    
      colr_out : OUT STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0)
    );
  END COMPONENT;

  --COMPONENT vga_colr_gen IS 
  --  GENERIC (
  --            r_cntr_inc_g : INTEGER := 10;
  --            g_cntr_inc_g : INTEGER := 50;
  --            b_cntr_inc_g : INTEGER := 15;
	--            depth_colr_g : INTEGER := 4
  --  );
  --  PORT (
  --         clk       : IN STD_LOGIC;
  --         rst_n     : IN STD_LOGIC;
  --         trig_in   : IN STD_LOGIC; -- take from v_sync
  --  
  --         r_colr_out : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
  --         g_colr_out : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0);
  --         b_colr_out : OUT STD_LOGIC_VECTOR(depth_colr_g-1 DOWNTO 0)
  --  );
  --END COMPONENT;

  SIGNAL clk_px_out_s   : STD_LOGIC;
  SIGNAL rst_n_s        : STD_LOGIC;
  SIGNAL v_sync_s       : STD_LOGIC;
  SIGNAL h_sync_s       : STD_LOGIC;
  SIGNAL colr_en_s      : STD_LOGIC;

  SIGNAL colr_sw_arr_s  : STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0);
  SIGNAL colr_gen_arr_s : STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0);
  SIGNAL colr_arr_s     : STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0);

BEGIN ------------------------------------------------------------------

  i_vga_rst_sync : vga_rst_sync
  PORT MAP (
             clk       => clk,
             rst_n_in  => rst_n,
             rst_n_out => rst_n_s
  );

  gen_clk_src: IF CONF_SIM = '1' GENERATE

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
  ELSE GENERATE 
      i_clk_gen : clk_gen -- Used in synthesis *************************************
      	PORT MAP (
      	    	     areset => NOT rst_n_s,
      	    	     inclk0 => clk,
      	    	     c0	   => clk_px_out_s
      	); -- Used in synthesis ****************************************************
  END GENERATE gen_clk_src;

  gen_sync : FOR idx IN (3-1) DOWNTO 0 GENERATE
  BEGIN
    i_sw_sync : vga_sw_sync
      GENERIC MAP (depth_colr_g => depth_colr_g)
      PORT MAP (
                 clk      => clk_px_out_s,
                 rst_n    => rst_n_s,
                 sw_in    => sw_in(idx),
                 colr_in  => colr_gen_arr_s(((idx+1)*depth_colr_g)-1 DOWNTO (idx*depth_colr_g)-1),
                 colr_out => colr_sw_arr_s(((idx+1)*depth_colr_g)-1 DOWNTO (idx*depth_colr_g)-1)
      );
  END GENERATE gen_sync;

  i_vga_controller : vga_controller
    GENERIC MAP ( 
      width_px_g      => 640,
      height_lns_g    => 480,
      h_sync_px_g     => 96,
      h_b_porch_px_g  => 48,
      h_f_porch_px_g  => 16,
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
    GENERIC MAP (
      depth_colr_g => depth_colr_g)
    PORT MAP (
      colr_in  => (colr_gen_arr_s),
      en_in    => colr_en_s,
      colr_out => (colr_arr_s)
    );

  gen_patt_gen : IF CONF_PATT_GEN = '1' GENERATE

   --i_vga_colr_gen : vga_colr_gen
   --GENERIC MAP (
    --  r_cntr_inc_g => 10,
    --  g_cntr_inc_g => 5,
    --  b_cntr_inc_g => 15,
	  --  depth_colr_g => 4
    --)
    --PORT MAP (
    --  clk       => clk_px_out_s,
    --  rst_n     => rst_n_s,
    --  trig_in   => v_sync_s,  
    --  r_colr_out => colr_arr_s((3*depth_colr_g)-1 DOWNTO (2*depth_colr_g)),
    --  g_colr_out => colr_arr_s((2*depth_colr_g)-1 DOWNTO (depth_colr_g)),
    --  b_colr_out => colr_arr_s((2*depth_colr_g)-1 DOWNTO 0)
    --);
  END GENERATE gen_patt_gen;

  clk_px_out  <= clk_px_out_s;
  v_sync_out  <= v_sync_s;
  h_sync_out  <= h_sync_s;

  r_colr_out <= colr_arr_s((3*depth_colr_g)-1 DOWNTO (2*depth_colr_g));
  g_colr_out <= colr_arr_s((2*depth_colr_g)-1 DOWNTO depth_colr_g);
  b_colr_out <= colr_arr_s(depth_colr_g-1     DOWNTO 0);

END ARCHITECTURE structural;

--------------------------------------------------------------------------------
