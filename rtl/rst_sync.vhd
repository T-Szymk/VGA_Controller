-------------------------------------------------------------------------------
-- Title      : Reset Synchroniser
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : rst_sync.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-26
-- Design     : rst_sync
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Variable size reset synchroniser
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-07-02  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity rst_sync is
  generic (
    SYNC_STAGES : integer := 3
  );
  port (
    clk_i       : in  std_logic;
    rstn_i      : in  std_logic;
    sync_rstn_o : out std_logic
  );
end entity rst_sync;

--------------------------------------------------------------------------------

architecture rtl of rst_sync is 

  signal rst_sync_r : unsigned(SYNC_STAGES-1 downto 0);

begin --------------------------------------------------------------------------

  assert SYNC_STAGES > 1
    report "Reset Synchroniser SYNC_STAGES must be greater than 1..."
    severity error;

  process (clk_i, rstn_i) is 
  begin 

    if rstn_i = '0' then 
      rst_sync_r <= (others => '0');
    elsif rising_edge(clk_i) then
      rst_sync_r <= rst_sync_r(SYNC_STAGES-2 downto 0) & '1';
    end if;

  end process;                           
 
  sync_rstn_o <= rst_sync_r(SYNC_STAGES-1);

end architecture rtl;

--------------------------------------------------------------------------------
