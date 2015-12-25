`include "define.vh"


/**
 * VGA sync signals generator
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module vga_core_sword (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire clk_base,  // base clock used to generate VGA's clock, should be at 25MHz
	output wire vga_clk,  // clock for VGA signals, the same as clk_base
	output reg vga_valid,  // sync signals valid flag
	output reg [H_COUNT_WIDTH-1:0] h_count,  // horizontal sync count
	output reg [V_COUNT_WIDTH-1:0] v_count,  // vertical sync count
	output reg [P_COUNT_WIDTH-1:0] p_count,  // pixel count
	output reg [H_COUNT_WIDTH-1:0] h_disp_max,  // maximum number of horizontal lines for display
	output reg [V_COUNT_WIDTH-1:0] v_disp_max,  // maximum number of vertical lines for display
	output reg [P_COUNT_WIDTH-1:0] p_disp_max,  // maximum number of pixels for display
	output reg h_sync,  // horizontal sync
	output reg v_sync,  // vertical sync
	output reg h_en,  // scan line inside horizontal display range
	output reg v_en  // scan line inside vertical display range
	);
	
	`include "function.vh"
	`include "vga_define.vh"
	// TODO add different resolution support
	
	reg [H_COUNT_WIDTH-1:0] h_sync_start, h_sync_end, h_disp_start, h_disp_end;
	reg [V_COUNT_WIDTH-1:0] v_sync_start, v_sync_end, v_disp_start, v_disp_end;
	reg h_pulse_value, v_pulse_value;
	
	wire [H_COUNT_WIDTH-1:0] h_count_next;
	wire [V_COUNT_WIDTH-1:0] v_count_next;
	wire [P_COUNT_WIDTH-1:0] p_count_next;
	
	always @(*) begin
		h_disp_max = VGA_640_480_60_H_DISP - 1;
		v_disp_max = VGA_640_480_60_V_DISP - 1;
		p_disp_max = VGA_640_480_60_H_DISP * VGA_640_480_60_V_DISP - 1;
		h_sync_start = VGA_640_480_60_H_DISP + VGA_640_480_60_H_FP - 1;
		h_sync_end = VGA_640_480_60_H_DISP + VGA_640_480_60_H_FP + VGA_640_480_60_H_PW - 1;
		h_disp_start = VGA_640_480_60_H_DISP + VGA_640_480_60_H_FP + VGA_640_480_60_H_PW + VGA_640_480_60_H_BP - 1;
		h_disp_end = VGA_640_480_60_H_DISP - 1;
		h_pulse_value = VGA_640_480_60_H_PV;
		v_sync_start = VGA_640_480_60_V_DISP + VGA_640_480_60_V_FP - 1;
		v_sync_end = VGA_640_480_60_V_DISP + VGA_640_480_60_V_FP + VGA_640_480_60_V_PW - 1;
		v_disp_start = VGA_640_480_60_V_DISP + VGA_640_480_60_V_FP + VGA_640_480_60_V_PW + VGA_640_480_60_V_BP - 1;
		v_disp_end = VGA_640_480_60_V_DISP - 1;
		v_pulse_value = VGA_640_480_60_V_PV;
	end
	
	assign
		vga_clk = clk_base;
	
	assign
		h_count_next = h_count + 1'h1,
		v_count_next = v_count + 1'h1,
		p_count_next = p_count + 1'h1;
	
	always @(posedge vga_clk) begin
		if (rst) begin
			vga_valid <= 0;
			h_count <= h_sync_start;
			v_count <= v_sync_start;
			h_sync <= h_pulse_value;
			v_sync <= v_pulse_value;
			h_en <= 0;
			v_en <= 0;
			p_count <= 0;
		end
		else begin
			vga_valid <= 1;
			if (h_count == h_sync_end) begin
				h_count <= h_count_next;
				h_sync <= ~h_pulse_value;
			end
			else if (h_count == h_disp_start) begin
				h_count <= 0;
				h_en <= 1;
			end
			else if (h_count == h_disp_end) begin
				h_count <= h_count_next;
				h_en <= 0;
			end
			else if (h_count == h_sync_start) begin
				h_count <= h_count_next;
				h_sync <= h_pulse_value;
				if (v_count == v_sync_end) begin
					v_count <= v_count_next;
					v_sync <= ~v_pulse_value;
				end
				else if (v_count == v_disp_start) begin
					v_count <= 0;
					v_en <= 1;
				end
				else if (v_count == v_disp_end) begin
					v_count <= v_count_next;
					v_en <= 0;
				end
				else if (v_count == v_sync_start) begin
					v_count <= v_count_next;
					v_sync <= v_pulse_value;
				end
				else begin
					v_count <= v_count_next;
				end
			end
			else begin
				h_count <= h_count_next;
			end
			if (~v_en)
				p_count <= 0;
			else if (h_en)
				p_count <= p_count_next;
		end
	end
	
endmodule
