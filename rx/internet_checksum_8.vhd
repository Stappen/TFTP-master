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


entity internet_checksum_8 is
  generic (
    init : std_logic_vector(15 downto 0) := X"0000");

  port (
    clk, reset_n, en : in  std_logic;
    din              : in  std_logic_vector(7 downto 0);
    dout             : out std_logic_vector(15 downto 0);
    check            : in std_logic;
    valid            : out std_logic
    );

end internet_checksum_8;

architecture rtl of internet_checksum_8 is

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

  signal oddbit : std_logic := '0';
  signal data_int : std_logic_vector(7 downto 0);
  signal en_int, check_int : std_logic;
  signal din_int : std_logic_vector(15 downto 0);
  
begin  -- rtl

  
  internet_checksum_16_1: internet_checksum_16
    generic map (
      init => init)
    port map (
      clk     => clk,
      reset_n => reset_n,
      en      => en_int,
      din     => din_int,
      dout    => dout,
      check   => check_int,
      valid   => valid);

  en_int <= oddbit and en;
  
  CLKLOGIC: process (clk, reset_n)
  begin  -- process CLKLOGIC
    if reset_n = '0' then               -- asynchronous reset (active low)
      oddbit <= '0';
      data_int <= (others => '0');
      check_int <= '0';
--      en_int <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      oddbit <= not oddbit;
      data_int <= din;
      check_int <= check;
--      en_int <= oddbit and en;
    end if;
  end process CLKLOGIC;

  p_datain: process (data_int, din, check, en_int)
  begin 

    if check='1' and en_int='1' then
      din_int <= data_int & X"00";
    else
      din_int <= data_int & din;
    end if;
  end process p_datain;
  
end rtl;
