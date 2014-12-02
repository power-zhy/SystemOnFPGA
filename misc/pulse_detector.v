`include "define.vh"


/**
 * Pulse Detector, mostly used by slow clock to detect pulse in fast clock domain.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module pulse_detector (
	input wire clk_i,  // data clock
	input wire dat_i,  // input data
	input wire clk_d,  // detect clock
	output reg dat_d  // detected data
	);
	
	parameter
		PULSE_VALUE = 1;  // which pulse to detect
	
	reg buff;
	
	always @(posedge clk_i) begin
		if (dat_i == PULSE_VALUE)
			buff <= dat_i;
		else if (dat_d == PULSE_VALUE)
			buff <= dat_i;
	end
	
	always @(posedge clk_d) begin
		dat_d <= buff;
	end
	
endmodule
