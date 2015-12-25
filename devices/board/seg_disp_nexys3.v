`include "define.vh"


/**
 * Display number using 7-segment tubes.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module seg_disp_nexys3 (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire [3:0] en,  // enable for each tube
	input wire mode,  // 0 for text mode, 1 for graphic mode
	input wire [15:0] data_text,  // text data to display
	input wire [31:0] data_graphic,  // graphic data to display
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
	
	wire [7:0] segment_disp;
	reg [7:0] segment_text, segment_graphic;
	reg [3:0] anode_disp;
	
	always @(*) begin
		segment_text = 0;
		segment_graphic = 0;
		anode_disp = 0;
		case (clk_count[CLK_COUNT_WIDTH-1:CLK_COUNT_WIDTH-2])
			2'h0: begin
				anode_disp = en[0] ? 4'b0001 : 4'b0000;
				segment_text[7] = dot[0];
				segment_text[6:0] = digit2seg(data_text[3:0]);
				segment_graphic = data_graphic[7:0];
			end
			2'h1: begin
				anode_disp = en[1] ? 4'b0010 : 4'b0000;
				segment_text[7] = dot[1];
				segment_text[6:0] = digit2seg(data_text[7:4]);
				segment_graphic = data_graphic[15:8];
			end
			2'h2: begin
				anode_disp = en[2] ? 4'b0100 : 4'b0000;
				segment_text[7] = dot[2];
				segment_text[6:0] = digit2seg(data_text[11:8]);
				segment_graphic = data_graphic[23:16];
			end
			2'h3: begin
				anode_disp = en[3] ? 4'b1000 : 4'b0000;
				segment_text[7] = dot[3];
				segment_text[6:0] = digit2seg(data_text[15:12]);
				segment_graphic = data_graphic[31:24];
			end
		endcase
	end
	
	assign
		segment_disp = mode ? segment_graphic : segment_text;
	
	always @(posedge clk) begin
		segment = SEG_PULSE ? segment_disp : ~segment_disp;
		anode = AN_PULSE ? anode_disp : ~anode_disp;
	end
	
endmodule
