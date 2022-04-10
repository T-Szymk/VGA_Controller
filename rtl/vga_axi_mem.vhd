-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA AXI Memory Module
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_axi_mem.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-04-07
-- Design     : vga_axi_mem
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: AXI-Lite (slave) memory module
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-04-07  1.1      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity vga_axi_mem is 
  generic (
  	AXI_ADDR_WIDTH INTEGER := 16;
  	AXI_DATA_WIDTH INTEGER := 36
  );
  port (
    -- AXI clk/rst_n
    s_aclk_i    : in  std_logic;
    s_arstn_i   : in  std_logic;
    -- AXI AR channel
    s_araddr_i  : in  std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    s_arprot_i  : in  std_logic_vector(2 downto 0);
    s_arvalid_i : in  std_logic;
    s_arrdy_o   : out std_logic;
    -- AXI R channel
    s_rdata_o   : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    s_rvalid_o  : out std_logic;
    s_rrdy_i    : in  std_logic; 
    s_rresp_o   : out std_logic_vector(1 downto 0)
  );
end entity vga_axi_mem;

--------------------------------------------------------------------------------

architecture rtl of vga_axi_mem is  

  type axi_mem_state_t is (reset, idle, rcv_addr, send_data);

  signal c_state, n_state : axi_mem_state_t;

begin

  s_rresp_o <= "00"; -- response tied to OKAY

  sync_cur_state : process(s_aclk_i, s_arstn_i) is -----------------------------
  begin
    if s_arstn_i = '0' then 
      c_state <= reset;
    elsif rising_edge(s_aclk_i) then
      c_state <= n_state; 
    end if;
  end process sync_cur_state; --------------------------------------------------

  comb_nxt_state : process (all) is -------------------------------------------- 
  begin 

    n_state <= c_state;

    case c_state is

      when reset =>
      when idle =>
      when send_addr =>
      when rcv_data =>
      when others =>

    end case;

  end process comb_nxt_state; --------------------------------------------------

  sync_outputs : process (s_aclk_i, s_arstn_i) is ------------------------------ 
  begin
  end process comb_nxt_state; --------------------------------------------------

end architecture rtl; 

--------------------------------------------------------------------------------