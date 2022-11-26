-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_memory_intf.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-26
-- Design     : vga_memory_intf
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Module to contain logic related to reading image data from BRAM
--              and returning it for use by the VGA controller
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-26  1.0      TZS     Created
-- 2022-07-19  1.1      TZS     Added generic for INIT_FILE
-- 2022-11-13  1.2      TZS     Refactored to instantiate updated modules     
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use work.vga_pkg.all;

entity vga_memory_intf is 
  generic (
    init_file_g : string := "" 
  );
  port (
    clk_i        : in  std_logic;
    rstn_i       : in  std_logic;
    pxl_ctr_i    : in  std_logic_vector(pxl_ctr_width_c - 1 downto 0);
    line_ctr_i   : in  std_logic_vector(line_ctr_width_c - 1 downto 0);
    disp_pxl_o   : out pixel_t
  );
end entity vga_memory_intf;

--------------------------------------------------------------------------------
architecture structural of vga_memory_intf is 

  ---- COMPONENT DECLARATIONS --------------------------------------------------

  component vga_line_buff_ctrl is
    generic (
      width_px_g          : integer := 640; 
      height_lns_g        : integer := 480;
      lbuff_latency_g     : integer :=   1; 
      h_b_porch_max_px_g  : integer := 144;
      v_b_porch_max_lns_g : integer :=  35;
      tile_width_g        : integer :=   4;
      pxl_ctr_width_g     : integer :=  10;
      ln_ctr_width_g      : integer :=  10;
      tiles_per_line_g    : integer := 160;
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
  end component;

  component vga_line_buffers is 
    generic (
      pxl_width_g        : integer :=   12;
      tile_width_g       : integer :=    4;
      fbuff_depth_g      : integer := 4800;
      fbuff_addr_width_g : integer :=   13;
      fbuff_data_width_g : integer :=   48;
      lbuff_addr_width_g : integer :=    8;
      tiles_per_row_g    : integer :=    4;
      tile_per_line_g    : integer :=  160  
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
  end component;

  component vga_frame_buffer is
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
  end component;
    
  ---- SIGNALS/CONSTANTS/VARIABLES/TYPES ---------------------------------------

  signal buff_fill_done_s : std_logic_vector(1 downto 0);
  signal buff_fill_req_s  : std_logic_vector(1 downto 0);              
  signal buff_sel_s       : std_logic_vector(1 downto 0);         
  signal disp_pxl_id_s    : std_logic_vector(lbuff_addr_width_c-1 downto 0); 
  signal fbuff_dout_s     : std_logic_vector(fbuff_data_width_c-1 downto 0);            
  signal fbuff_rd_rsp_s   : std_logic; 
  signal disp_pxl_s       : std_logic_vector(pxl_width_c-1 downto 0);          
  signal fbuff_rd_req_s   : std_logic;              
  signal fbuff_addra_s    : std_logic_vector(fbuff_addr_width_c-1 downto 0);
  signal fbuff_din_s      : std_logic_vector(fbuff_data_width_c-1 downto 0);
  signal fbuff_we_s       : std_logic;
  signal fbuff_en_s       : std_logic; 

begin --------------------------------------------------------------------------

  ---- COMPONENT INSTANTIATIONS ------------------------------------------------
  
  i_line_buff_ctrl : vga_line_buff_ctrl
  generic map (
    width_px_g          => width_px_c,    
    height_lns_g        => height_px_c,      
    lbuff_latency_g     => lbuff_latency_c,         
    h_b_porch_max_px_g  => h_b_porch_max_px_c,            
    v_b_porch_max_lns_g => v_b_porch_max_lns_c,             
    tile_width_g        => tile_width_c,      
    pxl_ctr_width_g     => pxl_ctr_width_c,         
    ln_ctr_width_g      => line_ctr_width_c,        
    tiles_per_line_g    => tiles_per_line_c,         
    tile_ctr_width_g    => lbuff_addr_width_c        
  )
  port map (
    clk_i            => clk_i,                  
    rstn_i           => rstn_i,                   
    buff_fill_done_i => buff_fill_done_s,                             
    pxl_cntr_i       => pxl_ctr_i,                       
    ln_cntr_i        => line_ctr_i,                      
    buff_fill_req_o  => buff_fill_req_s,                            
    buff_sel_o       => buff_sel_s,                       
    disp_pxl_id_o    => disp_pxl_id_s                         
  );

  i_line_buffs : vga_line_buffers
  generic map (
    pxl_width_g        => pxl_width_c,               
    tile_width_g       => tile_width_c,    
    fbuff_depth_g      => fbuff_depth_c,            
    fbuff_addr_width_g => fbuff_addr_width_c,                 
    fbuff_data_width_g => fbuff_data_width_c,
    lbuff_addr_width_g => lbuff_addr_width_c,                 
    tiles_per_row_g    => tiles_per_row_c,              
    tile_per_line_g    => tiles_per_line_c                
  )
  port map (
    clk_i            => clk_i,      
    rstn_i           => rstn_i,       
    buff_fill_req_i  => buff_fill_req_s,                
    buff_sel_i       => buff_sel_s,           
    disp_pxl_id_i    => disp_pxl_id_s,              
    fbuff_data_i     => fbuff_dout_s,             
    fbuff_rd_rsp_i   => fbuff_rd_rsp_s,               
    buff_fill_done_o => buff_fill_done_s,                 
    disp_pxl_o       => disp_pxl_s,           
    fbuff_rd_req_o   => fbuff_rd_req_s,               
    fbuff_addra_o    => fbuff_addra_s             
  );

  i_frame_buff : vga_frame_buffer
  generic map (
    fbuff_addr_width_g => fbuff_addr_width_c,            
    fbuff_data_width_g => fbuff_data_width_c,            
    fbuff_depth_g      => fbuff_depth_c,       
    init_file_g        => init_file_g   
  ) 
  port map (
    clk_i    => clk_i,   
    rstn_i   => rstn_i,    
    addra_i  => fbuff_addra_s,     
    dina_i   => fbuff_din_s,    
    wea_i    => fbuff_we_s,   
    ena_i    => fbuff_en_s,   
    rd_req_i => fbuff_rd_req_s,      
    rd_rsp_o => fbuff_rd_rsp_s,      
    douta_o  => fbuff_dout_s  
  );   

  ---- OUPUT ASSIGNMENTS -------------------------------------------------------

  fbuff_din_s <= (others => '0'); -- fbuff data in = 0
  fbuff_we_s  <= '0';             -- write disabled
  fbuff_en_s  <= '1';             -- enable is always set
  disp_pxl_o  <= disp_pxl_s;

end architecture structural;

--------------------------------------------------------------------------------