-------------------------------------------------------------------------------
-- Title      : VGA Controller Colour Mux Testbench
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : vga_colr_mux_tb.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2021-07-24
-- Design     : vga_colr_mux_tb
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Testbench for colour muxing block
--
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2021-07-24  1.0      TZS     Created
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.FINISH;

ENTITY vga_colr_mux_tb IS 
  GENERIC (depth_colr_g : INTEGER := 8);
END ENTITY vga_colr_mux_tb;

--------------------------------------------------------------------------------

ARCHITECTURE tb OF vga_colr_mux_tb IS 

  COMPONENT vga_colr_mux IS 
    
    GENERIC (depth_colr_g : INTEGER := 4);
    PORT (
      colr_in : IN STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0);
      en_in   : IN STD_LOGIC_VECTOR(3-1 DOWNTO 0);
    
      colr_out : OUT STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0)
    );

  END COMPONENT; 

  SIGNAL colr_i_s : STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0) := (OTHERS => '1');
  SIGNAL colr_o_s : STD_LOGIC_VECTOR((3*depth_colr_g)-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL en_i_s   : UNSIGNED(3-1 DOWNTO 0)                        := (OTHERS => '0'); 

  BEGIN -- architecture tb

  i_vga_colr_mux : vga_colr_mux
    GENERIC MAP ( depth_colr_g => depth_colr_g 
    )
    PORT MAP    ( colr_in      => colr_i_s,
                  en_in        => STD_LOGIC_VECTOR(en_i_s),
                  colr_out     => colr_o_s
    ); 


  TEST_SEQUENCER : PROCESS
  BEGIN 

    WAIT FOR 10 NS;
    
    IF NOW > 0 NS THEN 

      FOR idx IN 3-1 DOWNTO 0 LOOP
      
        IF en_i_s(idx) = '1' THEN
        
          ASSERT colr_o_s(((idx+1) * depth_colr_g)-1 DOWNTO (idx * depth_colr_g)) = colr_i_s( ((idx+1) * depth_colr_g)-1 DOWNTO (idx * depth_colr_g) )
            REPORT "TEST FAIL: Output #" & TO_STRING(idx) & " doesn't match input #" & TO_STRING(idx) & " when corresponding enable is '1'" &
                    LF & "Input value:  " & TO_HSTRING(colr_i_s( ((idx+1) * depth_colr_g)-1 DOWNTO (idx * depth_colr_g) )) &
                    LF & "Output value: " & TO_HSTRING(colr_o_s( ((idx+1) * depth_colr_g)-1 DOWNTO (idx * depth_colr_g) ))
            SEVERITY WARNING;
        
        ELSE  
        
          ASSERT OR(colr_o_s(((idx+1) * depth_colr_g)-1 DOWNTO (idx * depth_colr_g))) = '0'
            REPORT "TEST FAIL: Output #" & TO_STRING(idx) & " is not zeroes when corresponding enable is '0'" &
                    LF & "Output value: " & TO_HSTRING(colr_o_s( ((idx+1) * depth_colr_g)-1 DOWNTO (idx * depth_colr_g) ))
            SEVERITY WARNING;
        
        END IF;
      
      END LOOP;

    END IF;

    en_i_s <= en_i_s + 1;

  END PROCESS;

  TEST_MNGR : PROCESS
  BEGIN 
  
    WAIT UNTIL (NOW > 50 NS) AND (en_i_s = 0); 
    REPORT "Calling 'FINISH'";
    FINISH;
    
  END PROCESS;

END ARCHITECTURE tb;

--------------------------------------------------------------------------------