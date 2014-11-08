`include "define.vh"


/**
 * Interrupt converter, use a fast clock to sample interrupt signals.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module ir_conv (
	input wire clk,  // sample clock
	input wire rst,  // synchronous reset
	input wire [INTERRUPT_NUMBER-1:0] ir_i,  // input interrupt signals
	output wire [INTERRUPT_NUMBER-1:0] ir_o  // detected interrupt signals
	);
	
	parameter
		INTERRUPT_NUMBER = 30,  // number of interrupt signals
		INTERRUPT_DELAY = 10;  // how many clocks should output signals stay on 1
	
	genvar i;
	generate for (i=0; i<INTERRUPT_NUMBER; i=i+1) begin: CONVERTER
		reg [INTERRUPT_DELAY-1:0] shifter;
		always @(posedge clk) begin
			if (rst)
				shifter <= 0;
			else
				shifter <= {shifter[INTERRUPT_DELAY-2:0], ir_i[i]};
		end
		assign ir_o[i] = (shifter != 0);
	end
	endgenerate
	
endmodule
