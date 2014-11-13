`timescale 1ns / 1ps

module sim_fifo_asy;
	// Inputs
	reg rst;
	reg clk_w;
	reg en_w;
	reg [31:0] data_w;
	reg clk_r;
	reg en_r;
	
	// Outputs
	wire full_w;
	wire near_full_w;
	wire [7:0] space_count;
	wire [31:0] data_r;
	wire empty_r;
	wire near_empty_r;
	wire [7:0] data_count;
	
	// Instantiate the Unit Under Test (UUT)
	fifo_asy uut (
		.rst(rst), 
		.clk_w(clk_w), 
		.en_w(en_w), 
		.data_w(data_w), 
		.full_w(full_w), 
		.near_full_w(near_full_w), 
		.space_count(space_count), 
		.clk_r(clk_r), 
		.en_r(en_r), 
		.data_r(data_r), 
		.empty_r(empty_r), 
		.near_empty_r(near_empty_r), 
		.data_count(data_count)
	);
	
	initial begin
		// Initialize Inputs
		rst = 0;
		clk_w = 0;
		en_w = 0;
		data_w = 0;
		clk_r = 0;
		en_r = 0;
	end
	
	initial forever #10 clk_w = ~clk_w;
	initial begin
		#20 en_w = 1; data_w = 1001;
		#20 en_w = 0; data_w = 1002;
		#20 en_w = 0; data_w = 1003;
		#20 en_w = 0; data_w = 1004;
		#20 en_w = 0; data_w = 1005;
		#20 en_w = 0; data_w = 1006;
		#20 en_w = 1; data_w = 1007;
		#20 en_w = 0; data_w = 1008;
		#20 en_w = 0; data_w = 1009;
		#20 en_w = 0; data_w = 1010;
		#20 en_w = 0; data_w = 1011;
		#20 en_w = 1; data_w = 1012;
		#20 en_w = 0; data_w = 1013;
		#20 en_w = 0; data_w = 1014;
		#20 en_w = 0; data_w = 1015;
		#20 en_w = 0; data_w = 1016;
		#20 en_w = 0; data_w = 1017;
		#20 en_w = 0; data_w = 1018;
		#20 en_w = 0; data_w = 1019;
		#20 en_w = 0; data_w = 1020;
		#20 en_w = 0; data_w = 1021;
		#20 en_w = 0; data_w = 1022;
		#20 en_w = 1; data_w = 1023;
		#20 en_w = 1; data_w = 1024;
		#20 en_w = 1; data_w = 1025;
		#20 en_w = 0; data_w = 1026;
	end
	
	initial forever #50 clk_r = ~clk_r;
	initial begin
		#100 en_r = 1;
		#100 en_r = 1;
		#100 en_r = 1;
		#100 en_r = 0;
		#100 en_r = 0;
	end
	
endmodule
