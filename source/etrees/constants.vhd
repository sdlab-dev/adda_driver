-----------------------------------------------------------------------------
-- e7UDP/IP, e7MemIface, and so on
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is

  -- xmigiface
  constant MEMADDRWIDTH          : integer                                   := 34;
  constant DIMM_INITDATA_PATTERN : std_logic_vector(127 downto 0)            := (others => '0');
  constant INITSIZE              : std_logic_vector(MEMADDRWIDTH-1 downto 0) := B"10" & X"00000000";  -- 8GB

  component e7memiface_ddr3_kc705
    port (
      -- Inouts
      DDR3_DQ    : inout std_logic_vector(63 downto 0);
      DDR3_DQS_P : inout std_logic_vector(7 downto 0);
      DDR3_DQS_N : inout std_logic_vector(7 downto 0);

      -- Outputs
      DDR3_ADDR    : out std_logic_vector(13 downto 0);
      DDR3_BA      : out std_logic_vector(2 downto 0);
      DDR3_RAS_N   : out std_logic;
      DDR3_CAS_N   : out std_logic;
      DDR3_WE_N    : out std_logic;
      DDR3_RESET_N : out std_logic;
      DDR3_CK_P    : out std_logic_vector(0 downto 0);
      DDR3_CK_N    : out std_logic_vector(0 downto 0);
      DDR3_CKE     : out std_logic_vector(0 downto 0);
      DDR3_CS_N    : out std_logic_vector(0 downto 0);
      DDR3_DM      : out std_logic_vector(7 downto 0);
      DDR3_ODT     : out std_logic_vector(0 downto 0);

      -- Inputs
      -- Single-ended system clock(200MHz)
      SYS_CLK_IN   : in std_logic;
      -- iodelayctrl clk (reference clock, 200MHz)
      CLK_REF_IN   : in std_logic;
      -- System reset
      SYS_RST_N_IN : in std_logic;

      INIT_CALIB_COMPLETE_OUT : out std_logic;

      -- User Interface
      UPLGlobalClk_in     : in std_logic;
      UPLGlobalReset_n_in : in std_logic;

      pI0Request : in  std_logic;
      pI0Ack     : out std_logic;
      pI0Data    : in  std_logic_vector(127 downto 0);
      pI0En      : in  std_logic;

      pO0Request : out std_logic;
      pO0Ack     : in  std_logic;
      pO0Data    : out std_logic_vector(127 downto 0);
      pO0En      : out std_logic
      );
  end component;

  component memiface128_ddr3_512bit
    port (
      pReset_n      : in  std_logic;
      pFuncReset_n  : in  std_logic;
      pUPLGlobalClk : in  std_logic;
      pStatusIDLE   : out std_logic;

      -- 入力
      -- input
      pI0Data    : in  std_logic_vector(127 downto 0);
      pI0Request : in  std_logic;
      pI0Ack     : out std_logic;
      pI0En      : in  std_logic;
      -- 出力
      -- portnumber=0 ( output, sendid=0 )
      pO0Data    : out std_logic_vector(127 downto 0);
      pO0Request : out std_logic;
      pO0Ack     : in  std_logic;
      pO0En      : out std_logic;

      -- user port
      papp_addr          : out std_logic_vector(63 downto 0);
      papp_cmd           : out std_logic_vector(2 downto 0);
      papp_en            : out std_logic;
      papp_wdf_data      : out std_logic_vector(511 downto 0);
      papp_wdf_end       : out std_logic;
      papp_wdf_mask      : out std_logic_vector(63 downto 0);
      papp_wdf_wren      : out std_logic;
      papp_wdf_rdy       : in  std_logic;
      papp_rd_data       : in  std_logic_vector(511 downto 0);
      papp_rd_data_end   : in  std_logic;
      papp_rd_data_valid : in  std_logic;
      papp_rdy           : in  std_logic;

      pDebugA : out std_logic_vector(7 downto 0)
      );
  end component;

  component udpiface128_memiface128
    port (
      pReset_n      : in  std_logic;
      pFuncReset_n  : in  std_logic;
      pUPLGlobalClk : in  std_logic;
      pStatusIDLE   : out std_logic;

      --------------------------------------------------
      -- input
      --------------------------------------------------
      -- udp_input
      pI0Data    : in  std_logic_vector(127 downto 0);
      pI0Request : in  std_logic;
      pI0Ack     : out std_logic;
      pI0En      : in  std_logic;
      -- memiface_input
      pI1Data    : in  std_logic_vector(127 downto 0);
      pI1Request : in  std_logic;
      pI1Ack     : out std_logic;
      pI1En      : in  std_logic;
      
      --------------------------------------------------
      -- 出力
      --------------------------------------------------
      -- portnumber=0 ( udp_output, sendid=0 )
      pO0Data    : out std_logic_vector(127 downto 0);
      pO0Request : out std_logic;
      pO0Ack     : in  std_logic;
      pO0En      : out std_logic;
      -- portnumber=1 ( memiface_output, sendid=1 )
      pO1Data    : out std_logic_vector(127 downto 0);
      pO1Request : out std_logic;
      pO1Ack     : in  std_logic;
      pO1En      : out std_logic;

      --------------------------------------------------
      -- user port
      --------------------------------------------------
      pDebugA : out std_logic_vector(7 downto 0)
      );
  end component;

  component uplpacketbuffer_128to64_8k_fifobase
    port(
      pReset_n      : in  std_logic;
      pFuncReset_n  : in  std_logic;
      pUPLGlobalClk : in  std_logic;
      pStatusIDLE   : out std_logic;

      -- Input UPL
      pI0Clk        : in std_logic;
      pI0DataStrobe : in std_logic;
      pI0Error      : in std_logic;

      pI0En      : in  std_logic;
      pI0Data    : in  std_logic_vector(127 downto 0);
      pI0Ack     : out std_logic;
      pI0Request : in  std_logic;

      -- Output UPL
      pO0Clk     : in  std_logic;
      pO0Data    : out std_logic_vector(63 downto 0);
      pO0En      : out std_logic;
      pO0Ack     : in  std_logic;
      pO0Request : out std_logic;

      -- Debug Outputs
      pStatus_count_packet_dispose : out std_logic_vector(15 downto 0);
      pDebugA                      : out std_logic_vector(15 downto 0)
      );
  end component;

  component uplpacketbuffer_64to128_8k_fifobase
    port(
      pReset_n      : in  std_logic;
      pFuncReset_n  : in  std_logic;
      pUPLGlobalClk : in  std_logic;
      pStatusIDLE   : out std_logic;

      -- Input UPL
      pI0Clk        : in std_logic;
      pI0DataStrobe : in std_logic;
      pI0Error      : in std_logic;

      pI0En      : in  std_logic;
      pI0Data    : in  std_logic_vector(63 downto 0);
      pI0Ack     : out std_logic;
      pI0Request : in  std_logic;

      -- Output UPL
      pO0Clk     : in  std_logic;
      pO0Data    : out std_logic_vector(127 downto 0);
      pO0En      : out std_logic;
      pO0Ack     : in  std_logic;
      pO0Request : out std_logic;

      -- Debug Outputs
      pStatus_count_packet_dispose : out std_logic_vector(15 downto 0);
      pDebugA                      : out std_logic_vector(15 downto 0)
      );
  end component;


  -- UPL Types
  type UPL4 is
  record
    Data    : std_logic_vector(3 downto 0);
    Enable  : std_logic;
    Request : std_logic;
    Ack     : std_logic;
  end record;

  type UPL8 is
  record
    Data    : std_logic_vector(7 downto 0);
    Enable  : std_logic;
    Request : std_logic;
    Ack     : std_logic;
  end record;

  type UPL16 is
  record
    Data    : std_logic_vector(15 downto 0);
    Enable  : std_logic;
    Request : std_logic;
    Ack     : std_logic;
  end record;


  type UPL8i is
  record
    Data   : std_logic_vector(7 downto 0);
    Enable : std_logic;
    Ready  : std_logic;
  end record;

  type UPL8o is
  record
    Data    : std_logic_vector(7 downto 0);
    Enable  : std_logic;
    Request : std_logic;
    Ack     : std_logic;
  end record;

  type UPL32 is
  record
    Data    : std_logic_vector(31 downto 0);
    Enable  : std_logic;
    Request : std_logic;
    Ack     : std_logic;
  end record;

  type UPL32i is
  record
    Data   : std_logic_vector(31 downto 0);
    Enable : std_logic;
    Ready  : std_logic;
  end record;

  type UPL32o is
  record
    Data    : std_logic_vector(31 downto 0);
    Enable  : std_logic;
    Request : std_logic;
    Ack     : std_logic;
  end record;

  type UPL64 is
  record
    Data    : std_logic_vector(63 downto 0);
    Enable  : std_logic;
    Request : std_logic;
    Ack     : std_logic;
  end record;

  type UPL64i is
  record
    Data   : std_logic_vector(63 downto 0);
    Enable : std_logic;
    Ready  : std_logic;
  end record;

  type UPL128 is
  record
    Data    : std_logic_vector(127 downto 0);
    Enable  : std_logic;
    Request : std_logic;
    Ack     : std_logic;
  end record;


  subtype UPLAddr is std_logic_vector(7 downto 0);

  -- request commands for modules of memoryiface series
  constant MEMORYIFACE_COMMAND_READ                    : std_logic_vector(7 downto 0) := "00000001";
  constant MEMORYIFACE_COMMAND_READ_WITH_ROTATE        : std_logic_vector(7 downto 0) := "00010001";
  constant MEMORYIFACE_COMMAND_READ_WITH_ECCRESULT     : std_logic_vector(7 downto 0) := "01000001";
  constant MEMORYIFACE_COMMAND_READ_XBRAM_NOHEADER     : std_logic_vector(7 downto 0) := "01100000";
  constant MEMORYIFACE_COMMAND_WRITE                   : std_logic_vector(7 downto 0) := "00000010";
  constant MEMORYIFACE_COMMAND_WRITE_WITH_ROTATE       : std_logic_vector(7 downto 0) := "00010010";
  constant MEMORYIFACE_COMMAND_WRITE_REPLY             : std_logic_vector(7 downto 0) := "00000100";
  constant MEMORYIFACE_COMMAND_WRITE_REPLY_WITH_ROTATE : std_logic_vector(7 downto 0) := "00010100";
  constant MEMORYIFACE_COMMAND_WRITE_WITH_ACKRAMWRITE  : std_logic_vector(7 downto 0) := "00000101";
  constant MEMORYIFACE_COMMAND_READ_ACKRAM             : std_logic_vector(7 downto 0) := "00000110";
  constant MEMORYIFACE_COMMAND_CLEAR_ACKRAM            : std_logic_vector(7 downto 0) := "00000111";
  constant MEMORYIFACE_COMMAND_MEMTEST                 : std_logic_vector(7 downto 0) := "00001000";
  constant MEMORYIFACE_COMMAND_MEMFILL                 : std_logic_vector(7 downto 0) := "00001001";
  constant MEMORYIFACE_COMMAND_REFREASH                : std_logic_vector(7 downto 0) := "10000000";
  constant MEMORYIFACE_COMMAND_ERROR                   : std_logic_vector(7 downto 0) := "11111111";

  constant MEMORYIFACE_REPLY_SUCCESS    : std_logic_vector(7 downto 0) := "00000000";
  constant MEMORYIFACE_REPLY_FAIL       : std_logic_vector(7 downto 0) := "00000001";
  constant MEMORYIFACE_REPLY_UNSUPORTED : std_logic_vector(7 downto 0) := "00000011";

  subtype EtherAddr is std_logic_vector(47 downto 0);

  -- Ethernet constants
  constant ETHER_PROTO_ARP1        : std_logic_vector(7 downto 0)  := X"08";
  constant ETHER_PROTO_ARP2        : std_logic_vector(7 downto 0)  := X"06";
  constant ETHER_PROTO_ARP         : std_logic_vector(15 downto 0) := ETHER_PROTO_ARP1 & ETHER_PROTO_ARP2;  -- 0x0806
  constant ETHER_PROTO_IP4_1       : std_logic_vector(7 downto 0)  := X"08";
  constant ETHER_PROTO_IP4_2       : std_logic_vector(7 downto 0)  := X"00";
  constant ETHER_PROTO_IP4         : std_logic_vector(15 downto 0) := ETHER_PROTO_IP4_1 & ETHER_PROTO_IP4_2;  -- 0x0800
  constant ETHER_PROTO_IP6_1       : std_logic_vector(7 downto 0)  := X"86";
  constant ETHER_PROTO_IP6_2       : std_logic_vector(7 downto 0)  := X"DD";
  constant ETHER_PROTO_IP6         : std_logic_vector(15 downto 0) := ETHER_PROTO_IP6_1 & ETHER_PROTO_IP6_2;  -- 0x86dd
  constant ETHER_PROTO_PAUSE       : std_logic_vector(15 downto 0) := X"8808";  -- 0x8808
  constant ETHERBROADCAST          : EtherAddr                     := X"FFFF" & X"FFFF" & X"FFFF";  -- ff:ff:ff:ff:ff:ff
  constant ETHERPAUSEADDR          : EtherAddr                     := X"0180" & X"C200" & X"0001";  -- 01:80:c2:00:00:01
  constant ETHERMULTICAST          : EtherAddr                     := X"0100" & X"0000" & X"0000";
  constant ETHER_MLT_25_PREFIX_IP4 : std_logic_vector(24 downto 0) := X"01005E" & B"0";
  constant ETHER_MLT_16_PREFIX_IP6 : std_logic_vector(15 downto 0) := X"3333";

  -- ARP constants
  constant ARP_HWTYPE_DIX1   : std_logic_vector(7 downto 0)  := X"00";
  constant ARP_HWTYPE_DIX2   : std_logic_vector(7 downto 0)  := X"01";
  constant ARP_HWTYPE_DIX    : std_logic_vector(15 downto 0) := ARP_HWTYPE_DIX1 & ARP_HWTYPE_DIX2;  -- 0x0001
  constant ARP_HWLEN_ETHER   : std_logic_vector(7 downto 0)  := X"06";  -- 6
  constant ARP_PROTOLEN_IP   : std_logic_vector(7 downto 0)  := X"04";  -- 4
  constant ARP_CODE_REQUEST1 : std_logic_vector(7 downto 0)  := X"00";
  constant ARP_CODE_REQUEST2 : std_logic_vector(7 downto 0)  := X"01";
  constant ARP_CODE_REQUEST  : std_logic_vector(15 downto 0) := ARP_CODE_REQUEST1 & ARP_CODE_REQUEST2;  -- 1
  constant ARP_CODE_REPLY1   : std_logic_vector(7 downto 0)  := X"00";
  constant ARP_CODE_REPLY2   : std_logic_vector(7 downto 0)  := X"02";
  constant ARP_CODE_REPLY    : std_logic_vector(15 downto 0) := ARP_CODE_REPLY1 & ARP_CODE_REPLY2;  -- 2

  constant ARPMODIFY_COMMAND_READ         : std_logic_vector(3 downto 0) := X"0";
  constant ARPMODIFY_COMMAND_WRITE        : std_logic_vector(3 downto 0) := X"1";
  constant ARPMODIFY_COMMAND_DELETE       : std_logic_vector(3 downto 0) := X"2";
  constant ARPMODIFY_COMMAND_WRITE_ATFREE : std_logic_vector(3 downto 0) := X"3";
  constant ARPMODIFY_COMMAND_DOWNCOUNT    : std_logic_vector(3 downto 0) := X"4";
  constant ARPMODIFY_COMMAND_MACCLEAR     : std_logic_vector(3 downto 0) := X"E";
  constant ARPMODIFY_COMMAND_RESET        : std_logic_vector(3 downto 0) := X"F";

  constant ARPMODIFY_UPLDEST_IPV6 : std_logic_vector(15 downto 0) := X"ABCD";

  constant ARPMODIFY_TTL_IPV6_GET_SOL : std_logic_vector(7 downto 0) := X"02";
  constant ARPMODIFY_TTL_IPV6_GET_ADV : std_logic_vector(7 downto 0) := X"03";

  -- IP constants
  constant IPv4_HEADER_LEN : integer := 20;  -- 標準的なヘッダ長
  constant IPv6_HEADER_LEN : integer := 40;  -- 標準的なヘッダ長

  -- IPv4
  constant IP_VERSION4     : std_logic_vector(3 downto 0) := X"4";
  constant IP_IHL_MINIMUM  : std_logic_vector(3 downto 0) := X"5";  -- "5" is header-length(x8byte)
  constant IP_TOS_DEFAULT  : std_logic_vector(7 downto 0) := X"00";
  constant IP_TTL_DEFAULT  : std_logic_vector(7 downto 0) := X"FF";
  constant IP_PROTO_ICMP   : std_logic_vector(7 downto 0) := X"01";  --  1
  constant IP_PROTO_TCP    : std_logic_vector(7 downto 0) := X"06";  --  6
  constant IP_PROTO_UDP    : std_logic_vector(7 downto 0) := X"11";  -- 17
  constant IP_PROTO_SOCKET : std_logic_vector(7 downto 0) := X"fe";  -- 254(defined by etrees)

  subtype IPv4Addr is std_logic_vector(31 downto 0);
  subtype SockPort is std_logic_vector(15 downto 0);

  -- IPv6
  constant IPv6_PROTO_HOPBYHOP   : std_logic_vector(7 downto 0) := X"00";  -- 00 :
  constant IPv6_PROTO_DESTOPTS   : std_logic_vector(7 downto 0) := X"3C";  -- 60 :
  constant IPv6_PROTO_ROUTING    : std_logic_vector(7 downto 0) := X"2B";  -- 43 :
  constant IPv6_PROTO_FLAGMENT   : std_logic_vector(7 downto 0) := X"2C";  -- 44 :
  constant IPv6_PROTO_AUTH       : std_logic_vector(7 downto 0) := X"33";  -- 51 :
  constant IPv6_PROTO_SECPAYLOAD : std_logic_vector(7 downto 0) := X"32";  -- 50 :

  constant IPv6_PROTO_IPV6   : std_logic_vector(7 downto 0) := X"29";  -- 41 : cuppseledl v6 in v6
  constant IPv6_PROTO_ICMPV6 : std_logic_vector(7 downto 0) := X"3A";  -- 58 :
  constant IPv6_PROTO_NONEXT : std_logic_vector(7 downto 0) := X"3B";  -- 59 : no payload
  constant IPv6_PROTO_TCP    : std_logic_vector(7 downto 0) := IP_PROTO_TCP;  -- X"06" =  6
  constant IPv6_PROTO_UDP    : std_logic_vector(7 downto 0) := IP_PROTO_UDP;  -- X"11" = 17

  constant IP_VERSION6     : std_logic_vector(3 downto 0)  := X"6";
  constant IPv6_TC_DEFAULT : std_logic_vector(7 downto 0)  := X"00";
  constant IPv6_FL_DEFAULT : std_logic_vector(19 downto 0) := X"00000";


  -- multi cast address
  constant IPv4_MLT_04_PREFIX : std_logic_vector(3 downto 0) := X"E";

  --  64 bit prefix ( LinkLocal, SiteLocal, Global )
  constant IPv6_UNI_064_PREFIX_LinkL  : std_logic_vector(63 downto 0)  := X"FE800000" & X"00000000";  -- fe80::0/10
  constant IPv6_UNI_064_PREFIX_SiteL  : std_logic_vector(63 downto 0)  := X"FEC00000" & X"00000000";  -- fec0::0/10
  constant IPv6_UNI_064_PREFIX_Global : std_logic_vector(63 downto 0)  := X"20000000" & X"00000000";  -- 2000::0/3, 2001：sTLA addr, 2002：6to4 addr, 3ffe：pTLA addr
  -- 128 bit loopback
  constant IPv6_UNI_128_FULL_Loopback : std_logic_vector(127 downto 0) := X"00000000" & X"00000000" & X"00000000" & X"00000001";  -- ::1/128
  -- 128 bit null for request to dhcpv6 srever
  constant IPv6_UNI_128_FULL_Null     : std_logic_vector(127 downto 0) := (others => '0');  -- ::/128
  --  96 bit prefix for IPv4 compatible
  constant IPv6_UNI_096_PREFIX_v4comp : std_logic_vector(95 downto 0)  := (others => '0');  -- ::/96
  --  32 bit null constant for 32bit width matching.
  constant IPv6_UNI_032_NULL          : std_logic_vector(31 downto 0)  := (others => '0');  -- ::/31

  -- multi cast address
  constant IPv6_MLT_008_PREFIX            : std_logic_vector(7 downto 0)   := X"FF";
  -- preserved by IANA
  constant IPv6_MLT_016_PREFIX_INTERFACE  : std_logic_vector(15 downto 0)  := X"FF01";  -- or X"FF11"
  constant IPv6_MLT_016_PREFIX_LINKLOCAL  : std_logic_vector(15 downto 0)  := X"FF02";  -- or X"FF12"
  constant IPv6_MLT_016_PREFIX_GLOBAL     : std_logic_vector(15 downto 0)  := X"FF0E";  -- or X"FF1E"
  constant IPv6_MLT_IANA_ALLNODE_1        : std_logic_vector(127 downto 0) := X"FF01" & X"0000" & X"00000000" & X"00000000" & X"0000" & X"0001";  -- ff01::1/128 all hosts, node-local multicast
  constant IPv6_MLT_IANA_ALLNODE_2        : std_logic_vector(127 downto 0) := X"FF02" & X"0000" & X"00000000" & X"00000000" & X"0000" & X"0001";  -- ff02::1/128 all hosts, link-local multicast
  constant IPv6_MLT_IANA_ALLROUTER_1      : std_logic_vector(127 downto 0) := X"FF01" & X"0000" & X"00000000" & X"00000000" & X"0000" & X"0002";  -- ff01::2/128 all routers
  constant IPv6_MLT_IANA_ALLROUTER_2      : std_logic_vector(127 downto 0) := X"FF02" & X"0000" & X"00000000" & X"00000000" & X"0000" & X"0002";  -- ff02::2/128 all routers
  constant IPv6_MLT_IANA_ALLROUTER_5      : std_logic_vector(127 downto 0) := X"FF05" & X"0000" & X"00000000" & X"00000000" & X"0000" & X"0002";  -- ff05::2/128 all routers
  constant IPv6_MLT_IANA_104_PREFIX_SOLND : std_logic_vector(103 downto 0) := X"FF02" & X"0000" & X"00000000" & X"00000001" & X"FF";  -- ff02::1:ff00:0000/104 requested node, when included my ip addr in multicast packet

  -- ICMP layer

  -- ICMPv4
  constant ICMP_TYPE_ECHOREQUEST : std_logic_vector(7 downto 0) := X"08";
  constant ICMP_TYPE_ECHOREPLY   : std_logic_vector(7 downto 0) := X"00";

  -- ICMPv6
  constant ICMPv6_TYPE_ECHOREQUEST  : std_logic_vector(7 downto 0) := X"80";
  constant ICMPv6_TYPE_ECHOREPLY    : std_logic_vector(7 downto 0) := X"81";
  constant ICMPv6_TYPE_ROUTER_SOL   : std_logic_vector(7 downto 0) := X"85";
  constant ICMPv6_TYPE_ROUTER_ADV   : std_logic_vector(7 downto 0) := X"86";
  constant ICMPv6_TYPE_NEIGHBOR_SOL : std_logic_vector(7 downto 0) := X"87";
  constant ICMPv6_TYPE_NEIGHBOR_ADV : std_logic_vector(7 downto 0) := X"88";

  -- ICMPv6 Neighbor Option
  constant ICMPv6_NEIGHBOR_OPTTYPE_SRCLINKADDR : std_logic_vector(7 downto 0) := X"01";  -- src link addr (solicitation)
  constant ICMPv6_NEIGHBOR_OPTTYPE_TRGLINKADDR : std_logic_vector(7 downto 0) := X"02";  -- dst link addr (advertisement)

  component e7udpip_kintex7
    port(
      -- GMII PHY : 2.5V
      GEPHY_RST_N    : out   std_logic ;  -- このchipにおけるシステムリセットを出す
      GEPHY_MAC_CLK  : in    std_logic ;  -- PHYからの125MHzCLK入力（COLピンの設定より）
      -- MAC I/F
      GEPHY_COL      : in    std_logic ;  -- CollisionDetect/MAC_FREQ兼用ピン。外部で2kPUされている。＝＞MAC_CLK出力を125MHzにしている様。
      GEPHY_CRS      : in    std_logic ;  -- CarrierSence/RGMII_SEL0兼用ピン。外部で2kPDされている。
      GEPHY_TXCLK    : in    std_logic ;  -- TXCLK/RGMII_SEL1兼用ピン。外部で2kPDされている。＝＞CRSと合わせてGMIIモードにしている。
      -- TX out
      GEPHY_TD       : out   std_logic_vector( 7 downto 0 ) ;  -- 送信データ
      GEPHY_TXEN     : out   std_logic ;
      GEPHY_TXER     : out   std_logic ;
      GEPHY_GTXCLK   : out   std_logic ;  -- 125MHz クロック出力
      -- RX in
      GEPHY_RD       : in    std_logic_vector( 7 downto 0 ) ;  -- 受信データ
      GEPHY_RXCLK    : in    std_logic ;  -- 10M=>2.5MHz, 100M=>25MHz, 1G=>125MHz のクロックが来る
      GEPHY_RXDV     : in    std_logic ;
      GEPHY_RXER     : in    std_logic ;
      -- Management I/F
      GEPHY_MDC      : out   std_logic ;  -- クロック出力。max.2.5MHz。
      GEPHY_MDIO     : inout std_logic ;  -- コントロールデータ。
      GEPHY_INT_N    : in    std_logic ;  -- インタラプト。

      -- Asynchronous Reset
      Reset_n        : in  std_logic;

      -- UPL interface
      pUPLGlobalClk : in  std_logic;
      -- UDP tx input
      pUdp0Send_Data       : in  std_logic_vector( 31 downto 0 );
      pUdp0Send_Request    : in  std_logic;
      pUdp0Send_Ack        : out std_logic;
      pUdp0Send_Enable     : in  std_logic;

      pUdp1Send_Data       : in  std_logic_vector( 31 downto 0 );
      pUdp1Send_Request    : in  std_logic;
      pUdp1Send_Ack        : out std_logic;
      pUdp1Send_Enable     : in  std_logic;

      -- UDP rx output
      pUdp0Receive_Data       : out std_logic_vector( 31 downto 0 );
      pUdp0Receive_Request    : out std_logic;
      pUdp0Receive_Ack        : in  std_logic;
      pUdp0Receive_Enable     : out std_logic;

      pUdp1Receive_Data       : out std_logic_vector( 31 downto 0 );
      pUdp1Receive_Request    : out std_logic;
      pUdp1Receive_Ack        : in  std_logic;
      pUdp1Receive_Enable     : out std_logic;

      -- MII interface
      pMIIInput_Data       : in  std_logic_vector( 31 downto 0 );
      pMIIInput_Request    : in  std_logic;
      pMIIInput_Ack        : out std_logic;
      pMIIInput_Enable     : in  std_logic;

      pMIIOutput_Data       : out std_logic_vector( 31 downto 0 );
      pMIIOutput_Request    : out std_logic;
      pMIIOutput_Ack        : in  std_logic;
      pMIIOutput_Enable     : out std_logic;
        
      -- Setup
      pMyIpAddr       : in std_logic_vector( 31 downto 0 );
      pMyMacAddr      : in std_logic_vector( 47 downto 0 );
      pMyNetmask      : in std_logic_vector( 31 downto 0 );
      pDefaultGateway : in std_logic_vector( 31 downto 0 );
      pTargetIPAddr   : in std_logic_vector( 31 downto 0 );
      pMyUdpPort0     : in std_logic_vector( 15 downto 0 );
      pMyUdpPort1     : in std_logic_vector( 15 downto 0 );
      pPHYAddr        : in std_logic_vector( 4 downto 0 );
      pPHYMode        : in std_logic_vector( 3 downto 0 );

      -- Status
      pStatus_RxByteCount             : out std_logic_vector( 31 downto 0 );
      pStatus_RxPacketCount           : out std_logic_vector( 31 downto 0 );
      pStatus_RxErrorPacketCount      : out std_logic_vector( 15 downto 0 );
      pStatus_RxDropPacketCount       : out std_logic_vector( 15 downto 0 );
      pStatus_RxARPRequestPacketCount : out std_logic_vector( 15 downto 0 );
      pStatus_RxARPReplyPacketCount   : out std_logic_vector( 15 downto 0 );
      pStatus_RxICMPPacketCount       : out std_logic_vector( 15 downto 0 );
      pStatus_RxUDP0PacketCount       : out std_logic_vector( 15 downto 0 );
      pStatus_RxUDP1PacketCount       : out std_logic_vector( 15 downto 0 );
      pStatus_RxIPErrorPacketCount    : out std_logic_vector( 15 downto 0 );
      pStatus_RxUDPErrorPacketCount   : out std_logic_vector( 15 downto 0 );

      pStatus_TxByteCount             : out std_logic_vector( 31 downto 0 );
      pStatus_TxPacketCount           : out std_logic_vector( 31 downto 0 );
      pStatus_TxARPRequestPacketCount : out std_logic_vector( 15 downto 0 );
      pStatus_TxARPReplyPacketCount   : out std_logic_vector( 15 downto 0 );
      pStatus_TxICMPReplyPacketCount  : out std_logic_vector( 15 downto 0 );
      pStatus_TxUDP0PacketCount       : out std_logic_vector( 15 downto 0 );
      pStatus_TxUDP1PacketCount       : out std_logic_vector( 15 downto 0 );
      pStatus_TxMulticastPacketCount  : out std_logic_vector( 15 downto 0 );

      pStatus_Phy : out std_logic_vector(15 downto 0);

      pdebug : out std_logic_vector(63 downto 0)
      );
  end component;

end constants;
