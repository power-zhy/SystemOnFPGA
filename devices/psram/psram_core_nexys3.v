`include "define.vh"


/**
 * PSRAM core.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module psram_core_nexys3 (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire cs,  // chip select
	input wire we,  // write enable
	input wire [ADDR_BITS-1:2] addr,  // address
	input wire [3:0] sel,  // byte select
	input wire burst,  // burst mode flag
	input wire [31:0] din,  // data to write
	output reg [31:0] dout,  // data read in
	output reg busy,  // busy flag
	output reg ack,  // acknowledge
	// PSRAM interfaces
	output reg ram_ce_n = 1,
	output wire ram_clk,
	output reg ram_oe_n = 1,
	output reg ram_we_n = 1,
	output reg ram_adv_n = 1,
	output reg ram_cre = 0,
	output reg ram_lb_n = 1,
	output reg ram_ub_n = 1,
	input wire ram_wait,
	output reg [ADDR_BITS-1:1] ram_addr,
	input wire [15:0] ram_din,
	output reg [15:0] ram_dout
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100,  // main clock frequency in MHz
		ADDR_BITS = 24;  // address length for PSRAM
	localparam
		DELAY_INIT = 150000,  // delay time to complete initialization, in ns
		DELAY_CONFIG = 85,  // delay time to complete configuration, in ns
		DELAY_DONE = 50;  // delay time to wait when burst ended, in ns
	localparam
		COUNT_INIT = 1 + CLK_FREQ * DELAY_INIT / 1000,
		COUNT_CONFIG = 1 + CLK_FREQ * DELAY_CONFIG / 1000,
		COUNT_DONE = 1 + CLK_FREQ * DELAY_DONE / 1000,
		COUNT_BITS = GET_WIDTH(COUNT_INIT-1);
	localparam
		BCR_CONFIG = 16'b0_0_011_1_0_1_00_01_1_111;  // set 'ram_wait' to be asserted one data cycle before delay
	
	reg wait_buf;  // 'ram_wait' would be changed near the negative edge of RAM's clock, which is the positive edge of 'clk', may generate some uncertainty so that must be eliminated by buffering it at other clock edge
	always @(negedge clk) begin
		wait_buf <= ram_wait;
	end
	
	ODDR2 #(
		.DDR_ALIGNMENT("NONE"),
		.INIT(1'b0),
		.SRTYPE("SYNC")
		) RAM_CLK (
		.Q(ram_clk),
		.C0(clk),
		.C1(~clk),
		.CE(1'b1),
		.D0(1'b0),  // RAM's clock is reversed from the input clock
		.D1(1'b1),
		.R(rst),
		.S(1'b0)
		);
	
	localparam
		S_INIT = 0,  // wait for the initialization of PSRAM
		S_CONFIG = 1,  // set BCR
		S_IDLE = 2,  // idle
		S_START = 3,  // set address
		S_WAIT = 4,  // wait for ram_wait signal
		S_OP1 = 5,  // low 16-bits data
		S_OP2 = 6,  // high 16-bits data
		S_DONE = 7;  // acknowledge
	
	reg [2:0] state = 0;
	reg [2:0] next_state;
	reg [COUNT_BITS-1:0] count = 0;
	reg [COUNT_BITS-1:0] next_count;
	
	always @(*) begin
		next_state = 0;
		next_count = 0;
		case (state)
			S_INIT: begin
				if (count == COUNT_INIT-1) begin
					next_state = S_CONFIG;
					next_count = 0;
				end
				else begin
					next_state = S_INIT;
					next_count = count + 1'h1;
				end
			end
			S_CONFIG: begin
				if (count == COUNT_CONFIG-1) begin
					next_state = S_IDLE;
					next_count = 0;
				end
				else begin
					next_state = S_CONFIG;
					next_count = count + 1'h1;
				end
			end
			S_IDLE: begin
				if (cs)
					next_state = S_START;
				else
					next_state = S_IDLE;
			end
			S_START: begin
				next_state = S_WAIT;
			end
			S_WAIT: begin
				if (ram_wait || wait_buf)
					next_state = S_WAIT;
				else
					next_state = S_OP1;
			end
			S_OP1: begin
				next_state = S_OP2;
			end
			S_OP2: begin
				if (cs && burst && ~ram_wait)
					next_state = S_OP1;
				else
					next_state = S_DONE;
			end
			S_DONE: begin
				if (count == COUNT_DONE-1) begin
					next_state = S_IDLE;
					next_count = 0;
				end
				else begin
					next_state = S_DONE;
					next_count = count + 1'h1;
				end
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst) begin
			state <= 0;
			count <= 0;
		end
		else begin
			state <= next_state;
			count <= next_count;
		end
	end
	
	always @(posedge clk) begin
		busy <= 0;
		ack <= 0;
		ram_ce_n <= 1;
		ram_oe_n <= 1;
		ram_we_n <= 1;
		ram_adv_n <= 1;
		ram_cre <= 0;
		ram_addr <= 0;
		ram_dout <= 0;
		ram_lb_n <= 1;
		ram_ub_n <= 1;
		if (~rst) case (next_state)
			S_INIT: begin
				busy <= 1;
			end
			S_CONFIG: begin
				ram_ce_n <= 0;
				ram_we_n <= 0;
				ram_adv_n <= 0;
				ram_cre <= 1;
				ram_addr <= {7'b000_1000, BCR_CONFIG};
			end
			S_IDLE: begin
			end
			S_START: begin
				busy <= 1;
				ram_ce_n <= 0;
				ram_adv_n <= 0;
				ram_addr <= {addr, 1'b0};
				ram_we_n <= ~we;
				ram_oe_n <= we;
				ram_lb_n <= 0;
				ram_ub_n <= 0;
			end
			S_WAIT: begin
				busy <= 1;
				ram_ce_n <= 0;
				ram_we_n <= ~we;
				ram_oe_n <= we;
				ram_lb_n <= 0;
				ram_ub_n <= 0;
			end
			S_OP1: begin
				busy <= 1;
				ram_ce_n <= 0;
				ram_we_n <= ~we;
				ram_oe_n <= we;
				ram_dout <= din[15:0];
				ram_lb_n <= we ? ~sel[0] : 1'b0;
				ram_ub_n <= we ? ~sel[1] : 1'b0;
				ack <= we;  // acknowledge must be uttered earlier than normal as we need one clock to fetch next data
			end
			S_OP2: begin
				busy <= 1;
				ram_ce_n <= 0;
				ram_we_n <= ~we;
				ram_oe_n <= we;
				ram_dout <= din[31:16];
				ram_lb_n <= we ? ~sel[2] : 1'b0;
				ram_ub_n <= we ? ~sel[3] : 1'b0;
				ack <= ~we;
			end
			S_DONE: begin
			end
		endcase
	end
	
	always @(negedge clk) begin
		dout <= 0;
		if (~rst) case (state)  // read data must be buffered at the negative edge, so that use 'state' instead of 'next_state'
			S_OP1: dout <= {16'b0, ram_din};
			S_OP2: dout <= {ram_din, dout[15:0]};
			S_DONE: dout <= dout;
		endcase
	end
	
endmodule
