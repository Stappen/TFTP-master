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

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

use work.ntp_parameters.all;

entity gmii_physical is
  generic (
	 USE_ODDR	: boolean	:= true
  );
  port (

    reset, clk  : in std_logic;

    -- GMII Interface
    GMII_TXD    : out std_logic_vector(7 downto 0);
    GMII_TX_EN  : out std_logic;
    GMII_TX_ER  : out std_logic;
    GMII_TX_CLK : out std_logic;

    GMII_RXD    : in std_logic_vector(7 downto 0);
    GMII_RX_DV  : in std_logic;
    GMII_RX_ER  : in std_logic;
    GMII_RX_CLK : in std_logic;

    -- MAC Interface
    TXD_FROM_MAC   : in std_logic_vector(7 downto 0);
    TX_EN_FROM_MAC : in std_logic;
    TX_ER_FROM_MAC : in std_logic;

    RXD_TO_MAC   : out std_logic_vector(7 downto 0);
    RX_DV_TO_MAC : out std_logic;
    RX_ER_TO_MAC : out std_logic

    );

end gmii_physical;

architecture rtl of gmii_physical is
  signal vcc_i : std_logic;
  signal gnd_i : std_logic;

  signal gmii_tx_clk_i : std_logic;
  signal gmii_tx_en_r  : std_logic;
  signal gmii_tx_er_r  : std_logic;
  signal gmii_txd_r    : std_logic_vector(7 downto 0);

  signal gmii_rx_dv_i, gmii_rx_dv_r, gmii_rx_dv_r1, gmii_rx_dv_r2 : std_logic;
  signal gmii_rx_er_i, gmii_rx_er_r, gmii_rx_er_r1, gmii_rx_er_r2 : std_logic;
  signal gmii_rxd_i, gmii_rxd_r, gmii_rxd_r1, gmii_rxd_r2         : std_logic_vector(7 downto 0);
  signal gmii_rx_clk_i, gmii_tx_clk_d : std_logic;
  
  signal rdy : std_logic;
  signal CNTVALUEIN, CNTVALUEOUT : std_logic_vector(4 downto 0);
begin  -- rtl
  vcc_i <= '1';
  gnd_i <= '0';

--gen_oddr : if USE_ODDR = true generate
  gmii_tx_clk_oddr : ODDR
    port map (
      Q  => gmii_tx_clk_i,
      C  => clk,
      CE => vcc_i,
      D1 => gnd_i,
      D2 => vcc_i,
      R  => reset,
      S  => gnd_i
      );
--end generate gen_oddr;

--gen_oddr2 : if USE_ODDR = false generate
--	gmii_tx_clk_oddr : ODDR2
--    port map (
--      Q  => gmii_tx_clk_i,
--      C0 => clk,
--		C1 => not clk,
--      CE => vcc_i,
--      D0 => gnd_i,
--      D1 => vcc_i,
--      R  => reset,
--      S  => gnd_i
--      );
--end generate gen_oddr2;

  gmii_tx_clk_obuf : OBUF
    port map (
      I => gmii_tx_clk_i,
      O => GMII_TX_CLK
    );

  gmii_output_ffs : process (clk, reset)
  begin
    if reset = '1' then
      gmii_tx_en_r <= '0';
      gmii_tx_er_r <= '0';
      gmii_txd_r   <= (others => '0');
    elsif clk'event and clk = '1' then
      gmii_tx_en_r <= TX_EN_FROM_MAC;
      gmii_tx_er_r <= TX_ER_FROM_MAC;
      gmii_txd_r   <= TXD_FROM_MAC;
    end if;
  end process gmii_output_ffs;

  gmii_tx_en_obuf : OBUF port map (I => gmii_tx_en_r, O => GMII_TX_EN);
  gmii_tx_er_obuf : OBUF port map (I => gmii_tx_er_r, O => GMII_TX_ER);

  gmii_txd_bus : for I in 7 downto 0 generate
    gmii_txd_0_obuf : OBUF port map (I => gmii_txd_r(I), O => GMII_TXD(I));
  end generate;


  gmii_rx_dv_ibuf : IBUF port map (I => GMII_RX_DV, O => gmii_rx_dv_i);
  gmii_rx_er_ibuf : IBUF port map (I => GMII_RX_ER, O => gmii_rx_er_i);

  gmii_rxd_bus : for I in 7 downto 0 generate
    gmii_rxd_ibuf : IBUF port map (I => GMII_RXD(I), O => gmii_rxd_i(I));
  end generate;

 -- gmii_rx_clk_0_ibufg : IBUFG
 --   port map (
 --     I => GMII_RX_CLK,
  --    O => gmii_rx_clk_i
--);
	gmii_rx_clk_i <= GMII_RX_CLK;
	
  RXREGS : process (gmii_rx_clk_i, reset)
  begin
    if reset = '1' then
      gmii_rxd_r   <= (others => '0');
      gmii_rx_er_r <= '0';
      gmii_rx_dv_r <= '0';
    elsif gmii_rx_clk_i'event and gmii_rx_clk_i = '1' then
      gmii_rxd_r   <= gmii_rxd_i;
      gmii_rx_er_r <= gmii_rx_er_i;
      gmii_rx_dv_r <= gmii_rx_dv_i;
    end if;
  end process RXREGS;

  RXREGS2 : process (clk, reset)
  begin
    if reset = '1' then
      gmii_rxd_r1   <= (others => '0');
      gmii_rx_er_r1 <= '0';
      gmii_rx_dv_r1 <= '0';
      gmii_rxd_r2   <= (others => '0');
      gmii_rx_er_r2 <= '0';
      gmii_rx_dv_r2 <= '0';
    elsif clk'event and clk = '1' then
      gmii_rxd_r1   <= gmii_rxd_r;
      gmii_rx_er_r1 <= gmii_rx_er_r;
      gmii_rx_dv_r1 <= gmii_rx_dv_r;
      gmii_rxd_r2   <= gmii_rxd_r1;
      gmii_rx_er_r2 <= gmii_rx_er_r1;
      gmii_rx_dv_r2 <= gmii_rx_dv_r1;
    end if;
  end process RXREGS2;

  RXD_TO_MAC   <= gmii_rxd_r2;
  RX_DV_TO_MAC <= gmii_rx_dv_r2;
  RX_ER_TO_MAC <= gmii_rx_er_r2;
  
end rtl;
