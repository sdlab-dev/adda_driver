library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity adc_sample is

  generic (
    MAX_SAMPLING_POINTS : integer := 512 * 1024 * 1024
  );
  port (
    p_Clk : in std_logic;
    p_Reset : in std_logic;
    
    -- p_Clk domain
    p_ADC_KICK       : in  std_logic;
    p_ADC_RUN        : out std_logic;
    p_ADC_DATA_OUT   : out std_logic_vector(127 downto 0);
    p_ADC_DATA_RE    : in  std_logic;
    p_ADC_DATA_COUNT : out std_logic_vector(31 downto 0);

    p_SAMPLING_POINTS : in std_logic_vector(31 downto 0);
    
    -- p_ADC_Clk domain
    p_ADC_CLK    : in std_logic;
    p_ADC_DATA_A : in std_logic_vector(15 downto 0);
    p_ADC_DATA_B : in std_logic_vector(15 downto 0)
    
    );
end adc_sample;

architecture RTL of adc_sample is

  signal w_adc_sample_kick : std_logic := '0';
  signal adc_sample_kick   : std_logic := '0';
  signal adc_sample_kick_d : std_logic := '0';

  type state_type is (IDLE, RECV);
  signal state : state_type := IDLE;

  signal recv_counter : unsigned(31 downto 0) := (others => '0');

  signal adc_run : std_logic := '0';

  signal adc_run_r0 : std_logic := '0';
  signal adc_run_r1 : std_logic := '0';

  signal buf_reg_a : std_logic_vector(63 downto 0);
  signal buf_reg_b : std_logic_vector(63 downto 0);

  COMPONENT fifo_1024_128
    PORT (
      rst : IN STD_LOGIC;
      wr_clk : IN STD_LOGIC;
      rd_clk : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
      full : OUT STD_LOGIC;
      overflow : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      underflow : OUT STD_LOGIC;
      rd_data_count : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
      );
  END COMPONENT;

  signal w_fifo_din : std_logic_vector(127 downto 0) := (others => '0');
  signal w_fifo_we : std_logic := '0';
  signal w_adc_data_count : std_logic_vector(31 downto 0) := (others => '0');

  attribute mark_debug : string;
  attribute keep       : string;

  signal buf_reg_a_d  : std_logic_vector(63 downto 0) := (others => '0');
  signal buf_reg_b_d  : std_logic_vector(63 downto 0) := (others => '0');
  signal w_fifo_din_d : std_logic_vector(127 downto 0) := (others => '0');
  signal w_fifo_we_d  : std_logic                      := '0';

  attribute mark_debug of buf_reg_a_d  : signal is "true";
  attribute mark_debug of buf_reg_b_d  : signal is "true";
  attribute mark_debug of w_fifo_din_d : signal is "true";
  attribute mark_debug of w_fifo_we_d  : signal is "true";

  attribute keep of buf_reg_a_d  : signal is "true";
  attribute keep of buf_reg_b_d  : signal is "true";
  attribute keep of w_fifo_din_d : signal is "true";
  attribute keep of w_fifo_we_d  : signal is "true";

  signal w_fifo_full      : std_logic;
  signal w_fifo_overflow  : std_logic;
  signal w_fifo_empty     : std_logic;
  signal w_fifo_underflow : std_logic;
  
  signal w_fifo_full_d : std_logic;

  attribute mark_debug of w_fifo_full_d  : signal is "true";
  attribute keep of w_fifo_full_d  : signal is "true";

  signal w_sampling_points : unsigned(31 downto 0);
  attribute mark_debug of w_sampling_points : signal is "true";
  attribute keep of w_sampling_points : signal is "true";
  
begin

  w_adc_sample_kick <= p_ADC_KICK;
  p_ADC_DATA_COUNT  <= w_adc_data_count;
  p_ADC_RUN         <= adc_run_r1;

  U_BUF : fifo_1024_128
    PORT map(
      rst           => p_Reset,
      wr_clk        => p_ADC_CLK,
      rd_clk        => p_Clk,
      din           => w_fifo_din,
      wr_en         => w_fifo_we,
      rd_en         => p_ADC_DATA_RE,
      dout          => p_ADC_DATA_OUT,
      full          => w_fifo_full,
      overflow      => w_fifo_overflow,
      empty         => w_fifo_empty,
      underflow     => w_fifo_underflow,
      rd_data_count => w_adc_data_count(9 downto 0)
      );
  w_adc_data_count(31 downto 10) <= (others => '0');
    
  process(p_CLK)
  begin
    if(p_CLK'event and p_CLK = '1') then
      adc_run_r0 <= adc_run;
      adc_run_r1 <= adc_run_r0;
    end if;
  end process;

  process(p_ADC_CLK)
  begin
    if(p_ADC_CLK'event and p_ADC_CLK = '1') then

      if p_Reset = '1' then
        adc_sample_kick   <= '0';
        adc_sample_kick_d <= '0';
        w_fifo_we         <= '0';
        adc_run           <= '0';
      else
        adc_sample_kick   <= w_adc_sample_kick;
        adc_sample_kick_d <= adc_sample_kick;

        case (state) is
          
          ------------------------------------------
          when IDLE =>
            
            if adc_sample_kick_d = '0' and adc_sample_kick = '1' then  -- rising edge
              state   <= RECV;
              adc_run <= '1';
            else
              adc_run <= '0';
            end if;
            recv_counter <= (others => '0');
            w_fifo_we    <= '0';
            w_sampling_points <= unsigned(p_SAMPLING_POINTS);
          ------------------------------------------
            
          ------------------------------------------
          when RECV =>
--            if recv_counter < X"00100000" then -- before 1M (1024*1024) samples
            if (recv_counter < w_sampling_points) and (recv_counter < MAX_SAMPLING_POINTS) then
              recv_counter <= recv_counter + 1;
            else
              recv_counter <= (others => '0');
              state <= IDLE;
            end if;
            
            case recv_counter(1 downto 0) is
              when "00" =>
                buf_reg_a(63 downto 48) <= p_ADC_DATA_A;
                buf_reg_b(63 downto 48) <= p_ADC_DATA_B;
                w_fifo_we <= '0';
              when "01" =>
                buf_reg_a(47 downto 32) <= p_ADC_DATA_A;
                buf_reg_b(47 downto 32) <= p_ADC_DATA_B;
                w_fifo_we <= '0';
              when "10" =>
                buf_reg_a(31 downto 16) <= p_ADC_DATA_A;
                buf_reg_b(31 downto 16) <= p_ADC_DATA_B;
                w_fifo_we <= '0';
              when "11" =>
                w_fifo_din <= buf_reg_a(63 downto 16) & p_ADC_DATA_A & buf_reg_b(63 downto 16) & p_ADC_DATA_B;
                w_fifo_we <= '1';
              when others => null;
            end case;
          ------------------------------------------
            
          ------------------------------------------
          when others =>
            null;
          ------------------------------------------
                         
        end case;
        
      end if;
    end if;
  end process;

  process(p_ADC_CLK)
  begin
    if p_ADC_CLK'event and p_ADC_CLK = '1' then
      buf_reg_a_d <= buf_reg_a;
      buf_reg_b_d <= buf_reg_b;
      w_fifo_din_d <= w_fifo_din;
      w_fifo_we_d <= w_fifo_we;
      w_fifo_full_d <= w_fifo_full;
    end if;
  end process;

end RTL;
