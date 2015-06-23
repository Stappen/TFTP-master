--                                    
--                              COPYRIGHT                             
--  
--  High-throughput NTP server 
--  Copyright (c) 2009, The University of Waikato, New Zealand
--  Copyright (c) 2009, Anthony M. Blake <amb@anthonix.com>
--  All rights reserved.
--  
--  Author: Anthony M. Blake (amb@anthonix.com) - 2009
--          Mark Will (mark.will@outlook.com)   - 2012
--
--  Redistribution and use in source and binary forms, with or without
--  modification, are permitted provided that the following conditions are met:
--      * Redistributions of source code must retain the above copyright
--        notice, this list of conditions and the following disclaimer.
--      * Redistributions in binary form must reproduce the above copyright
--        notice, this list of conditions and the following disclaimer in the
--        documentation and/or other materials provided with the distribution.
--      * Neither the name of the organization nor the
--        names of its contributors may be used to endorse or promote products
--        derived from this software without specific prior written permission.
--  
--  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--  DISCLAIMED. IN NO EVENT SHALL THE UNIVERSITY OF WAIKATO BE LIABLE FOR ANY
--  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;
entity ethernet is

  port (
    clk, reset_n : in std_logic;

    conf : in tftp_conf;

    rxd    : in std_logic_vector(7 downto 0);
    dv, er : in std_logic;

    eth       : out ethernet_datapath_interface;
    goodframe : out std_logic;

    eth_src : out std_logic_vector(47 downto 0)

    );

 
end ethernet;



architecture rtl of ethernet is

  type   states is (IDLE, PREAMBLE, IFD, DEST, SRC, PAYLOAD, IFG);
  signal next_state, state : states;

  signal counter : std_logic_vector(3 downto 0);

  signal broadcast, station, checksum : std_logic;
  signal macr                         : std_logic_vector(47 downto 0);

  signal curfcs : std_logic_vector(31 downto 0);
  signal eth_src_r : std_logic_vector(47 downto 0);

  signal eth0, eth1, eth2, eth3, eth4, eth5 : ethernet_datapath_interface;
  
begin  -- rtl

  goodframe <= (broadcast or station) and checksum;

  eth.data    <= eth5.data;
  eth.sof_n   <= eth5.sof_n;
  eth.eof_n   <= eth0.eof_n;
  eth.valid_n <= eth0.valid_n or eth5.valid_n;

  eth_src <= eth_src_r;

  FSM : process (clk, reset_n)
  begin
    if reset_n = '0' then
      state   <= IDLE;
      counter <= (others => '0');

      checksum  <= '0';
      station   <= '0';
      broadcast <= '0';
      macr      <= conf.macaddr;

      curfcs <= (others => '1');

      eth0.data    <= (others => '0');
      eth0.sof_n   <= '1';
      eth0.eof_n   <= '1';
      eth0.valid_n <= '1';
      
		eth5.sof_n	 <= '1';

      eth_src_r <= (others => '0');
		
    elsif clk'event and clk = '1' then
      state <= next_state;

      eth0.data <= rxd;

      if state /= next_state or state = IDLE then
        counter <= X"1";
      else
        counter <= counter + 1;
      end if;

      if state = PREAMBLE then
        broadcast <= '1';
      elsif state = DEST and rxd /= X"FF" then
        broadcast <= '0';
      end if;

      if state = IDLE then
        macr <= conf.macaddr;
      elsif state = DEST then
        macr <= macr(39 downto 0) & macr(47 downto 40);
      end if;

      if state = SRC then
        eth_src_r <= eth_src_r(39 downto 0) & rxd;
      end if;

      if state = PREAMBLE then
        station <= '1';
      elsif state = DEST and rxd /= macr(47 downto 40) then
        station <= '0';
      end if;

      if state = IDLE or state = PREAMBLE or state = IFD then
        curfcs <= (others => '1');
      else
        curfcs <= next_fcs(reverse_vector(rxd), curfcs);
		  --curfcs <= reverse_vector(rxd & rxd & rxd & rxd);
      end if;

      if state = PREAMBLE then
        checksum <= '0';
      elsif state = PAYLOAD and dv = '0' and er = '0' then
        if curfcs = X"C704DD7B" then
          checksum <= '1';
        else
          checksum <= '0';
        end if;

      end if;

      if state = PAYLOAD and dv = '0' and er = '0' then
        eth0.eof_n <= '0';
      else
        eth0.eof_n <= '1';
      end if;

      if state = DEST and counter = X"1" then
        eth0.sof_n <= '0';
      else
        eth0.sof_n <= '1';
      end if;

      if state = PAYLOAD or state = DEST or state = SRC then
        eth0.valid_n <= '0';
      else
        eth0.valid_n <= '1';
      end if;

      eth1 <= eth0;
      eth2 <= eth1;
      eth3 <= eth2;
      eth4 <= eth3;
      eth5 <= eth4;
      
    end if;
  end process FSM;

  p_next_state : process (state, rxd, er, dv, counter)
  begin  -- process p_next_state
	next_state <= state;
    case state is
      when IDLE => if dv = '1' and er = '0' and rxd = X"55" then
                     next_state <= PREAMBLE;
                   end if;

      when PREAMBLE => if dv = '1' and er = '0' and rxd = X"55" and counter = X"6" then
                         next_state <= IFD;
                       elsif dv = '1' and er = '0' and rxd = X"55" then
                         next_state <= PREAMBLE;
                       else
                         next_state <= IDLE;
                       end if;
                       
      when IFD => if dv = '1' and er = '0' and rxd = X"D5" then
                    next_state <= DEST;
                  else
                    next_state <= IDLE;
                  end if;

      when DEST => if dv = '1' and er = '0' and counter = X"6" then
                     next_state <= SRC;
                   elsif dv = '1' and er = '0' then
                     next_state <= DEST;
                   else
                     next_state <= IDLE;
                   end if;

      when SRC => if dv = '1' and er = '0' and counter = x"6" then
                    next_state <= PAYLOAD;
                  elsif dv = '1' and er = '0' then
                    next_state <= SRC;
                  else
                    next_state <= IDLE;
                  end if;
                   
      when PAYLOAD => if dv = '0' and er = '0' then
                        next_state <= IDLE;
                      end if;
                      

      when others => null;
    end case;
    
  end process p_next_state;
  

end rtl;
