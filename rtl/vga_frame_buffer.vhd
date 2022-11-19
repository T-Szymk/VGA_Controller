-------------------------------------------------------------------------------
-- Title      : VGA Controller Frame Buffer
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_frame_buffer.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-11-05
-- Design     : vga_frame_buffer
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to contain frame buffer memory and access logic including
--              handshaking. 
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-11-05  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;

entity vga_frame_buffer is 
  generic (
    fbuff_addr_width_g : integer :=   13;
    fbuff_data_width_g : integer :=   48; -- 4 tiles @ 12px each
    fbuff_depth_g      : integer := 4800; -- total num. of pxls / (tile area * tiles_per_row) == (640*480)/(4 * 4 * 4)
    init_file_g        : string  := ""
  );
  port (
    clk_i    : in  std_logic;
    rstn_i   : in  std_logic;   
    addra_i  : in  std_logic_vector(fbuff_addr_width_g-1 downto 0);
    dina_i   : in  std_logic_vector(fbuff_data_width_g-1 downto 0);
    wea_i    : in  std_logic;  
    ena_i    : in  std_logic;  
    rd_req_i : in  std_logic;     
    rd_rsp_o : out std_logic;     
    douta_o  : out std_logic_vector(fbuff_data_width_g-1 downto 0)    
  );
end entity vga_frame_buffer;

--------------------------------------------------------------------------------

architecture rtl of vga_frame_buffer is 

-----COMPONENT DECLARATION -----------------------------------------------------

  component xilinx_sp_BRAM
    generic (
      RAM_WIDTH : integer := 18;
      RAM_DEPTH : integer := 2048;
      INIT_FILE : string := "/home/tom/Development/VGA_Controller/supporting_apps/mem_file_gen/mem_file.mem"
    );
    port (
      addra : in  std_logic_vector(INTEGER(CEIL(LOG2(REAL(RAM_DEPTH - 1))))-1 downto 0);      
      dina  : in  std_logic_vector(RAM_WIDTH-1 downto 0);      
      clka  : in  std_logic;      
      wea   : in  std_logic;     
      ena   : in  std_logic;     
      douta : out std_logic_vector(RAM_WIDTH-1 downto 0)       
    );
  end component;

---- SIGNALS/CONSTANTS/VARIABLES/TYPES -----------------------------------------

  type mem_state_t is ( RESET, IDLE, READ_REQ, READ_RSP );

  signal mem_state_r : mem_state_t;

  signal rd_rsp_r : std_logic;
  signal dout_s   : std_logic_vector(fbuff_data_width_g-1 downto 0);

begin --------------------------------------------------------------------------

---- COMPONENT INSTANTIATION ---------------------------------------------------

i_sp_ram : xilinx_sp_BRAM
generic map (
  RAM_WIDTH => fbuff_data_width_g,
  RAM_DEPTH => fbuff_depth_g,
  INIT_FILE => init_file_g
)
port map (
  addra => addra_i,    
  dina  => dina_i,   
  clka  => clk_i,   
  wea   => wea_i,  
  ena   => ena_i,  
  douta => dout_s
);

---- LOGIC ---------------------------------------------------------------------

  READ_MEM_FSM_p : process(clk_i, rstn_i) is -----------------------------------
  begin 

    if rstn_i = '0' then
      
      mem_state_r <= RESET;
      rd_rsp_r    <= '0'; 
    
    elsif rising_edge(clk_i) then 
      
      case mem_state_r is                                                 ------
        
        when RESET =>                                                       ----
          
          mem_state_r <= IDLE;

        when IDLE =>                                                        ----
        
          if rd_req_i = '1' then 
            mem_state_r <= READ_REQ;
          end if;
        
        when READ_REQ =>                                                    ----
        
          rd_rsp_r    <= '1';
          mem_state_r <= READ_RSP;
        
        when READ_RSP =>                                                    ----
          -- data is available to read from dout at this point
          rd_rsp_r    <= '0';
          mem_state_r <= IDLE;
        
        when others =>                                                      ----

          mem_state_r <= IDLE;  

      end case;                                                           ------
    
    end if;

  end process READ_MEM_FSM_p; --------------------------------------------------


--- output assignments ---------------------------------------------------------
  
  rd_rsp_o <= rd_rsp_r;
  douta_o  <= dout_s;

end architecture;