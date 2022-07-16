-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Buffers
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
-- 2022-07-16  1.1      TZS     Refactored code to use simpler FSM
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity vga_mem_buff is 
  port (
    clk_i           : in  std_logic;
    rstn_i          : in  std_logic;
    disp_addr_ctr_i : in  std_logic_vector(mem_addr_width_c-1 downto 0);
    disp_pxl_ctr_i  : in  std_logic_vector(row_ctr_width_c-1 downto 0);
    mem_data_i      : in  std_logic_vector(mem_row_width_c-1 downto 0);
    mem_addr_o      : out std_logic_vector(mem_addr_width_c-1 downto 0);
    mem_ren_o       : out std_logic;
    disp_blank_o    : out std_logic;
    disp_pxl_o      : out pixel_t
  );
end entity vga_mem_buff;

--------------------------------------------------------------------------------
architecture rtl OF vga_mem_buff IS

  type state_t is (IDLE, INIT_FIRST_BUFF, READ_BUFF_WRITE_OTHER);
  type buffer_t is array (1 downto 0) of pixel_word_t;
    
  signal c_state       : state_t;
  signal disp_pxl_s    : pixel_t;
  signal data_buffer_r : buffer_t;
  signal mem_data_s    : pixel_word_t;

  signal buff_filled_r : std_logic_vector(1 downto 0);

  signal mem_ren_r, 
         disp_blank_s : std_logic;

  signal buff_wr_sel_r     : integer range 1 downto 0 := 0;
  signal buff_rd_sel_s     : integer range 1 downto 0 := 0;

  signal disp_pxl_ctr_int_s : integer range pxl_per_row_c downto 0 := 0;

  signal mem_addr_r : unsigned(mem_addr_width_c-1 downto 0);
  
begin --------------------------------------------------------------------------

  -- single process FSM
  process (clk_i, rstn_i) is ---------------------------------------------------
  begin 

    if rstn_i = '0' then 
  
      mem_ren_r <= '1';

      for idx in 0 to pxl_per_row_c - 1 loop
        data_buffer_r(0)(idx) <= (others => '0');
        data_buffer_r(1)(idx) <= (others => '0');
      end loop;      

        mem_addr_r    <= (others => '0');
        buff_filled_r <= (others => '0');
        buff_wr_sel_r <= 0;

    elsif rising_edge(clk_i) then 

      mem_ren_r     <= '0';
      data_buffer_r <= data_buffer_r;
      mem_addr_r    <= mem_addr_r;
      buff_filled_r <= buff_filled_r;
      buff_wr_sel_r <= buff_wr_sel_r;
      c_state       <= c_state;

    
      case (c_state) is 

        when IDLE =>

          mem_ren_r  <= '1';
          -- no need to check for overflows as memory should constain larger than 2 rows
          mem_addr_r <= mem_addr_r + 1;
          c_state    <= INIT_FIRST_BUFF;
        
        when INIT_FIRST_BUFF =>

          mem_ren_r <= '0';
          data_buffer_r(buff_wr_sel_r) <= mem_data_s;
          buff_filled_r(buff_wr_sel_r) <= '1';
          buff_wr_sel_r                <= 1;

          c_state <= READ_BUFF_WRITE_OTHER;
        
        when READ_BUFF_WRITE_OTHER =>

          if (buff_filled_r(buff_wr_sel_r) = '0') AND 
             (disp_pxl_ctr_int_s = 0) then 
            
            data_buffer_r(buff_wr_sel_r) <= mem_data_s;
            buff_filled_r(buff_wr_sel_r) <= '1';

          elsif (disp_pxl_ctr_int_s = pxl_per_row_c - 2) then

            mem_ren_r <= '1';
            mem_addr_r <= mem_addr_r + 1;

          elsif (disp_pxl_ctr_int_s = pxl_per_row_c - 1) then

            buff_wr_sel_r <= 1 when buff_wr_sel_r = 0 else 0;
          
            buff_filled_r(buff_rd_sel_s) <= '0';
        
          end if;
        
        when others =>

          c_state <= IDLE;
      
      end case;
      
    
    end if;

  end process; -----------------------------------------------------------------

  -- signal conversions --------------------------------------------------------
  gen_assign_mem_data : for idx in 0 to pxl_per_row_c - 1 generate 
    mem_data_s(idx) <= mem_data_i((idx*pxl_width_c)+pxl_width_c-1 downto (idx*pxl_width_c));  
  end generate gen_assign_mem_data;

  disp_pxl_ctr_int_s <= to_integer(unsigned(disp_pxl_ctr_i));

  buff_rd_sel_s <= 1 when buff_wr_sel_r = 0 else 0;

  disp_blank_s <= '0';

  -- output assignments --------------------------------------------------------
  disp_pxl_s   <= data_buffer_r(buff_rd_sel_s)(disp_pxl_ctr_int_s);
  disp_pxl_o   <= disp_pxl_s;
  disp_blank_o <= disp_blank_s;
  mem_addr_o   <= std_logic_vector(mem_addr_r);
  mem_ren_o    <= mem_ren_r;

end architecture rtl;

--------------------------------------------------------------------------------