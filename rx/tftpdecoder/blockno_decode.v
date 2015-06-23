`timescale 1ns / 1ps
// AUTHOR: Robbie Litchfield
// TFTP Server
// Block Number Decoder
module blockno_decode(
    input clk,
    input reset,
    input en,
    input [7:0] eth_data,
	 output block_valid, 
	 output [15:0] block_no
    );

	 // The block register
	 reg [7:0] block [1:0];
	 reg [1:0] counter; 
	 
	 
	 // Assert block results
	 assign block_no = { block[0], block[1] };
	 assign block_valid = counter[1];
	 
	always@(posedge clk)
		begin
			// Reset if necessary
			if(reset) begin 
				block[0] <= 8'b0;
				block[1] <= 8'b0;
				counter <= 2'b0;
			end else if(en & ~counter[1]) begin
				// Store block into registers		
				block[1] <= eth_data;
				block[0] <= block[1];
				counter <= counter + 2'b1;
			end
		end


endmodule
