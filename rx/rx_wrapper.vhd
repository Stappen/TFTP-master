----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:26:03 06/09/2013 
-- Design Name: 
-- Module Name:    rx_wrapper - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.defs.all;

entity rx_wrapper is
    Port ( clk : in  STD_LOGIC;
           reset_n : in  STD_LOGIC;
           macaddr : in  STD_LOGIC_VECTOR (47 downto 0);
           ipv4addr : in  STD_LOGIC_VECTOR (31 downto 0);
           dv : in  STD_LOGIC;
           er : in  STD_LOGIC;
           rxd : in  STD_LOGIC_VECTOR (7 downto 0);
			  eth_src : out std_logic_vector(47 downto 0);
			 ip_src : out std_logic_vector(31 downto 0);
				udp_src : out std_logic_vector(15 downto 0);
				tid : out std_logic_vector(15 downto 0);
				tftp_block : out std_logic_vector(15 downto 0);
				block_len : out std_logic_vector(15 downto 0);
				ready_n_tftp : out std_logic;
				header : out std_logic_vector(63 downto 0);
    sha : out std_logic_vector(47 downto 0);
    spa : out std_logic_vector(31 downto 0);
    tha : out std_logic_vector(47 downto 0);
    tpa : out std_logic_vector(31 downto 0);
    ready_n_arp : out std_logic
				);
end rx_wrapper;
  
architecture rtl of rx_wrapper is

component rx 
  port(
  clk, reset_n : in std_logic;
  conf : in tftp_conf;
  dv, er : in std_logic;
  rxd : std_logic_vector(7 downto 0);
  arp_opcode : out arp_opcode_t;

  tftp_opcode : out tftp_opcode_t  
  );
 end component;

 -- Signals to wrap
signal arp_opcode : arp_opcode_t;
signal tftp_opcode : tftp_opcode_t;
signal conf : tftp_conf;

begin

-- Assign TFTP record types
conf.macaddr <= macaddr;
conf.ipv4addr <= ipv4addr;
eth_src <= tftp_opcode.eth_src; 
ip_src <= tftp_opcode.ip_src;
udp_src <= tftp_opcode.udp_src;
tid <= tftp_opcode.tid;
tftp_block <= tftp_opcode.tftp_block;
block_len <= tftp_opcode.block_len;
ready_n_tftp <= tftp_opcode.ready_n;
header <= arp_opcode.header;
 sha <= arp_opcode.sha;
    spa <= arp_opcode.spa;
    tha <= arp_opcode.tha;
    tpa <= arp_opcode.tpa;
    ready_n_arp <= arp_opcode.ready_n;

rx1: rx 
	port map(
		clk        => clk,
      reset_n    => reset_n,
		dv => dv,
		er => er, 
		conf       => conf,
		rxd => rxd,
		arp_opcode => arp_opcode,
		tftp_opcode => tftp_opcode);


end rtl;

