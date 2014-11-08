`include "define.vh"

/**
 * Carry look-ahead adder
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */


module inner_pg_1 (
	input wire a, b,
	output wire p, g
	);
	
	assign p = a | b;
	assign g = a & b;

endmodule


module inner_pg_4 (
	input wire [3:0] p, g,
	output wire p_group, g_group
	);
	
	assign p_group = p[0] & p[1] & p[2] & p[3];
	assign g_group = (g[0] & p[1] & p[2] & p[3]) | (g[1] & p[2] & p[3]) | (g[2] & p[3]) | g[3];

endmodule


module adder_4 (
	input wire [3:0] a, b,
	input wire cin,
	output wire [3:0] s,
	output wire [4:1] cout,
	output wire p_4, g_4
	);
	
	wire [3:0] p, g;
	
	inner_pg_1
		PG0 (.a(a[0]), .b(b[0]), .p(p[0]), .g(g[0])),
		PG1 (.a(a[1]), .b(b[1]), .p(p[1]), .g(g[1])),
		PG2 (.a(a[2]), .b(b[2]), .p(p[2]), .g(g[2])),
		PG3 (.a(a[3]), .b(b[3]), .p(p[3]), .g(g[3]));
	inner_pg_4
		PG4 (.p(p), .g(g), .p_group(p_4), .g_group(g_4));
	
	assign
		cout[1] = g[0] | (p[0] & cin),
		cout[2] = g[1] | (p[1] & cout[1]),
		cout[3] = g[2] | (p[2] & cout[2]),
		cout[4] = g_4 | (p_4 & cin);
	assign
		s[0] = a[0] ^ b[0] ^ cin,
		s[1] = a[1] ^ b[1] ^ cout[1],
		s[2] = a[2] ^ b[2] ^ cout[2],
		s[3] = a[3] ^ b[3] ^ cout[3];
	
endmodule


module adder_16 (
	input wire [15:0] a, b,
	input wire cin,
	output wire [15:0] s,
	output wire [16:1] cout,
	output wire p_16, g_16
	);
	
	wire [3:0] p_4, g_4;
	wire c_tmp;
	
	adder_4
		ADD0 (.a(a[3:0]), .b(b[3:0]), .cin(cin), .s(s[3:0]), .cout(cout[4:1]), .p_4(p_4[0]), .g_4(g_4[0])),
		ADD1 (.a(a[7:4]), .b(b[7:4]), .cin(cout[4]), .s(s[7:4]), .cout(cout[8:5]), .p_4(p_4[1]), .g_4(g_4[1])),
		ADD2 (.a(a[11:8]), .b(b[11:8]), .cin(cout[8]), .s(s[11:8]), .cout(cout[12:9]), .p_4(p_4[2]), .g_4(g_4[2])),
		ADD3 (.a(a[15:12]), .b(b[15:12]), .cin(cout[12]), .s(s[15:12]), .cout({c_tmp, cout[15:13]}), .p_4(p_4[3]), .g_4(g_4[3]));
	
	inner_pg_4
		PG16 (.p(p_4), .g(g_4), .p_group(p_16), .g_group(g_16));
	
	assign
		cout[16] = g_16 | (p_16 & cin);
	
endmodule

/*
module adder_64 (
	input wire [63:0] a, b,
	input wire cin,
	output wire [63:0] s,
	output wire cout,
	output wire p_64, g_64
	);
	
	wire [3:0] p_16, g_16;
	wire [3:0] c;
	
	adder_16
		ADD0 (.a(a[15:0]), .b(b[15:0]), .cin(cin), .s(s[15:0]), .cout(c[0]), .p_16(p_16[0]), .g_16(g_16[0])),
		ADD1 (.a(a[31:16]), .b(b[31:16]), .cin(c[0]), .s(s[31:16]), .cout(c[1]), .p_16(p_16[1]), .g_16(g_16[1])),
		ADD2 (.a(a[47:32]), .b(b[47:32]), .cin(c[1]), .s(s[47:32]), .cout(c[2]), .p_16(p_16[2]), .g_16(g_16[2])),
		ADD3 (.a(a[63:48]), .b(b[63:48]), .cin(c[2]), .s(s[63:48]), .cout(c[3]), .p_16(p_16[3]), .g_16(g_16[3]));
	
	inner_pg_4
		PG16 (.p(p_16), .g(g_16), .p_group(p_64), .g_group(g_64));
	
	assign
		cout = g_64 | (p_64 & cin);
	
endmodule


module adder_256 (
	input wire [255:0] a, b,
	input wire cin,
	output wire [255:0] s,
	output wire cout,
	output wire p_256, g_256
	);
	
	wire [3:0] p_64, g_64;
	wire [3:0] c;
	
	adder_64
		ADD0 (.a(a[63:0]), .b(b[63:0]), .cin(cin), .s(s[63:0]), .cout(c[0]), .p_64(p_64[0]), .g_64(g_64[0])),
		ADD1 (.a(a[127:64]), .b(b[127:64]), .cin(c[0]), .s(s[127:64]), .cout(c[1]), .p_64(p_64[1]), .g_64(g_64[1])),
		ADD2 (.a(a[191:128]), .b(b[191:128]), .cin(c[1]), .s(s[191:128]), .cout(c[2]), .p_64(p_64[2]), .g_64(g_64[2])),
		ADD3 (.a(a[255:192]), .b(b[255:192]), .cin(c[2]), .s(s[255:192]), .cout(c[3]), .p_64(p_64[3]), .g_64(g_64[3]));
	
	inner_pg_4
		PG16 (.p(p_64), .g(g_64), .p_group(p_256), .g_group(g_256));
	
	assign
		cout = g_256 | (p_256 & cin);
	
endmodule


module adder_1024 (
	input wire [1023:0] a, b,
	input wire cin,
	output wire [1023:0] s,
	output wire cout,
	output wire p_1024, g_1024
	);
	
	wire [3:0] p_256, g_256;
	wire [3:0] c;
	
	adder_256
		ADD0 (.a(a[255:0]), .b(b[255:0]), .cin(cin), .s(s[255:0]), .cout(c[0]), .p_256(p_256[0]), .g_256(g_256[0])),
		ADD1 (.a(a[511:256]), .b(b[511:256]), .cin(c[0]), .s(s[511:256]), .cout(c[1]), .p_256(p_256[1]), .g_256(g_256[1])),
		ADD2 (.a(a[767:512]), .b(b[767:512]), .cin(c[1]), .s(s[767:512]), .cout(c[2]), .p_256(p_256[2]), .g_256(g_256[2])),
		ADD3 (.a(a[1023:768]), .b(b[1023:768]), .cin(c[2]), .s(s[1023:768]), .cout(c[3]), .p_256(p_256[3]), .g_256(g_256[3]));
	
	inner_pg_4
		PG16 (.p(p_256), .g(g_256), .p_group(p_1024), .g_group(g_1024));
	
	assign
		cout = g_1024 | (p_1024 & cin);
	
endmodule


module adder_4096 (
	input wire [4095:0] a, b,
	input wire cin,
	output wire [4095:0] s,
	output wire cout,
	output wire p_4096, g_4096
	);
	
	wire [3:0] p_1024, g_1024;
	wire [3:0] c;
	
	adder_1024
		ADD0 (.a(a[1023:0]), .b(b[1023:0]), .cin(cin), .s(s[1023:0]), .cout(c[0]), .p_1024(p_1024[0]), .g_1024(g_1024[0])),
		ADD1 (.a(a[2047:1024]), .b(b[2047:1024]), .cin(c[0]), .s(s[2047:1024]), .cout(c[1]), .p_1024(p_1024[1]), .g_1024(g_1024[1])),
		ADD2 (.a(a[3071:2048]), .b(b[3071:2048]), .cin(c[1]), .s(s[3071:2048]), .cout(c[2]), .p_1024(p_1024[2]), .g_1024(g_1024[2])),
		ADD3 (.a(a[4095:3072]), .b(b[4095:3072]), .cin(c[2]), .s(s[4095:3072]), .cout(c[3]), .p_1024(p_1024[3]), .g_1024(g_1024[3]));
	
	inner_pg_4
		PG16 (.p(p_1024), .g(g_1024), .p_group(p_4096), .g_group(g_4096));
	
	assign
		cout = g_4096 | (p_4096 & cin);
	
endmodule
*/

module adder_32 (
	input wire [31:0] a, b,
	input wire cin,
	output wire [31:0] s,
	output wire [32:1] cout
	);
	
	adder_16
		ADD0 (.a(a[15:0]), .b(b[15:0]), .cin(cin), .s(s[15:0]), .cout(cout[16:1]), .p_16(), .g_16()),
		ADD1 (.a(a[31:16]), .b(b[31:16]), .cin(cout[16]), .s(s[31:16]), .cout(cout[32:17]), .p_16(), .g_16());
	
endmodule


module adder (
	input wire [N-1:0] a, b,
	input wire mode,  // 0 for add, 1 for sub
	output wire [N-1:0] result,
	output wire carry,
	output wire overflow
	);
	
	wire [N-1:0] bb;
	wire cin;
	wire [N:1] cout;
	
	assign bb = mode ? ~b : b;
	assign cin = mode;
	assign
		carry = cout[N] ^ mode,
		overflow = cout[N] ^ cout[N-1];
	
	parameter
		N = 32;  // bit length
	
	generate begin: ADDER_GEN
		case (N)
			4: adder_4 ADDER_4 (.a(a), .b(bb), .cin(cin), .s(result), .cout(cout));
			16: adder_16 ADDER_16 (.a(a), .b(bb), .cin(cin), .s(result), .cout(cout));
			32: adder_32 ADDER_32 (.a(a), .b(bb), .cin(cin), .s(result), .cout(cout));
			/*64: adder_64 ADDER_64 (.a(a), .b(bb), .cin(cin), .s(result), .cout(cout));
			256: adder_256 ADDER_256 (.a(a), .b(bb), .cin(cin), .s(result), .cout(cout));
			1024: adder_1024 ADDER_1024 (.a(a), .b(bb), .cin(cin), .s(result), .cout(cout));
			4096: adder_4096 ADDER_4096 (.a(a), .b(bb), .cin(cin), .s(result), .cout(cout));*/
			default: initial $display("Error: Illegal bit length %0d", N);
		endcase
	end
	endgenerate
	
endmodule
