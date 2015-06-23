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

use work.defs.all;

entity ipv4_dec_module is
  port (
    clk, reset_n : in std_logic;

    conf : in tftp_conf;
    
    cnt    : in std_logic_vector(7 downto 0);
    eth_in : in ethernet_datapath_interface;

    protocol   : out std_logic_vector(7 downto 0);
    src_ipaddr : out std_logic_vector(31 downto 0);
    valid      : out std_logic

    );

end ipv4_dec_module;

architecture rtl of ipv4_dec_module is

  component internet_checksum_8
    generic (
      init : std_logic_vector(15 downto 0));
    port (
      clk, reset_n, en : in  std_logic;
      din              : in  std_logic_vector(7 downto 0);
      dout             : out std_logic_vector(15 downto 0);
      check            : in  std_logic;
      valid            : out std_logic);
  end component;

  signal checksum, match : std_logic;

  signal data_int, cnt_int : std_logic_vector(7 downto 0);

  signal checksum_en, checksum_check : std_logic;

  type   states is (IDLE, T0, T1, S0, S1, S2, S3);
  signal state : states;

  type   checksum_states is (IDLE, CK, VLD);
  signal checksum_state : checksum_states;

  signal proto_int : std_logic_vector(7 downto 0);
  signal src_addr_int : std_logic_vector(31 downto 0);

  signal ip_int : std_logic_vector(31 downto 0);
  
begin

  REGS : process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_int <= (others => '0');
      cnt_int  <= (others => '0');
      proto_int <= (others => '0');
      src_addr_int <= (others => '0');
    elsif clk'event and clk = '1' then
      if eth_in.valid_n = '0' then
        data_int <= eth_in.data;
        cnt_int  <= cnt;
      end if;

      -- get the protocol
      if cnt_int=X"16" then
        proto_int <= data_int;
      end if;

      -- get src ip
      if cnt_int=X"19" or cnt_int=X"1A" or cnt_int=X"1B" or cnt_int=X"1C" then
        src_addr_int <= src_addr_int(23 downto 0) & data_int;
      end if;     
      
    end if;
  end process REGS;

  CHECKSUMLOGIC : process (clk, reset_n)
  begin
    if reset_n = '0' then
      checksum_state <= IDLE;
    elsif clk'event and clk = '1' then
      if checksum_state = VLD then
        checksum_state <= IDLE;
      elsif cnt_int = X"00" then
        checksum_state <= IDLE;
      elsif cnt_int = X"0C" then
        checksum_state <= CK;
      elsif cnt_int = X"20" then
        checksum_state <= VLD;
      end if;
    end if;
  end process CHECKSUMLOGIC;
  
  MATCHLOGIC : process (clk, reset_n)
  begin
    if reset_n = '0' then
      state <= IDLE;
      ip_int <= conf.ipv4addr;
    elsif clk'event and clk = '1' then

      ip_int <= conf.ipv4addr;
      
      if cnt_int = X"00" then
        state <= IDLE;
      else

        -- ethertype first?
        -- count int?
        if state = IDLE and cnt_int = X"0B" and data_int = X"08" then
          state <= T0;
        elsif state = T0 then
          if data_int = X"00" then
            state <= T1;
          else
            state <= IDLE;
          end if;
        -- ok ethertype done next is vers and hl
        -- check the ip addr
        elsif state = T1 and cnt_int = X"1D" then 
          if data_int = ip_int(31 downto 24) then
            state <= S0;
            ip_int <= ip_int(23 downto 0) & ip_int(31 downto 24);
          else
            state <= IDLE;
          end if;
        elsif state = S0 then
          if data_int = ip_int(31 downto 24) then
            ip_int <= ip_int(23 downto 0) & ip_int(31 downto 24);
            state <= S1;
          else
            state <= IDLE;
          end if;
        elsif state = S1 then
          if data_int = ip_int(31 downto 24) then
            ip_int <= ip_int(23 downto 0) & ip_int(31 downto 24);
            state <= S2;
          else
            state <= IDLE;
          end if;
        elsif state = S2 then
          if data_int = ip_int(31 downto 24) then
            ip_int <= ip_int(23 downto 0) & ip_int(31 downto 24);
            state <= S3;
          else
            state <= IDLE;
          end if;
        elsif state = S3 then

        end if;
      end if;
      
    end if;
  end process MATCHLOGIC;

  with state select
    match <=
    '1' when S3,
    '0' when others;
  
  internet_checksum_8_1 : internet_checksum_8
    generic map (
      init => X"0000")
    port map (
      clk     => clk,
      reset_n => eth_in.sof_n,
      en      => checksum_en,
      din     => data_int,
      dout    => open,
      check   => checksum_check,
      valid   => checksum);

  with checksum_state select
    checksum_en <=
    '1' when CK,
    '0' when others;
  
  with checksum_state select
    checksum_check <=
    '1' when VLD,
    '0' when others;
  
  valid <= match and checksum;

  src_ipaddr <= src_addr_int;
  protocol <= proto_int;
  
end rtl;
