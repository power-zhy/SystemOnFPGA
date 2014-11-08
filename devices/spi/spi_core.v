`include "define.vh"


/**
 * SPI core for transmitting data, do not manage slave selection.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module spi_core (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire [BAUD_DIV_WIDTH-1:0] baud_div,  // baud rate division, should be 10M/2/baudrate-1
	input wire cpha,  // clock phase, generally 0
	input wire cpol,  // clock polarity, generally 0
	input wire lsbfe,  // LSB first enable, generally 0
	input wire en,  // enable signal, flag to start transmitting
	input wire [DATA_BITS-1:0] din,  // data to sent out
	output reg ack,  // data sent/received acknowledge
	output reg [DATA_BITS-1:0] dout,  // data received in
	output reg busy,  // busy flag
	// SPI interfaces
	output reg sck = 0,
	input wire miso,
	output reg mosi = 1
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100,  // main clock frequency in MHz, should be multiple of 10M
		BAUD_DIV_WIDTH = 8,  // width for baud rate division
		DATA_BITS = 8;  // data length for transmit
	localparam
		CLK_DIV = CLK_FREQ / 10,
		CLK_DIV_WIDTH = GET_WIDTH(CLK_DIV-1),
		DATA_BITS_WIDTH = GET_WIDTH(DATA_BITS);
	
	reg [CLK_DIV_WIDTH-1:0] clk_count = 0;
	reg [BAUD_DIV_WIDTH-1:0] hns_count = 0;
	reg [DATA_BITS_WIDTH-1:0] bit_count = 0;
	reg sck_prev;
	reg [DATA_BITS-1:0] data_buf;
	
	always @(posedge clk) begin
		if (rst) begin
			clk_count <= 0;
			hns_count <= 0;
			sck <= 0;
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
					sck <= ~sck;
				end
			end
		end
		else begin
			clk_count <= 0;
			hns_count <= 0;
		end
	end
	
	always @(posedge clk) begin
		if (rst)
			sck_prev <= 0;
		else
			sck_prev <= sck;
	end
	
	localparam
		S_IDLE = 0,  // idle
		S_LOAD = 1,  // load data, prepare for sending
		S_TRANS = 2,  // send and receive data simultaneously
		S_ACK = 3;  // acknowledge
	
	reg [1:0] state = 0;
	reg [1:0] next_state;
	
	always @(*) begin
		next_state = S_IDLE;
		case (state)
			S_IDLE: begin
				if (sck != cpol)
					next_state = S_IDLE;
				else if (en)
					next_state = S_LOAD;
				else
					next_state = S_IDLE;
			end
			S_LOAD: begin
				next_state = S_TRANS;
			end
			S_TRANS: begin
				if (bit_count == DATA_BITS)
					next_state = S_ACK;
				else
					next_state = S_TRANS;
			end
			S_ACK: begin
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
			busy <= 0;
			bit_count <= 0;
			data_buf <= 0;
			dout <= 0;
			ack <= 0;
			mosi <= 1;
		end
		else case (next_state)
			S_IDLE: begin
				busy <= (sck != cpol);
				bit_count <= 0;
				data_buf <= 0;
				dout <= 0;
				ack <= 0;
				mosi <= 1;
			end
			S_LOAD: begin
				busy <= 1;
				bit_count <= 0;
				data_buf <= din;
				dout <= 0;
				ack <= 0;
				mosi <= 1;
			end
			S_TRANS: begin
				busy <= 1;
				mosi <= lsbfe ? data_buf[0] : data_buf[DATA_BITS-1];
				if ((cpha^cpol) ? (sck_prev&~sck) : (~sck_prev&sck)) begin
					dout <= lsbfe ? {miso, dout[DATA_BITS-1:1]} : {dout[DATA_BITS-2:0], miso};
				end
				if ((cpha^cpol) ? (~sck_prev&sck) : (sck_prev&~sck)) begin
					data_buf <= lsbfe ? {1'b0, data_buf[DATA_BITS-1:1]} : {data_buf[DATA_BITS-2:0], 1'b0};
					bit_count <= bit_count + 1'h1;
				end
				ack <= 0;
			end
			S_ACK: begin
				busy <= 0;
				bit_count <= 0;
				data_buf <= 0;
				ack <= 1;
				mosi <= 1;
			end
		endcase
	end
	
endmodule
