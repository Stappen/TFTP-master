library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.defs.all;


--so the preamble is already added to packets, possibly not the best idea, but
-- its what I did. So all this has to do is add any padding and the fcs.

entity eth_cs is
  
  port (
    clk, reset_n : in  std_logic;
    eth          : in  ethernet_datapath_interface;
    data         : out std_logic_vector(7 downto 0);
    en, er       : out std_logic);

end eth_cs;

architecture rtl of eth_cs is

  type states is (IDLE, PREAMBLE, PAYLOAD, FCS, IFG, PAD);
  signal state, next_state : states;

  signal eth_pause, eth_r : ethernet_datapath_interface;
  signal curfcs, curfcs_r : std_logic_vector(31 downto 0);
  signal cnt    : std_logic_vector(7 downto 0);

begin  -- rtl


  p_eth_reg : process (clk)
  begin
    if clk'event and clk='1' then
      eth_pause.data <= eth.data;
      eth_pause.sof_n <= eth.sof_n;
      eth_pause.eof_n <= eth.eof_n;
      eth_pause.valid_n <= eth.valid_n;
      eth_r.data <= eth_pause.data;
      eth_r.sof_n <= eth_pause.sof_n;
      eth_r.eof_n <= eth_pause.eof_n;
      eth_r.valid_n <= eth_pause.valid_n;
      
    end if;
  end process p_eth_reg;

  -- purpose: finds the frame checksum
  -- type   : sequential
  -- inputs : clk, reset_n, state
  -- outputs: curfcs
  p_fcs: process (clk, reset_n)
  begin  -- process p_fcs
    if reset_n = '1' then               -- asynchronous reset (active low)
      curfcs <= (others => '1');
      curfcs_r <= (others => '0');   -- not sure?
    elsif clk'event and clk = '1' then  -- rising clock edge
      case state is
        when IDLE => curfcs <= (others => '1');
        when PREAMBLE => curfcs <= (others => '1');
        when PAYLOAD => curfcs <= next_fcs(reverse_vector(eth_r.data), curfcs);
        when PAD => curfcs <= next_fcs(x"00", curfcs);
        when FCS => curfcs <= curfcs(23 downto 0) & curfcs(31 downto 24);
        when others => null;
      end case;

      curfcs_r <= curfcs;
    end if;
  end process p_fcs;

  -- purpose: adds checksum and pad to ethernet frame
  -- type   : combinational
  -- inputs : state, eth, curfcs
  -- outputs: data
  p_dataout: process (state, eth_r, curfcs_r)
  begin  -- process p_dataout
    data <= x"00";
    en <= '0';
    er <= '0';

    case state is
      when PAYLOAD => data <= eth_r.data; en <= '1';
      when PREAMBLE => data <= eth_r.data; en <= '1';
      when FCS => data <= not reverse_vector(curfcs(31 downto 24)); en <= '1';
      when PAD => data <= (others => '0'); en <= '1';
      when IFG => data <= (others => '0'); en <= '1';
      when others => null;
    end case;
  end process p_dataout;

--increment counter..
  p_counter : process (clk, reset_n)
  begin
    if reset_n = '0' then
      cnt <= (others => '0');
    elsif clk'event and clk = '1' then
      cnt <= std_logic_vector(unsigned(cnt) + to_unsigned(1, 8));
      if state /= next_state then
        cnt <= (others => '0');
      end if;
    end if;
  end process p_counter;

  
  p_next_state : process (state, eth, cnt)
  begin

    next_state <= state;

    case state is
      when IDLE =>
        if eth.valid_n = '0' then
          next_state <= PREAMBLE;
        end if;

      when PREAMBLE =>
        if cnt = X"07" then
          next_state <= PAYLOAD;
        end if;

      -- padding to 59 bytes.. 
      when PAYLOAD =>
        if eth_r.eof_n = '0' and
          cnt < std_logic_vector(to_unsigned(59, 8)) then
          next_state <= PAD;
        elsif eth_r.eof_n = '0' then
          next_state <= FCS;
        end if;

    when PAD =>
        if cnt < std_logic_vector(to_unsigned(59, 8)) then
          next_state <= PAD;
        else
          next_state <= FCS;
        end if;

      when FCS =>
        if cnt = X"03" then
          next_state <= IFG;
        end if;

      when IFG =>
        if cnt = X"0A" then
          next_state <= IDLE;
        end if;

      when others => null;
    end case;
  end process p_next_state;

end rtl;
