`include "define.vh"


/**
 * Buffer with two lines, one for reading and another for preparing, so it is safe to use two clocks.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module buffer_2l (
	input wire clk,  // main clock
	input wire switch,  // line switch
	// data writing
	input wire clk_w,  // write clock
	input wire en_w,  // write enable
	input wire [ADDR_BITS-1:0] addr_w,  // address to write
	input wire [DATA_BITS-1:0] data_w,  // data to write
	// data reading
	input wire clk_r,  // read clock
	input wire [ADDR_BITS-1:0] addr_r,  // address to read
	output wire [DATA_BITS-1:0] data_r  // data from read
	);
	
	parameter
		DATA_BITS = 32,  // data length
		ADDR_BITS = 8;  // address length
	
	reg line = 0;  // write one line and read another line
	reg [DATA_BITS-1:0] data_a [0:(1<<ADDR_BITS)-1];
	reg [DATA_BITS-1:0] data_b [0:(1<<ADDR_BITS)-1];
	reg [DATA_BITS-1:0] data_ra, data_rb;
	
	always @(posedge clk) begin
		if (switch)
			line <= ~line;
	end
	
	always @(posedge clk_w) begin
		if (en_w) begin
			if (line)
				data_b[addr_w] <= data_w;
			else
				data_a[addr_w] <= data_w;
		end
	end
	
	always @(posedge clk_r) begin
		data_ra <= data_a[addr_r];
		data_rb <= data_b[addr_r];
	end
	
	assign
		data_r = line ? data_ra : data_rb;
	
endmodule
