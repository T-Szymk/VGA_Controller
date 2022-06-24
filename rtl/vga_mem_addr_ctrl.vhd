-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Address Controller
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_mem_addr_ctrl.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-24
-- Design     : vga_mem_addr_ctrl
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to contain logic related to reading image data from BRAM
--              and returning it for use by the VGA controller
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-24  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity vga_mem_addr_ctrl is
  generic (
    DEBUG : boolean := TRUE
  );
  port(
    clk_i      : in std_logic;
    rstn_i     : in std_logic;
    pxl_ctr_i  : in std_logic_vector(pxl_ctr_width_c - 1 downto 0);
    line_ctr_i : in std_logic_vector(line_ctr_width_c - 1 downto 0)
  );
end entity vga_mem_addr_ctrl;

--------------------------------------------------------------------------------

architecture rtl of vga_mem_addr_ctrl is 

  signal disp_pxl_ctr_r : unsigned(disp_pxl_depth_c - 1 downto 0) := (others => '0');

  signal line_ctr_s : line_ctr_t := 0;
  signal pxl_ctr_s  : pxl_ctr_t  := 0;

  signal mem_pxl_ctr_r  : unsigned(row_ctr_width_c - 1 downto 0) := (others => '0');
  signal mem_addr_ctr_r : unsigned(mem_addr_width_c - 1 downto 0) := (others => '0');

begin
  -- cast counters to more readable types
  line_ctr_s <= to_integer(unsigned(line_ctr_i));
  pxl_ctr_s  <= to_integer(unsigned(pxl_ctr_i));

  mem_ctr : process (clk_i, rstn_i) is 
  begin 
    if rstn_i = '0' then 
      
      mem_pxl_ctr_r  <= (others => '0');
      mem_addr_ctr_r <= (others => '0');
    
    elsif rising_edge(clk_i) then
      -- if the line counter is within the visible region and if the pixel counter is in the visible region
      if line_ctr_s > (v_b_porch_max_lns_c - 1) AND line_ctr_s < v_disp_max_lns_c AND
         pxl_ctr_s > (h_b_porch_max_px_c - 1) AND pxl_ctr_s < h_disp_max_px_c then
          
            if mem_pxl_ctr_r = (pxl_per_row_c - 1) then
              
              mem_pxl_ctr_r <= (others => '0');
              
              if mem_addr_ctr_r = (mem_depth_c - 1) then 
                mem_addr_ctr_r <= (others => '0');
              else 
                mem_addr_ctr_r <= mem_addr_ctr_r + 1;
              end if;

            else
              mem_pxl_ctr_r <= mem_pxl_ctr_r + 1; 
            end if;
        
      end if;
    end if;
  end process mem_ctr;

  -- below only needed for debugging
  gen_disp_ctr : if DEBUG = TRUE generate

    disp_ctr : process (clk_i, rstn_i) is 
    begin 
      if rstn_i = '0' then 
        
        disp_pxl_ctr_r <= (others => '0');
      
      elsif rising_edge(clk_i) then
        -- if the line counter is within the visible region and if the pixel counter is in the visible region
        if line_ctr_s > (v_b_porch_max_lns_c - 1) AND line_ctr_s < v_disp_max_lns_c AND
           pxl_ctr_s > (h_b_porch_max_px_c - 1) AND pxl_ctr_s < h_disp_max_px_c then
            
              if disp_pxl_ctr_r = (disp_pxl_max_c - 1) then
                disp_pxl_ctr_r <= (others => '0');
              else
                disp_pxl_ctr_r <= disp_pxl_ctr_r + 1; 
              end if;
          
        end if;
      end if;
    end process disp_ctr;

end generate gen_disp_ctr;

end architecture rtl;

--------------------------------------------------------------------------------