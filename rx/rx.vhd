library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity rx is

  port(
  clk, reset_n : in std_logic;
  conf : in tftp_conf;

  dv, er : in std_logic;
  rxd : in  std_logic_vector(7 downto 0);

  arp_opcode : out arp_opcode_t;
  
  tftp_opcode : out tftp_opcode_t  
  );
  
end rx;

architecture rtl of rx is

 component ethernet
    port (
      clk, reset_n, dv, er : in  std_logic;
      conf               : in  tftp_conf;
      rxd                  : in  std_logic_vector(7 downto 0);
      goodframe            : out std_logic;
      eth                  : out ethernet_datapath_interface;
      eth_src              : out std_logic_vector(47 downto 0));
  end component;
    
  component arp
    port (
      clk, reset_n : in  std_logic;
      conf         : in  tftp_conf;
      cnt          : in  std_logic_vector(7 downto 0);
      eth_in       : in  ethernet_datapath_interface;
      arp_opcode   : out arp_opcode_t;
      valid        : out std_logic);
  end component;

  --taken from Anthony's NTP code
  --this has to be changed to use a tftp conf, not that there is a difference
  component ipv4_dec_module
    port (
      clk, reset_n : in  std_logic;
      conf         : in  tftp_conf;
      cnt          : in  std_logic_vector(7 downto 0);
      eth_in       : in  ethernet_datapath_interface;
      protocol     : out std_logic_vector(7 downto 0);
      src_ipaddr   : out std_logic_vector(31 downto 0);
      valid        : out std_logic);
  end component;

  --taken from Anthony's NTP code with conf removed, checks the checksum
  component udp_dec_module
    port (
      clk, reset_n : in  std_logic;
      cnt          : in  std_logic_vector(7 downto 0);
      eth          : in  ethernet_datapath_interface;
      ip_v     : in  std_logic;
      v        : out std_logic);
  end component;

  --this one just extracts the port numbers
  component udpport_decode
    port (
      clk                : in  std_logic;
      reset              : in  std_logic;
      eth_data, cnt      : in  std_logic_vector(7 downto 0);
      dst_port, src_port : out std_logic_vector(15 downto 0));
  end component;

  component tftp_decode
    port (
      clk, reset         : in  std_logic;
      cnt, eth_data      : in  std_logic_vector(7 downto 0);
      udp_dst            : in  std_logic_vector(15 downto 0);
      valid              : out std_logic;
      tid, next_block_no : out std_logic_vector(15 downto 0);
      length             : out std_logic_vector(15 downto 0));
  end component;

  signal reset : std_logic;
  signal cnt : std_logic_vector(7 downto 0);
  signal tftp_opcode_r : tftp_opcode_t;
  signal arp_opcode_r : arp_opcode_t;
  
  -- ethernet outputs
  signal eth_in : ethernet_datapath_interface;
  signal goodframe : std_logic;
  signal eth_src : std_logic_vector(47 downto 0);

  -- arp outputs
  signal arp_v : std_logic;
  
  -- ip outputs
  signal proto : std_logic_vector(7 downto 0);
  signal ip_src : std_logic_vector(31 downto 0);
  signal ip_v : std_logic;
 
  -- udp outputs
  signal udp_src, udp_dst : std_logic_vector(15 downto 0);
  signal udp_v : std_logic;

  -- tftp outputs
  signal tftp_v : std_logic;
  signal tid, next_block_no : std_logic_vector(15 downto 0);
  signal length : std_logic_vector(15 downto 0);
  signal tftp_reset : std_logic;
  
    begin                                 --rtl

    reset <= not reset_n;
    tftp_reset <= reset or not eth_in.sof_n;

    tftp_opcode <= tftp_opcode_r;
    arp_opcode <= arp_opcode_r;
    
    -- ethernet
    ethernet_1: ethernet
      port map (
        clk       => clk,
        reset_n   => reset_n,
        dv        => dv,
        er        => er,
        conf    => conf,
        rxd       => rxd,
        goodframe => goodframe,
		  eth => eth_in,
        eth_src   => eth_src);

    -- arpmodule
    arp_1: arp
      port map (
        clk        => clk,
        reset_n    => reset_n,
        conf       => conf,
        cnt        => cnt,
        eth_in     => eth_in,
        arp_opcode => arp_opcode_r,
        valid =>  arp_v);
    
  ip_module_1 : ipv4_dec_module
    port map (
      clk        => clk,
      reset_n    => reset_n,
      conf       => conf,
      cnt        => cnt,
      eth_in     => eth_in,
      protocol   => proto,
      src_ipaddr => ip_src,
      valid      => ip_v);

   udp_module_1 : udp_dec_module
    port map (
      clk      => clk,
      reset_n  => reset_n,
      cnt      => cnt,
      eth      => eth_in,
      ip_v => ip_v,
      v    => udp_v);

  udp_module_2 : udpport_decode
    port map (
      clk => clk,
      reset =>  reset,
      eth_data => eth_in.data,
      cnt => cnt,
      dst_port => udp_dst,
      src_port => udp_src);

    -- tftp
  tftp : tftp_decode
    port map (
      clk => clk,
      reset => tftp_reset,
      cnt => cnt,
      eth_data => eth_in.data,
      udp_dst => udp_dst,
      tid => tid,
      next_block_no => next_block_no,
      length => length,
      valid => tftp_v);

    -- purpose: data byte counter
    -- type   : combinational
    -- inputs : clk, reset_n
    -- outputs: count
    p_count: process (clk, reset_n)
    begin  -- process p_count
      if reset_n = '0' then
        cnt <= (others => '0');
      elsif clk'event and clk = '1' then
        if eth_in.sof_n = '0' then
        cnt <= X"00";
        elsif eth_in.valid_n = '0' then
          cnt <= cnt + 1;
        end if;
      end if;
    end process p_count;

    -- figure out a way so this doesnt get added to the queue several times in
    -- a row until the _vs reset
    -- purpose: update the opcode regs
    -- type   : combinational
    -- inputs : clk, reset_n
    -- outputs: tftp_opcode_r
    opcodereg: process (clk, reset_n)
    begin  -- process opcode reg
      if reset_n = '0' then
        tftp_opcode_r.ready_n <= '0';
        arp_opcode_r.ready_n <= '0';
      elsif clk'event and clk = '1' then
        tftp_opcode_r.eth_src <= eth_src;
        tftp_opcode_r.ip_src <= ip_src;
        tftp_opcode_r.udp_src <= udp_src;
        tftp_opcode_r.tid <= tid;
        tftp_opcode_r.tftp_block <= next_block_no;
        tftp_opcode_r.block_len <= length;
        
        --goodframe is only active once fcs is confirmed, so this is fine
        if goodframe = '1' and ip_v = '1'
          and udp_v = '1' and tftp_v = '1' then
          tftp_opcode_r.ready_n <= '1';
        else
          tftp_opcode_r.ready_n <= '0';
        end if;

       -- if goodframe = '1' and arp_v = '1' then
        --  arp_opcode_r.ready_n <= '1';
        --else
        --  arp_opcode_r.ready_n <= '0';
        --end if;
      end if;
    end process opcodereg;
    
end rtl;
