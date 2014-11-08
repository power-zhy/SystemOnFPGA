`include "define.vh"


module test_ps2 (
	input wire clk,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire we,
	input wire high,
	input wire [7:0] cmd,
	output wire [15:0] data,
	output wire [7:0] state,
	// PS2 interfaces
	inout ps2_clk,
	inout ps2_dat
	);
	
	parameter
		CLK_FREQ = 100;
	
	wire [7:0] dout;
	reg [31:0] data_buf;
	
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
		else if (tx_ack || rx_ack || tx_err || rx_err)
			cs_buf <= 0;
	end
	
	wire tx_busy, rx_busy;
	wire tx_ack, rx_ack;
	wire tx_err, rx_err;
	wire [3:0] bit_count;
	reg [3:0] bit_count_buf;
	always @(posedge clk) begin
		if (rst)
			bit_count_buf <= 0;
		else if (rx_ack || rx_err)
			bit_count_buf <= bit_count;
	end
	
	ps2_host #(
		.CLK_FREQ(CLK_FREQ)
		) PS2_HOST (
		.clk(clk),
		.rst(rst),
		.tx_en(cs_buf & we),
		.tx_data(cmd),
		.rx_en(cs_buf),
		.rx_data(dout),
		.tx_busy(tx_busy),
		.rx_busy(rx_busy),
		.tx_ack(tx_ack),
		.rx_ack(rx_ack),
		.tx_err(tx_err),
		.rx_err(rx_err),
		.ps2_clk(ps2_clk),
		.ps2_dat(ps2_dat)
		);
	
	always @(posedge clk) begin
		if (rst)
			data_buf <= 0;
		else if (rx_ack || rx_err)
			data_buf <= {data_buf[23:0], dout};
	end
	
	reg tx_err_buf, rx_err_buf;
	always @(posedge clk) begin
		if (rst) begin
			tx_err_buf <= 0;
			rx_err_buf <= 0;
		end
		else begin
			tx_err_buf <= tx_err_buf | tx_err;
			rx_err_buf <= rx_err_buf | rx_err;
		end
	end
	
	assign data = high ? data_buf[31:16] : data_buf[15:0];
	assign state = {tx_busy, rx_busy, 2'b0, tx_err_buf, rx_err_buf, tx_ack, rx_ack};
	
endmodule
