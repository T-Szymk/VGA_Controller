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
use IEEE.numeric_std.all;
use WORK.vga_pkg.all;

entity vga_axi_mem_ctrl is 
  generic (
  	AXI_ADDR_WIDTH : INTEGER := 32;
  	AXI_DATA_WIDTH : INTEGER := 64
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
  signal m_arvalid_r : std_logic;
  signal m_rrdy_s    : std_logic;
  signal req_data_s  : std_logic; -- set to 1 when vga requires data

  signal addr_r0, addr_r : unsigned(AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal data_r  : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) := (others => '0');

begin

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
      
        if m_arrdy_i = '1' and req_data_s = '1' then 
          n_state <= r_addr;
        end if;

      when r_addr =>                                                         ---
        -- set valid high 
        -- populate data line
        n_state <= r_data; 

      when r_data =>                                                         ---
        -- Might be able to optimise here by returning to r_addr when there is 
        -- new read requests...
        if(m_rvalid_i = '1') then
          n_state <= idle;
        end if;

      when others =>                                                         ---

        n_state <= reset;

    end case;

  end process comb_nxt_state; --------------------------------------------------

  sync_axi_ctrl : process (clk, rst_n) is --------------------------------------
  begin 

     if rst_n = '0' then
       m_arvalid_r <= '0';
       addr_r     <= (others => '0');
       addr_r0    <= (others => '0'); -- NOTE THAT THE ADDRESS SHOULD BE ASSIGNED TO SOMETHING VALID BUT UNTIL THE LOGIC IS THERE, AN INCREMENTAL VALUE WILL BE USED.    
     elsif rising_edge(clk) then 
       m_arvalid_r <= '0';
       addr_r0  <= addr_r + 1; -- NOTE THAT THE ADDRESS SHOULD BE ASSIGNED TO SOMETHING VALID BUT UNTIL THE LOGIC IS THERE, AN INCREMENTAL VALUE WILL BE USED. 

     case n_state is 
       when reset  =>
       when idle   =>
         if(c_state = r_data) then
           data_r      <= m_rdata_i;
         end if;
       when r_addr =>
         m_arvalid_r <= '1';
         addr_r      <= addr_r0;
       when r_data =>
       when others =>
     end case; 

     end if;

  end process sync_axi_ctrl; ---------------------------------------------------

  m_aclk_o    <= clk;
  m_arstn_o   <= rst_n;
  m_araddr_o  <= std_logic_vector(addr_r); 
  m_arvalid_o <= m_arvalid_r;
  m_arprot_o  <= "000"; -- unpriveleged, unsecure, data access
  m_rrdy_o    <= '1';

end architecture rtl; 

--------------------------------------------------------------------------------