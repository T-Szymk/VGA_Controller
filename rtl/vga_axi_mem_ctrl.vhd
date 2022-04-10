-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA AXI Memory Controller
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_axi_mem_ctrl.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-03-26
-- Design     : vga_axi_mem_ctrl
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Controller to manage the memory accesses of the VGA controller 
--              via an AXI-Lite (master) interface.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-03-25  1.1      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.vga_pkg.all;

entity vga_axi_mem_ctrl is 
  generic (
  	AXI_ADDR_WIDTH : integer := 32;
  	AXI_DATA_WIDTH : integer := 64
  );
  port (
    clk         : in std_logic;
    rst_n       : in std_logic;
    pxl_ctr_i   : in std_logic_vector((pxl_ctr_width_c-1) downto 0);
    line_ctr_i  : in std_logic_vector((line_ctr_width_c-1) downto 0); 
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

  type axi_state_t is (reset, idle, send_addr, rcv_data);

  signal c_state, n_state : axi_state_t;
  signal m_arvalid_r,
         m_rrdy_r         : std_logic;
  signal req_data_s       : std_logic; -- set to 1 when vga requires data

  signal m_araddr_r_0, 
         m_araddr_r    : unsigned(AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal m_rdata_r     : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) := (others => '0');

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
      
        if req_data_s = '1' then 
          n_state <= send_addr;
        end if;

      when send_addr =>                                                         ---
        -- set valid high 
        -- populate data line
        if m_arvalid_r = '1' and m_arrdy_i = '1' then
          n_state <= rcv_data; 
        end if;

      when rcv_data =>                                                         ---
        -- Might be able to optimise here by returning to send_addr when there are new read requests...
        -- read data when ready and valid
        if(m_rvalid_i = '1') and (m_rrdy_r = '1') then
          n_state <= idle;
        end if;

      when others =>                                                         ---

        n_state <= reset;

    end case;

  end process comb_nxt_state; --------------------------------------------------

  sync_outputs : process (clk, rst_n) is --------------------------------------
  begin     
     
    if rst_n = '0' then
      
      m_rrdy_r     <= '0';
      m_arvalid_r  <= '0';
      m_araddr_r   <= (others => '0');
      m_araddr_r_0 <= (others => '0'); -- NOTE THAT THE ADDRESS SHOULD BE ASSIGNED TO SOMETHING VALID BUT UNTIL THE LOGIC IS THERE, AN INCREMENTAL VALUE WILL BE USED.

    elsif rising_edge(clk) then 
      
      m_rrdy_r     <= '0';
      m_arvalid_r  <= '0';
      m_araddr_r_0 <= m_araddr_r + 1; -- NOTE THAT THE ADDRESS SHOULD BE ASSIGNED TO SOMETHING VALID BUT UNTIL THE LOGIC IS THERE, AN INCREMENTAL VALUE WILL BE USED. 
         
      case n_state is 
        when reset =>
        when idle  =>
           
          if(c_state = rcv_data) then -- when rdy/vld = 1
            m_rdata_r <= m_rdata_i;
          end if;
           
        when send_addr =>
          
          m_arvalid_r <= '1';
          m_araddr_r  <= m_araddr_r_0;
           
        when rcv_data =>
          m_rrdy_r    <= '1';
        when others =>
      end case; 
    end if;

  end process sync_outputs; ---------------------------------------------------

  m_araddr_o  <= std_logic_vector(m_araddr_r); 
  m_arvalid_o <= m_arvalid_r;
  m_arprot_o  <= "000"; -- unpriveleged, unsecure, data access
  m_rrdy_o    <= m_rrdy_r;

end architecture rtl; 

--------------------------------------------------------------------------------