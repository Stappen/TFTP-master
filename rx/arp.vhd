library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity arp is
  
  port (
    clk, reset_n : in std_logic;
    
    conf         : in tftp_conf;
    
    cnt : in std_logic_vector(7 downto 0);
    eth_in       : in ethernet_datapath_interface;

    valid : out std_logic;
    arp_opcode : out arp_opcode_t
    );

end arp;

architecture rtl of arp is

  type states is (IDLE, HEADER, SHA, SPA, THA, TPA);
  signal state, next_state : states;
  
  constant header_data : std_logic_vector(79 downto 0) := x"0806_0001_0800_0604_0001";
  signal header_int : std_logic_vector(79 downto 0);
  signal ip_int : std_logic_vector(31 downto 0);

  signal arp_opcode_r : arp_opcode_t;

  signal data_int, cnt_int : std_logic_vector(7 downto 0);
  signal header_v, tpa_v : std_logic;
  
begin  -- rtl

  valid <= header_v and tpa_v;
  arp_opcode <= arp_opcode_r;

  -- purpose: updates fsm
  -- type   : combinational ..why does this always seem to say combinational?
  -- inputs : clk, reset_n
  -- outputs: eth_addr_r and _int, ip_r and _int
  fsm: process (clk, reset_n)
  begin  -- process REGS
    if reset_n = '0' then
      state <= IDLE;
    elsif clk'event and clk = '1' then

      state <= next_state;
      
      if STATE = HEADER then
        if data_int /= header_int(79 downto 72) then
          header_v <= '0';
        else
          header_v <= '1';
        end if;
      end if;
      
      if STATE = HEADER then
        tpa_v <= '1';
      elsif STATE = TPA and data_int /= ip_int(31 downto 24) then
          tpa_v <= '0';
      end if;

      if STATE = IDLE then
        header_int <= header_data;
      elsif STATE = HEADER then
        header_int <= header_int(71 downto 0) & header_int(79 downto 72);
      end if;

      if STATE = IDLE then
        ip_int <= conf.ipv4addr;
      elsif STATE = TPA then        
        ip_int <= ip_int(23 downto 0) & ip_int(31 downto 24);
      end if;
        
      if STATE = SHA then
        arp_opcode_r.tha <= arp_opcode_r.tha(39 downto 0) & data_int;
      end if;
        
      if state = SPA then
        arp_opcode_r.tpa <= arp_opcode_r.tpa(23 downto 0) & data_int;
      end if;

    end if;
  end process fsm;

  -- purpose: updates the fields in the arp packet
  -- type   : combinational
  -- inputs : state, data_int
  -- outputs: arp_packet
  updatepacket: process (state, cnt)
  begin  -- process update packet
    case next_state is
      when IDLE =>
        if cnt_int = x"0a" then
          next_state <= HEADER;
        end if;        
      when HEADER =>
        if header_v = '0' then
          next_state <= IDLE;
        elsif cnt = x"15" then
          next_state <= SHA;
        end if;               
      when SHA =>
        if cnt = x"1b" then
          next_state <= SPA;
        end if;
      when SPA =>
        if tpa_v = '0' or cnt = x"29" then
          next_state <= IDLE;        
        end if;
      when others => null;
    end case;
  end process updatepacket;
  
end rtl;
