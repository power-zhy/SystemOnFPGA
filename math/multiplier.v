`include "define.vh"


/**
 * 4-based Booth Multiplier.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module multiplier (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire en,  // calculation enable signal
	input wire sign,  // signed/unsigned flag
	input wire [DATA_BITS-1:0] multiplicand,  // multiplicand
	input wire [DATA_BITS-1:0] multiplier,  // multiplier
	output reg done = 0,  // calculation complete flag
	output wire [RESULT_BITS-1:0] product  // multiplication result
	);
	
	`include "function.vh"
	parameter
		DATA_BITS = 32;
	localparam
		RESULT_BITS = 2*DATA_BITS,
		COUNT_BITS = GET_WIDTH(DATA_BITS-1);
	
	// to deal with signed and unsigned together, we add 2 bits to both multiplier and multiplicand
	reg [DATA_BITS+1:0] cand;
	reg [DATA_BITS+1:0] temp;
	reg [RESULT_BITS+3:0] result;
	reg load, shift;
	reg [COUNT_BITS-1:0] counter;
	reg last;
	
	localparam
		S_IDLE  = 0,
		S_CALC  = 1,
		S_LAST  = 2,
		S_DONE  = 3;
	
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
					next_state = S_LAST;
				else
					next_state = S_CALC;
			end
			S_LAST: begin
				shift = 1;
				next_state = S_DONE;
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
	
	always @(*) begin
		case({result[1:0], last})
			3'b001, 3'b010:
				temp = result[RESULT_BITS+3:DATA_BITS+2] + cand;
			3'b101, 3'b110:
				temp = result[RESULT_BITS+3:DATA_BITS+2] - cand;
			3'b011:
				temp = result[RESULT_BITS+3:DATA_BITS+2] + (cand << 1);
			3'b100:
				temp = result[RESULT_BITS+3:DATA_BITS+2] - (cand << 1);
			default:
				temp = result[RESULT_BITS+3:DATA_BITS+2];
		endcase
	end
	
	always @(posedge clk) begin
		if (rst) begin
			cand <= 0;
			result <= 0;
			counter <= 0;
			last <= 0;
		end
		else if (load) begin
			cand <= {{2{sign?multiplicand[DATA_BITS-1]:1'b0}}, multiplicand};
			result <= {{DATA_BITS+2{1'b0}}, {2{sign?multiplier[DATA_BITS-1]:1'b0}}, multiplier};
			counter <= 0;
			last <= 0;
		end
		else if (shift) begin
			{result, last} <= {{2{temp[DATA_BITS+1]}}, temp, result[DATA_BITS+1:1]};
			counter <= counter + 1'h1;
		end
	end
	
	assign
		product = result[RESULT_BITS-1:0];
	
endmodule
