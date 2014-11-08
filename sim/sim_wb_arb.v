`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:37:14 09/20/2014
// Design Name:   wb_arb
// Module Name:   D:/Verilog/SystemOnFPGA/sim_wb_arb.v
// Project Name:  SystemOnFPGA
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: wb_arb
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module sim_wb_arb;

	// Inputs
	reg wb_clk;
	reg wb_rst;
	reg m0_cyc_i;
	reg m0_stb_i;
	reg [31:2] m0_addr_i;
	reg [2:0] m0_cti_i;
	reg [1:0] m0_bte_i;
	reg [3:0] m0_sel_i;
	reg m0_we_i;
	reg [31:0] m0_data_i;
	reg m1_cyc_i;
	reg m1_stb_i;
	reg [31:2] m1_addr_i;
	reg [2:0] m1_cti_i;
	reg [1:0] m1_bte_i;
	reg [3:0] m1_sel_i;
	reg m1_we_i;
	reg [31:0] m1_data_i;
	reg m2_cyc_i;
	reg m2_stb_i;
	reg [31:2] m2_addr_i;
	reg [2:0] m2_cti_i;
	reg [1:0] m2_bte_i;
	reg [3:0] m2_sel_i;
	reg m2_we_i;
	reg [31:0] m2_data_i;
	reg m3_cyc_i;
	reg m3_stb_i;
	reg [31:2] m3_addr_i;
	reg [2:0] m3_cti_i;
	reg [1:0] m3_bte_i;
	reg [3:0] m3_sel_i;
	reg m3_we_i;
	reg [31:0] m3_data_i;
	reg [31:0] s0_data_i;
	reg s0_ack_i;
	reg [31:0] s1_data_i;
	reg s1_ack_i;
	reg [31:0] s2_data_i;
	reg s2_ack_i;

	// Outputs
	wire invalid_addr;
	wire [31:0] m0_data_o;
	wire m0_ack_o;
	wire [31:0] m1_data_o;
	wire m1_ack_o;
	wire [31:0] m2_data_o;
	wire m2_ack_o;
	wire [31:0] m3_data_o;
	wire m3_ack_o;
	wire s0_cyc_o;
	wire s0_stb_o;
	wire [31:2] s0_addr_o;
	wire [2:0] s0_cti_o;
	wire [1:0] s0_bte_o;
	wire [3:0] s0_sel_o;
	wire s0_we_o;
	wire [31:0] s0_data_o;
	wire s1_cyc_o;
	wire s1_stb_o;
	wire [31:2] s1_addr_o;
	wire [2:0] s1_cti_o;
	wire [1:0] s1_bte_o;
	wire [3:0] s1_sel_o;
	wire s1_we_o;
	wire [31:0] s1_data_o;
	wire s2_cyc_o;
	wire s2_stb_o;
	wire [31:2] s2_addr_o;
	wire [2:0] s2_cti_o;
	wire [1:0] s2_bte_o;
	wire [3:0] s2_sel_o;
	wire s2_we_o;
	wire [31:0] s2_data_o;

	// Instantiate the Unit Under Test (UUT)
	wb_arb uut (
		.wb_clk(wb_clk), 
		.wb_rst(wb_rst), 
		.invalid_addr(invalid_addr), 
		.m0_cyc_i(m0_cyc_i), 
		.m0_stb_i(m0_stb_i), 
		.m0_addr_i(m0_addr_i), 
		.m0_cti_i(m0_cti_i), 
		.m0_bte_i(m0_bte_i), 
		.m0_sel_i(m0_sel_i), 
		.m0_we_i(m0_we_i), 
		.m0_data_o(m0_data_o), 
		.m0_data_i(m0_data_i), 
		.m0_ack_o(m0_ack_o), 
		.m1_cyc_i(m1_cyc_i), 
		.m1_stb_i(m1_stb_i), 
		.m1_addr_i(m1_addr_i), 
		.m1_cti_i(m1_cti_i), 
		.m1_bte_i(m1_bte_i), 
		.m1_sel_i(m1_sel_i), 
		.m1_we_i(m1_we_i), 
		.m1_data_o(m1_data_o), 
		.m1_data_i(m1_data_i), 
		.m1_ack_o(m1_ack_o), 
		.m2_cyc_i(m2_cyc_i), 
		.m2_stb_i(m2_stb_i), 
		.m2_addr_i(m2_addr_i), 
		.m2_cti_i(m2_cti_i), 
		.m2_bte_i(m2_bte_i), 
		.m2_sel_i(m2_sel_i), 
		.m2_we_i(m2_we_i), 
		.m2_data_o(m2_data_o), 
		.m2_data_i(m2_data_i), 
		.m2_ack_o(m2_ack_o), 
		.m3_cyc_i(m3_cyc_i), 
		.m3_stb_i(m3_stb_i), 
		.m3_addr_i(m3_addr_i), 
		.m3_cti_i(m3_cti_i), 
		.m3_bte_i(m3_bte_i), 
		.m3_sel_i(m3_sel_i), 
		.m3_we_i(m3_we_i), 
		.m3_data_o(m3_data_o), 
		.m3_data_i(m3_data_i), 
		.m3_ack_o(m3_ack_o), 
		.s0_cyc_o(s0_cyc_o), 
		.s0_stb_o(s0_stb_o), 
		.s0_addr_o(s0_addr_o), 
		.s0_cti_o(s0_cti_o), 
		.s0_bte_o(s0_bte_o), 
		.s0_sel_o(s0_sel_o), 
		.s0_we_o(s0_we_o), 
		.s0_data_i(s0_data_i), 
		.s0_data_o(s0_data_o), 
		.s0_ack_i(s0_ack_i), 
		.s1_cyc_o(s1_cyc_o), 
		.s1_stb_o(s1_stb_o), 
		.s1_addr_o(s1_addr_o), 
		.s1_cti_o(s1_cti_o), 
		.s1_bte_o(s1_bte_o), 
		.s1_sel_o(s1_sel_o), 
		.s1_we_o(s1_we_o), 
		.s1_data_i(s1_data_i), 
		.s1_data_o(s1_data_o), 
		.s1_ack_i(s1_ack_i), 
		.s2_cyc_o(s2_cyc_o), 
		.s2_stb_o(s2_stb_o), 
		.s2_addr_o(s2_addr_o), 
		.s2_cti_o(s2_cti_o), 
		.s2_bte_o(s2_bte_o), 
		.s2_sel_o(s2_sel_o), 
		.s2_we_o(s2_we_o), 
		.s2_data_i(s2_data_i), 
		.s2_data_o(s2_data_o), 
		.s2_ack_i(s2_ack_i)
	);

	initial begin
		// Initialize Inputs
		wb_clk = 0;
		wb_rst = 0;
		m0_cyc_i = 0;
		m0_stb_i = 0;
		m0_addr_i = 0;
		m0_cti_i = 0;
		m0_bte_i = 0;
		m0_sel_i = 0;
		m0_we_i = 0;
		m0_data_i = 0;
		m1_cyc_i = 0;
		m1_stb_i = 0;
		m1_addr_i = 0;
		m1_cti_i = 0;
		m1_bte_i = 0;
		m1_sel_i = 0;
		m1_we_i = 0;
		m1_data_i = 0;
		m2_cyc_i = 0;
		m2_stb_i = 0;
		m2_addr_i = 0;
		m2_cti_i = 0;
		m2_bte_i = 0;
		m2_sel_i = 0;
		m2_we_i = 0;
		m2_data_i = 0;
		m3_cyc_i = 0;
		m3_stb_i = 0;
		m3_addr_i = 0;
		m3_cti_i = 0;
		m3_bte_i = 0;
		m3_sel_i = 0;
		m3_we_i = 0;
		m3_data_i = 0;
		s0_data_i = 0;
		s0_ack_i = 0;
		s1_data_i = 0;
		s1_ack_i = 0;
		s2_data_i = 0;
		s2_ack_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		#11;  // make sure all data change below occurs after the posedge of clock
		#100 m0_cyc_i = 1;
		#100 m1_cyc_i = 1;
		#100 m2_cyc_i = 1;
		#100 m1_cyc_i = 0;
		#100 m0_cyc_i = 0;
		#100 m1_cyc_i = 1;
		#100 m2_cyc_i = 0;
		#100 m1_cyc_i = 0;

	end
	initial forever #10 wb_clk = ~wb_clk;

endmodule

