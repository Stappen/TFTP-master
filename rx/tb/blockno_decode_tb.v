`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:30:51 06/06/2013
// Design Name:   blockno_decode
// Module Name:   C:/Users/Robbie Litchfield/tftp/blockno_decode_tb.v
// Project Name:  tftp
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: blockno_decode
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module blockno_decode_tb;

	// Inputs
	reg clk;
	reg reset;
	reg en;
	reg [7:0] eth_data;

	// Outputs
	wire [15:0] block_no;

	// Instantiate the Unit Under Test (UUT)
	blockno_decode uut (
		.clk(clk), 
		.reset(reset), 
		.en(en), 
		.eth_data(eth_data), 
		.block_no(block_no)
	);
	
	   // Note: CLK must be defined as a reg when using this method
   
   parameter PERIOD = 50;

   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end  
			

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		en = 0;
		eth_data = 0;

		// Wait 100 ns for global reset to finish
		#PERIOD;
        
		// Add stimulus here
		// Test DATA packet
		reset = 0;
		// Give op data
		#(PERIOD / 2);
		en = 1;
		eth_data = 8'b0;
		#PERIOD;
		eth_data = 8'b1;
		#PERIOD;
		en = 0;
		if(block_no == 16'b1)
			$display("Block Number succesfully decoded");
		else
			$display("Block Number test failed");
	end
      
endmodule

