`include "define.vh"


/**
 * SRAM device with wishbone connection interfaces, can be used up to 100MHz.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_sram_sword (
	input wire clk,  // main clock, should be faster then bus clock
	input wire rst,  // synchronous reset
	// SRAM interfaces
	output reg sram_ce_n,
	output reg sram_oe_n,
	output reg sram_we_n,
	output reg [ADDR_BITS-1:2] sram_addr,
	input wire [47:0] sram_din,
	output reg [47:0] sram_dout,
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
	parameter
		BURST_CTI = 3'b010,
		BURST_BTE = 2'b00;
	
	wire cs, burst;
	assign
		cs = wbs_cyc_i & wbs_stb_i & wbs_addr_i[31:ADDR_BITS] == HIGH_ADDR,
		burst = (wbs_cti_i == BURST_CTI) & (wbs_bte_i == BURST_BTE) & (wbs_sel_i == 4'b1111);
	
	reg burst_buf;
	always @(posedge wbs_clk_i) begin
		if (rst)
			burst_buf <= 0;
		else
			burst_buf <= burst;
	end
	
	localparam
		S_READ = 0,
		S_WRITE = 1;
	
	reg state = 0;
	reg next_state;
	reg [31:0] read_buf;
	
	always @(*) begin
		sram_ce_n = ~cs;
		sram_oe_n = 0;
		sram_we_n = 1;
		sram_addr = burst_buf ? wbs_addr_i[ADDR_BITS-1:2] + 1'h1 : wbs_addr_i[ADDR_BITS-1:2];
		sram_dout = 0;
		next_state = S_READ;
		if (cs) case (state)
			S_READ: begin
				sram_oe_n = 0;
				sram_we_n = 1;
				sram_dout[31:0] = 0;
				if (wbs_we_i)
					next_state = S_WRITE;
				else
					next_state = S_READ;
			end
			S_WRITE: begin
				sram_oe_n = 1;
				sram_we_n = 0;
				sram_dout[31:24] = wbs_sel_i[3] ? wbs_data_i[31:24] : read_buf[31:24];
				sram_dout[23:16] = wbs_sel_i[2] ? wbs_data_i[23:16] : read_buf[23:16];
				sram_dout[15:8] = wbs_sel_i[1] ? wbs_data_i[15:8] : read_buf[15:8];
				sram_dout[7:0] = wbs_sel_i[0] ? wbs_data_i[7:0] : read_buf[7:0];
				next_state = S_READ;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst)
			state = S_READ;
		else
			state = next_state;
	end
	
	always @(posedge clk) begin
		if (rst) begin
			read_buf <= 0;
		end
		else case (state)
			S_READ: read_buf <= sram_din[31:0];
			default: read_buf <= 0;
		endcase
	end
	
	always @(posedge wbs_clk_i) begin
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (~rst && cs) begin
			if (~wbs_we_i)
				wbs_data_o <= sram_din[31:0];
			wbs_ack_o <= 1;
		end
	end
	
endmodule
