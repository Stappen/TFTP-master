-------------------------------------------------------------------------------
-- Title      : Testbench for design "tftp_assembler"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tftp_assembler_tb.vhd
-- Author     : Christopher Lorier  <cml16@voodoo.cms.waikato.ac.nz>
-- Company    : 
-- Created    : 2013-06-10
-- Last update: 2013-06-11
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
-- 2013-06-10  1.0      cml16	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

-------------------------------------------------------------------------------

entity tftp_assembler_tb is

end tftp_assembler_tb;

-------------------------------------------------------------------------------

architecture tb of tftp_assembler_tb is

  component tftp_assembler
    port (
      clk, reset_n  : in  std_logic;
      conf          : in  tftp_conf;
      mem_ready, dv : in  std_logic;
      opcode        : in  tftp_opcode_t;
      mem_data      : in  std_logic_vector(7 downto 0);
      en            : in  std_logic;
      mem_en        : out std_logic;
      ready         : out std_logic;
      eth_out       : out ethernet_datapath_interface);
  end component;

  -- component ports
  signal reset_n  : std_logic;
  signal conf          : tftp_conf;
  signal mem_ready, dv : std_logic;
  signal opcode        : tftp_opcode_t;
  signal mem_data      : std_logic_vector(7 downto 0);
  signal en            : std_logic;
  signal mem_en        : std_logic;
  signal ready         : std_logic;
  signal eth_out       : ethernet_datapath_interface;

  -- clock
  signal Clk : std_logic := '1';

  --queue simulation
  signal op1, op2 : tftp_opcode_t;
  signal mem1, mem2 : std_logic_vector(63 downto 0) := x"9897_9695_9493_9291";

  type states is (READY1, SEND1, READY2, SEND2, IDLE);
  signal state : states;
  signal count : std_logic_vector(15 downto 0);
  
begin  -- tb

  -- component instantiation
  DUT: tftp_assembler
    port map (
      clk       => clk,
      reset_n   => reset_n,
      conf      => conf,
      mem_ready => mem_ready,
      dv        => dv,
      opcode    => opcode,
      mem_data  => mem_data,
      en        => en,
      mem_en    => mem_en,
      ready     => ready,
      eth_out   => eth_out);
  
  -- clock generation
  Clk <= not Clk after 10 ns;

  reset_n <= '0', '1' after 15 ns;

  -- waveform generation
  WaveGen_Proc: process
  begin
    wait until Clk = '1';
  end process WaveGen_Proc;


  -- purpose: inputs
  -- type   : sequential
  -- inputs : clk, reset_n
  -- outputs: 
  inputs: process (clk, reset_n)
  begin  -- process inputs
    if reset_n = '0' then               -- asynchronous reset (active low)
          -- insert signal assignments here
    conf.macaddr <= x"f1f2f3f4f5f6";
    conf.ipv4addr <= x"c0a80101";

    op1.eth_src <= x"0a0b0c0d0e0f";
    op1.ip_src <= x"c0a80202";
    op1.udp_src <= x"c1c2";
    op1.tid <= x"2222";
    op1.tftp_block <= x"9876";
    op1.block_len <= x"0000";
    op1.ready_n  <= '0';
    
    op2.eth_src <= x"2a2b2c2d2e2f";
    op2.ip_src <= x"c0a80303";
    op2.udp_src <= x"e1e2";
    op2.tid <= x"6666";
    op2.tftp_block <= x"6789";
    op2.block_len <= x"0008";
    op2.ready_n  <= '0';

    state <= READY1;
    en <= '0';
    mem_ready <= '0';
    count <= x"0000";
    
    elsif clk'event and clk = '1' then  -- rising clock edge
        opcode <= op1;
        mem_ready <= '1';

      if ready = '1' then
        en <= '1';        
      end if;
      
      if state = READY1 and mem_en = '1' then
        state <= READY2;
      elsif state = READY2 then
        dv <= '0';
        if mem_en = '1' then
          en <= '1';
          state <= SEND2;
        end if;
      elsif state = SEND2 then
        count <= count + 1;
        dv <= '1';
        opcode <= op2;
        mem_data <= mem2(63 downto 56);
        mem2 <= mem2(55 downto 0) & mem2(63 downto 56);
         if count = x"0008" then
          count <= x"0000";
          state <= IDLE;
        else
          count <= count + 1;
        end if;
         elsif state = IDLE then
           dv <= '0';
           mem_ready <= '0';
      end if;
     
      
    end if;
  end process inputs;

  

end tb;

-------------------------------------------------------------------------------

configuration tftp_assembler_tb_tb_cfg of tftp_assembler_tb is
  for tb
  end for;
end tftp_assembler_tb_tb_cfg;

-------------------------------------------------------------------------------
