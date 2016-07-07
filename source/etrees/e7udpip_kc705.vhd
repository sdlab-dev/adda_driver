library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.constants.all;
use work.misc.all;

entity e7udpip_kc705 is
  port(
    -- システムクロック
    CLK_200MHz : in std_logic;            -- 200MHz
    CLK_600MHz : in std_logic;            -- 200MHz
    DDR_REFCLK : in std_logic;            -- 200MHz

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

    -- Asynchronous Reset
    RESET : in std_logic;

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
end e7udpip_kc705;

architecture rtl of e7udpip_kc705 is

  -- Global synchronous clock and reset
  signal w_clk_125MHz : std_logic;
  signal w_rst_125MHz : std_logic;
  
  signal w_clk_200MHz : std_logic;
  signal w_rst_200MHz : std_logic;
  
  signal w_ddr_refclk : std_logic;

  signal Status_RxByteCount             : std_logic_vector(31 downto 0);
  signal Status_RxPacketCount           : std_logic_vector(31 downto 0);
  signal Status_RxErrorPacketCount      : std_logic_vector(15 downto 0);
  signal Status_RxDropPacketCount       : std_logic_vector(15 downto 0);
  signal Status_RxARPRequestPacketCount : std_logic_vector(15 downto 0);
  signal Status_RxARPReplyPacketCount   : std_logic_vector(15 downto 0);
  signal Status_RxICMPPacketCount       : std_logic_vector(15 downto 0);
  signal Status_RxUDP0PacketCount       : std_logic_vector(15 downto 0);
  signal Status_RxUDP1PacketCount       : std_logic_vector(15 downto 0);
  signal Status_RxIPErrorPacketCount    : std_logic_vector(15 downto 0);
  signal Status_RxUDPErrorPacketCount   : std_logic_vector(15 downto 0);
  signal Status_TxByteCount             : std_logic_vector(31 downto 0);
  signal Status_TxPacketCount           : std_logic_vector(31 downto 0);
  signal Status_TxARPRequestPacketCount : std_logic_vector(15 downto 0);
  signal Status_TxARPReplyPacketCount   : std_logic_vector(15 downto 0);
  signal Status_TxICMPReplyPacketCount  : std_logic_vector(15 downto 0);
  signal Status_TxUDP0PacketCount       : std_logic_vector(15 downto 0);
  signal Status_TxUDP1PacketCount       : std_logic_vector(15 downto 0);
  signal Status_TxMulticastPacketCount  : std_logic_vector(15 downto 0);
  signal status_phy                     : std_logic_vector(15 downto 0);

  component uplmulti_in4
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
  end component uplmulti_in4;

  component uplmulti_out4
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
  end component uplmulti_out4;

  component uplbuf
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

      -- Debug Output Pins
      pDebugA : out std_logic_vector( 7 downto 0 )
      );
  end component uplbuf;
  

  signal w_DDR3_WR_Request : std_logic;
  signal w_DDR3_WR_Ack     : std_logic;
  signal w_DDR3_WR_En      : std_logic;
  signal w_DDR3_WR_Data    : std_logic_vector(127 downto 0);

  signal w_DDR3_WR_Request_tmp : std_logic;
  signal w_DDR3_WR_Ack_tmp     : std_logic;
  signal w_DDR3_WR_En_tmp      : std_logic;
  signal w_DDR3_WR_Data_tmp    : std_logic_vector(127 downto 0);

  signal w_DDR3_RD_Request : std_logic;
  signal w_DDR3_RD_Ack     : std_logic;
  signal w_DDR3_RD_En      : std_logic;
  signal w_DDR3_RD_Data    : std_logic_vector(127 downto 0);

begin

  clkingen : IBUFDS_GTE2 port map (
    CEB   => '0',
    I     => GEPHY0_MAC_CLK_P,
    IB    => GEPHY0_MAC_CLK_N,
    O     => w_clk_125MHz,
    ODIV2 => open
    );
  
  -- Create synchronous reset in the system clock domain.
  gen_reset_125mhz: sync_reset
    generic map(
      RESET_CYCLES => 10,
      RESET_COUNTER_WIDTH => 4
      )
    port map(
      CLK => w_clk_125MHz,
      ARESET => RESET,
      SRESET => w_rst_125MHz
      );

  w_clk_200Mhz <= CLK_200MHz;  
--  w_clk_200Mhz <= w_clk_125MHz;
  gen_reset_200mhz: sync_reset
    generic map(
      RESET_CYCLES => 10,
      RESET_COUNTER_WIDTH => 4
      )
    port map(
      CLK => w_clk_200MHz,
      ARESET => RESET,
      SRESET => w_rst_200MHz
      );
  UPLGlobalClk   <= w_clk_200MHz;
  UPLGlobalReset <= w_rst_200MHz;

  w_ddr_refclk <= DDR_REFCLK;

  u_e7udpip0 : e7udpip_kintex7
    port map (
      -- GMII PHY 
      GEPHY_RST_N       => GEPHY0_RST_N,
      GEPHY_MAC_CLK     => w_clk_125MHz,  -- MAC_CLKがないので、125MHzのクロック信号線をつなぐ
      -- MAC I/F
      GEPHY_COL         => GEPHY0_COL,
      GEPHY_CRS         => GEPHY0_CRS,
      GEPHY_TXCLK       => GEPHY0_TXCLK,
      -- TX out
      GEPHY_TD          => GEPHY0_TD,
      GEPHY_TXEN        => GEPHY0_TXEN,
      GEPHY_TXER        => GEPHY0_TXER,
      GEPHY_GTXCLK      => GEPHY0_GTXCLK,
      -- RX in
      GEPHY_RD          => GEPHY0_RD,
      GEPHY_RXCLK       => GEPHY0_RXCLK,
      GEPHY_RXDV        => GEPHY0_RXDV,
      GEPHY_RXER        => GEPHY0_RXER,
      -- Management I/F
      GEPHY_MDC         => GEPHY0_MDC,
      GEPHY_MDIO        => GEPHY0_MDIO,
      GEPHY_INT_N       => GEPHY0_INT_N,
      -- Asynchronous Reset
      RESET_N           => not w_rst_125MHz,
      -- UPL interface
---      pUPLGlobalClk     => w_clk_125MHz,
      pUPLGlobalClk     => w_clk_200mhz,
      -- UDP tx input
      pUdp0Send_Data    => UDP0Send_Data,
      pUdp0Send_Request => UDP0Send_Request,
      pUdp0Send_Ack     => UDP0Send_Ack,
      pUdp0Send_Enable  => UDP0Send_Enable,

      pUdp1Send_Data    => UDP1Send_Data,
      pUdp1Send_Request => UDP1Send_Request,
      pUdp1Send_Ack     => UDP1Send_Ack,
      pUdp1Send_Enable  => UDP1Send_Enable,

      -- UDP rx output
      pUdp0Receive_Data    => Udp0Receive_Data,
      pUdp0Receive_Request => Udp0Receive_Request,
      pUdp0Receive_Ack     => Udp0Receive_Ack,
      pUdp0Receive_Enable  => Udp0Receive_Enable,

      pUdp1Receive_Data    => Udp1Receive_Data,
      pUdp1Receive_Request => Udp1Receive_Request,
      pUdp1Receive_Ack     => Udp1Receive_Ack,
      pUdp1Receive_Enable  => Udp1Receive_Enable,

      -- MII interface
      pMIIInput_Data       => X"00000000",
      pMIIInput_Request    => '0',
      pMIIInput_Ack        => open,
      pMIIInput_Enable     => '0',

      pMIIOutput_Data      => open,
      pMIIOutput_Request   => open,
      pMIIOutput_Ack       => '1',
      pMIIOutput_Enable    => open,

      -- Setup
      pMyIpAddr       => MyIpAddr,
      pMyMacAddr      => MyMacAddr,
      pMyUdpPort0     => MyUdpPort0,
      pMyUdpPort1     => MyUdpPort1,
      pMyNetmask      => MyNetmask,
      pDefaultGateway => MyDefaultGateway,
      pTargetIpAddr   => serveripaddr,

        pPHYAddr      => "00111",
        pPHYMode      => "1000",        -- auto neg

      -- Status
      pStatus_RxByteCount             => Status_RxByteCount,
      pStatus_RxPacketCount           => Status_RxPacketCount,
      pStatus_RxErrorPacketCount      => Status_RxErrorPacketCount,
      pStatus_RxDropPacketCount       => Status_RxDropPacketCount,
      pStatus_RxARPRequestPacketCount => Status_RxARPRequestPacketCount,
      pStatus_RxARPReplyPacketCount   => Status_RxARPReplyPacketCount,
      pStatus_RxICMPPacketCount       => Status_RxICMPPacketCount,
      pStatus_RxUDP0PacketCount       => Status_RxUDP0PacketCount,
      pStatus_RxUDP1PacketCount       => Status_RxUDP1PacketCount,
      pStatus_RxIPErrorPacketCount    => Status_RxIPErrorPacketCount,
      pStatus_RxUDPErrorPacketCount   => Status_RxUDPErrorPacketCount,
      
      pStatus_TxByteCount             => Status_TxByteCount,
      pStatus_TxPacketCount           => Status_TxPacketCount,
      pStatus_TxARPRequestPacketCount => Status_TxARPRequestPacketCount,
      pStatus_TxARPReplyPacketCount   => Status_TxARPReplyPacketCount,
      pStatus_TxICMPReplyPacketCount  => Status_TxICMPReplyPacketCount,
      pStatus_TxUDP0PacketCount       => Status_TxUDP0PacketCount,
      pStatus_TxUDP1PacketCount       => Status_TxUDP1PacketCount,
      pStatus_TxMulticastPacketCount  => Status_TxMulticastPacketCount,
      
      pStatus_Phy => Status_phy
      );

  u_memiface : e7memiface_ddr3_kc705 port map(
    -- Inouts
    DDR3_DQ    => DDR3_DQ,
    DDR3_DQS_P => DDR3_DQS_P,
    DDR3_DQS_N => DDR3_DQS_N,

    -- Outputs
    DDR3_ADDR    => DDR3_ADDR,
    DDR3_BA      => DDR3_BA,
    DDR3_RAS_N   => DDR3_RAS_N,
    DDR3_CAS_N   => DDR3_CAS_N,
    DDR3_WE_N    => DDR3_WE_N,
    DDR3_RESET_N => DDR3_RESET_N,
    DDR3_CK_P    => DDR3_CK_P,
    DDR3_CK_N    => DDR3_CK_N,
    DDR3_CKE     => DDR3_CKE,
    DDR3_CS_N    => DDR3_CS_N,
    DDR3_DM      => DDR3_DM,
    DDR3_ODT     => DDR3_ODT,

    -- Inputs
--    SYS_CLK_IN   => w_clk_200MHz,
    SYS_CLK_IN   => CLK_600MHz,
    CLK_REF_IN   => w_ddr_refclk,
    SYS_RST_N_IN => not w_rst_200MHz,

    -- Status Outputs
    INIT_CALIB_COMPLETE_OUT => INIT_CALIB_COMPLETE_OUT,

    -- User Interface
    UPLGlobalClk_in     => w_clk_200MHz,
    UPLGlobalReset_n_in => not w_rst_200MHz,

    pI0Request => w_DDR3_WR_Request,
    pI0Ack     => w_DDR3_WR_Ack,
    pI0En      => w_DDR3_WR_En,
    pI0Data    => w_DDR3_WR_Data,

    pO0Request => w_DDR3_RD_Request,
    pO0Ack     => w_DDR3_RD_Ack,
    pO0En      => w_DDR3_RD_En,
    pO0Data    => w_DDR3_RD_Data
    );

  U_DDR_WR_MULT : uplmulti_in4
    generic map(
      WIDTH => 128
      )
    port map(
      pReset_n      => not w_rst_200MHz,
      pFuncReset_n  => not w_rst_200MHz,
      pUPLGlobalClk => w_clk_200MHz,
      pStatusIDLE   => open,

      pI0En      => DDR3_WR0_En,
      pI0Data    => DDR3_WR0_Data,
      pI0Request => DDR3_WR0_Request,
      pI0Ack     => DDR3_WR0_Ack,

      pI1En      => DDR3_WR1_En,
      pI1Data    => DDR3_WR1_Data,
      pI1Request => DDR3_WR1_Request,
      pI1Ack     => DDR3_WR1_Ack,

      pI2En      => DDR3_WR2_En,
      pI2Data    => DDR3_WR2_Data,
      pI2Request => DDR3_WR2_Request,
      pI2Ack     => DDR3_WR2_Ack,

      pI3En      => DDR3_WR3_En,
      pI3Data    => DDR3_WR3_Data,
      pI3Request => DDR3_WR3_Request,
      pI3Ack     => DDR3_WR3_Ack,

      pO0Data    => w_DDR3_WR_Data,
      pO0En      => w_DDR3_WR_En,
      pO0Ack     => w_DDR3_WR_Ack,
      pO0Request => w_DDR3_WR_Request,

      -- Debug Output Pins
      pDebugA => open
      );

  --U_UPLBUF : uplbuf
  --  generic map(
  --    WIDTH => 128
  --    )
  --  port map(
  --    pReset_n      => not w_rst_200MHz,
  --    pFuncReset_n  => not w_rst_200MHz,
  --    pUPLGlobalClk => w_clk_200MHz,
  --    pStatusIDLE   => open,
  --
  --    pI0En      => w_DDR3_WR_En_tmp,
  --    pI0Data    => w_DDR3_WR_Data_tmp,
  --    pI0Request => w_DDR3_WR_Request_tmp,
  --    pI0Ack     => w_DDR3_WR_Ack_tmp,
  --
  --    pO0Data    => w_DDR3_WR_Data,
  --    pO0En      => w_DDR3_WR_En,
  --    pO0Ack     => w_DDR3_WR_Ack,
  --    pO0Request => w_DDR3_WR_Request,
  --  
  --    -- Debug Output Pins
  --    pDebugA => open
  --    );
  

  U_DDR_RD_MULT : uplmulti_out4
    generic map(
        WIDTH => 128
        )
    port map(
        pReset_n      => not w_rst_200MHz,
        pFuncReset_n  => not w_rst_200MHz,
        pUPLGlobalClk => w_clk_200MHz,
        pStatusIDLE   => open,

        pI0En      => w_DDR3_RD_En,
        pI0Data    => w_DDR3_RD_Data,
        pI0Request => w_DDR3_RD_Request,
        pI0Ack     => w_DDR3_RD_Ack,

        pO0Data    => DDR3_RD0_Data,
        pO0En      => DDR3_RD0_En,
        pO0Ack     => DDR3_RD0_Ack,
        pO0Request => DDR3_RD0_Request,

        pO1Data    => DDR3_RD1_Data,
        pO1En      => DDR3_RD1_En,
        pO1Ack     => DDR3_RD1_Ack,
        pO1Request => DDR3_RD1_Request,

        pO2Data    => DDR3_RD2_Data,
        pO2En      => DDR3_RD2_En,
        pO2Ack     => DDR3_RD2_Ack,
        pO2Request => DDR3_RD2_Request,

        pO3Data    => DDR3_RD3_Data,
        pO3En      => DDR3_RD3_En,
        pO3Ack     => DDR3_RD3_Ack,
        pO3Request => DDR3_RD3_Request,

        -- Debug Output Pins
        pDebugA => open
        );
  
end RTL;
