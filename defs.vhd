library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package defs is

  type tftp_conf is record
    macaddr  : std_logic_vector(47 downto 0);
    ipv4addr : std_logic_vector(31 downto 0);
  end record;

  type ethernet_datapath_interface is record
    data    : std_logic_vector(7 downto 0);
    sof_n   : std_logic;
    eof_n   : std_logic;
    valid_n : std_logic;
    ready_n : std_logic;
  end record;

  --REMEMBER: these are named for the rx stage, in tx the names are backwards
  type tftp_opcode_t is record
    eth_src    : std_logic_vector(47 downto 0);
    ip_src     : std_logic_vector(31 downto 0);
    udp_src    : std_logic_vector(15 downto 0);
    tid        : std_logic_vector(15 downto 0);
    tftp_block : std_logic_vector(15 downto 0);
    block_len  : std_logic_vector(15 downto 0);
    ready_n : std_logic;
  end record;

  type arp_opcode_t is record
    header : std_logic_vector(63 downto 0);
    sha : std_logic_vector(47 downto 0);
    spa : std_logic_vector(31 downto 0);
    tha : std_logic_vector(47 downto 0);
    tpa : std_logic_vector(31 downto 0);
    ready_n : std_logic;
  end record;
  
  constant pre_data : std_logic_vector(63 downto 0) := x"5555_5555_5555_55d5";  
  constant ethertype_arp : std_logic_vector(15 downto 0) := x"0806";
  constant ETHERTYPE_IP : std_logic_vector(15 downto 0) := x"0800";

  constant IP_CONST_1 : std_logic_vector(15 downto 0) := x"4500";
  constant IP_CONST_2 : std_logic_vector(31 downto 0) := x"0000_3011";

  function next_fcs
    (data : std_logic_vector(7 downto 0);
     CRC  : std_logic_vector(31 downto 0))
    return std_logic_vector;

  function reverse_vector (a : in std_logic_vector)
    return std_logic_vector;

  

end defs;

package body defs is

    function reverse_vector (a : in std_logic_vector)
      return std_logic_vector is
    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'reverse_range) is a;
  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;
    return result;
  end;  -- function reverse_vector

  function next_fcs
    (data : std_logic_vector(7 downto 0);
     CRC  : std_logic_vector(31 downto 0))
    return std_logic_vector is

    variable D      : std_logic_vector(7 downto 0);
    variable C      : std_logic_vector(31 downto 0);
    variable NewCRC : std_logic_vector(31 downto 0);

  begin

    D := data;
    C := CRC;

    NewCRC(0) := D(6) xor D(0) xor C(24) xor C(30);
    NewCRC(1) := D(7) xor D(6) xor D(1) xor D(0) xor C(24) xor C(25) xor
                 C(30) xor C(31);
    NewCRC(2) := D(7) xor D(6) xor D(2) xor D(1) xor D(0) xor C(24) xor
                 C(25) xor C(26) xor C(30) xor C(31);
    NewCRC(3) := D(7) xor D(3) xor D(2) xor D(1) xor C(25) xor C(26) xor
                 C(27) xor C(31);
    NewCRC(4) := D(6) xor D(4) xor D(3) xor D(2) xor D(0) xor C(24) xor
                 C(26) xor C(27) xor C(28) xor C(30);
    NewCRC(5) := D(7) xor D(6) xor D(5) xor D(4) xor D(3) xor D(1) xor
                 D(0) xor C(24) xor C(25) xor C(27) xor C(28) xor C(29) xor
                 C(30) xor C(31);
    NewCRC(6) := D(7) xor D(6) xor D(5) xor D(4) xor D(2) xor D(1) xor
                 C(25) xor C(26) xor C(28) xor C(29) xor C(30) xor C(31);
    NewCRC(7) := D(7) xor D(5) xor D(3) xor D(2) xor D(0) xor C(24) xor
                 C(26) xor C(27) xor C(29) xor C(31);
    NewCRC(8) := D(4) xor D(3) xor D(1) xor D(0) xor C(0) xor C(24) xor
                 C(25) xor C(27) xor C(28);
    NewCRC(9) := D(5) xor D(4) xor D(2) xor D(1) xor C(1) xor C(25) xor
                 C(26) xor C(28) xor C(29);
    NewCRC(10) := D(5) xor D(3) xor D(2) xor D(0) xor C(2) xor C(24) xor
                  C(26) xor C(27) xor C(29);
    NewCRC(11) := D(4) xor D(3) xor D(1) xor D(0) xor C(3) xor C(24) xor
                  C(25) xor C(27) xor C(28);
    NewCRC(12) := D(6) xor D(5) xor D(4) xor D(2) xor D(1) xor D(0) xor
                  C(4) xor C(24) xor C(25) xor C(26) xor C(28) xor C(29) xor
                  C(30);
    NewCRC(13) := D(7) xor D(6) xor D(5) xor D(3) xor D(2) xor D(1) xor
                  C(5) xor C(25) xor C(26) xor C(27) xor C(29) xor C(30) xor
                  C(31);
    NewCRC(14) := D(7) xor D(6) xor D(4) xor D(3) xor D(2) xor C(6) xor
                  C(26) xor C(27) xor C(28) xor C(30) xor C(31);
    NewCRC(15) := D(7) xor D(5) xor D(4) xor D(3) xor C(7) xor C(27) xor
                  C(28) xor C(29) xor C(31);
    NewCRC(16) := D(5) xor D(4) xor D(0) xor C(8) xor C(24) xor C(28) xor
                  C(29);
    NewCRC(17) := D(6) xor D(5) xor D(1) xor C(9) xor C(25) xor C(29) xor
                  C(30);
    NewCRC(18) := D(7) xor D(6) xor D(2) xor C(10) xor C(26) xor C(30) xor
                  C(31);
    NewCRC(19) := D(7) xor D(3) xor C(11) xor C(27) xor C(31);
    NewCRC(20) := D(4) xor C(12) xor C(28);
    NewCRC(21) := D(5) xor C(13) xor C(29);
    NewCRC(22) := D(0) xor C(14) xor C(24);
    NewCRC(23) := D(6) xor D(1) xor D(0) xor C(15) xor C(24) xor C(25) xor
                  C(30);
    NewCRC(24) := D(7) xor D(2) xor D(1) xor C(16) xor C(25) xor C(26) xor
                  C(31);
    NewCRC(25) := D(3) xor D(2) xor C(17) xor C(26) xor C(27);
    NewCRC(26) := D(6) xor D(4) xor D(3) xor D(0) xor C(18) xor C(24) xor
                  C(27) xor C(28) xor C(30);
    NewCRC(27) := D(7) xor D(5) xor D(4) xor D(1) xor C(19) xor C(25) xor
                  C(28) xor C(29) xor C(31);
    NewCRC(28) := D(6) xor D(5) xor D(2) xor C(20) xor C(26) xor C(29) xor
                  C(30);
    NewCRC(29) := D(7) xor D(6) xor D(3) xor C(21) xor C(27) xor C(30) xor
                  C(31);
    NewCRC(30) := D(7) xor D(4) xor C(22) xor C(28) xor C(31);
    NewCRC(31) := D(5) xor C(23) xor C(29);

    return NewCRC;

  end next_fcs;

    
end defs;
