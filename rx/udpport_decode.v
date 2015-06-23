`timescale 1ns / 1ps
//AUHTOR: Robbie Litchfield & Thomas Verstappen
// TFTP Decode
// UDPPort decoder
module udpport_decode(
    input clk,
    input reset,
    input [7:0] eth_data,
    input [7:0] cnt,
    output [15:0] dst_port,
    output [15:0] src_port
    );
	 
	 // The UDP port registers
	 reg [7:0] UDP [3:0];
	 
	 // Assert outputs
	 assign dst_port = {UDP[2], UDP[3]};
	 assign src_port = {UDP[0], UDP[1]};
	 
	 parameter START = 8'h21, FINISH = 8'h24;
	 
	 // See if count is within range
	 wire en = ((START <= cnt) & (cnt <= FINISH));
	 
	 // Feed data into registers
	 always@(posedge clk) begin
		if(reset) begin
			UDP[3] <= 8'b0;
			UDP[2] <= 8'b0;
			UDP[1] <= 8'b0;
			UDP[0] <= 8'b0;
		end else if (en) begin
			UDP[3] <= eth_data;
			UDP[2] <= UDP[3];
			UDP[1] <= UDP[2];
			UDP[0] <= UDP[1];
		end
	 end


endmodule
