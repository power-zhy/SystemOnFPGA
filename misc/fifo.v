`include "define.vh"


/**
 * Synchronous FIFO, read data is ready without read enable signal, but will be changed 1 cycle after detecting it.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module fifo (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// data writing
	input wire en_w,  // write enable
	input wire [DATA_BITS-1:0] data_w,  // data to write
	output reg full_w,  // full flag
	output reg near_full_w,  // near full flag (only one space left)
	output reg [ADDR_BITS-1:0] space_count,  // free space count
	// data reading
	input wire en_r,  // read enable
	output wire [DATA_BITS-1:0] data_r,  // data from read
	output reg empty_r,  // empty flag
	output reg near_empty_r,  // near empty flag (only one data left)
	output reg [ADDR_BITS-1:0] data_count  // available data count
	);
	
	parameter
		DATA_BITS = 32,  // data length
		ADDR_BITS = 8;  // address length
	parameter
		DETECT_WEN_EDGE = 0,  // use positive edge detection for write enable signal, if used, will not support burst mode
		DETECT_REN_EDGE = 0;  // use positive edge detection for read enable signal, if used, will not support burst mode
	
	reg [DATA_BITS-1:0] data [0:(1<<ADDR_BITS)-1];
	reg [ADDR_BITS-1:0] ptr_w = 0, ptr_w_next;
	reg [ADDR_BITS-1:0] ptr_r = 0, ptr_r_next;
	
	wire wen, ren;
	reg wen_prev, ren_prev;
	
	reg [DATA_BITS-1:0] read_buf, write_buf;
	reg read_src;
	
	always @(posedge clk) begin
		if (rst) begin
			wen_prev <= 0;
			ren_prev <= 0;
		end
		else begin
			wen_prev <= en_w;
			ren_prev <= en_r;
		end
	end
	
	assign
		wen = DETECT_WEN_EDGE ? (~wen_prev & en_w) : en_w,
		ren = DETECT_REN_EDGE ? (~ren_prev & en_r) : en_r;
	
	always @(*) begin
		ptr_w_next = ptr_w;
		ptr_r_next = ptr_r;
		if (wen && ~full_w)
			ptr_w_next = ptr_w + 1'h1;
		if (ren && ~empty_r)
			ptr_r_next = ptr_r + 1'h1;
	end
	
	always @(posedge clk) begin
		if (rst) begin
			ptr_w <= 0;
			ptr_r <= 0;
			read_src <= 0;
		end
		else begin
			ptr_w <= ptr_w_next;
			ptr_r <= ptr_r_next;
			if (empty_r)
				read_src <= 0;
			else if (near_empty_r && ren)
				read_src <= 0;
			else
				read_src <= 1;
		end
	end
	
	always @(posedge clk) begin
		read_buf <= data[ptr_r_next];  // let data_r be available 1 cycle after ren utters, otherwise normal block RAM need 2 cycle
		if (wen && ~full_w) begin
			data[ptr_w] <= data_w;
			write_buf <= data_w;
		end
	end
	
	assign
		data_r = read_src ? read_buf : write_buf;  // data_r should be available immediately at the negative edge of empty_r
	
	always @(posedge clk) begin
		if (rst) begin
			full_w <= 1;
			near_full_w <= 1;
			empty_r <= 1;
			near_empty_r <= 1;
			space_count <= 0;
			data_count <= 0;
		end
		else begin
			full_w <= (ptr_w_next + 1'h1 == ptr_r_next);
			near_full_w <= (ptr_w_next + 2'h2 == ptr_r_next);
			empty_r <= (ptr_w_next == ptr_r_next);
			near_empty_r <= (ptr_w_next == ptr_r_next + 1'h1);
			space_count <= ptr_r_next - (ptr_w_next + 1'h1);
			data_count <= ptr_w_next - ptr_r_next;
		end
	end
	
endmodule
