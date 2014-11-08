`include "define.vh"


/**
 * Register File for MIPS CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module regfile (
	input wire clk,  // main clock
	// debug
	`ifdef DEBUG
	input wire [ADDR_BITS-1:0] debug_addr,  // debug address
	output reg [DATA_BITS-1:0] debug_data,  // debug data
	`endif
	// read channel A
	input wire [ADDR_BITS-1:0] addr_a,
	output reg [DATA_BITS-1:0] data_a,
	// read channel B
	input wire [ADDR_BITS-1:0] addr_b,
	output reg [DATA_BITS-1:0] data_b,
	// write channel W
	input wire en_w,
	input wire [ADDR_BITS-1:0] addr_w,
	input wire [DATA_BITS-1:0] data_w
	);
	
	parameter
		ADDR_BITS = 5,
		DATA_BITS = 32;
	
	reg [DATA_BITS-1:0] regfile [1:(1<<ADDR_BITS)-1];  // $zero is always zero
	
	// write
	always @(posedge clk) begin
		if (en_w && addr_w != 0)
			regfile[addr_w] <= data_w;
	end
	
	// read
	always @(negedge clk) begin
		data_a <= addr_a == 0 ? 0 : regfile[addr_a];
		data_b <= addr_b == 0 ? 0 : regfile[addr_b];
	end
	/*always @(*) begin
		data_a = addr_a == 0 ? 0 : regfile[addr_a];
		data_b = addr_b == 0 ? 0 : regfile[addr_b];
	end*/
	
	// debug
	`ifdef DEBUG
	always @(negedge clk) begin
		debug_data <= debug_addr == 0 ? 0 : regfile[debug_addr];
	end
	/*always @(*) begin
		debug_data = debug_addr == 0 ? 0 : regfile[debug_addr];
	end*/
	`endif
	
endmodule
