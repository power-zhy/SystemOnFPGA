`include "define.vh"


/**
 * RAM with wishbone connection interfaces.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module ram (
	// wishbone slave interfaces
	input wire wbs_clk_i,
	input wire wbs_cyc_i,
	input wire wbs_stb_i,
	input wire [WB_ADDR_BITS-1:2] wbs_addr_i,
	input wire [2:0] wbs_cti_i,
	input wire [1:0] wbs_bte_i,
	input wire [WORD_BYTES-1:0] wbs_sel_i,
	input wire wbs_we_i,
	input wire [WORD_BITS-1:0] wbs_data_i,
	output reg [WORD_BITS-1:0] wbs_data_o,
	output reg wbs_ack_o,
	output wire wbs_err_o
	);
	
	parameter
		ADDR_BITS = 12,  // device address length
		WB_ADDR_BITS = 32,  // wishbone address length
		HIGH_ADDR = 20'h00000,  // high address value, as the address length of wishbone is larger than device
		WORD_BYTES = 4;  // number of bytes per-word
	parameter
		BURST_CTI = 3'b010,
		BURST_BTE = 2'b00;
	localparam
		WORD_BITS = 8 * WORD_BYTES;  // 32
	
	wire [ADDR_BITS-1:2] addr_buf;
	wire wbs_cs, wbs_burst;
	assign
		addr_buf = (wbs_ack_o & wbs_burst) ? wbs_addr_i[ADDR_BITS-1:2] + 1'h1 : wbs_addr_i[ADDR_BITS-1:2],
		wbs_cs = wbs_cyc_i & wbs_stb_i & wbs_addr_i[WORD_BITS-1:ADDR_BITS] == HIGH_ADDR,
		wbs_err_o = wbs_cyc_i & wbs_stb_i & wbs_addr_i[WORD_BITS-1:ADDR_BITS] != HIGH_ADDR,
		wbs_burst = (wbs_cti_i == BURST_CTI) & (wbs_bte_i == BURST_BTE) & (wbs_sel_i == {WORD_BYTES{1'b1}});
	
	genvar i;
	generate for (i=0; i<WORD_BYTES; i=i+1) begin: DATA_CONTENT
		reg [7:0] inner_data [0:(1<<(ADDR_BITS-2))-1];
		always @(posedge wbs_clk_i) begin
			if (wbs_cs && wbs_we_i) begin
				if (wbs_sel_i[i])
					inner_data[wbs_addr_i[ADDR_BITS-1:2]] <= wbs_data_i[8*i+7-:8];
			end
			else begin
				wbs_data_o[8*i+7-:8] <= inner_data[addr_buf];
			end
		end
	end
	endgenerate
	
	always @(posedge wbs_clk_i) begin
		wbs_ack_o <= 0;
		if (wbs_cs) begin
			if (wbs_ack_o && ~wbs_burst)
				wbs_ack_o <= 0;
			else
				wbs_ack_o <= 1;
		end
	end
	
endmodule
