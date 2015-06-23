`timescale 1ns / 1ps
// Robbie Litchfield
// Behavioural Implementation of RAM module using BLockRAM
module mem_access(
    input clk,
    input reset,
    input queue_ready,
	 input [31:0] queue_data,
	 input read_request, // High when you want data from memory
    output reg read_queue_ready,
	 output reg dr,
	 output reg dv,
    output [7:0] data
    );
	 
	 parameter IDLE = 3'b0, GETOP = 3'b1, STOREOP = 3'b10, WAIT = 3'b11, DATA = 3'b100; 
	 reg [2:0] state, nextState;
	 reg [15:0] length;
	 reg [15:0] block;
	 reg [15:0] counter;
	 reg [RAM_ADDR_BITS-1:0] addr;
	 reg [RAM_WIDTH-1:0] data_r;
	 reg ram_en;
	 
	// State transitions
	always @(posedge clk) begin 
		state <= nextState;
		if(reset) begin
			state <= IDLE;
			nextState <= IDLE;
		end else begin
			case (state) 
				IDLE:
					if(queue_ready)
						nextState <= GETOP;
				GETOP:
					nextState <= STOREOP;
				STOREOP: 
					nextState <= WAIT;
				WAIT:
					if(read_request)
						if(length != 0)
							nextState <= DATA;
						else
							nextState <= IDLE;
				DATA:
					if(counter == (length - 1))
						nextState <= IDLE;
			endcase
		end
	end
	
	// Logic
	always@(*) begin
		read_queue_ready <= 0;
		dv <= 0;
		dr <= 0;
		case (state)
			IDLE:
				begin
					length <= 0;
					block <= 0;
					addr <= 0;
					ram_en <= 0;
					counter <= 0;
				end
			GETOP:	
				read_queue_ready <= 1;
			STOREOP:
				begin
					length <= queue_data[15:0];
					block <= (queue_data[31:16] - 16'b1);
				end
			WAIT:
				dr <= 1;
			DATA:
				begin
					ram_en <= 1;
					addr <= (block * 512) + counter;
					counter <= counter + 1;
				end
		endcase
	end

	// ----------------- BLOCK RAM ------------------
   parameter RAM_WIDTH = 8;
   parameter RAM_ADDR_BITS = 16;
   
   (* RAM_STYLE="{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
   reg [RAM_WIDTH-1:0] ISO [(2**RAM_ADDR_BITS)-1:0];
	assign data = data_r;

   //  The forllowing code is only necessary if you wish to initialize the RAM 
   //  contents via an external file (use $readmemb for binary data)
   initial
      $readmemh("TinyCore-current.hex", ISO);

   always @(posedge clk)
		if(reset)
			data_r <= 8'b0;
      else if (ram_en)
			data_r <= ISO[addr];
endmodule
