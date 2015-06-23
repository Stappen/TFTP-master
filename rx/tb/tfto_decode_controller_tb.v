`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:26:18 06/06/2013
// Design Name:   tftp_decode_controller
// Module Name:   C:/Users/Robbie Litchfield/tftp/tfto_decode_controller_tb.v
// Project Name:  tftp
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: tftp_decode_controller
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tftp_decode_controller_tb;

	// Inputs
	reg clk;
	reg reset;
	reg [7:0] cnt;
	reg [7:0] eth_data;
	reg ack;
	reg req;

	// Outputs
	wire idle_en;
	wire opcode_en;
	wire blockno_en;
	wire filename_en;
	wire mode_en;
	
	reg [7:0] REQ_DATA [61:0];
	initial $readmemh("request.hex", REQ_DATA);
	
	reg [7:0] ACK_DATA [59:0];
	initial $readmemh("acknowledge.hex", ACK_DATA);

   // Note: CLK must be defined as a reg when using this method
   parameter PERIOD = 50;

   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end  

	// Instantiate the Unit Under Test (UUT)
	tftp_decode_controller uut (
		.clk(clk), 
		.reset(reset), 
		.cnt(cnt), 
		.eth_data(eth_data), 
		.ack(ack), 
		.req(req), 
		.idle_en(idle_en), 
		.opcode_en(opcode_en), 
		.blockno_en(blockno_en), 
		.filename_en(filename_en), 
		.mode_en(mode_en)
	);
	integer i;
	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		cnt = 0;
		eth_data = 0;
		ack = 0;
		req = 0;

		// Wait 100 ns for global reset to finish
		#PERIOD;
		reset = 0;
        
		// Test req packet
		req = 1;
		
		for (i = 0; i < 62; i=i+1) begin
			// Feed in data
			eth_data = REQ_DATA[i];
			cnt = i+1;
			
			// Wait for clock
			#PERIOD;
			
			// Check mid-cycle transitions
			if(i == 42 && opcode_en)
				$display("OP Transition successful");
			else if (i == 42)
				$display("OP transition failed");
				
			if(i == 44 && filename_en)
				$display("Filename transition successful");
			else if (i == 44)
				$display("Filename transition failed");
				
				if(i == 56 && mode_en)
				$display("Mode transition successful");
			else if (i == 56)
				$display("Mode transition failed");
		end
		
		// Check end transition
		// Wait for clock
			#PERIOD;
		if(idle_en)
			$display("Idle transition successful");
		else 
			$display("Final idle transition failed");
			
		// Initialize Inputs
		reset = 1;
		cnt = 0;
		eth_data = 0;
		ack = 0;
		req = 0;

		// Wait 100 ns for global reset to finish
		#PERIOD;
		reset = 0;
		
		// Test ack packet
		ack = 1;
		
		for (i = 0; i < 60; i=i+1) begin
			// Feed in data
			eth_data = REQ_DATA[i];
			cnt = i+1;
			
			// Wait for clock
			#PERIOD;
			
			// Check mid-cycle transitions
			if(i == 42 && opcode_en)
				$display("OP Transition successful");
			else if (i == 42)
				$display("OP transition failed");
				
			if(i == 44 && blockno_en)
				$display("Block number transition successful");
			else if (i == 44)
				$display("Block Number transition failed");
		end
		
		// Check end transition
		// Wait for clock
			#PERIOD;
		if(idle_en)
			$display("Idle transition successful");
		else 
			$display("Final idle transition failed");
			

	end
      
endmodule

