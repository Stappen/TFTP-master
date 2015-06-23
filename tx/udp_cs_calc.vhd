library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;


entity udp_cs_calc is
  
  port (
    clk, reset_n              : in  std_logic;
    
    ip_src, ip_dst            : in  std_logic_vector(31 downto 0);
    udp_len, udp_src, udp_dst : in std_logic_vector(15 downto 0);
    tftp_block_no             : in std_logic_vector(15 downto 0);

    mem_data                  : in std_logic_vector(7 downto 0);
    start                        : in std_logic;

    udp_cs                    : out std_logic_vector(15 downto 0);
    ready                     : out std_logic);

end udp_cs_calc;

architecture rtl of udp_cs_calc is

    signal cs_32 : std_logic_vector(31 downto 0) := x"0000_0000";
    signal cs : std_logic_vector(15 downto 0);

    signal data_r : std_logic_vector(7 downto 0);
    signal reg : std_logic_vector(191 downto 0);

    signal count : std_logic_vector(15 downto 0);
    
    signal active, pause : std_logic;
    
begin  -- rtl
  
  -- purpose: does checksumming
  -- type   : sequential
  -- inputs : clk, reset_n, everything else
  -- outputs: udp_cs and ready
checksum: process (clk, reset_n)
  begin  -- process checksum
    if reset_n = '0' then               -- asynchronous reset (active low)
      count <= x"0000";
      pause <= '0';
      ready <= '0';
      cs_32 <= x"0000_0000";
      cs <= x"0000";
      active <= '0';
      data_r <= x"00";
    elsif clk'event and clk = '1' then  -- rising clock edge

      --might as well do this during the pause..
      if active = '1' and pause = '1' then
        cs <= cs_32(15 downto 0) + cs_32(31 downto 16);
      elsif active = '0' then
        cs <= x"0000";
      end if;

      -- update cs
      if active = '1' and pause = '0' then
        cs_32 <= (x"0000" & cs) + (x"0000" & reg(191 downto 176));
      elsif active = '0' then
        cs_32 <= x"0000_0000";
      end if;
      
      if active = '1' then
        udp_cs <= cs xor x"ffff";        
      end if;

      if active = '0' and start = '1' then
        active <= '1';
        ready <=  '0';
      elsif active = '1' and count = udp_len + 12 then
        active <= '0';
        ready <= '1';
      end if;

      if active = '1' and pause = '0' then
        data_r <= mem_data;
      end if;
      
      -- load reg
      if active = '0' and start = '1' then
        reg <= ip_src & ip_dst & x"0011" & udp_len & udp_src & udp_dst
               & udp_len & x"0000" & x"0003" & tftp_block_no;
      elsif active = '1' and pause = '1' then
        reg <= reg(175 downto 0) & data_r & mem_data;
      end if;

      if active = '0' then
        count <= x"0000";
      elsif active = '1' and pause = '1' then
        count <= count + 2;
      end if;
      
      if active = '0' then
        pause <= '0';
      else
        pause <= not pause;  
      end if;
            
    end if;
  end process checksum;  
  
end rtl;
