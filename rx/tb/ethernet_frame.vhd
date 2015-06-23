library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package ethernet_frame is

  type ETHERNET_FRAME is array (0 to 83) of std_logic_vector(7 downto 0);
  type ET is array (0 to 1) of std_logic_vector(7 downto 0);
  type MAC_ADDR is array (0 to 5) of std_logic_vector(7 downto 0);
  
  signal ef_eth_dest : MAC_ADDR := (x"1a", x"2a", x"3a", x"4a", x"5a", x"6a");
  signal ef_eth_src : MAC_ADDR := (x"1b", x"2b", x"3b", x"4b", x"5b", x"6b");
  signal ef_ethertype : ET := (x"08", x"00");

end ethernet_frame;
