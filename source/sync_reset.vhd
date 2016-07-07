-----------------------------------------------------------------------------
-- generated synchronous reset from asynchronous reset
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_reset is

  generic (
    RESET_CYCLES : integer := 10; -- reset cycles to keep after ARESET
    RESET_COUNTER_WIDTH : integer := 4 -- data width of reset counter, 2**RESET_COUNTER_WIDTH
                                       -- should be larger than RESET_CYCLES
    );
  
  port (
    CLK : in std_logic; -- clock
    ARESET : in std_logic; -- async. reset
    SRESET : out std_logic -- sync. reset
    );
  
end sync_reset;

architecture RTL of sync_reset is

  signal reset_counter : unsigned(RESET_COUNTER_WIDTH-1 downto 0) := (others => '0');
  
  signal areset_n : std_logic := '0';
  signal reset_n : std_logic := '0';

begin

  areset_n <= not ARESET;

  process (CLK, areset_n)
  begin
    if (areset_n = '0') then
      reset_counter <= (others => '0');
      reset_n       <= '0';
    elsif (CLK'event and CLK = '1') then
      if to_integer(reset_counter) < RESET_CYCLES then
        reset_counter <= reset_counter + 1;
      else
        reset_n <= '1';
      end if;
    end if;
  end process;
  SRESET <= not reset_n;

end RTL;
