`timescale 1ns / 1ps

// AUTHOR: Robbie Litchfield
// TFTP Server
// Filename Decode testbench

module filename_decode_tb;

	// Inputs
	reg clk;
	reg reset;
	reg en;
	reg [7:0] eth_data;
	reg [15:0] dest_port;

	// Outputs
	wire valid;
	wire [15:0] mem_location;
	wire valid_port;

	// Instantiate the Unit Under Test (UUT)
	filename_decode uut (
		.clk(clk), 
		.reset(reset), 
		.en(en), 
		.eth_data(eth_data), 
		.valid(valid), 
		.mem_location(mem_location), 
		.dest_port(dest_port), 
		.valid_port(valid_port)
	);

   parameter PERIOD = 50;

   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end  

	reg [7:0] FILENAME [20:0];
	initial $readmemh("filename.hex", FILENAME);
integer i;
	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		en = 0;
		eth_data = 0;
		dest_port = 16'h400;

		// Wait 100 ns for global reset to finish
		#PERIOD;
		reset = 0;
		  en = 1;
		// Add stimulus here
			for (i = 0; i < 21; i=i+1) begin
			// Feed in data
			eth_data = FILENAME[i];
			
			// Wait for clock
			#PERIOD;
		end
		
		if(valid && mem_location == 16'h400)
			$display("Test passed");
		else
			$display("Test Failed");

	end
      
endmodule

