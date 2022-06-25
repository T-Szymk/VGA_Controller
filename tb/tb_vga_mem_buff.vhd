-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : tb_vga_mem_buff.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-25
-- Design     : tb_vga_mem_buff
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Testbench to run buff module.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-25  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity tb_vga_mem_buff is 
generic (
  CLK_PERIOD : time := 40 ns
);
end entity tb_vga_mem_buff;

--------------------------------------------------------------------------------
architecture tb of tb_vga_mem_buff is

  component vga_mem_buff is 
    port (
      clk_i           : in  std_logic;
      rstn_i          : in  std_logic;
      disp_addr_ctr_i : in  std_logic_vector(mem_addr_width_c-1 downto 0);
      disp_pxl_ctr_i  : in  std_logic_vector(row_ctr_width_c-1 downto 0);
      mem_data_i      : in  std_logic_vector(mem_row_width_c-1 downto 0);
      mem_addr_o      : out std_logic_vector(mem_addr_width_c-1 downto 0);
      disp_blank_o    : out std_logic;
      disp_pxl_o      : out pixel_t
    );
    end component;

  signal clk_s, rstn_s   : std_logic := '0';
  signal disp_addr_ctr_s : unsigned(mem_addr_width_c-1 downto 0);       
  signal disp_pxl_ctr_s  : unsigned(row_ctr_width_c-1 downto 0);      
  signal mem_data_s      : unsigned(mem_row_width_c-1 downto 0);  
  signal mem_addr_s      : std_logic_vector(mem_addr_width_c-1 downto 0);  
  signal disp_blank_s    : std_logic;    
  signal disp_pxl_s      : pixel_t;

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

  addr_ctr : process (clk_s, rstn_s) is 
  begin 
    if rstn_s = '0' then 
      disp_addr_ctr_s <= (others => '0');
      disp_pxl_ctr_s  <= (others => '0');
      mem_data_s      <= (others => '0');
    elsif rising_edge(clk_s) then
      if disp_pxl_ctr_s = (pxl_per_row_c - 1) then 
        disp_pxl_ctr_s  <= (others => '0');
        disp_addr_ctr_s <= disp_addr_ctr_s + 1;
        mem_data_s      <= mem_data_s + 1;
      else
        disp_pxl_ctr_s  <= disp_pxl_ctr_s + 1;
      end if;
    end if;
  end process addr_ctr;

  i_dut : vga_mem_buff
    port map (
      clk_i           => clk_s,   
      rstn_i          => rstn_s,    
      disp_addr_ctr_i => std_logic_vector(disp_addr_ctr_s),             
      disp_pxl_ctr_i  => std_logic_vector(disp_pxl_ctr_s),            
      mem_data_i      => std_logic_vector(mem_data_s),        
      mem_addr_o      => mem_addr_s,              
      disp_blank_o    => disp_blank_s,          
      disp_pxl_o      => disp_pxl_s       
    );

end architecture tb;

--------------------------------------------------------------------------------