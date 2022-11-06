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

--             Note: The blank signal is intended to be used by the buffers as a 
--             fault management mechanism. In the future, the memory interface 
--             will probably change to something which provides greater 
--             bandwidth but also most likely a higher latency (e.g. DDR). This 
--             means that there is the potential for memory delays to stall the 
--             buffer logic and cause the memory address counter (mem_addr_r) to
--             fall out of sync with what the required memory value should be. 
--             The planned mitigation for this will be to perform a comparison 
--             between the internal counter value and the externally calculated 
--             'expected' address (disp_addr_ctr_i). If these values do not 
--             match, the blank signal will be set and the pixels in frame will 
--             be 'skipped' until the addresses match again.
--             However, as this is not currently implemented, the associated 
--             values are stubbed.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-25  1.0      TZS     Created
-- 2022-07-17  1.1      TZS     Refactored code to use simpler FSM
-- 2022-07-22  1.2      TZS     Fixed missing state reset state
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity vga_mem_buff is 
  port (
    clk_i           : in  std_logic;
    rstn_i          : in  std_logic; -- reset MUST be synchronous
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
      -- read en needs to be set high during reset to ensure that data can be read
      -- from the memory in the second cycle. This is why a synchronous reset 
      -- deassertion is required.
      mem_ren_r <= '1';

      c_state <= IDLE;

      -- data buffer_r is a custom type and is not trivial to clear.
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

        when IDLE => -----------------------------------------------------------
          -- set signals connected to memory to ensure that there will be data
          -- on the memory dout following the next transition.

          mem_ren_r  <= '1';
          -- no need to check for overflows as memory should constain larger than 2 rows
          mem_addr_r <= mem_addr_r + 1;
          c_state    <= INIT_FIRST_BUFF;
        
        when INIT_FIRST_BUFF => ------------------------------------------------
          -- read data from output of memory and fill first buffer. 
          -- Maintain memory control signals to ensure that second buffer can be filled
          -- following the next transition.  
          -- Update status signals to indicate one buffer is filled.
          

          mem_ren_r <= '0';
          data_buffer_r(buff_wr_sel_r) <= mem_data_s;
          buff_filled_r(buff_wr_sel_r) <= '1';
          buff_wr_sel_r                <= 1;

          c_state <= READ_BUFF_WRITE_OTHER;
        
        when READ_BUFF_WRITE_OTHER => ------------------------------------------
        -- FSM remains in this state until reset. Operations are scheduled using
        -- the index of the pixel which is currently being read of one of the 
        -- buffers. 
        -- One buffer is loaded while the other buffer is read out. Once all
        -- pixels have been read out of the other buffer, the roles switch and the
        -- previously read buffer is now loaded.

          if (buff_filled_r(buff_wr_sel_r) = '0') AND 
             (disp_pxl_ctr_int_s = 0) then 
            -- read memory data into selected buffer if it is not already filled
            -- (note that there is not CURRENTLY a scenario in which this can happen
            --  and the check has been reserved for future use)
            data_buffer_r(buff_wr_sel_r) <= mem_data_s;
            buff_filled_r(buff_wr_sel_r) <= '1';

          elsif (disp_pxl_ctr_int_s = pxl_per_row_c - 2) then
            -- ensure memory signals are set in the last pixel so that data is 
            -- available to be read once the pixel counter resets. 
            mem_ren_r <= '1';
            
            -- check for overflows before incrementing the memory counter
            if mem_addr_r = (mem_depth_c - 1) then
              mem_addr_r <= (others => '0');
            else 
              mem_addr_r <= mem_addr_r + 1;
            end if;

          -- switch buffer designations read_buff <-> write_buff and set filled
          -- status of the previously read buffer to indicate it should now be 
          -- treated as "empty"
          elsif (disp_pxl_ctr_int_s = pxl_per_row_c - 1) then
            
            if buff_wr_sel_r = 0 then 
              buff_wr_sel_r <= 1;
            else   
              buff_wr_sel_r <= 0;
            end if;
          
            buff_filled_r(buff_rd_sel_s) <= '0';
        
          end if;
        
        when others => ---------------------------------------------------------

          c_state <= IDLE;
      
      end case;
      
    
    end if;

  end process; -----------------------------------------------------------------

  -- signal conversions -------------------------------------------------------- 
  gen_assign_mem_data : for pxl_id in 0 to pxl_per_row_c - 1 generate 
    mem_data_s(pxl_id) <= mem_data_i((pxl_id*pxl_width_c)+(pxl_width_c-1) downto (pxl_id*pxl_width_c));  
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