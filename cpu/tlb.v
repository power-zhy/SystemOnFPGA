`include "define.vh"


/**
 * Translation Look-aside Buffer for Memory Management Unit.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module tlb (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire [ENTRY_BITS-1:0] addr_r,  // page number for reading
	output wire hit_r,  // TLB hit flag
	output wire [DATA_BITS-1:0] data_r,  // entry content read out
	input wire en_w,  // write enable signal
	input wire [ENTRY_BITS-1:0] addr_w,  // page number for writing
	input wire [DATA_BITS-1:0] data_w  // entry content write in
	);
	
	`include "function.vh"
	parameter
		ADDR_BITS = 32,  // address length
		ENTRY_BITS = 20,  // entry length
		DATA_BITS = 25,  // data length
		LINE_NUM = 16;  // number of lines in TLB, must be the power of 2
	localparam
		LINE_NUM_WIDTH = GET_WIDTH(LINE_NUM-1);
	
	reg [LINE_NUM-1:0] valid = 0;
	reg [ENTRY_BITS-1:0] entry [0:LINE_NUM-1];
	reg [DATA_BITS-1:0] data [0:LINE_NUM-1];
	wire [LINE_NUM-1:0] hit_inner;
	wire [LINE_NUM_WIDTH-1:0] index_inner;
	
	reg [LINE_NUM_WIDTH-1:0] replace;  // which line to be replaced next
	
	genvar i;
	generate for (i=0; i<LINE_NUM; i=i+1) begin: HIT_JUDGE
		assign hit_inner[i] = valid[i] & (addr_r == entry[i]);
	end
	endgenerate
	
	bit_searcher #(
		.N(LINE_NUM)
		) BS (
		.bits(hit_inner),
		.target(1'b1),
		.direction(1'b0),
		.hit(hit_r),
		.index(index_inner)
		);
	
	assign
		data_r = data[index_inner];
	
	always @(posedge clk) begin
		if (rst) begin
			valid <= 0;
			replace <= 0;
		end
		else if (en_w) begin
			valid[replace] <= 1'b1;
			entry[replace] <= addr_w;
			data[replace] <= data_w;
			if (replace == LINE_NUM-1)
				replace <= 0;
			else
				replace <= replace + 1'h1;
		end
	end
	
endmodule
