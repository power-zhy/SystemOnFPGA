`include "define.vh"


/**
 * SRAM core.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module sram_core_sword (
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
	// SRAM interfaces
	output reg sram_ce_n,
	output reg sram_oe_n,
	output reg sram_we_n,
	output reg [ADDR_BITS-1:2] sram_addr,
	input wire [47:0] sram_din,
	output reg [47:0] sram_dout
	);
	
	`include "function.vh"
	parameter
		CLK_FREQ = 100,  // main clock frequency in MHz
		ADDR_BITS = 22;  // address length for SRAM
	
	localparam
		S_IDLE = 0,  // idle
		S_START = 1,  // set address and read operation
		S_READ = 2,  // read data
		S_WRITE = 3;  // write data
	
	reg [1:0] state = 0;
	reg [1:0] next_state;
	
	always @(*) begin
		next_state = 0;
		case (state)
			S_IDLE: begin
				if (cs)
					next_state = S_START;
				else
					next_state = S_IDLE;
			end
			S_START: begin
				if (~we)
					next_state = S_READ;
				else
					next_state = S_WRITE;
			end
			S_READ: begin
				if (cs && burst)
					next_state = S_START;
				else
					next_state = S_IDLE;
			end
			S_WRITE: begin
				if (cs && burst)
					next_state = S_START;
				else
					next_state = S_IDLE;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst) begin
			state <= 0;
		end
		else begin
			state <= next_state;
		end
	end
	
	reg bursting = 0;
	always @(posedge clk) begin
		busy <= 0;
		ack <= 0;
		sram_ce_n <= 1;
		sram_oe_n <= 1;
		sram_we_n <= 1;
		sram_addr <= 0;
		sram_dout <= 0;
		bursting <= 0;
		dout <= 0;
		if (~rst) case (next_state)
			S_IDLE: begin
				bursting <= 0;
			end
			S_START: begin
				busy <= 1;
				sram_ce_n <= 0;
				sram_oe_n <= 0;
				sram_addr <= bursting ? sram_addr + 1'h1 : addr;
				bursting <= cs & burst;
				ack <= we;  // acknowledge must be uttered earlier than normal as we need one clock to fetch next data
			end
			S_READ: begin
				busy <= 1;
				sram_ce_n <= 0;
				sram_oe_n <= 0;
				sram_addr <= sram_addr;
				bursting <= cs & burst;
				dout <= sram_din;
				ack <= 1;
			end
			S_WRITE: begin
				busy <= 1;
				sram_ce_n <= 0;
				sram_we_n <= 0;
				sram_addr <= sram_addr;
				sram_dout[31:24] <= sel[3] ? din[31:24] : sram_din[31:24];
				sram_dout[23:16] <= sel[2] ? din[23:16] : sram_din[23:16];
				sram_dout[15:8] <= sel[1] ? din[15:8] : sram_din[15:8];
				sram_dout[7:0] <= sel[0] ? din[7:0] : sram_din[7:0];
				bursting <= cs & burst;
			end
		endcase
	end
	
endmodule
