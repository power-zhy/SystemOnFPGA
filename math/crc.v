`include "define.vh"


/**
 * General CRC verification
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module crc (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire en,  // calculation enable signal
	input wire [VERI_BITS-1:0] veri_poly,  // generator polynomial coefficients without the highest one, as which is always 1
	input wire [DATA_BITS-1:0] data,  // data to check
	output reg done = 0,  // calculation complete flag
	output reg [VERI_BITS-1:0] crc  // CRC result
	);
	
	`include "function.vh"
	parameter
		VERI_BITS = 32,  // maximum exponent in generator polynomial
		DATA_BITS = 32;  // data length being checked
	localparam
		DATA_BITS_WIDTH = GET_WIDTH(DATA_BITS);
	
	reg [DATA_BITS-1:0] data_buf;
	reg [DATA_BITS_WIDTH-1:0] bit_count;
	
	localparam
		S_IDLE = 0,  // idle
		S_LOAD = 1,  // load data, prepare for calculating
		S_CALC = 2,  // calculating
		S_DONE = 3;  // done
	
	reg [1:0] state = 0;
	reg [1:0] next_state;
	
	always @(*) begin
		next_state = S_IDLE;
		case (state)
			S_IDLE: begin
				if (en)
					next_state = S_LOAD;
				else
					next_state = S_IDLE;
			end
			S_LOAD: begin
				next_state = S_CALC;
			end
			S_CALC: begin
				if (bit_count == DATA_BITS)
					next_state = S_DONE;
				else
					next_state = S_CALC;
			end
			S_DONE: begin
				next_state = S_IDLE;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst)
			state <= 0;
		else
			state <= next_state;
	end
	
	always @(posedge clk) begin
		if (rst) begin
			data_buf <= 0;
			bit_count <= 0;
			crc <= 0;
			done <= 0;
		end
		else case (next_state)
			S_IDLE: begin
				bit_count <= 0;
			end
			S_LOAD: begin
				data_buf <= data;
				bit_count <= 0;
				crc <= 0;
				done <= 0;
			end
			S_CALC: begin
				data_buf <= {data_buf[DATA_BITS-2:0], 1'b0};
				bit_count <= bit_count + 1'h1;
				if (crc[VERI_BITS-1] ^ data_buf[DATA_BITS-1])
					crc <= {crc[VERI_BITS-2:0], 1'b0} ^ veri_poly;
				else
					crc <= {crc[VERI_BITS-2:0], 1'b0};
			end
			S_DONE: begin
				done <= 1;
			end
		endcase
	end
	
endmodule



/**
 * General CRC verification, but receive data bits one by one as a stream
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module crc_stream (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire en,  // enable flag to calculate CRC value
	input wire [VERI_BITS-1:0] veri_poly,  // generator polynomial coefficients without the highest one, as which is always 1
	input wire data,  // data bit to calculate
	output reg [VERI_BITS-1:0] crc  // CRC result
	);
	
	parameter
		VERI_BITS = 32;  // maximum exponent in generator polynomial
	
	always @(posedge clk) begin
		if (rst) begin
			crc <= 0;
		end
		else if (en) begin
			if (crc[VERI_BITS-1] ^ data)
				crc <= {crc[VERI_BITS-2:0], 1'b0} ^ veri_poly;
			else
				crc <= {crc[VERI_BITS-2:0], 1'b0};
		end
	end

endmodule
