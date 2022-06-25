-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
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
    disp_blank_o    : out std_logic;
    disp_pxl_o      : out pixel_t
  );
end entity vga_mem_buff;

--------------------------------------------------------------------------------
architecture rtl OF vga_mem_buff IS

  type state_t is (RESET, IDLE_RST, IDLE_RUN, INIT_A, FILL_A, FILL_B);
  
  -- FSM signals
  signal c_state, n_state   : state_t := RESET;
  signal fill_A_r, fill_B_r : std_logic := '0';
  signal last_buff_pxl_s    : std_logic := '0';
  signal buff_wr_sel_r      : std_logic := '0'; -- A: 0, B: 1
  signal buff_rd_sel_r      : std_logic := '0'; -- A: 0, B: 1

  -- pixel buffers
  signal buff_A_r, buff_B_r : pixel_word_t;
  -- buffer mgmt signals
  signal buff_A_addr_r, buff_B_addr_r : unsigned(mem_addr_width_c-1 downto 0);
  signal disp_pxl_ctr_s : unsigned(row_ctr_width_c-1 downto 0);
  -- module output registers
  signal mem_addr_r   : unsigned(mem_addr_width_c-1 downto 0);
  signal disp_blank_s : std_logic;
  signal disp_pxl_s   : pixel_t;

BEGIN  -------------------------------------------------------------------------

  -- synchronous current state assignment
  sync_cstate : process (clk_i, rstn_i) is -------------------------------------
  begin 
    if rstn_i = '0' then
      c_state <= RESET; 
    elsif rising_edge(clk_i) then 
      c_state <= n_state;
    end if;
  end process sync_cstate; -----------------------------------------------------
  
  -- combinational next state assignment
  comb_nstate : process (all) is -----------------------------------------------
  begin 
    -- default assignment
    n_state <= c_state;
    
    case c_state is                                                 ------------

      when RESET =>
        n_state <= IDLE_RST;

      when IDLE_RST =>                                                    ------     
        n_state <= INIT_A;

      when INIT_A =>                                                      ------       
        -- if first time, fill buffer A address + data, then move on to FILL_B_READ_A,
        n_state <= FILL_B;

      when IDLE_RUN =>                                                    ------     
        -- switch buffers when last pixel in word is being displayed
        if last_buff_pxl_s = '1' then 
          if buff_wr_sel_r = '0' then
            n_state <= FILL_A;
          else 
            n_state <= FILL_B;
          end if;
        else 
          n_state <= c_state;
        end if;
      
      when FILL_A =>                                                      ------              
          n_state <= IDLE_RUN;

      when FILL_B =>                                                      ------              
        n_state <= IDLE_RUN;
      
      when OTHERS =>                                                      ------       
        n_state <= IDLE_RST;
    
    end case;                                                       ------------

  end process comb_nstate; -----------------------------------------------------
  
  -- synchronous output assignment
  sync_outp : process (clk_i, rstn_i) is ---------------------------------------
  begin

    if rstn_i = '0' then 

      fill_A_r      <= '0';
      fill_B_r      <= '0';
      buff_rd_sel_r <= '0';

    elsif rising_edge(clk_i) then

      fill_A_r      <= '0';
      fill_B_r      <= '0';
      buff_rd_sel_r <= buff_rd_sel_r;

      case n_state is                                               ------------

        when RESET =>                                                     ------

        when IDLE_RST =>                                                  ------  
          
        when INIT_A =>                                                    ------    
          fill_A_r <= '1';

        when IDLE_RUN =>                                                  ------

        when FILL_A =>                                                    ------           
          fill_A_r      <= '1';
          buff_rd_sel_r <= '1';
        
        when FILL_B =>                                                    ------           
          fill_B_r      <= '1';
          buff_rd_sel_r <= '0';

        when OTHERS =>                                                    ------    


      end case;                                                     ------------
    
    end if;

  end process sync_outp;  ------------------------------------------------------
  
  -- process used to write buffers from memory
  sync_buff_wr : process (clk_i, rstn_i) is 
  begin 
    if rstn_i = '0' then 
      
      -- set buffers to 0 on reset
      buff_clr(buff_A_r);
      buff_clr(buff_B_r);
      mem_addr_r     <= (others => '0');
      buff_A_addr_r  <= (others => '0');
      buff_B_addr_r  <= (others => '0');
      buff_wr_sel_r <= '0';

    elsif rising_edge(clk_i) then 
      -- memory data should be ready on the line, so read it into BUFF_A then
      -- increment the address 
      if fill_A_r = '1' then 
        buff_A_addr_r <= mem_addr_r;
        mem_addr_r <= mem_addr_r + 1;
        buff_fill(mem_data_i, buff_A_r);
        buff_wr_sel_r <= '1';
      end if;

      -- equivalent for BUFF_B
      if fill_B_r = '1' then 
        buff_B_addr_r <= mem_addr_r;
        mem_addr_r <= mem_addr_r + 1;
        buff_fill(mem_data_i, buff_B_r);
        buff_wr_sel_r <= '0';
      end if;

    end if;
  end process sync_buff_wr; ----------------------------------------------------

  
  -- use input pixel counter if the selected buffer address matches the expected
  -- address value from the addr_ctrl module. This is to prevent address 
  -- misalignment from propagating through the design.
  comb_pxl_ctr: process (all) is -----------------------------------------------
  begin 
    if (buff_rd_sel_r = '0' AND std_logic_vector(buff_A_addr_r) = disp_addr_ctr_i) OR 
       (buff_rd_sel_r = '1' AND std_logic_vector(buff_B_addr_r) = disp_addr_ctr_i) then
      disp_pxl_ctr_s <= unsigned(disp_pxl_ctr_i);
      disp_blank_s   <= '0';
    else 
      disp_pxl_ctr_s <= (others => '0');
      disp_blank_s   <= '1';
    end if;
  end process comb_pxl_ctr;

  -- output pixel value logic
  disp_pxl_s <= buff_A_r(to_integer(disp_pxl_ctr_s)) WHEN buff_rd_sel_r = '0' ELSE 
                buff_B_r(to_integer(disp_pxl_ctr_s));
  -- pulse to indicate final pixel in word, used to drive state machine
  last_buff_pxl_s <= '1' WHEN disp_pxl_ctr_s = (pxl_per_row_c - 1) ELSE '0';

  -- output assignments --------------------------------------------------------

  mem_addr_o   <= std_logic_vector(mem_addr_r);
  disp_blank_o <= disp_blank_s;
  disp_pxl_o   <= disp_pxl_s;

end architecture rtl;

--------------------------------------------------------------------------------