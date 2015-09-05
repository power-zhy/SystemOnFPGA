`include "define.vh"


/**
 * Board IOs with wishbone connection interfaces.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_board_sword (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// board interfaces
	input wire [15:0] switch,
	output reg [4:0] btn_x,
	input wire [3:0] btn_y,
	output wire led_clk,
	output wire led_en,
	output wire led_clr_n,
	output wire led_do,
	output wire seg_clk,
	output wire seg_en,
	output wire seg_clr_n,
	output wire seg_do,
	// peripheral wishbone interfaces
	input wire wbs_clk_i,
	input wire wbs_cs_i,
	input wire [DEV_ADDR_BITS-1:2] wbs_addr_i,
	input wire [3:0] wbs_sel_i,
	input wire [31:0] wbs_data_i,
	input wire wbs_we_i,
	output reg [31:0] wbs_data_o,
	output reg wbs_ack_o,
	// debug display interfaces
	`ifdef DEBUG
	input wire debug_en,
	input wire [15:0] debug_led,
	input wire [31:0] debug_data,
	input wire [15:0] debug_dot,
	`endif
	// interrupt
	output reg interrupt
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz
	parameter
		DEV_ADDR_BITS = 8;  // address length of I/O space
	localparam
		SCAN_INTERVAL = 20,  // scan interval for matrix keyboard, must be larger then anti-jitter's max jitter time
		COUNT_SCAN = 1 + CLK_FREQ * SCAN_INTERVAL * 1000,
		COUNT_BITS = GET_WIDTH(COUNT_SCAN-1);
	
	// registers
	reg reg_btn_mode = 0;
	reg [19:0] reg_btn = 0;
	reg [4:0] reg_scan_out = 0;
	reg [3:0] reg_sacn_in = 0;
	reg [15:0] reg_led = 0;
	reg reg_disp_mode = 0;
	reg [31:0] reg_disp_text = 0;
	reg [63:0] reg_disp_graphic = 0;
	reg [7:0] reg_en = 0;
	reg [7:0] reg_dot = 0;
	
	// matrix keyboard scan
	reg [COUNT_BITS-1:0] clk_count = 0;
	
	always @(posedge clk) begin
		if (rst)
			clk_count <= 0;
		else if (clk_count[COUNT_BITS-1])
			clk_count <= 0;
		else
			clk_count <= clk_count + 1'h1;
	end
	
	always @(posedge clk) begin
		if (rst) begin
			btn_x <= 0;
			reg_btn <= 0;
			reg_sacn_in <= 0;
		end
		else if (reg_btn_mode) begin
			reg_btn <= 0;
			btn_x <= reg_scan_out;
			reg_sacn_in <= ~btn_y;  // will delay a little time because of anti-jitter
		end
		else begin
			reg_sacn_in <= 0;
			if (clk_count[COUNT_BITS-1]) case (btn_x)
				5'b11110: begin
					btn_x <= 5'b11101;
					reg_btn[3:0] <= ~btn_y;
				end
				5'b11101: begin
					btn_x <= 5'b11011;
					reg_btn[7:4] <= ~btn_y;
				end
				5'b11011: begin
					btn_x <= 5'b10111;
					reg_btn[11:8] <= ~btn_y;
				end
				5'b10111: begin
					btn_x <= 5'b01111;
					reg_btn[15:12] <= ~btn_y;
				end
				5'b01111: begin
					btn_x <= 5'b11110;
					reg_btn[19:16] <= ~btn_y;
				end
				default: begin
					btn_x <= 5'b11110;
				end
			endcase
		end
	end
	
	// outputs
	wire [15:0] led;
	wire [7:0] en, dot;
	wire [31:0] data;
	
	`ifdef DEBUG
	assign
		led = debug_en ? debug_led : reg_led,
		en = debug_en ? 8'hFF : reg_en,
		data = debug_en ? debug_data : reg_disp_text,
		dot = debug_en ? debug_dot : reg_dot;
	`else
	assign
		led = reg_led,
		en = reg_en,
		data = reg_disp_text,
		dot = reg_dot;
	`endif
	
	board_disp_sword #(
		.CLK_FREQ(CLK_FREQ)
		) BOARD_DISP_SWORD (
		.clk(clk),
		.rst(rst),
		.en(en),
		.data(data),
		.dot(dot),
		.led(led),
		.led_clk(led_clk),
		.led_en(led_en),
		.led_clr_n(led_clr_n),
		.led_do(led_do),
		.seg_clk(seg_clk),
		.seg_en(seg_en),
		.seg_clr_n(seg_clr_n),
		.seg_do(seg_do)
		);
	
	// wishbone controller
	always @(posedge wbs_clk_i) begin
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (rst) begin
			reg_disp_text <= 0;
			wbs_data_o <= 0;
			wbs_ack_o <= 0;
		end
		else if (wbs_cs_i & ~wbs_ack_o) begin
			case (wbs_addr_i)
				0: begin
					wbs_data_o <= {16'b0, switch};
				end
				1: begin
					wbs_data_o <= {12'b0, reg_btn};
				end
				2: begin
					wbs_data_o <= {reg_btn_mode, 19'b0, reg_sacn_in, 3'b0, reg_scan_out};
					if (wbs_we_i) begin
						if (wbs_sel_i[3])
							reg_btn_mode <= wbs_data_i[31];
						if (wbs_sel_i[0])
							reg_scan_out <= wbs_data_i[4:0];
					end
				end
				4: begin
					wbs_data_o <= {16'b0, reg_led};
					if (wbs_we_i) begin
						if (wbs_sel_i[1])
							reg_led[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_led[7:0] <= wbs_data_i[7:0];
					end
				end
				6: begin
					wbs_data_o <= reg_disp_text;
					if (wbs_we_i) begin
						if (wbs_sel_i[3])
							reg_disp_text[31:24] <= wbs_data_i[31:24];
						if (wbs_sel_i[2])
							reg_disp_text[23:16] <= wbs_data_i[23:16];
						if (wbs_sel_i[1])
							reg_disp_text[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_disp_text[7:0] <= wbs_data_i[7:0];
					end
				end
				7: begin
					wbs_data_o <= {reg_disp_mode, 15'b0, reg_en, reg_dot};
					if (wbs_we_i) begin
						if (wbs_sel_i[3])
							reg_disp_mode <= wbs_data_i[31];
						if (wbs_sel_i[1])
							reg_en <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_dot <= wbs_data_i[7:0];
					end
				end
				8: begin
					wbs_data_o <= reg_disp_graphic[31:0];
					if (wbs_we_i) begin
						if (wbs_sel_i[3])
							reg_disp_graphic[31:24] <= wbs_data_i[31:24];
						if (wbs_sel_i[2])
							reg_disp_graphic[23:16] <= wbs_data_i[23:16];
						if (wbs_sel_i[1])
							reg_disp_graphic[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_disp_graphic[7:0] <= wbs_data_i[7:0];
					end
				end
				9: begin
					wbs_data_o <= reg_disp_graphic[63:32];
					if (wbs_we_i) begin
						if (wbs_sel_i[3])
							reg_disp_graphic[63:56] <= wbs_data_i[31:24];
						if (wbs_sel_i[2])
							reg_disp_graphic[55:48] <= wbs_data_i[23:16];
						if (wbs_sel_i[1])
							reg_disp_graphic[47:40] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_disp_graphic[39:32] <= wbs_data_i[7:0];
					end
				end
				default: begin
					wbs_data_o <= 0;
				end
			endcase
			wbs_ack_o <= 1;
		end
	end
	
	// interrupt
	wire [35:0] reg_in;
	assign
		reg_in = {switch, reg_btn};
	reg [35:0] in_prev;
	always @(posedge clk) begin
		if (rst)
			in_prev <= 0;
		else
			in_prev <= reg_in;
	end
	
	always @(posedge clk) begin
		if (rst)
			interrupt <= 0;
		else
			interrupt <= (in_prev != reg_in);
	end
	
endmodule
