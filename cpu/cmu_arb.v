`include "define.vh"


/**
 * CMU arbitrator, select requests from ITLB/DTLB/CPU_MEM to DCACHE.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module cmu_arb (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// ITLB channel
	input wire itlb_ren,  // read enable signal
	input wire [31:0] itlb_addr,  // read address
	output reg itlb_ack,  // acknowledgement
	output reg [31:0] itlb_data,  // data content
	// DTLB channel
	input wire dtlb_ren,  // read enable signal
	input wire [31:0] dtlb_addr,  // read address
	output reg dtlb_ack,  // acknowledgement
	output reg [31:0] dtlb_data,  // data content
	// CPU_MEM channel
	input wire mem_cen,  // whether using cache or access memory directly
	input wire [31:0] mem_addr,  // address for data read or write
	input wire [1:0] mem_type,  // memory access type (word, half, byte)
	input wire mem_ext,  // whether to use sign extend or not for byte or half word reading
	input wire mem_ren,  // read enable signal
	output reg [31:0] mem_dout,  // data read out
	input wire mem_wen,  // write enable signal
	input wire [31:0] mem_din,  // data write in
	input wire mem_fen,  // flush enable signal
	input wire mem_lock,  // keep current data to avoid process repeating
	// CMU signals
	output reg en_cache,
	output reg [31:0] addr_rw,
	output reg [1:0] addr_type,
	output reg sign_ext,
	output reg en_r,
	input wire [31:0] data_r,
	output reg en_w,
	output reg [31:0] data_w,
	output reg en_f,
	output reg lock,
	input wire stall,
	// other
	output wire stall_total  // stall other component when CMU is busy
	);
	
	`include "cpu_define.vh"
	parameter
		STALL_HALF_DELAY = 1;  // delay the stall signal half clock to prevent close logic loop
	
	localparam
		S_IDLE = 0,  // idle
		S_ITLB = 1,  // deal with ITLB's request
		S_DTLB = 2,  // deal with DTLB's request
		S_MEM = 3,  // deal with CPU_MEM's request
		S_WAIT = 4;  // wait one clock to prepare new request
	
	reg [2:0] state = 0;
	reg [2:0] next_state;
	
	always @(*) begin
		next_state = S_IDLE;
		case (state)
			S_IDLE, S_WAIT: begin
				if (itlb_ren)
					next_state = S_ITLB;
				else if (dtlb_ren)
					next_state = S_DTLB;
				else if (mem_ren || mem_wen || mem_fen)
					next_state = S_MEM;
				else
					next_state = S_IDLE;
			end
			S_ITLB: begin
				if (~stall)
					next_state = S_WAIT;
				else
					next_state = S_ITLB;
			end
			S_DTLB: begin
				if (~stall)
					next_state = S_WAIT;
				else
					next_state = S_DTLB;
			end
			S_MEM: begin
				if (~mem_lock && ~stall)
					next_state = S_IDLE;
				else
					next_state = S_MEM;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst)
			state <= 0;
		else
			state <= next_state;
	end
	
	always @(*) begin
		en_cache = 0;
		addr_rw = 0;
		addr_type = 0;
		sign_ext = 0;
		en_r = 0;
		en_w = 0;
		data_w = 0;
		en_f = 0;
		lock = 0;
		case (next_state)
			S_ITLB: begin
				en_cache = 1;
				addr_rw = itlb_addr;
				addr_type = MEM_TYPE_WORD;
				en_r = 1;
			end
			S_DTLB: begin
				en_cache = 1;
				addr_rw = dtlb_addr;
				addr_type = MEM_TYPE_WORD;
				en_r = 1;
			end
			S_MEM: begin
				en_cache = mem_cen;
				addr_rw = mem_addr;
				addr_type = mem_type;
				sign_ext = mem_ext;
				en_r = mem_ren;
				en_w = mem_wen;
				data_w = mem_din;
				en_f = mem_fen;
				lock = mem_lock;
			end
		endcase
	end
	
	always @(*) begin
		itlb_ack = 0;
		itlb_data = 0;
		dtlb_ack = 0;
		dtlb_data = 0;
		mem_dout = 0;
		case (state)
			S_ITLB: begin
				itlb_ack = ~stall;
				itlb_data = data_r;
			end
			S_DTLB: begin
				dtlb_ack = ~stall;
				dtlb_data = data_r;
			end
			S_MEM: begin
				mem_dout = data_r;
			end
		endcase
	end
	
	// stall
	reg stall_inner, stall_delay;
	
	always @(*) begin
		stall_inner = 0;
		case (next_state)
			S_ITLB, S_DTLB, S_WAIT: stall_inner = 1;
			S_MEM: stall_inner = stall;
		endcase
	end
	
	always @(negedge clk) begin
		if (rst)
			stall_delay <= 0;
		else
			stall_delay <= stall_inner;
	end
	
	assign
		stall_total = STALL_HALF_DELAY ? stall_delay : stall_inner;
	
endmodule
