`timescale 1ns / 1ps

//AUTHOR: Robbie Litchfield
// TFTP Server
// Mode Decode Testbench

module mode_decode_tb;

	// Inputs
	reg clk;
	reg reset;
	reg en;
	reg [7:0] eth_data;

	// Outputs
	wire valid;

	// Instantiate the Unit Under Test (UUT)
	mode_decode uut (
		.clk(clk), 
		.reset(reset), 
		.en(en), 
		.eth_data(eth_data), 
		.valid(valid)
	);
	
	parameter O = 8'h6F, C = 8'h63, T = 8'h74, E = 8'h65, NULL = 8'h0;
	reg [7:0] OCTECT [5:0];
	
   parameter PERIOD = 50;

   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end  
integer i;
	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		en = 0;
		eth_data = 0;
		
		// SETUP STRING
			OCTECT[0] = O;
	OCTECT[1] = C;
	OCTECT[2] = T;
	OCTECT[3] = E;
	OCTECT[4] = T;
	OCTECT[5] = NULL;
	

		// Wait 100 ns for global reset to finish
		#PERIOD;
		reset = 0;
		  en = 1;
		// Add stimulus here
			for (i = 0; i < 6; i=i+1) begin
			// Feed in data
			eth_data = OCTECT[i];
			
			// Wait for clock
			#PERIOD;
		end
		
		if(valid)
			$display("Test passed");
		else
			$display("Test Failed");
        
		// Add stimulus here

	end
      
endmodule

