library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity tftp_server is

   port (
  clk, reset_n : in std_logic;
  conf : in tftp_conf;
  EX_STATE : out ntp_ex_states;
  GMII_TXD    : out std_logic_vector(7 downto 0);
  GMII_TX_EN  : out std_logic;
  GMII_TX_ER  : out std_logic;
  GMII_TX_CLK : out std_logic;
  GMII_RXD    : in  std_logic_vector(7 downto 0);
  GMII_RX_DV  : in  std_logic;
  GMII_RX_ER  : in  std_logic;
  GMII_RX_CLK : in  std_logic;
  MII_TX_CLK : in std_logic;
  GMII_COL   : in std_logic;
  GMII_CRS   : in std_logic;
  GMII_MDIO  : inout std_logic;
  GMII_MDC   : out   std_logic;
  GMII_INT   : in    std_logic;
  GMII_RESET : out   std_logic
    );

end tftp_server;

architecture rtl of tftp_server is

  signal GMII_MDC, GMII_RESET : std_logic;
  
  component rx
    port (
      clk, reset_n : in  std_logic;
      conf         : in  tftp_conf;
      dv, er       : in  std_logic;
      rxd          : in  std_logic_vector(7 downto 0);  --why is this not in or
                                                        --out?
      arp_opcode   : out arp_opcode_t;
      tftp_opcode  : out tftp_opcode_t);
  end component;

  signal arp_opcode : arp_opcode_t;
  signal tftp_opcode : tftp_opcode_t;
  
  component tx
    port (
      clk, reset_n : in  std_logic;
      conf         : in  tftp_conf;
      arp_opcode   : in  arp_opcode_t;
      tftp_opcode  : in  tftp_opcode_t;
      txd          : out ethernet_datapath_interface);
  end component;

  signal txd : ethernet_datapath_interface;
  
    component gmii_physical
    port (
      reset, clk     : in  std_logic;
      GMII_TXD       : out std_logic_vector(7 downto 0);
      GMII_TX_EN     : out std_logic;
      GMII_TX_ER     : out std_logic;
      GMII_TX_CLK    : out std_logic;
      GMII_RXD       : in  std_logic_vector(7 downto 0);
      GMII_RX_DV     : in  std_logic;
      GMII_RX_ER     : in  std_logic;
      GMII_RX_CLK    : in  std_logic;
      TXD_FROM_MAC   : in  std_logic_vector(7 downto 0);
      TX_EN_FROM_MAC : in  std_logic;
      TX_ER_FROM_MAC : in  std_logic;
      RXD_TO_MAC     : out std_logic_vector(7 downto 0);
      RX_DV_TO_MAC   : out std_logic;
      RX_ER_TO_MAC   : out std_logic);
  end component;


begin  -- rtl

  reset <= not reset_n;
  GMII_RESET <= reset_n;
  GMII_MDC <= '0';
  
  rx_1: rx
    port map (
      clk         => clk,
      reset_n     => reset_n,
      conf        => conf,
      dv          => dv,
      er          => er,
      rxd         => rxd,
      arp_opcode  => arp_opcode,
      tftp_opcode => tftp_opcode);

  tx_1: tx
    port map (
      clk         => clk,
      reset_n     => reset_n,
      conf        => conf,
      arp_opcode  => arp_opcode,
      tftp_opcode => tftp_opcode,
      txd         => txd);

  txd_en <= not txd.valid_n;

  gmii_physical_1: gmii_physical
    port map (
      reset          => reset,
      clk            => clk,
      GMII_TXD       => GMII_TXD,
      GMII_TX_EN     => GMII_TX_EN,
      GMII_TX_ER     => GMII_TX_ER,
      GMII_TX_CLK    => GMII_TX_CLK,
      GMII_RXD       => GMII_RXD,
      GMII_RX_DV     => GMII_RX_DV,
      GMII_RX_ER     => GMII_RX_ER,
      GMII_RX_CLK    => GMII_RX_CLK,
      TXD_FROM_MAC   => txd.data,
      TX_EN_FROM_MAC => txd_en,
      TX_ER_FROM_MAC => tx_er,
      RXD_TO_MAC     => rxd,
      RX_DV_TO_MAC   => rx_dv,
      RX_ER_TO_MAC   => rx_er);
  
end rtl;
