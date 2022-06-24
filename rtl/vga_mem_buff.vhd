-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_mem_buff.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-25
-- Design     : vga_mem_buff
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to contain ping-pong buffers and logic to control display
--              datapath between the memory and the VGA controller.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-25  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

ENTITY vga_mem_buff IS 
  PORT (
    clk_i           : in  std_logic;
    rstn_i          : in  std_logic;
    disp_addr_ctr_i : in  std_logic_vector(mem_addr_width_c-1 downto 0);
    disp_pxl_ctr_i  : in  std_logic_vector(row_ctr_width_c-1 downto 0);
    mem_data_i      : in  pixel_word_t;
    mem_addr_o      : out std_logic_vector(mem_addr_width_c-1 downto 0);
    mem_ren_o       : out std_logic;
    disp_blank_o    : out std_logic;
    disp_pxl_o      : out pixel_t
  );
END ENTITY vga_mem_buff;

--------------------------------------------------------------------------------
ARCHITECTURE rtl OF vga_mem_buff IS

  type state_t is (INIT, FILL_A, FILL_A_READ_B, FILL_B_READ_A);
  
  signal c_state, n_state : state_t := INIT;
  signal mem_addr_r   : unsigned(mem_addr_width_c-1 downto 0);
  signal mem_ren_r    : std_logic;
  signal disp_blank_r : std_logic;
  signal disp_pxl_r   : pixel_t;

BEGIN  -------------------------------------------------------------------------

  sync_cstate : process (clk_i, rstn_i) is -------------------------------------
  begin 
    if rstn_i = '0' then
      c_state <= INIT; 
    elsif rising_edge(clk_i) then 
      c_state <= n_state;
    end if;
  end process sync_cstate; -----------------------------------------------------

  comb_nstate : process (all) is -----------------------------------------------
  begin 
    -- default assignment
    n_state <= c_state;
    
    case c_state is 
      when INIT =>
        n_state <= FILL_A;

      when FILL_A =>
        -- if first time, fill buffer A address + data, then move on to FILL_B_READ_A,
        n_state <= FILL_B_READ_A;

      when FILL_A_READ_B =>
      -- wait for pxl_ctr to reach final value and move to FILL_B_READ_A

      when FILL_B_READ_A =>
      --  wait for pxl_ctr to reach final value and move to FILL_A_READ_B
      when OTHERS =>
    end case;

  end process comb_nstate; -----------------------------------------------------
  
  sync_outp : process (clk_i, rstn_i) is ---------------------------------------
  begin

    if rstn_i = '0' then 

      mem_addr_r   <= (others => '0');
      mem_ren_r    <= '0';
      disp_blank_r <= '0';
      disp_pxl_r   <= (others => '0');

    elsif rising_edge(clk_i) then

      case c_state is 
        when INIT =>
     
          mem_addr_r   <= (others => '0');
          mem_ren_r    <= '0';
          disp_blank_r <= '0';
          disp_pxl_r   <= (others => '0');
          
        when FILL_A =>
        when FILL_A_READ_B =>
        when FILL_B_READ_A =>
        when OTHERS =>
      end case;
    
    end if;

  end process sync_outp;  ------------------------------------------------------

  ------------------------------------------------------------------------------

  mem_addr_o   <= mem_addr_r;
  mem_ren_o    <= mem_ren_r;
  disp_blank_o <= disp_blank_r;
  disp_pxl_o   <= disp_pxl_r;

END ARCHITECTURE rtl;

--------------------------------------------------------------------------------