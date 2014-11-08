`include "define.vh"


module test_ppcm (
	input wire clk,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire we,
	input wire high,
	input wire [7:0] addr,
	output wire [15:0] data,
	output wire [7:0] state,
	// PPCM interfaces
	output wire pcm_ce_n,
	output wire pcm_rst_n,
	output wire pcm_oe_n,
	output wire pcm_we_n,
	output wire [ADDR_BITS-1:1] pcm_addr,
	input wire [15:0] pcm_din,
	output wire [15:0] pcm_dout
	);
	
	parameter
		CLK_FREQ = 100,
		ADDR_BITS = 24;
	
	wire busy, ack;
	wire [31:0] dout;
	reg [31:0] data_buf;
	
	reg cs_prev;
	always @(posedge clk_bus) begin
		if (rst)
			cs_prev <= 0;
		else
			cs_prev <= cs;
	end
	
	reg cs_buf;
	always @(posedge clk_bus) begin
		if (rst)
			cs_buf <= 0;
		else if (cs & ~cs_prev)
			cs_buf <= 1;
		else if (ack)
			cs_buf <= 0;
	end
	
	/*ppcm_core #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS)
		) PPCM_CORE (
		.clk(clk),
		.rst(rst),
		.cs(~cs_prev & cs),
		.addr({14'b0, addr}),
		.burst(1'b0),
		.dout(dout),
		.busy(busy),
		.ack(ack),
		.pcm_ce_n(pcm_ce_n),
		.pcm_rst_n(pcm_rst_n),
		.pcm_oe_n(pcm_oe_n),
		.pcm_we_n(pcm_we_n),
		.pcm_addr(pcm_addr),
		.pcm_din(pcm_din),
		.pcm_dout(pcm_dout)
		);*/
	
	wb_ppcm #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(8'h00),
		.BUF_ADDR_BITS(4)
		) WB_PPCM (
		.clk(clk),
		.rst(rst),
		.pcm_busy(busy),
		.pcm_ce_n(pcm_ce_n),
		.pcm_rst_n(pcm_rst_n),
		.pcm_oe_n(pcm_oe_n),
		.pcm_we_n(pcm_we_n),
		.pcm_addr(pcm_addr),
		.pcm_din(pcm_din),
		.pcm_dout(pcm_dout),
		.wbs_clk_i(clk_bus),
		.wbs_cyc_i(cs_buf),
		.wbs_stb_i(cs_buf),
		.wbs_addr_i({22'b0, addr}),
		.wbs_cti_i(3'b0),
		.wbs_bte_i(2'b0),
		.wbs_sel_i(4'b1111),
		.wbs_we_i(1'b0),
		.wbs_data_i(32'b0),
		.wbs_data_o(dout),
		.wbs_ack_o(ack)
		);
	
	always @(posedge clk_bus) begin
		if (rst)
			data_buf <= 0;
		else if (ack)
			data_buf <= dout;
	end
	
	assign data = high ? data_buf[31:16] : data_buf[15:0];
	assign state = {busy, pcm_ce_n, pcm_rst_n, pcm_oe_n, pcm_we_n, 2'b0, ack};
	
endmodule
