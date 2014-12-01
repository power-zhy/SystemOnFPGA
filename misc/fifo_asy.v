`include "define.vh"


/**
 * Asynchronous FIFO, read data is ready without read enable signal, and would be changed at the next positive edge of read clock after it.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module fifo_asy (
	input wire rst,  // synchronous reset
	// data writing
	input wire clk_w,  // write clock
	input wire en_w,  // write enable
	input wire [DATA_BITS-1:0] data_w,  // data to write
	output reg full_w = 1,  // full flag
	output reg near_full_w = 1,  // near full flag (only one space left)
	output reg [ADDR_BITS-1:0] space_count = 0,  // free space count
	// data reading
	input wire clk_r,  // read clock
	input wire en_r,  // read enable
	output reg [DATA_BITS-1:0] data_r,  // data from read
	output reg empty_r = 1,  // empty flag
	output reg near_empty_r = 1,  // near empty flag (only one data left)
	output reg [ADDR_BITS-1:0] data_count = 0  // available data count
	);
	
	parameter
		DATA_BITS = 32,  // data length
		ADDR_BITS = 8;  // address length
	
	reg [DATA_BITS-1:0] data [0:(1<<ADDR_BITS)-1];
	reg [ADDR_BITS-1:0] ptr_w = 0, ptr_w_next;
	reg [ADDR_BITS-1:0] ptr_r = 0, ptr_r_next;
	
	// data write
	always @(*) begin
		ptr_w_next = ptr_w;
		if (en_w && ~full_w)
			ptr_w_next = ptr_w + 1'h1;
	end
	
	always @(posedge clk_w) begin
		if (rst)
			ptr_w <= 0;
		else
			ptr_w <= ptr_w_next;
	end
	
	always @(posedge clk_w) begin
		if (en_w && ~full_w)
			data[ptr_w] <= data_w;
	end
	
	// data read
	always @(*) begin
		ptr_r_next = ptr_r;
		if (en_r && ~empty_r)
			ptr_r_next = ptr_r + 1'h1;
	end
	
	always @(posedge clk_r) begin
		if (rst)
			ptr_r <= 0;
		else
			ptr_r <= ptr_r_next;
	end
	
	always @(posedge clk_r) begin
		data_r <= data[ptr_r_next];
	end
	
	// full/empty detect
	always @(posedge clk_w) begin
		if (rst) begin
			full_w <= 1;
			near_full_w <= 1;
			space_count <= 0;
		end
		else begin
			full_w <= (ptr_w_next + 1'h1 == ptr_r);
			near_full_w <= (ptr_w_next + 2'h2 == ptr_r);
			space_count <= ptr_r - (ptr_w_next + 1'h1);
		end
	end
	
	always @(posedge clk_r) begin
		if (rst) begin
			empty_r <= 1;
			near_empty_r <= 1;
			data_count <= 0;
		end
		else begin
			empty_r <= (ptr_w == ptr_r_next);
			near_empty_r <= (ptr_w == ptr_r_next + 1'h1);
			data_count <= ptr_w - ptr_r_next;
		end
	end
	
endmodule
