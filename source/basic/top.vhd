-----------------------------------------------------------------------------
-- Top Module
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

use work.constants.all;
use work.fmc150_components.all;
use work.etrees.all;
use work.misc.all;

entity top is
  port (
    
    --------------------------------------------------
    -- System
    --------------------------------------------------
    -- System clock
    SYSCLK_P : in std_logic;            -- 200MHz
    SYSCLK_N : in std_logic;
    
    -- Asynchronous reset
    RESET : in std_logic;
    
    --------------------------------------------------
    -- FMC150
    --------------------------------------------------
    ADC_CHA_N    : in  std_logic_vector (6 downto 0);
    ADC_CHA_P    : in  std_logic_vector (6 downto 0);
    ADC_CHB_N    : in  std_logic_vector (6 downto 0);
    ADC_CHB_P    : in  std_logic_vector (6 downto 0);
    ADC_SDO      : in  std_logic;
    CDCE_SDO     : in  std_logic;
    CLK_AB_N     : in  std_logic;
    CLK_AB_P     : in  std_logic;
    DAC_SDO      : in  std_logic;
    MON_N_INT    : in  std_logic;
    MON_SDO      : in  std_logic;
    PLL_STATUS   : in  std_logic;
    PRSNT_M2C_L  : in  std_logic;
    
    ADC_N_EN     : out std_logic;
    ADC_RESET    : out std_logic;
    CDCE_N_EN    : out std_logic;
    CDCE_N_PD    : out std_logic;
    CDCE_N_RESET : out std_logic;
    DAC_DATA_N   : out std_logic_vector (7 downto 0);
    DAC_DATA_P   : out std_logic_vector (7 downto 0);
    DAC_DCLK_N   : out std_logic;
    DAC_DCLK_P   : out std_logic;
    DAC_FRAME_N  : out std_logic;
    DAC_FRAME_P  : out std_logic;
    DAC_N_EN     : out std_logic;
    MON_N_EN     : out std_logic;
    MON_N_RESET  : out std_logic;
    REF_EN       : out std_logic;
    SPI_SCLK     : out std_logic;
    SPI_SDATA    : out std_logic;
    TXENABLE     : out std_logic;


    -- Ethernet
    -- GMII PHY : 2.5V
    GEPHY0_RST_N     : out std_logic;   -- system reset for PHY
    GEPHY0_MAC_CLK_P : in  std_logic;   -- 125MHz CLK input form PHY
    GEPHY0_MAC_CLK_N : in  std_logic;   -- 125MHz CLK input form PHY

    -- MAC I/F
    GEPHY0_COL   : in std_logic;        -- CollisionDetect/MAC_FREQ
    GEPHY0_CRS   : in std_logic;        -- CarrierSence/RGMII_SEL0
    GEPHY0_TXCLK : in std_logic;        -- TXCLK/RGMII_SEL1

    -- TX out
    GEPHY0_TD     : out std_logic_vector(7 downto 0);  -- TX DATA
    GEPHY0_TXEN   : out std_logic;
    GEPHY0_TXER   : out std_logic;
    GEPHY0_GTXCLK : out std_logic;      -- 125MHz CLK output to PHY

    -- RX in
    GEPHY0_RD    : in std_logic_vector(7 downto 0);  -- RX DATA
    GEPHY0_RXCLK : in std_logic;        -- 10M=>2.5MHz, 100M=>25MHz, 1G=>125MHz
    GEPHY0_RXDV  : in std_logic;
    GEPHY0_RXER  : in std_logic;

    -- Management I/F
    GEPHY0_MDC   : out   std_logic;     -- Clock output(max.2.5MHz)
    GEPHY0_MDIO  : inout std_logic;     -- control data
    GEPHY0_INT_N : in    std_logic;     -- interrupt


    --------------------------------------------------
    -- DDR3 SDRAM
    --------------------------------------------------
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

    --------------------------------------------------
    -- RS232C
    --------------------------------------------------
    rs232_dce_txd : out std_logic;
    rs232_dce_rxd : in  std_logic;
    rs232_rts     : out std_logic;
    rs232_cts     : in  std_logic;
    BTN_CENTER    : in  std_logic;
    BTN_SOUTH     : in  std_logic;
    BTN_NORTH     : in  std_logic;
    BTN_EAST      : in  std_logic;
    BTN_WEST      : in  std_logic;
    --------------------------------------------------
    -- for debuging
    --------------------------------------------------
    GPIO     : in  std_logic_vector(3 downto 0);
    LED      : out std_logic_vector(7 downto 0)
    
    );
end top;

architecture RTL of top is

  component clock_gen
    port
      ( -- Clock in ports
        CLK_IN1  : in  std_logic;
        -- Clock out ports
        CLK_OUT1 : out std_logic;
        CLK_OUT2 : out std_logic;
        CLK_OUT3 : out std_logic;
        -- Status and control signals
        RESET    : in  std_logic;
        LOCKED   : out std_logic
        );
  end component;

  signal clk_100MHz    : std_logic;
  signal clk_200MHz    : std_logic;
  signal clk_600MHz    : std_logic;
  signal sysclk_locked : std_logic;

  signal sysclk_i : std_logic;
  signal sysclk_bufg : std_logic;
  signal w_areset : std_logic;

  signal w_spi_sdata    : std_logic;
--  signal w_spi_sdata_we : std_logic;

    component udp_parser
    port (
      p_CLK   : in std_logic;
      p_RESET : in std_logic;

      p_LED                      : out std_logic;
      p_ADC_KICK                 : out std_logic;
      p_ADC_RUN                  : in  std_logic;
      p_ADC_ADDR_RESET           : out std_logic;
      p_DAC_KICK                 : out std_logic;
      p_DAC_RUN                  : in  std_logic;
      p_ADC_KICK_AFTER_DAC_START : out std_logic;
      p_ADDA_SAMPLING_POINTS     : out std_logic_vector(31 downto 0);
      p_ADDA_SAMPLING_POINTS_WE  : out std_logic;

      --UDP input
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

      -- User port
      p_MY_IP_ADDR     : in std_logic_vector(31 downto 0);
      p_MY_PORT        : in std_logic_vector(15 downto 0);
      p_SERVER_IP_ADDR : in std_logic_vector(31 downto 0);
      p_SERVER_PORT    : in std_logic_vector(15 downto 0);

      p_DEBUG : out std_logic_vector(7 downto 0)
      );
  end component udp_parser;

  component udp_packet_send_in_fifo_with_trigger

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

  end component udp_packet_send_in_fifo_with_trigger;

  component adc_sample
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
  end component adc_sample;

  component fifo2memiface
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
  end component fifo2memiface;

  component dac_sample
    generic (
      MAX_COUNT : integer := 512 * 1024 * 1024
      );
    port (
      p_Clk : in std_logic;
      p_Reset : in std_logic;
    
      -- p_Clk domain
      p_DAC_KICK       : in  std_logic;
      p_DAC_RUN        : out std_logic;
      p_DAC_DATA_IN    : in  std_logic_vector(127 downto 0);
      p_DAC_DATA_WE    : in  std_logic;
      p_DAC_PROG_FULL  : out std_logic;

      p_SAMPLING_POINTS : in std_logic_vector(31 downto 0);

      -- p_DAC_Clk domain
      p_DAC_CLK    : in std_logic;
      p_DAC_DATA_A : out std_logic_vector(15 downto 0);
      p_DAC_DATA_B : out std_logic_vector(15 downto 0);
      p_DAC_DATA_EN_PRE : out std_logic;
      p_DAC_DATA_EN     : out std_logic

      );
  end component dac_sample;

  component memiface2fifo
    generic (
      TX_COUNT_STEP : integer := 256;
      RX_COUNT_STEP : integer := 4
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
  end component memiface2fifo;

  component dds
    port (
      clk    : in  std_logic;
      cosine : out std_logic_vector(15 downto 0);
      sine   : out std_logic_vector(15 downto 0)
      );
  end component dds;

  signal UDP0Send_Data                                            : std_logic_vector(31 downto 0);
  signal UDP0Send_Enable, UDP0Send_Request, UDP0Send_Ack          : std_logic;
  signal UDP1Send_Data                                            : std_logic_vector(31 downto 0);
  signal UDP1Send_Enable, UDP1Send_Request, UDP1Send_Ack          : std_logic;
  signal UDP0Receive_Data                                         : std_logic_vector(31 downto 0);
  signal UDP0Receive_Enable, UDP0Receive_Request, UDP0Receive_Ack : std_logic;
  signal UDP1Receive_Data                                         : std_logic_vector(31 downto 0);
  signal UDP1Receive_Enable, UDP1Receive_Request, UDP1Receive_Ack : std_logic;

  signal w_dram2udp : UPL128;
  signal w_udp2dram : UPL128;
  
  signal w_arduino2dram : UPL128;
  signal w_dram2arduino : UPL128;

  signal UPLGlobalClk   : std_logic;
  signal UPLGlobalReset : std_logic;

  signal MyIpAddr         : std_logic_vector(31 downto 0);
  signal MyMacAddr        : std_logic_vector(47 downto 0);
  signal MyUdpPort0       : std_logic_vector(15 downto 0);
  signal MyUdpPort1       : std_logic_vector(15 downto 0);
  signal MyNetmask        : std_logic_vector(31 downto 0);
  signal MyDefaultGateway : std_logic_vector(31 downto 0);
  signal serverIpAddr     : std_logic_vector(31 downto 0);

  signal p_DEBUG : std_logic_vector(7 downto 0);
  signal counter : unsigned(31 downto 0) := (others => '0');

  signal w_init_calib_complete : std_logic;

  signal w_led : std_logic;

  attribute mark_debug : string;
  attribute keep       : string;

  signal w_dram2udp_data_d    : std_logic_vector(127 downto 0);
  signal w_dram2udp_request_d : std_logic;
  signal w_dram2udp_ack_d     : std_logic;
  signal w_dram2udp_enable_d  : std_logic;
  
  signal w_udp2dram_data_d    : std_logic_vector(127 downto 0);
  signal w_udp2dram_request_d : std_logic;
  signal w_udp2dram_ack_d     : std_logic;
  signal w_udp2dram_enable_d  : std_logic;
    
  signal w_dram2fifo_data_d    : std_logic_vector(127 downto 0);
  signal w_dram2fifo_request_d : std_logic;
  signal w_dram2fifo_ack_d     : std_logic;
  signal w_dram2fifo_enable_d  : std_logic;
  
  signal w_fifo2dram_data_d    : std_logic_vector(127 downto 0);
  signal w_fifo2dram_request_d : std_logic;
  signal w_fifo2dram_ack_d     : std_logic;
  signal w_fifo2dram_enable_d  : std_logic;
  
  signal w_fifo2dram_reply_data_d    : std_logic_vector(127 downto 0);
  signal w_fifo2dram_reply_request_d : std_logic;
  signal w_fifo2dram_reply_ack_d     : std_logic;
  signal w_fifo2dram_reply_enable_d  : std_logic;
  
  attribute mark_debug of w_dram2udp_data_d    : signal is "true";
  attribute mark_debug of w_dram2udp_request_d : signal is "true";
  attribute mark_debug of w_dram2udp_ack_d     : signal is "true";
  attribute mark_debug of w_dram2udp_enable_d  : signal is "true";
  
  attribute mark_debug of w_udp2dram_data_d    : signal is "true";
  attribute mark_debug of w_udp2dram_request_d : signal is "true";
  attribute mark_debug of w_udp2dram_ack_d     : signal is "true";
  attribute mark_debug of w_udp2dram_enable_d  : signal is "true";
    
  attribute mark_debug of w_dram2fifo_data_d    : signal is "true";
  attribute mark_debug of w_dram2fifo_request_d : signal is "true";
  attribute mark_debug of w_dram2fifo_ack_d     : signal is "true";
  attribute mark_debug of w_dram2fifo_enable_d  : signal is "true";
  
  attribute mark_debug of w_fifo2dram_data_d    : signal is "true";
  attribute mark_debug of w_fifo2dram_request_d : signal is "true";
  attribute mark_debug of w_fifo2dram_ack_d     : signal is "true";
  attribute mark_debug of w_fifo2dram_enable_d  : signal is "true";

  attribute mark_debug of w_fifo2dram_reply_data_d    : signal is "true";
  attribute mark_debug of w_fifo2dram_reply_request_d : signal is "true";
  attribute mark_debug of w_fifo2dram_reply_ack_d     : signal is "true";
  attribute mark_debug of w_fifo2dram_reply_enable_d  : signal is "true";

  attribute keep of w_dram2udp_data_d    : signal is "true";
  attribute keep of w_dram2udp_request_d : signal is "true";
  attribute keep of w_dram2udp_ack_d     : signal is "true";
  attribute keep of w_dram2udp_enable_d  : signal is "true";
  
  attribute keep of w_udp2dram_data_d    : signal is "true";
  attribute keep of w_udp2dram_request_d : signal is "true";
  attribute keep of w_udp2dram_ack_d     : signal is "true";
  attribute keep of w_udp2dram_enable_d  : signal is "true";
  
  attribute keep of w_dram2fifo_data_d    : signal is "true";
  attribute keep of w_dram2fifo_request_d : signal is "true";
  attribute keep of w_dram2fifo_ack_d     : signal is "true";
  attribute keep of w_dram2fifo_enable_d  : signal is "true";
  
  attribute keep of w_fifo2dram_data_d    : signal is "true";
  attribute keep of w_fifo2dram_request_d : signal is "true";
  attribute keep of w_fifo2dram_ack_d     : signal is "true";
  attribute keep of w_fifo2dram_enable_d  : signal is "true";

  attribute keep of w_fifo2dram_reply_data_d    : signal is "true";
  attribute keep of w_fifo2dram_reply_request_d : signal is "true";
  attribute keep of w_fifo2dram_reply_ack_d     : signal is "true";
  attribute keep of w_fifo2dram_reply_enable_d  : signal is "true";
  
  signal w_adc_out_clk : std_logic;
  signal w_adc_out_a   : std_logic_vector(15 downto 0);
  signal w_adc_out_b   : std_logic_vector(15 downto 0);

  signal w_adc_out_a_d   : std_logic_vector(15 downto 0);
  signal w_adc_out_b_d   : std_logic_vector(15 downto 0);
  
  attribute mark_debug of w_adc_out_a_d : signal is "true";
  attribute mark_debug of w_adc_out_b_d : signal is "true";
  attribute keep of w_adc_out_a_d : signal is "true";
  attribute keep of w_adc_out_b_d : signal is "true";

  signal w_adc_kick    : std_logic := '0';
  signal w_adc_run     : std_logic := '0';
  signal w_adc_data_re : std_logic := '0';
  
  signal w_adc_data_out   : std_logic_vector(127 downto 0) := (others => '0');
  signal w_adc_data_count : std_logic_vector(31 downto 0)  := (others => '0');

  signal w_fifo2memiface_addr_reset : std_logic := '0';
  
  signal w_fifo2dram       : UPL128;
  signal w_fifo2dram_reply : UPL128;
  
  signal w_dram2fifo       : UPL128;
  signal w_dram2fifo_reply : UPL128;
  
  signal w_adc_data_re_d : std_logic := '0';
  signal w_adc_data_out_d   : std_logic_vector(127 downto 0) := (others => '0');
  signal w_adc_data_count_d : std_logic_vector(31 downto 0)  := (others => '0');
    
  attribute mark_debug of w_adc_data_re_d    : signal is "true";
  attribute mark_debug of w_adc_data_out_d   : signal is "true";
  attribute mark_debug of w_adc_data_count_d : signal is "true";

  attribute keep of w_adc_data_re_d    : signal is "true";
  attribute keep of w_adc_data_out_d   : signal is "true";
  attribute keep of w_adc_data_count_d : signal is "true";

  signal adc_clk_counter : unsigned(31 downto 0);

  signal w_init_done : std_logic;

  signal w_dac_sample_kick      : std_logic;
  signal w_dac_sample_run       : std_logic;
  signal w_dac_sample_din       : std_logic_vector(127 downto 0);
  signal w_dac_sample_we        : std_logic;
  signal w_dac_sample_prog_full : std_logic;

  signal w_dac_out_clk : std_logic;
  signal w_dac_in_a : std_logic_vector(15 downto 0);
  signal w_dac_in_b : std_logic_vector(15 downto 0);
  
  signal w_dac_mem_out_a : std_logic_vector(15 downto 0);
  signal w_dac_mem_out_b : std_logic_vector(15 downto 0);

  signal w_dds_out_a : std_logic_vector(15 downto 0);
  signal w_dds_out_b : std_logic_vector(15 downto 0);

  signal w_memiface2fifo_kick : std_logic;
  signal w_memiface2fifo_busy : std_logic;

  signal w_dac_kick   : std_logic;
  signal w_dac_run    : std_logic;
  signal w_dac_kick_d : std_logic;
  signal w_dac_run_d  : std_logic;

  signal w_dac_sample_we_d : std_logic;
  
  signal w_dram2fifo_reply_request_d : std_logic;
  signal w_dram2fifo_reply_data_d    : std_logic_vector(127 downto 0);
  signal w_dram2fifo_reply_ack_d     : std_logic;
  signal w_dram2fifo_reply_enable_d  : std_logic;

  attribute mark_debug of w_dac_kick_d      : signal is "true";
  attribute mark_debug of w_dac_run_d       : signal is "true";
  attribute mark_debug of w_dac_sample_we_d : signal is "true";
  
  attribute mark_debug of w_dram2fifo_reply_request_d : signal is "true";
  attribute mark_debug of w_dram2fifo_reply_data_d    : signal is "true";
  attribute mark_debug of w_dram2fifo_reply_ack_d     : signal is "true";
  attribute mark_debug of w_dram2fifo_reply_enable_d  : signal is "true";

  attribute keep of w_dac_kick_d      : signal is "true";
  attribute keep of w_dac_run_d       : signal is "true";
  attribute keep of w_dac_sample_we_d : signal is "true";
  
  attribute keep of w_dram2fifo_reply_request_d : signal is "true";
  attribute keep of w_dram2fifo_reply_data_d    : signal is "true";
  attribute keep of w_dram2fifo_reply_ack_d     : signal is "true";
  attribute keep of w_dram2fifo_reply_enable_d  : signal is "true";

  signal w_dac_data_en_pre : std_logic;
  signal w_dac_data_en     : std_logic;

  signal w_adc_kick_after_dac_start : std_logic;

  signal w_adc_monitor_fifo_wr_en   : std_logic := '0';
  signal w_adc_monitor_fifo_trigger : std_logic;
  signal w_adc_monitor_fifo_full    : std_logic;
  signal w_adc_monitor_fifo_count   : std_logic_vector(9 downto 0);
  signal w_adc_monitor_counter      : unsigned(31 downto 0) := (others => '0');
  attribute keep of w_adc_monitor_fifo_count : signal is "true";
  attribute mark_debug of w_adc_monitor_fifo_count : signal is "true";
    
  signal w_adc_monitor_fifo_trigger_d : std_logic;
  signal w_adc_monitor_fifo_trigger_dd : std_logic;

  component f32c_with_upl_kintex7
    port (
      clk100m : in std_logic;

      rs232_dce_txd : out std_logic;
      rs232_dce_rxd : in  std_logic;
      rs232_rts     : out std_logic;
      rs232_cts     : in  std_logic;

      seg        : out std_logic_vector(7 downto 0);  -- 7-segment display
      an         : out std_logic_vector(3 downto 0);  -- 7-segment display
      led        : out std_logic_vector(7 downto 0);
      btn_center : in  std_logic;
      btn_south  : in  std_logic;
      btn_north  : in  std_logic;
      btn_east   : in  std_logic;
      btn_west   : in  std_logic;
      sw         : in  std_logic_vector(7 downto 0);

      UPLGlobalClk : in std_logic;
      
      UPL0Send_Data    : out std_logic_vector(31 downto 0);
      UPL0Send_Enable  : out std_logic;
      UPL0Send_Request : out std_logic;
      UPL0Send_Ack     : in  std_logic;
      
      UPL0Receive_Data    : in  std_logic_vector(31 downto 0);
      UPL0Receive_Enable  : in  std_logic;
      UPL0Receive_Request : in  std_logic;
      UPL0Receive_Ack     : out std_logic
      );
  end component f32c_with_upl_kintex7;

  signal f32c_led : std_logic_vector(7 downto 0);

  signal w_f32c_to_parser : UPL32;
  signal w_parser_to_f32c : UPL32;
  
  signal w_led_0                      : std_logic;
  signal w_adc_kick_0                 : std_logic;
  signal w_adc_run_0                  : std_logic;
  signal w_fifo2memiface_addr_reset_0 : std_logic;
  signal w_dac_kick_0                 : std_logic;
  signal w_dac_run_0                  : std_logic;
  signal w_adc_kick_after_dac_start_0 : std_logic;

  signal w_led_1                      : std_logic;
  signal w_adc_kick_1                 : std_logic;
  signal w_adc_run_1                  : std_logic;
  signal w_fifo2memiface_addr_reset_1 : std_logic;
  signal w_dac_kick_1                 : std_logic;
  signal w_dac_run_1                  : std_logic;
  signal w_adc_kick_after_dac_start_1 : std_logic;

  signal w_adda_sampling_points      : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1 * 1024 * 1024, 32));
  signal w_adda_sampling_points_0    : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1 * 1024 * 1024, 32));
  signal w_adda_sampling_points_1    : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1 * 1024 * 1024, 32));
  signal w_adda_sampling_points_we_0 : std_logic;
  signal w_adda_sampling_points_we_1 : std_logic;

begin

  MyIpAddr         <= X"0a000001";
  MyMacAddr        <= X"001b1aff0001";
  MyUdpPort0       <= X"4000";
  MyUdpPort1       <= X"4001";
  MyNetmask        <= X"ff000000";
  MyDefaultGateway <= X"0a0000fe";
  serverIpAddr     <= X"0a000003";


  ibufds_instance : IBUFDS port map (
    I  => SYSCLK_P,
    IB => SYSCLK_N,
    O  => sysclk_i
    );

  bufg_instance : BUFG port map(
    I => sysclk_i,
    O => sysclk_bufg
    );

  ---- System Clock
  clk_system_syn : clock_gen port map (
    CLK_IN1  => sysclk_bufg,
    -- Clock out ports
    CLK_OUT1 => clk_100MHz,
    CLK_OUT2 => clk_200MHz,
    CLK_OUT3 => clk_600MHz,
    RESET    => RESET,
    LOCKED   => sysclk_locked
    );

  w_areset <= '0' when RESET = '0' and sysclk_locked = '1' else '1';

  U_FMC150 : FMC150_sample port map(
    clk_100MHz   => clk_100MHz,
    clk_200MHz   => clk_200MHz,
    clk_locked   => sysclk_locked,
    cpu_reset    => RESET,
    adc_cha_n    => adc_cha_n,
    adc_cha_p    => adc_cha_p,
    adc_chb_n    => adc_chb_n,
    adc_chb_p    => adc_chb_p,
    adc_sdo      => adc_sdo,
    cdce_sdo     => cdce_sdo,
    clk_ab_n     => clk_ab_n,
    clk_ab_p     => clk_ab_p,
    dac_sdo      => dac_sdo,
    mon_n_int    => mon_n_int,
    mon_sdo      => mon_sdo,
    pll_status   => pll_status,
    prsnt_m2c_l  => prsnt_m2c_l,
    adc_n_en     => adc_n_en,
    adc_reset    => adc_reset,
    cdce_n_en    => cdce_n_en,
    cdce_n_pd    => cdce_n_pd,
    cdce_n_reset => cdce_n_reset,
    dac_data_n   => dac_data_n,
    dac_data_p   => dac_data_p,
    dac_dclk_n   => dac_dclk_n,
    dac_dclk_p   => dac_dclk_p,
    dac_frame_n  => dac_frame_n,
    dac_frame_p  => dac_frame_p,
    dac_n_en     => dac_n_en,
    mon_n_en     => mon_n_en,
    mon_n_reset  => mon_n_reset,
    ref_en       => ref_en,
    spi_sclk     => spi_sclk,
    spi_sdata    => w_spi_sdata,
--    spi_sdata_we => w_spi_sdata_we,
    txenable     => txenable,
    
    p_INIT_DONE => w_init_done,

    p_ADC_OUT_CLK => w_adc_out_clk,
    p_ADC_OUT_A   => w_adc_out_a,
    p_ADC_OUT_B   => w_adc_out_b,

    p_DAC_OUT_CLK => w_dac_out_clk,
    p_DAC_IN_A    => w_dac_in_a,
    p_DAC_IN_B    => w_dac_in_b
    );
--  SPI_SDATA <= w_spi_sdata when w_spi_sdata_we = '1' else 'Z';
  SPI_SDATA <= w_spi_sdata;
  
  U_e7UDPIP : e7udpip_kc705 port map(
    CLK_200MHz       => clk_200MHz,
    CLK_600MHz       => clk_600MHz,
    DDR_REFCLK       => clk_200MHz,
    RESET            => w_areset,
    GEPHY0_RST_N     => GEPHY0_RST_N,
    GEPHY0_MAC_CLK_P => GEPHY0_MAC_CLK_P,
    GEPHY0_MAC_CLK_N => GEPHY0_MAC_CLK_N,
    GEPHY0_COL       => GEPHY0_COL,
    GEPHY0_CRS       => GEPHY0_CRS,
    GEPHY0_TXCLK     => GEPHY0_TXCLK,
    GEPHY0_TD        => GEPHY0_TD,
    GEPHY0_TXEN      => GEPHY0_TXEN,
    GEPHY0_TXER      => GEPHY0_TXER,
    GEPHY0_GTXCLK    => GEPHY0_GTXCLK,
    GEPHY0_RD        => GEPHY0_RD,
    GEPHY0_RXCLK     => GEPHY0_RXCLK,
    GEPHY0_RXDV      => GEPHY0_RXDV,
    GEPHY0_RXER      => GEPHY0_RXER,
    GEPHY0_MDC       => GEPHY0_MDC,
    GEPHY0_MDIO      => GEPHY0_MDIO,
    GEPHY0_INT_N     => GEPHY0_INT_N,
    DDR3_DM          => DDR3_DM,
    DDR3_DQ          => DDR3_DQ,
    DDR3_DQS_P       => DDR3_DQS_P,
    DDR3_DQS_N       => DDR3_DQS_N,
    DDR3_ADDR        => DDR3_ADDR,
    DDR3_CK_P        => DDR3_CK_P,
    DDR3_CK_N        => DDR3_CK_N,
    DDR3_BA          => DDR3_BA,
    DDR3_RAS_N       => DDR3_RAS_N,
    DDR3_CAS_N       => DDR3_CAS_N,
    DDR3_WE_N        => DDR3_WE_N,
    DDR3_CS_N        => DDR3_CS_N,
    DDR3_CKE         => DDR3_CKE,
    DDR3_ODT         => DDR3_ODT,
    DDR3_RESET_N     => DDR3_RESET_N,
    INIT_CALIB_COMPLETE_OUT => w_init_calib_complete,

    UPLGlobalClk   => UPLGlobalClk,
    UPLGlobalReset => UPLGlobalReset,

    MyIpAddr         => MyIpAddr,
    MyMacAddr        => MyMacAddr,
    MyUdpPort0       => MyUdpPort0,
    MyUdpPort1       => MyUdpPort1,
    MyNetmask        => MyNetmask,
    MyDefaultGateway => MyDefaultGateway,
    serverIpAddr     => serverIpAddr,

    UDP0Send_Data       => UDP0Send_Data,
    UDP0Send_Enable     => UDP0Send_Enable,
    UDP0Send_Request    => UDP0Send_Request,
    UDP0Send_Ack        => UDP0Send_Ack,
    
    UDP1Send_Data       => UDP1Send_Data,
    UDP1Send_Enable     => UDP1Send_Enable,
    UDP1Send_Request    => UDP1Send_Request,
    UDP1Send_Ack        => UDP1Send_Ack,
    
    UDP0Receive_Data    => UDP0Receive_Data,
    UDP0Receive_Enable  => UDP0Receive_Enable,
    UDP0Receive_Request => UDP0Receive_Request,
    UDP0Receive_Ack     => UDP0Receive_Ack,
    
    UDP1Receive_Data    => UDP1Receive_Data,
    UDP1Receive_Enable  => UDP1Receive_Enable,
    UDP1Receive_Request => UDP1Receive_Request,
    UDP1Receive_Ack     => UDP1Receive_Ack,

    DDR3_WR0_Request => w_udp2dram.request,
    DDR3_WR0_Ack     => w_udp2dram.ack,
    DDR3_WR0_En      => w_udp2dram.enable,
    DDR3_WR0_Data    => w_udp2dram.data,
    
    DDR3_WR1_Request => w_fifo2dram.request,
    DDR3_WR1_Ack     => w_fifo2dram.ack,
    DDR3_WR1_En      => w_fifo2dram.enable,
    DDR3_WR1_Data    => w_fifo2dram.data,
        
    DDR3_WR2_Request => w_dram2fifo.request,
    DDR3_WR2_Ack     => w_dram2fifo.ack,
    DDR3_WR2_En      => w_dram2fifo.enable,
    DDR3_WR2_Data    => w_dram2fifo.data,
    
    DDR3_WR3_Request => w_arduino2dram.request,
    DDR3_WR3_Ack     => w_arduino2dram.ack,
    DDR3_WR3_En      => w_arduino2dram.enable,
    DDR3_WR3_Data    => w_arduino2dram.data,

    DDR3_RD0_Request => w_dram2udp.request,
    DDR3_RD0_Ack     => w_dram2udp.ack,
    DDR3_RD0_En      => w_dram2udp.enable,
    DDR3_RD0_Data    => w_dram2udp.data,
    
    DDR3_RD1_Request => w_fifo2dram_reply.request,
    DDR3_RD1_Ack     => w_fifo2dram_reply.ack,
    DDR3_RD1_En      => w_fifo2dram_reply.enable,
    DDR3_RD1_Data    => w_fifo2dram_reply.data,
    
    DDR3_RD2_Request => w_dram2fifo_reply.request,
    DDR3_RD2_Ack     => w_dram2fifo_reply.ack,
    DDR3_RD2_En      => w_dram2fifo_reply.enable,
    DDR3_RD2_Data    => w_dram2fifo_reply.data,
    
    DDR3_RD3_Request => w_dram2arduino.request,
    DDR3_RD3_Ack     => w_dram2arduino.ack,
    DDR3_RD3_En      => w_dram2arduino.enable,
    DDR3_RD3_Data    => w_dram2arduino.data
    );

  w_led                      <= w_led_0 or w_led_1;
  w_adc_kick                 <= w_adc_kick_0 or w_adc_kick_1;
  w_fifo2memiface_addr_reset <= w_fifo2memiface_addr_reset_0 or w_fifo2memiface_addr_reset_1;
  w_dac_kick                 <= w_dac_kick_0 or w_dac_kick_1;
  w_adc_kick_after_dac_start <= w_adc_kick_after_dac_start_0 or w_adc_kick_after_dac_start_1;
  
  w_adc_run_0 <= w_adc_run;
  w_adc_run_1 <= w_adc_run;
  w_dac_run_0 <= w_dac_run;
  w_dac_run_1 <= w_dac_run;
  
  U_SAMPLE0 : udp_parser port map(
    p_CLK   => UPLGlobalClk,
    p_RESET => UPLGlobalReset,

    p_LED                      => w_led_0,
    p_ADC_KICK                 => w_adc_kick_0,
    p_ADC_RUN                  => w_adc_run_0,
    p_ADC_ADDR_RESET           => w_fifo2memiface_addr_reset_0,
    p_DAC_KICK                 => w_dac_kick_0,
    p_DAC_RUN                  => w_dac_run_0,
    p_ADC_KICK_AFTER_DAC_START => w_adc_kick_after_dac_start_0,
    p_ADDA_SAMPLING_POINTS     => w_adda_sampling_points_0,
    p_ADDA_SAMPLING_POINTS_WE  => w_adda_sampling_points_we_0,
    
    -- 入力
    p_UDP_RX_DATA    => Udp0Receive_Data,
    p_UDP_RX_REQUEST => Udp0Receive_Request,
    p_UDP_RX_ACK     => Udp0Receive_Ack,
    p_UDP_RX_ENABLE  => Udp0Receive_Enable,
    -- 出力
    p_UDP_TX_DATA    => UDP0Send_Data,
    p_UDP_TX_REQUEST => UDP0Send_Request,
    p_UDP_TX_ACK     => UDP0Send_Ack,
    p_UDP_TX_ENABLE  => UDP0Send_Enable,

    -- DRAM (DDR3) input
    p_DRAM_RX_DATA    => w_dram2udp.data,
    p_DRAM_RX_REQUEST => w_dram2udp.request,
    p_DRAM_RX_ACK     => w_dram2udp.ack,
    p_DRAM_RX_ENABLE  => w_dram2udp.enable,

    -- DRAM (DDR3) output
    p_DRAM_TX_DATA    => w_udp2dram.data,
    p_DRAM_TX_REQUEST => w_udp2dram.request,
    p_DRAM_TX_ACK     => w_udp2dram.ack,
    p_DRAM_TX_ENABLE  => w_udp2dram.enable,

    -- ユーザポート
    p_MY_IP_ADDR     => MyIpAddr,
    p_MY_PORT        => MyUDPPort0,
    p_SERVER_IP_ADDR => serverIpAddr,
    p_SERVER_PORT    => MyUDPPort0,

    p_DEBUG => p_DEBUG
    );

  U_SAMPLE1 : udp_packet_send_in_fifo_with_trigger

    port map(
      p_CLK   => UPLGlobalClk,
      p_RESET => UPLGlobalReset,

      --UDP Input
      pI0Data    => Udp1Receive_Data,
      pI0Request => Udp1Receive_Request,
      pI0Ack     => Udp1Receive_Ack,
      pI0En      => Udp1Receive_Enable,
      -- UDP Output
      pO0Data    => UDP1Send_Data,
      pO0Request => UDP1Send_Request,
      pO0Ack     => UDP1Send_Ack,
      pO0En      => UDP1Send_Enable,

      -- User port
      p_MY_IP_ADDR     => MyIpAddr,
      p_MY_PORT        => MyUDPPort1,
      p_SERVER_IP_ADDR => serverIpAddr,
      p_SERVER_PORT    => MyUDPPort1,

      -- FIFO write
      p_FIFO_WR_CLK => w_adc_out_clk,
      p_FIFO_WR_EN  => w_adc_monitor_fifo_wr_en,
      p_FIFO_DIN    => w_adc_out_a & w_adc_out_b,
      p_FIFO_FULL   => w_adc_monitor_fifo_full,
      p_FIFO_WR_DATA_COUNT => w_adc_monitor_fifo_count,

      p_TRIGGER => w_adc_monitor_fifo_trigger
      );

  process(w_adc_out_clk)
  begin
    if w_adc_out_clk'event and w_adc_out_clk = '1' then
      w_adc_monitor_fifo_trigger_d  <= w_adc_monitor_fifo_trigger;
      w_adc_monitor_fifo_trigger_dd <= w_adc_monitor_fifo_trigger_d;
      if w_adc_monitor_fifo_trigger_dd = '1' then
        w_adc_monitor_fifo_wr_en <= '1';
      elsif unsigned(w_adc_monitor_fifo_count) >= 256 then
        w_adc_monitor_fifo_wr_en <= '0';
      end if;
    end if;
  end process;
  
  LED(0) <= not UPLGlobalReset             when GPIO(0) = '0' else f32c_led(0);
  LED(1) <= w_init_calib_complete          when GPIO(0) = '0' else f32c_led(1);
  LED(2) <= w_init_done                    when GPIO(0) = '0' else f32c_led(2);
  LED(3) <= std_logic(adc_clk_counter(24)) when GPIO(0) = '0' else f32c_led(3);
  LED(4) <= p_DEBUG(0)                     when GPIO(0) = '0' else f32c_led(4);
  LED(5) <= p_DEBUG(1)                     when GPIO(0) = '0' else f32c_led(5);
  LED(6) <= std_logic(counter(24))         when GPIO(0) = '0' else f32c_led(6);
  LED(7) <= w_led                          when GPIO(0) = '0' else f32c_led(7);
  process(UPLGlobalClk)
  begin
    if(UPLGlobalClk'event and UPLGlobalClk = '1') then
      if UPLGlobalReset = '1' then
        counter <= (others => '0');
      else
        counter <= counter + 1;
      end if;
    end if;
  end process;
  
  process(w_adc_out_clk)
  begin
    if(w_adc_out_clk'event and w_adc_out_clk = '1') then
      if UPLGlobalReset = '1' then
        adc_clk_counter <= (others => '0');
      else
        adc_clk_counter <= adc_clk_counter + 1;
      end if;
    end if;
  end process;

  process(UPLGlobalClk)
  begin
    if(UPLGlobalClk'event and UPLGlobalClk = '1') then
      -- to DDR3
      w_dram2udp_data_d    <= w_dram2udp.data;
      w_dram2udp_request_d <= w_dram2udp.request;
      w_dram2udp_ack_d     <= w_dram2udp.ack;
      w_dram2udp_enable_d  <= w_dram2udp.enable;

      w_fifo2dram_data_d    <= w_fifo2dram.data;
      w_fifo2dram_request_d <= w_fifo2dram.request;
      w_fifo2dram_ack_d     <= w_fifo2dram.ack;
      w_fifo2dram_enable_d  <= w_fifo2dram.enable;

      w_dram2fifo_data_d    <= w_dram2fifo.data;
      w_dram2fifo_request_d <= w_dram2fifo.request;
      w_dram2fifo_ack_d     <= w_dram2fifo.ack;
      w_dram2fifo_enable_d  <= w_dram2fifo.enable;

      -- from DDR3
      w_udp2dram_data_d    <= w_udp2dram.data;
      w_udp2dram_request_d <= w_udp2dram.request;
      w_udp2dram_ack_d     <= w_udp2dram.ack;
      w_udp2dram_enable_d  <= w_udp2dram.enable;

      w_dram2fifo_reply_data_d    <= w_dram2fifo_reply.data;
      w_dram2fifo_reply_request_d <= w_dram2fifo_reply.request;
      w_dram2fifo_reply_ack_d     <= w_dram2fifo_reply.ack;
      w_dram2fifo_reply_enable_d  <= w_dram2fifo_reply.enable;
      
      -- adc/dac
      w_adc_data_out_d <= w_adc_data_out;
      w_adc_data_re_d <= w_adc_data_re;
      w_adc_data_count_d <= w_adc_data_count;

      w_dac_kick_d <= w_dac_kick;
      w_dac_run_d <= w_dac_run;

      w_dram2fifo_reply_ack_d <= w_dram2fifo_reply.ack;
      
    end if;
  end process;

  U_ADC_SAMPLE: adc_sample
    port map(
      p_Clk => UPLGlobalClk,
      p_Reset => UPLGlobalReset,
    
      -- p_Clk domain
      p_ADC_KICK       => w_adc_kick or (w_adc_kick_after_dac_start and w_dac_data_en),
      p_ADC_RUN        => w_adc_run,
      p_ADC_DATA_OUT   => w_adc_data_out,
      p_ADC_DATA_RE    => w_adc_data_re,
      p_ADC_DATA_COUNT => w_adc_data_count,

      p_SAMPLING_POINTS => w_adda_sampling_points,

      -- p_ADC_Clk domain
      p_ADC_CLK    => w_adc_out_clk,
      p_ADC_DATA_A => w_adc_out_a,
      p_ADC_DATA_B => w_adc_out_b

      );

  U_FIFO2MEMIFACE : fifo2memiface
    port map(
      p_Clk => UPLGlobalClk,
      p_Reset => UPLGlobalReset,
    
      p_DDR3_MEMORY_OFFSET => std_logic_vector(to_unsigned(0, 32)),

      p_FIFO_DATA_OUT   => w_adc_data_out,
      p_FIFO_DATA_RE    => w_adc_data_re,
      p_FIFO_DATA_COUNT => w_adc_data_count,

      p_MemIface_UPL_Enable  => w_fifo2dram.enable,
      p_MemIface_UPL_Request => w_fifo2dram.request,
      p_MemIface_UPL_Ack     => w_fifo2dram.ack,
      p_MemIface_UPL_Data    => w_fifo2dram.data,

      p_MemIface_UPL_Reply_Ack => w_fifo2dram_reply.ack,
      p_MemIface_UPL_Reply_En  => w_fifo2dram_reply.enable,
      
      p_MemIface_ADDR_Reset  => w_fifo2memiface_addr_reset
      );

  U_DAC_SAMPLE: dac_sample
    generic map(
      MAX_COUNT => 512 * 1024 * 1024 -- 512M (1024*1024) samples
      )
    port map(
      p_Clk => UPLGlobalClk,
      p_Reset => UPLGlobalReset,
    
      -- p_Clk domain
      p_DAC_KICK       => w_dac_sample_kick,
      p_DAC_RUN        => w_dac_sample_run,
      p_DAC_DATA_IN    => w_dac_sample_din,
      p_DAC_DATA_WE    => w_dac_sample_we,
      p_DAC_PROG_FULL  => w_dac_sample_prog_full,

      p_SAMPLING_POINTS => w_adda_sampling_points,

      -- p_DAC_Clk domain
      p_DAC_CLK    => w_dac_out_clk,
      p_DAC_DATA_A => w_dac_mem_out_a,
      p_DAC_DATA_B => w_dac_mem_out_b,
      p_DAC_DATA_EN_PRE => w_dac_data_en_pre,
      p_DAC_DATA_EN     => w_dac_data_en
      
      );

  U_MEMIFACE2FIFO: memiface2fifo
    generic map(
      TX_COUNT_STEP => 256, -- "1024 byte" corresponds to "256 samples for 2ch",
                            -- because a sample/ch is 2Byte.
      RX_COUNT_STEP => 4 -- "128 bit" corresponds to "4 samples for 2ch",
                         -- because a sample/ch is 16bit.
      )
    port map(
      p_Clk => UPLGlobalClk,
      p_Reset => UPLGlobalReset,

      p_KICK => w_memiface2fifo_kick,
      p_BUSY => w_memiface2fifo_busy,
    
      p_DDR3_MEMORY_OFFSET => std_logic_vector(to_unsigned(512 * 1024 * 1024, 32)),
      p_READ_WRITE_COUNT => w_adda_sampling_points,

      p_FIFO_DATA_OUT   => w_dac_sample_din,
      p_FIFO_DATA_WE    => w_dac_sample_we,
      p_FIFO_PROG_FULL  => w_dac_sample_prog_full,

      p_MemIface_UPL_Enable  => w_dram2fifo.enable,
      p_MemIface_UPL_Request => w_dram2fifo.request,
      p_MemIface_UPL_Ack     => w_dram2fifo.ack,
      p_MemIface_UPL_Data    => w_dram2fifo.data,

      p_MemIface_UPL_Reply_Ack     => w_dram2fifo_reply.ack,
      p_MemIface_UPL_Reply_En      => w_dram2fifo_reply.enable,
      p_MemIface_UPL_Reply_Data    => w_dram2fifo_reply.data,
      p_MemIface_UPL_Reply_Request => w_dram2fifo_reply.request
      );

  w_dac_sample_kick <= w_dac_kick;
  w_memiface2fifo_kick <= w_dac_kick;

  w_dac_run <= w_dac_sample_run;

  process(w_adc_out_clk)
  begin
    if w_adc_out_clk'event and w_adc_out_clk = '1' then
      w_adc_out_a_d <= w_adc_out_a;
      w_adc_out_b_d <= w_adc_out_b;
    end if;
  end process;

  -- DDS
    dds_syn : dds port map (
      clk    => w_dac_out_clk,
      cosine => w_dds_out_a,
      sine   => w_dds_out_b
      );

  --process(w_dac_out_clk)
  --begin
  --  if w_dac_out_clk'event and w_dac_out_clk = '1' then
  --    if GPIO(0) = '1' then
  --      w_dac_in_a <= w_dac_mem_out_a;
  --      w_dac_in_b <= w_dac_mem_out_b;
  --    else
  --      w_dac_in_a <= w_dds_out_a;
  --      w_dac_in_b <= w_dds_out_b;
  --    end if;
  --  end if;
  --end process;
  w_dac_in_a <= w_dac_mem_out_a;
  w_dac_in_b <= w_dac_mem_out_b;

  U_F32C: f32c_with_upl_kintex7
    port map(
      clk100m => clk_100MHz,

      rs232_dce_txd => rs232_dce_txd,
      rs232_dce_rxd => rs232_dce_rxd,
      rs232_rts     => rs232_rts,
      rs232_cts     => rs232_cts,

      seg        => open,
      an         => open,
      led        => f32c_led,
      btn_center => BTN_CENTER,
      btn_south  => BTN_SOUTH,
      btn_north  => BTN_NORTH,
      btn_east   => BTN_EAST,
      btn_west   => BTN_WEST,
      sw         => (others => '0'),

      UPLGlobalClk => UPLGlobalClk,
      
      UPL0Send_Data    => w_f32c_to_parser.data,
      UPL0Send_Enable  => w_f32c_to_parser.enable,
      UPL0Send_Request => w_f32c_to_parser.request,
      UPL0Send_Ack     => w_f32c_to_parser.ack,
      
      UPL0Receive_Data    => w_parser_to_f32c.data,
      UPL0Receive_Enable  => w_parser_to_f32c.enable,
      UPL0Receive_Request => w_parser_to_f32c.request,
      UPL0Receive_Ack     => w_parser_to_f32c.ack
      );
  
  U_SAMPLE2 : udp_parser port map(
    p_CLK   => UPLGlobalClk,
    p_RESET => UPLGlobalReset,

    p_LED                      => w_led_1,
    p_ADC_KICK                 => w_adc_kick_1,
    p_ADC_RUN                  => w_adc_run_1,
    p_ADC_ADDR_RESET           => w_fifo2memiface_addr_reset_1,
    p_DAC_KICK                 => w_dac_kick_1,
    p_DAC_RUN                  => w_dac_run_1,
    p_ADC_KICK_AFTER_DAC_START => w_adc_kick_after_dac_start_1,
    p_ADDA_SAMPLING_POINTS     => w_adda_sampling_points_1,
    p_ADDA_SAMPLING_POINTS_WE  => w_adda_sampling_points_we_1,
    
    -- 入力
    p_UDP_RX_DATA    => w_f32c_to_parser.data,
    p_UDP_RX_REQUEST => w_f32c_to_parser.request,
    p_UDP_RX_ACK     => w_f32c_to_parser.ack,
    p_UDP_RX_ENABLE  => w_f32c_to_parser.enable,
    -- 出力
    p_UDP_TX_DATA    => w_parser_to_f32c.data,
    p_UDP_TX_REQUEST => w_parser_to_f32c.request,
    p_UDP_TX_ACK     => w_parser_to_f32c.ack,
    p_UDP_TX_ENABLE  => w_parser_to_f32c.enable,

    -- DRAM (DDR3) input
    p_DRAM_RX_DATA    => w_dram2arduino.data,
    p_DRAM_RX_REQUEST => w_dram2arduino.request,
    p_DRAM_RX_ACK     => w_dram2arduino.ack,
    p_DRAM_RX_ENABLE  => w_dram2arduino.enable,

    -- DRAM (DDR3) output
    p_DRAM_TX_DATA    => w_arduino2dram.data,
    p_DRAM_TX_REQUEST => w_arduino2dram.request,
    p_DRAM_TX_ACK     => w_arduino2dram.ack,
    p_DRAM_TX_ENABLE  => w_arduino2dram.enable,

    -- ユーザポート
    p_MY_IP_ADDR     => MyIpAddr,
    p_MY_PORT        => MyUDPPort0,
    p_SERVER_IP_ADDR => serverIpAddr,
    p_SERVER_PORT    => MyUDPPort0,

    p_DEBUG => open
    );

  w_adda_sampling_points <= w_adda_sampling_points_0 when w_adda_sampling_points_we_0 = '1' else
                            w_adda_sampling_points_1 when w_adda_sampling_points_we_1 = '1' else
                            w_adda_sampling_points;

end RTL;
