-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : tb_vga_memory_intf.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-28
-- Design     : tb_vga_memory_intf
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Testbench to memory interface module.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-28  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity tb_vga_memory_intf is 
generic (
  CLK_PERIOD : time := 40 ns
);
end entity tb_vga_memory_intf;

--------------------------------------------------------------------------------
architecture tb of tb_vga_memory_intf is

  component vga_memory_intf is 
    port (
      clk_i        : in  std_logic;
      rstn_i       : in  std_logic;
      pxl_ctr_i    : in  std_logic_vector(pxl_ctr_width_c - 1 downto 0);
      line_ctr_i   : in  std_logic_vector(line_ctr_width_c - 1 downto 0);
      disp_blank_o : out std_logic;
      disp_pxl_o   : out pixel_t
    );
  end component;

  signal clk_s, rstn_s : std_logic := '0';
  signal pxl_ctr_s     : unsigned(pxl_ctr_width_c-1 downto 0) := (others => '0');
  signal line_ctr_s    : unsigned(line_ctr_width_c-1 downto 0) := (others => '0');
  signal blank_s       : std_logic;
  signal displ_pxl_s   : pixel_t;

begin --------------------------------------------------------------------------

  clk_gen : process is                                               -----------
  begin    
    while now < 100 ms loop
      clk_s <= '0';
      wait for CLK_PERIOD/2;
      clk_s <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
      assert TRUE 
        report "END OF SIMULATION"
        severity ERROR; 
  end process clk_gen;                                               -----------

  rstn_s <= '1' after CLK_PERIOD * 10;

  -- Process to count pixels and lines in the same fashion that the controller 
  -- uses.
  process (clk_s, rstn_s) is                                         -----------
  begin 
    
    if rstn_s = '0' then 
      
      pxl_ctr_s  <= (others => '0'); 
      line_ctr_s <= (others => '0');  
    
    elsif rising_edge(clk_s) then 
      
      if pxl_ctr_s = pxl_ctr_max_c - 1 then 
        
        if line_ctr_s = line_ctr_max_c - 1 then 
          line_ctr_s <= (others => '0');
        else
          line_ctr_s <= line_ctr_s + 1;
        end if;
        
        pxl_ctr_s <= (others => '0');
      
      else 
        pxl_ctr_s <= pxl_ctr_s + 1;
      end if;
    
    end if;
  end process;                                                       -----------

  i_dut : vga_memory_intf
    port map (
      clk_i        => clk_s,
      rstn_i       => rstn_s,
      pxl_ctr_i    => std_logic_vector(pxl_ctr_s),
      line_ctr_i   => std_logic_vector(line_ctr_s),
      disp_blank_o => blank_s,
      disp_pxl_o   => displ_pxl_s
    );

end architecture tb;

--------------------------------------------------------------------------------