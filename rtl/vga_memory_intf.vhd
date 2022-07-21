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
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use work.vga_pkg.all;

entity vga_memory_intf is 
  generic (
    INIT_FILE : string := "/home/tom/Development/VGA_Controller/supporting_apps/mem_file_gen/mem_file.mem"
  );
  port (
    clk_i        : in  std_logic;
    rstn_i       : in  std_logic;
    pxl_ctr_i    : in  std_logic_vector(pxl_ctr_width_c - 1 downto 0);
    line_ctr_i   : in  std_logic_vector(line_ctr_width_c - 1 downto 0);
    disp_blank_o : out std_logic;
    disp_pxl_o   : out pixel_t
  );
end entity vga_memory_intf;

--------------------------------------------------------------------------------
architecture rtl of vga_memory_intf is 

  component vga_mem_addr_ctrl is
    generic (
      DEBUG : boolean
    );
    port (
      clk_i          : in  std_logic;
      rstn_i         : in  std_logic;
      pxl_ctr_i      : in  std_logic_vector(pxl_ctr_width_c - 1 downto 0);
      line_ctr_i     : in  std_logic_vector(line_ctr_width_c - 1 downto 0);
      mem_addr_ctr_o : out std_logic_vector(mem_addr_width_c - 1 downto 0);
      mem_pxl_ctr_o  : out std_logic_vector(row_ctr_width_c - 1 downto 0)
    );
  end component;

  component vga_mem_buff is 
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
  end component;

  component xilinx_true_dual_port_read_first_1_clock_ram is
    generic (
      RAM_WIDTH       : integer := 18;           
      RAM_DEPTH       : integer := 1024;         
      INIT_FILE       : string := ""             
    );
    port (
      addra  : in  std_logic_vector(mem_addr_width_c-1 downto 0); 
      dina   : in  std_logic_vector(RAM_WIDTH-1 downto 0);               
      clka   : in  std_logic;                                     
      wea    : in  std_logic;                                                                          
      ena    : in  std_logic;
      rst    : in  std_logic;                                                                          
      douta  : out std_logic_vector(RAM_WIDTH-1 downto 0)                
    );
  end component;
    
  signal mem_pxl_ctr_s  : std_logic_vector(row_ctr_width_c-1 downto 0);
  signal mem_addr_ctr_s : std_logic_vector(mem_addr_width_c-1 downto 0);
  signal mem_data_s     : std_logic_vector(mem_row_width_c-1 downto 0);
  signal mem_addr_s     : std_logic_vector(mem_addr_width_c-1 downto 0);
  signal disp_blank_s   : std_logic;
  signal mem_ren_s      : std_logic;
  signal disp_pxl_s     : pixel_t;

begin --------------------------------------------------------------------------

 i_mem_addr_ctrl : vga_mem_addr_ctrl
   generic map (
     DEBUG => FALSE
   )
   port map (
     clk_i          => clk_i,
     rstn_i         => rstn_i,
     pxl_ctr_i      => pxl_ctr_i,
     line_ctr_i     => line_ctr_i,
     mem_addr_ctr_o => mem_addr_ctr_s,
     mem_pxl_ctr_o  => mem_pxl_ctr_s
   );

  i_mem_buff : vga_mem_buff
    port map (
      clk_i           => clk_i,
      rstn_i          => rstn_i,
      disp_addr_ctr_i => mem_addr_ctr_s,
      disp_pxl_ctr_i  => mem_pxl_ctr_s,
      mem_data_i      => mem_data_s,
      mem_addr_o      => mem_addr_s,
      mem_ren_o       => mem_ren_s,
      disp_blank_o    => disp_blank_s,
      disp_pxl_o      => disp_pxl_s
    );
    -- read only BRAM
    i_xilinx_dp_ram : xilinx_true_dual_port_read_first_1_clock_ram
      generic map (
        RAM_WIDTH => mem_row_width_c, 
        RAM_DEPTH => mem_depth_c,     
        INIT_FILE => INIT_FILE
      )
      port map (
        addra  => mem_addr_s,
        dina   => (others => '0'),
        clka   => clk_i,
        wea    => '0',
        ena    => mem_ren_s,
        rst    => '0',
        douta  => mem_data_s
      );

  disp_blank_o <= disp_blank_s;
  disp_pxl_o   <= disp_pxl_s;

end architecture rtl;

--------------------------------------------------------------------------------