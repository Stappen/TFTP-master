-------------------------------------------------------------------------------
-- Title      : Testbench for design "ethernet"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ethernet_tb.vhd
-- Author     : Christopher Lorier  <cml16@voodoo.cms.waikato.ac.nz>
-- Company    : 
-- Created    : 2013-05-23
-- Last update: 2013-05-28
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Hardware TFTP Server
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-05-23  1.0      cml16	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.ethernet_frame.all;
use work.defs.all;

-------------------------------------------------------------------------------

entity ethernet_tb is

end ethernet_tb;

-------------------------------------------------------------------------------

architecture tb of ethernet_tb is

  component ethernet
    port (
      clk, reset_n       : in  std_logic;
      dv, er             : in  std_logic;
      config             : in  tftp_conf;
      rxd                : in  std_logic_vector(7 downto 0);
      arp, ip, goodframe : out std_logic;
      eth_src            : out std_logic_vector(47 downto 0));
  end component;

  -- component ports
  signal reset_n, dv   : std_logic;
  signal config             : tftp_conf;
  signal rxd                : std_logic_vector(7 downto 0);
  signal er, arp, ip : std_logic;
  signal eth_src            : std_logic_vector(47 downto 0);

  type ETHERNET_FRAME is array (0 to 83) of std_logic_vector(7 downto 0);
  
  -- clock
  signal Clk : std_logic := '1';
  signal success : std_logic := '0';
  signal index : integer := 0;
  signal ef : ETHERNET_FRAME;
  
begin  -- tb



  -- component instantiation
  DUT: ethernet
    port map (
      clk       => Clk,
      reset_n   => reset_n,
      dv        => dv,
      er        => er,
      config    => config,
      rxd       => rxd,
      arp       => arp,
      ip        => ip,
      eth_src   => eth_src);

  -- clock generation
  Clk <= not Clk after 10 ns;

  reset_n <= '0', '1' after 15 ns;

-- purpose: input frame into ethernet
-- type   : sequential
-- inputs : clk, reset_n  
test: process (clk, reset_n)
begin  -- process test
  if reset_n = '0' then                 -- asynchronous reset (active low)
    config.macaddr(47 downto 40) <= ef_eth_dest(0);
    config.macaddr(39 downto 32) <= ef_eth_dest(1);
    config.macaddr(31 downto 24) <= ef_eth_dest(2);
    config.macaddr(23 downto 16) <= ef_eth_dest(3);
    config.macaddr(15 downto 8) <= ef_eth_dest(4);
    config.macaddr(7 downto 0) <= ef_eth_dest(5);
    
    index <= 0;
    er <= '0';
    
    for i in 0 to 6 loop
      ef(i) <= x"55";
    end loop;  -- preamble
    ef(7) <= x"d5"; -- ifd
    for i in 0 to 5 loop
      ef(i + 8) <= ef_eth_dest(i);
    end loop;  -- eth dest
    for i in 0 to 5 loop
      ef(i + 14) <= ef_eth_src(i);
    end loop;  -- eth src
    for i in 0 to 1 loop
      ef(i + 20) <= ef_ethertype(i);
    end loop;  -- ethertype
    for i in 0 to 45 loop
      ef(i + 22) <= x"ff";
    end loop;  -- payload
    for i in 0 to 3 loop
      ef(i + 68) <= x"ff";
    end loop;  -- fcs
    for i in 0 to 11 loop
      ef(i + 72) <= (others => '0');
    end loop;  -- i
    
  elsif clk'event and clk = '1' then    -- rising clock edge
    if index < 84 then
      rxd <= ef(index);
      dv <= '1';
    end if;
    index <= index + 1;
    if eth_src(47 downto 40) = ef_eth_src(0) and
      eth_src(39 downto 32) = ef_eth_src(1) and
      eth_src(31 downto 24) = ef_eth_src(2) and
      eth_src(23 downto 16) = ef_eth_src(3) and
      eth_src(15 downto 8) = ef_eth_src(4) and
      eth_src(7 downto 0) = ef_eth_src(5) and ip = '1' then
      success <= '1';
    end if;
  end if;
end process test;
  
end tb;

-------------------------------------------------------------------------------

configuration ethernet_tb_tb_cfg of ethernet_tb is
  for tb
  end for;
end ethernet_tb_tb_cfg;

-------------------------------------------------------------------------------
