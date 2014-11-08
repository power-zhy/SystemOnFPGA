`include "define.vh"


/**
 * Serial PCM core, read only.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module spcm_core (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire cs,  // chip select
	input wire [ADDR_BITS-1:2] addr,  // address
	input wire burst,  // burst mode flag
	output reg [31:0] dout,  // data read in
	output reg busy,  // busy flag
	output reg ack,  // acknowledge
	// Serial PCM interfaces
	output wire spcm_cs_n,
	output wire spcm_sck,
	output wire spcm_mosi,
	input wire spcm_miso
	);
	
	parameter
		ADDR_BITS = 24;  // address length for serial PCM
	
	reg spi_en;
	reg [31:0] spi_din;
	wire [31:0] spi_dout;
	wire spi_ack;
	wire spi_busy;
	
	spi_core_fast #(
		.SPI_CPHA(0),
		.SPI_CPOL(0),
		.SPI_LSBFE(0),
		.DATA_BITS(32)
		) SPCM_SPI (
		.clk(clk),
		.rst(rst),
		.en(spi_en),
		.din(spi_din),
		.dout(spi_dout),
		.ack(spi_ack),
		.busy(spi_busy),
		.sck(spcm_sck),
		.miso(spcm_miso),
		.mosi(spcm_mosi)
		);
	
	assign spcm_cs_n = ~spi_busy;
	
	localparam
		S_IDLE = 0,  // idle
		S_SEND = 1,  // send command
		S_RECV = 2,  // receive data
		S_DONE = 3;  // wait until SPI core is not busy
	
	reg [1:0] state = 0;
	reg [1:0] next_state;
	
	always @(*) begin
		next_state = 0;
		case (state)
			S_IDLE: begin
				if (cs)
					next_state = S_SEND;
				else
					next_state = S_IDLE;
			end
			S_SEND: begin
				if (spi_ack)
					next_state = S_RECV;
				else
					next_state = S_SEND;
			end
			S_RECV: begin
				if (spi_ack && ~burst)
					next_state = S_DONE;
				else
					next_state = S_RECV;
			end
			S_DONE: begin
				if (~spi_busy)
					next_state = S_IDLE;
				else
					next_state = S_DONE;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst)
			state <= 0;
		else
			state <= next_state;
	end
	
	always @(*) begin
		spi_en = 0;
		spi_din = 0;
		dout = 0;
		busy = 0;
		ack = 0;
		case (state)
			S_SEND: begin
				busy = 1;
				spi_en = 1;
				spi_din = {8'h3, addr, 2'b0};
			end
			S_RECV: begin
				spi_en = 1;
				busy = 1;
				dout = spi_dout;
				ack = spi_ack;
			end
		endcase
	end
	
endmodule
