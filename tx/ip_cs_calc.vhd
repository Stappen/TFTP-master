library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity ip_cs_calc is

  port (
    clk, reset_n, start : in  std_logic;
    ip_src, ip_dst   : in  std_logic_vector(31 downto 0);
    ip_len, ip_id    : in  std_logic_vector(15 downto 0);
    ip_cs          : out std_logic_vector(15 downto 0);
    ready          : out std_logic);
end ip_cs_calc;

architecture rtl of ip_cs_calc is

    signal cs_32 : std_logic_vector(31 downto 0) := x"0000_0000";
    signal cs : std_logic_vector(15 downto 0);

    signal reg : std_logic_vector(127 downto 0);
    
    signal count : std_logic_vector(15 downto 0);

    signal active, done, pause : std_logic;
    
    constant IP_CS_CONST : std_logic_vector(31 downto 0) := x"0000_7511";

begin  -- rtl
 
  -- purpose: builds the header
  -- type   : sequential
  -- inputs : clk, reset_n, all the inputs
  -- outputs: ip_header, ready
  checksum: process (clk, reset_n)
  begin  -- process build_header
    if reset_n = '0' then               -- asynchronous reset (active low)
      count <= x"0000";
      ready <= '0';
      active <= '0';
      cs_32 <= x"0000_0000";
      cs <= x"0000";
      done <=  '0';
      reg <= ip_len & ip_id & ip_src & ip_dst & IP_CS_CONST;
    elsif clk'event and clk = '1' then  -- rising clock edge

      --might as well do this during the pause..
      if active = '1' and pause = '1' then
        cs <= cs_32(15 downto 0) + cs_32(31 downto 16);
      elsif active = '0' then
        cs <= x"0000";
      end if;
      
      if active = '1' and pause = '0' then
        cs_32 <= (x"0000" & cs) + (x"0000" & reg(127 downto 112));
      elsif active = '0' then
        cs_32 <= x"0000_0000";
      end if;

      if active = '1' then
        ip_cs <= cs xor x"ffff";
      end if;
      
      if active = '1' and count = x"0010" then
        active <= '0';
        ready <= '1';
      elsif active = '0' and done = '0' and start = '1' then
        active <= '1';
        ready <= '0';
      end if;

      if active = '0' and start = '1' then
        reg <= ip_len & ip_id & ip_src & ip_dst & IP_CS_CONST;
      elsif active = '1' and pause = '1' then
        reg <= reg(111 downto 0) & x"0000";
      end if;

      if active = '0' then
        count <= x"0000";
      elsif active = '1' and pause = '1' then
        count <= count + 2;
      end if;

      if active = '1' and count = x"0010" then
         done <= '1';
       elsif start = '0' then
         done <= '0';
       end if;

       if active = '0' then
        pause <= '0';
      else
        pause <= not pause;  
      end if;

    end if;
  end process checksum;

end rtl;
