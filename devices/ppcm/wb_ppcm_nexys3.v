`include "define.vh"


/**
 * Parallel PCM device with wishbone connection interfaces, including read buffers (read only).
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_ppcm_nexys3 (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	output wire pcm_busy,  // busy flag
	// Parallel PCM interfaces
	output wire pcm_ce_n,
	output wire pcm_rst_n,
	output wire pcm_oe_n,
	output wire pcm_we_n,
	output wire [ADDR_BITS-1:1] pcm_addr,
	input wire [15:0] pcm_din,
	output wire [15:0] pcm_dout,
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
		ADDR_BITS = 24,  // address length for Parallel PCM
		HIGH_ADDR = 8'hFF,  // high address value, as the address length of wishbone is larger than device
		BUF_ADDR_BITS = 4;  // address length for buffer
	
	wire cs;
	wire [ADDR_BITS-1:2] addr;
	wire burst;
	wire [31:0] dout;
	wire busy;
	wire ack;
	
	// core
	ppcm_core_nexys3 #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS)
		) PPCM_CORE (
		.clk(clk),
		.rst(rst),
		.cs(cs),
		.addr(addr),
		.burst(burst),
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
		);
	
	// adapter
	wb_mem_adapter #(
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(HIGH_ADDR),
		.BUF_ADDR_BITS(BUF_ADDR_BITS),
		.BURST_CTI(3'b010),
		.BURST_BTE(2'b00)
		) PPCM_ADAPTER (
		.rst(rst),
		.busy(pcm_busy),
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
