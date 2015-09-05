`include "define.vh"


/**
 * Flash memory device with wishbone connection interfaces, including read buffers (read only).
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_flash_sword (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	output wire flash_busy,  // busy flag
	// Flash memory interfaces
	output wire [1:0] flash_ce_n,
	output wire flash_rst_n,
	output wire flash_oe_n,
	output wire flash_we_n,
	output wire flash_wp_n,
	input wire [1:0] flash_ready,
	output wire [ADDR_BITS-1:2] flash_addr,
	input wire [31:0] flash_din,
	output wire [31:0] flash_dout,
	// wishbone slave interfaces
	input wire wbs_clk_i,
	input wire wbs_cyc_i,
	input wire wbs_stb_i,
	input wire [31:2] wbs_addr_i,
	input wire [2:0] wbs_cti_i,
	input wire [1:0] wbs_bte_i,
	input wire [3:0] wbs_sel_i,
	input wire wbs_we_i,
	input wire [31:0] wbs_data_i,
	output wire [31:0] wbs_data_o,
	output wire wbs_ack_o
	);
	
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz
	parameter
		ADDR_BITS = 25,  // address length for Parallel PCM
		HIGH_ADDR = 7'h7F,  // high address value, as the address length of wishbone is larger than device
		ADDR_BURST = 4,  // address length in which burst can be used
		BUF_ADDR_BITS = 4;  // address length for buffer
	
	wire cs;
	wire [ADDR_BITS-1:2] addr;
	wire burst;
	wire [31:0] dout;
	wire busy;
	wire ack;
	
	// core
	flash_core #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS-1),
		.ADDR_BURST(ADDR_BURST)
		) FLASH_CORE0 (
		.clk(clk),
		.rst(rst),
		.cs(cs),
		.addr(addr),
		.burst(burst),
		.dout(dout[15:0]),
		.busy(busy),
		.ack(ack),
		.flash_ce_n(flash_ce_n[0]),
		.flash_rst_n(flash_rst_n),
		.flash_oe_n(flash_oe_n),
		.flash_we_n(flash_we_n),
		.flash_wp_n(flash_wp_n),
		.flash_ready(flash_ready[0] & flash_ready[1]),
		.flash_addr(flash_addr),
		.flash_din(flash_din[15:0]),
		.flash_dout(flash_dout[15:0])
		);
	
	flash_core #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS-1),
		.ADDR_BURST(ADDR_BURST)
		) FLASH_CORE1 (
		.clk(clk),
		.rst(rst),
		.cs(cs),
		.addr(addr),
		.burst(burst),
		.dout(dout[31:16]),
		.busy(),
		.ack(),
		.flash_ce_n(flash_ce_n[1]),
		.flash_rst_n(),
		.flash_oe_n(),
		.flash_we_n(),
		.flash_wp_n(),
		.flash_ready(flash_ready[0] & flash_ready[1]),
		.flash_addr(),
		.flash_din(flash_din[31:16]),
		.flash_dout(flash_dout[31:16])
		);
	
	// adapter
	wb_mem_adapter #(
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(HIGH_ADDR),
		.BUF_ADDR_BITS(BUF_ADDR_BITS),
		.BURST_CTI(3'b010),
		.BURST_BTE(2'b00)
		) FLASH_ADAPTER (
		.rst(rst),
		.busy(flash_busy),
		.wbs_clk_i(wbs_clk_i),
		.wbs_cyc_i(wbs_cyc_i),
		.wbs_stb_i(wbs_stb_i),
		.wbs_addr_i(wbs_addr_i),
		.wbs_cti_i(wbs_cti_i),
		.wbs_bte_i(wbs_bte_i),
		.wbs_sel_i(4'b1111),
		.wbs_we_i(1'b0),
		.wbs_data_i(32'b0),
		.wbs_data_o(wbs_data_o),
		.wbs_ack_o(wbs_ack_o),
		.mem_clk(clk),
		.mem_cs(cs),
		.mem_we(),
		.mem_addr(addr),
		.mem_sel(),
		.mem_burst(burst),
		.mem_din(),
		.mem_dout(dout),
		.mem_busy(busy),
		.mem_ack(ack)
		);
	
endmodule
