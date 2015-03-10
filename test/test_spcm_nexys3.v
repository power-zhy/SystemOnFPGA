`include "define.vh"


module test_spcm_nexys3 (
	input wire clk,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire we,
	input wire [7:0] addr,
	output wire [31:0] data,
	output wire [7:0] state,
	// SPCM interfaces
	output wire spcm_cs_n,
	output wire spcm_sck,
	output wire spcm_mosi,
	input wire spcm_miso
	);
	
	parameter
		CLK_FREQ = 100,
		ADDR_BITS = 24;
	
	wire busy, ack;
	wire [31:0] dout;
	reg [31:0] data_buf;
	
	reg cs_prev;
	always @(posedge clk) begin
		if (rst)
			cs_prev <= 0;
		else
			cs_prev <= cs;
	end
	
	reg cs_buf;
	always @(posedge clk) begin
		if (rst)
			cs_buf <= 0;
		else if (cs & ~cs_prev)
			cs_buf <= 1;
		else if (ack)
			cs_buf <= 0;
	end
	
	spcm_core_nexys3 #(
		.ADDR_BITS(ADDR_BITS)
		) SPCM_CORE (
		.clk(clk),
		.rst(rst),
		.cs(~cs_prev & cs),
		.addr(addr),
		.burst(1'b0),
		.dout(dout),
		.busy(busy),
		.ack(ack),
		.spcm_cs_n(spcm_cs_n),
		.spcm_sck(spcm_sck),
		.spcm_mosi(spcm_mosi),
		.spcm_miso(spcm_miso)
		);
	
	always @(posedge clk) begin
		if (rst)
			data_buf <= 0;
		else if (ack)
			data_buf <= dout;
	end
	
	assign data = data_buf;
	assign state = {busy, 5'b0, spcm_cs_n, ack};
	
endmodule
