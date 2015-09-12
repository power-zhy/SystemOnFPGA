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
	wire [31:0] reg_in;
	reg [31:0] reg_out = 0;
	
	assign reg_in = {19'b0, btn_s, btn_l, btn_r, btn_u, btn_d, switch[7:0]};
	
	wire [3:0] en, dot;
	wire [15:0] data;
	
	`ifdef DEBUG
	assign
		led = debug_en ? debug_led : reg_out[7:0],
		en = debug_en ? 4'b1111 : reg_out[15:12],
		data = debug_en ? debug_data : reg_out[31:16],
		dot = debug_en ? debug_dot : reg_out[11:8];
	`else
	assign
		led = reg_out[7:0],
		en = reg_out[15:12],
		data = reg_out[31:16],
		dot = reg_out[11:8];
	`endif
	
	seg_disp_nexys3 SEG_DISP (
		.clk(clk),
		.rst(rst),
		.en(en),
		.data(data),
		.dot(dot),
		.segment(segment),
		.anode(anode)
		);
	
	// wishbone controller
	always @(posedge wbs_clk_i) begin
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (rst) begin
			reg_out <= 0;
			wbs_data_o <= 0;
			wbs_ack_o <= 0;
		end
		else if (wbs_cs_i & ~wbs_ack_o) begin
			case (wbs_addr_i)
				0: begin
					wbs_data_o <= reg_in;
				end
				6: begin
					wbs_data_o <= reg_out;
					if (wbs_we_i) begin
						if (wbs_sel_i[3])
							reg_out[31:24] <= wbs_data_i[31:24];
						if (wbs_sel_i[2])
							reg_out[23:16] <= wbs_data_i[23:16];
						if (wbs_sel_i[1])
							reg_out[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_out[7:0] <= wbs_data_i[7:0];
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
