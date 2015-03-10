`include "define.vh"


/**
 * Wishbone arbitrator, with priority m0 > m1 > m2 > ...
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_arb (
	input wire wb_clk,  // wishbone clock
	input wire wb_rst,  // synchronous reset
	// wishbone master 0 - VRAM
	input wire m0_cyc_i, m0_stb_i,
	input wire [31:2] m0_addr_i,
	input wire [2:0] m0_cti_i,
	input wire [1:0] m0_bte_i,
	input wire [3:0] m0_sel_i,
	input wire m0_we_i,
	output reg [31:0] m0_data_o,
	input wire [31:0] m0_data_i,
	output reg m0_ack_o,
	// wishbone master 1 - ICMU
	input wire m1_cyc_i, m1_stb_i,
	input wire [31:2] m1_addr_i,
	input wire [2:0] m1_cti_i,
	input wire [1:0] m1_bte_i,
	input wire [3:0] m1_sel_i,
	input wire m1_we_i,
	output reg [31:0] m1_data_o,
	input wire [31:0] m1_data_i,
	output reg m1_ack_o,
	// wishbone master 2 - DCMU
	input wire m2_cyc_i, m2_stb_i,
	input wire [31:2] m2_addr_i,
	input wire [2:0] m2_cti_i,
	input wire [1:0] m2_bte_i,
	input wire [3:0] m2_sel_i,
	input wire m2_we_i,
	output reg [31:0] m2_data_o,
	input wire [31:0] m2_data_i,
	output reg m2_ack_o,
	// wishbone master 3 - DMA
	input wire m3_cyc_i, m3_stb_i,
	input wire [31:2] m3_addr_i,
	input wire [2:0] m3_cti_i,
	input wire [1:0] m3_bte_i,
	input wire [3:0] m3_sel_i,
	input wire m3_we_i,
	output reg [31:0] m3_data_o,
	input wire [31:0] m3_data_i,
	output reg m3_ack_o,
	// wishbone slave 0 - RAM
	output reg  s0_cyc_o, s0_stb_o,
	output reg [31:2] s0_addr_o,
	output reg [2:0] s0_cti_o,
	output reg [1:0] s0_bte_o,
	output reg [3:0] s0_sel_o,
	output reg s0_we_o,
	input wire [31:0] s0_data_i,
	output reg [31:0] s0_data_o,
	input wire s0_ack_i,
	// wishbone slave 1 - ROM
	output reg  s1_cyc_o, s1_stb_o,
	output reg [31:2] s1_addr_o,
	output reg [2:0] s1_cti_o,
	output reg [1:0] s1_bte_o,
	output reg [3:0] s1_sel_o,
	output reg s1_we_o,
	input wire [31:0] s1_data_i,
	output reg [31:0] s1_data_o,
	input wire s1_ack_i,
	// wishbone slave 2 - I/O devices
	output reg  s2_cyc_o, s2_stb_o,
	output reg [31:2] s2_addr_o,
	output reg [2:0] s2_cti_o,
	output reg [1:0] s2_bte_o,
	output reg [3:0] s2_sel_o,
	output reg s2_we_o,
	input wire [31:0] s2_data_i,
	output reg [31:0] s2_data_o,
	input wire s2_ack_i
	);
	
	`include "function.vh"
	localparam
		MASTER_COUNT = 4;
	localparam
		MASTER_COUNT_BITS = GET_WIDTH(MASTER_COUNT-1);
	
	// master selector
	reg curr_cyc = 0;
	wire next_cyc;
	reg [MASTER_COUNT_BITS-1:0] curr_master = 0;
	wire [MASTER_COUNT_BITS-1:0] next_master;
	
	// current master interface
	wire [MASTER_COUNT_BITS-1:0] master;
	reg m_cyc_i, m_stb_i;
	reg [31:2] m_addr_i;
	reg [2:0] m_cti_i;
	reg [1:0] m_bte_i;
	reg [3:0] m_sel_i;
	reg m_we_i;
	reg [31:0] m_data_o;
	reg [31:0] m_data_i;
	reg m_ack_o;
	
	// slave selector
	wire s0_sel, s1_sel, s2_sel;
	wire f_t1, f_t2;
	assign
		f_t1 = (m_addr_i[31:24] == {8{1'b1}}),
		f_t2 = (m_addr_i[23:16] == {8{1'b1}});
	assign
		s0_sel = ~f_t1,
		s1_sel = f_t1 & ~f_t2,
		s2_sel = f_t1 & f_t2;
	
	bit_searcher #(  // master priority: m0 > m1 > m2 > m3
		.N(MASTER_COUNT)
		) BS (
		.bits({m3_cyc_i, m2_cyc_i, m1_cyc_i, m0_cyc_i}),
		.target(1'b1),
		.direction(1'b0),
		.hit(next_cyc),
		.index(next_master)
		);
	
	always @(posedge wb_clk) begin
		if (wb_rst) begin
			curr_cyc <= 0;
			curr_master <= 0;
		end
		else if (curr_cyc && ~m_cyc_i) begin  // ensure there is one clock for negative m_cyc_i signal so that bus request can be safely changed
			curr_cyc <= next_cyc;
			curr_master <= next_master;
		end
		else if (~curr_cyc) begin
			curr_cyc <= next_cyc;
			curr_master <= next_master;
		end
	end
	
	assign
		master = curr_cyc ? curr_master : next_master;  // ensure current bus operation can not be interrupted
	
	always @(*) begin
		m_cyc_i = 0;
		m_stb_i = 0;
		m_addr_i = 0;
		m_cti_i = 0;
		m_bte_i = 0;
		m_sel_i = 0;
		m_we_i = 0;
		m_data_i = 0;
		if (curr_cyc || next_cyc) begin
			case (master)
				0: begin
					m_cyc_i = m0_cyc_i;
					m_stb_i = m0_stb_i;
					m_addr_i = m0_addr_i;
					m_cti_i = m0_cti_i;
					m_bte_i = m0_bte_i;
					m_sel_i = m0_sel_i;
					m_we_i = m0_we_i;
					m_data_i = m0_data_i;
				end
				1: begin
					m_cyc_i = m1_cyc_i;
					m_stb_i = m1_stb_i;
					m_addr_i = m1_addr_i;
					m_cti_i = m1_cti_i;
					m_bte_i = m1_bte_i;
					m_sel_i = m1_sel_i;
					m_we_i = m1_we_i;
					m_data_i = m1_data_i;
				end
				2: begin
					m_cyc_i = m2_cyc_i;
					m_stb_i = m2_stb_i;
					m_addr_i = m2_addr_i;
					m_cti_i = m2_cti_i;
					m_bte_i = m2_bte_i;
					m_sel_i = m2_sel_i;
					m_we_i = m2_we_i;
					m_data_i = m2_data_i;
				end
				3: begin
					m_cyc_i = m3_cyc_i;
					m_stb_i = m3_stb_i;
					m_addr_i = m3_addr_i;
					m_cti_i = m3_cti_i;
					m_bte_i = m3_bte_i;
					m_sel_i = m3_sel_i;
					m_we_i = m3_we_i;
					m_data_i = m3_data_i;
				end
			endcase
		end
	end
	
	always @(*) begin
		m0_data_o = 0;
		m0_ack_o = 0;
		m1_data_o = 0;
		m1_ack_o = 0;
		m2_data_o = 0;
		m2_ack_o = 0;
		m3_data_o = 0;
		m3_ack_o = 0;
		if (curr_cyc || next_cyc) begin
			case (master)
				0: begin
					m0_data_o = m_data_o;
					m0_ack_o = m_ack_o;
				end
				1: begin
					m1_data_o = m_data_o;
					m1_ack_o = m_ack_o;
				end
				2: begin
					m2_data_o = m_data_o;
					m2_ack_o = m_ack_o;
				end
				3: begin
					m3_data_o = m_data_o;
					m3_ack_o = m_ack_o;
				end
			endcase
		end
	end
	
	always @(*) begin
		s0_cyc_o = 0;
		s0_stb_o = 0;
		s0_addr_o = 0;
		s0_cti_o = 0;
		s0_bte_o = 0;
		s0_sel_o = 0;
		s0_we_o = 0;
		s0_data_o = 0;
		s1_cyc_o = 0;
		s1_stb_o = 0;
		s1_addr_o = 0;
		s1_cti_o = 0;
		s1_bte_o = 0;
		s1_sel_o = 0;
		s1_we_o = 0;
		s1_data_o = 0;
		s2_cyc_o = 0;
		s2_stb_o = 0;
		s2_addr_o = 0;
		s2_cti_o = 0;
		s2_bte_o = 0;
		s2_sel_o = 0;
		s2_we_o = 0;
		s2_data_o = 0;
		if (curr_cyc || next_cyc) begin
			case (1)
				s0_sel: begin
					s0_cyc_o = m_cyc_i;
					s0_stb_o = m_stb_i;
					s0_addr_o = m_addr_i;
					s0_cti_o = m_cti_i;
					s0_bte_o = m_bte_i;
					s0_sel_o = m_sel_i;
					s0_we_o = m_we_i;
					s0_data_o = m_data_i;
				end
				s1_sel: begin
					s1_cyc_o = m_cyc_i;
					s1_stb_o = m_stb_i;
					s1_addr_o = m_addr_i;
					s1_cti_o = m_cti_i;
					s1_bte_o = m_bte_i;
					s1_sel_o = m_sel_i;
					s1_we_o = m_we_i;
					s1_data_o = m_data_i;
				end
				s2_sel: begin
					s2_cyc_o = m_cyc_i;
					s2_stb_o = m_stb_i;
					s2_addr_o = m_addr_i;
					s2_cti_o = m_cti_i;
					s2_bte_o = m_bte_i;
					s2_sel_o = m_sel_i;
					s2_we_o = m_we_i;
					s2_data_o = m_data_i;
				end
			endcase
		end
	end
	
	always @(*) begin
		m_data_o = 0;
		m_ack_o = 0;
		if (curr_cyc || next_cyc) begin
			case (1)
				s0_sel: begin
					m_data_o = s0_data_i;
					m_ack_o = s0_ack_i;
				end
				s1_sel: begin
					m_data_o = s1_data_i;
					m_ack_o = s1_ack_i;
				end
				s2_sel: begin
					m_data_o = s2_data_i;
					m_ack_o = s2_ack_i;
				end
			endcase
		end
	end
	
endmodule
