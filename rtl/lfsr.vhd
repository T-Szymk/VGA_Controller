LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY lfsr IS
  GENERIC (
    SIZE : INTEGER := 6
  );
  PORT (
  	clk      : IN STD_LOGIC;
  	rst_n    : IN STD_LOGIC;
    lfsr_out : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0)
  );
END ENTITY lfsr;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF lfsr IS 

  SIGNAL lfsr_r : UNSIGNED(SIZE-1 DOWNTO 0);

BEGIN

  PROCESS (clk, rst_n) IS 
  BEGIN 

    IF rst_n = '0' THEN

      lfsr_r <= ('0') & (SIZE-2 DOWNTO 0 => '1');

    
    ELSIF RISING_EDGE(clk) THEN

      lfsr_r <= lfsr_r srl 1;
      lfsr_r(SIZE-1) <= lfsr_r(0) XOR lfsr_r(1);

    END IF;

  END PROCESS;

  lfsr_out <= STD_LOGIC_VECTOR(lfsr_r);

END ARCHITECTURE rtl;
--------------------------------------------------------------------------------