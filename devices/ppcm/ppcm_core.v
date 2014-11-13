`include "define.vh"


/**
 * Parallel PCM core, read only.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module ppcm_core (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire cs,  // chip select
	input wire [ADDR_BITS-1:2] addr,  // address
	input wire burst,  // burst mode flag
	output reg [31:0] dout,  // data read in
	output reg busy,  // busy flag
	output reg ack,  // acknowledge
	// Parallel PCM interfaces
	output reg pcm_ce_n = 1,
	output reg pcm_rst_n = 1,
	output reg pcm_oe_n = 1,
	output reg pcm_we_n = 1,
	output reg [ADDR_BITS-1:1] pcm_addr,
	input wire [15:0] pcm_din,
	output reg [15:0] pcm_dout
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100,  // main clock frequency in MHz
		ADDR_BITS = 24;  // address length for Parallel PCM
	localparam
		DELAY_INIT = 100000,  // delay time to complete initialization after reset, in ns
		DELAY_START = 115,  // delay time to get the first data, in ns
		DELAY_DATA = 25;  // delay time to get latter data within block, in ns
	localparam
		COUNT_INIT = 1 + CLK_FREQ * DELAY_INIT / 1000,
		COUNT_START = 1 + CLK_FREQ * DELAY_START / 1000,
		COUNT_DATA = 1 + CLK_FREQ * DELAY_DATA / 1000,
		COUNT_BITS = GET_WIDTH(COUNT_INIT-1);
	
	always @(posedge clk) begin
		pcm_rst_n <= ~rst;
	end
	
	localparam
		S_INIT = 0,  // wait for the initialization of PPCM
		S_IDLE = 1,  // idle
		S_WAIT = 2,  // wait for data
		S_OP1 = 3,  // read low 16-bits data
		S_OP2 = 4,  // read high 16-bits data
		S_DONE = 5;  // acknowledge
	
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
					next_state = S_IDLE;
					next_count = 0;
				end
				else begin
					next_state = S_INIT;
					next_count = count + 1'h1;
				end
			end
			S_IDLE: begin
				if (cs) begin
					next_state = S_WAIT;
				end
				else begin
					next_state = S_IDLE;
				end
			end
			S_WAIT: begin
				if (count == COUNT_START-COUNT_DATA-1) begin
					next_state = S_OP1;
					next_count = 0;
				end
				else begin
					next_state = S_WAIT;
					next_count = count + 1'h1;
				end
			end
			S_OP1: begin
				if (count == COUNT_DATA-1) begin
					next_state = S_OP2;
					next_count = 0;
				end
				else begin
					next_state = S_OP1;
					next_count = count + 1'h1;
				end
			end
			S_OP2: begin
				if (count == COUNT_DATA-1) begin
					if (cs && burst && (pcm_addr[3:1] != 3'b111))
						next_state = S_OP1;
					else
						next_state = S_DONE;
					next_count = 0;
				end
				else begin
					next_state = S_OP2;
					next_count = count + 1'h1;
				end
			end
			S_DONE: begin
				next_state = S_IDLE;
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
		pcm_ce_n <= 1;
		pcm_oe_n <= 1;
		pcm_we_n <= 1;
		pcm_addr <= 0;
		pcm_dout <= 0;
		busy <= 0;
		if (~rst) case (next_state)
			S_INIT: begin
				busy <= 1;
			end
			S_WAIT: begin
				busy <= 1;
				pcm_ce_n <= 0;
				pcm_oe_n <= 0;
				pcm_addr <= {addr, 1'b0};
			end
			S_OP1, S_OP2: begin
				busy <= 1;
				pcm_ce_n <= 0;
				pcm_oe_n <= 0;
				if (count == COUNT_DATA-1)
					pcm_addr <= pcm_addr + 1'h1;
				else
					pcm_addr <= pcm_addr;
			end
		endcase
	end
	
	always @(posedge clk) begin
		ack <= 0;
		if (~rst) case (state)
			S_OP1: if (count == COUNT_DATA-1) begin
				dout <= {16'b0, pcm_din};
			end
			S_OP2: if (count == COUNT_DATA-1) begin
				dout <= {pcm_din, dout[15:0]};
				ack <= 1;
			end
		endcase
	end
	
endmodule
