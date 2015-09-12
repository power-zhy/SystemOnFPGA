`include "define.vh"


/**
 * PS2 host controller.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module ps2_host (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	input wire tx_en,  // TX enable signal, flag to start transmitting
	input wire [7:0] tx_data,  // data to send out
	input wire rx_en,  // RX enable
	output wire [7:0] rx_data,  // data received in
	output reg tx_busy,  // data transmitting flag
	output reg rx_busy,  // data receiving flag
	output reg tx_ack,  // data transmitted acknowledge
	output reg rx_ack,  // data received acknowledge
	output reg tx_err,  // transmit error flag
	output reg rx_err,  // receive error flag, mainly check bit or stop bit error
	// PS2 interfaces
	inout wire ps2_clk,
	inout wire ps2_dat
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz
	localparam
		DELAY_TIME = 1000;  // delay time in us used for holding the clock signal, also used as time-out when receiving data
	localparam
		CLK_COUNT = CLK_FREQ * DELAY_TIME,  // CLK_FREQ * 1000000 / (1000000 / DELAY_TIME)
		CLK_COUNT_WIDTH = GET_WIDTH(CLK_COUNT);
	
	reg clk_i, dat_i;
	reg clk_i_prev;
	reg clk_hold;
	reg dat_o;
	reg dat_en;
	
	reg [9:0] tx_buf;  // do not include stop bit
	reg [10:0] rx_buf;
	reg [CLK_COUNT_WIDTH-1:0] clk_count = 0;
	reg [CLK_COUNT_WIDTH-1:0] next_clk_count;
	
	assign
		ps2_clk = clk_hold ? 1'b0 : 1'bz,
		ps2_dat = dat_en ? dat_o : 1'bz;
	
	// must buffer these two signals to eliminate potential conflict
	always @(posedge clk) begin
		clk_i <= ps2_clk;
		dat_i <= ps2_dat;
	end
	
	always @(posedge clk) begin
		if (rst)
			clk_i_prev <= 0;
		else
			clk_i_prev <= clk_i;
	end
	
	localparam
		S_DELAY = 0,  // hold the clock line to insert a period of delay
		S_IDLE = 1,  // idle
		S_TX_REQ = 2,  // load data, hold the clock line to request data sending
		S_TX = 3,  // send data
		S_TX_ACK = 4,  // receive and check acknowledge bit
		S_RX = 5,  // receive data
		S_RX_CHECK = 6,  // check the checksum of received data
		S_TX_ERROR = 7,  // set tx_error
		S_RX_ERROR = 8,  // set rx_error
		S_TX_DONE = 9,  // set tx_ack
		S_RX_DONE = 10;  // set_rx_ack
	
	reg [3:0] state = 0;
	reg [3:0] next_state;
	reg [3:0] bit_count;
	
	always @(*) begin
		next_state = S_DELAY;
		next_clk_count = clk_count + 1'h1;
		case (state)
			S_DELAY: begin
				`ifndef NO_PS2_WRITE
				if (clk_count == CLK_COUNT) begin
					next_clk_count = 0;
					next_state = S_IDLE;
				end
				else begin
					next_clk_count = clk_count + 1'h1;
					next_state = S_DELAY;
				end
				`else
				next_state = S_IDLE;
				`endif
			end
			S_IDLE: begin
				next_clk_count = 0;
				if (tx_en)
					next_state = S_TX_REQ;
				else if (clk_i_prev && ~clk_i)
					if (~dat_i)
						next_state = S_RX;
					else
						next_state = S_RX_ERROR;
				else
					next_state = S_IDLE;
			end
			S_TX_REQ: begin
				if (clk_count == CLK_COUNT) begin
					next_clk_count = 0;
					next_state = S_TX;
				end
				else begin
					next_clk_count = clk_count + 1'h1;
					next_state = S_TX_REQ;
				end
			end
			S_TX: begin
				if (clk_i_prev && ~clk_i)
					next_clk_count = 0;
				if (bit_count == 10) begin
					next_clk_count = 0;
					next_state = S_TX_ACK;
				end
				else if (clk_count == CLK_COUNT) begin
					next_clk_count = 0;
					next_state = S_TX_ERROR;
				end
				else begin
					next_clk_count = clk_count + 1'h1;
					next_state = S_TX;
				end
			end
			S_TX_ACK: begin
				if (clk_i_prev && ~clk_i)
					if (~dat_i)
						next_state = S_TX_DONE;
					else
						next_state = S_TX_ERROR;
				else if (clk_count == CLK_COUNT-1)
					next_state = S_TX_ERROR;
				else
					next_state = S_TX_ACK;
			end
			S_RX: begin
				if (clk_i_prev && ~clk_i)
					next_clk_count = 0;
				if (bit_count == 11) begin
					next_clk_count = 0;
					next_state = S_RX_CHECK;
				end
				else if (clk_count == CLK_COUNT) begin
					next_clk_count = 0;
					next_state = S_RX_ERROR;
				end
				else begin
					next_clk_count = clk_count + 1'h1;
					next_state = S_RX;
				end
			end
			S_RX_CHECK: begin
				if (rx_buf[10] && ^rx_buf[9:1] && ~rx_buf[0])
					next_state = S_RX_DONE;
				else
					next_state = S_RX_ERROR;
			end
			S_TX_ERROR, S_RX_ERROR, S_TX_DONE, S_RX_DONE: begin
				next_clk_count = 0;
				next_state = S_DELAY;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst) begin
			state <= 0;
			clk_count <= 0;
		end
		else begin
			state <= next_state;
			clk_count <= next_clk_count;
		end
	end
	
	always @(posedge clk) begin
		clk_hold <= 0;
		dat_en <= 0;
		tx_busy <= 0;
		rx_busy <= 0;
		tx_ack <= 0;
		rx_ack <= 0;
		tx_err <= 0;
		rx_err <= 0;
		if (rst) begin
			clk_hold <= 0;
			dat_en <= 0;
			dat_o <= 0;
			tx_buf <= 0;
			rx_buf <= 0;
			bit_count <= 0;
			tx_busy <= 0;
			rx_busy <= 0;
			tx_ack <= 0;
			rx_ack <= 0;
			tx_err <= 0;
			rx_err <= 0;
		end
		else case (next_state)
			S_DELAY: begin
				clk_hold <= 1;
			end
			S_IDLE: begin
				clk_hold <= ~rx_en;
				dat_o <= 0;
				tx_buf <= 0;
				rx_buf <= 0;
				bit_count <= 0;
			end
			S_TX_REQ: begin
				tx_busy <= 1;
				if (~clk_hold)
					tx_buf <= {~(^tx_data), tx_data, 1'b0};
				clk_hold <= 1;
			end
			S_TX: begin
				tx_busy <= 1;
				dat_en <= 1;
				dat_o <= tx_buf[0];
				if (clk_i_prev && ~clk_i) begin
					bit_count <= bit_count + 1'h1;
					tx_buf <= {1'b0, tx_buf[9:1]};
				end
			end
			S_TX_ACK: begin
				tx_busy <= 1;
			end
			S_RX: begin
				rx_busy <= 1;
				if (clk_i_prev && ~clk_i) begin
					bit_count <= bit_count + 1'h1;
					rx_buf <= {dat_i, rx_buf[10:1]};
				end
			end
			S_RX_CHECK: begin
				rx_busy <= 1;
			end
			S_TX_ERROR: begin
				tx_err <= 1;
			end
			S_RX_ERROR: begin
				rx_err <= 1;
			end
			S_TX_DONE: begin
				tx_ack <= 1;
			end
			S_RX_DONE: begin
				rx_ack <= 1;
			end
		endcase
		`ifdef NO_PS2_WRITE
		clk_hold <= 0;
		`endif
	end
	
	assign
		rx_data = rx_buf[8:1];
	
endmodule
