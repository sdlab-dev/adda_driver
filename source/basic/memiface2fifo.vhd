library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity memiface2fifo is
  generic (
    MAX_COUNT : integer := 1 * 1024 * 1024
    );
  port (
    p_Clk : in std_logic;
    p_Reset : in std_logic;

    p_KICK : in  std_logic;
    p_BUSY : out std_logic;

    p_DDR3_MEMORY_OFFSET : in std_logic_vector(31 downto 0);
    p_READ_WRITE_COUNT : in std_logic_vector(31 downto 0);
    
    p_FIFO_DATA_OUT   : out  std_logic_vector(127 downto 0);
    p_FIFO_DATA_WE    : out std_logic;
    p_FIFO_PROG_FULL  : in  std_logic;

    p_MemIface_UPL_Enable  : out std_logic;
    p_MemIface_UPL_Request : out std_logic;
    p_MemIface_UPL_Ack     : in  std_logic;
    p_MemIface_UPL_Data    : out std_logic_vector(127 downto 0);

    p_MemIface_UPL_Reply_Ack     : out std_logic;
    p_MemIface_UPL_Reply_En      : in  std_logic;
    p_MemIface_UPL_Reply_Data    : in  std_logic_vector(127 downto 0);
    p_MemIface_UPL_Reply_Request : in  std_logic
    );
end memiface2fifo;

architecture RTL of memiface2fifo is

  constant TX_COUNT_STEP : integer := 256; -- "1024 byte" corresponds to "256 samples for 2ch",
                                           -- because a sample/ch is 2Byte.
  constant RX_COUNT_STEP : integer := 4;   -- "128 bit" corresponds to "4 samples for 2ch",
                                           -- because a sample/ch is 16bit.
  constant BURST_READ_BYTES : integer := 1024; -- 32words * 32bytes/word
    
  attribute mark_debug : string;
  attribute keep       : string;

  type emit_state_type is (EMIT_IDLE, EMIT_RUN, EMIT_UPLACK_WAIT_AND_READ_REQ, EMIT_RUN_NEXT);
  type recv_state_type is (RECV_IDLE, RECV_RUN, RECV_WAIT_REPLY, RECV_REPLY_DATA);
  signal emit_state : emit_state_type := EMIT_IDLE;
  signal recv_state : recv_state_type := RECV_IDLE;

  signal tx_count : unsigned(31 downto 0) := (others => '0');
  signal rx_count : unsigned(31 downto 0) := (others => '0');

  signal address : unsigned(31 downto 0) := (others => '0');

  signal reg_kick : std_logic;
  signal reg_busy : std_logic := '0';


  signal tx_count_d : std_logic_vector(31 downto 0);
  signal rx_count_d : std_logic_vector(31 downto 0);
  signal prog_full_d : std_logic;

  attribute mark_debug of tx_count_d  : signal is "true";
  attribute mark_debug of rx_count_d  : signal is "true";
  attribute mark_debug of prog_full_d : signal is "true";
  
  attribute keep of tx_count_d  : signal is "true";
  attribute keep of rx_count_d  : signal is "true";
  attribute keep of prog_full_d : signal is "true";

  signal w_read_count : unsigned(31 downto 0);
  
  signal w_read_count_d : std_logic_vector(31 downto 0);
  attribute mark_debug of w_read_count_d : signal is "true";
  attribute keep of w_read_count_d : signal is "true";

begin

  p_BUSY <= reg_busy;

  EMIT_REQUEST : process(p_Clk)
  begin
    if p_Clk'event and p_Clk = '1' then
      if p_Reset = '1' then
        p_MemIface_UPL_Enable  <= '0';
        p_MemIface_UPL_Request <= '0';
        emit_state             <= EMIT_IDLE;
      else

        case emit_state is
          ---------------------------------------------------------------------
          -- wait for kick
          ---------------------------------------------------------------------
          when EMIT_IDLE =>
            if p_KICK = '1' and reg_kick = '0' then  -- rising edge of p_KICK
              emit_state <= EMIT_RUN;
            end if;
--            address                <= (others => '0');
            address                <= unsigned(p_DDR3_MEMORY_OFFSET);
            tx_count               <= (others => '0');
            p_MemIface_UPL_Enable  <= '0';
            p_MemIface_UPL_Request <= '0';
            w_read_count <= unsigned(p_READ_WRITE_COUNT);
            
          ---------------------------------------------------------------------
          -- RUN
          ---------------------------------------------------------------------
          when EMIT_RUN =>
            p_MemIface_UPL_Request <= '1';  -- to emit memory read request
            p_MemIface_UPL_Enable  <= '0';
            emit_state             <= EMIT_UPLACK_WAIT_AND_READ_REQ;
            p_MemIface_UPL_DATA    <= X"FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFE";
          ---------------------------------------------------------------------

          ---------------------------------------------------------------------
          -- EMIT MEMORY READ REQUEST PACKET
          ---------------------------------------------------------------------
          when EMIT_UPLACK_WAIT_AND_READ_REQ =>
            if p_MemIface_UPL_Ack = '1' then
              p_MemIface_UPL_Enable  <= '1';
              -- command = read command (X"01")
              -- length = 32 words, 32bytes/word (X"20"), 
              p_MemIface_UPL_DATA    <= X"00000000" & X"0000" & X"01" & X"20" & X"00000000" & std_logic_vector(address);
              p_MemIface_UPL_Request <= '0';
              tx_count               <= tx_count + TX_COUNT_STEP;

              --if tx_count = MAX_COUNT - TX_COUNT_STEP then  -- last request
              if (tx_count + TX_COUNT_STEP = w_read_count) or (tx_count + TX_COUNT_STEP = MAX_COUNT) then  -- last request
                emit_state <= EMIT_IDLE;
                address    <= unsigned(p_DDR3_MEMORY_OFFSET);
              else
--                emit_state <= EMIT_RUN; -- emit next read request
                emit_state <= EMIT_RUN_NEXT;   -- emit next read request
                address    <= address + BURST_READ_BYTES; -- 1024;  -- 32words * 32bytes/word
              end if;
              
            end if;

          when EMIT_RUN_NEXT =>
            if tx_count - rx_count < 15 then
              emit_state <= EMIT_RUN; -- emit next read request
            end if;
            p_MemIface_UPL_Request <= '0';
            p_MemIface_UPL_Enable  <= '0';
            
          when others => null;
        end case;
        
      end if;
    end if;
  end process EMIT_REQUEST;

  
  RECV_REPLY: process(p_Clk)
  begin
    
    if p_Clk'event and p_Clk = '1' then
      
      if p_Reset = '1' then
        p_FIFO_DATA_WE           <= '0';
        p_MemIface_UPL_Reply_Ack <= '0';
        recv_state               <= RECV_IDLE;
        reg_busy                 <= '1';
      else

        case recv_state is
          ---------------------------------------------------------------------
          -- wait for kick
          ---------------------------------------------------------------------
          when RECV_IDLE =>
            if p_KICK = '1' and reg_kick = '0' then  -- rising edge of p_KICK
              recv_state <= RECV_RUN;
              reg_busy   <= '1';
            else
              reg_busy <= '0';
            end if;
            p_FIFO_DATA_WE           <= '0';
            rx_count                 <= (others => '0');
            p_MemIface_UPL_Reply_Ack <= '0';
            
          ---------------------------------------------------------------------
          -- RUN
          ---------------------------------------------------------------------
          when RECV_RUN => -- wait for fifo ready
            if p_FIFO_PROG_FULL = '0' then  -- fifo is ready
              recv_state <= RECV_WAIT_REPLY;
              p_MemIface_UPL_Reply_Ack <= '1';
            end if;
            p_FIFO_DATA_WE           <= '0';
          ---------------------------------------------------------------------

          ---------------------------------------------------------------------
          -- WAIT for MEMORY REPLY, and RECEIVE FIRST WORD of REPLY UPL PACKET
          ---------------------------------------------------------------------
          when RECV_WAIT_REPLY =>
            if p_MemIface_UPL_Reply_En = '1' then
              p_MemIface_UPL_Reply_Ack <= '0';
              -- drop the first data, which is response header from e7MemIface
              recv_state <= RECV_REPLY_DATA;
            end if;

          ---------------------------------------------------------------------
          -- RECEIVE PAYLOAD DATA of REPLY UPL PACKET and WRITE INTO FIFO
          ---------------------------------------------------------------------
          when RECV_REPLY_DATA =>
            -- fifo data should be written in 64 cycles (= 64cycle * 16Byte/cycle = 1024Byte)
            p_FIFO_DATA_WE  <= p_MemIface_UPL_Reply_En;
            p_FIFO_DATA_OUT <= p_MemIface_UPL_Reply_Data;

            if p_MemIface_UPL_Reply_En = '1' then
              rx_count <= rx_count + RX_COUNT_STEP;
            end if;
            
            if p_MemIface_UPL_Reply_En = '0' then  -- End of UPL Packet Receiving
              --if rx_count = MAX_COUNT then
              if rx_count = w_read_count or rx_count = MAX_COUNT then
                recv_state <= RECV_IDLE;
              else
                recv_state <= RECV_RUN;            -- wait for next read reply
              end if;
            end if;
            
          when others => null;
        end case;
        
      end if;
    end if;
  end process RECV_REPLY;

  SYS : process(p_Clk)
  begin
    if p_Clk'event and p_Clk = '1' then
      tx_count_d     <= std_logic_vector(tx_count);
      rx_count_d     <= std_logic_vector(rx_count);
      prog_full_d    <= p_FIFO_PROG_FULL;
      reg_kick       <= p_KICK;
      w_read_count_d <= std_logic_vector(w_read_count);
    end if;
  end process SYS;
  
end RTL;
