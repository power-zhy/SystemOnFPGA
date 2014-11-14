`include "define.vh"

/**
 * Search the bit "target" in a bit array "bits", and return the index of first target bit found.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */


module bit_searcher_2 (
	input wire [1:0] bits,
	input wire target,
	input wire direction,
	output wire hit,
	output reg index
	);
	
	assign hit = (bits[1:0] != {2{~target}});
	always @(*) begin
		if (direction) begin
			if (bits[1] == ~target)
				index = 1'b0;
			else
				index = 1'b1;
		end
		else begin
			if (bits[0] == ~target)
				index = 1'b1;
			else
				index = 1'b0;
		end
	end
	
endmodule


module bit_searcher_4 (
	input wire [3:0] bits,
	input wire target,
	input wire direction,
	output wire hit,
	output reg [1:0] index
	);
	
	assign hit = (bits[3:0] != {4{~target}});
	always @(*) begin
		if (direction) begin
			if (bits[3:1] == {3{~target}})
				index = 2'b00;
			else if (bits[3:2] == {2{~target}})
				index = 2'b01;
			else if (bits[3] == ~target)
				index = 2'b10;
			else
				index = 2'b11;
		end
		else begin
			if (bits[2:0] == {3{~target}})
				index = 2'b11;
			else if (bits[1:0] == {2{~target}})
				index = 2'b10;
			else if (bits[0] == ~target)
				index = 2'b01;
			else
				index = 2'b00;
		end
	end
	
endmodule


module bit_searcher_16 (
	input wire [15:0] bits,
	input wire target,
	input wire direction,
	output wire hit,
	output wire [3:0] index
	);
	
	wire [3:0] hit_inner;
	wire [1:0] index_inner [3:0];
	wire [1:0] index_upper;
	
	bit_searcher_4
		BS0 (.bits(bits[3:0]), .target(target), .direction(direction), .hit(hit_inner[0]), .index(index_inner[0])),
		BS1 (.bits(bits[7:4]), .target(target), .direction(direction), .hit(hit_inner[1]), .index(index_inner[1])),
		BS2 (.bits(bits[11:8]), .target(target), .direction(direction), .hit(hit_inner[2]), .index(index_inner[2])),
		BS3 (.bits(bits[15:12]), .target(target), .direction(direction), .hit(hit_inner[3]), .index(index_inner[3]));
	bit_searcher_4
		BS4 (.bits(hit_inner[3:0]), .target(1'b1), .direction(direction), .hit(hit), .index(index_upper));
	
	assign index = {index_upper, index_inner[index_upper]};
	
endmodule


module bit_searcher_64 (
	input wire [63:0] bits,
	input wire target,
	input wire direction,
	output wire hit,
	output wire [5:0] index
	);
	
	wire [3:0] hit_inner;
	wire [3:0] index_inner [3:0];
	wire [1:0] index_upper;
	
	bit_searcher_16
		BS0 (.bits(bits[15:0]), .target(target), .direction(direction), .hit(hit_inner[0]), .index(index_inner[0])),
		BS1 (.bits(bits[31:16]), .target(target), .direction(direction), .hit(hit_inner[1]), .index(index_inner[1])),
		BS2 (.bits(bits[47:32]), .target(target), .direction(direction), .hit(hit_inner[2]), .index(index_inner[2])),
		BS3 (.bits(bits[63:48]), .target(target), .direction(direction), .hit(hit_inner[3]), .index(index_inner[3]));
	bit_searcher_4
		BS4 (.bits(hit_inner[3:0]), .target(1'b1), .direction(direction), .hit(hit), .index(index_upper));
	
	assign index = {index_upper, index_inner[index_upper]};
	
endmodule


module bit_searcher_256 (
	input wire [255:0] bits,
	input wire target,
	input wire direction,
	output wire hit,
	output wire [7:0] index
	);
	
	wire [3:0] hit_inner;
	wire [5:0] index_inner [3:0];
	wire [1:0] index_upper;
	
	bit_searcher_64
		BS0 (.bits(bits[63:0]), .target(target), .direction(direction), .hit(hit_inner[0]), .index(index_inner[0])),
		BS1 (.bits(bits[127:64]), .target(target), .direction(direction), .hit(hit_inner[1]), .index(index_inner[1])),
		BS2 (.bits(bits[191:128]), .target(target), .direction(direction), .hit(hit_inner[2]), .index(index_inner[2])),
		BS3 (.bits(bits[255:192]), .target(target), .direction(direction), .hit(hit_inner[3]), .index(index_inner[3]));
	bit_searcher_4
		BS4 (.bits(hit_inner[3:0]), .target(1'b1), .direction(direction), .hit(hit), .index(index_upper));
	
	assign index = {index_upper, index_inner[index_upper]};
	
endmodule


module bit_searcher_32 (
	input wire [31:0] bits,
	input wire target,
	input wire direction,
	output wire hit,
	output wire [4:0] index
	);
	
	wire [1:0] hit_inner;
	wire [3:0] index_inner [3:0];
	wire index_upper;
	
	bit_searcher_16
		BS0 (.bits(bits[15:0]), .target(target), .direction(direction), .hit(hit_inner[0]), .index(index_inner[0])),
		BS1 (.bits(bits[31:16]), .target(target), .direction(direction), .hit(hit_inner[1]), .index(index_inner[1]));
	bit_searcher_2
		BS4 (.bits(hit_inner[1:0]), .target(1'b1), .direction(direction), .hit(hit), .index(index_upper));
	
	assign index = {index_upper, index_inner[index_upper]};
	
endmodule


module bit_searcher (
	input wire [N-1:0] bits,  // data being searched
	input wire target,  // search target
	input wire direction,  // search direction, 0 for lower to upper and 1 otherwise
	output wire hit,  // target found flag
	output wire [W-1:0] index  // index of target in data
	);
	
	`include "function.vh"
	parameter
		N = 32;
	localparam
		W = GET_WIDTH(N-1);
	
	generate begin: BS_GEN
		case (N)
			2: bit_searcher_2 BS_2 (.bits(bits), .target(target), .direction(direction), .hit(hit), .index(index));
			4: bit_searcher_4 BS_4 (.bits(bits), .target(target), .direction(direction), .hit(hit), .index(index));
			16: bit_searcher_16 BS_16 (.bits(bits), .target(target), .direction(direction), .hit(hit), .index(index));
			32: bit_searcher_32 BS_32 (.bits(bits), .target(target), .direction(direction), .hit(hit), .index(index));
			64: bit_searcher_64 BS_64 (.bits(bits), .target(target), .direction(direction), .hit(hit), .index(index));
			256: bit_searcher_256 BS_256 (.bits(bits), .target(target), .direction(direction), .hit(hit), .index(index));
			default: initial $display("Error: Illegal bit length %0d", N);
		endcase
	end
	endgenerate
	
endmodule
