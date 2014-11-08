`include "define.vh"


/**
 * Shifter.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module shifter (
	input wire [31:0] a,  // operand to be shifted
	input wire [4:0] b,  // shift amount
	input wire dirt,  // 0 for shift left, 1 for right
	input wire sign,  // 0 for logical shift, 1 for arithmetic
	input wire rotate,  // 1 for rotate shift and ignore sign
	output wire [31:0] result  // calculation result
	);
	
	wire in;
	wire [31:0] r0, r1, r2, r3, r4;
	
	assign
		in = dirt & sign & a[31];
	assign
		r4 = b[4] ? (dirt ? {(rotate ? a[15:0] : {16{in}}), a[31:16]} : {a[15:0], (rotate ? a[31:16] : {16{in}})}) : a,
		r3 = b[3] ? (dirt ? {(rotate ? r4[7:0] : {8{in}}), r4[31:8]} : {r4[23:0], (rotate ? r4[31:24] : {8{in}})}) : r4,
		r2 = b[2] ? (dirt ? {(rotate ? r3[3:0] : {4{in}}), r3[31:4]} : {r3[27:0], (rotate ? r3[31:28] : {4{in}})}) : r3,
		r1 = b[1] ? (dirt ? {(rotate ? r2[1:0] : {2{in}}), r2[31:2]} : {r2[29:0], (rotate ? r2[31:30] : {2{in}})}) : r2,
		r0 = b[0] ? (dirt ? {(rotate ? r1[0] : in), r1[31:1]} : {r1[30:0], (rotate ? r1[31] : in)}) : r1;
	assign
		result = r0;
	
endmodule
