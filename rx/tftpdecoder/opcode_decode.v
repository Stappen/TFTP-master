`timescale 1ns / 1ps
// AUTHOR: Robbie Litchfield
// TFTP Server
// OPCODE decoder
module opcode_decode(
    input clk,
    input reset,
    input en,
    input [7:0] eth_data,
    output ack,
    output req
    );
	 
	 // The opcodes we respond to
	 parameter REQ = 16'b1, ACK = 16'b100; 
	 
	 // The opcode register
	 reg [7:0] opcode [1:0];
	 reg [1:0] counter; 
	 
	 // Assert opcode results
	 wire [15:0] op = { opcode[0], opcode[1] };
	 assign req = op == REQ;
	 assign ack = op == ACK;

	always@(posedge clk)
		begin
			// Reset if necessary
			if(reset) begin 
				opcode[0] <= 8'b0;
				opcode[1] <= 8'b0;
				counter <= 2'b0;
			end else if(en & ~counter[1]) begin
				// Store opcode into registers		
				opcode[1] <= eth_data;
				opcode[0] <= opcode[1]; 
				counter <= counter + 2'b1;
			end
		end
endmodule
