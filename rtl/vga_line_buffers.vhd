-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Line Buffers
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_line_buffers.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-25
-- Design     : vga_line_buffers
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to contain ping-pong buffers and logic to control display
--              datapath between the memory and the VGA controller.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-25  1.0      TZS     Created
-- 2022-07-17  1.1      TZS     Refactored code to use simpler FSM
-- 2022-07-22  1.2      TZS     Fixed missing state reset state
-- 2022-11-13  1.2      TZS     Changed name and refactored design to be used in 
--                              combination with line_buff_control module.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;


entity vga_line_buffers is 
  generic (
    pxl_width_g        : integer :=   12;           
    tile_width_g       : integer :=    4;
    fbuff_depth_g      : integer := 4800;        
    fbuff_addr_width_g : integer :=   13;             
    fbuff_data_width_g : integer :=   48;
    lbuff_addr_width_g : integer :=    8;          
    tiles_per_row_g    : integer :=    4;          
    tile_per_line_g    : integer :=  160 -- 640 / 4    
  );
  port(
    clk_i            : in  std_logic;     
    rstn_i           : in  std_logic;      
    buff_fill_req_i  : in  std_logic_vector(1 downto 0);               
    buff_sel_i       : in  std_logic_vector(1 downto 0);          
    disp_pxl_id_i    : in  std_logic_vector(lbuff_addr_width_g-1 downto 0);             
    fbuff_data_i     : in  std_logic_vector(fbuff_data_width_g-1 downto 0);            
    fbuff_rd_rsp_i   : in  std_logic;              
    buff_fill_done_o : out std_logic_vector(1 downto 0);                
    disp_pxl_o       : out std_logic_vector(pxl_width_g-1 downto 0);          
    fbuff_rd_req_o   : out std_logic;              
    fbuff_addra_o    : out std_logic_vector(fbuff_addr_width_g-1 downto 0)            
  );
end entity vga_line_buffers;

--------------------------------------------------------------------------------
architecture rtl OF vga_line_buffers IS
  
  ---- COMPONENT DECLARATIONS --------------------------------------------------
  
  component xilinx_sp_BRAM  
    generic (
      RAM_WIDTH  : integer := 18;
      RAM_DEPTH  : integer := 2048;
      ADDR_WIDTH : integer := 8;
      INIT_FILE  : string  := ""
    );
    port (
      addra : in  std_logic_vector(ADDR_WIDTH-1 downto 0);      
      dina  : in  std_logic_vector(RAM_WIDTH-1 downto 0);      
      clka  : in  std_logic;      
      wea   : in  std_logic;     
      ena   : in  std_logic;     
      douta : out std_logic_vector(RAM_WIDTH-1 downto 0)       
    );
  end component;

  ---- SIGNALS/CONSTANTS/VARIABLES/TYPES ---------------------------------------

  type fill_lbuff_states_t is (RESET, IDLE, READ_FBUFF, WRITE_LBUFF, FINAL);

  type buff_addr_arr_t is array (1 downto 0) of std_logic_vector(lbuff_addr_width_g-1 downto 0);
  type buff_pxl_arr_t  is array (1 downto 0) of std_logic_vector(pxl_width_g-1 downto 0);

  signal fill_lbuff_c_state_r, fill_lbuff_n_state_r : fill_lbuff_states_t;

  signal fill_in_progress_r : std_logic_vector(1 downto 0);
  signal lbuff_fill_done_r  : std_logic_vector(1 downto 0);
  signal fill_select_r      : integer range 0 to 1;
                                               
  signal lbuff_addr_s      : buff_addr_arr_t;
  signal lbuff_wr_addr_r   : unsigned(lbuff_addr_width_g-1 downto 0);
  signal lbuff_rd_addr_s   : std_logic_vector(lbuff_addr_width_g-1 downto 0);
  signal lbuff_din_s       : std_logic_vector(pxl_width_g-1 downto 0);
  signal lbuff_dout_s      : buff_pxl_arr_t;
  signal lbuff_we_r        : std_logic_vector(1 downto 0);
  signal lbuff_en_s        : std_logic_vector(1 downto 0);
  signal lbuff_cntr_en_r   : std_logic;
  signal lbuff_tile_cntr_r : unsigned(lbuff_addr_width_g-1 downto 0);
                                    
  signal fbuff_rd_req_r : std_logic;
                        
  signal fbuff_pxl_s   : unsigned(pxl_width_g-1 downto 0); 
  signal fbuff_addr_r  : unsigned(fbuff_addr_width_g-1 downto 0); 
  signal fbuff_data_r  : unsigned(fbuff_data_width_g-1 downto 0);

begin --------------------------------------------------------------------------

  --- INTERMEDIATE SIGNAL ASSIGNMENT LOGIC -------------------------------------

  lbuff_en_s      <= (others => '1'); -- read enable of line buffer is always set
  lbuff_rd_addr_s <= disp_pxl_id_i;

  comb_fbuff_pxl_assign : process (lbuff_tile_cntr_r, fbuff_data_r) is ---------
  begin 

    -- select pixel slice within row for write to line buffer
    fbuff_pxl_s <= fbuff_data_r(((to_integer(lbuff_tile_cntr_r) * pxl_width_g) + 
                                  pxl_width_g) - 1 downto 
                                (to_integer(lbuff_tile_cntr_r) * pxl_width_g));

  end process comb_fbuff_pxl_assign; -------------------------------------------

  ---- BUFFER INSTANCE AND ADDRESS SIGNAL GENERATION ---------------------------

  generate_lbuffs : for buffer_i in 0 to 1 generate ----------------------------

    i_line_buff0 : xilinx_sp_BRAM
    generic map (
      RAM_WIDTH  => pxl_width_g,
      RAM_DEPTH  => tile_per_line_g,
      ADDR_WIDTH => lbuff_addr_width_g,
      INIT_FILE  => ""
    )
    port map (
      addra => lbuff_addr_s(buffer_i),     
      dina  => lbuff_din_s,    
      clka  => clk_i,    
      wea   => lbuff_we_r(buffer_i),   
      ena   => lbuff_en_s(buffer_i),  
      douta => lbuff_dout_s(buffer_i)
    );

    -- set both lbuff din as we controls what is written to the line_buff
    lbuff_din_s  <= std_logic_vector(fbuff_pxl_s); 
    
    -- it is not possible to read from and write to the same buffer simultaneously
    lbuff_addr_s(buffer_i) <= lbuff_rd_addr_s when buff_sel_i(buffer_i) = '1' else 
                              std_logic_vector(lbuff_wr_addr_r);

  end generate generate_lbuffs; ------------------------------------------------

  ---- FILL LINE BUFFER FSM ----------------------------------------------------
  buff_fill_fsm : process (clk_i, rstn_i) is
  begin
    if rstn_i = '0' then
      fill_lbuff_c_state_r <= RESET;
    elsif rising_edge(clk_i) then 
      fill_lbuff_c_state_r <= fill_lbuff_n_state_r;
    end if;  
  end process buff_fill_fsm; ---------------------------------------------------

  n_state : process (ALL) is ---------------------------------------------------
  begin 

    fill_lbuff_n_state_r <= fill_lbuff_c_state_r;

    case fill_lbuff_c_state_r is 
      
      when RESET =>  
        
        fill_lbuff_n_state_r <= IDLE;

      when IDLE => 
     
        if fill_in_progress_r /= "00" then 
          fill_lbuff_n_state_r <= READ_FBUFF;
        end if;
      
      when READ_FBUFF => 

        if fbuff_rd_rsp_i = '1' then
          fill_lbuff_n_state_r <= WRITE_LBUFF;
        end if;

      when WRITE_LBUFF => 

        if lbuff_tile_cntr_r = (tiles_per_row_g - 1) then 
          if (lbuff_wr_addr_r = (tile_per_line_g - 1))  then 
            fill_lbuff_n_state_r <= FINAL;
          else 
            fill_lbuff_n_state_r <= READ_FBUFF;
          end if;
        end if;

      when FINAL => 

        fill_lbuff_n_state_r <= IDLE;

      when others =>

        fill_lbuff_n_state_r <= RESET;

    end case;
  end process n_state; ---------------------------------------------------------

  out_assign : process (clk_i, rstn_i) is --------------------------------------
  begin 

    if rstn_i = '0' then
      
      lbuff_cntr_en_r     <= '0';
      fbuff_rd_req_r      <= '0';
      lbuff_we_r          <= (others => '0');
      lbuff_fill_done_r   <= (others => '0');
      fbuff_addr_r        <= (others => '0');
      fbuff_data_r        <= (others => '0');

    elsif rising_edge(clk_i) then 

      case fill_lbuff_c_state_r is 
      
        when RESET =>                                                       ----
          
          -- do nothing
        
        when IDLE =>                                                        ----
          
          if fill_in_progress_r /= "00" then 
            fbuff_rd_req_r <= '1';
          end if;

        when READ_FBUFF =>                                                  ----
        
          -- Start read from frame buffer and move to writing line buffer once 
          -- completed
          fbuff_rd_req_r <= '0';
            
          if fbuff_rd_rsp_i = '1' then 
               
            -- increment frame buffer address ready for next request
            incr_addr : if fbuff_addr_r = (fbuff_depth_g-1) then 
              fbuff_addr_r <= (others => '0');
            else  
              fbuff_addr_r <= fbuff_addr_r + 1;
            end if incr_addr;
                
            fbuff_data_r              <= unsigned(fbuff_data_i);
            lbuff_cntr_en_r           <= '1';
            lbuff_we_r(fill_select_r) <= '1';

          end if;

        when WRITE_LBUFF =>                                                 ----   
        
          -- Write each tile from frame buffer row into the line buffer. Once
          -- complete, either perform another frame buffer read or finish 
          
            if to_integer(lbuff_tile_cntr_r) = (tiles_per_row_g - 1) then 
              
              lbuff_cntr_en_r           <= '0';
              lbuff_we_r(fill_select_r) <= '0'; -- stop writing once at row limit

              if to_integer(lbuff_wr_addr_r) = (tile_per_line_g - 1) then
                -- indicate that the buffer being filled is now full 
                -- (only a single buffer should be in progress at any time)
                lbuff_fill_done_r <= fill_in_progress_r;
              else
                fbuff_rd_req_r <= '1';
              end if;
            end if;
        
        when FINAL =>                                                    ---- 

          -- Clear remaining control states and move to idle as line buffer 
          -- has been written 
          lbuff_fill_done_r <= (others => '0');
        
        when others =>                                                      ----            
          
          -- do nothing

      end case;
    end if;
  end process out_assign; ---------------------------------------------------

  ---- LINE BUFFER ADDRESS + TILE COUNTER LOGIC --------------------------------

  tile_addr_counters : process (clk_i, rstn_i) is ------------------------------
  begin 

    if rstn_i = '0' then 

      lbuff_wr_addr_r   <= (others => '0');
      lbuff_tile_cntr_r <= (others => '0');

    elsif rising_edge(clk_i) then 

      if lbuff_cntr_en_r = '1' then 

        -- increment line buffer address counter
        if lbuff_wr_addr_r = (tile_per_line_g - 1) then
          lbuff_wr_addr_r <= (others => '0');
        else 
          lbuff_wr_addr_r <= lbuff_wr_addr_r + 1; -- 'bleurgh' TODO: refactor this to clean up type conversion 
        end if;

        -- increment tile in row counter
        if lbuff_tile_cntr_r = (tiles_per_row_g - 1) then
          lbuff_tile_cntr_r <= (others => '0');
        else 
          lbuff_tile_cntr_r <= lbuff_tile_cntr_r + 1;
        end if;

      end if;
      
      assert (lbuff_tile_cntr_r <= tiles_per_row_g)
      report "Tile counter overflow detected." & lf &
              "    Tile Counter: " & integer'image(to_integer(lbuff_tile_cntr_r)) & lf &
              "    Tiles per row: " & integer'image(tiles_per_row_g)
      severity error;

      assert (lbuff_wr_addr_r <= tile_per_line_g) 
      report "Line buffer address overflow detected." & lf &
             "    LB Write Addr: " & integer'image(to_integer(lbuff_wr_addr_r)) & lf &
             "    LB depth: " & integer'image(tile_per_line_g)
      severity error;

    end if;

  end process tile_addr_counters; ----------------------------------------------

  ---- BUFFER FILL IN PROGRESS + FILL SELECT LOGIC -----------------------------

  in_progress_select : process (clk_i, rstn_i) is ------------------------------
  begin 

    if rstn_i = '0' then 
    
      fill_in_progress_r <= (others => '0');
      fill_select_r      <= 0;

    elsif rising_edge(clk_i) then 

      -- prioritise buffer_A. Only one buffer should be filled at a time as 
      -- there is a single frame buff memory interface
      if fill_in_progress_r = "00" then 

        if buff_fill_req_i(0) = '1' then 

          fill_in_progress_r(0) <= '1';
          fill_select_r         <= 0;

        elsif buff_fill_req_i(1) = '1' then 

          fill_in_progress_r(1) <= '1';
          fill_select_r         <= 1;

        end if;

      else

        if lbuff_fill_done_r(0) = '1' then 
          fill_in_progress_r(0) <= '0';          
        elsif lbuff_fill_done_r(1) = '1' then
          fill_in_progress_r(1) <= '0';           
        end if;

      end if;
    end if;
  end process in_progress_select; ----------------------------------------------

  ---- ASSERTIONS --------------------------------------------------------------

  assert fbuff_data_width_g = (tiles_per_row_g * pxl_width_g)
    report "Data width of frame buffer must match the bit width of the tiles within each row!"
    severity error;

  --- OUTPUT ASSIGNMENTS -------------------------------------------------------

  buff_fill_done_o <= lbuff_fill_done_r;
  fbuff_rd_req_o   <= fbuff_rd_req_r;
  fbuff_addra_o    <= std_logic_vector(fbuff_addr_r);

  disp_pxl_o <= std_logic_vector(lbuff_dout_s(0)) when buff_sel_i(0) = '1' else 
                std_logic_vector(lbuff_dout_s(1)) when buff_sel_i(1) = '1' else
                (others => '0');

end architecture rtl; ----------------------------------------------------------

--------------------------------------------------------------------------------