`include "define.vh"


/**
 * UART TX part for sending data only.
 * Simplified version with 8 data bits, 1 stop bits and no check bit.
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
	input wire [7:0] data,  // data to send out
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
		SAMPLE_COUNT = 8,
		SAMPLE_COUNT_WIDTH = GET_WIDTH(SAMPLE_COUNT-1),
		CLK_DIV = CLK_FREQ / 10,
		CLK_DIV_WIDTH = GET_WIDTH(CLK_DIV-1);
	
	reg bit_done;
	reg [CLK_DIV_WIDTH-1:0] clk_count = 0;
	reg [BAUD_DIV_WIDTH-1:0] hns_count = 0;
	reg [SAMPLE_COUNT_WIDTH-1:0] sample_count = 0;
	
	always @(posedge clk) begin
		bit_done <= 0;
		if (rst || ~busy) begin
			clk_count <= 0;
			hns_count <= 0;
			sample_count <= 0;
		end
		else begin
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
						bit_done <= 1;
						sample_count <= 0;
					end
				end
			end
		end
	end
	
	reg [7:0] data_buf;
	reg check_bit;
	
	always @(*) begin
		check_bit = 0;
		if (check_en) begin
			case (check_type)
				2'b00: begin
					case (data_type)
						2'b00: check_bit = ~(^data_buf[7:0]);
						2'b01: check_bit = ~(^data_buf[6:0]);
						2'b10: check_bit = ~(^data_buf[5:0]);
						2'b11: check_bit = ~(^data_buf[4:0]);
					endcase
				end
				2'b01: begin
					case (data_type)
						2'b00: check_bit = (^data_buf[7:0]);
						2'b01: check_bit = (^data_buf[6:0]);
						2'b10: check_bit = (^data_buf[5:0]);
						2'b11: check_bit = (^data_buf[4:0]);
					endcase
				end
				2'b10: check_bit = 1;
				2'b11: check_bit = 0;
			endcase
		end
	end
	
	localparam
		S_IDLE = 0,
		S_START = 1,
		S_DATA0 = 2,
		S_DATA1 = 3,
		S_DATA2 = 4,
		S_DATA3 = 5,
		S_DATA4 = 6,
		S_DATA5 = 7,
		S_DATA6 = 8,
		S_DATA7 = 9,
		S_CHECK = 10,
		S_STOP0 = 11,
		S_STOP1 = 12,
		S_DONE = 13;
	
	reg [3:0] state = 0;
	reg [3:0] next_state;
	
	always @(*) begin
		next_state = S_IDLE;
		busy = 0;
		case (state)
			S_IDLE: begin
				if (en)
					next_state = S_START;
				else
					next_state = S_IDLE;
			end
			S_START, S_DATA0, S_DATA1, S_DATA2, S_DATA3: begin
				busy = 1;
				if (bit_done)
					next_state = state + 1'h1;
				else
					next_state = state;
			end
			S_DATA4: begin
				busy = 1;
				if (bit_done) begin
					if (data_type == 2'b11) begin
						if (check_en)
							next_state = S_CHECK;
						else
							next_state = S_STOP0;
					end
					else
						next_state = state + 1'h1;
				end
				else begin
					next_state = state;
				end
			end
			S_DATA5: begin
				busy = 1;
				if (bit_done) begin
					if (data_type == 2'b10) begin
						if (check_en)
							next_state = S_CHECK;
						else
							next_state = S_STOP0;
					end
					else
						next_state = state + 1'h1;
				end
				else begin
					next_state = state;
				end
			end
			S_DATA6: begin
				busy = 1;
				if (bit_done) begin
					if (data_type == 2'b01) begin
						if (check_en)
							next_state = S_CHECK;
						else
							next_state = S_STOP0;
					end
					else
						next_state = state + 1'h1;
				end
				else begin
					next_state = state;
				end
			end
			S_DATA7: begin
				busy = 1;
				if (bit_done) begin
					if (check_en)
						next_state = S_CHECK;
					else
						next_state = S_STOP0;
				end
				else begin
					next_state = state;
				end
			end
			S_CHECK: begin
				busy = 1;
				if (bit_done)
					next_state = S_STOP0;
				else
					next_state = S_CHECK;
			end
			S_STOP0: begin
				busy = 1;
				if (bit_done) begin
					if (stop_type == 0)
						next_state = S_DONE;
					else
						next_state = state + 1'h1;
				end
				else begin
					next_state = state;
				end
			end
			S_STOP1: begin
				busy = 1;
				if (bit_done) begin
					next_state = S_DONE;
				end
				else begin
					next_state = state;
				end
			end
			S_DONE: begin
				busy = 1;
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
		tx <= 1;
		if (rst) begin
			data_buf <= 0;
		end
		else case (state)
			S_IDLE: begin
				data_buf <= 0;
			end
			S_START: begin
				data_buf <= data;
				tx <= 0;
			end
			S_DATA0, S_DATA1, S_DATA2, S_DATA3, S_DATA4, S_DATA5, S_DATA6, S_DATA7: begin
				tx <= data_buf[0];
				if (bit_done)
					data_buf <= {1'b1, data_buf[7:1]};
			end
			S_CHECK: begin
				tx <= check_bit;
			end
			S_STOP0, S_STOP1: begin
				tx <= 1;
			end
		endcase
	end
	
	always @(posedge clk) begin
		ack <= 0;
		if (~rst) case (next_state)
			S_DONE: ack <= 1;
		endcase
	end
	
endmodule
