library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity tftp_assembler is
  
  port (
    clk, reset_n : in  std_logic;
  
    conf         : in  tftp_conf;

    mem_ready, dv          : in  std_logic;
    opcode       : in  tftp_opcode_t;
    mem_data     : in  std_logic_vector(7 downto 0);

    en           : in  std_logic;

    mem_en       : out std_logic;
    
    ready        : out std_logic;
    eth_out      : out ethernet_datapath_interface);

end tftp_assembler;

architecture rtl of tftp_assembler is
  
  constant TFTP_DATA_OP : std_logic_vector(15 downto 0) := x"0003";

  type states is (IDLE, SND_ETH, SND_IP, SND_UDP, SND_PL);
  signal state, next_state : states;

  signal opcode_r : tftp_opcode_t;
  signal cs_start : std_logic;
  
  -- ethernet --
  signal ethernet_r : std_logic_vector(175 downto 0);

  -- ip --
  signal ip_r : std_logic_vector(159 downto 0);
  signal ip_id, ip_len : std_logic_vector(15 downto 0);
  signal ip_cs : std_logic_vector(15 downto 0);

  -- ip component
  component ip_cs_calc
    port (
      clk, reset_n, start : in  std_logic;
      ip_src, ip_dst   : in  std_logic_vector(31 downto 0);
      ip_len, ip_id    : in  std_logic_vector(15 downto 0);
      ip_cs            : out std_logic_vector(15 downto 0);
      ready            : out std_logic);
  end component;
  
  signal ip_ready : std_logic;
  
  -- udp --
  signal udp_r : std_logic_vector(95 downto 0);
  signal udp_len : std_logic_vector(15 downto 0);
  
  --udp component
  component udp_cs_calc
    port (
      clk, reset_n              : in  std_logic;
      ip_src, ip_dst            : in  std_logic_vector(31 downto 0);
      udp_len, udp_src, udp_dst : in  std_logic_vector(15 downto 0);
      tftp_block_no             : in  std_logic_vector(15 downto 0);
      mem_data                  : in  std_logic_vector(7 downto 0);
      start                     : in  std_logic;
      udp_cs                    : out std_logic_vector(15 downto 0);
      ready                     : out std_logic);
  end component;

  signal udp_ready : std_logic;
  signal udp_cs : std_logic_vector(15 downto 0);

  -- payload --
  signal pl_count : std_logic_vector(15 downto 0);
  signal payload_r : std_logic_vector(4095 downto 0);
  signal next_pl : std_logic_vector(7 downto 0);
  signal pl_move, pl_full, pl_start : std_logic;
  signal pl_length : std_logic_vector(15 downto 0);

  --output
  signal ready_r : std_logic;
  signal out_count : std_logic_vector(15 downto 0);

begin  -- rtl
-------------------------------------------------------------------------------
-- Payload
-------------------------------------------------------------------------------  
 
  -- Payload r is where payload data is stored as I calculate checksums.
  -- Packets are
  -- pushed in byte by byte at one end and read out byte by byte at the other.
  -- meanwhile checksums are calculated.
  -- A series of small packets will cause this to run at less than line rate,
  -- but the nature of tftp suggests that shouldnt be a major issue.

  -- purpose: input to payload_r
  -- type   : combinational
  -- inputs : dv, mem_data
  -- outputs: next_pl
  next_pl_p: process (dv, mem_data)
  begin  -- process next_pl_p
    if dv = '1' then
      next_pl <= mem_data;
    else
      next_pl <= x"00";
    end if;
  end process next_pl_p;

  -- purpose: updates the payload register
  -- type   : sequential
  -- inputs : clk, reset_n, mem_data, state
  -- outputs: payload_r
  payload_update: process (clk, reset_n)
  begin  -- process payload_update
    if reset_n = '0' then               -- asynchronous reset (active low)
      pl_count <= x"0001";
      pl_move <= '0';
      pl_full <= '0';
      pl_start <= '0';
      cs_start <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      
      --shift when sending or not full
      if state = SND_PL or pl_move = '1' then
        payload_r <= next_pl & payload_r(4095 downto 8);        
      end if;

      if (state = SND_PL or state = IDLE) and pl_full = '0' and pl_move = '0'
         and mem_ready = '1' and pl_start <= '0' then
        pl_start <= '1';
      else
        pl_start <=  '0';
      end if;
      
      if (state = SND_PL or state = IDLE) and pl_full = '0' and pl_move = '0'
         and mem_ready = '1' then
        opcode_r <= opcode;
        opcode_r.ready_n <= '0';
      elsif state = SND_UDP then
        --this indicates the opcode is no longer relevant
        opcode_r.ready_n <= '1';    
      end if;

      if pl_start = '1' then
        mem_en <= '1';
      else
        mem_en <= '0';
      end if;

      if pl_start = '1' then      
        cs_start <= '1';
      else
        cs_start <= '0';
      end if;
      
      if pl_start = '1' then        
        pl_move <= '1';
      elsif pl_count = x"0200" or opcode_r.block_len = x"0000" then
        pl_move <= '0';
      end if;

      if pl_count = x"200" or opcode_r.block_len = x"0000" then
        pl_length <= opcode_r.block_len;
      end if;

      if state = SND_PL then
        pl_full <= '0';
      elsif pl_count = x"0200" or opcode_r.block_len = x"0000" then
        pl_full <= '1';
      end if;

      if pl_count = x"0200" or opcode_r.block_len = x"0000" then
        pl_count <= x"0001";
      elsif pl_move = '1' then
        pl_count <= pl_count + 1;
      end if;
    end if;
  end process payload_update;

-------------------------------------------------------------------------------
-- Ethernet
-------------------------------------------------------------------------------
  
  -- purpose: updates the ethernet register
  -- type   : sequential
  -- inputs : clk, reset_n, opcode_r, conf
  -- outputs: 
  update_ethernet: process (clk, reset_n)
  begin  -- process update_ethernet
    if reset_n = '0' then               -- asynchronous reset (active low)
    elsif clk'event and clk = '1' then  -- rising clock edge
      
      if state = SND_ETH then
        ethernet_r <= ethernet_r(167 downto 0) & ethernet_r(175 downto 168);
      else
        ethernet_r <= pre_data & opcode_r.eth_src & conf.macaddr & ethertype_ip;
      end if;
    end if;
  end process update_ethernet;

-------------------------------------------------------------------------------
-- IP 
-------------------------------------------------------------------------------

  ip_len <= opcode_r.block_len + 32;
            
  ip_cs_calc_1: ip_cs_calc
    port map (
      clk     => clk,
      reset_n => reset_n,
      start => cs_start,
      ip_src  => conf.ipv4addr,
      ip_dst  => opcode_r.ip_src,
      ip_len  => ip_len,
      ip_id   => ip_id,
      ip_cs   => ip_cs,
      ready   => ip_ready);
  
-- purpose: updates ip register
-- type   : sequential
-- inputs : clk, reset_n, ip_header
-- outputs: ip_r
update_ip: process (clk, reset_n)
begin  -- process update_ip
  if reset_n = '0' then         -- asynchronous reset (active low)
    ip_id <= x"abcd";                    -- arbitrary value
        
  elsif clk'event and clk = '1' then    -- rising clock edge
    
    if state = SND_IP then
      ip_r <= ip_r(151 downto 0) & ip_r(159 downto 152);
    else
      ip_r <= IP_CONST_1 & ip_len & ip_id & IP_CONST_2 & ip_cs & conf.ipv4addr
              & opcode_r.ip_src;
    end if;

    if state = SND_UDP and next_state /= SND_UDP then
      ip_id <= ip_id + 1;
    end if;
    
  end if;
end process update_ip;

-------------------------------------------------------------------------------
-- UDP
-------------------------------------------------------------------------------

udp_len <= opcode_r.block_len + 12;

udp_cs_calc_1: udp_cs_calc
  port map (
    clk           => clk,
    reset_n       => reset_n,
    ip_src        => conf.ipv4addr,
    ip_dst        => opcode_r.ip_src,
    udp_len       => udp_len,
    udp_src       => opcode_r.tid,
    udp_dst       => opcode_r.udp_src,
    tftp_block_no => opcode_r.tftp_block,
    mem_data      => mem_data,
    start         => cs_start,
    udp_cs        => udp_cs,
    ready         => udp_ready);

-- purpose: updates udp_r (contains udp and tftp headers)
-- type   : sequential
-- inputs : clk, reset_n, udp_header
-- outputs: udp_r
update_udp: process (clk, reset_n)
begin  -- process update_udp
  if reset_n = '0' then                 -- asynchronous reset (active low)
  elsif clk'event and clk = '1' then    -- rising clock edge
    if state = SND_UDP then
      udp_r <= udp_r(87 downto 0) & udp_r(95 downto 88);
    else
      udp_r <= opcode_r.tid & opcode_r.udp_src & udp_len & udp_cs & TFTP_DATA_OP
               & opcode_r.tftp_block;
    end if;    
  end if;
end process update_udp;

-------------------------------------------------------------------------------
--Output
-------------------------------------------------------------------------------


  -- purpose: ready or not
  -- type   : combinational
  -- inputs : udp_ready, ip_ready, pl_full, pl_count
  -- outputs: ready_r (and as a consequence ready
readiness: process (udp_ready, ip_ready, pl_count, pl_full, opcode_r)
  begin  -- process readiness
      if udp_ready = '1' and ip_ready = '1' and opcode_r.ready_n = '0' and
        ((pl_full = '1') or (pl_count > x"1c8")) then
        ready_r <= '1';
      else
        ready_r <= '0';
      end if;
  end process readiness;
  
  ready <= ready_r;
  
-- purpose: outputs packets
-- type   : sequential
-- inputs : clk, reset_n, header and payload registers
-- outputs: eth_out
output_FSM: process (clk, reset_n)
begin  -- process output
  if reset_n = '0' then                 -- asynchronous reset (active low)
    eth_out.sof_n <= '1';
    eth_out.eof_n <= '1';
    eth_out.valid_n <= '1';
    eth_out.ready_n <= '1';
    out_count <= x"0001";
  elsif clk'event and clk = '1' then    -- rising clock edge
    
    if state = SND_ETH then
      eth_out.data <= ethernet_r(175 downto 168);
    elsif state = SND_IP then
      eth_out.data <= ip_r(159 downto 152);
    elsif state = SND_UDP then
      eth_out.data <= udp_r(95 downto 88);
    elsif state = SND_PL then
      eth_out.data <= payload_r(7 downto 0);
    end if;

    if state = SND_ETH and out_count = x"009" then
      eth_out.sof_n <= '0';
    else
      eth_out.sof_n <= '1';
    end if;

    if (state = SND_PL and out_count = pl_length) or
       (state = SND_UDP and out_count = x"00c" and pl_length = x"0000") then
      eth_out.eof_n <= '0';
    else
      eth_out.eof_n <= '1';
    end if;

    if state = SND_ETH then
      eth_out.valid_n <= '0';
    elsif state = IDLE or (state = SND_PL and pl_length = x"0000") then
      eth_out.valid_n <= '1';
    end if;

    if state /= next_state then
      out_count <= x"0001";
    else
      out_count <= out_count + 1;
    end if;
    
    state <= next_state;
  end if;
end process output_FSM;

find_next_state: process (clk, reset_n) 
begin
  if reset_n = '0' then
  elsif clk'event and clk = '0' then    -- lower edge
    case state is
      when IDLE =>
        if en = '1' and ready_r = '1' then
          next_state <= SND_ETH;
        else
          next_state <= IDLE;
        end if;   
      when SND_ETH =>
        if out_count = x"016" then
          next_state <= SND_IP;
        else
          next_state <= SND_ETH;
        end if;
      when SND_IP =>
        if out_count = x"014" then
          next_state <= SND_UDP;
        else
          next_state <= SND_IP;
        end if;
      when SND_UDP =>
        if out_count = x"00c" then
          next_state <= SND_PL;
        else
          next_state <= SND_UDP;
        end if;
      when SND_PL =>
        if out_count >= pl_length then
          next_state <= IDLE;
        else
          next_state <= SND_PL;
        end if;
      when others => null;
    end case;
  end if;
end process find_next_state;
end rtl;
