`include "define.vh"


module test_flash_anvylsword (
	input wire clk,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire we,
	input wire [7:0] addr,
	output wire [31:0] data,
	output wire [7:0] state,
	// flash interfaces
	output wire [1:0] flash_ce_n,
	output wire flash_rst_n,
	output wire flash_oe_n,
	output wire flash_we_n,
	output wire flash_wp_n,
	input wire [1:0] flash_ready,
	output wire [ADDR_BITS-1:2] flash_addr,
	input wire [31:0] flash_din,
	output wire [31:0] flash_dout
	);
	
	parameter
		CLK_FREQ = 100,
		ADDR_BITS = 25;
	
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
	
	/*flash_core #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS)
		) FLASH_CORE (
		.clk(clk),
		.rst(rst),
		.cs(~cs_prev & cs),
		.addr({14'b0, addr}),
		.burst(1'b0),
		.dout(dout),
		.busy(busy),
		.ack(ack),
		.flash_ce_n(flash_ce_n),
		.flash_rst_n(flash_rst_n),
		.flash_oe_n(flash_oe_n),
		.flash_we_n(flash_we_n),
		.flash_wp_n(flash_wp_n),
		.flash_ready(flash_ready),
		.flash_addr(flash_addr),
		.flash_din(flash_din),
		.flash_dout(flash_dout)
		);*/
	
	wb_flash_anvylsword #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(0),
		.BUF_ADDR_BITS(4)
		) WB_FLASH (
		.clk(clk),
		.rst(rst),
		.flash_busy(busy),
		.flash_ce_n(flash_ce_n),
		.flash_rst_n(flash_rst_n),
		.flash_oe_n(flash_oe_n),
		.flash_we_n(flash_we_n),
		.flash_wp_n(flash_wp_n),
		.flash_ready(flash_ready),
		.flash_addr(flash_addr),
		.flash_din(flash_din),
		.flash_dout(flash_dout),
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
	
	assign data = data_buf;
	assign state = {busy, flash_ce_n[0], flash_rst_n, flash_oe_n, flash_we_n, flash_ready[0], flash_ready[1], ack};
	
endmodule
