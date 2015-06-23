`timescale 1ns / 1ps
// AUTHOR: Robbie Litchfield
// TFTP Server
// Filename decode
module filename_decode(
    input clk,
    input reset,
    input en,
    input [7:0] eth_data,
    output valid,
    output [15:0] mem_location,
	 input [15:0] dest_port,
	 output valid_port
    );
	 
	 // State swtiches itself off when sees a 0
	 reg enabled;
	 always@(posedge clk)
		if(reset) begin
			enabled <= 1'b1;
		end else if(en & enabled) begin
			enabled <= |eth_data;
		end
		
	
	 // The files we will serve
	 // Case sensitive
	 parameter TINY = 32'h2B7873E9;// Tiny Core Linux (TinyCore-current.iso\0) 
	 parameter TINY_LOCATION = 16'h400; // Located at address 1024;
	 
	 // Instantiate the CRC module
	 wire [31:0] result;
	 crc checksum(eth_data, en&enabled, result, reset, clk);
	 
	 // Assert results
	 assign valid = TINY == result;
	 assign mem_location =  valid ? 16'h400 : 16'b0;
	 assign valid_port = dest_port == TINY_LOCATION;


endmodule
