`include "define.vh"


/**
 * Divider.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module divider (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire en,  // calculation enable signal
	input wire sign,  // signed/unsigned flag
	input wire [DATA_BITS-1:0] dividend,  // dividend
	input wire [DATA_BITS-1:0] divisor,  // divisor
	output reg done = 0,  // calculation complete flag
	output wire [DATA_BITS-1:0] quotient,  // multiplication quotient
	output wire [DATA_BITS-1:0] remainder  // multiplication remainder
	);
	
	`include "function.vh"
	parameter
		DATA_BITS = 32;
	localparam
		RESULT_BITS = 2*DATA_BITS,
		COUNT_BITS = GET_WIDTH(DATA_BITS-1);
	
	reg [DATA_BITS-1:0] dsor;
	reg [DATA_BITS-1:0] temp;
	reg [RESULT_BITS-1:0] result;
	reg neg_quot, neg_rem;
	reg load, shift;
	reg [COUNT_BITS-1:0] counter;
	reg last;
	
	localparam
		S_IDLE  = 0,
		S_CALC  = 1,
		S_DONE  = 2;
	
	reg [1:0] state = 0;
	reg [1:0] next_state;
	
	always @(*) begin
		done = 0;
		load = 0;
		shift = 0;
		next_state = S_IDLE;
		case (state)
			S_IDLE: begin
				if (en) begin
					load = 1;
					next_state = S_CALC;
				end
			end
			S_CALC: begin
				shift = 1;
				if (counter == {COUNT_BITS{1'b1}})
					next_state = S_DONE;
				else
					next_state = S_CALC;
			end
			S_DONE: begin
				done = 1;
				next_state = S_IDLE;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst)
			state <= 0;
		else
			state <= next_state;
	end
	
	assign
		temp = result[RESULT_BITS-1:DATA_BITS] - dsor;
	
	always @(posedge clk) begin
		if (rst) begin
			dsor <= 0;
			neg_quot <= 0;
			neg_rem <= 0;
			result <= 0;
			counter <= 0;
			last <= 0;
		end
		else if (load) begin
			dsor <= (sign & divisor[DATA_BITS-1]) ? (~divisor + 1'h1) : divisor;
			neg_quot <= sign ? divisor[DATA_BITS-1] ^ dividend[DATA_BITS-1] : 1'b0;
			neg_rem <= sign ? dividend[DATA_BITS-1] : 1'b0;
			result <= {{DATA_BITS-1{1'b0}}, (sign&dividend[DATA_BITS-1])?(~dividend+1'h1):dividend, 1'b0};
			counter <= 0;
			last <= 0;
		end
		else if (shift) begin
			{last, result} <= temp[DATA_BITS-1] ? {result[RESULT_BITS-1:0], 1'b0} : {temp[DATA_BITS-1:0], result[DATA_BITS-1:0], 1'b1};
			counter <= counter + 1'h1;
		end
	end
	
	assign
		quotient = neg_quot ? (~result[DATA_BITS-1:0]+1'h1) : result[DATA_BITS-1:0],
		remainder = neg_rem ? (~{last,result[RESULT_BITS-1:DATA_BITS+1]}+1'h1) : {last,result[RESULT_BITS-1:DATA_BITS+1]};
	
endmodule
