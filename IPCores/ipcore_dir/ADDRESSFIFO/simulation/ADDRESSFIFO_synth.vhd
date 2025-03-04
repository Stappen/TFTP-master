--------------------------------------------------------------------------------
--
-- FIFO Generator Core Demo Testbench 
--
--------------------------------------------------------------------------------
--
-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--------------------------------------------------------------------------------
--
-- Filename: ADDRESSFIFO_synth.vhd
--
-- Description:
--   This is the demo testbench for fifo_generator core.
--
--------------------------------------------------------------------------------
-- Library Declarations
--------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_unsigned.ALL;
USE IEEE.STD_LOGIC_arith.ALL;
USE ieee.numeric_std.ALL;
USE ieee.STD_LOGIC_misc.ALL;

LIBRARY std;
USE std.textio.ALL;

LIBRARY work;
USE work.ADDRESSFIFO_pkg.ALL;

--------------------------------------------------------------------------------
-- Entity Declaration
--------------------------------------------------------------------------------
ENTITY ADDRESSFIFO_synth IS
  GENERIC(
  	   FREEZEON_ERROR : INTEGER := 0;
	   TB_STOP_CNT    : INTEGER := 0;
	   TB_SEED        : INTEGER := 1
	 );
  PORT(
	S_ACLK     :  IN  STD_LOGIC;
        RESET      :  IN  STD_LOGIC;
        SIM_DONE   :  OUT STD_LOGIC;
        STATUS     :  OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
END ENTITY;

ARCHITECTURE simulation_arch OF ADDRESSFIFO_synth IS
    CONSTANT TDATA_OFFSET      : INTEGER := if_then_else(1 = 1,32-32,32);
    CONSTANT TSTRB_OFFSET      : INTEGER := if_then_else(0 = 1,TDATA_OFFSET-4,TDATA_OFFSET);
    CONSTANT TKEEP_OFFSET      : INTEGER := if_then_else(0 = 1,TSTRB_OFFSET-4,TSTRB_OFFSET);
    CONSTANT TID_OFFSET        : INTEGER := if_then_else(0 = 1,TKEEP_OFFSET-8,TKEEP_OFFSET);
    CONSTANT TDEST_OFFSET      : INTEGER := if_then_else(0 = 1,TID_OFFSET-4,TID_OFFSET);
    CONSTANT TLAST_OFFSET      : INTEGER := if_then_else(0 = 1,TDEST_OFFSET-4,TDEST_OFFSET);

    -- FIFO interface signal declarations
    SIGNAL s_aresetn                      :   STD_LOGIC;
    SIGNAL m_axis_tvalid                  :   STD_LOGIC;
    SIGNAL m_axis_tready                  :   STD_LOGIC;
    SIGNAL m_axis_tdata                   :   STD_LOGIC_VECTOR(32-1 DOWNTO 0);
    SIGNAL s_axis_tvalid                  :   STD_LOGIC;
    SIGNAL s_axis_tready                  :   STD_LOGIC;
    SIGNAL s_axis_tdata                   :   STD_LOGIC_VECTOR(32-1 DOWNTO 0);
    SIGNAL s_aclk_i		          :   STD_LOGIC;
   -- TB Signals
    SIGNAL prc_we_i                       :   STD_LOGIC := '0';
    SIGNAL prc_re_i                       :   STD_LOGIC := '0';
    SIGNAL dout_chk_i                     :   STD_LOGIC := '0';
    SIGNAL rst_int_rd                     :   STD_LOGIC := '0';
    SIGNAL rst_int_wr                     :   STD_LOGIC := '0';
    SIGNAL rst_gen_rd                     :   STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rst_s_wr3                      :   STD_LOGIC := '0';
    SIGNAL rst_s_rd                       :   STD_LOGIC := '0';
    SIGNAL reset_en                       :   STD_LOGIC := '0';
    SIGNAL din_axis                       :   STD_LOGIC_VECTOR(32-1 DOWNTO 0);
    SIGNAL dout_axis                      :   STD_LOGIC_VECTOR(32-1 DOWNTO 0);
    SIGNAL wr_en_axis                     :   STD_LOGIC := '0';
    SIGNAL rd_en_axis                     :   STD_LOGIC := '0';
    SIGNAL full_axis                      :   STD_LOGIC := '0';
    SIGNAL empty_axis                     :   STD_LOGIC := '0';
    SIGNAL status_axis                    :   STD_LOGIC_VECTOR(7 DOWNTO 0):="00000000";
    SIGNAL rst_async_rd1                  :   STD_LOGIC := '0'; 
    SIGNAL rst_async_rd2                  :   STD_LOGIC := '0'; 
    SIGNAL rst_async_rd3                  :   STD_LOGIC := '0'; 


 BEGIN  

   ---- Reset generation logic -----
   rst_int_wr          <= rst_async_rd3 OR rst_s_rd;
   rst_int_rd          <= rst_async_rd3 OR rst_s_rd;

   --Testbench reset synchronization
   PROCESS(s_aclk_i,RESET)
   BEGIN
     IF(RESET = '1') THEN
       rst_async_rd1    <= '1';
       rst_async_rd2    <= '1';
       rst_async_rd3    <= '1';
     ELSIF(s_aclk_i'event AND s_aclk_i='1') THEN
       rst_async_rd1    <= RESET;
       rst_async_rd2    <= rst_async_rd1;
       rst_async_rd3    <= rst_async_rd2;
     END IF;
   END PROCESS;

   --Soft reset for core and testbench
   PROCESS(s_aclk_i)
   BEGIN 
     IF(s_aclk_i'event AND s_aclk_i='1') THEN
       rst_gen_rd      <= rst_gen_rd + "1";
       IF(reset_en = '1' AND AND_REDUCE(rst_gen_rd) = '1') THEN
         rst_s_rd      <= '1';
         assert false
         report "Reset applied..Memory Collision checks are not valid"
         severity note;
       ELSE
         IF(AND_REDUCE(rst_gen_rd)  = '1' AND rst_s_rd = '1') THEN
           rst_s_rd    <= '0';
           assert false
           report "Reset removed..Memory Collision checks are valid"
           severity note;
         END IF;
       END IF;
     END IF;
   END PROCESS;
   ------------------
   
   ---- Clock buffers for testbench ----
  s_aclk_i <= S_ACLK;
   ------------------
    
    s_aresetn 	              <= NOT (RESET OR rst_s_rd) AFTER 12 ns;




    S_AXIS_TVALID             <= wr_en_axis;
    M_AXIS_TREADY             <= rd_en_axis;
    full_axis                 <= NOT s_axis_tready;
    empty_axis                <= NOT m_axis_tvalid;

    fg_dg_axis: ADDRESSFIFO_dgen
      GENERIC MAP (  
          	 C_DIN_WIDTH      => 32,
		 C_DOUT_WIDTH     => 32,
		 TB_SEED          => TB_SEED, 
 		 C_CH_TYPE        => 0
                  )
      PORT MAP (  
                RESET            => rst_int_wr,
                WR_CLK           => s_aclk_i,
		PRC_WR_EN        => prc_we_i,
                FULL             => full_axis,
                WR_EN            => wr_en_axis,
                WR_DATA          => din_axis
	       );

   fg_dv_axis: ADDRESSFIFO_dverif
    GENERIC MAP (  
	       C_DOUT_WIDTH       => 32,
	       C_DIN_WIDTH        => 32,
	       C_USE_EMBEDDED_REG => 0,
	       TB_SEED            => TB_SEED, 
 	       C_CH_TYPE          => 0	 
	       )
     PORT MAP(
              RESET               => rst_int_rd,
              RD_CLK              => s_aclk_i,
	      PRC_RD_EN           => prc_re_i,
              RD_EN               => rd_en_axis,
	      EMPTY               => empty_axis,
	      DATA_OUT            => dout_axis,
	      DOUT_CHK            => dout_chk_i
	    );

    fg_pc_axis: ADDRESSFIFO_pctrl
    GENERIC MAP (  
              AXI_CHANNEL         => "AXI4_Stream",
              C_APPLICATION_TYPE  => 0,
	      C_DOUT_WIDTH        => 32,
	      C_DIN_WIDTH         => 32,
	      C_WR_PNTR_WIDTH     => 10,
    	      C_RD_PNTR_WIDTH     => 10,
 	      C_CH_TYPE           => 0,
              FREEZEON_ERROR      => FREEZEON_ERROR,
	      TB_SEED             => TB_SEED, 
              TB_STOP_CNT         => TB_STOP_CNT
	     )
     PORT MAP(
              RESET_WR            => rst_int_wr,
              RESET_RD            => rst_int_rd,
	      RESET_EN            => reset_en,
              WR_CLK              => s_aclk_i,
              RD_CLK              => s_aclk_i,
              PRC_WR_EN           => prc_we_i,
              PRC_RD_EN           => prc_re_i,
	      FULL                => full_axis,
	      EMPTY               => empty_axis,
              ALMOST_FULL         => '0',
              ALMOST_EMPTY        => '0',
	      DATA_IN             => din_axis,
	      DATA_OUT            => dout_axis,
	      DOUT_CHK            => dout_chk_i,
	      SIM_DONE            => SIM_DONE,
	      STATUS              => STATUS
	    );
       s_axis_tdata    <= din_axis(32-1 DOWNTO TDATA_OFFSET);
       dout_axis(32-1 DOWNTO TDATA_OFFSET) <= m_axis_tdata;

  ADDRESSFIFO_inst : ADDRESSFIFO_exdes 
    PORT MAP (
           S_ARESETN                 => s_aresetn,
           M_AXIS_TVALID             => m_axis_tvalid,
           M_AXIS_TREADY             => m_axis_tready,
           M_AXIS_TDATA              => m_axis_tdata,
           S_AXIS_TVALID             => s_axis_tvalid,
           S_AXIS_TREADY             => s_axis_tready,
           S_AXIS_TDATA              => s_axis_tdata,
           S_ACLK                    => s_aclk_i);

END ARCHITECTURE;
