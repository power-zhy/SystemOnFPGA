`include "define.vh"


/**
 * Arithmetic and Logic Unit for MIPS CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module alu (
	input wire [31:0] a, b,  // two operands
	input wire sign,  // signed/unsigned flag
	input wire [3:0] oper,  // operation type
	output reg [31:0] result,  // calculation result
	output reg overflow  // overflow flag
	);
	
	`include "mips_define.vh"
	
	reg adder_mode;
	wire [31:0] adder_result;
	wire adder_cf, adder_of;
	reg shifter_dirt;
	reg shifter_rotate;
	wire [31:0] shifter_result;
	
	adder #(
		.N(32)
		) ADDER (
		.a(a),
		.b(b),
		.mode(adder_mode),
		.result(adder_result),
		.carry(adder_cf),
		.overflow(adder_of)
		);
	
	shifter SHIFTER (
		.a(b),
		.b(a[4:0]),
		.dirt(shifter_dirt),
		.sign(sign),
		.rotate(shifter_rotate),
		.result(shifter_result)
		);
	
	always @(*) begin
		adder_mode = 0;
		shifter_dirt = 0;
		shifter_rotate = 0;
		result = 0;
		overflow = 0;
		case (oper)
			EXE_ALU_ADD: begin
				adder_mode = 0;
				result = adder_result;
				overflow = adder_of & sign;
			end
			EXE_ALU_SUB: begin
				adder_mode = 1;
				result = adder_result;
				overflow = adder_of & sign;
			end
			EXE_ALU_SLT: begin
				adder_mode = 1;
				if (sign)
					result = {31'b0, adder_of ^ adder_result[31]};
				else
					result = {31'b0, adder_cf};
			end
			EXE_ALU_LUI: begin
				result = {b[15:0], 16'b0};
			end
			EXE_ALU_AND: begin
				result = a & b;
			end
			EXE_ALU_OR: begin
				result = a | b;
			end
			EXE_ALU_XOR: begin
				result = a ^ b;
			end
			EXE_ALU_NOR: begin
				result = ~(a | b);
			end
			EXE_ALU_SLL: begin
				shifter_dirt = 0;
				shifter_rotate = 0;
				result = shifter_result;
			end
			EXE_ALU_SRL: begin
				shifter_dirt = 1;
				shifter_rotate = 0;
				result = shifter_result;
			end
			EXE_ALU_ROTR: begin
				shifter_dirt = 1;
				shifter_rotate = 1;
				result = shifter_result;
			end
			EXE_ALU_SLLV: begin
				shifter_dirt = 0;
				shifter_rotate = 0;
				result = shifter_result;
			end
			EXE_ALU_SRLV: begin
				shifter_dirt = 1;
				shifter_rotate = 0;
				result = shifter_result;
			end
			EXE_ALU_ROTRV: begin
				shifter_dirt = 1;
				shifter_rotate = 1;
				result = shifter_result;
			end
		endcase
	end
	
endmodule
