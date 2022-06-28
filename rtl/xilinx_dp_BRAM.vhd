-------------------------------------------------------------------------------
-- Title      : VGA Controller - Dual Port BRAM
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : xilinx_dp_BRAM.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-26
-- Design     : xilinx_dp_BRAM
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Modified code taken from the true dual port BRAM taken from
--              Xilinx templates.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-26  1.0      TZS     Created
-- 2022-06-28  1.1      TZS     Moved ram_pkg to separate design unit.
--------------------------------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;
use std.textio.all;

entity xilinx_dp_BRAM is
  generic (
    RAM_WIDTH       : integer := 18;           -- Specify RAM data width
    RAM_DEPTH       : integer := 1024;         -- Specify RAM depth (number of entries)
    INIT_FILE       : string := "RAM_INIT.dat" -- Specify name/location of RAM initialization file if using one (leave blank if not)
  );
  port (
    addra  : in  std_logic_vector(mem_addr_width_c-1 downto 0); -- Port A Address bus, width determined from RAM_DEPTH
    addrb  : in  std_logic_vector(mem_addr_width_c-1 downto 0); -- Port B Address bus, width determined from RAM_DEPTH
    dina   : in  std_logic_vector(RAM_WIDTH-1 downto 0);           -- Port A RAM input data
    dinb   : in  std_logic_vector(RAM_WIDTH-1 downto 0);           -- Port B RAM input data
    clka   : in  std_logic;                                        -- Clock
    wea    : in  std_logic;                                        -- Port A Write enable
    web    : in  std_logic;                                        -- Port B Write enable
    ena    : in  std_logic;                                        -- Port A RAM Enable, for additional power savings, disable port when not in use
    enb    : in  std_logic;                                        -- Port B RAM Enable, for additional power savings, disable port when not in use
    douta  : out std_logic_vector(RAM_WIDTH-1 downto 0);           --  Port A RAM output data
    doutb  : out std_logic_vector(RAM_WIDTH-1 downto 0)            --  Port B RAM output data
  );
end xilinx_dp_BRAM;

--------------------------------------------------------------------------------

architecture rtl of xilinx_dp_BRAM is

  constant C_RAM_WIDTH       : integer := RAM_WIDTH;
  constant C_RAM_DEPTH       : integer := RAM_DEPTH;
  constant C_INIT_FILE       : string  := INIT_FILE;
  
  signal douta_reg : std_logic_vector(C_RAM_WIDTH-1 downto 0) := (others => '0');
  signal doutb_reg : std_logic_vector(C_RAM_WIDTH-1 downto 0) := (others => '0');
  
  type ram_type is array (C_RAM_DEPTH-1 downto 0) of std_logic_vector (C_RAM_WIDTH-1 downto 0);          -- 2D Array Declaration for RAM signal
  
  signal ram_data_a : std_logic_vector(C_RAM_WIDTH-1 downto 0) ;
  signal ram_data_b : std_logic_vector(C_RAM_WIDTH-1 downto 0) ;
  
  -- The folowing code either initializes the memory values to a specified file or to all zeros to match hardware
  
  impure function initramfromfile (ramfilename : in string) return ram_type is
    file     ramfile     : text open read_mode is ramfilename;
    variable ramfileline : line;
    variable ram_name    : ram_type;
    variable bitvec      : bit_vector(C_RAM_WIDTH-1 downto 0);
  begin
    
    for i in ram_type'range loop
      readline (ramfile, ramfileline);
      read (ramfileline, bitvec);
      ram_name(i) := to_stdlogicvector(bitvec);
    end loop;
    
    return ram_name;

  end function; ----------------------------------------------------------------

  impure function init_from_file_or_zeroes(ramfile : in string) return ram_type is -------
  begin
    if ramfile = "RAM_INIT.dat" then
      return InitRamFromFile("RAM_INIT.dat");
    else
      return (others => (others => '0'));
    end if;
  end function;
  -- Following code defines RAM

  signal ram_name : ram_type := init_from_file_or_zeroes(C_INIT_FILE);

begin --------------------------------------------------------------------------

  process (clka) is ------------------------------------------------------------
  begin
    if rising_edge(clka) then
      if(ena = '1') then
        ram_data_a <= ram_name(to_integer(unsigned(addra)));
        if(wea = '1') then
          ram_name(to_integer(unsigned(addra))) <= dina;
        end if;
      end if;
    end if;
  end process; -----------------------------------------------------------------

  process (clka) is ------------------------------------------------------------
  begin
    if rising_edge(clka) then
      if(enb = '1') then
        ram_data_b <= ram_name(to_integer(unsigned(addrb)));
        if(web = '1') then
          ram_name(to_integer(unsigned(addrb))) <= dinb;
        end if;
      end if;
    end if;
  end process; -----------------------------------------------------------------

  douta <= ram_data_a;
  doutb <= ram_data_b;

end rtl;                  
                            