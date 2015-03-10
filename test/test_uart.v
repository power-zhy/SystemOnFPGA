`include "define.vh"


module test_uart (
	input wire clk,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire we,
	input wire [7:0] din,
	output wire [31:0] data,
	output wire [7:0] state,
	// UART interfaces
	input wire uart_rx,
	output wire uart_tx
	);
	
	parameter
		CLK_FREQ = 100;
	
	wire [7:0] dout;
	reg [31:0] data_buf;
	
	reg [7:0] tx_data;
	wire tx_busy;
	wire tx_ack;
	wire [7:0] rx_data;
	wire rx_busy;
	wire rx_err, rx_ack;
	wire [15:0] uart_mode;
	assign
		uart_mode = 16'h8101;
	
	reg cs_prev;
	always @(posedge clk) begin
		if (rst)
			cs_prev <= 0;
		else
			cs_prev <= cs;
	end
	
	reg cs_buf;
	always @(posedge clk) begin
		if (rst)
			cs_buf <= 0;
		else if (cs & ~cs_prev)
			cs_buf <= 1;
		else if (tx_ack || rx_ack || rx_err)
			cs_buf <= 0;
	end
	
	uart_core_tx #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_DIV_WIDTH(8)
		) UART_TX (
		.clk(clk),
		.rst(rst),
		.baud_div(uart_mode[15:8]),
		.data_type(uart_mode[7:6]),
		.stop_type(uart_mode[5:4]),
		.check_en(uart_mode[3]),
		.check_type(uart_mode[2:1]),
		.en(cs_buf & we),
		.data(din),
		.busy(tx_busy),
		.ack(tx_ack),
		.tx(uart_tx)
		);
	
	uart_core_rx #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_DIV_WIDTH(8)
		) UART_RX (
		.clk(clk),
		.rst(rst),
		.baud_div(uart_mode[15:8]),
		.data_type(uart_mode[7:6]),
		.stop_type(uart_mode[5:4]),
		.check_en(uart_mode[3]),
		.check_type(uart_mode[2:1]),
		.en(1'b1),
		.data(dout),
		.busy(rx_busy),
		.ack(rx_ack),
		.err(rx_err),
		.rx(uart_rx)
		);
	
	always @(posedge clk) begin
		if (rst)
			data_buf <= 0;
		else if (rx_ack || rx_err)
			data_buf <= {data_buf[23:0], dout};
	end
	
	reg rx_err_buf, tx_ack_buf, rx_ack_buf;
	always @(posedge clk) begin
		if (rst) begin
			rx_err_buf <= 0;
			tx_ack_buf <= 0;
			rx_ack_buf <= 0;
		end
		else begin
			rx_err_buf <= rx_err_buf | rx_err;
			tx_ack_buf <= tx_ack_buf | tx_ack;
			rx_ack_buf <= rx_ack_buf | rx_ack;
		end
	end
	
	assign data = data_buf;
	assign state = {tx_busy, rx_busy, 3'b0, rx_err_buf, tx_ack_buf, rx_ack_buf};
	
endmodule
