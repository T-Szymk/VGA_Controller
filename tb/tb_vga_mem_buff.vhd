-------------------------------------------------------------------------------
-- Title      : VGA Controller - VGA Memory Interface
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : tb_vga_mem_buff.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-25
-- Design     : tb_vga_mem_buff
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Testbench to run buff module.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-25  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vga_pkg.all;

entity tb_vga_mem_buff is 
generic (
  CLK_PERIOD    : time := 40 ns;
  MEM_INIT_FILE : string := "../../supporting_apps/mem_file_gen/mem_file.mem"
);
end entity tb_vga_mem_buff;

--------------------------------------------------------------------------------
architecture tb of tb_vga_mem_buff is

  component vga_mem_buff is 
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
    end component;

  component xilinx_true_dual_port_read_first_1_clock_ram is 
    generic (
      RAM_WIDTH       : integer := 18;           -- Specify RAM data width
      RAM_DEPTH       : integer := 1024;         -- Specify RAM depth (number of entries)
      INIT_FILE       : string := "RAM_INIT.dat" -- Specify name/location of RAM initialization file if using one (leave blank if not)
    );
    port (
      addra  : in  std_logic_vector(mem_addr_width_c-1 downto 0); 
      addrb  : in  std_logic_vector(mem_addr_width_c-1 downto 0); 
      dina   : in  std_logic_vector(RAM_WIDTH-1 downto 0);        
      dinb   : in  std_logic_vector(RAM_WIDTH-1 downto 0);        
      clka   : in  std_logic;                                     
      wea    : in  std_logic;                                     
      web    : in  std_logic;                                     
      ena    : in  std_logic;                                     
      enb    : in  std_logic;                                     
      douta  : out std_logic_vector(RAM_WIDTH-1 downto 0);        
      doutb  : out std_logic_vector(RAM_WIDTH-1 downto 0)         
    );
    end component;

  signal clk_s, rstn_s   : std_logic := '0';
  signal ctr_rstn_s      : std_logic := '0';
  signal disp_addr_ctr_s : unsigned(mem_addr_width_c-1 downto 0);       
  signal disp_pxl_ctr_s  : unsigned(row_ctr_width_c-1 downto 0);      
  signal mem_data_s      : std_logic_vector(mem_row_width_c-1 downto 0);  
  signal mem_addr_s      : std_logic_vector(mem_addr_width_c-1 downto 0);  
  signal disp_blank_s    : std_logic;    
  signal disp_pxl_s      : pixel_t;
  signal mem_ren_s       : std_logic;
  signal blank_test_s    : std_logic := '1';

begin --------------------------------------------------------------------------

  clk_gen : process is                                               -----------
  begin    
    while now < 200 ms loop
      clk_s <= '0';
      wait for CLK_PERIOD/2;
      clk_s <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
      assert TRUE 
        report "END OF SIMULATION"
        severity ERROR; 
  end process clk_gen;                                               -----------

  rstn_s <= '1' after CLK_PERIOD * 10; 
  ctr_rstn_s <= '1' after CLK_PERIOD * 100; -- simulating the porch/sync period

  addr_ctr : process (clk_s, ctr_rstn_s) is ------------------------------------
  begin 
    if ctr_rstn_s = '0' then 
      disp_addr_ctr_s <= (others => '0');
      disp_pxl_ctr_s  <= (others => '0');

    elsif rising_edge(clk_s) then
      
      if disp_pxl_ctr_s = (pxl_per_row_c - 1) then 
        
        disp_pxl_ctr_s  <= (others => '0');
        
        -- skip address at addr 8 to test blanking
        if blank_test_s = '1' then 
          if disp_addr_ctr_s = 8 then
            disp_addr_ctr_s <= disp_addr_ctr_s + 2;
          elsif disp_addr_ctr_s = 16 then
            blank_test_s    <= '0';
            disp_addr_ctr_s <= (others => '0');
          else
            disp_addr_ctr_s <= disp_addr_ctr_s + 1;
          end if;
        else 
          disp_addr_ctr_s <= disp_addr_ctr_s + 1;
        end if;

      else
        disp_pxl_ctr_s  <= disp_pxl_ctr_s + 1;
      end if;

    end if;
  end process addr_ctr; --------------------------------------------------------

  i_dut : vga_mem_buff
    port map (
      clk_i           => clk_s,   
      rstn_i          => rstn_s,    
      disp_addr_ctr_i => std_logic_vector(disp_addr_ctr_s),             
      disp_pxl_ctr_i  => std_logic_vector(disp_pxl_ctr_s),            
      mem_data_i      => mem_data_s,        
      mem_addr_o      => mem_addr_s,
      mem_ren_o       => mem_ren_s,              
      disp_blank_o    => disp_blank_s,          
      disp_pxl_o      => disp_pxl_s       
    );

    i_bram : xilinx_true_dual_port_read_first_1_clock_ram
      generic map (
        RAM_WIDTH => mem_row_width_c,
        RAM_DEPTH => mem_depth_c,
        INIT_FILE => MEM_INIT_FILE
      )
      port map (
        addra => mem_addr_s,   
        addrb => (others => '0'),   
        dina  => (others => '0'),  
        dinb  => (others => '0'),  
        clka  => clk_s,  
        wea   => '0', 
        web   => '0', 
        ena   => mem_ren_s, 
        enb   => '0', 
        douta => mem_data_s,   
        doutb => open  
      );


end architecture tb;

--------------------------------------------------------------------------------