-------------------------------------------------------------------------------
-- Title      : VGA Controller - Synchronous FIFO
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : sync_fifo.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-03-17
-- Design     : sync_fifo
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Synchronous FIFO structure 
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-03-11  1.1      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity sync_fifo is 
  generic (
  	FIFO_WIDTH : integer := 36;
  	FIFO_DEPTH : integer := 10
  );
  port (
  	clk       : in  std_logic;
  	clr_n_in  : in  std_logic;
  	we_in     : in  std_logic;
  	rd_in     : in  std_logic;
  	data_in   : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);
  	empty_out : out std_logic;
  	full_out  : out std_logic;
  	data_out  : out std_logic_vector(FIFO_WIDTH - 1 downto 0)
	);
end entity sync_fifo;

--------------------------------------------------------------------------------

architecture rtl of sync_fifo is 

  type fifo_block_t is array(FIFO_DEPTH - 1 downto 0) of std_logic_vector(FIFO_WIDTH-1 downto 0);

  signal full_s     : std_logic := '0';
  signal empty_s    : std_logic := '1';
  signal data_out_r : std_logic_vector(FIFO_WIDTH - 1 downto 0) := (others => '0');
  signal wr_ptr_s   : integer range FIFO_DEPTH - 1 downto 0 := 0;
  signal rd_ptr_s   : integer range FIFO_DEPTH - 1 downto 0 := 0;
  signal data_cnt_r : integer range FIFO_DEPTH downto 0 := 0;

  signal fifo_block_r : fifo_block_t;

begin 

  write_process : process (clk) is ---------------------------------------------
  begin 
  
    if rising_edge(clk) then
      if clr_n_in = '0' then 

        for idx in 0 to FIFO_DEPTH - 1 loop
          fifo_block_r(idx) <= (others => '0');
        end loop; 

        wr_ptr_s <= 0;

      else 
        if (full_s = '0' and we_in = '1') or (we_in = '1' and rd_in = '1') then
            
          fifo_block_r(wr_ptr_s) <= data_in;
            
          if wr_ptr_s = FIFO_DEPTH - 1 then 
            wr_ptr_s <= 0;
          else 
            wr_ptr_s <= wr_ptr_s + 1;
          end if; 
          
        end if;
      end if;
    end if;
  
  end process write_process; ---------------------------------------------------

  read_process : process (clk) is ----------------------------------------------
  begin 
  
    if rising_edge(clk) then
      if clr_n_in = '0' then 
      
        rd_ptr_s <= 0;

      else 
        if (empty_s = '0' and rd_in = '1') then
            
          data_out_r <= fifo_block_r(rd_ptr_s);
            
          if rd_ptr_s = FIFO_DEPTH - 1 then 
            rd_ptr_s <= 0;
          else 
            rd_ptr_s <= rd_ptr_s + 1;
          end if; 
          
        end if;
      end if;
    end if;

  end process; -----------------------------------------------------------------

  
  count_process : process (clk) is --------------------------------------------- 
  begin 

    if rising_edge(clk) then 
      if clr_n_in = '0' then 
      
        data_cnt_r <= 0;

      else
        if we_in = '1' and data_cnt_r /= FIFO_DEPTH and rd_in = '0' then 
            data_cnt_r <= data_cnt_r + 1; 
        elsif rd_in = '1' and data_cnt_r /= 0 and we_in = '0' then
          data_cnt_r <= data_cnt_r - 1; 
        elsif rd_in = '1' and we_in = '1' and data_cnt_r = 0 then
          data_cnt_r <= 1;
        end if;
      end if;
    end if;

  end process count_process; ---------------------------------------------------

  full_s  <= '1' when data_cnt_r = FIFO_DEPTH else '0';
  empty_s <= '1' when data_cnt_r = 0 else '0'; 

  data_out  <= data_out_r;
  empty_out <= empty_s;
  full_out  <= full_s;

end architecture rtl;

--------------------------------------------------------------------------------