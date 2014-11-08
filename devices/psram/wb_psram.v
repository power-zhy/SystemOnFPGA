`include "define.vh"


/**
 * PSRAM device with wishbone connection interfaces, including read/write buffers.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_psram (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	output wire ram_busy,  // busy flag
	// PSRAM interfaces
	output wire ram_clk,
	output wire ram_ce_n,
	output wire ram_oe_n,
	output wire ram_we_n,
	output wire ram_adv_n,
	output wire ram_cre,
	output wire ram_lb_n,
	output wire ram_ub_n,
	input wire ram_wait,
	output wire [ADDR_BITS-1:1] ram_addr,
	input wire [15:0] ram_din,
	output wire [15:0] ram_dout,
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
		ADDR_BITS = 24,  // address length for PSRAM
		HIGH_ADDR = 8'h00,  // high address value, as the address length of wishbone is larger than device
		BUF_ADDR_BITS = 4;  // address length for buffer
	
	wire cs;
	wire we;
	wire [ADDR_BITS-1:2] addr;
	wire [3:0] sel;
	wire burst;
	wire [31:0] din;
	wire [31:0] dout;
	wire busy;
	wire ack;
	
	// core
	psram_core #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS)
		) PSRAM_CORE (
		.clk(clk),
		.rst(rst),
		.cs(cs),
		.we(we),
		.addr(addr),
		.sel(sel),
		.burst(burst),
		.din(din),
		.dout(dout),
		.busy(busy),
		.ack(ack),
		.ram_ce_n(ram_ce_n),
		.ram_clk(ram_clk),
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
		);
	
	// adapter
	wb_mem_adapter #(
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(HIGH_ADDR),
		.BUF_ADDR_BITS(BUF_ADDR_BITS),
		.BURST_CTI(3'b010),
		.BURST_BTE(2'b00)
		) PSRAM_ADAPTER (
		.rst(rst),
		.busy(ram_busy),
		.wbs_clk_i(wbs_clk_i),
		.wbs_cyc_i(wbs_cyc_i),
		.wbs_stb_i(wbs_stb_i),
		.wbs_addr_i(wbs_addr_i),
		.wbs_cti_i(wbs_cti_i),
		.wbs_bte_i(wbs_bte_i),
		.wbs_sel_i(wbs_sel_i),
		.wbs_we_i(wbs_we_i),
		.wbs_data_i(wbs_data_i),
		.wbs_data_o(wbs_data_o),
		.wbs_ack_o(wbs_ack_o),
		.mem_clk(clk),
		.mem_cs(cs),
		.mem_we(we),
		.mem_addr(addr),
		.mem_sel(sel),
		.mem_burst(burst),
		.mem_din(din),
		.mem_dout(dout),
		.mem_busy(busy),
		.mem_ack(ack)
		);
	
endmodule
