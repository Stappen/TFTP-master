`timescale 1ns / 1ps

//AUTHOR: Robbie Litchfield
// TFTP Server
// TFTP Decode Testbench

module tftp_decode_tb;

	// Inputs
	reg clk;
	reg reset;
	reg [7:0] cnt;
	reg [7:0] eth_data;
	reg [15:0] udp_dst;

	// Outputs
	wire valid;
	wire [15:0] tid;
	wire [15:0] next_block_no;
	wire [9:0] length;

	// Instantiate the Unit Under Test (UUT)
	tftp_decode uut (
		.clk(clk), 
		.reset(reset), 
		.cnt(cnt), 
		.eth_data(eth_data), 
		.udp_dst(udp_dst), 
		.valid(valid), 
		.tid(tid), 
		.next_block_no(next_block_no), 
		.length(length)
	);
	
	   
   parameter PERIOD = 50;

   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end  
	
		reg [7:0] REQ_DATA [70:0];
	initial $readmemh("request2.hex", REQ_DATA);
	
	reg [7:0] ACK_DATA [59:0];
	initial $readmemh("acknowledge.hex", ACK_DATA);

integer i;
integer r;
	initial begin
	
		// Run REQ packet type 3 times
		for(r = 0; r < 3; r = r + 1) 
			begin
				// Initialize Inputs
				clk = 0;
				reset = 1;
				cnt = 0;
				eth_data = 0;
				udp_dst = 0;

				// Wait 100 ns for global reset to finish
				#PERIOD;
				reset = 0;
        
				// Add stimulus here
				// Test req packet
				udp_dst = 16'h45;
		
				for (i = 0; i < 71; i=i+1) begin
					// Feed in data
					eth_data = REQ_DATA[i];
					cnt = i;
			
					// Wait for clock
					#PERIOD;
				end
			end
		// Check output
		if(valid && tid == 16'h400 && next_block_no == 16'b1 && length == 10'h200)
			$display("REQ packet passed");
		else
			$display("REQ packet failed");
			
		// Run ACK packet type 3 times
		for(r = 0; r < 3; r = r + 1) 
			begin
				// Initialize Inputs
				clk = 0;
				reset = 1;
				cnt = 0;
				eth_data = 0;
				udp_dst = 0;

				// Wait 100 ns for global reset to finish
				#PERIOD;
				reset = 0;
        
				// Add stimulus here
				// Test ack packet
				udp_dst = 16'h400;
		
				for (i = 0; i < 60; i=i+1) begin
					// Feed in data
					eth_data = ACK_DATA[i];
					cnt = i;
			
					// Wait for clock
					#PERIOD;
				end
			end
		// Check output
		if(valid && tid == 16'h400 && next_block_no == 16'b10 && length == 10'h200)
			$display("ACK packet passed");
		else
			$display("ACK packet failed");
	end   
endmodule

