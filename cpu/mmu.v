`include "define.vh"


/**
 * Memory Management Unit.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module mmu (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire suspend,  // force suspend current process
	// address translation interfaces
	input wire en_mmu,  // enable signal
	output reg stall,  // stall other components when MMU is busy
	input wire [31:12] pdb_addr,  // base address of page directory table
	input wire [31:12] logical,  // logical address
	output reg [31:12] physical,  // physical address
	output reg page_fault,  // page fault error
	output reg auth_user,  // authorization: can be accessed by user mode
	output reg auth_exec,  // authorization: can be executed
	output reg auth_write,  // authorization: can be written
	output reg en_cache,  // cache enable for current page
	// data fetch interfaces (for page information)
	output reg ren,  // read enable signal
	output reg [31:0] addr,  // address of data
	input wire ack,  // acknowledgement
	input wire [31:0] data  // data content
	);
	
	parameter
		LINE_NUM = 16;  // number of lines in TLB, must be the power of 2
	
	wire tlb_hit_r;
	wire [24:0] tlb_data_r;
	reg tlb_en_w;
	reg [31:12] tlb_addr_w;
	reg [24:0] tlb_data_w;
	
	tlb #(
		.ADDR_BITS(32),
		.ENTRY_BITS(20),
		.DATA_BITS(25),
		.LINE_NUM(LINE_NUM)
		) TLB (
		.clk(clk),
		.rst(rst),
		.addr_r(logical),
		.hit_r(tlb_hit_r),
		.data_r(tlb_data_r),
		.en_w(tlb_en_w),
		.addr_w(tlb_addr_w),
		.data_w(tlb_data_w)
		);
	
	reg [24:0] tlb_data;
	reg [4:0] prop_buf;
	
	localparam
		S_IDLE = 0,  // idle
		S_OP1 = 1,  // fetch the page directory entry
		S_OP2 = 2;  // fetch the page table entry
	
	reg [1:0] state = 0;
	reg [1:0] next_state;
	
	always @(*) begin
		stall = 0;
		next_state = S_IDLE;
		if (~suspend) case (state)
			S_IDLE: begin
				if (en_mmu) begin
					if (tlb_hit_r) begin
						stall = 0;
						next_state = S_IDLE;
					end
					else if (~prop_buf[0]) begin
						stall = 0;
						next_state = S_IDLE;
					end
					else begin
						stall = 1;
						next_state = S_OP1;
					end
				end
				else begin
					stall = 0;
					next_state = S_IDLE;
				end
			end
			S_OP1: begin
				stall = 1;
				if (ack) begin
					if (data[0])
						next_state = S_OP2;
					else
						next_state = S_IDLE;
				end
				else begin
					next_state = S_OP1;
				end
			end
			S_OP2: begin
				stall = 1;
				if (ack)
					next_state = S_IDLE;
				else
					next_state = S_OP2;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst || suspend)
			state <= 0;
		else
			state <= next_state;
	end
	
	// memory control
	always @(posedge clk) begin
		if (rst || suspend) begin
			ren <= 0;
			addr <= 0;
		end
		else case (state)
			S_IDLE: begin
				if (en_mmu && ~tlb_hit_r) begin
					ren <= 1;
					addr <= {pdb_addr, logical[31:22], 2'b0};
				end
				else begin
					ren <= 0;
					addr <= 0;
				end
			end
			S_OP1: begin
				if (ack) begin
					ren <= 1;
					addr <= {data[31:12], logical[21:12], 2'b0};
				end
			end
		endcase
	end
	
	// TLB control
	always @(*) begin
		tlb_en_w = 0;
		tlb_addr_w = 0;
		tlb_data_w = 0;
		if (~suspend) case (state)
			S_OP2: begin
				tlb_en_w = ack;
				tlb_addr_w = logical;
				tlb_data_w = {data[31:12], data[4:0] & prop_buf};
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst || suspend)
			prop_buf <= 5'b01111;
		else case (state)
			S_IDLE: prop_buf <= 5'b01111;
			S_OP1: prop_buf <= data[4:0];
		endcase
	end
	
	// outputs
	always @(*) begin
		if (tlb_hit_r)
			tlb_data = tlb_data_r;
		else if (~prop_buf[0])
			tlb_data = {20'b0, prop_buf};
		else
			tlb_data = 0;
	end
	
	always @(*) begin
		physical = logical;
		page_fault = 0;
		auth_user = 1;
		auth_exec = 1;
		auth_write = 1;
		en_cache = 0;
		if (en_mmu && ~stall) begin
			physical = tlb_data[24:5];
			page_fault = ~tlb_data[0];
			auth_user = tlb_data[1];
			auth_exec = tlb_data[3];
			auth_write = tlb_data[2];
			en_cache = tlb_data[4];
		end
	end
	
endmodule
