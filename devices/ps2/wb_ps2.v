`include "define.vh"


/**
 * PS2 host with wishbone connection interfaces, including read/write buffers.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_ps2 (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	// PS2 interfaces
	inout wire ps2_clk,
	inout wire ps2_dat,
	// peripheral wishbone interfaces
	input wire wbs_clk_i,
	input wire wbs_cs_i,
	input wire [DEV_ADDR_BITS-1:2] wbs_addr_i,
	input wire [3:0] wbs_sel_i,
	input wire [31:0] wbs_data_i,
	input wire wbs_we_i,
	output reg [31:0] wbs_data_o,
	output reg wbs_ack_o,
	// interrupt
	output reg interrupt
	);
	
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz, should be multiple of 10M
	parameter
		DEV_ADDR_BITS = 8;  // address length of I/O space
	
	// control registers
	reg data_valid, tx_error, rx_error;
	
	wire [7:0] rx_data;
	reg [7:0] din, dout;
	
	reg tx_en;
	wire rx_en;
	wire tx_busy, rx_busy;
	wire tx_err, rx_err;
	wire tx_ack, rx_ack;
	reg read, write;
	
	// host
	ps2_host #(
		.CLK_FREQ(CLK_FREQ)
		) PS2_HOST (
		.clk(clk),
		.rst(rst),
		.tx_en(tx_en),
		.tx_data(dout),
		.rx_en(rx_en),
		.rx_data(rx_data),
		.tx_busy(tx_busy),
		.rx_busy(rx_busy),
		.tx_err(tx_err),
		.rx_err(rx_err),
		.tx_ack(tx_ack),
		.rx_ack(rx_ack),
		.ps2_clk(ps2_clk),
		.ps2_dat(ps2_dat)
		);
	
	assign
		rx_en = ~data_valid;
	
	always @(posedge clk) begin
		if (rst) begin
			data_valid <= 0;
			din <= 0;
		end
		else if (rx_ack) begin
			data_valid <= 1;
			din <= rx_data;
		end
		else if (read) begin
			data_valid <= 0;
			din <= 0;
		end
	end
	
	always @(posedge clk) begin
		if (rst || write)
			tx_error <= 0;
		else if (tx_err)
			tx_error <= 1;
	end
	
	always @(posedge clk) begin
		if (rst || read)
			rx_error <= 0;
		else if (rx_err)
			rx_error <= 1;
	end
	
	always @(posedge clk) begin
		if (rst || tx_ack || tx_err)
			tx_en <= 0;
		else if (write)
			tx_en <= 1;
	end
	
	// wishbone controller
	always @(posedge wbs_clk_i) begin
		read <= 0;
		write <= 0;
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (rst) begin
			wbs_data_o <= 0;
			wbs_ack_o <= 0;
		end
		else if (wbs_cs_i & ~wbs_ack_o) begin
			case (wbs_addr_i)
				14'h0: begin
					wbs_data_o <= {rx_busy, tx_busy, 27'b0, data_valid, rx_error, tx_error};
				end
				14'h3: begin
					wbs_data_o <= {24'h0, din};
					dout <= wbs_data_i[7:0]; // sel_i are ignored
					if (wbs_we_i)
						write <= 1;
					else
						read <= 1;
				end
				default: begin
					wbs_data_o <= 0;
				end
			endcase
			wbs_ack_o <= 1;
		end
	end
	
	// interrupt
	always @(posedge clk) begin
		if (rst)
			interrupt <= 0;
		else
			interrupt <= rx_ack | tx_err | rx_err;
	end
	
endmodule
