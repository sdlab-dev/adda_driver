--
-- UPL混合モジュール(2入力)
--
--   2002/5/9 (C) Satoshi FUNADA, All rights resereved.
--   2002/3/7 (C) Satoshi FUNADA, All rights resereved.
--
--  $Id: uplmulti_out2.vhd,v 1.2 2002/05/10 00:21:25 funada Exp $
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity uplmulti_out4 is
    generic(
        WIDTH : integer
        );
    port(
        pReset_n    : in std_logic;
        pFuncReset_n    : in std_logic;
        pUPLGlobalClk : in std_logic;
        pStatusIDLE : out std_logic;

        pI0En      : in  std_logic;
        pI0Data    : in  std_logic_vector( WIDTH-1 downto 0 );
        pI0Request : in  std_logic;
        pI0Ack     : out std_logic;

        pO0Data    : out std_logic_vector( WIDTH-1 downto 0 );
        pO0En      : out std_logic;
        pO0Ack     : in  std_logic;
        pO0Request : out std_logic;

        pO1Data    : out std_logic_vector( WIDTH-1 downto 0 );
        pO1En      : out std_logic;
        pO1Ack     : in  std_logic;
        pO1Request : out std_logic;

        pO2Data    : out std_logic_vector( WIDTH-1 downto 0 );
        pO2En      : out std_logic;
        pO2Ack     : in  std_logic;
        pO2Request : out std_logic;

        pO3Data    : out std_logic_vector( WIDTH-1 downto 0 );
        pO3En      : out std_logic;
        pO3Ack     : in  std_logic;
        pO3Request : out std_logic;

        -- Debug Output Pins
        pDebugA : out std_logic_vector( 7 downto 0 )
        );
end uplmulti_out4;

architecture RTL of uplmulti_out4 is


    -- 
    -- 内部信号線
    -- 
    signal Reset_n : std_logic;
    
    type stateType is ( IDLE, ACKWAIT, SEND );
    signal State : stateType;

    signal uplnum : std_logic_vector(2 downto 0);
    signal edge_detect : std_logic;

    signal selected_ack : std_logic;
    
begin

    Reset_n <= pReset_n and pFuncReset_n;

    pStatusIDLE <= '1' when State = IDLE else '0';
    
    
    -- 
    -- 非同期系処理
    -- 

    selected_ack <= pO0ack when uplnum(1 downto 0) = "00" else
                    pO1ack when uplnum(1 downto 0) = "01" else
                    pO2ack when uplnum(1 downto 0) = "10" else
                    pO3ack;
                    
    
    -- 
    -- 同期系処理
    -- 
    process (pUPLGlobalClk)
    begin
        if( pUPLGlobalClk'event and pUPLGlobalClk = '1' ) then

            if( Reset_n = '0' ) then

                -- ステートマシン初期化
                State <= IDLE;

                pO0En      <= '0';
                pO0Data    <= (others => '0');
                pO0Request <= '0';

                pO1En      <= '0';
                pO1Data    <= (others => '0');
                pO1Request <= '0';

                pO2En      <= '0';
                pO2Data    <= (others => '0');
                pO2Request <= '0';

                pO3En      <= '0';
                pO3Data    <= (others => '0');
                pO3Request <= '0';

                edge_detect <= '0';
                uplnum <= (others => '0');
                
            else
                
                case State is
                    when IDLE =>
                        if( pI0Request = '1' ) then
                            uplnum <= pI0Data(2 downto 0);

                            case pI0Data(1 downto 0) is
                                when "00" => State <= ACKWAIT;
                                when "01" => State <= ACKWAIT;
                                when "10" => State <= ACKWAIT;
                                when "11" => State <= ACKWAIT;
                                when others => null;
                            end case;
                        end if;

                        pI0Ack <= '0';

                        pO0En <= '0';
                        pO0Data <= (others => '0');
                        pO1En <= '0';
                        pO1Data <= (others => '0');
                        pO2En <= '0';
                        pO2Data <= (others => '0');
                        pO3En <= '0';
                        pO3Data <= (others => '0');
                        
                        edge_detect <= '0';
                        
                    when ACKWAIT =>
                        -- ackが来るまで、reqを出す
                        if( selected_ack = '1' ) then
                            pO0Request <= '0';
                            pO1Request <= '0';
                            pO2Request <= '0';
                            pO3Request <= '0';
                            -- ACKが帰ってきたら、送り元にACKを返す
                            pI0Ack <= '1';
                            State <= SEND;
                        else
                            case uplnum(1 downto 0) is
                                when "00"  => pO0Request <= '1';
                                when "01"  => pO1Request <= '1';
                                when "10"  => pO2Request <= '1';
                                when "11"  => pO3Request <= '1';
                                when others => null;
                            end case;
                        end if;

                    when SEND =>
                        if( pI0Request = '0' ) then
                            pI0Ack <= '0';
                        end if;

                        case uplnum(1 downto 0) is
                            when "00"  => pO0En <= pI0En; pO0Data <= pI0Data;
                            when "01"  => pO1En <= pI0En; pO1Data <= pI0Data;
                            when "10"  => pO2En <= pI0En; pO2Data <= pI0Data;
                            when "11"  => pO3En <= pI0En; pO3Data <= pI0Data;
                            when others => null;
                        end case;

                        -- InEnが 0->1->0と遷移したらこのステージは終了
                        edge_detect <= pI0En;
                        if( pI0En = '0' and edge_detect='1' ) then
                            State <= IDLE;
                        end if;

                    when others =>
                        State <= IDLE;
                end case;
            end if;
        end if;
    end process;
end RTL;
