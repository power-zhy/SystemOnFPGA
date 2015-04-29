`include "define.vh"


/**
 * Clock generator.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module clk_step (
	input wire clk_i,  // input clock source
	input wire step_en,  // enable step mode
	input wire step_i,  // step control
	output reg clk_en,  // clock enable signal
	output reg clk_o  // clock output
	);
	
	reg step_prev;
	always @(negedge clk_i) begin
		step_prev <= step_i;
		clk_en <= (step_i & (~step_prev)) | (~step_en);
	end
	
	BUFGCE CLK_EN (.I(clk_i), .CE(clk_en), .O(clk_o));
	
endmodule
