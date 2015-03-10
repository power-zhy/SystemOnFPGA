`include "define.vh"


/**
 * UART TX part for sending data only.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module uart_core_tx (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire [BAUD_DIV_WIDTH-1:0] baud_div,  // baud rate division, should be 10M/8/baudrate-1
	input wire [1:0] data_type,  // type for number of data bits, 00 for eight, 01 for seven, 10 for six, 11 for five
	input wire [1:0] stop_type,  // type for number of stop bits, 00 for one, 01 for one and a half, 10 for two
	input wire check_en,  // whether to use data checking or not
	input wire [1:0] check_type,  // data checking type, 00 for odd, 01 for even, 10 for mark, 11 for space
	input wire en,  // enable signal, flag to start transmitting
	input wire [DATA_BITS_MAX-1:0] data,  // data to send out
	output reg busy,  // busy flag
	output reg ack,  // data sent acknowledge
	// UART TX interface
	output reg tx = 1
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100,  // main clock frequency in MHz, should be multiple of 10M
		BAUD_DIV_WIDTH = 8;  // width for baud rate division
	localparam
		DATA_BITS_MAX = 8,  // maximum data length for transmit
		STOP_BITS_MAX = 2,  // maximum stop flag length
		SAMPLE_COUNT = 8,
		SAMPLE_COUNT_WIDTH = GET_WIDTH(SAMPLE_COUNT-1),
		CLK_DIV = CLK_FREQ / 10,
		CLK_DIV_WIDTH = GET_WIDTH(CLK_DIV-1),
		TRANS_BITS_MAX = DATA_BITS_MAX + STOP_BITS_MAX + 2,
		TRANS_BITS_WIDTH = GET_WIDTH(TRANS_BITS_MAX);
	
	reg check_bit;
	reg [TRANS_BITS_WIDTH-1:0] trans_bits;  // number of actual transmitting bits - 1
	reg [TRANS_BITS_MAX-1:0] data_buf;
	reg [CLK_DIV_WIDTH-1:0] clk_count = 0;
	reg [BAUD_DIV_WIDTH-1:0] hns_count = 0;
	reg [SAMPLE_COUNT_WIDTH-1:0] sample_count = 0;
	reg bit_done;
	reg [TRANS_BITS_WIDTH-1:0] bit_count = 0;
	
	always @(*) begin
		case (data_type)  // regard one and a half stop bits as two
			2'b00: case (stop_type)
				2'b00: trans_bits = check_en ? 4'd10 : 4'd9;
				default: trans_bits = check_en ? 4'd11 : 4'd10;
			endcase
			2'b01: case (stop_type)
				2'b00: trans_bits = check_en ? 4'd9 : 4'd8;
				default: trans_bits = check_en ? 4'd10 : 4'd9;
			endcase
			2'b10: case (stop_type)
				2'b00: trans_bits = check_en ? 4'd8 : 4'd7;
				default: trans_bits = check_en ? 4'd9 : 4'd8;
			endcase
			2'b11: case (stop_type)
				2'b00: trans_bits = check_en ? 4'd7 : 4'd6;
				default: trans_bits = check_en ? 4'd8 : 4'd7;
			endcase
		endcase
	end
	
	always @(*) begin
		if (check_en) begin
			case (check_type)
				2'b00: begin
					case (data_type)
						2'b00: check_bit = ~(^data[7:0]);
						2'b01: check_bit = ~(^data[6:0]);
						2'b10: check_bit = ~(^data[5:0]);
						2'b11: check_bit = ~(^data[4:0]);
					endcase
				end
				2'b01: begin
					case (data_type)
						2'b00: check_bit = (^data[7:0]);
						2'b01: check_bit = (^data[6:0]);
						2'b10: check_bit = (^data[5:0]);
						2'b11: check_bit = (^data[4:0]);
					endcase
				end
				2'b10: check_bit = 1;
				2'b11: check_bit = 0;
			endcase
		end
		else begin
			check_bit = 0;
		end
	end
	
	always @(posedge clk) begin
		bit_done <= 0;
		ack <= 0;
		if (rst) begin
			clk_count <= 0;
			hns_count <= 0;
			sample_count <= 0;
			bit_count <= 0;
		end
		else if (busy) begin
			if (clk_count != CLK_DIV-1) begin
				clk_count <= clk_count + 1'h1;
			end
			else begin
				clk_count <= 0;
				if (hns_count != baud_div) begin
					hns_count <= hns_count + 1'h1;
				end
				else begin
					hns_count <= 0;
					if (sample_count != SAMPLE_COUNT-1) begin
						sample_count <= sample_count + 1'h1;
					end
					else begin
						sample_count <= 0;
						bit_done <= 1;
						if (bit_count != trans_bits) begin
							bit_count <= bit_count + 1'h1;
						end
						else begin
							bit_count <= 0;
							ack <= 1;
						end
					end
				end
			end
		end
		else begin
			clk_count <= 0;
			hns_count <= 0;
			sample_count <= 0;
			bit_count <= 0;
		end
	end
	
	localparam
		S_IDLE = 0,  // idle
		S_LOAD = 1,  // load data, prepare for sending
		S_TRANS = 2;  // send data
	
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
				next_state = S_TRANS;
			end
			S_TRANS: begin
				if (ack)
					next_state = S_IDLE;
				else
					next_state = S_TRANS;
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
			busy <= 0;
			data_buf <= 0;
			tx <= 1;
		end
		else case (next_state)
			S_IDLE: begin
				busy <= 0;
				data_buf <= 0;
				tx <= 1;
			end
			S_LOAD: begin
				busy <= 1;
				case (data_type)
					2'b00: data_buf <= {2'b11, check_en?check_bit:1'b1, data[7:0], 1'b0};
					2'b01: data_buf <= {3'b111, check_en?check_bit:1'b1, data[6:0], 1'b0};
					2'b10: data_buf <= {4'b1111, check_en?check_bit:1'b1, data[5:0], 1'b0};
					2'b11: data_buf <= {5'b11111, check_en?check_bit:1'b1, data[4:0], 1'b0};
				endcase
				tx <= 1;  // TX is one clock after busy, as data_buf is also one clock after bit_done
			end
			S_TRANS: begin
				busy <= 1;
				if (bit_done)
					data_buf <= {1'b1, data_buf[TRANS_BITS_MAX-1:1]};
				tx <= data_buf[0];
			end
		endcase
	end
	
endmodule
