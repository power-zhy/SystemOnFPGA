`include "define.vh"


module test_vga_sword (
	input wire clk,
	input wire clk_base,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire [7:0] mode,
	output wire [31:0] data,
	output wire [7:0] state,
	// VGA interfaces
	output wire vga_h_sync,
	output wire vga_v_sync,
	output wire [3:0] vga_red,
	output wire [3:0] vga_green,
	output wire [3:0] vga_blue
	);
	
	parameter
		CLK_FREQ = 100;
	
	wire ack;
	wire [31:0] dout;
	reg [31:0] data_buf;
	
	reg cs_prev;
	always @(posedge clk_bus) begin
		if (rst)
			cs_prev <= 0;
		else
			cs_prev <= cs;
	end
	
	reg cs_buf;
	always @(posedge clk_bus) begin
		if (rst)
			cs_buf <= 0;
		else if (cs & ~cs_prev)
			cs_buf <= 1;
		else if (ack)
			cs_buf <= 0;
	end
	
	wire wb_cyc, wb_stb;
	wire [31:2] wb_addr;
	wire [2:0] wb_cti;
	wire [1:0] wb_bte;
	wire [31:0] wb_data;
	wire wb_ack;
	
	wb_vga_sword #(
		.CLK_FREQ(CLK_FREQ),
		.DEV_ADDR_BITS(8)
		) WB_VGA (
		.clk(clk),
		.rst(rst),
		.clk_base(clk_base),
		.h_sync(vga_h_sync),
		.v_sync(vga_v_sync),
		.r_color(vga_red),
		.g_color(vga_green),
		.b_color(vga_blue),
		.wbm_clk_i(clk_bus),
		.wbm_cyc_o(wb_cyc),
		.wbm_stb_o(wb_stb),
		.wbm_addr_o(wb_addr),
		.wbm_cti_o(wb_cti),
		.wbm_bte_o(wb_bte),
		.wbm_sel_o(),
		.wbm_we_o(),
		.wbm_data_i(wb_data),
		.wbm_data_o(),
		.wbm_ack_i(wb_ack),
		.wbs_clk_i(clk_bus),
		.wbs_cs_i(cs_buf),
		.wbs_addr_i(6'b0),
		.wbs_sel_i(4'b1111),
		.wbs_data_i({mode[7:4], 24'b0, mode[3:0]}),
		.wbs_we_i(1'b1),
		.wbs_data_o(dout),
		.wbs_ack_o(ack)
		);
	
	assign
		wb_ack = wb_cyc & wb_stb,
		wb_data = mode[7] ? {wb_addr[17:2], wb_addr[17:2]} : {24'h072007, wb_addr[9:2]};
	
	always @(posedge clk_bus) begin
		if (rst)
			data_buf <= 0;
		else if (ack)
			data_buf <= dout;
	end
	
	assign data = data_buf;
	assign state = {wb_cyc, wb_stb, 1'b0, wb_ack, 3'b0, ack};
	
endmodule
