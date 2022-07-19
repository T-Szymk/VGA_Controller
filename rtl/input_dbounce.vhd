-------------------------------------------------------------------------------
-- Title      : Input Debounce 
-- Project    : VGA Controller
--------------------------------------------------------------------------------
-- File       : input_dbounce.vhd
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2022-07-19
-- Design     : input_dbounce
-- Platform   : -
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Input debouncer with configurable delay
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2022-07-19  1.0      TZS     Created
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity input_dbounce is 
  generic (
    dbounce_counter_g : integer   := 10;
    init_value_g      : std_logic := '0'
  );
  port (
    clk_i    : in  std_logic;
    signal_i : in  std_logic;
    signal_o : out std_logic 
  );
end entity input_dbounce;

--------------------------------------------------------------------------------
architecture rtl of input_dbounce is 

  type state_t is (IDLE, COUNT, RISING, FALLING);
  
  signal curr_state_s : state_t := IDLE;

  -- input synchroniser
  signal signal_sync_r, 
         signal_sync_rr,
         signal_sync_rrr : std_logic := init_value_g;
  -- register to hold previous value
  signal signal_old_r, 
         signal_new_stored_r, 
         signal_out_r : std_logic := init_value_g;  

  signal dbounce_counter_r : integer range (dbounce_counter_g - 1) downto 0 := 0;

begin 

  process (clk_i) is -----------------------------------------------------------
    
  begin 

    if rising_edge(clk_i) then

      -- synchroniser chain
      signal_sync_r   <= signal_i;
      signal_sync_rr  <= signal_sync_r;
      signal_sync_rrr <= signal_sync_rr;

      signal_old_r <= signal_sync_rrr;

      curr_state_s <= curr_state_s;
    
      case (curr_state_s) is ---------------------------------------------------

        when IDLE =>                                                       -----
          
          -- when the input signal changes state, store value and start timer 
          if signal_sync_rrr /= signal_old_r then 

            curr_state_s <= COUNT;
            signal_new_stored_r <= signal_sync_rrr;
            dbounce_counter_r <= 0;

          end if;
          
        when COUNT =>                                                      -----

          if dbounce_counter_r = (dbounce_counter_g - 1) then
            
            dbounce_counter_r <= 0;
            
            -- once timer expires, check if latest synchronised input matches
            -- the stored value. If so, set output to 1 or 0 depending on the
            -- input value
            if signal_sync_rrr = signal_new_stored_r then 

              if signal_new_stored_r = '1' then 
                curr_state_s <= RISING;
                signal_out_r <= '1';
              else 
                curr_state_s <= FALLING;
                signal_out_r <= '0';
              end if;
            
            else 
              -- if synchronised value does not match the stored value, return
              -- to IDLE and do not update the output
              curr_state_s <= IDLE;

            end if;

          else 

            dbounce_counter_r <= dbounce_counter_r + 1;

          end if;

        when RISING =>                                                     -----
          
          curr_state_s <= IDLE;


        when FALLING =>                                                    -----
                  
        curr_state_s <= IDLE;
        
        when others =>                                                     -----

          curr_state_s <= IDLE;

      end case; ----------------------------------------------------------------

    end if;

  end process; -----------------------------------------------------------------

    signal_o <= signal_out_r;

end architecture rtl;

--------------------------------------------------------------------------------
