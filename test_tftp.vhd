entity test_rx is
  
  port (
    clk, reset_n, dv_in, er : in std_logic;
    conf : in tftp_conf;
    rxd : in std_logic_vector(7 downto 0);
    en, er_o : out std_logic;
    txd : out std_logic_vector(7 downto 0)
    );

end test_rx;

architecture test_rx of test_rx is

  component rx
    port (
      clk, reset_n : in  std_logic;
      conf         : in  tftp_conf;
      dv, er       : in  std_logic;
      rxd          : in  std_logic_vector(7 downto 0);
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
      en, er       : out std_logic;
      data         : out std_logic_vector(7 downto 0));
  end component;
  
begin  -- test_rx

  rx_1: rx
    port map (
      clk         => clk,
      reset_n     => reset_n,
      conf        => conf,
      dv          => dv_in,
      er          => er_in,
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
      en          => en,
      er          => er_o,
      data        => txd);
  
end test_rx;
