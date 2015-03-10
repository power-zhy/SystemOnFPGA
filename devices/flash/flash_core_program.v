`include "define.vh"


/**
 * Flash memory core, read only.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module flash_core_program (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire cs,  // chip select
	input wire we,  // write enable
	input wire [ADDR_BITS-1:1] addr,  // address
	input wire burst,  // burst mode flag
	input wire [15:0] din,  // command to write
	output reg [15:0] dout,  // data read in
	output reg busy,  // busy flag
	output reg ack,  // acknowledge
	// Flash memory interfaces
	output reg flash_ce_n = 1,
	output reg flash_rst_n = 1,
	output reg flash_oe_n = 1,
	output reg flash_we_n = 1,
	output reg flash_wp_n = 0,
	input wire flash_ready,
	output reg [ADDR_BITS-1:1] flash_addr,
	input wire [15:0] flash_din,
	output reg [15:0] flash_dout
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100,  // main clock frequency in MHz
		ADDR_BITS = 24,  // address length for flash memory
		ADDR_BURST = 4;  // address length in which burst can be used
	localparam
		DELAY_INIT = 300000,  // delay time to complete initialization after reset, in ns
		DELAY_PRE_READ = 100,  // delay time to get the first data, in ns
		DELAY_READ = 30,  // delay time to get latter data within block, in ns
		DELAY_WRITE = 30,  // delay time to write one command, in ns
		DELAY_DONE = 80;  // delay time to wait between two operations, in ns
	localparam
		COUNT_INIT = 1 + CLK_FREQ * DELAY_INIT / 1000,
		COUNT_PRE_READ = 1 + CLK_FREQ * DELAY_PRE_READ / 1000,
		COUNT_READ = 1 + CLK_FREQ * DELAY_READ / 1000,
		COUNT_WRITE = 1 + CLK_FREQ * DELAY_WRITE / 1000,
		COUNT_DONE = 1 + CLK_FREQ * DELAY_DONE / 1000,
		COUNT_BITS = GET_WIDTH(COUNT_INIT-1);
	
	wire flash_burst;
	assign flash_burst = cs && burst && (flash_addr[ADDR_BURST:1] != {ADDR_BURST{1'b1}});
	
	localparam
		S_INIT = 0,  // initialization
		S_IDLE = 1,  // idle
		S_PRE_READ = 2,  // wait for data
		S_READ = 3,  // read data
		S_WRITE = 4,  // write command
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
					if (flash_ready) begin
						next_state = S_IDLE;
						next_count = 0;
					end
					else begin
						next_state = S_INIT;
						next_count = count;
					end
				end
				else begin
					next_state = S_INIT;
					next_count = count + 1'h1;
				end
			end
			S_IDLE: begin
				if (cs) begin
					if (we)
						next_state = S_WRITE;
					else
						next_state = S_PRE_READ;
				end
				else begin
					next_state = S_IDLE;
				end
			end
			S_PRE_READ: begin
				if (count == (COUNT_PRE_READ==COUNT_READ ? 0 : COUNT_PRE_READ-COUNT_READ-1)) begin
					next_state = S_READ;
					next_count = 0;
				end
				else begin
					next_state = S_PRE_READ;
					next_count = count + 1'h1;
				end
			end
			S_READ: begin
				if (count == COUNT_READ-1) begin
					if (flash_burst)
						next_state = S_READ;
					else
						next_state = S_DONE;
					next_count = 0;
				end
				else begin
					next_state = S_READ;
					next_count = count + 1'h1;
				end
			end
			S_WRITE: begin
				if (count == COUNT_WRITE-1) begin
					next_state = S_DONE;
					next_count = 0;
				end
				else begin
					next_state = S_WRITE;
					next_count = count + 1'h1;
				end
			end
			S_DONE: begin
				if (count == COUNT_DONE-1) begin
					if (flash_ready) begin
						next_state = S_IDLE;
						next_count = 0;
					end
					else begin
						next_state = S_DONE;
						next_count = count;
					end
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
		flash_rst_n <= ~rst;
		flash_ce_n <= 1;
		flash_oe_n <= 1;
		flash_we_n <= 1;
		flash_wp_n <= 0;
		flash_addr <= 0;
		flash_dout <= 0;
		busy <= 0;
		if (~rst) case (next_state)
			S_INIT: begin
				busy <= 1;
			end
			S_PRE_READ: begin
				busy <= 1;
				flash_ce_n <= 0;
				flash_oe_n <= 0;
				flash_addr <= addr;
			end
			S_READ: begin
				busy <= 1;
				flash_ce_n <= 0;
				flash_oe_n <= 0;
				if (next_count == COUNT_READ-1)
					flash_addr <= flash_addr + 1'h1;
				else
					flash_addr <= flash_addr;
			end
			S_WRITE: begin
				busy <= 1;
				flash_ce_n <= 0;
				flash_oe_n <= 1;
				flash_we_n <= 0;
				flash_addr <= addr;
				flash_dout <= din;
			end
			S_DONE: begin
				busy <= 1;
			end
		endcase
	end
	
	always @(posedge clk) begin
		ack <= 0;
		if (~rst) case (next_state)
			S_READ: if (next_count == COUNT_READ-1) begin
				dout <= flash_din;
				ack <= 1;
			end
			S_DONE: if (state == S_WRITE) begin
				ack <= 1;
			end
		endcase
	end
	
endmodule
