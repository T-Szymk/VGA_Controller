-------------------------------------------------------------------------------
-- Title      : VGA Controller - RAM Package
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : ram_pkg.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-06-28
-- Design     : ram_pkg
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Package to contain definitions used for Xilinx BRAMs
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-06-28  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

package ram_pkg is -------------------------------------------------------------
    function clogb2 (depth: in natural) return integer;
end ram_pkg; -------------------------------------------------------------------

package body ram_pkg is --------------------------------------------------------

  function clogb2( depth : in natural) return integer is
    variable temp    : integer := depth;
    variable ret_val : integer := 0;
  begin

    while temp > 1 loop
      ret_val := ret_val + 1;
      temp    := temp / 2;
    end loop;
    
    return ret_val;
  end function;

end package body ram_pkg; ------------------------------------------------------