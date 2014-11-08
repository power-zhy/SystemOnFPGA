`include "define.vh"


/**
 * SPI core for transmitting data, do not manage slave selection.
 * This is the fast version, SPI's clock will be exactly the same as the input clock.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module spi_core_fast (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire en,  // enable signal, flag to start transmitting
	input wire [DATA_BITS-1:0] din,  // data to sent out
	output reg [DATA_BITS-1:0] dout,  // data received in
	output reg ack,  // data sent/received acknowledge
	output reg busy,  // busy flag
	// SPI interfaces
	output wire sck,
	input wire miso,
	output reg mosi
	);
	
	`include "function.vh"
	parameter
		SPI_CPHA = 0,  // clock phase
		SPI_CPOL = 0,  // clock polarity
		SPI_LSBFE = 0,  // LSB first enable
		DATA_BITS = 8;  // data length for transmit
	localparam
		DATA_BITS_WIDTH = GET_WIDTH(DATA_BITS);
	
	reg [DATA_BITS-1:0] data_buf;
	
	ODDR2 #(
		.DDR_ALIGNMENT("NONE"),
		.INIT(SPI_CPOL ? 1'b1 : 1'b0),
		.SRTYPE("SYNC")
		) RAM_CLK (
		.Q(sck),
		.C0(clk),
		.C1(~clk),
		.CE(busy),
		.D0(1'b1),
		.D1(1'b0),
		.R(1'b0),
		.S(1'b0)
		);
	
	localparam
		S_IDLE = 0,  // idle
		S_LOAD = 1,  // load data, prepare for sending
		S_TRANS = 2,  // send and receive data simultaneously
		S_ACK = 3;  // acknowledge
	
	reg [1:0] state = 0;
	reg [1:0] next_state;
	reg [DATA_BITS_WIDTH-1:0] count = 0;
	reg [DATA_BITS_WIDTH-1:0] next_count;
	
	always @(*) begin
		next_state = 0;
		next_count = 0;
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
				next_count = count + 1'h1;
				if (count == DATA_BITS-1)
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
		if (rst) begin
			state <= 0;
			count <= 0;
		end
		else begin
			state <= next_state;
			count <= next_count;
		end
	end
	
	generate begin: SPI_GEN
		if (SPI_CPHA ^ SPI_CPOL) begin
			always @(negedge clk) begin
				dout <= 0;
				ack <= 0;
				if (~rst) case (next_state)
					S_TRANS: begin
						dout <= SPI_LSBFE ? {miso, dout[DATA_BITS-1:1]} : {dout[DATA_BITS-2:0], miso};
					end
					S_ACK: begin
						dout <= dout;
						ack <= 1;
					end
				endcase
			end
			always @(posedge clk) begin
				data_buf <= 0;
				mosi <= 1;
				if (~rst) case (next_state)
					S_LOAD: begin
						data_buf <= din;
					end
					S_TRANS: begin
						mosi <= SPI_LSBFE ? data_buf[0] : data_buf[DATA_BITS-1];
						data_buf <= SPI_LSBFE ? {1'b0, data_buf[DATA_BITS-1:1]} : {data_buf[DATA_BITS-2:0], 1'b0};
					end
				endcase
			end
		end
		else begin
			always @(posedge clk) begin
				dout <= 0;
				ack <= 0;
				if (~rst) case (next_state)
					S_TRANS: begin
						dout <= SPI_LSBFE ? {miso, dout[DATA_BITS-1:1]} : {dout[DATA_BITS-2:0], miso};
					end
					S_ACK: begin
						dout <= dout;
						ack <= 1;
					end
				endcase
			end
			always @(negedge clk) begin
				data_buf <= 0;
				mosi <= 1;
				if (~rst) case (next_state)
					S_LOAD: begin
						data_buf <= din;
					end
					S_TRANS: begin
						mosi <= SPI_LSBFE ? data_buf[0] : data_buf[DATA_BITS-1];
						data_buf <= SPI_LSBFE ? {1'b0, data_buf[DATA_BITS-1:1]} : {data_buf[DATA_BITS-2:0], 1'b0};
					end
				endcase
			end
		end
		if (SPI_CPOL) begin
			always @(posedge clk) begin
				busy <= 0;
				if (~rst) case (next_state)
					S_TRANS: busy <= 1;
				endcase
			end
		end
		else begin
			always @(negedge clk) begin
				busy <= 0;
				if (~rst) case (next_state)
					S_TRANS: busy <= 1;
				endcase
			end
		end
	end
	endgenerate
	
endmodule
