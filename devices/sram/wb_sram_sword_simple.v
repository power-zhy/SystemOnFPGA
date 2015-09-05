`include "define.vh"


/**
 * SRAM device with wishbone connection interfaces, can be used up to 100MHz.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_sram_sword (
	input wire clk,  // main clock, should be faster then bus clock
	input wire rst,  // synchronous reset
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
	output reg [31:0] wbs_data_o,
	output reg wbs_ack_o
	);
	
	parameter
		ADDR_BITS = 22,  // address length for PSRAM
		HIGH_ADDR = 10'h000;  // high address value, as the address length of wishbone is larger than device
	
	wire cs;
	assign
		cs = wbs_cyc_i & wbs_stb_i & wbs_addr_i[31:ADDR_BITS] == HIGH_ADDR;
	
	assign
		sram_ce_n = ~cs,
		sram_oe_n = wbs_we_i,
		sram_we_n = ~wbs_we_i,
		sram_addr = wbs_addr_i[ADDR_BITS-1:2],
		sram_dout = {16'b0, wbs_data_i};
	
	always @(posedge wbs_clk_i) begin
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (~rst && cs) begin
			wbs_data_o <= sram_din[31:0];
			wbs_ack_o <= 1;
		end
	end
	
endmodule
