-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA AXI Memory Controller
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_axi_mem_ctrl.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-03-05
-- Design     : vga_axi_mem_ctrl
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Controller to manage the memory accesses of the VGA controller 
--              via an AXI (master) interface.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-03-05  1.1      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
USE WORK.VGA_PKG.ALL;

entity vga_axi_mem_ctrl is 
  generic (
  	AXI_ADDR_WIDTH INTEGER := 16;
  	AXI_DATA_WIDTH INTEGER := 36
  );
  port (
    clk         : in std_logic;
    rst_n       : in std_logic;
    pxl_ctr_i   : in std_logic_vector((pxl_ctr_width_c-1) downto 0);
    line_ctr_i  : in std_logic_vector((line_ctr_width_c-1) downto 0); 
    -- AXI clk/rst_n
    m_aclk_o    : out std_logic;
    m_arstn_o   : out std_logic;
    -- AXI AR channel
    m_araddr_o  : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    m_arprot_o  : out std_logic_vector(2 downto 0);
    m_arvalid_o : out std_logic;
    m_arrdy_i   : in  std_logic;
    -- AXI R channel
    m_rdata_i   : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    m_rvalid_i  : in  std_logic;
    m_rrdy_o    : out std_logic; 
    m_rresp_i   : in  std_logic_vector(1 downto 0)
  );
end entity vga_axi_mem_ctrl;

--------------------------------------------------------------------------------

architecture rtl of vga_axi_mem_ctrl is 

  type axi_state_t is (reset, idle, r_addr, r_data);

  signal c_state, n_state : axi_state_t;
  signal m_rvalid_r, m_arrdy_r : std_logic;
  signal m_arvalid_s, m_rrdy_s : std_logic;

begin

  sync_axi_ctrl : process (clk, rst_n) is --------------------------------------
  begin 

     if rst_n = '0' then
       m_rvalid_r <= '0';
       m_arrdy_r  <= '0';
     elsif rising_edge(clk) then 
       m_rvalid_r <= m_rvalid_i;
       m_arrdy_r  <= m_arrdy_i;
     end if;

  end process sync_axi_ctrl; ---------------------------------------------------

  sync_cur_state : process (clk, rst_n) is -------------------------------------
  begin 

    if rst_n = '0' then
      c_state <= reset;
    elsif rising_edge(clk) then
      c_state <= n_state; 
    end if;

  end process sync_cur_state; --------------------------------------------------

  comb_nxt_state : process (all) is --------------------------------------------
  begin 

    n_state <= c_state;

    case c_state is
      
      when reset  =>                                                         ---

        if rst_n = '1' then
        	n_state <= idle;
        end if;

      when idle   =>                                                         ---
      
        if m_arrdy_r = '1' and m_arvalid_s = '1' then 
          n_state <= r_addr;
        end if;

      when r_addr =>                                                         ---

        if m_rvalid_r = '1' and m_rrdy_s = '1' then 
          n_state <= r_data;
        end if;
                                                                 
      when r_data =>                                                         ---

        if m_arrdy_r = '1' and m_arvalid_s = '1' then 
          n_state <= r_addr;
        else 
          n_state <= idle;
        end if; 

      when others =>                                                         ---

        n_state <= reset;

    end case;

  end process comb_nxt_state; --------------------------------------------------

  comb_fsm_out : process (all) is ----------------------------------------------
  begin
  end process comb_fsm_out; ----------------------------------------------------

  m_aclk_o  <= clk;
  m_arstn_o <= rst_n;

end architecture rtl; 

--------------------------------------------------------------------------------