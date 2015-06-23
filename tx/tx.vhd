library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity tx is

  port (
    clk, reset_n : in std_logic;
    conf         : in tftp_conf;
    arp_opcode   : in arp_opcode_t;
    tftp_opcode  : in tftp_opcode_t;
    en, er       : out std_logic;       -- er is pointless I think..
    data         : out std_logic_vector(7 downto 0));
end tx;

architecture rtl of tx is
	
	
	component mem_access(
	clk, reset, queue_ready : in std_logic;
	 queue_data : in std_logic_vector(31 downto 0);
	 read_request : in std_logic; -- High when you want data from memory
    read_queue_ready, dr, dv : out std_logic;
    data: out std_logic_vector;
    );

	component OPCODEFIFO 
		port (
		s_aclk, s_aresetn, s_axis_tvalid : in std_logic;
		s_axis_tready : out std_logic;
		s_axis_tdata : in std_logic_vector(255 downto 0);
      m_axis_tvalid : out std_logic;
      m_axis_tready : in std_logic;
		m_axis_tdata : out std_logic_vector(255 downto 0);
		);
	end component;
	
	component ADDRESSFIFO 
		port (
		s_aclk, s_aresetn, s_axis_tvalid : in std_logic;
		s_axis_tready : out std_logic;
		s_axis_tdata : in std_logic_vector(32 downto 0);
      m_axis_tvalid : out std_logic;
      m_axis_tready : in std_logic;
		m_axis_tdata : out std_logic_vector(32 downto 0);
		);
	end component;
	
	component mem_access(
		clk, reset, queue_ready : in std_logic;
		queue_data : in std_logic_vector(31 downto 0);
		read_request : in std_logic; -- High when you want data from memory
		read_queue_ready, dr, dv : out std_logic; 
		data : out std_logic_vector(7 downto 0);
    );
	
  component tftp_assembler
    port (
      clk, reset_n  : in  std_logic;
      conf          : in  tftp_conf;
      mem_ready, dv : in  std_logic;
      opcode        : in  tftp_opcode_t;
      mem_data      : in  std_logic_vector(7 downto 0);
      en            : in  std_logic;
      mem_en        : out std_logic;
      ready         : out std_logic;
      eth_out       : out ethernet_datapath_interface);
  end component;

  signal mem_data : std_logic_vector(7 downto 0);
  signal mem_ready, mem_dv, tftp_en, tftp_ready : std_logic;
  signal curr_tftp_op : tftp_opcode_t;
  signal tftp_data : ethernet_datapath_interface;

  component arp_assembler
    port (
      clk, reset_n : in  std_logic;
      conf         : in  tftp_conf;
      arp_opcode   : in  arp_opcode_t;
      en           : in  std_logic;
      ready        : out std_logic;
      eth_out      : out ethernet_datapath_interface);
  end component;

  signal curr_arp_op : arp_opcode_t;
  signal arp_en : std_logic;

  --component Scheduler
  --  port (
  --    clk, reset : in  std_logic;
  --    arpRdy, tftpRdy : in std_logic;
  --    arpEn      : out std_logic;
  --    ftpEn      : out std_logic;
  --    data       : out ethernet_datapath_interface);
--  end component;

  signal eth_out : ethernet_datapath_interface;
	signal tftp_queue_write, addr_queue_write, tftp_queue_read, tftp_assert_read, addr_queue_read, addr_assert_read : std_logic;
	signal tftp_op_out : tftp_opcode_t;
	signal addr_op_out : std_logic_vector(31 downto 0);
  component eth_cs
    port (
      clk, reset_n : in  std_logic;
      eth          : in  ethernet_datapath_interface;
      data         : out std_logic_vector(7 downto 0);
      en, er       : out std_logic);
  end component;
  
begin

	OPCODEFIFO: tftp_queue 
		port map (
		s_aclk => clk,
		s_aresetn => reset_n,
		s_axis_tvalid => tftp_opcode.ready_n,
		s_axis_tready => tftp_queue_write,
		s_axis_tdata => tftp_opcode,
      m_axis_tvalid => tftp_queue_read,
      m_axis_tready => tftp_assert_read,
		m_axis_tdata => tftp_op_out
		);
	end component;
	
	ADDRFIFO: memaddr_queue
		port map (
			s_aclk => clk,
			s_aresetn => reset_n,
			s_axis_tvalid => tftp_tftp_opcode.ready_n,
			s_axis_tready => addr_queue_write,
			s_axis_tdata => tftp_opcode.tftp_block & tfto_cpcode.block_len,
			m_axis_tvalid => addr_queue_read,
			m_axis_tready => addr_assert_read,
			m_axis_tdata => addr_op_out
		);
	end component;

  tftp_assembler_1: tftp_assembler
    port map (
      clk       => clk,
      reset_n   => reset_n,
      conf      => conf,
      mem_ready => mem_ready,
      dv        => mem_dv,
      opcode    => curr_tftp_op,
      mem_data  => mem_data,
      en        => tftp_en,
      mem_en    => mem_en,
      ready     => tftp_ready,
      eth_out   => tftp_data);

  arp_assembler_1: arp_assembler
    port map (
      clk        => clk,
      reset_n    => reset_n,
      conf       => conf,
      arp_opcode => arp_opcode,
      en         => arp_en,
      ready      => arp_ready,
      eth_out    => arp_data);
  
  	mem_access_1: mem_access (
		clk => clk, 
		reset => reset_n, 
		queue_ready =>  addr_queue_read, 
		--addr_assert_read
		queue_data => addr_op_out,
		read_request => mem_en, -- High when you want data from memory
		read_queue_ready => addr_assert_read,
		dr => mem_ready, 
		dv => mem_dv, 
		data => mem_data
    );
	

  --Scheduler_1: Scheduler
  --  port map (
  --    clk     => clk,
  --    reset   => reset,
  --   arpRdy  => arp_ready,
  --   tftpRdy => tftp_ready,
  --    arpData => arp_data,
  --    tftpData => tftp_data,
  --    arpEn   => arp_en,
  --    ftpEn   => tftp_en,
  --    data    => eth_out);

  eth_cs_1: eth_cs
    port map (
      clk     => clk,
      reset_n => reset_n,
      eth     => eth_out,
      data    => data,
      en      => en,
      er      => er);
  
  
end rtl;
