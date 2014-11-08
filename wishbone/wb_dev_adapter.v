`include "define.vh"


/**
 * Wishbone - Devices adapter, Split one wishbone slave interface into several smaller device interfaces.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_dev_adapter (
	// wishbone slave interfaces
	input wire wbs_cyc_i,
	input wire wbs_stb_i,
	input wire [TOTAL_ADDR_BITS-1:2] wbs_addr_i,
	input wire [3:0] wbs_sel_i,
	input wire wbs_we_i,
	input wire [31:0] wbs_data_i,
	output reg [31:0] wbs_data_o,
	output reg wbs_ack_o,
	// slave device 0
	output reg d0_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d0_addr_o,
	output reg [3:0] d0_sel_o,
	output reg d0_we_o,
	output reg [31:0] d0_data_o,
	input wire [31:0] d0_data_i,
	input wire d0_ack_i,
	// slave device 1
	output reg d1_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d1_addr_o,
	output reg [3:0] d1_sel_o,
	output reg d1_we_o,
	output reg [31:0] d1_data_o,
	input wire [31:0] d1_data_i,
	input wire d1_ack_i,
	// slave device 2
	output reg d2_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d2_addr_o,
	output reg [3:0] d2_sel_o,
	output reg d2_we_o,
	output reg [31:0] d2_data_o,
	input wire [31:0] d2_data_i,
	input wire d2_ack_i,
	// slave device 3
	output reg d3_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d3_addr_o,
	output reg [3:0] d3_sel_o,
	output reg d3_we_o,
	output reg [31:0] d3_data_o,
	input wire [31:0] d3_data_i,
	input wire d3_ack_i,
	// slave device 4
	output reg d4_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d4_addr_o,
	output reg [3:0] d4_sel_o,
	output reg d4_we_o,
	output reg [31:0] d4_data_o,
	input wire [31:0] d4_data_i,
	input wire d4_ack_i,
	// slave device 5
	output reg d5_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d5_addr_o,
	output reg [3:0] d5_sel_o,
	output reg d5_we_o,
	output reg [31:0] d5_data_o,
	input wire [31:0] d5_data_i,
	input wire d5_ack_i,
	// slave device 6
	output reg d6_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d6_addr_o,
	output reg [3:0] d6_sel_o,
	output reg d6_we_o,
	output reg [31:0] d6_data_o,
	input wire [31:0] d6_data_i,
	input wire d6_ack_i,
	// slave device 7
	output reg d7_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d7_addr_o,
	output reg [3:0] d7_sel_o,
	output reg d7_we_o,
	output reg [31:0] d7_data_o,
	input wire [31:0] d7_data_i,
	input wire d7_ack_i,
	// slave device 8
	output reg d8_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d8_addr_o,
	output reg [3:0] d8_sel_o,
	output reg d8_we_o,
	output reg [31:0] d8_data_o,
	input wire [31:0] d8_data_i,
	input wire d8_ack_i,
	// slave device 9
	output reg d9_cs_o,
	output reg [SINGLE_ADDR_BITS-1:2] d9_addr_o,
	output reg [3:0] d9_sel_o,
	output reg d9_we_o,
	output reg [31:0] d9_data_o,
	input wire [31:0] d9_data_i,
	input wire d9_ack_i
	);
	
	parameter
		TOTAL_ADDR_BITS = 16,  // address length for the whole device I/O space
		SINGLE_ADDR_BITS = 8;  // address length for single device I/O space
	
	always @(*) begin
		d0_cs_o = 0;
		d0_addr_o = 0;
		d0_sel_o = 0;
		d0_we_o = 0;
		d0_data_o = 0;
		d1_cs_o = 0;
		d1_addr_o = 0;
		d1_sel_o = 0;
		d1_we_o = 0;
		d1_data_o = 0;
		d2_cs_o = 0;
		d2_addr_o = 0;
		d2_sel_o = 0;
		d2_we_o = 0;
		d2_data_o = 0;
		d3_cs_o = 0;
		d3_addr_o = 0;
		d3_sel_o = 0;
		d3_we_o = 0;
		d3_data_o = 0;
		d4_cs_o = 0;
		d4_addr_o = 0;
		d4_sel_o = 0;
		d4_we_o = 0;
		d4_data_o = 0;
		d5_cs_o = 0;
		d5_addr_o = 0;
		d5_sel_o = 0;
		d5_we_o = 0;
		d5_data_o = 0;
		d6_cs_o = 0;
		d6_addr_o = 0;
		d6_sel_o = 0;
		d6_we_o = 0;
		d6_data_o = 0;
		d7_cs_o = 0;
		d7_addr_o = 0;
		d7_sel_o = 0;
		d7_we_o = 0;
		d7_data_o = 0;
		d8_cs_o = 0;
		d8_addr_o = 0;
		d8_sel_o = 0;
		d8_we_o = 0;
		d8_data_o = 0;
		d9_cs_o = 0;
		d9_addr_o = 0;
		d9_sel_o = 0;
		d9_we_o = 0;
		d9_data_o = 0;
		if (wbs_cyc_i & wbs_stb_i) case (wbs_addr_i[TOTAL_ADDR_BITS-1:SINGLE_ADDR_BITS])
			0: begin
				d0_cs_o = 1;
				d0_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d0_sel_o = wbs_sel_i;
				d0_we_o = wbs_we_i;
				d0_data_o = wbs_data_i;
			end
			1: begin
				d1_cs_o = 1;
				d1_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d1_sel_o = wbs_sel_i;
				d1_we_o = wbs_we_i;
				d1_data_o = wbs_data_i;
			end
			2: begin
				d2_cs_o = 1;
				d2_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d2_sel_o = wbs_sel_i;
				d2_we_o = wbs_we_i;
				d2_data_o = wbs_data_i;
			end
			3: begin
				d3_cs_o = 1;
				d3_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d3_sel_o = wbs_sel_i;
				d3_we_o = wbs_we_i;
				d3_data_o = wbs_data_i;
			end
			4: begin
				d4_cs_o = 1;
				d4_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d4_sel_o = wbs_sel_i;
				d4_we_o = wbs_we_i;
				d4_data_o = wbs_data_i;
			end
			5: begin
				d5_cs_o = 1;
				d5_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d5_sel_o = wbs_sel_i;
				d5_we_o = wbs_we_i;
				d5_data_o = wbs_data_i;
			end
			6: begin
				d6_cs_o = 1;
				d6_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d6_sel_o = wbs_sel_i;
				d6_we_o = wbs_we_i;
				d6_data_o = wbs_data_i;
			end
			7: begin
				d7_cs_o = 1;
				d7_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d7_sel_o = wbs_sel_i;
				d7_we_o = wbs_we_i;
				d7_data_o = wbs_data_i;
			end
			8: begin
				d8_cs_o = 1;
				d8_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d8_sel_o = wbs_sel_i;
				d8_we_o = wbs_we_i;
				d8_data_o = wbs_data_i;
			end
			9: begin
				d9_cs_o = 1;
				d9_addr_o = wbs_addr_i[SINGLE_ADDR_BITS-1:2];
				d9_sel_o = wbs_sel_i;
				d9_we_o = wbs_we_i;
				d9_data_o = wbs_data_i;
			end
		endcase
	end
	
	always @(*) begin
		wbs_data_o = 0;
		wbs_ack_o = 0;
		if (wbs_cyc_i & wbs_stb_i) case (wbs_addr_i[TOTAL_ADDR_BITS-1:SINGLE_ADDR_BITS])
			0: begin
				wbs_data_o = d0_data_i;
				wbs_ack_o = d0_ack_i;
			end
			1: begin
				wbs_data_o = d1_data_i;
				wbs_ack_o = d1_ack_i;
			end
			2: begin
				wbs_data_o = d2_data_i;
				wbs_ack_o = d2_ack_i;
			end
			3: begin
				wbs_data_o = d3_data_i;
				wbs_ack_o = d3_ack_i;
			end
			4: begin
				wbs_data_o = d4_data_i;
				wbs_ack_o = d4_ack_i;
			end
			5: begin
				wbs_data_o = d5_data_i;
				wbs_ack_o = d5_ack_i;
			end
			6: begin
				wbs_data_o = d6_data_i;
				wbs_ack_o = d6_ack_i;
			end
			7: begin
				wbs_data_o = d7_data_i;
				wbs_ack_o = d7_ack_i;
			end
			8: begin
				wbs_data_o = d8_data_i;
				wbs_ack_o = d8_ack_i;
			end
			9: begin
				wbs_data_o = d9_data_i;
				wbs_ack_o = d9_ack_i;
			end
		endcase
	end
	
endmodule
