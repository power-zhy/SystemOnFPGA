`include "define.vh"


module test_ps2 (
	input wire clk,
	input wire clk_bus,
	input wire rst,
	input wire cs,
	input wire we,
	input wire [7:0] cmd,
	output wire [31:0] data,
	output wire [7:0] state,
	// PS2 interfaces
	inout wire ps2_clk,
	inout wire ps2_dat
	);
	
	parameter
		CLK_FREQ = 100;
	
	wire [7:0] dout;
	reg [31:0] data_buf;
	
	wire tx_busy, rx_busy;
	wire tx_ack, rx_ack;
	wire tx_err, rx_err;
	
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
	
	ps2_host #(
		.CLK_FREQ(CLK_FREQ)
		) PS2_HOST (
		.clk(clk),
		.rst(rst),
		.tx_en(cs & we),
		.tx_data(cmd),
		.rx_en(cs),
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
	
	assign data = data_buf;
	assign state = {tx_busy, rx_busy, 2'b0, tx_err_buf, rx_err_buf, tx_ack, rx_ack};
	
endmodule
