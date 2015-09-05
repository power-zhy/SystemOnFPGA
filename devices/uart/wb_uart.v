`include "define.vh"


/**
 * UART device with wishbone connection interfaces, including read/write buffers.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_uart (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	// UART interfaces
	input wire rx,
	output wire tx,
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
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz, should be multiple of 10M
	parameter
		DEV_ADDR_BITS = 8;
	parameter
		RX_BUF_ADDR_WIDTH = 8,  // RX buffer address length
		TX_BUF_ADDR_WIDTH = 8,  // TX buffer address length
		RX_IR_THRESHOLD = 192,  // when there are more than this number of data in RX buffer, an interrupt would be uttered
		RX_IR_TIMEOUT = 100;  // in ms, when there are some data in RX buffer and not been read after this time, an interrupt would be uttered
	localparam
		TIMEOUT_COUNT = CLK_FREQ * 1000 * RX_IR_TIMEOUT,
		TIMEOUT_WIDTH = GET_WIDTH(TIMEOUT_COUNT-1);
	
	// control registers
	reg error = 0, rx_buf_of = 0, rx_buf_uf = 0, tx_buf_of = 0;
	wire [RX_BUF_ADDR_WIDTH-1:0] rx_left;
	wire [TX_BUF_ADDR_WIDTH-1:0] tx_left;
	reg [31:0] reg_mode = 0;
	
	wire rx_en, tx_en;
	reg rx_rst, tx_rst;
	wire rx_busy;
	wire rx_ack, tx_ack;
	wire rx_err;
	wire [7:0] rx_data, tx_data;
	wire rx_full, tx_full;
	wire rx_empty, tx_empty;
	reg rx_ren, tx_wen;
	wire [7:0] din;
	reg [7:0] dout;
	
	assign
		rx_en = reg_mode[0],
		tx_en = reg_mode[0] & ~tx_empty;
	
	// core
	uart_core_tx #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_DIV_WIDTH(8)
		) UART_TX (
		.clk(clk),
		.rst(rst),
		.baud_div(reg_mode[15:8]),
		.data_type(reg_mode[7:6]),
		.stop_type(reg_mode[5:4]),
		.check_en(reg_mode[3]),
		.check_type(reg_mode[2:1]),
		.en(tx_en),
		.data(tx_data),
		.busy(),
		.ack(tx_ack),
		.tx(tx)
		);
	
	uart_core_rx #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_DIV_WIDTH(8)
		) UART_RX (
		.clk(clk),
		.rst(rst),
		.baud_div(reg_mode[15:8]),
		.data_type(reg_mode[7:6]),
		.stop_type(reg_mode[5:4]),
		.check_en(reg_mode[3]),
		.check_type(reg_mode[2:1]),
		.en(rx_en),
		.data(rx_data),
		.busy(rx_busy),
		.ack(rx_ack),
		.err(rx_err),
		.rx(rx)
		);
	
	// buffer
	reg rx_ren_prev, tx_wen_prev;
	wire rx_ren_raise, tx_wen_raise;
	
	always @(posedge clk) begin
		if (rst) begin
			rx_ren_prev <= 0;
			tx_wen_prev <= 0;
		end
		else begin
			rx_ren_prev <= rx_ren;
			tx_wen_prev <= tx_wen;
		end
	end
	
	assign
		rx_ren_raise = ~rx_ren_prev & rx_ren,
		tx_wen_raise = ~tx_wen_prev & tx_wen;
	
	fifo #(
		.DATA_BITS(8),
		.ADDR_BITS(TX_BUF_ADDR_WIDTH),
		.DETECT_WEN_EDGE(0),
		.DETECT_REN_EDGE(0)
		) FIFO_TX (
		.clk(clk),
		.rst(rst | tx_rst),
		.en_w(tx_wen_raise),
		.data_w(dout),
		.full_w(tx_full),
		.near_full_w(),
		.space_count(tx_left),
		.en_r(tx_ack),
		.data_r(tx_data),
		.empty_r(tx_empty),
		.near_empty_r(),
		.data_count()
		);
	
	fifo #(
		.DATA_BITS(8),
		.ADDR_BITS(RX_BUF_ADDR_WIDTH),
		.DETECT_WEN_EDGE(0),
		.DETECT_REN_EDGE(0)
		) FIFO_RX (
		.clk(clk),
		.rst(rst | rx_rst),
		.en_w(rx_ack),
		.data_w(rx_data),
		.full_w(rx_full),
		.near_full_w(),
		.space_count(),
		.en_r(rx_ren_raise),
		.data_r(din),
		.empty_r(rx_empty),
		.near_empty_r(),
		.data_count(rx_left)
		);
	
	always @(posedge clk) begin
		if (rst || tx_rst) begin
			tx_buf_of <= 0;
		end
		else if (tx_full && tx_wen_raise)
			tx_buf_of <= 1;
	end
	
	always @(posedge clk) begin
		if (rst || rx_rst) begin
			rx_buf_of <= 0;
			rx_buf_uf <= 0;
			error <= 0;
		end
		else begin
			if (rx_full && rx_ack)
				rx_buf_of <= 1;
			if (rx_empty && rx_ren_raise)
				rx_buf_uf <= 1;
			if (rx_err)
				error <= 1;
		end
	end
	
	// wishbone controller
	always @(posedge wbs_clk_i) begin
		tx_wen <= 0;
		rx_ren <= 0;
		tx_rst <= 0;
		rx_rst <= 0;
		dout <= 0;
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (rst) begin
			reg_mode <= 0;
			wbs_data_o <= 0;
			wbs_ack_o <= 0;
		end
		else if (wbs_cs_i & ~wbs_ack_o) begin
			case (wbs_addr_i)
				0: begin
					wbs_data_o <= {rx_busy, tx_en, 24'b0, error, rx_buf_of, rx_buf_uf, tx_buf_of, ~rx_empty, tx_empty};
				end
				1: begin
					wbs_data_o[31:16] <= rx_left;
					wbs_data_o[15:0] <= tx_left;
				end
				2: begin
					wbs_data_o <= reg_mode;
					if (wbs_we_i) begin
						tx_rst <= 1;
						rx_rst <= 1;
						if (wbs_sel_i[3])
							reg_mode[31:24] <= wbs_data_i[31:24];
						if (wbs_sel_i[2])
							reg_mode[23:16] <= wbs_data_i[23:16];
						if (wbs_sel_i[1])
							reg_mode[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_mode[7:0] <= wbs_data_i[7:0];
					end
				end
				3: begin
					wbs_data_o <= {24'h0, din};
					dout <= wbs_data_i[7:0]; // wbs_sel_i are ignored
					if (wbs_we_i)
						tx_wen <= 1;
					else
						rx_ren <= 1;
				end
				default: begin
					wbs_data_o <= 0;
				end
			endcase
			wbs_ack_o <= 1;
		end
	end
	
	// interrupt
	reg tx_empty_prev = 1;
	reg [7:0] rx_left_prev;
	reg [TIMEOUT_WIDTH-1:0] clk_count;
	wire ir_tx_empty, ir_rx_full, ir_error, ir_timeout, ir_tx_of, ir_rx_of, ir_rx_uf;
	
	always @(posedge clk) begin
		if (rst) begin
			tx_empty_prev <= 1;
			rx_left_prev <= 0;
		end
		else begin
			tx_empty_prev <= tx_empty;
			rx_left_prev <= rx_left;
		end
	end
	
	always @(posedge clk) begin
		if (rst || rx_empty || rx_ren)
			clk_count <= 0;
		else if (clk_count == TIMEOUT_COUNT-1)
			clk_count <= 0;
		else
			clk_count <= clk_count + 1'h1;
	end
	
	assign
		ir_tx_empty = ~tx_empty_prev & tx_empty,
		ir_rx_full = (rx_left_prev == RX_IR_THRESHOLD-1) & (rx_left == RX_IR_THRESHOLD),
		ir_error = rx_err,
		ir_timeout = (clk_count == TIMEOUT_COUNT-1),
		ir_tx_of = tx_full & tx_wen_raise,
		ir_rx_of = rx_full & rx_ack,
		ir_rx_uf = rx_empty & rx_ren_raise;
	
	always @(posedge clk) begin
		if (rst)
			interrupt <= 0;
		else
			interrupt <= ir_tx_empty | ir_rx_full | ir_error | ir_timeout | ir_tx_of | ir_rx_of | ir_rx_uf;
	end
	
endmodule
