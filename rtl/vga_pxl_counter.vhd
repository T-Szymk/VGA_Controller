-------------------------------------------------------------------------------
-- Title      : VGA Controller Pixel Counter
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_pxl_counter.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-12-11
-- Design     : vga_controller
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Counter to provide pixel and line counter values to be used by
--              VGA controller.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-12-11  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity vga_pxl_counter is 
	port (
    clk_i      : in std_logic;
    rstn_i     : in std_logic;
    
    pxl_ctr_o  : out std_logic_vector((pxl_ctr_width_c - 1) downto 0);
    line_ctr_o : out std_logic_vector((line_ctr_width_c - 1) downto 0)
	);
end entity vga_pxl_counter;

--------------------------------------------------------------------------------

architecture rtl of vga_pxl_counter is 

-- VARIABLES / CONSTANTS / TYPES -----------------------------------------------

  signal pxl_ctr_r  : pxl_ctr_t;
  signal line_ctr_r : line_ctr_t;

begin

  sync_cntrs : process (clk_i, rstn_i) is -- line/pxl counters --------------------
  begin 

    if rstn_i = '0' then 

      pxl_ctr_r  <= pxl_ctr_t'high;
      line_ctr_r <= line_ctr_t'high;

    elsif rising_edge(clk_i) then 

      if pxl_ctr_r = pxl_ctr_t'high then

        if line_ctr_r = line_ctr_t'high then -- end of frame
          line_ctr_r <=  0; 
        else -- end of line but not frame
          line_ctr_r <= line_ctr_r + 1; 
        end if;

        pxl_ctr_r <=  0; -- reset px_counter at end of the line

      else 

        pxl_ctr_r <= pxl_ctr_r + 1;

      end if;
    end if;
  end process sync_cntrs; ------------------------------------------------------

  pxl_ctr_o  <= std_logic_vector(to_unsigned(pxl_ctr_r, pxl_ctr_width_c));
  line_ctr_o <= std_logic_vector(to_unsigned(line_ctr_r, line_ctr_width_c));

end architecture;

--------------------------------------------------------------------------------