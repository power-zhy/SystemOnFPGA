`include "define.vh"


module test_psram (
	input wire clk,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire we,
	input wire high,
	input wire [7:0] addr,
	output wire [15:0] data,
	output wire [7:0] state,
	// PSRAM interfaces
	output wire ram_ce_n,
	output wire ram_clk,
	output wire ram_oe_n,
	output wire ram_we_n,
	output wire ram_adv_n,
	output wire ram_cre,
	output wire ram_lb_n,
	output wire ram_ub_n,
	input wire ram_wait,
	output wire [ADDR_BITS-1:1] ram_addr,
	input wire [15:0] ram_din,
	output wire [15:0] ram_dout
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
	
	/*psram_core #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS)
		) PSRAM_CORE (
		.clk(clk),
		.rst(rst),
		.cs(cs & ~cs_prev),
		.we(we),
		.addr({14'b0, addr}),
		.sel(4'b1111),
		.burst(1'b0),
		.din(32'h12345678),
		.dout(dout),
		.busy(busy),
		.ack(ack),
		.ram_clk(ram_clk),
		.ram_ce_n(ram_ce_n),
		.ram_oe_n(ram_oe_n),
		.ram_we_n(ram_we_n),
		.ram_adv_n(ram_adv_n),
		.ram_cre(ram_cre),
		.ram_lb_n(ram_lb_n),
		.ram_ub_n(ram_ub_n),
		.ram_wait(ram_wait),
		.ram_addr(ram_addr),
		.ram_din(ram_din),
		.ram_dout(ram_dout)
		);*/
	
	wb_psram #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(8'h00),
		.BUF_ADDR_BITS(4)
		) WB_PSRAM (
		.clk(clk),
		.rst(rst),
		.ram_busy(busy),
		.ram_clk(ram_clk),
		.ram_ce_n(ram_ce_n),
		.ram_oe_n(ram_oe_n),
		.ram_we_n(ram_we_n),
		.ram_adv_n(ram_adv_n),
		.ram_cre(ram_cre),
		.ram_lb_n(ram_lb_n),
		.ram_ub_n(ram_ub_n),
		.ram_wait(ram_wait),
		.ram_addr(ram_addr),
		.ram_din(ram_din),
		.ram_dout(ram_dout),
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
	
	assign data = high ? data_buf[31:16] : data_buf[15:0];
	assign state = {busy, ram_ce_n, ram_oe_n, ram_we_n, ram_adv_n, ram_wait, 1'b0, ack};
	
endmodule
