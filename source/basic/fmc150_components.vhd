library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fmc150_components is

  component FMC150_sample
    port (

      clk_100MHz : in std_logic;
      clk_200MHz : in std_logic;
      clk_locked : in std_logic;

      adc_cha_n    : in  std_logic_vector (6 downto 0);
      adc_cha_p    : in  std_logic_vector (6 downto 0);
      adc_chb_n    : in  std_logic_vector (6 downto 0);
      adc_chb_p    : in  std_logic_vector (6 downto 0);
      adc_sdo      : in  std_logic;
      cdce_sdo     : in  std_logic;
      clk_ab_n     : in  std_logic;
      clk_ab_p     : in  std_logic;
      cpu_reset    : in  std_logic;
      dac_sdo      : in  std_logic;
      mon_n_int    : in  std_logic;
      mon_sdo      : in  std_logic;
      pll_status   : in  std_logic;
      prsnt_m2c_l  : in  std_logic;
      adc_n_en     : out std_logic;
      adc_reset    : out std_logic;
      cdce_n_en    : out std_logic;
      cdce_n_pd    : out std_logic;
      cdce_n_reset : out std_logic;
      dac_data_n   : out std_logic_vector (7 downto 0);
      dac_data_p   : out std_logic_vector (7 downto 0);
      dac_dclk_n   : out std_logic;
      dac_dclk_p   : out std_logic;
      dac_frame_n  : out std_logic;
      dac_frame_p  : out std_logic;
      dac_n_en     : out std_logic;
      mon_n_en     : out std_logic;
      mon_n_reset  : out std_logic;
      ref_en       : out std_logic;
      spi_sclk     : out std_logic;
      spi_sdata    : out std_logic;
      txenable     : out std_logic;

      p_INIT_DONE : out std_logic;

      p_ADC_OUT_CLK : out std_logic;
      p_ADC_OUT_A   : out std_logic_vector(15 downto 0);
      p_ADC_OUT_B   : out std_logic_vector(15 downto 0);

      p_DAC_OUT_CLK : out std_logic;
      p_DAC_IN_A    : in std_logic_vector(15 downto 0);
      p_DAC_IN_B    : in std_logic_vector(15 downto 0)
      );
  end component FMC150_sample;
  
end fmc150_components;
