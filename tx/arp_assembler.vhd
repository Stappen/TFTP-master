library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity arp_assembler is
  
  port (
    clk, reset_n : in  std_logic;
    
    conf : in tftp_conf;
    
    arp_opcode   : in  arp_opcode_t;

    en  : in  std_logic;
    ready : out std_logic;
    eth_out      : out ethernet_datapath_interface);

end arp_assembler;

architecture rtl of arp_assembler is

  constant arp_out_header : std_logic_vector(63 downto 0) := x"0001_0800_0604_0002";
    
  signal ready_r : std_logic;
  signal sending : std_logic;
  signal count : std_logic_vector(7 downto 0);

  signal arp_packet_r : std_logic_vector(399 downto 0);

begin  -- rtl

  ready <= ready_r;
  
-- purpose: outputs the contents of the packet register
-- type   : sequential
-- inputs : clk, reset_n, eth_out
-- outputs: eth_out
output: process (clk, reset_n)
begin  -- process output
  if reset_n = '0' then                 -- asynchronous reset (active low)
    sending <= '0';
    ready_r <= '0';
    
  elsif clk'event and clk = '1' then  -- rising clock edge

    if sending = '0' and arp_opcode.ready_n = '0' then
      arp_packet_r <= pre_data & arp_opcode.tha & conf.macaddr & ethertype_arp &
                arp_out_header & conf.macaddr & conf.ipv4addr & arp_opcode.tha &
                arp_opcode.tpa;
      ready_r <= '1';
    elsif sending = '1' then
      arp_packet_r <= arp_packet_r(391 downto 0) & arp_packet_r(399 downto 392);
      ready_r <= '0';
    end if;
    
    if sending = '0' and ready_r = '1' and en = '1' then
      sending <= '1';
      count <= x"00";
      
    elsif sending = '1' then

      if count = x"32" then
        sending <= '0';
      end if;

      if count = x"8" then
        eth_out.sof_n <= '0';
      else
        eth_out.sof_n <= '1';
      end if;

      if count = x"32" then
        eth_out.valid_n <= '1';
      else
        eth_out.valid_n <= '0';
      end if;

      if count = x"8" then
        eth_out.sof_n <= '0';
      else
        eth_out.sof_n <= '1';
      end if;

      if count = x"31" then
        eth_out.eof_n <= '0';
      else
        eth_out.eof_n <= '1';
      end if;

      count <= count + 1;

      eth_out.data <= arp_packet_r(399 downto 392);
    end if;
    
  end if;
end process output;
end rtl;
