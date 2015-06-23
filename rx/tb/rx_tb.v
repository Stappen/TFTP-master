// Verilog Test Fixture Template

  `timescale 1 ns / 1 ps

  module rx_tb;
          // Inputs
	reg clk;
   reg reset_n;
   reg [47:0] macaddr;
   reg [31:0] ipv4addr;
   reg  dv;
   reg  er;
   reg [7:0] rxd;


	// Outputs
	wire [47:0] eth_src;
	wire [31:0] ip_src;
	wire [15:0]	udp_src;
	wire [15:0]	tid;
	wire [15:0] tftp_block;
	wire [9:0]	block_len;
	wire ready_n_tftp;
	wire [63:0]	header;
   wire [47:0] sha;
   wire [31:0] spa;
   wire [47:0] tha;
   wire [31:0] tpa;
   wire ready_n_arp;

	// Instantiate the Unit Under Test (UUT)
	rx_wrapper uut (
		.clk(clk),
		.reset_n(reset_n),
		.macaddr(macaddr),
		.ipv4addr(ipv4addr),
		.dv(dv),
		.er(er),
		.rxd(rxd),
		.eth_src(eth_src),
		.ip_src(ip_src),
		.udp_src(udp_src),
		.tid(tid),
		.tftp_block(tftp_block),
		.block_len(block_len),
		.ready_n_tftp(ready_n_tftp),
		.header(header),
		.sha(sha),
		.spa(spa),
		.tha(tha),
		.tpa(tpa),
		.ready_n_arp(ready_n_arp)
	);

   parameter PERIOD = 50;

   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end  

	reg [7:0] FILENAME [125:0];
	initial $readmemh("requestfull.hex", FILENAME);
integer i;
integer r;

	initial begin
	
	// Initialize Inputs
		clk = 0;
		reset_n = 0;
		macaddr = 48'h180373b84b27;
		ipv4addr = 32'h82d9dc1b;
		dv = 0;
		er = 0;
		rxd = 8'b0;
		// Wait 100 ns for global reset to finish
		#PERIOD;
		reset_n = 1;
		#PERIOD;
	
	for(r = 0; r < 3; r = r + 1)
		begin
			dv = 1;
			// Add stimulus here
			for (i = 0; i < 126; i=i+1) begin
				// Feed in data
				rxd = FILENAME[i];
			
				// Wait for clock
				#PERIOD;
		end
		rxd = 0;
		dv = 0;

		end
		

	end
  endmodule