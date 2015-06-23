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
use work.defs.all;

entity udp_dec_module is
  port (
    clk, reset_n : in std_logic;
    
    cnt      : in std_logic_vector(7 downto 0);
    eth      : in ethernet_datapath_interface;
	 ip_v     : in  std_logic;
    v        : out std_logic

    );

end udp_dec_module;

architecture rtl of udp_dec_module is
  component internet_checksum_16
    generic (
      init : std_logic_vector(15 downto 0));
    port (
      clk, reset_n, en : in  std_logic;
      din              : in  std_logic_vector(15 downto 0);
      dout             : out std_logic_vector(15 downto 0);
      check            : in  std_logic;
      valid            : out std_logic);
  end component;
  
  signal checksum_v, checksum_en, checksum_en0, checksum_check, checksum_check_r : std_logic;
  signal checksum_data, eth_data_sll                             : std_logic_vector(7 downto 0);
  signal cks_toggle_r                                            : std_logic_vector(23 downto 0);

  signal cksdat : std_logic_vector(15 downto 0);
  signal odd, udpcheck : std_logic;
  
begin

  v <= checksum_v and udpcheck and ip_v;
  --v <= udpcheck and ip_v;
  checksum_en0 <= odd and checksum_en;
  
  internet_checksum_16_1: internet_checksum_16
    generic map (
      init => X"0000")
    port map (
      clk     => clk,
      reset_n => eth.sof_n,
      en      => checksum_en0,
      din     => cksdat,
      dout    => open,
      check   => checksum_check_r,
      valid   => checksum_v);

  p_checksum : process (clk, reset_n)
  begin
    if reset_n = '0' or eth.sof_n = '0' then
      checksum_en      <= '0';
      cks_toggle_r     <= X"151618";
      checksum_check   <= '0';
      checksum_check_r <= '0';
    elsif clk'event and clk = '1' then

      if eth.valid_n = '1' then
        checksum_en <= '0';
      elsif eth.valid_n = '0' and cnt = cks_toggle_r(23 downto 16) then
        checksum_en  <= not checksum_en;
        cks_toggle_r <= cks_toggle_r(15 downto 0) & cks_toggle_r(23 downto 16);
      end if;

      checksum_check_r <= checksum_check;

      checksum_check <= '0';
      if eth.eof_n = '0' then
        checksum_check <= '1';
      end if;
      
    end if;
  end process p_checksum;

  p_cksdat: process (clk, reset_n)
  begin 
    if eth.sof_n = '0' or reset_n = '0' then     
      cksdat <= (others => '0');
      odd <= '0';
    elsif clk'event and clk = '1' then

      if checksum_en ='1' then
        cksdat <= cksdat(7 downto 0) & checksum_data;
        odd <= not odd;
      end if;
      
    end if;
  end process p_cksdat;
  
  eth_data_sll <= eth.data(6 downto 0) & '0';

  with cnt select
    checksum_data <=
    eth_data_sll when X"26",
    eth.data     when others;

  p_udpcheck: process (clk, reset_n)
  begin
    if eth.sof_n ='0' or reset_n = '0' then    
      udpcheck <= '0';
    elsif clk'event and clk = '1' then 
      if cnt=X"16" and eth.data=X"11" then
        udpcheck <= '1';
      end if;
    end if;
  end process p_udpcheck;
  
end rtl;
