library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package misc is

  component sync_reset
    
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
  end component sync_reset;


  component dualportram
    generic (
      DEPTH : integer := 10;
      WIDTH : integer := 32;
      WORDS : integer := 1024
      );
    port (
      clk     : in  std_logic;
      reset  : in  std_logic;

      we      : in  std_logic;
      oe      : in  std_logic;
      address : in  signed(31 downto 0);
      din     : in  signed(WIDTH-1 downto 0);
      dout    : out signed(WIDTH-1 downto 0);

      we_b      : in  std_logic;
      oe_b      : in  std_logic;
      address_b : in  signed(31 downto 0);
      din_b     : in  signed(WIDTH-1 downto 0);
      dout_b    : out signed(WIDTH-1 downto 0);

      length : out signed(31 downto 0)
      );
  end component dualportram;

  component simple_dualportram
    generic (
      DEPTH : integer := 10;
      WIDTH : integer := 32;
      WORDS : integer := 1024
      );
    port (
      clk       : in  std_logic;
      reset     : in  std_logic;
      we_b      : in  std_logic;
      oe_b      : in  std_logic;
      length    : out signed(31 downto 0);
      address_b : in  signed(31 downto 0);
      dout_b    : out signed(WIDTH-1 downto 0);
      din_b     : in  signed(WIDTH-1 downto 0)
      );
  end component simple_dualportram;

end misc;
