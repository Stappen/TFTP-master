`timescale 1ns / 1ps

// AUTHOR: Robbie Litchfield
// TFTP Server
// TFTP Decode module
module tftp_decode(
    input clk,
    input reset,
    input [7:0] cnt, // The byte count offset in the packet
    input [7:0] eth_data, // The ether data
    input [15:0] udp_dst, // The destination UDP port
    output valid, // The valid signal
    output [15:0] tid, // The TFTP tid and location in memory
    output [15:0] next_block_no, // The next block number
	 output [15:0] length // The length of the next block (0 - 512)
    );
	 
	/*// Setup controller
	wire ack, req, idle_en, opcode_en, blockno_en, filename_en, mode_en;
	wire [7:0] shiftcnt = (cnt+8'b1);
	tftp_decode_controller controller(clk, reset, shiftcnt, eth_data, ack, 
						req, idle_en, opcode_en, blockno_en, filename_en, mode_en);*/
	parameter START = 8'h29;
	wire en = (cnt >= START);
						
	// Setup opcode decoder
	opcode_decode opcode(clk, reset, en, eth_data, ack, req);
	 					
	// --- REQ decoder ---
	// Setup filename decoder
	wire file_valid, valid_ack_port;
	wire [15:0] req_tid;
	filename_decode filename(clk, reset, req, eth_data, file_valid, req_tid, udp_dst, valid_ack_port);
	
	// Dest port check
	parameter TFTPPORT = 16'h45;
	wire valid_req_port = udp_dst == TFTPPORT;
	
	// Setup mode decoder
	wire mode_valid;
	mode_decode mode(clk, reset, file_valid, eth_data, mode_valid);
	
	// Checl for valid req packet
	wire req_v = file_valid & valid_req_port & mode_valid & req;
	
	// --- ACK decoder ---
	wire [15:0] block;
	wire block_valid;
	// Setup blockno decoder
	blockno_decode blockno(clk, reset, ack, eth_data, block_valid, block);
	
	// Check for valid ack packet
	wire ack_v = valid_ack_port & block_valid & ack;
	
	// Assert results
	// The length of CORE iso in bytes (Perfectly fits into 512 blocks)
	parameter COREBLOCKS = 16'h6000;
	assign valid = ack_v | req_v;
	assign tid = ack_v ? udp_dst : 
					 req_v ? req_tid :
					 16'b0;
	assign next_block_no = ack_v ? (block + 16'b1) :
							req_v ? 16'b1 :
							16'b0;
	// Terminate with block of size 0
	assign length = (next_block_no > COREBLOCKS) ? 16'b0 : 16'h200;
	
	
				
	
	 
	 
	 
	 

endmodule
