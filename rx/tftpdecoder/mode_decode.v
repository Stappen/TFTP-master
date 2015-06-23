`timescale 1ns / 1ps
// AUTHOR: Robbie Litchfield
// TFTP Server
// Mode decode
module mode_decode(
    input clk,
    input reset,
    input en,
    input [7:0] eth_data,
    output valid
    );
	 
	  
	 // State swtiches itself off when sees a 0
	 reg enabled;
	 always@(posedge clk)
		if(reset) begin
			enabled <= 1'b1;
		end else if(en& enabled) begin
			enabled <= |eth_data;
		end
		
	 
	 // The uppercase ASCII range
	 parameter START = 8'h41, FINISH = 8'h5A, OFFSET = 8'h20;
	 // The hash for "octect\0"
	 parameter HASH = 32'h0B923DBE;
	 
	 // Ensure input data is lower case
	 wire [7:0] lowercase = ((START <= eth_data) & (eth_data <= FINISH)) ? (eth_data + OFFSET) : eth_data;

	 // Instantiate the CRC module
	 wire [31:0] result;
	 crc checksum(lowercase, en&enabled, result, reset, clk);
	 
	 // Assert result
	 assign valid = result == HASH;
endmodule
