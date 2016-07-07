library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity fifo2memiface is
  port (
    p_Clk : in std_logic;
    p_Reset : in std_logic;
    
    p_DDR3_MEMORY_OFFSET : in std_logic_vector(31 downto 0);
    
    p_FIFO_DATA_OUT   : in  std_logic_vector(127 downto 0);
    p_FIFO_DATA_RE    : out std_logic;
    p_FIFO_DATA_COUNT : in  std_logic_vector(31 downto 0);

    p_MemIface_UPL_Enable  : out std_logic;
    p_MemIface_UPL_Request : out std_logic;
    p_MemIface_UPL_Ack     : in  std_logic;
    p_MemIface_UPL_Data    : out std_logic_vector(127 downto 0);

    p_MemIface_UPL_Reply_Ack : out std_logic;  -- for drop
    p_MemIface_UPL_Reply_En  : in  std_logic;  -- for drop
    
    p_MemIface_ADDR_Reset  : in  std_logic
    );
end fifo2memiface;

architecture RTL of fifo2memiface is

  type state_type is (IDLE, UPLACK_WAIT, MEM_HEADER, MEM_DATA, RECV_ACK);
  signal state : state_type := IDLE;

  signal fifo_count : unsigned(31 downto 0) := (others => '0');
  signal tx_count   : unsigned(31 downto 0) := (others => '0');

  signal address : unsigned(31 downto 0) := (others => '0');

  signal MemIface_UPL_Reply_En_d : std_logic := '0';
  
begin

  process(p_Clk)
  begin
    if p_Clk'event and p_Clk = '1' then
      if p_Reset = '1' then
        p_FIFO_DATA_RE           <= '0';
        p_MemIface_UPL_Enable    <= '0';
        p_MemIface_UPL_Request   <= '0';
        p_MemIface_UPL_Reply_Ack <= '0';
        state <= IDLE;
      else

        MemIface_UPL_Reply_En_d <= p_MemIface_UPL_Reply_En;

        if p_MemIface_ADDR_Reset = '1' then
--          address <= (others => '0');
          address <= unsigned(p_DDR3_MEMORY_OFFSET);
        end if;

        case state is
          when IDLE =>
            if to_integer(unsigned(p_FIFO_DATA_COUNT)) >= 64 then
              state                  <= UPLACK_WAIT;
              p_MemIface_UPL_Request <= '1';
            else
              p_MemIface_UPL_Request <= '0';
            end if;
            p_FIFO_DATA_RE           <= '0';
            p_MemIface_UPL_Enable    <= '0';
            fifo_count               <= (others => '0');
            tx_count                 <= (others => '0');
            p_MemIface_UPL_Reply_Ack <= '0';

          when UPLACK_WAIT =>
            if p_MemIface_UPL_Ack = '1' then
              p_FIFO_DATA_RE <= '1';    -- for next next
              fifo_count     <= fifo_count + 1;
              state          <= MEM_HEADER;
              p_MemIface_UPL_Request <= '0';
            end if;

          when MEM_HEADER =>
              p_FIFO_DATA_RE <= '1';    -- for next next
              fifo_count     <= fifo_count + 1;
              p_MemIface_UPL_Enable <= '1';
              p_MemIface_UPL_DATA <= X"00000000" & X"0000" & X"04" & X"20" & X"00000000" & std_logic_vector(address);
              state <= MEM_DATA;

          when MEM_DATA =>
            if fifo_count < 64 then
              fifo_count <= fifo_count + 1;
              p_FIFO_DATA_RE <= '1';    -- for next next
            else
              p_FIFO_DATA_RE <= '0';    -- for next next
            end if;

            if tx_count < 64 then
              tx_count              <= tx_count + 1;
              p_MemIface_UPL_Enable <= '1';
              p_MemIface_UPL_DATA   <= p_FIFO_DATA_OUT;
            else
              tx_count                 <= (others => '0');
              p_MemIface_UPL_Enable    <= '0';
              p_MemIface_UPL_DATA      <= (others => '0');
              state                    <= RECV_ACK;
--              state <= IDLE;
              address                  <= address + 1024;  -- for next memory write
              p_MemIface_UPL_Reply_Ack <= '1';             -- to recv ack
            end if;

          when RECV_ACK =>
            
            if p_MemIface_UPL_Reply_En = '1' then  -- Ack should be de-asserted when En is asserted
              p_MemIface_UPL_Reply_Ack <= '0';
            end if;
            if MemIface_UPL_Reply_En_d = '1' and p_MemIface_UPL_Reply_En = '0' then  -- falling edge
              state <= IDLE;
            end if;
            
          when others => null;
        end case;
        
      end if;
    end if;
  end process;
  
end RTL;
