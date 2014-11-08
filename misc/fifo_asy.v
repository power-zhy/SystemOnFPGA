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
	parameter
		STATE_VIA_CLOCK = 0;  // state output using positive edge of clock
	
	reg [DATA_BITS-1:0] data [0:(1<<ADDR_BITS)-1];
	reg [ADDR_BITS-1:0] ptr_w = 0, ptr_w_next;
	reg [ADDR_BITS-1:0] ptr_r = 0, ptr_r_next;
	
	reg [DATA_BITS-1:0] read_buf, write_buf, write_buf2;
	
	wire full_w_inner, near_full_w_inner;
	wire empty_r_inner, near_empty_r_inner;
	wire [ADDR_BITS-1:0] space_count_inner, data_count_inner;
	reg full_w_buf, near_full_w_buf;
	reg empty_r_buf, near_empty_r_buf;
	reg [ADDR_BITS-1:0] space_count_buf, data_count_buf;
	
	// read source
	// 0: FIFO is empty, no source available, but should be careful when data written in
	// 1: FIFO has only one data and is being read, must refer to whether there is data written at the same time
	// 2: Other situation, just read data from array
	reg [1:0] read_src = 0;
	
	// data writing
	always @(posedge clk_w) begin
		if (empty_r_inner && en_w) begin
			write_buf <= data_w;
			write_buf2 <= data_w;
		end
		else if (near_empty_r_inner && en_w) begin
			write_buf2 <= data_w;
		end
	end
	
	always @(*) begin
		ptr_w_next = ptr_w;
		if (~rst && en_w && ~full_w)
			ptr_w_next = ptr_w + 1'h1;
	end
	
	always @(posedge clk_w) begin
		if (rst)
			ptr_w <= 0;
		else
			ptr_w <= ptr_w_next;
	end
	
	always @(posedge clk_w) begin
		if (~rst && en_w && ~full_w) begin
			data[ptr_w] <= data_w;
		end
	end
	
	// data reading
	always @(*) begin
		ptr_r_next = ptr_r;
		if (~rst && en_r && ~empty_r)
			ptr_r_next = ptr_r + 1'h1;
	end
	
	always @(posedge clk_r) begin
		if (rst)
			ptr_r <= 0;
		else
			ptr_r <= ptr_r_next;
	end
	
	always @(posedge clk_r) begin
		if (rst)
			read_src <= 0;
		else if (empty_r_inner)
			read_src <= 0;
		else if (near_empty_r_inner && en_r)
			read_src <= 1;
		else
			read_src <= 2;
	end
	
	always @(posedge clk_r) begin
		read_buf <= data[ptr_r_next];  // let data_r be available 1 cycle after en_r utters, otherwise normal block RAM need 2 cycle
	end
	
	// ensure data_r be available immediately at the negative edge of empty_r
	always @(*) begin
		case (read_src)
			0: data_r = write_buf;
			1: data_r = (~empty_r_inner) ? write_buf2 : write_buf;
			default: data_r = read_buf;
		endcase
	end
	
	// full/empty detect
	assign
		full_w_inner = (ptr_w + 1'h1 == ptr_r),
		near_full_w_inner = (ptr_w + 2'h2 == ptr_r),
		empty_r_inner = (ptr_w == ptr_r),
		near_empty_r_inner = (ptr_w == ptr_r + 1'h1),
		space_count_inner = ptr_r - (ptr_w + 1'h1),
		data_count_inner = ptr_w - ptr_r;
	
	always @(posedge clk_w) begin
		if (rst) begin
			full_w_buf <= 1;
			near_full_w_buf <= 1;
			space_count_buf <= 0;
		end
		else begin
			full_w_buf <= (ptr_w_next + 1'h1 == ptr_r_next);
			near_full_w_buf <= (ptr_w_next + 2'h2 == ptr_r_next);
			space_count_buf <= ptr_r_next - (ptr_w_next + 1'h1);
		end
	end
	
	always @(posedge clk_r) begin
		if (rst) begin
			empty_r_buf <= 1;
			near_empty_r_buf <= 1;
			data_count_buf <= 0;
		end
		else begin
			empty_r_buf <= (ptr_w_next == ptr_r_next);
			near_empty_r_buf <= (ptr_w_next == ptr_r_next + 1'h1);
			data_count_buf <= ptr_w_next - ptr_r_next;
		end
	end
	
	assign
		full_w = STATE_VIA_CLOCK ? full_w_buf : full_w_inner,
		near_full_w = STATE_VIA_CLOCK ? near_full_w_buf : near_full_w_inner,
		empty_r = STATE_VIA_CLOCK ? empty_r_buf : empty_r_inner,
		near_empty_r = STATE_VIA_CLOCK ? near_empty_r_buf : near_empty_r_inner,
		space_count = STATE_VIA_CLOCK ? space_count_buf : space_count_inner,
		data_count = STATE_VIA_CLOCK ? data_count_buf : data_count_inner;
	
endmodule
