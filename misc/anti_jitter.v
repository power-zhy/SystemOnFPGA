`include "define.vh"


/**
 * Anti-jitter for input buttons and switches on board.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module anti_jitter (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire sig_i,  // input signal with jitter noises
	output reg sig_o = INIT_VALUE  // output signal without jitter noises
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100,  // main clock frequency in MHz
		JITTER_MAX = 10000;  // longest time for jitter noises in us
	parameter
		INIT_VALUE = 0;  // initialized output value
	localparam
		CLK_COUNT = CLK_FREQ * JITTER_MAX,  // CLK_FREQ * 1000000 / (1000000 / JITTER_MAX)
		CLK_COUNT_WIDTH = GET_WIDTH(CLK_COUNT-1);
	
	reg [CLK_COUNT_WIDTH-1:0] clk_count = 0;
	
	always @(posedge clk) begin
		if (rst) begin
			clk_count <= 0;
			sig_o <= INIT_VALUE;
		end
		else if (sig_i == sig_o) begin
			clk_count <= 0;
		end
		else if (clk_count == CLK_COUNT-1) begin
			clk_count <= 0;
			sig_o <= sig_i;
		end
		else begin
			clk_count <= clk_count + 1'h1;
		end
	end
	
endmodule
