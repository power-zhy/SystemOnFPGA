`include "define.vh"


/**
 * Data cache core.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module cache (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire [ADDR_BITS-1:0] addr,  // address
	input wire store,  // set valid to 1 and reset dirty to 0
	input wire [WORD_BYTES-1:0] edit,  // set dirty to 1
	input wire invalid,  // reset valid to 0
	input wire [WORD_BITS-1:0] din,  // data write in
	output wire hit,  // hit or not
	output reg [WORD_BITS-1:0] dout,  // data read out
	output reg valid,  // valid bit
	output reg dirty,  // dirty bit
	output reg [TAG_BITS-1:0] tag,  // tag bits
	output reg [LINE_NUM-1:0] dirty_map  // dirty bits of all cache lines
	);
	
	`include "function.vh"
	parameter
		ADDR_BITS = 32,  // address length
		WORD_BYTES = 4,  // number of bytes per-word
		LINE_WORDS = 4,  // number of words per-line
		LINE_NUM = 64;  // number of lines in cache, must be the power of 2
	localparam
		WORD_BITS = 8 * WORD_BYTES,  // 32
		LINE_WORDS_WIDTH = GET_WIDTH(LINE_WORDS-1),  // 2
		WORD_BYTES_WIDTH = GET_WIDTH(WORD_BYTES-1),  // 2
		LINE_INDEX_WIDTH = GET_WIDTH(LINE_NUM-1),  // 6
		TAG_BITS = ADDR_BITS - LINE_INDEX_WIDTH - LINE_WORDS_WIDTH - WORD_BYTES_WIDTH;  // 22
	
	reg [LINE_NUM-1:0] inner_valid = 0;
	reg [LINE_NUM-1:0] inner_dirty = 0;
	reg [TAG_BITS-1:0] inner_tag [0:LINE_NUM-1];
	
	genvar i;
	generate for (i=0; i<WORD_BYTES; i=i+1) begin: DATA_CONTENT
		reg [7:0] inner_data [0:LINE_NUM*LINE_WORDS-1];
		always @(negedge clk) begin
			dout[8*i+7-:8] <= inner_data[addr[ADDR_BITS-TAG_BITS-1:WORD_BYTES_WIDTH]];
			if (store || (edit[i] && hit))
				inner_data[addr[ADDR_BITS-TAG_BITS-1:WORD_BYTES_WIDTH]] <= din[8*i+7-:8];
		end
	end
	endgenerate
	
	always @(negedge clk) begin
		if (rst) begin
			inner_valid <= 0;
			inner_dirty <= 0;
		end
		else if (invalid) begin
			inner_valid[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]] <= 0;
			inner_dirty[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]] <= 0;
		end
		else if (store) begin
			inner_valid[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]] <= 1;
			inner_dirty[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]] <= 0;
			inner_tag[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]] <= addr[ADDR_BITS-1:ADDR_BITS-TAG_BITS];
		end
		else if (|edit && hit) begin
			inner_dirty[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]] <= 1;
		end
	end
	
	always @(*) begin
		valid = inner_valid[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]];
		dirty = inner_dirty[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]];
		tag = inner_tag[addr[ADDR_BITS-TAG_BITS-1:LINE_WORDS_WIDTH+WORD_BYTES_WIDTH]];
		dirty_map = inner_dirty;
	end
	
	assign hit = valid & (tag == addr[ADDR_BITS-1:ADDR_BITS-TAG_BITS]);
	
endmodule
