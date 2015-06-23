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


entity internet_checksum_16 is
  generic (
    init : std_logic_vector(15 downto 0) := X"0000");

  port (
    clk, reset_n, en : in  std_logic;
    din              : in  std_logic_vector(15 downto 0);
    dout             : out std_logic_vector(15 downto 0);
    check            : in std_logic;
    valid            : out std_logic
    );

end internet_checksum_16;

architecture rtl of internet_checksum_16 is

  signal reg : std_logic_vector(31 downto 0) := X"00000000";
    
begin

  CLKLOGIC: process (clk, reset_n)
  begin 
    if reset_n = '0' then
      reg <= X"0000" & init;
    elsif clk'event and clk = '1' then 

      if check='1' then
        reg <= X"0000" & reg(31 downto 16) + reg(15 downto 0);
      elsif en='1' then
        reg <= reg + (X"0000" & din);          
      end if;
      
    end if;
  end process CLKLOGIC;

  dout <= reg(15 downto 0);

  with reg(15 downto 0) select
    valid <=
    '1' when X"FFFF",
    '0' when others;
  
end rtl;
