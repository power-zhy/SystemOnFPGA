`timescale 1ns / 1ps

module sim_fifo;
	// Inputs
	reg clk;
	reg rst;
	reg en_w;
	reg [31:0] data_w;
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
	fifo #(
		.DETECT_WEN_EDGE(0),
		.DETECT_REN_EDGE(1)
		) uut (
		.clk(clk),
		.rst(rst),
		.en_w(en_w),
		.data_w(data_w),
		.full_w(full_w),
		.near_full_w(near_full_w),
		.space_count(space_count),
		.en_r(en_r),
		.data_r(data_r),
		.empty_r(empty_r),
		.near_empty_r(near_empty_r),
		.data_count(data_count)
	);
	
	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		en_w = 0;
		data_w = 0;
		en_r = 0;
	end
	
	initial forever #10 clk = ~clk;
	
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
	end
	
	initial begin
		#90
		#50 en_r = 1; #50 en_r = 0;
		#50 en_r = 1; #50 en_r = 0;
		#50 en_r = 1; #50 en_r = 0;
	end
	
endmodule
