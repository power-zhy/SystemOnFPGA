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
	output wire full_w,  // full flag
	output wire near_full_w,  // near full flag (only one space left)
	output wire [ADDR_BITS-1:0] space_count,  // free space count
	// data reading
	input wire clk_r,  // read clock
	input wire en_r,  // read enable
	output reg [DATA_BITS-1:0] data_r,  // data from read
	output wire empty_r,  // empty flag
	output wire near_empty_r,  // near empty flag (only one data left)
	output wire [ADDR_BITS-1:0] data_count  // available data count
	);
	
	parameter
		DATA_BITS = 32,  // data length
		ADDR_BITS = 8;  // address length
	
	reg [DATA_BITS-1:0] data [0:(1<<ADDR_BITS)-1];
	reg [ADDR_BITS-1:0] ptr_w = 0;
	reg [ADDR_BITS-1:0] ptr_r = 0;
	
	reg [DATA_BITS-1:0] read_buf, write_buf, write_buf2;
	
	// read source
	// 0: FIFO is empty, no source available, but should be careful when data written in
	// 1: FIFO has only one data and is being read, must refer to whether there is data written at the same time
	// 2: Other situation, just read data from array
	reg [1:0] read_src = 0;
	
	// data writing
	always @(posedge clk_w) begin
		if (empty_r && en_w) begin
			write_buf <= data_w;
			write_buf2 <= data_w;
		end
		else if (near_empty_r && en_w) begin
			write_buf2 <= data_w;
		end
	end
	
	always @(posedge clk_w) begin
		if (rst) begin
			ptr_w <= 0;
		end
		else begin
			if (en_w && ~full_w) begin
				data[ptr_w] <= data_w;
				ptr_w <= ptr_w + 1'h1;
			end
		end
	end
	
	// data reading
	always @(posedge clk_r) begin
		read_buf <= data[en_r ? ptr_r + 1'h1 : ptr_r];  // let data_r be available 1 cycle after en_r utters, otherwise normal block RAM need 2 cycle
	end
	
	always @(posedge clk_r) begin
		if (rst) begin
			ptr_r <= 0;
			read_src <= 0;
		end
		else begin
			if (empty_r)
				read_src <= 0;
			else if (near_empty_r && en_r)
				read_src <= 1;
			else
				read_src <= 2;
			if (en_r && ~empty_r) begin
				ptr_r <= ptr_r + 1'h1;
			end
		end
	end
	
	// ensure data_r be available immediately at the negative edge of empty_r
	always @(*) begin
		case (read_src)
			0: data_r = write_buf;
			1: data_r = (~empty_r) ? write_buf2 : write_buf;
			default: data_r = read_buf;
		endcase
	end
	
	// full/empty detect
	assign
		full_w = (ptr_w + 1'h1 == ptr_r),
		near_full_w = (ptr_w + 2'h2 == ptr_r),
		empty_r = (ptr_w == ptr_r),
		near_empty_r = (ptr_w == ptr_r + 1'h1);
	
	assign
		space_count = ptr_r - (ptr_w + 1'h1),
		data_count = ptr_w - ptr_r;
	
endmodule
