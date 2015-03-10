`include "define.vh"


/**
 * Board IOs with wishbone connection interfaces.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_board_anvylsword (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// board interfaces
	input wire [15:0] switch,
	input wire [3:0] btn_x,
	input wire [3:0] btn_y,
	output wire led_clk,
	output wire led_clr_n,
	output wire led_do,
	output wire seg_clk,
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
	
	// registers
	reg [15:0] reg_btn;
	reg [15:0] reg_led;
	reg [31:0] reg_data;
	reg [7:0] reg_en;
	reg [7:0] reg_dot;
	
	always @(*) begin
		reg_btn = 0;
		case (btn_y)
			4'b0001: reg_btn[3:0] = btn_x;
			4'b0010: reg_btn[7:4] = btn_x;
			4'b0100: reg_btn[11:8] = btn_x;
			4'b1000: reg_btn[15:12] = btn_x;
		endcase
	end
	
	// outputs
	wire [15:0] led;
	wire [7:0] en, dot;
	wire [31:0] data;
	
	`ifdef DEBUG
	assign
		led = debug_en ? debug_led : reg_led[7:0],
		en = debug_en ? 4'b1111 : reg_en[15:12],
		data = debug_en ? debug_data : reg_data[31:16],
		dot = debug_en ? debug_dot : reg_dot[11:8];
	`else
	assign
		led = reg_led[7:0],
		en = reg_en[15:12],
		data = reg_data[31:16],
		dot = reg_dot[11:8];
	`endif
	
	board_disp_anvylsword #(
		.CLK_FREQ(CLK_FREQ)
		) BOARD_DISP_ANVYLSWORD (
		.clk(clk),
		.rst(rst),
		.en(en),
		.data(data),
		.dot(dot),
		.led(led),
		.led_clk(led_clk),
		.led_clr_n(led_clr_n),
		.led_do(led_do),
		.seg_clk(seg_clk),
		.seg_clr_n(seg_clr_n),
		.seg_do(seg_do)
		);
	
	// wishbone controller
	always @(posedge wbs_clk_i) begin
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (rst) begin
			reg_data <= 0;
			wbs_data_o <= 0;
			wbs_ack_o <= 0;
		end
		else if (wbs_cs_i & ~wbs_ack_o) begin
			case (wbs_addr_i)
				14'h0: begin
					wbs_data_o <= {16'b0, switch};
				end
				14'h1: begin
					wbs_data_o <= 0;  //TODO
				end
				14'h4: begin
					wbs_data_o <= {16'b0, reg_led};
					if (wbs_we_i) begin
						if (wbs_sel_i[1])
							reg_led[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_led[7:0] <= wbs_data_i[7:0];
					end
				end
				14'h5: begin
					wbs_data_o <= reg_data;
					if (wbs_we_i) begin
						if (wbs_sel_i[3])
							reg_data[31:24] <= wbs_data_i[31:24];
						if (wbs_sel_i[2])
							reg_data[23:16] <= wbs_data_i[23:16];
						if (wbs_sel_i[1])
							reg_data[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_data[7:0] <= wbs_data_i[7:0];
					end
				end
				14'h6: begin
					wbs_data_o <= {16'b0, reg_en, reg_dot};
					if (wbs_we_i) begin
						if (wbs_sel_i[1])
							reg_en <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_dot <= wbs_data_i[7:0];
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
	reg [31:0] in_prev;
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
