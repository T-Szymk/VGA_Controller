-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Line Buffer Controller
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_line_buff_ctrl.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-24
-- Design     : vga_line_buff_ctrl
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to control the reading/writing of line buffers.  
--              A buffer is only written to if it is marked as empty (!full),
--              A buffer is only read from if it is marked as full.
--              This provides interlocking and prevents the line buffers from
--              being read/written at the same time. 
--
--              A limitation of this is that if the line buffer write process 
--              takes too long , the displayed pixels with fall out of sync. 
--              However, as the time window available for write is large when 
--              using tiling (e.g. with a tile size of 4, each line write has a 
--              minimum of 4x the amount of time required to read an entire line
--              available), it is not realistic that a write would exceed it.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-24  1.0      TZS     Created
-- 2022-07-16  1.1      TZS     Updates made for integration with mem intf model
-- 2022-11-12  1.2      TZS     Changed name and refactored design to allow 
--                              elastic reading/writing of buffers.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
use work.vga_pkg.all;

entity vga_line_buff_ctrl is
  generic (
    width_px_g          : integer := 640; 
    height_lns_g        : integer := 480;
    lbuff_latency_g     : integer :=   1; -- latency of line buffer memory operations in cycles
    h_b_porch_max_px_g  : integer := 144;
    v_b_porch_max_lns_g : integer :=  35;
    tile_width_g        : integer :=   4;
    pxl_ctr_width_g     : integer :=  10;
    ln_ctr_width_g      : integer :=  10;
    tile_per_line_g     : integer := 160;
    tile_ctr_width_g    : integer :=   8
  );
  port(
    clk_i            : in  std_logic;    
    rstn_i           : in  std_logic;     
    buff_fill_done_i : in  std_logic_vector(1 downto 0);               
    pxl_cntr_i       : in  std_logic_vector(pxl_ctr_width_g-1 downto 0);         
    ln_cntr_i        : in  std_logic_vector(ln_ctr_width_g-1 downto 0);        
    buff_fill_req_o  : out std_logic_vector(1 downto 0);              
    buff_sel_o       : out std_logic_vector(1 downto 0);         
    disp_pxl_id_o    : out std_logic_vector(tile_ctr_width_g-1 downto 0)          
  );
end entity vga_line_buff_ctrl;

--------------------------------------------------------------------------------

architecture rtl of vga_line_buff_ctrl is 

---- SIGNALS/CONSTANTS/VARIABLES/TYPES -----------------------------------------

  type read_buff_states_t is (READ_BUFF_RESET, INIT, READ_BUFF_A, READ_BUFF_B);
  type fill_buff_states_t is (FILL_BUFF_RESET, FILL_A, FILL_B);

  constant disp_start_px_c : integer := h_b_porch_max_px_g - lbuff_latency_g;
  constant disp_end_px_c   : integer := h_b_porch_max_px_g + width_px_g - lbuff_latency_g;

  constant disp_start_lns_c : integer := v_b_porch_max_lns_g;
  constant disp_end_lns_c   : integer := v_b_porch_max_lns_g + height_lns_g;
  
  -- width of counter which is used to count either the number of pixels or lines within a tile
  constant tile_pxl_ctr_width_c : integer := (INTEGER(CEIL(LOG2(REAL(tile_width_g - 1))))); 

  signal last_disp_pixel_s : std_logic; -- pulse which is 1 for a cycle during the final cycle of the last pixel in the display buffer 
  signal counter_en_s      : std_logic; -- register enable used to control display counters
  
  -- used to determine which buffer is used to source display pixel (one-hot encoded)
  signal buff_sel_r : std_logic_vector(1 downto 0);
  -- signal used to indicate that line buffer should be filled from frame buffer
  signal buff_fill_req_r : std_logic_vector(1 downto 0);
  signal buff_full_r     : std_logic_vector(1 downto 0); 

  signal disp_pxl_id_r : unsigned(tile_ctr_width_g-1 downto 0);
  
  signal tile_pxl_cntr_r : unsigned(tile_pxl_ctr_width_c-1 downto 0);
  signal tile_lns_cntr_r : unsigned(tile_pxl_ctr_width_c-1 downto 0);

  signal read_buff_state_r : read_buff_states_t;
  signal fill_buff_state_r : fill_buff_states_t;


begin --------------------------------------------------------------------------

  ---- READ BUFFER FSM ---------------------------------------------------------
  read_buff_fsm : process (clk_i, rstn_i) is -----------------------------------
  begin 
    
    if rstn_i = '0' then 

      read_buff_state_r <= READ_BUFF_RESET;
      buff_sel_r        <= "00";

    elsif rising_edge(clk_i) then 

      case read_buff_state_r is 
      
        when READ_BUFF_RESET =>                                             ----
          
          read_buff_state_r <= INIT;
        
        when INIT =>                                                        ----
          
          -- only begin reading from buffer A once buffer A has been filled
          if buff_full_r(0) = '1' then
            read_buff_state_r <= READ_BUFF_A;
            buff_sel_r        <= "01"; 
          end if;

        when READ_BUFF_A =>                                                 ----

          -- switch to reading from buffer B once last pixel of buffer A is 
          -- being displayed and buffer B has been filled
          if (last_disp_pixel_s = '1') and (buff_full_r(1) ='1') then 
           read_buff_state_r <= READ_BUFF_B;
           buff_sel_r        <= "10";
          end if;
        
        when READ_BUFF_B =>                                                 ---- 
        
          -- switch to reading from buffer A once last pixel of buffer B is 
          -- being displayed and buffer A has been filled */
          if (last_disp_pixel_s = '1') and (buff_full_r(0) = '1') then 
           read_buff_state_r <= READ_BUFF_A;
           buff_sel_r        <= "01";
          end if;

        when others =>                                                      ----
          read_buff_state_r <= READ_BUFF_RESET;

      end case;
    end if;
  end process read_buff_fsm; ---------------------------------------------------

  ---- FILL BUFFER FSM ---------------------------------------------------------
  fill_buff_fsm : process (clk_i, rstn_i) is -----------------------------------
  begin 

    if rstn_i = '0' then 

      fill_buff_state_r <= FILL_BUFF_RESET;
      buff_fill_req_r   <= (others => '0');

    elsif rising_edge(clk_i) then 

      case fill_buff_state_r is

        when FILL_BUFF_RESET =>                                             ----    
        
          fill_buff_state_r <= FILL_A;
          buff_fill_req_r   <= "01"; -- send fill request pulse for line buffer A                 
        
        when FILL_A =>                                                      ----
        
          buff_fill_req_r <= "00";
            
          -- If A is full and B is empty (i.e. B has been read from)
          if buff_full_r = "01" then 
            fill_buff_state_r <= FILL_B;
            buff_fill_req_r   <= "10";
          end if;

        when FILL_B =>                                                      ----    
        
          buff_fill_req_r <= "00";
            
          -- If B is full and A is empty (i.e. A has been read from)
          if buff_full_r = "10" then 
            fill_buff_state_r <= FILL_A;
            buff_fill_req_r   <= "01";
          end if;

        when others =>                                                      ----     
        
          fill_buff_state_r <= FILL_BUFF_RESET;

      end case;
    end if;
  end process fill_buff_fsm; ---------------------------------------------------

  ---- DISPLAY PIXEL COUNTER LOGIC ---------------------------------------------
  disp_ctr_logic : process (clk_i, rstn_i) is ---------------------------------- 
  begin 

    if rstn_i = '0' then 

      disp_pxl_id_r   <= (others => '0');
      tile_pxl_cntr_r <= (others => '0');
      tile_lns_cntr_r <= (others => '0');

    elsif rising_edge(clk_i) then 

      -- each pixel is displayed for tile_width_g cycles and each line is repeated 
      -- tile_width_g times
      if tile_pxl_cntr_r = (tile_width_g - 1) and (counter_en_s = '1') then 
        
        tile_pxl_cntr_r <= (others => '0');
         
        if disp_pxl_id_r = (tile_per_line_g - 1) then
          
          disp_pxl_id_r <= (others => '0');
           
          if tile_lns_cntr_r = (tile_width_g - 1) then
            tile_lns_cntr_r <= (others => '0');
          else 
            tile_lns_cntr_r <= (tile_lns_cntr_r + 1);
          end if;
            
        else -- if disp_pxl_id_r = (tile_per_line_g - 1) then
         
          disp_pxl_id_r <= disp_pxl_id_r + 1;
        
        end if;
         
      elsif (counter_en_s = '1') then 
      
        tile_pxl_cntr_r <= tile_pxl_cntr_r + 1;
      
      end if;
    end if;
  end process disp_ctr_logic; --------------------------------------------------

  ---- BUFFER EMPTY/FULL LOGIC -------------------------------------------------
  gen_buff_idx : for buff_idx in 0 to 1 generate -------------------------------
    
    buff_empty_full : process (clk_i, rstn_i) is -------------------------------
    begin
    
      if rstn_i = '0' then
        
        buff_full_r(buff_idx) <= '0';
        
      elsif rising_edge(clk_i) then 

        -- set buff_full once confirmation received from buffer that fill is complete
        if buff_fill_done_i(buff_idx) = '1' then 
          
          buff_full_r(buff_idx) <= '1';

        elsif last_disp_pixel_s = '1' then  -- if last display pixel signal is active, clear full status of buffer being read
        
          if buff_sel_r(buff_idx) = '1' then 
            
            buff_full_r(buff_idx) <= '0';
          
          end if;
        end if;
      end if;
    end process buff_empty_full; -----------------------------------------------

  end generate gen_buff_idx; ---------------------------------------------------

  ---- COUNTER ENABLE LOGIC ----------------------------------------------------
  comb_counter_en: process (ln_cntr_i, pxl_cntr_i) is --------------------------

    variable pxl_cntr_s : unsigned(pxl_ctr_width_g-1 downto 0);
    variable ln_cntr_s  : unsigned(ln_ctr_width_g-1 downto 0);

  begin 
    -- variables used for converting values in conditional statements 
    pxl_cntr_s := unsigned(pxl_cntr_i);
    ln_cntr_s  := unsigned(ln_cntr_i);

    if (ln_cntr_s >= disp_start_px_c) and 
       (ln_cntr_s <  disp_end_px_c) then 

      if (pxl_cntr_s >= disp_start_lns_c) and 
         (pxl_cntr_s < disp_end_lns_c) then 

        counter_en_s <= '1';

      else
        
        counter_en_s <= '0';
      
      end if;

    else 

      counter_en_s <= '0';

    end if;

  end process comb_counter_en; -------------------------------------------------
  
  ---- LAST PIXEL LOGIC --------------------------------------------------------
  comb_last_pxl : process (tile_lns_cntr_r, disp_pxl_id_r, tile_pxl_cntr_r) is 
  begin 

    -- during the last cycle of the display pixel of a buffer, set last_disp_pixel to 1
    if (tile_lns_cntr_r = (tile_width_g - 1)) and 
       (disp_pxl_id_r   = (tile_per_line_g - 1)) and 
       (tile_pxl_cntr_r = (tile_width_g - 1) ) then
 
      last_disp_pixel_s <= '1';

    else

      last_disp_pixel_s <= '0';
    
    end if;
  end process comb_last_pxl; ---------------------------------------------------
  
  ------------------------------------------------------------------------------

  ---- OUTPUT ASSIGNMENTS --------------------------------------------------------

  buff_fill_req_o <= buff_fill_req_r;
  buff_sel_o      <= buff_sel_r;
  disp_pxl_id_o   <= std_logic_vector(disp_pxl_id_r);

end architecture rtl; ----------------------------------------------------------

--------------------------------------------------------------------------------