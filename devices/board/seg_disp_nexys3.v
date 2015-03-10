`include "define.vh"


/**
 * Display number using 7-segment tubes.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module seg_disp_nexys3 (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire [3:0] en,  // enable for each tube
	input wire [15:0] data,  // data to display
	input wire [3:0] dot,  // enable for each dot
	// 7-segment tube interfaces
	output reg [7:0] segment,
	output reg [3:0] anode
	);
	
	localparam
		AN_PULSE = 1'b0,
		SEG_PULSE = 1'b0;
	localparam
		CLK_COUNT_WIDTH = 16;
	
	function [6:0] digit2seg;
		input [3:0] number;
		begin
			case (number)
				4'h0: digit2seg = 7'b0111111;
				4'h1: digit2seg = 7'b0000110;
				4'h2: digit2seg = 7'b1011011;
				4'h3: digit2seg = 7'b1001111;
				4'h4: digit2seg = 7'b1100110;
				4'h5: digit2seg = 7'b1101101;
				4'h6: digit2seg = 7'b1111101;
				4'h7: digit2seg = 7'b0000111;
				4'h8: digit2seg = 7'b1111111;
				4'h9: digit2seg = 7'b1101111;
				4'hA: digit2seg = 7'b1110111;
				4'hB: digit2seg = 7'b1111100;
				4'hC: digit2seg = 7'b0111001;
				4'hD: digit2seg = 7'b1011110;
				4'hE: digit2seg = 7'b1111001;
				4'hF: digit2seg = 7'b1110001;
			endcase
		end
	endfunction
	
	reg [CLK_COUNT_WIDTH-1:0] clk_count;
	
	always @(posedge clk) begin
		if (rst)
			clk_count <= 0;
		else
			clk_count <= clk_count + 1'h1;
	end
	
	always @(posedge clk) begin
		segment <= {8{~SEG_PULSE}};
		anode <= {4{~AN_PULSE}};
		case (clk_count[CLK_COUNT_WIDTH-1:CLK_COUNT_WIDTH-2])
			2'h0: begin
				anode <= {{3{~AN_PULSE}}, AN_PULSE};
				segment[7] <= dot[0] ? SEG_PULSE : ~SEG_PULSE;
				segment[6:0] <= en[0] ? (SEG_PULSE ? digit2seg(data[3:0]) : ~digit2seg(data[3:0])) : {7{~SEG_PULSE}};
			end
			2'h1: begin
				anode <= {{2{~AN_PULSE}}, AN_PULSE, ~AN_PULSE};
				segment[7] <= dot[1] ? SEG_PULSE : ~SEG_PULSE;
				segment[6:0] <= en[1] ? (SEG_PULSE ? digit2seg(data[7:4]) : ~digit2seg(data[7:4])) : {7{~SEG_PULSE}};
			end
			2'h2: begin
				anode <= {~AN_PULSE, AN_PULSE, {2{~AN_PULSE}}};
				segment[7] <= dot[2] ? SEG_PULSE : ~SEG_PULSE;
				segment[6:0] <= en[2] ? (SEG_PULSE ? digit2seg(data[11:8]) : ~digit2seg(data[11:8])) : {7{~SEG_PULSE}};
			end
			2'h3: begin
				anode <= {AN_PULSE, {3{~AN_PULSE}}};
				segment[7] <= dot[3] ? SEG_PULSE : ~SEG_PULSE;
				segment[6:0] <= en[3] ? (SEG_PULSE ? digit2seg(data[15:12]) : ~digit2seg(data[15:12])) : {7{~SEG_PULSE}};
			end
		endcase
	end
	
endmodule
