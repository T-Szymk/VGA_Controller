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
--              Write takes precedence over read if both are asserted on an 
--              empty FIFO. 
--              If FIFO is full, a write and read can be completed in the same 
--              cycle.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-03-11  1.1      TZS     Created
-- 2022-04-18  1.2      TZS     Added comments
-- 2022-04-02  1.3      TZS     Added almost empty/full
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
  	clk          : in  std_logic;
  	clr_n_in     : in  std_logic;
  	we_in        : in  std_logic;
  	rd_in        : in  std_logic;
  	data_in      : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);
  	empty_out    : out std_logic;
  	full_out     : out std_logic;
    al_empty_out : out std_logic;
    al_full_out  : out std_logic;
  	data_out     : out std_logic_vector(FIFO_WIDTH - 1 downto 0)
	);
end entity sync_fifo;

--------------------------------------------------------------------------------

architecture rtl of sync_fifo is 

  type fifo_block_t is array(FIFO_DEPTH - 1 downto 0) of std_logic_vector(FIFO_WIDTH-1 downto 0);

  signal full_s     : std_logic := '0';
  signal empty_s    : std_logic := '1';
  signal al_empty_s : std_logic := '0';  
  signal al_full_s  : std_logic := '0';
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
        -- set all entries to 0 and reset pointer when clear is LOW
        for idx in 0 to FIFO_DEPTH - 1 loop
          fifo_block_r(idx) <= (others => '0');
        end loop;

        wr_ptr_s <= 0;

      else 
        -- TWO conditions when data can be written in:
        -- 1) FIFO has space
        -- 2) FIFO is full but is being read and therefore creating space.
        if (full_s = '0' and we_in = '1') or (we_in = '1' and rd_in = '1') then
            
          fifo_block_r(wr_ptr_s) <= data_in;
          
          -- wrap pointer at max address
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
        -- reset pointer when clear is LOW
        rd_ptr_s <= 0;

      else 
        -- read ONLY checks empty and read_in
        if (empty_s = '0' and rd_in = '1') then
            
          data_out_r <= fifo_block_r(rd_ptr_s);
          
          -- wrap pointer at max address
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
        -- increment counter if data is added
        -- decrement counter if data is removed
        -- don't touch counter if data is added & removed within the same cycle
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

  -- almost empty/full comb
  al_process : process (data_cnt_r) is -----------------------------------------
  begin
  
    al_empty_s <= '1' when data_cnt_r = 1 else '0';
    al_full_s  <= '1' when data_cnt_r = (FIFO_DEPTH - 1 ) else '0';

  end process al_process; ------------------------------------------------------

  full_s  <= '1' when data_cnt_r = FIFO_DEPTH else '0';
  empty_s <= '1' when data_cnt_r = 0 else '0'; 

  data_out  <= data_out_r;
  empty_out <= empty_s;
  full_out  <= full_s;
  al_empty_out <= al_empty_s;
  al_full_out  <= al_full_s;

end architecture rtl;

--------------------------------------------------------------------------------