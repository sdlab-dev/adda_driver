library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity udp_packet_send_in_fifo_with_trigger is

    port (
    p_CLK   : in std_logic;
    p_RESET : in std_logic;
    
    --UDP Input
    pI0Data    : in  std_logic_vector(31 downto 0);
    pI0Request : in  std_logic;
    pI0Ack     : out std_logic;
    pI0En      : in  std_logic;
    -- UDP Output
    pO0Data    : out std_logic_vector(31 downto 0);
    pO0Request : out std_logic;
    pO0Ack     : in  std_logic;
    pO0En      : out std_logic;
        
    -- User port
    p_MY_IP_ADDR     : in std_logic_vector(31 downto 0);
    p_MY_PORT        : in std_logic_vector(15 downto 0);
    p_SERVER_IP_ADDR : in std_logic_vector(31 downto 0);
    p_SERVER_PORT    : in std_logic_vector(15 downto 0);

    -- FIFO write
    p_FIFO_WR_CLK        : in  std_logic;
    p_FIFO_WR_EN         : in  std_logic;
    p_FIFO_DIN           : in  std_logic_vector(31 downto 0);
    p_FIFO_FULL          : out std_logic;
    p_FIFO_WR_DATA_COUNT : out std_logic_vector(9 downto 0);

    p_TRIGGER : out std_logic
    );

end udp_packet_send_in_fifo_with_trigger;

architecture RTL of udp_packet_send_in_fifo_with_trigger is

  attribute mark_debug : string;
  attribute keep       : string;

  type StateType is (IDLE, DATA_WAIT, DUMMY, SEND, READ_ALL);
  signal state : StateType := IDLE;

  signal tx_counter : std_logic_vector(31 downto 0);
  signal rx_counter : unsigned(31 downto 0);

  COMPONENT fifo_1024_32
    PORT (
      rst           : IN  STD_LOGIC;
      wr_clk        : IN  STD_LOGIC;
      rd_clk        : IN  STD_LOGIC;
      din           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      wr_en         : IN  STD_LOGIC;
      rd_en         : IN  STD_LOGIC;
      dout          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      full          : OUT STD_LOGIC;
      overflow      : OUT STD_LOGIC;
      empty         : OUT STD_LOGIC;
      underflow     : OUT STD_LOGIC;
      wr_data_count : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
      rd_data_count : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
      );
  END COMPONENT;

  signal w_fifo_rd_en     : std_logic;
  signal w_fifo_dout      : std_logic_vector(31 downto 0);
  signal w_fifo_dout_reg  : std_logic_vector(31 downto 0);
  signal w_fifo_overflow  : std_logic;
  signal w_fifo_empty     : std_logic;
  signal w_fifo_full      : std_logic;
  signal w_fifo_underflow : std_logic;

  signal fifo_full_dd : std_logic;
  signal fifo_full_d : std_logic;

  signal src_ip        : std_logic_vector(31 downto 0);
  signal dest_ip       : std_logic_vector(31 downto 0);
  signal src_dest_port : std_logic_vector(31 downto 0);

  signal idle_counter : unsigned(31 downto 0) := (others => '0');

  signal w_fifo_rd_data_count : std_logic_vector(9 downto 0);
  
  attribute keep of w_fifo_rd_data_count : signal is "true";
  attribute mark_debug of w_fifo_rd_data_count : signal is "true";

begin  -- RTL

  p_FIFO_FULL <= w_fifo_full;
  
  process (p_CLK)
  begin  -- process
    if p_CLK'event and p_CLK = '1' then
      if p_RESET = '1' then
        state        <= IDLE;
        pI0Ack       <= '0';
        pO0Request   <= '0';
        pO0En        <= '0';
        p_TRIGGER    <= '0';
      else

        case state is
          
          when IDLE =>
            if pI0En = '1' then         -- An UDP packet is arrived.
              state      <= DATA_WAIT;
              pI0Ack     <= '0';
              p_TRIGGER  <= '1';
              rx_counter <= rx_counter + 1;
              src_ip     <= pI0Data;
            else
              pI0Ack     <= '1';
              rx_counter <= (others => '0');
            end if;
            tx_counter   <= (others => '0');
            pO0Request   <= '0';
            pO0En        <= '0';
            w_fifo_rd_en <= '0';
            idle_counter <= (others => '0');
            pO0Data      <= (others => '0');

          when DATA_WAIT =>
            if w_fifo_empty = '0' then -- after starting data receiving
              p_TRIGGER <= '0';
            end if;

            if w_fifo_empty = '0' and unsigned(w_fifo_rd_data_count) >= 256 and pI0En = '0' then
              state <= SEND;
              idle_counter <= (others => '0');
            end if;

            rx_counter <= rx_counter + 1;
            
            case to_integer(rx_counter) is
              when 1 => dest_ip <= pI0Data;
              when 2 => src_dest_port <= pI0Data;
              when others => null;
            end case;

          when SEND =>

            w_fifo_dout_reg <= w_fifo_dout;
            
            if to_integer(unsigned(tx_counter)) > 0 then  -- during packet sending
              tx_counter <= std_logic_vector(unsigned(tx_counter) + 1);
            elsif pO0Ack = '1' then     -- ready to send UDP packet
              pO0Request <= '0';
              pO0En      <= '1';        -- start to send a UDP packet
              tx_counter <= std_logic_vector(to_unsigned(1, tx_counter'length));
            else -- ack = '0' and tx_counter = 0 (= before packet sending)
              pO0Request <= '1';
            end if;
            
            case to_integer(unsigned(tx_counter)) is
              when 0 => pO0Data <= src_ip;  -- p_MY_IP_ADDR;
              when 1 => pO0Data <= dest_ip; -- p_SERVER_IP_ADDR;
                        w_fifo_rd_en <= '1'; -- for next next
              when 2 => pO0Data <= src_dest_port; -- p_MY_PORT & p_SERVER_PORT;
              when 3 => pO0Data <= X"00000400";  -- 1024
              when others =>
                pO0Data <= w_fifo_dout_reg;
                if to_integer(unsigned(tx_counter)) - 4 = 255 then -- last word (- (/ 1024 4) 1)
                  state <= READ_ALL;
--                elsif to_integer(unsigned(tx_counter)) - 4 = 252 then
--                  w_fifo_rd_en <= '0'; -- for next next
                end if;
            end case;

          when READ_ALL =>
            
            pO0Request   <= '0';
            pO0En        <= '0';
            
            if w_fifo_empty = '0' then
              w_fifo_rd_en <= '1';
            else
              w_fifo_rd_en <= '0';
              state <= IDLE;
            end if;
            
          when others =>
            state <= IDLE;
        end case;
      end if;
    end if;
  end process;

  U: fifo_1024_32 PORT map(
      rst           => p_RESET,
      wr_clk        => p_FIFO_WR_CLK,
      rd_clk        => p_CLK,
      din           => p_FIFO_DIN,
      wr_en         => p_FIFO_WR_EN,
      rd_en         => w_fifo_rd_en,
      dout          => w_fifo_dout,
      full          => w_fifo_full,
      overflow      => w_fifo_overflow,
      empty         => w_fifo_empty,
      underflow     => w_fifo_underflow,
      wr_data_count => p_FIFO_WR_DATA_COUNT,
      rd_data_count => w_fifo_rd_data_count
      );
  
end RTL;
