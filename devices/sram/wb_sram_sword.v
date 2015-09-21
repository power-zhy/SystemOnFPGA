`include "define.vh"


/**
 * SRAM device with wishbone connection interfaces, including read/write buffers.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_sram_sword (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	output wire ram_busy,  // busy flag
	// SRAM interfaces
	output wire sram_ce_n,
	output wire sram_oe_n,
	output wire sram_we_n,
	output wire [ADDR_BITS-1:2] sram_addr,
	input wire [47:0] sram_din,
	output wire [47:0] sram_dout,
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
	output wire wbs_ack_o,
	output wire wbs_err_o
	);
	
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz
	parameter
		ADDR_BITS = 22,  // address length for SRAM
		HIGH_ADDR = 10'h000,  // high address value, as the address length of wishbone is larger than device
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
	sram_core_sword #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS)
		) SRAM_CORE (
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
		.sram_ce_n(sram_ce_n),
		.sram_oe_n(sram_oe_n),
		.sram_we_n(sram_we_n),
		.sram_addr(sram_addr),
		.sram_din(sram_din),
		.sram_dout(sram_dout)
		);
	
	// adapter
	wb_mem_adapter #(
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(HIGH_ADDR),
		.BUF_ADDR_BITS(BUF_ADDR_BITS),
		.BURST_CTI(3'b010),
		.BURST_BTE(2'b00)
		) SRAM_ADAPTER (
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
		.wbs_err_o(wbs_err_o),
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
