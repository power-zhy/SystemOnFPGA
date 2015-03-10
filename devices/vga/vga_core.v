`include "define.vh"


/**
 * VGA sync signals generator
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module vga_core (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire clk_base,  // base clock used to generate VGA's clock, should be at 100MHz
	input wire [3:0] mode_in,  // VGA's mode, see "vga_define.vh" for details
	output wire vga_clk,  // clock for VGA signals, minimum is 25MHz
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
	
	reg [7:0] dcm_m, dcm_d;
	reg [H_COUNT_WIDTH-1:0] h_sync_start, h_sync_end, h_disp_start, h_disp_end;
	reg [V_COUNT_WIDTH-1:0] v_sync_start, v_sync_end, v_disp_start, v_disp_end;
	reg h_pulse_value, v_pulse_value;
	reg [3:0] mode = 0;
	reg mode_change;
	
	wire [H_COUNT_WIDTH-1:0] h_count_next;
	wire [V_COUNT_WIDTH-1:0] v_count_next;
	wire [P_COUNT_WIDTH-1:0] p_count_next;
	
	wire vga_clk_valid;
	reg vga_stall = 0, mode_en = 0;
	
	always @(*) begin
		case (mode)
			VGA_CODE_640_480_60: begin
				mode_en = 1;
				dcm_m = VGA_640_480_60_M;
				dcm_d = VGA_640_480_60_D;
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
			VGA_CODE_640_480_72: begin
				mode_en = 1;
				dcm_m = VGA_640_480_72_M;
				dcm_d = VGA_640_480_72_D;
				h_disp_max = VGA_640_480_72_H_DISP - 1;
				v_disp_max = VGA_640_480_72_V_DISP - 1;
				p_disp_max = VGA_640_480_72_H_DISP * VGA_640_480_72_V_DISP - 1;
				h_sync_start = VGA_640_480_72_H_DISP + VGA_640_480_72_H_FP - 1;
				h_sync_end = VGA_640_480_72_H_DISP + VGA_640_480_72_H_FP + VGA_640_480_72_H_PW - 1;
				h_disp_start = VGA_640_480_72_H_DISP + VGA_640_480_72_H_FP + VGA_640_480_72_H_PW + VGA_640_480_72_H_BP - 1;
				h_disp_end = VGA_640_480_72_H_DISP - 1;
				h_pulse_value = VGA_640_480_72_H_PV;
				v_sync_start = VGA_640_480_72_V_DISP + VGA_640_480_72_V_FP - 1;
				v_sync_end = VGA_640_480_72_V_DISP + VGA_640_480_72_V_FP + VGA_640_480_72_V_PW - 1;
				v_disp_start = VGA_640_480_72_V_DISP + VGA_640_480_72_V_FP + VGA_640_480_72_V_PW + VGA_640_480_72_V_BP - 1;
				v_disp_end = VGA_640_480_72_V_DISP - 1;
				v_pulse_value = VGA_640_480_72_V_PV;
			end
			VGA_CODE_640_480_75: begin
				mode_en = 1;
				dcm_m = VGA_640_480_75_M;
				dcm_d = VGA_640_480_75_D;
				h_disp_max = VGA_640_480_75_H_DISP - 1;
				v_disp_max = VGA_640_480_75_V_DISP - 1;
				p_disp_max = VGA_640_480_75_H_DISP * VGA_640_480_75_V_DISP - 1;
				h_sync_start = VGA_640_480_75_H_DISP + VGA_640_480_75_H_FP - 1;
				h_sync_end = VGA_640_480_75_H_DISP + VGA_640_480_75_H_FP + VGA_640_480_75_H_PW - 1;
				h_disp_start = VGA_640_480_75_H_DISP + VGA_640_480_75_H_FP + VGA_640_480_75_H_PW + VGA_640_480_75_H_BP - 1;
				h_disp_end = VGA_640_480_75_H_DISP - 1;
				h_pulse_value = VGA_640_480_75_H_PV;
				v_sync_start = VGA_640_480_75_V_DISP + VGA_640_480_75_V_FP - 1;
				v_sync_end = VGA_640_480_75_V_DISP + VGA_640_480_75_V_FP + VGA_640_480_75_V_PW - 1;
				v_disp_start = VGA_640_480_75_V_DISP + VGA_640_480_75_V_FP + VGA_640_480_75_V_PW + VGA_640_480_75_V_BP - 1;
				v_disp_end = VGA_640_480_75_V_DISP - 1;
				v_pulse_value = VGA_640_480_75_V_PV;
			end
			VGA_CODE_800_600_60: begin
				mode_en = 1;
				dcm_m = VGA_800_600_60_M;
				dcm_d = VGA_800_600_60_D;
				h_disp_max = VGA_800_600_60_H_DISP - 1;
				v_disp_max = VGA_800_600_60_V_DISP - 1;
				p_disp_max = VGA_800_600_60_H_DISP * VGA_800_600_60_V_DISP - 1;
				h_sync_start = VGA_800_600_60_H_DISP + VGA_800_600_60_H_FP - 1;
				h_sync_end = VGA_800_600_60_H_DISP + VGA_800_600_60_H_FP + VGA_800_600_60_H_PW - 1;
				h_disp_start = VGA_800_600_60_H_DISP + VGA_800_600_60_H_FP + VGA_800_600_60_H_PW + VGA_800_600_60_H_BP - 1;
				h_disp_end = VGA_800_600_60_H_DISP - 1;
				h_pulse_value = VGA_800_600_60_H_PV;
				v_sync_start = VGA_800_600_60_V_DISP + VGA_800_600_60_V_FP - 1;
				v_sync_end = VGA_800_600_60_V_DISP + VGA_800_600_60_V_FP + VGA_800_600_60_V_PW - 1;
				v_disp_start = VGA_800_600_60_V_DISP + VGA_800_600_60_V_FP + VGA_800_600_60_V_PW + VGA_800_600_60_V_BP - 1;
				v_disp_end = VGA_800_600_60_V_DISP - 1;
				v_pulse_value = VGA_800_600_60_V_PV;
			end
			VGA_CODE_800_600_72: begin
				mode_en = 1;
				dcm_m = VGA_800_600_72_M;
				dcm_d = VGA_800_600_72_D;
				h_disp_max = VGA_800_600_72_H_DISP - 1;
				v_disp_max = VGA_800_600_72_V_DISP - 1;
				p_disp_max = VGA_800_600_72_H_DISP * VGA_800_600_72_V_DISP - 1;
				h_sync_start = VGA_800_600_72_H_DISP + VGA_800_600_72_H_FP - 1;
				h_sync_end = VGA_800_600_72_H_DISP + VGA_800_600_72_H_FP + VGA_800_600_72_H_PW - 1;
				h_disp_start = VGA_800_600_72_H_DISP + VGA_800_600_72_H_FP + VGA_800_600_72_H_PW + VGA_800_600_72_H_BP - 1;
				h_disp_end = VGA_800_600_72_H_DISP - 1;
				h_pulse_value = VGA_800_600_72_H_PV;
				v_sync_start = VGA_800_600_72_V_DISP + VGA_800_600_72_V_FP - 1;
				v_sync_end = VGA_800_600_72_V_DISP + VGA_800_600_72_V_FP + VGA_800_600_72_V_PW - 1;
				v_disp_start = VGA_800_600_72_V_DISP + VGA_800_600_72_V_FP + VGA_800_600_72_V_PW + VGA_800_600_72_V_BP - 1;
				v_disp_end = VGA_800_600_72_V_DISP - 1;
				v_pulse_value = VGA_800_600_72_V_PV;
			end
			VGA_CODE_800_600_75: begin
				mode_en = 1;
				dcm_m = VGA_800_600_75_M;
				dcm_d = VGA_800_600_75_D;
				h_disp_max = VGA_800_600_75_H_DISP - 1;
				v_disp_max = VGA_800_600_75_V_DISP - 1;
				p_disp_max = VGA_800_600_75_H_DISP * VGA_800_600_75_V_DISP - 1;
				h_sync_start = VGA_800_600_75_H_DISP + VGA_800_600_75_H_FP - 1;
				h_sync_end = VGA_800_600_75_H_DISP + VGA_800_600_75_H_FP + VGA_800_600_75_H_PW - 1;
				h_disp_start = VGA_800_600_75_H_DISP + VGA_800_600_75_H_FP + VGA_800_600_75_H_PW + VGA_800_600_75_H_BP - 1;
				h_disp_end = VGA_800_600_75_H_DISP - 1;
				h_pulse_value = VGA_800_600_75_H_PV;
				v_sync_start = VGA_800_600_75_V_DISP + VGA_800_600_75_V_FP - 1;
				v_sync_end = VGA_800_600_75_V_DISP + VGA_800_600_75_V_FP + VGA_800_600_75_V_PW - 1;
				v_disp_start = VGA_800_600_75_V_DISP + VGA_800_600_75_V_FP + VGA_800_600_75_V_PW + VGA_800_600_75_V_BP - 1;
				v_disp_end = VGA_800_600_75_V_DISP - 1;
				v_pulse_value = VGA_800_600_75_V_PV;
			end
			VGA_CODE_1024_768_60: begin
				mode_en = 1;
				dcm_m = VGA_1024_768_60_M;
				dcm_d = VGA_1024_768_60_D;
				h_disp_max = VGA_1024_768_60_H_DISP - 1;
				v_disp_max = VGA_1024_768_60_V_DISP - 1;
				p_disp_max = VGA_1024_768_60_H_DISP * VGA_1024_768_60_V_DISP - 1;
				h_sync_start = VGA_1024_768_60_H_DISP + VGA_1024_768_60_H_FP - 1;
				h_sync_end = VGA_1024_768_60_H_DISP + VGA_1024_768_60_H_FP + VGA_1024_768_60_H_PW - 1;
				h_disp_start = VGA_1024_768_60_H_DISP + VGA_1024_768_60_H_FP + VGA_1024_768_60_H_PW + VGA_1024_768_60_H_BP - 1;
				h_disp_end = VGA_1024_768_60_H_DISP - 1;
				h_pulse_value = VGA_1024_768_60_H_PV;
				v_sync_start = VGA_1024_768_60_V_DISP + VGA_1024_768_60_V_FP - 1;
				v_sync_end = VGA_1024_768_60_V_DISP + VGA_1024_768_60_V_FP + VGA_1024_768_60_V_PW - 1;
				v_disp_start = VGA_1024_768_60_V_DISP + VGA_1024_768_60_V_FP + VGA_1024_768_60_V_PW + VGA_1024_768_60_V_BP - 1;
				v_disp_end = VGA_1024_768_60_V_DISP - 1;
				v_pulse_value = VGA_1024_768_60_V_PV;
			end
			/*VGA_CODE_1024_768_70: begin
				mode_en = 1;
				dcm_m = VGA_1024_768_70_M;
				dcm_d = VGA_1024_768_70_D;
				h_disp_max = VGA_1024_768_70_H_DISP - 1;
				v_disp_max = VGA_1024_768_70_V_DISP - 1;
				p_disp_max = VGA_1024_768_70_H_DISP * VGA_1024_768_70_V_DISP - 1;
				h_sync_start = VGA_1024_768_70_H_DISP + VGA_1024_768_70_H_FP - 1;
				h_sync_end = VGA_1024_768_70_H_DISP + VGA_1024_768_70_H_FP + VGA_1024_768_70_H_PW - 1;
				h_disp_start = VGA_1024_768_70_H_DISP + VGA_1024_768_70_H_FP + VGA_1024_768_70_H_PW + VGA_1024_768_70_H_BP - 1;
				h_disp_end = VGA_1024_768_70_H_DISP - 1;
				h_pulse_value = VGA_1024_768_70_H_PV;
				v_sync_start = VGA_1024_768_70_V_DISP + VGA_1024_768_70_V_FP - 1;
				v_sync_end = VGA_1024_768_70_V_DISP + VGA_1024_768_70_V_FP + VGA_1024_768_70_V_PW - 1;
				v_disp_start = VGA_1024_768_70_V_DISP + VGA_1024_768_70_V_FP + VGA_1024_768_70_V_PW + VGA_1024_768_70_V_BP - 1;
				v_disp_end = VGA_1024_768_70_V_DISP - 1;
				v_pulse_value = VGA_1024_768_70_V_PV;
			end
			VGA_CODE_1280_768_60: begin
				mode_en = 1;
				dcm_m = VGA_1280_768_60_M;
				dcm_d = VGA_1280_768_60_D;
				h_disp_max = VGA_1280_768_60_H_DISP - 1;
				v_disp_max = VGA_1280_768_60_V_DISP - 1;
				p_disp_max = VGA_1280_768_60_H_DISP * VGA_1280_768_60_V_DISP - 1;
				h_sync_start = VGA_1280_768_60_H_DISP + VGA_1280_768_60_H_FP - 1;
				h_sync_end = VGA_1280_768_60_H_DISP + VGA_1280_768_60_H_FP + VGA_1280_768_60_H_PW - 1;
				h_disp_start = VGA_1280_768_60_H_DISP + VGA_1280_768_60_H_FP + VGA_1280_768_60_H_PW + VGA_1280_768_60_H_BP - 1;
				h_disp_end = VGA_1280_768_60_H_DISP - 1;
				h_pulse_value = VGA_1280_768_60_H_PV;
				v_sync_start = VGA_1280_768_60_V_DISP + VGA_1280_768_60_V_FP - 1;
				v_sync_end = VGA_1280_768_60_V_DISP + VGA_1280_768_60_V_FP + VGA_1280_768_60_V_PW - 1;
				v_disp_start = VGA_1280_768_60_V_DISP + VGA_1280_768_60_V_FP + VGA_1280_768_60_V_PW + VGA_1280_768_60_V_BP - 1;
				v_disp_end = VGA_1280_768_60_V_DISP - 1;
				v_pulse_value = VGA_1280_768_60_V_PV;
			end
			VGA_CODE_1280_768_75: begin
				mode_en = 1;
				dcm_m = VGA_1280_768_75_M;
				dcm_d = VGA_1280_768_75_D;
				h_disp_max = VGA_1280_768_75_H_DISP - 1;
				v_disp_max = VGA_1280_768_75_V_DISP - 1;
				p_disp_max = VGA_1280_768_75_H_DISP * VGA_1280_768_75_V_DISP - 1;
				h_sync_start = VGA_1280_768_75_H_DISP + VGA_1280_768_75_H_FP - 1;
				h_sync_end = VGA_1280_768_75_H_DISP + VGA_1280_768_75_H_FP + VGA_1280_768_75_H_PW - 1;
				h_disp_start = VGA_1280_768_75_H_DISP + VGA_1280_768_75_H_FP + VGA_1280_768_75_H_PW + VGA_1280_768_75_H_BP - 1;
				h_disp_end = VGA_1280_768_75_H_DISP - 1;
				h_pulse_value = VGA_1280_768_75_H_PV;
				v_sync_start = VGA_1280_768_75_V_DISP + VGA_1280_768_75_V_FP - 1;
				v_sync_end = VGA_1280_768_75_V_DISP + VGA_1280_768_75_V_FP + VGA_1280_768_75_V_PW - 1;
				v_disp_start = VGA_1280_768_75_V_DISP + VGA_1280_768_75_V_FP + VGA_1280_768_75_V_PW + VGA_1280_768_75_V_BP - 1;
				v_disp_end = VGA_1280_768_75_V_DISP - 1;
				v_pulse_value = VGA_1280_768_75_V_PV;
			end
			VGA_CODE_1280_960_60: begin
				mode_en = 1;
				dcm_m = VGA_1280_960_60_M;
				dcm_d = VGA_1280_960_60_D;
				h_disp_max = VGA_1280_960_60_H_DISP - 1;
				v_disp_max = VGA_1280_960_60_V_DISP - 1;
				p_disp_max = VGA_1280_960_60_H_DISP * VGA_1280_960_60_V_DISP - 1;
				h_sync_start = VGA_1280_960_60_H_DISP + VGA_1280_960_60_H_FP - 1;
				h_sync_end = VGA_1280_960_60_H_DISP + VGA_1280_960_60_H_FP + VGA_1280_960_60_H_PW - 1;
				h_disp_start = VGA_1280_960_60_H_DISP + VGA_1280_960_60_H_FP + VGA_1280_960_60_H_PW + VGA_1280_960_60_H_BP - 1;
				h_disp_end = VGA_1280_960_60_H_DISP - 1;
				h_pulse_value = VGA_1280_960_60_H_PV;
				v_sync_start = VGA_1280_960_60_V_DISP + VGA_1280_960_60_V_FP - 1;
				v_sync_end = VGA_1280_960_60_V_DISP + VGA_1280_960_60_V_FP + VGA_1280_960_60_V_PW - 1;
				v_disp_start = VGA_1280_960_60_V_DISP + VGA_1280_960_60_V_FP + VGA_1280_960_60_V_PW + VGA_1280_960_60_V_BP - 1;
				v_disp_end = VGA_1280_960_60_V_DISP - 1;
				v_pulse_value = VGA_1280_960_60_V_PV;
			end
			VGA_CODE_1280_960_85: begin
				mode_en = 1;
				dcm_m = VGA_1280_960_85_M;
				dcm_d = VGA_1280_960_85_D;
				h_disp_max = VGA_1280_960_85_H_DISP - 1;
				v_disp_max = VGA_1280_960_85_V_DISP - 1;
				p_disp_max = VGA_1280_960_85_H_DISP * VGA_1280_960_85_V_DISP - 1;
				h_sync_start = VGA_1280_960_85_H_DISP + VGA_1280_960_85_H_FP - 1;
				h_sync_end = VGA_1280_960_85_H_DISP + VGA_1280_960_85_H_FP + VGA_1280_960_85_H_PW - 1;
				h_disp_start = VGA_1280_960_85_H_DISP + VGA_1280_960_85_H_FP + VGA_1280_960_85_H_PW + VGA_1280_960_85_H_BP - 1;
				h_disp_end = VGA_1280_960_85_H_DISP - 1;
				h_pulse_value = VGA_1280_960_85_H_PV;
				v_sync_start = VGA_1280_960_85_V_DISP + VGA_1280_960_85_V_FP - 1;
				v_sync_end = VGA_1280_960_85_V_DISP + VGA_1280_960_85_V_FP + VGA_1280_960_85_V_PW - 1;
				v_disp_start = VGA_1280_960_85_V_DISP + VGA_1280_960_85_V_FP + VGA_1280_960_85_V_PW + VGA_1280_960_85_V_BP - 1;
				v_disp_end = VGA_1280_960_85_V_DISP - 1;
				v_pulse_value = VGA_1280_960_85_V_PV;
			end
			VGA_CODE_1280_1024_60: begin
				mode_en = 1;
				dcm_m = VGA_1280_1024_60_M;
				dcm_d = VGA_1280_1024_60_D;
				h_disp_max = VGA_1280_1024_60_H_DISP - 1;
				v_disp_max = VGA_1280_1024_60_V_DISP - 1;
				p_disp_max = VGA_1280_1024_60_H_DISP * VGA_1280_1024_60_V_DISP - 1;
				h_sync_start = VGA_1280_1024_60_H_DISP + VGA_1280_1024_60_H_FP - 1;
				h_sync_end = VGA_1280_1024_60_H_DISP + VGA_1280_1024_60_H_FP + VGA_1280_1024_60_H_PW - 1;
				h_disp_start = VGA_1280_1024_60_H_DISP + VGA_1280_1024_60_H_FP + VGA_1280_1024_60_H_PW + VGA_1280_1024_60_H_BP - 1;
				h_disp_end = VGA_1280_1024_60_H_DISP - 1;
				h_pulse_value = VGA_1280_1024_60_H_PV;
				v_sync_start = VGA_1280_1024_60_V_DISP + VGA_1280_1024_60_V_FP - 1;
				v_sync_end = VGA_1280_1024_60_V_DISP + VGA_1280_1024_60_V_FP + VGA_1280_1024_60_V_PW - 1;
				v_disp_start = VGA_1280_1024_60_V_DISP + VGA_1280_1024_60_V_FP + VGA_1280_1024_60_V_PW + VGA_1280_1024_60_V_BP - 1;
				v_disp_end = VGA_1280_1024_60_V_DISP - 1;
				v_pulse_value = VGA_1280_1024_60_V_PV;
			end
			VGA_CODE_1280_1024_75: begin
				mode_en = 1;
				dcm_m = VGA_1280_1024_75_M;
				dcm_d = VGA_1280_1024_75_D;
				h_disp_max = VGA_1280_1024_75_H_DISP - 1;
				v_disp_max = VGA_1280_1024_75_V_DISP - 1;
				p_disp_max = VGA_1280_1024_75_H_DISP * VGA_1280_1024_75_V_DISP - 1;
				h_sync_start = VGA_1280_1024_75_H_DISP + VGA_1280_1024_75_H_FP - 1;
				h_sync_end = VGA_1280_1024_75_H_DISP + VGA_1280_1024_75_H_FP + VGA_1280_1024_75_H_PW - 1;
				h_disp_start = VGA_1280_1024_75_H_DISP + VGA_1280_1024_75_H_FP + VGA_1280_1024_75_H_PW + VGA_1280_1024_75_H_BP - 1;
				h_disp_end = VGA_1280_1024_75_H_DISP - 1;
				h_pulse_value = VGA_1280_1024_75_H_PV;
				v_sync_start = VGA_1280_1024_75_V_DISP + VGA_1280_1024_75_V_FP - 1;
				v_sync_end = VGA_1280_1024_75_V_DISP + VGA_1280_1024_75_V_FP + VGA_1280_1024_75_V_PW - 1;
				v_disp_start = VGA_1280_1024_75_V_DISP + VGA_1280_1024_75_V_FP + VGA_1280_1024_75_V_PW + VGA_1280_1024_75_V_BP - 1;
				v_disp_end = VGA_1280_1024_75_V_DISP - 1;
				v_pulse_value = VGA_1280_1024_75_V_PV;
			end
			VGA_CODE_1360_768_60: begin
				mode_en = 1;
				dcm_m = VGA_1360_768_60_M;
				dcm_d = VGA_1360_768_60_D;
				h_disp_max = VGA_1360_768_60_H_DISP - 1;
				v_disp_max = VGA_1360_768_60_V_DISP - 1;
				p_disp_max = VGA_1360_768_60_H_DISP * VGA_1360_768_60_V_DISP - 1;
				h_sync_start = VGA_1360_768_60_H_DISP + VGA_1360_768_60_H_FP - 1;
				h_sync_end = VGA_1360_768_60_H_DISP + VGA_1360_768_60_H_FP + VGA_1360_768_60_H_PW - 1;
				h_disp_start = VGA_1360_768_60_H_DISP + VGA_1360_768_60_H_FP + VGA_1360_768_60_H_PW + VGA_1360_768_60_H_BP - 1;
				h_disp_end = VGA_1360_768_60_H_DISP - 1;
				h_pulse_value = VGA_1360_768_60_H_PV;
				v_sync_start = VGA_1360_768_60_V_DISP + VGA_1360_768_60_V_FP - 1;
				v_sync_end = VGA_1360_768_60_V_DISP + VGA_1360_768_60_V_FP + VGA_1360_768_60_V_PW - 1;
				v_disp_start = VGA_1360_768_60_V_DISP + VGA_1360_768_60_V_FP + VGA_1360_768_60_V_PW + VGA_1360_768_60_V_BP - 1;
				v_disp_end = VGA_1360_768_60_V_DISP - 1;
				v_pulse_value = VGA_1360_768_60_V_PV;
			end*/
			default: begin
				mode_en = 0;
				dcm_m = 2;
				dcm_d = 2;
				h_disp_max = 0;
				v_disp_max = 0;
				p_disp_max = 0;
				h_sync_start = 0;
				h_sync_end = 0;
				h_disp_start = 0;
				h_disp_end = 0;
				h_pulse_value = 0;
				v_sync_start = 0;
				v_sync_end = 0;
				v_disp_start = 0;
				v_disp_end = 0;
				v_pulse_value = 0;
			end
		endcase
	end
	
	wire vga_clk_unbuf;
	wire prog_clk;
	reg	prog_en, prog_data;
	wire prog_done;
	reg [9:0] load_data;
	reg [3:0] load_addr, next_load_addr;
	
	assign prog_clk = clk;
	
	DCM_CLKGEN #(
		.CLKFXDV_DIVIDE(2),
		.CLKFX_DIVIDE(8),
		.CLKFX_MULTIPLY(2),
		.CLKFX_MD_MAX(0.5),
		.CLKIN_PERIOD(10),
		.SPREAD_SPECTRUM("NONE"),
		.STARTUP_WAIT("FALSE")
		) DCM_VGA (
		.CLKIN(clk_base),
		.RST(rst),
		.FREEZEDCM(1'b0),
		.CLKFX(vga_clk_unbuf),
		.CLKFX180(),
		.CLKFXDV(),
		.LOCKED(vga_clk_valid),
		.PROGEN(prog_en),
		.PROGCLK(prog_clk),
		.PROGDATA(prog_data),
		.PROGDONE(prog_done),
		.STATUS()
		);
	
	BUFG CLK_VGA_BUF (.I(vga_clk_unbuf), .O(vga_clk));
	
	localparam
		INTERVAL_D = 2,
		INTERVAL_M = 2;
	
	localparam
		S_IDLE = 0,  // idle
		S_D = 1,  // send divisor value
		S_D_WAIT = 2,  // delay
		S_M = 3,  // send multiplier value
		S_M_WAIT = 4,  // delay
		S_GO = 5,  // send go command
		S_GO_WAIT = 6;  // delay
	
	reg [2:0] state = 0;
	reg [2:0] next_state;
	
	always @(*) begin
		vga_stall = 0;
		mode_change = 0;
		load_data = 0;
		prog_en = 0;
		prog_data = 0;
		next_load_addr = load_addr + 1'h1;
		next_state = S_IDLE;
		case (state)
			S_IDLE: begin
				if (vga_clk_valid && (mode != mode_in)) begin
					vga_stall = 1;
					mode_change = 1;
					next_load_addr = 0;
					next_state = S_D;
				end
			end
			S_D: begin
				vga_stall = 1;
				load_data = {dcm_d, 2'b01};
				prog_en = 1;
				prog_data = load_data[load_addr];
				if (load_addr == 9) begin
					next_load_addr = 0;
					next_state = S_D_WAIT;
				end
				else begin
					next_state = S_D;
				end
			end
			S_D_WAIT: begin
				vga_stall = 1;
				prog_en = 0;
				if (load_addr == INTERVAL_D) begin
					next_load_addr = 0;
					next_state = S_M;
				end
				else begin
					next_state = S_D_WAIT;
				end
			end
			S_M: begin
				vga_stall = 1;
				load_data = {dcm_m, 2'b11};
				prog_en = 1;
				prog_data = load_data[load_addr];
				if (load_addr == 9) begin
					next_load_addr = 0;
					next_state = S_M_WAIT;
				end
				else begin
					next_state = S_M;
				end
			end
			S_M_WAIT: begin
				vga_stall = 1;
				prog_en = 0;
				if (load_addr == INTERVAL_M) begin
					next_load_addr = 0;
					next_state = S_GO;
				end
				else begin
					next_state = S_M_WAIT;
				end
			end
			S_GO: begin
				vga_stall = 1;
				prog_en = 1;
				prog_data = 0;
				next_state = S_GO_WAIT;
			end
			S_GO_WAIT: begin
				vga_stall = 1;
				if (~prog_done || ~vga_clk_valid)
					next_state = S_GO_WAIT;
			end
		endcase
	end
	
	always @(posedge prog_clk) begin
		if (rst) begin
			state <= 0;
			load_addr <= 0;
			mode <= 0;
		end
		else begin
			state <= next_state;
			load_addr <= next_load_addr;
			if (mode_change) begin
				mode <= mode_in;
			end
		end
	end
	
	assign
		h_count_next = h_count + 1'h1,
		v_count_next = v_count + 1'h1,
		p_count_next = p_count + 1'h1;
	
	always @(posedge vga_clk) begin
		if (vga_stall || ~mode_en || ~vga_clk_valid) begin
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
