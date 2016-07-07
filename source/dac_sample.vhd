library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity dac_sample is
  generic (
    MAX_COUNT : integer := 1024 * 1024 -- 1M
    );
  port (
    p_Clk : in std_logic;
    p_Reset : in std_logic;
    
    -- p_Clk domain
    p_DAC_KICK       : in  std_logic;
    p_DAC_RUN        : out std_logic;
    p_DAC_DATA_IN    : in  std_logic_vector(127 downto 0);
    p_DAC_DATA_WE    : in  std_logic;
    p_DAC_PROG_FULL  : out std_logic;

    -- p_DAC_Clk domain
    p_DAC_CLK         : in  std_logic;
    p_DAC_DATA_A      : out std_logic_vector(15 downto 0);
    p_DAC_DATA_B      : out std_logic_vector(15 downto 0);
    p_DAC_DATA_EN_PRE : out std_logic;
    p_DAC_DATA_EN     : out std_logic
    );
end dac_sample;

architecture RTL of dac_sample is

  signal w_dac_sample_kick : std_logic := '0';
  signal dac_sample_kick   : std_logic := '0';
  signal dac_sample_kick_d : std_logic := '0';

  type state_type is (IDLE, EMIT0, EMIT1, EMIT2, EMIT3);
  signal state : state_type := IDLE;

  signal emit_counter : unsigned(31 downto 0) := (others => '0');

  signal dac_run : std_logic := '0';

  signal dac_run_r0 : std_logic := '0';
  signal dac_run_r1 : std_logic := '0';

  signal buf_reg_a : std_logic_vector(63 downto 0);
  signal buf_reg_b : std_logic_vector(63 downto 0);

  COMPONENT fifo_16384_128
    PORT (
      rst : IN STD_LOGIC;
      wr_clk : IN STD_LOGIC;
      rd_clk : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
      full : OUT STD_LOGIC;
      prog_full : OUT STD_LOGIC;
      overflow : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      underflow : OUT STD_LOGIC;
      prog_empty : out STD_LOGIC
      );
  END COMPONENT;

  signal w_fifo_dout       : std_logic_vector(127 downto 0) := (others => '0');
  signal w_fifo_re         : std_logic                      := '0';
  signal w_fifo_empty      : std_logic                      := '0';
  signal w_fifo_prog_empty : std_logic                      := '0';

  attribute mark_debug : string;
  attribute keep       : string;

  signal buf_reg_a_d         : std_logic_vector(63 downto 0)  := (others => '0');
  signal buf_reg_b_d         : std_logic_vector(63 downto 0)  := (others => '0');
  signal w_fifo_dout_d       : std_logic_vector(127 downto 0) := (others => '0');
  signal w_fifo_re_d         : std_logic                      := '0';
  signal w_fifo_empty_d      : std_logic                      := '0';
  signal w_fifo_prog_empty_d : std_logic                      := '0';

  attribute mark_debug of buf_reg_a_d         : signal is "true";
  attribute mark_debug of buf_reg_b_d         : signal is "true";
  attribute mark_debug of w_fifo_dout_d       : signal is "true";
  attribute mark_debug of w_fifo_re_d         : signal is "true";
  attribute mark_debug of w_fifo_empty_d      : signal is "true";
  attribute mark_debug of w_fifo_prog_empty_d : signal is "true";

  attribute keep of buf_reg_a_d         : signal is "true";
  attribute keep of buf_reg_b_d         : signal is "true";
  attribute keep of w_fifo_dout_d       : signal is "true";
  attribute keep of w_fifo_re_d         : signal is "true";
  attribute keep of w_fifo_empty_d      : signal is "true";
  attribute keep of w_fifo_prog_empty_d : signal is "true";

begin

  w_dac_sample_kick <= p_DAC_KICK;
  p_DAC_RUN         <= dac_run_r1;

  U_BUF : fifo_16384_128
    PORT map(
      rst       => p_Reset,
      -----------------------------------
      wr_clk    => p_Clk,
      din       => p_DAC_DATA_IN,
      wr_en     => p_DAC_DATA_WE,
      full      => open,
      prog_full => p_DAC_PROG_FULL,
      overflow  => open,
      -----------------------------------
      rd_clk    => p_DAC_CLK,
      rd_en     => w_fifo_re,
      dout      => w_fifo_dout,
      empty     => w_fifo_empty,
      underflow => open,
      prog_empty => w_fifo_prog_empty
      -----------------------------------
      );
    
  process(p_CLK)
  begin
    if(p_CLK'event and p_CLK = '1') then
      dac_run_r0 <= dac_run;
      dac_run_r1 <= dac_run_r0;
    end if;
  end process;

  process(p_DAC_CLK)
  begin
    if(p_DAC_CLK'event and p_DAC_CLK = '1') then

      if p_Reset = '1' then
        dac_sample_kick   <= '0';
        dac_sample_kick_d <= '0';
        w_fifo_re         <= '0';
        dac_run           <= '0';
        p_DAC_DATA_EN     <= '0';
        p_DAC_DATA_EN_PRE <= '0';
      else
        dac_sample_kick   <= w_dac_sample_kick;
        dac_sample_kick_d <= dac_sample_kick;

        case (state) is
          
          ------------------------------------------
          when IDLE =>
            if dac_sample_kick_d = '0' and dac_sample_kick = '1' then  -- rising edge
              state   <= EMIT0;
              dac_run <= '1';
            else
              dac_run <= '0';
            end if;
            emit_counter      <= (others => '0');
            w_fifo_re         <= '0';
            p_DAC_DATA_EN     <= '0';
            p_DAC_DATA_EN_PRE <= '0';
          ------------------------------------------

          ------------------------------------------
          when EMIT0 =>
            emit_counter <= (others => '0');
--            if w_fifo_empty = '0' then
            if w_fifo_prog_empty = '0' then
              w_fifo_re <= '1'; -- start to read
              state <= EMIT1;
            end if;
          ------------------------------------------

          ------------------------------------------
          when EMIT1 =>  -- just consume 1 cycle to ready FIFO data
            emit_counter      <= (others => '0');
            w_fifo_re         <= '0';
            state             <= EMIT2;
          ------------------------------------------

          ------------------------------------------
          when EMIT2 =>
            buf_reg_a <= w_fifo_dout(127 downto 64);
            buf_reg_b <= w_fifo_dout(63 downto 0);
            p_DAC_DATA_EN_PRE <= '1';
            state <= EMIT3;
          ------------------------------------------
            
          ------------------------------------------
          when EMIT3 =>
            p_DAC_DATA_EN     <= '1';
            p_DAC_DATA_EN_PRE <= '0';
            
            if emit_counter < MAX_COUNT then -- before 1M (1024*1024) samples
              emit_counter <= emit_counter + 1;
            else
              emit_counter <= (others => '0');
              state <= IDLE;
            end if;
            

            if emit_counter < MAX_COUNT then -- before 1M (1024*1024) samples

              p_DAC_DATA_A <= buf_reg_a(63 downto 48);
              p_DAC_DATA_B <= buf_reg_b(63 downto 48);
              
              case emit_counter(1 downto 0) is
                when "00" =>
                  buf_reg_a <= buf_reg_a(47 downto 0) & X"0000";
                  buf_reg_b <= buf_reg_b(47 downto 0) & X"0000";
                  w_fifo_re <= '0';
                when "01" =>
                  buf_reg_a <= buf_reg_a(47 downto 0) & X"0000";
                  buf_reg_b <= buf_reg_b(47 downto 0) & X"0000";
                  if emit_counter < X"000FFFFE" then -- except last 1 word
                    w_fifo_re <= '1'; -- for next next
                  else
                    w_fifo_re <= '0';
                  end if;
                when "10" =>
                  buf_reg_a <= buf_reg_a(47 downto 0) & X"0000";
                  buf_reg_b <= buf_reg_b(47 downto 0) & X"0000";
                  w_fifo_re <= '0';
                when "11" =>
                  buf_reg_a <= w_fifo_dout(127 downto 64);
                  buf_reg_b <= w_fifo_dout(63 downto 0);
                  w_fifo_re <= '0';
                when others => null;
              end case;
              
            else
              
              p_DAC_DATA_A <= (others => '0');
              p_DAC_DATA_B <= (others => '0');
              
            end if;
          ------------------------------------------
            
          ------------------------------------------
          when others =>
            null;
          ------------------------------------------
                         
        end case;
        
      end if;
    end if;
  end process;

  process(p_DAC_CLK)
  begin
    if p_DAC_CLK'event and p_DAC_CLK = '1' then
      buf_reg_a_d    <= buf_reg_a;
      buf_reg_b_d    <= buf_reg_b;
      w_fifo_dout_d  <= w_fifo_dout;
      w_fifo_re_d    <= w_fifo_re;
      w_fifo_empty_d <= w_fifo_empty;
      w_fifo_prog_empty_d <= w_fifo_prog_empty;
    end if;
  end process;

end RTL;
