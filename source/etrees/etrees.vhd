-----------------------------------------------------------------------------
-- e7UDP/IP, e7MemIface, and so on
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package etrees is

  component e7udpip_kc705
    port(
      -- システムクロック
      CLK_200MHz : in std_logic;
      CLK_600MHz : in std_logic;
      DDR_REFCLK : in std_logic;            -- 200MHz
      -- Asynchronous Reset
      RESET : in std_logic;

      -- GMII PHY : 2.5V
      GEPHY0_RST_N     : out std_logic;   -- このchipにおけるシステムリセット
      GEPHY0_MAC_CLK_P : in  std_logic;   -- PHYからの125MHzCLK入力
      GEPHY0_MAC_CLK_N : in  std_logic;   -- PHYからの125MHzCLK入力

      -- MAC I/F
      GEPHY0_COL   : in std_logic;        -- CollisionDetect/MAC_FREQ兼用ピン
      GEPHY0_CRS   : in std_logic;        -- CarrierSence/RGMII_SEL0兼用ピン
      GEPHY0_TXCLK : in std_logic;        -- TXCLK/RGMII_SEL1兼用ピン

      -- TX out
      GEPHY0_TD     : out std_logic_vector(7 downto 0);  -- 送信データ
      GEPHY0_TXEN   : out std_logic;
      GEPHY0_TXER   : out std_logic;
      GEPHY0_GTXCLK : out std_logic;                     -- 125MHz クロック出力

      -- RX in
      GEPHY0_RD    : in std_logic_vector(7 downto 0);  -- 受信データ
      GEPHY0_RXCLK : in std_logic;        -- 10M=>2.5MHz, 100M=>25MHz, 1G=>125MHz
      GEPHY0_RXDV  : in std_logic;
      GEPHY0_RXER  : in std_logic;

      -- Management I/F
      GEPHY0_MDC   : out   std_logic;     -- クロック出力。max.2.5MHz。
      GEPHY0_MDIO  : inout std_logic;     -- コントロールデータ。
      GEPHY0_INT_N : in    std_logic;     -- インタラプト。

      -- DDR3 SDRAM
      DDR3_DM      : out   std_logic_vector(7 downto 0);
      DDR3_DQ      : inout std_logic_vector(63 downto 0);
      DDR3_DQS_P   : inout std_logic_vector(7 downto 0);
      DDR3_DQS_N   : inout std_logic_vector(7 downto 0);
      DDR3_ADDR    : out   std_logic_vector(13 downto 0);
      DDR3_CK_P    : out   std_logic_vector(0 downto 0);
      DDR3_CK_N    : out   std_logic_vector(0 downto 0);
      DDR3_BA      : out   std_logic_vector(2 downto 0);
      DDR3_RAS_N   : out   std_logic;
      DDR3_CAS_N   : out   std_logic;
      DDR3_WE_N    : out   std_logic;
      DDR3_CS_N    : out   std_logic_vector(0 downto 0);
      DDR3_CKE     : out   std_logic_vector(0 downto 0);
      DDR3_ODT     : out   std_logic_vector(0 downto 0);
      DDR3_RESET_N : out   std_logic;
      INIT_CALIB_COMPLETE_OUT : out std_logic;

      -- user port
      UPLGlobalClk   : out std_logic;
      UPLGlobalReset : out std_logic;

      MyIpAddr         : in std_logic_vector(31 downto 0);
      MyMacAddr        : in std_logic_vector(47 downto 0);
      MyUdpPort0       : in std_logic_vector(15 downto 0);
      MyUdpPort1       : in std_logic_vector(15 downto 0);
      MyNetmask        : in std_logic_vector(31 downto 0);
      MyDefaultGateway : in std_logic_vector(31 downto 0);
      serverIpAddr     : in std_logic_vector(31 downto 0);

      UDP0Send_Data       : in  std_logic_vector(31 downto 0);
      UDP0Send_Enable     : in  std_logic;
      UDP0Send_Request    : in  std_logic;
      UDP0Send_Ack        : out std_logic;
      UDP1Send_Data       : in  std_logic_vector(31 downto 0);
      UDP1Send_Enable     : in  std_logic;
      UDP1Send_Request    : in  std_logic;
      UDP1Send_Ack        : out std_logic;
      UDP0Receive_Data    : out std_logic_vector(31 downto 0);
      UDP0Receive_Enable  : out std_logic;
      UDP0Receive_Request : out std_logic;
      UDP0Receive_Ack     : in  std_logic;
      UDP1Receive_Data    : out std_logic_vector(31 downto 0);
      UDP1Receive_Enable  : out std_logic;
      UDP1Receive_Request : out std_logic;
      UDP1Receive_Ack     : in  std_logic;

      DDR3_WR0_Request : in std_logic;
      DDR3_WR0_Ack     : out std_logic;
      DDR3_WR0_En      : in std_logic;
      DDR3_WR0_Data    : in std_logic_vector(127 downto 0);
      DDR3_WR1_Request : in std_logic;
      DDR3_WR1_Ack     : out std_logic;
      DDR3_WR1_En      : in std_logic;
      DDR3_WR1_Data    : in std_logic_vector(127 downto 0);
      DDR3_WR2_Request : in std_logic;
      DDR3_WR2_Ack     : out std_logic;
      DDR3_WR2_En      : in std_logic;
      DDR3_WR2_Data    : in std_logic_vector(127 downto 0);
      DDR3_WR3_Request : in std_logic;
      DDR3_WR3_Ack     : out std_logic;
      DDR3_WR3_En      : in std_logic;
      DDR3_WR3_Data    : in std_logic_vector(127 downto 0);

      DDR3_RD0_Request : out std_logic;
      DDR3_RD0_Ack     : in std_logic;
      DDR3_RD0_En      : out std_logic;
      DDR3_RD0_Data    : out std_logic_vector(127 downto 0);
      DDR3_RD1_Request : out std_logic;
      DDR3_RD1_Ack     : in std_logic;
      DDR3_RD1_En      : out std_logic;
      DDR3_RD1_Data    : out std_logic_vector(127 downto 0);
      DDR3_RD2_Request : out std_logic;
      DDR3_RD2_Ack     : in std_logic;
      DDR3_RD2_En      : out std_logic;
      DDR3_RD2_Data    : out std_logic_vector(127 downto 0);
      DDR3_RD3_Request : out std_logic;
      DDR3_RD3_Ack     : in std_logic;
      DDR3_RD3_En      : out std_logic;
      DDR3_RD3_Data    : out std_logic_vector(127 downto 0)

      );
  end component e7udpip_kc705;

  component sync_reset
    generic (
      RESET_CYCLES : integer := 10; -- reset cycles to keep after ARESET
      RESET_COUNTER_WIDTH : integer := 4 -- data width of reset counter, 2**RESET_COUNTER_WIDTH
      );
    port (
      CLK : in std_logic; -- clock
      ARESET : in std_logic; -- async. reset
      SRESET : out std_logic -- sync. reset
      );
  end component sync_reset;

end etrees;
