-------------------------------------------------------------------------------
-- Title      : VGA Controller - Single Port BRAM
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : xilinx_sp_BRAM.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-26
-- Design     : xilinx_sp_BRAM
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Modified code taken from the true single BRAM taken from
--              Xilinx templates.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-26  1.0      TZS     Created
-- 2022-06-28  1.1      TZS     Moved ram_pkg to separate design unit.
-- 2022-11-19  1.2      TZS     Update design to be single port RAM.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.vga_pkg.all;
use std.textio.all;

--------------------------------------------------------------------------------

entity xilinx_sp_BRAM is
  generic (
    RAM_WIDTH  : integer := 18;           
    RAM_DEPTH  : integer := 1024;
    ADDR_WIDTH : integer := 8;         
    INIT_FILE  : string := "RAM_INIT.dat" 
  );
  port (
    addra  : in  std_logic_vector(ADDR_WIDTH-1 downto 0); 
    dina   : in  std_logic_vector(RAM_WIDTH-1 downto 0);           
    clka   : in  std_logic;                                        
    wea    : in  std_logic;                                        
    ena    : in  std_logic;                                        
    douta  : out std_logic_vector(RAM_WIDTH-1 downto 0)           
  );
end xilinx_sp_BRAM;

--------------------------------------------------------------------------------

architecture rtl of xilinx_sp_BRAM is

  constant C_RAM_WIDTH       : integer := RAM_WIDTH;
  constant C_RAM_DEPTH       : integer := RAM_DEPTH;
  constant C_INIT_FILE       : string  := INIT_FILE;
  
  signal douta_reg : std_logic_vector(C_RAM_WIDTH-1 downto 0) := (others => '0');
  
  type ram_type is array (C_RAM_DEPTH-1 downto 0) of std_logic_vector (C_RAM_WIDTH-1 downto 0);          -- 2D Array Declaration for RAM signal
  
  signal ram_data_a : std_logic_vector(C_RAM_WIDTH-1 downto 0) ;
  
  -- The folowing code either initializes the memory values to a specified file or to all zeros to match hardware
  
  impure function initramfromfile (ramfilename : in string) return ram_type is
    file     ramfile     : text open read_mode is ramfilename;
    variable ramfileline : line;
    variable ram         : ram_type;
    variable bitvec      : bit_vector(C_RAM_WIDTH-1 downto 0);
  begin
    
    for i in ram_type'range loop
      readline (ramfile, ramfileline);
      read (ramfileline, bitvec);
      ram(i) := to_stdlogicvector(bitvec);
    end loop;
    
    return ram;

  end function; ----------------------------------------------------------------

  impure function init_from_file_or_zeroes(ramfile : in string) return ram_type is -------
  begin
    if ramfile /= "" then
      return InitRamFromFile(ramfile);
    else
      return (others => (others => '0'));
    end if;
  end function;
  -- Following code defines RAM

  signal ram : ram_type := init_from_file_or_zeroes(C_INIT_FILE);

begin --------------------------------------------------------------------------

  process (clka) is ------------------------------------------------------------
  begin
    if rising_edge(clka) then
      if ena = '1' then
        ram_data_a <= ram(to_integer(unsigned(addra)));
        if wea = '1' then
          ram(to_integer(unsigned(addra))) <= dina;
        end if;
      end if;
    end if;
  end process; -----------------------------------------------------------------

  douta <= ram_data_a;

end rtl;                  
                            