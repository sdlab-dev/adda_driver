--
-- UPL混合モジュール(2入力)
--
--   2002/5/9 (C) Satoshi FUNADA, All rights resereved.
--   2002/3/7 (C) Satoshi FUNADA, All rights resereved.
--
--  $Id: uplmulti_in2.vhd,v 1.1 2002/05/09 07:54:57 funada Exp $
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity uplmulti_in4 is
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

        pI1En      : in  std_logic;
        pI1Data    : in  std_logic_vector( WIDTH-1 downto 0 );
        pI1Request : in  std_logic;
        pI1Ack     : out std_logic;

        pI2En      : in  std_logic;
        pI2Data    : in  std_logic_vector( WIDTH-1 downto 0 );
        pI2Request : in  std_logic;
        pI2Ack     : out std_logic;

        pI3En      : in  std_logic;
        pI3Data    : in  std_logic_vector( WIDTH-1 downto 0 );
        pI3Request : in  std_logic;
        pI3Ack     : out std_logic;

        pO0Data    : out std_logic_vector( WIDTH-1 downto 0 );
        pO0En      : out std_logic;
        pO0Ack     : in  std_logic;
        pO0Request : out std_logic;

        -- Debug Output Pins
        pDebugA : out std_logic_vector( 7 downto 0 )
        );
end uplmulti_in4;

architecture RTL of uplmulti_in4 is


    -- 
    -- 内部信号線
    -- 

    signal Reset_n, Reset_n_0, Reset_n_1 : std_logic;
    
    type stateType is ( IDLE, REQUEST, SEND );
    signal State : stateType;

    signal edge_detect : std_logic;

    signal uplnum : std_logic_vector(1 downto 0);
    signal selected_inReq : std_logic;
    signal selected_inEn : std_logic;
    signal selected_inData : std_logic_vector(WIDTH-1 downto 0);
    
begin

--    Reset_n <= pReset_n and pFuncReset_n;
    process( pUPLGlobalClk )
    begin
        if( pUPLGlobalClk'event and pUPLGlobalClk = '1' ) then
            Reset_n_1 <= pReset_n and pFuncReset_n;
            Reset_n_0 <= Reset_n_1;
            Reset_n <= Reset_n_0;
        end if;
    end process;

    pStatusIDLE <= '1' when State = IDLE else '0';
    

    -- 非同期系処理
    selected_inEn <= pI0En when uplnum = "00" else
                     pI1En when uplnum = "01" else
                     pI2En when uplnum = "10" else
                     pI3En;
    
    selected_inReq <= pI0Request when uplnum = "00" else
                      pI1Request when uplnum = "01" else
                      pI2Request when uplnum = "10" else
                      pI3Request;
    

    selected_inData <= pI0Data when uplnum = "00" else
                       pI1Data when uplnum = "01" else
                       pI2Data when uplnum = "10" else
                       pI3Data;
    
    -- 同期系処理
    
    process (pUPLGlobalClk)
    begin
        if( pUPLGlobalClk'event and pUPLGlobalClk = '1' ) then
            if( Reset_n = '0' ) then

                -- ステートマシン初期化
                State <= IDLE;
                
                pI0Ack <= '0';
                pI1Ack <= '0';
                pI2Ack <= '0';
                pI3Ack <= '0';

                pO0En      <= '0';
                pO0Data    <= (others => '0');
                pO0Request <= '0';

                edge_detect <= '0';
                uplnum      <= (others => '0');

            else

                case State is
                    when IDLE => 

                        pI0Ack <= '0';
                        pI1Ack <= '0';
                        pI2Ack <= '0';
                        pI3Ack <= '0';

                        pO0En      <= '0';
                        pO0Data    <= (others => '0');
                        pO0Request <= '0';

                        -- どれかの入力がRequest状態になるのを待つ
                        if( pI0Request = '1' ) then
                            uplnum <= "00";
                            State <= REQUEST;
                        elsif( pI1Request = '1' ) then
                            uplnum <= "01";
                            State <= REQUEST;
                        elsif( pI2Request = '1' ) then
                            uplnum <= "10";
                            State <= REQUEST;
                        elsif( pI3Request = '1' ) then
                            uplnum <= "11";
                            State <= REQUEST;
                        end if;

                        edge_detect <= '0';
                        
                    when REQUEST =>

                        if( pO0Ack = '1' ) then
                            pO0Request <= '0';
                            -- ACKを返す
                            case uplnum is
                                when "00" => pI0Ack <= '1';
                                when "01" => pI1Ack <= '1';
                                when "10" => pI2Ack <= '1';
                                when "11" => pI3Ack <= '1';
                                when others => null;
                            end case;
                            State <= SEND;
                        else
                            pO0Request <= '1';
                            -- in1のnextアドレスを送信する
                            pO0Data(2 downto 0) <= "0" & uplnum;
                        end if;

                    when SEND =>

                        -- 入力1が終了するのを待つ
                        pO0En   <= selected_InEn;
                        pO0Data <= selected_InData;

                        -- InEnが1になったら、ackも落す
                        if( selected_InEn = '1' ) then
                            pI0Ack <= '0';
                            pI1Ack <= '0';
                            pI2Ack <= '0';
                            pI3Ack <= '0';
                        end if;
                        
                        -- InEnが0->1->0となったら、このステージは終了する
                        edge_detect <= selected_InEn;
                        if( edge_detect = '1' and selected_InEn = '0' ) then
                            -- pI0Enが1->0に遷移した
                            State <= IDLE;
                        end if;

                    when others =>
                        State <= IDLE;
                end case;
            end if;
        end if;
    end process;
end RTL;
