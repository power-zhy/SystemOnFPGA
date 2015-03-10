`include "define.vh"


module test_sram_anvylsword (
	input wire clk,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire we,
	input wire [7:0] addr,
	output wire [31:0] data,
	output wire [7:0] state,
	// SRAM interfaces
	output wire sram_ce_n,
	output wire sram_oe_n,
	output wire sram_we_n,
	output wire [ADDR_BITS-1:2] sram_addr,
	input wire [47:0] sram_din,
	output wire [47:0] sram_dout
	);
	
	parameter
		CLK_FREQ = 100,
		ADDR_BITS = 22;
	
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
	
	wb_sram_anvylsword #(
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(0)
		) WB_SRAM (
		.rst(rst),
		.sram_ce_n(sram_ce_n),
		.sram_oe_n(sram_oe_n),
		.sram_we_n(sram_we_n),
		.sram_addr(sram_addr),
		.sram_din(sram_din),
		.sram_dout(sram_dout),
		.wbs_clk_i(clk_bus),
		.wbs_cyc_i(cs_buf),
		.wbs_stb_i(cs_buf),
		.wbs_addr_i({22'b0, addr}),
		.wbs_cti_i(3'b0),
		.wbs_bte_i(2'b0),
		.wbs_sel_i(4'b1111),
		.wbs_we_i(we),
		.wbs_data_i(32'h12345678),
		.wbs_data_o(dout),
		.wbs_ack_o(ack)
		);
	
	always @(posedge clk_bus) begin
		if (rst)
			data_buf <= 0;
		else if (ack)
			data_buf <= dout;
	end
	
	assign data = data_buf;
	assign state = {busy, sram_ce_n, sram_oe_n, sram_we_n, 3'b0, ack};
	
endmodule
