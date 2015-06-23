`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:42:06 06/06/2013 
// Design Name: 
// Module Name:    tftp_decode_controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tftp_decode_controller(
    input clk,
    input reset,
    input [7:0] cnt,
    input [7:0] eth_data,
    input ack,
    input req,
    output reg idle_en,
    output reg opcode_en,
    output reg blockno_en,
    output reg filename_en,
    output reg mode_en
    );
	 
	  // The state machine states
	 //parameter IDLE = 5'b00001, OPCODE = 5'b00010, BLOCKNO = 5'b00100, FILENAME = 5'b01000, MODE = 5'b10000;
	 parameter IDLE = 3'b0, OPCODE = 3'b001, BLOCKNO = 3'b011, FILENAME = 5'b010, MODE = 3'b110; // Faster
	 reg[4:0] state, nextState;
	 
	
	// Perform state transition
	always @(posedge clk) 		
		if	(reset) begin
			state <= IDLE;
			nextState <= IDLE;
		end
		else 		  state <= nextState;
	// Calculate next state
	always @(posedge clk)
		// Calculate possible transitions
		begin
			case(state)
				IDLE:
					if(cnt == 8'h2A)
						nextState <= OPCODE;
				OPCODE:
					if(cnt == 8'h2C) 
						if(ack)
							nextState <= BLOCKNO;
						else if(req)
							nextState <= FILENAME;
						else
							// This is an error
							nextState <= IDLE;

				BLOCKNO:
					if(cnt == 8'h2E)
						nextState <= IDLE;
				FILENAME:
					if(eth_data == 8'b0)
						nextState <= MODE;
				MODE:
					if(eth_data == 8'b0)
						nextState <= IDLE;
					else
						nextState <= MODE;
			endcase
		end
	
	// Perform continuous logic
	always @(*) begin
		// Assume no signals asserted
		idle_en <= 1'b0;
      opcode_en <= 1'b0;
      blockno_en <= 1'b0;
      filename_en <= 1'b0;
      mode_en <= 1'b0;
	
		case (state) 
			IDLE:
				begin
					idle_en <= 1'b1;
				end
			OPCODE:
				begin
					opcode_en <= 1'b1;
				end
			BLOCKNO:
				begin
					blockno_en <= 1'b1;
				end
			FILENAME:
				begin
					filename_en <= 1'b1;
				end
			MODE:
				begin
					mode_en <= 1'b1;
				end
		endcase
	end



endmodule
