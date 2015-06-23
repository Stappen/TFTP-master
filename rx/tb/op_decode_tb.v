`timescale 1ns / 1ps

// AUTHOR: Robbie Litchfield
// TFTP Server
// Opcode Decoder test bench

module op_decode_tb;

	// Inputs
	reg clk;
	reg reset;
	reg en;
	reg [7:0] eth_data;

	// Outputs
	wire ack;
	wire req;
	
	
   // Note: CLK must be defined as a reg when using this method
   
   parameter PERIOD = 50;

   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end  
				

	// Instantiate the Unit Under Test (UUT)
	opcode_decode uut (
		.clk(clk), 
		.reset(reset), 
		.en(en), 
		.eth_data(eth_data), 
		.ack(ack), 
		.req(req)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		en = 0;
		eth_data = 0;

		// Wait 100 ns for global reset to finish
		#PERIOD;
        
		// Add stimulus here
		// Test REQ packet
		reset = 0;
		// Give op data
		#(PERIOD / 2);
		en = 1;
		eth_data = 8'b0;
		#PERIOD;
		eth_data = 8'b1;
		#PERIOD;
		en = 0;
		if(req && ~ack)
			$display("REQ test was successfull");
		else if (~req)
			$display("REQ was not asserted when it should've");
		else if (ack)
			$display("ACK was asserted instead of REQ");
		#PERIOD;
		
		// Test ACK packet
		// Reset control
		reset = 1;
		en = 0;
		eth_data = 0;
		#PERIOD;
		reset = 0;
		// Give op data
		#PERIOD;
		en = 1;
		eth_data = 8'b0;
		#PERIOD;
		eth_data = 8'b100;
		#PERIOD;
		en = 0;
		if(~req && ack)
			$display("ACK test was successfull");
		else if (~ack)
			$display("ACK was not asserted when it should've");
		else if (req)
			$display("REQ was asserted instead of ACK");
		#PERIOD;
		
		// Test Garbage
		// Reset control
		reset = 1;
		en = 0;
		eth_data = 0;
		#PERIOD;
		reset = 0;
		// Give op data
		#PERIOD;
		en = 1;
		eth_data = 8'b1111;
		#PERIOD;
		eth_data = 8'b1001;
		#PERIOD;
		en = 0;
		if(req)
			$display("REQ was asserted woth garbage");
		else if (ack)
			$display("ACK was asserted with garbage");
		else
			$display("Garbage test was succesful");
		#100;
		

	end
      
endmodule

