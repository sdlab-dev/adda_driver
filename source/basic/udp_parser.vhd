library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.constants.all;
use work.misc.all;

entity udp_parser is
  port (
    -- main
    p_CLK   : in std_logic;
    p_RESET : in std_logic;

    p_LED            : out std_logic;
    p_ADC_KICK       : out std_logic;
    p_ADC_RUN        : in  std_logic;
    p_ADC_ADDR_RESET : out std_logic;
    p_DAC_KICK       : out std_logic;
    p_DAC_RUN        : in  std_logic;
    p_ADC_KICK_AFTER_DAC_START : out std_logic;
    p_ADDA_SAMPLING_POINTS     : out std_logic_vector(31 downto 0);
    p_ADDA_SAMPLING_POINTS_WE  : out std_logic;

    -- UDP input
    p_UDP_RX_DATA    : in  std_logic_vector(31 downto 0);
    p_UDP_RX_REQUEST : in  std_logic;
    p_UDP_RX_ACK     : out std_logic;
    p_UDP_RX_ENABLE  : in  std_logic;

    -- UDP output
    p_UDP_TX_DATA    : out std_logic_vector(31 downto 0);
    p_UDP_TX_REQUEST : out std_logic;
    p_UDP_TX_ACK     : in  std_logic;
    p_UDP_TX_ENABLE  : out std_logic;

    -- DRAM (DDR3) input
    p_DRAM_RX_DATA    : in std_logic_vector(127 downto 0);
    p_DRAM_RX_REQUEST : in std_logic;
    p_DRAM_RX_ACK     : out  std_logic;
    p_DRAM_RX_ENABLE  : in std_logic;

    -- DRAM (DDR3) output
    p_DRAM_TX_DATA    : out std_logic_vector(127 downto 0);
    p_DRAM_TX_REQUEST : out std_logic;
    p_DRAM_TX_ACK     : in  std_logic;
    p_DRAM_TX_ENABLE  : out std_logic;

    -- setting
    p_MY_IP_ADDR     : in std_logic_vector(31 downto 0);
    p_MY_PORT        : in std_logic_vector(15 downto 0);
    p_SERVER_IP_ADDR : in std_logic_vector(31 downto 0);
    p_SERVER_PORT    : in std_logic_vector(15 downto 0);

    p_DEBUG : out std_logic_vector(7 downto 0)
    );
end udp_parser;

architecture rtl of udp_parser is

  constant DEFAULT_ADDA_SAMPLING_POINTS : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1 * 1024 * 1024, 32));
  constant MIN_POINTS : unsigned(31 downto 0) := to_unsigned(1 * 1024 * 1024, 32);
  constant MAX_POINTS : unsigned(31 downto 0) := to_unsigned(128 * 1024 * 1024, 32);


  type state_type is (STATE_IDLE,
                      STATE_RX_UDP,
                      STATE_TX_ACK, STATE_TX_NACK, STATE_TX_BRAM,
                      STATE_CMD_ACK, STATE_CMD_NULL,
                      STATE_CMD_LED_ON, STATE_CMD_LED_OFF,
                      STATE_CMD_BRAM_WRITE, STATE_CMD_BRAM_READ,
                      STATE_CMD_KICK_DRAMREAD, STATE_CMD_KICK_DRAMWRITE,
                      STATE_CMD_AD_START, STATE_CMD_DA_START, STATE_CMD_DA_AD_START);
  signal state : state_type := STATE_IDLE;

  type sub_state_type is (SUB_DRAM_WAIT_ACK,
                          SUB_DRAM_SENDING,
                          SUB_DRAM_START_RECV,
                          SUB_DRAM_WAIT_ENABLE,
                          SUB_DRAM_RECEIVING);
  signal sub_state : sub_state_type := SUB_DRAM_WAIT_ACK;

  type adc_state_type is (ADC_PREPARE,
                          ADC_KICK,
                          ADC_START_WAIT,
                          ADC_STOP_WAIT
                          );
  signal adc_state : adc_state_type := ADC_PREPARE;

  type dac_state_type is (DAC_PREPARE,
                          DAC_KICK,
                          DAC_START_WAIT,
                          DAC_STOP_WAIT
                          );
  signal dac_state : dac_state_type := DAC_PREPARE;

  type dac_adc_state_type is (DAC_ADC_PREPARE,
                              DAC_ADC_KICK,
                              DAC_ADC_START_WAIT,
                              DAC_ADC_STOP_WAIT
                              );
  signal dac_adc_state : dac_adc_state_type := DAC_ADC_PREPARE;
  
  signal tx_counter : signed(31 downto 0);
  signal rx_counter : signed(31 downto 0);

  signal src_ip_addr    : std_logic_vector(31 downto 0);
  signal dst_ip_addr    : std_logic_vector(31 downto 0);
  signal src_port       : std_logic_vector(15 downto 0);
  signal dst_port       : std_logic_vector(15 downto 0);
  signal payload_length : unsigned(31 downto 0);

----- begin bram signals
  signal w_ram_addr       : signed(31 downto 0) := (others => '0');
  signal w_ram_write_en   : std_logic;
  signal w_ram_read_data  : signed(127 downto 0);
  signal w_ram_write_data : std_logic_vector(127 downto 0);
  signal w_ram_read_en    : std_logic;
----- end bram signals

  signal led            : std_logic := '0';
  
  signal ram_write_buf  : std_logic_vector(127 downto 0) := (others => '0');
  signal ram_write_addr : signed(31 downto 0) := (others => '0');

----- begin rtl -----
begin
----- begin local connections
  p_LED <= led;
----- end local connections
  
----- begin bram -----
  BUF: simple_dualportram
    generic map(
      DEPTH => 7,
      WIDTH => 128,
      WORDS => 128
      )
    port map(
      clk       => p_CLK,
      reset     => p_RESET,
      we_b      => w_ram_write_en,
      oe_b      => w_ram_read_en,
      length    => open,
      address_b => w_ram_addr,
      dout_b    => w_ram_read_data,
      din_b     => signed(w_ram_write_data)
      );
  w_ram_read_en <= '1';

----- end bram -----

  process (p_CLK)
  begin  -- process
    if p_CLK'event and p_CLK = '1' then
      if p_RESET = '1' then
        state            <= STATE_IDLE;
        p_UDP_RX_ACK     <= '0';
        p_UDP_TX_REQUEST <= '0';
        p_UDP_TX_ENABLE  <= '0';
        tx_counter       <= (others => '0');
        rx_counter       <= (others => '0');
        p_DEBUG          <= X"11";

        w_ram_write_en <= '0';
        w_ram_addr     <= (others => '0');
        
        led <= '0';
        p_ADDA_SAMPLING_POINTS_WE <= '0';
      else
        case state is
          when STATE_IDLE =>
            if p_UDP_RX_ENABLE = '1' then  -- An UDP packet is arrived.
              state        <= STATE_RX_UDP;
              src_ip_addr  <= p_UDP_RX_DATA;        -- 1st DWORD is source port
              rx_counter   <= to_signed(1, rx_counter'length);
              p_UDP_RX_ACK <= '0';
            else
              rx_counter   <= (others => '0');
              p_UDP_RX_ACK <= '1';
            end if;
            tx_counter        <= (others => '0');
            p_UDP_TX_REQUEST  <= '0';
            p_UDP_TX_ENABLE   <= '0';
            p_DRAM_TX_REQUEST <= '0';
            p_DRAM_TX_ENABLE  <= '0';
            w_ram_write_en    <= '0';
            w_ram_addr        <= (others => '0');
            p_ADC_KICK        <= '0';
            p_DAC_KICK        <= '0';
            p_ADC_KICK_AFTER_DAC_START <= '0';
            p_ADDA_SAMPLING_POINTS_WE <= '0';
            p_ADDA_SAMPLING_POINTS <= DEFAULT_ADDA_SAMPLING_POINTS;
          when STATE_RX_UDP =>
            p_UDP_RX_ACK <= '0';
            if p_UDP_RX_ENABLE = '0' then
              state <= STATE_TX_ACK;
            else
              rx_counter <= rx_counter + 1;
              case to_integer(rx_counter) is
                when 0 =>
                  null;                 -- consume 1st DWORD at previous state
                  
                when 1 =>
                  dst_ip_addr <= p_UDP_RX_DATA;
                  
                when 2 =>
                  dst_port <= p_UDP_RX_DATA(31 downto 16);
                  src_port <= p_UDP_RX_DATA(15 downto 0);
                  
                when 3 =>
                  payload_length <= unsigned(p_UDP_RX_DATA);  -- Length
                  
                when 4 =>

                  case p_UDP_RX_DATA is
                    
                    when X"00000000" =>
                      p_ADC_ADDR_RESET <= '1';
                      state <= STATE_CMD_ACK;
                      
                    when X"00000001" =>
                      state   <= STATE_CMD_LED_ON;
                      p_DEBUG <= X"FF";
                      
                    when X"00000002" =>
                      state   <= STATE_CMD_LED_OFF;
                      p_DEBUG <= X"00";
                      
                    when X"00000003" =>
                      state          <= STATE_CMD_BRAM_WRITE;
                      w_ram_write_en <= '1';
                      ram_write_addr <= (others => '0');
                      
                    when X"00000004" =>
                      state <= STATE_CMD_BRAM_READ;
                      
                    when X"00000005" =>
                      state             <= STATE_CMD_KICK_DRAMREAD;
                      p_DRAM_TX_REQUEST <= '1';
                      sub_state         <= SUB_DRAM_WAIT_ACK;
                      w_ram_addr        <= (others => '0');
                      
                    when X"00000006" =>
                      state             <= STATE_CMD_KICK_DRAMWRITE;
                      p_DRAM_TX_REQUEST <= '1';
                      w_ram_addr        <= (others => '0');
                      sub_state         <= SUB_DRAM_WAIT_ACK;
                      
                    when X"00000007" =>
                      state            <= STATE_CMD_AD_START;
                      p_ADC_ADDR_RESET <= '1';
                      adc_state        <= ADC_PREPARE;
                      
                    when X"00000008" =>
                      state            <= STATE_CMD_DA_START;
                      dac_state        <= DAC_PREPARE;
                      
                    when X"00000009" =>
                      state            <= STATE_CMD_DA_AD_START;
                      dac_adc_state    <= DAC_ADC_PREPARE;

                    when others =>
                      state <= STATE_CMD_NULL;
                      
                  end case;
                  
                when others =>          -- receiving payload
                  null;
              end case;
            end if;
            
          when STATE_CMD_ACK =>
            p_UDP_RX_ACK <= '0';
            p_ADC_ADDR_RESET <= '0';
            if p_UDP_RX_ENABLE = '0' then
              state <= STATE_TX_ACK;
            end if;

          when STATE_CMD_NULL =>
            p_UDP_RX_ACK <= '0';
            if p_UDP_RX_ENABLE = '0' then
              state <= STATE_TX_NACK;
            end if;
            
          when STATE_CMD_LED_ON =>
            p_UDP_RX_ACK <= '0';
            led          <= '1';
            if p_UDP_RX_ENABLE = '0' then
              state <= STATE_TX_ACK;
            end if;
            
          when STATE_CMD_LED_OFF =>
            p_UDP_RX_ACK <= '0';
            led          <= '0';
            if p_UDP_RX_ENABLE = '0' then
              state <= STATE_TX_ACK;
            end if;
            
          when STATE_CMD_BRAM_WRITE =>
            p_UDP_RX_ACK <= '0';
            if p_UDP_RX_ENABLE = '0' then
              state          <= STATE_TX_ACK;
              w_ram_write_en <= '0';
            end if;
            ------ BRAMへのデータの書き込み
            ------ rx_counterは5スタート
            rx_counter <= rx_counter + 1;

            if ((rx_counter - 5) and X"00000003") = 0 then
              w_ram_write_en               <= '0';
              ram_write_buf(127 downto 96) <= p_UDP_RX_DATA;
            elsif ((rx_counter - 5) and X"00000003") = 1 then
              w_ram_write_en              <= '0';
              ram_write_buf(95 downto 64) <= p_UDP_RX_DATA;
            elsif ((rx_counter - 5) and X"00000003") = 2 then
              w_ram_write_en              <= '0';
              ram_write_buf(63 downto 32) <= p_UDP_RX_DATA;
            elsif ((rx_counter - 5) and X"00000003") = 3 then
              w_ram_write_en   <= '1';
              w_ram_addr       <= ram_write_addr;
              ram_write_addr   <= ram_write_addr + 1;
              w_ram_write_data <= ram_write_buf(127 downto 32) & p_UDP_RX_DATA;
            end if;
            
          when STATE_CMD_BRAM_READ =>
            p_UDP_RX_ACK <= '0';
            if p_UDP_RX_ENABLE = '0' then
              state <= STATE_TX_BRAM;
            end if;
---------- begin STATE_CMD_KICK_DRAMREAD
          when STATE_CMD_KICK_DRAMREAD =>
            p_UDP_RX_ACK <= '0';
            case sub_state is
              when SUB_DRAM_WAIT_ACK =>
                if(p_DRAM_TX_ACK = '1') then
                  sub_state         <= SUB_DRAM_SENDING;
                  p_DRAM_TX_REQUEST <= '0';
                  tx_counter        <= (others => '0');
                  ram_write_addr    <= (others => '0');
                end if;
                w_ram_addr     <= (others => '0');
                w_ram_write_en <= '0';
              when SUB_DRAM_SENDING =>
                p_DRAM_TX_ENABLE <= '1';
                p_DRAM_TX_DATA   <= std_logic_vector(w_ram_read_data);
                if tx_counter = 3 then
                  sub_state     <= SUB_DRAM_START_RECV;
                  p_DRAM_RX_ACK <= '1';
                  tx_counter    <= (others => '0');
                else
                  tx_counter <= tx_counter + 1;
                end if;
              when SUB_DRAM_START_RECV =>
                p_DRAM_TX_ENABLE <= '0';
                p_DRAM_RX_ACK    <= '1';
                sub_state        <= SUB_DRAM_WAIT_ENABLE;
                w_ram_write_en   <= '0';
                ram_write_addr   <= (others => '0');
              when SUB_DRAM_WAIT_ENABLE =>
                if(p_DRAM_RX_ENABLE = '1') then
                  p_DRAM_RX_ACK    <= '0';
                  -- drop the first data, which is response header from e7MemIface
--                  ram_write_addr   <= ram_write_addr + 1;
--                  w_ram_addr       <= ram_write_addr;
--                  w_ram_write_data <= p_DRAM_RX_DATA;
--                  w_ram_write_en   <= '1';
                  w_ram_write_en   <= '1';
                  sub_state        <= SUB_DRAM_RECEIVING;
                end if;
              when SUB_DRAM_RECEIVING =>
                p_DRAM_RX_ACK <= '0';
                if(p_DRAM_RX_ENABLE = '1') then
                  ram_write_addr   <= ram_write_addr + 1;
                  w_ram_addr       <= ram_write_addr;
                  w_ram_write_data <= p_DRAM_RX_DATA;
                  w_ram_write_en   <= '1';
                else
                  w_ram_write_en <= '0';
                  state          <= STATE_TX_ACK;
                  tx_counter     <= (others => '0');
                end if;
            end case;
---------- end STATE_CMD_BRAM2DRAM
---------- begin STATE_CMD_KICK_DRAMWRITE
          when STATE_CMD_KICK_DRAMWRITE =>
            p_UDP_RX_ACK <= '0';
            case sub_state is
              when SUB_DRAM_WAIT_ACK =>
                if(p_DRAM_TX_ACK = '1') then
                  sub_state         <= SUB_DRAM_SENDING;
                  p_DRAM_TX_REQUEST <= '0';
                  tx_counter        <= (others => '0');
                  ram_write_addr    <= (others => '0');
                  w_ram_addr        <= w_ram_addr + 1;  -- for next next
                else
                  p_DRAM_TX_REQUEST <= '1';
                end if;
                tx_counter     <= (others => '0');
                w_ram_write_en <= '0';
                p_DRAM_RX_ACK  <= '0';
              when SUB_DRAM_SENDING =>
                p_DRAM_TX_ENABLE <= '1';
                p_DRAM_TX_DATA   <= std_logic_vector(w_ram_read_data);
                w_ram_addr       <= w_ram_addr + 1;     -- for next next
                tx_counter       <= tx_counter + 1;
                if(tx_counter = 64+1-1) then            -- cmd(1) + data(64)
                  sub_state      <= SUB_DRAM_START_RECV;
                  ram_write_addr <= (others => '0');
                end if;
                p_DRAM_RX_ACK <= '0';
              when SUB_DRAM_START_RECV =>
                p_DRAM_TX_ENABLE <= '0';
                p_DRAM_RX_ACK    <= '1';
                sub_state        <= SUB_DRAM_WAIT_ENABLE;
                ram_write_addr   <= (others => '0');
              when SUB_DRAM_WAIT_ENABLE =>
                if(p_DRAM_RX_ENABLE = '1') then
                  ram_write_addr   <= ram_write_addr + 1;
                  w_ram_addr       <= ram_write_addr;
                  w_ram_write_data <= p_DRAM_RX_DATA;
                  w_ram_write_en   <= '1';
                  sub_state        <= SUB_DRAM_RECEIVING;
                  p_DRAM_RX_ACK    <= '0';
                else
                  p_DRAM_RX_ACK <= '1';
                end if;
              when SUB_DRAM_RECEIVING =>
                p_DRAM_RX_ACK <= '0';
                if(p_DRAM_RX_ENABLE = '1') then
                  ram_write_addr   <= ram_write_addr + 1;
                  w_ram_addr       <= ram_write_addr;
                  w_ram_write_data <= p_DRAM_RX_DATA;
                  w_ram_write_en   <= '1';
                else
                  state          <= STATE_TX_ACK;
                  tx_counter     <= (others => '0');
                  w_ram_write_en <= '0';
                end if;
            end case;
---------- end STATE_CMD_DRAM_WRITE
--------- begin STATE_CMD_AD_START
          when STATE_CMD_AD_START =>
            case adc_state is
              when ADC_PREPARE =>
                if p_UDP_RX_ENABLE = '1' and
                   payload_length > 4 and
                   unsigned(p_UDP_RX_DATA) >= MIN_POINTS and
                   unsigned(p_UDP_RX_DATA) <= MAX_POINTS then
                  p_ADDA_SAMPLING_POINTS <= p_UDP_RX_DATA;
                end if;
                adc_state <= ADC_KICK;
                p_ADDA_SAMPLING_POINTS_WE <= '1';
              when ADC_KICK =>
                p_ADC_ADDR_RESET <= '0';
                p_ADC_KICK <= '1';
                adc_state <= ADC_START_WAIT;
              when ADC_START_WAIT =>
                if p_ADC_RUN = '1' then
                  p_ADC_KICK <= '0';
                  adc_state <= ADC_STOP_WAIT;
                  p_ADDA_SAMPLING_POINTS_WE <= '0';
                else
                  p_ADC_KICK <= '1';
                  p_ADDA_SAMPLING_POINTS_WE <= '1';
                end if;
              when ADC_STOP_WAIT =>
                if p_ADC_RUN = '0' and p_UDP_RX_ENABLE = '0' then
                  state <= STATE_TX_ACK;
                end if;
              when others => null;
            end case;
--------- end STATE_CMD_AD_START
--------- begin STATE_CMD_DA_START
          when STATE_CMD_DA_START =>
            case dac_state is
              when DAC_PREPARE =>
                if p_UDP_RX_ENABLE = '1' and
                   payload_length > 4 and
                   unsigned(p_UDP_RX_DATA) >= MIN_POINTS and
                   unsigned(p_UDP_RX_DATA) <= MAX_POINTS then
                  p_ADDA_SAMPLING_POINTS <= p_UDP_RX_DATA;
                end if;
                dac_state <= DAC_KICK;
                p_ADDA_SAMPLING_POINTS_WE <= '1';
              when DAC_KICK =>
                p_DAC_KICK <= '1';
                dac_state <= DAC_START_WAIT;
                p_ADDA_SAMPLING_POINTS_WE <= '1';
              when DAC_START_WAIT =>
                if p_DAC_RUN = '1' then
                  p_DAC_KICK <= '0';
                  dac_state <= DAC_STOP_WAIT;
                  p_ADDA_SAMPLING_POINTS_WE <= '0';
                else
                  p_DAC_KICK <= '1';
                  p_ADDA_SAMPLING_POINTS_WE <= '1';
                end if;
              when DAC_STOP_WAIT =>
                if p_DAC_RUN = '0' and p_UDP_RX_ENABLE = '0' then
                  state <= STATE_TX_ACK;
                end if;
              when others => null;
            end case;
--------- end STATE_CMD_DA_START
--------- begin STATE_CMD_DA_AD_START
          when STATE_CMD_DA_AD_START =>
            case dac_adc_state is
              when DAC_ADC_PREPARE =>
                if p_UDP_RX_ENABLE = '1' and
                   payload_length > 4 and
                   unsigned(p_UDP_RX_DATA) >= MIN_POINTS and
                   unsigned(p_UDP_RX_DATA) <= MAX_POINTS then
                  p_ADDA_SAMPLING_POINTS <= p_UDP_RX_DATA;
                end if;
                dac_adc_state <= DAC_ADC_KICK;
                p_ADDA_SAMPLING_POINTS_WE <= '1';
              when DAC_ADC_KICK =>
                p_DAC_KICK <= '1';
                p_ADC_KICK_AFTER_DAC_START <= '1';
                dac_adc_state <= DAC_ADC_START_WAIT;
                p_ADC_ADDR_RESET <= '0';
                
              when DAC_ADC_START_WAIT =>
                if p_DAC_RUN = '1' then
                  p_DAC_KICK <= '0';
                else
                  p_DAC_KICK <= '1';
                end if;
                if p_ADC_RUN = '1' then -- ADC must start after DAC started
                  p_ADC_KICK_AFTER_DAC_START <= '0';
                  dac_adc_state <= DAC_ADC_STOP_WAIT;
                  p_ADDA_SAMPLING_POINTS_WE <= '0';
                else
                  p_ADC_KICK_AFTER_DAC_START <= '1';
                  p_ADDA_SAMPLING_POINTS_WE <= '1';
                end if;
                
              when DAC_ADC_STOP_WAIT =>
                if p_ADC_RUN = '0' and p_UDP_RX_ENABLE = '0' then
                  state <= STATE_TX_ACK;
                end if;
                
              when others => null;
            end case;
--------- end STATE_CMD_DA_AD_START
--------- begin STATE_TX_ACK
          when STATE_TX_ACK =>
            if(tx_counter > 0)then
              tx_counter <= tx_counter + 1;
            elsif p_UDP_TX_ACK = '1' then  -- ready to send UDP packet
              p_UDP_TX_REQUEST <= '0';
              p_UDP_TX_ENABLE  <= '1';  -- start to send a UDP packet

              tx_counter <= to_signed(1, tx_counter'length);
            else  -- ack = '0' and tx_counter = 0 (= before packet sending)
              p_UDP_TX_REQUEST <= '1';
            end if;

            case to_integer(tx_counter) is
              when 0 =>
                p_UDP_TX_DATA <= src_ip_addr;
              when 1 =>
                p_UDP_TX_DATA <= dst_ip_addr;
              when 2 =>
                p_UDP_TX_DATA <= dst_port & src_port;
              when 3 =>                 -- payload_length
                p_UDP_TX_DATA <= X"00000004";
              when 4 =>
                p_UDP_TX_DATA <= X"00000001";
                state         <= STATE_IDLE;
              when others =>
                state <= STATE_IDLE;
            end case;
--------- end STATE_TX_ACK
--------- begin STATE_TX_NACK
          when STATE_TX_NACK =>
            if tx_counter > 0 then
              tx_counter <= tx_counter + 1;
            elsif p_UDP_TX_ACK = '1' then  -- ready to send UDP packet
              p_UDP_TX_REQUEST <= '0';
              p_UDP_TX_ENABLE  <= '1';  -- start to send a UDP packet
              tx_counter       <= to_signed(1, tx_counter'length);
            else  -- ack = '0' and tx_counter = 0 (= before packet sending)
              p_UDP_TX_REQUEST <= '1';
            end if;

            case to_integer(tx_counter) is
              when 0 =>
                p_UDP_TX_DATA <= src_ip_addr;
              when 1 =>
                p_UDP_TX_DATA <= dst_ip_addr;
              when 2 =>
                p_UDP_TX_DATA <= dst_port & src_port;
              when 3 =>                 --length
                p_UDP_TX_DATA <= X"00000004";
              when 4 =>
                p_UDP_TX_DATA <= X"00000000";
                state         <= STATE_IDLE;
              when others =>
                state <= STATE_IDLE;
            end case;
--------- end STATE_TX_NACK
--------- begin STATE_TX_BRAM
          when STATE_TX_BRAM =>
            
            if tx_counter >= 260 then
              state <= STATE_IDLE;
            elsif tx_counter > 0 then
              tx_counter <= tx_counter + 1;
            elsif p_UDP_TX_ACK = '1' then  -- ready to send UDP packet
              p_UDP_TX_REQUEST <= '0';
              p_UDP_TX_ENABLE  <= '1';  -- start to send a UDP packet
              tx_counter       <= to_signed(1, tx_counter'length);
            else  -- ack = '0' and tx_counter = 0 (= before packet sending)
              p_UDP_TX_REQUEST <= '1';
            end if;

            case to_integer(tx_counter) is
              when 0 =>
                p_UDP_TX_DATA <= src_ip_addr;
              when 1 =>
                p_UDP_TX_DATA <= dst_ip_addr;
              when 2 =>
                p_UDP_TX_DATA <= dst_port & src_port;
              when 3 =>                        -- length
                p_UDP_TX_DATA <= X"00000404";
                w_ram_addr <= (others => '0'); -- for next next cycle
              when 4 =>
                p_UDP_TX_DATA <= X"00000002";  --- means BRAM
              when others =>
                if ((tx_counter - 5) and X"00000003") = 0 then
                  p_UDP_TX_DATA <= std_logic_vector(w_ram_read_data(127 downto 96));
                elsif ((tx_counter - 5) and X"00000003") = 1 then
                  p_UDP_TX_DATA <= std_logic_vector(w_ram_read_data(95 downto 64));
                elsif ((tx_counter - 5) and X"00000003") = 2 then
                  p_UDP_TX_DATA <= std_logic_vector(w_ram_read_data(63 downto 32));
                  w_ram_addr <= w_ram_addr + 1; -- for next next cycle
                elsif ((tx_counter - 5) and X"00000003") = 3 then
                  p_UDP_TX_DATA <= std_logic_vector(w_ram_read_data(31 downto 0));
                end if;
            end case;

--------- end STATE_TX_BRAM
          when others =>
            state <= STATE_IDLE;
        end case;
      end if;
    end if;
  end process;
end rtl;
--- end rtl
