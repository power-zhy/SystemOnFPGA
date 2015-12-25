`include "define.vh"


/**
 * Board IOs with wishbone connection interfaces.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_board_nexys3 (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// board interfaces
	input wire [7:0] switch,
	input wire btn_l, btn_r, btn_u, btn_d, btn_s,
	output wire [7:0] led,
	output wire [7:0] segment,
	output wire [3:0] anode,
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
	input wire [7:0] debug_led,
	input wire [15:0] debug_data,
	input wire [3:0] debug_dot,
	`endif
	// interrupt
	output reg interrupt
	);
	
	parameter
		DEV_ADDR_BITS = 8;  // address length of I/O space
	
	// control registers
	wire [4:0] reg_btn;
	assign reg_btn = {btn_s, btn_l, btn_r, btn_u, btn_d};
	
	reg [7:0] reg_led = 0;
	reg reg_disp_mode = 0;
	reg [15:0] reg_disp_text = 0;
	reg [31:0] reg_disp_graphic = 0;
	reg [3:0] reg_en = 0;
	reg [3:0] reg_dot = 0;
	
	// outputs
	wire mode;
	wire [3:0] en, dot;
	wire [15:0] data;
	
	`ifdef DEBUG
	assign
		led = debug_en ? debug_led : reg_led,
		mode = debug_en ? 1'b0 : reg_disp_mode,
		en = debug_en ? 4'hF : reg_en,
		data = debug_en ? debug_data : reg_disp_text,
		dot = debug_en ? debug_dot : reg_dot;
	`else
	assign
		led = reg_led,
		mode = reg_disp_mode,
		en = reg_en,
		data = reg_disp_text,
		dot = reg_dot;
	`endif
	
	seg_disp_nexys3 SEG_DISP (
		.clk(clk),
		.rst(rst),
		.en(en),
		.mode(mode),
		.data_text(data),
		.data_graphic(reg_disp_graphic),
		.dot(dot),
		.segment(segment),
		.anode(anode)
		);
	
	// wishbone controller
	always @(posedge wbs_clk_i) begin
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (rst) begin
			reg_led <= 0;
			reg_disp_mode <= 0;
			reg_disp_text <= 0;
			reg_disp_graphic <= 0;
			reg_en <= 0;
			reg_dot <= 0;
			wbs_data_o <= 0;
			wbs_ack_o <= 0;
		end
		else if (wbs_cs_i & ~wbs_ack_o) begin
			case (wbs_addr_i)
				0: begin
					wbs_data_o <= {24'b0, switch};
				end
				1: begin
					wbs_data_o <= {27'b0, reg_btn};
				end
				4: begin
					wbs_data_o <= {24'b0, reg_led};
					if (wbs_we_i) begin
						if (wbs_sel_i[0])
							reg_led <= wbs_data_i[7:0];
					end
				end
				6: begin
					wbs_data_o <= reg_disp_text;
					if (wbs_we_i) begin
						if (wbs_sel_i[1])
							reg_disp_text[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_disp_text[7:0] <= wbs_data_i[7:0];
					end
				end
				7: begin
					wbs_data_o <= {reg_disp_mode, 19'b0, reg_en, 4'b0, reg_dot};
					if (wbs_we_i) begin
						if (wbs_sel_i[3])
							reg_disp_mode <= wbs_data_i[31];
						if (wbs_sel_i[1])
							reg_en <= wbs_data_i[11:8];
						if (wbs_sel_i[0])
							reg_dot <= wbs_data_i[3:0];
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
				default: begin
					wbs_data_o <= 0;
				end
			endcase
			wbs_ack_o <= 1;
		end
	end
	
	// interrupt
	wire [12:0] reg_in;
	assign
		reg_in = {switch, reg_btn};
	
	reg [12:0] in_prev = 0;
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
