`timescale 1ns / 1ps
//AUTHOR: Robbie litchfield & Thomas Verstappen
// TFTP Server
// UDP Port decode test bench

module udpport_decode_tb;

	// Inputs
	reg clk;
	reg reset;
	reg [7:0] eth_data;
	reg [7:0] cnt;

	// Outputs
	wire [15:0] dst_port;
	wire [15:0] src_port;

	// Instantiate the Unit Under Test (UUT)
	udpport_decode uut (
		.clk(clk), 
		.reset(reset), 
		.eth_data(eth_data), 
		.cnt(cnt), 
		.dst_port(dst_port), 
		.src_port(src_port)
	);

	   
   parameter PERIOD = 50;

   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end  
	
		
		reg [7:0] REQ_DATA [70:0];
	initial $readmemh("request2.hex", REQ_DATA);
integer i;
	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		eth_data = 0;
		cnt = 0;

		// Wait 100 ns for global reset to finish
		#PERIOD;
		reset = 0;
		
		// Feed in data
			for (i = 0; i < 71; i=i+1) begin
			// Feed in data
			eth_data = REQ_DATA[i];
			cnt = i;
			
			// Wait for clock
			#PERIOD;
		end
		
			// Check results
		if(dst_port == 16'h45 && src_port == 16'hc5ba)
			$display("Test passed");
		else
			$display("Test failed");


	end
      
endmodule

