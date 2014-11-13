`include "define.vh"


/**
 * Memory management unit.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module mmu (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// address translation interfaces
	input wire en_mmu,  // enable signal
	output wire stall,  // stall other component when MMU is busy
	input wire [31:PAGE_ADDR_BITS] pdb_addr,  // base address of page directory table
	input wire [31:PAGE_ADDR_BITS] logical,  // logical address
	output wire [31:PAGE_ADDR_BITS] physical,  // physical address
	output wire page_fault,  // page fault error
	output wire auth_user,  // authorization: can be accessed by user mode
	output wire auth_exec,  // authorization: can be executed
	output wire auth_write,  // authorization: can be written
	output wire en_cache,  // cache enable for current page
	// data fetch interfaces (for page information)
	output wire ren,  // read enable signal
	output wire [31:0] addr,  // address of data
	input wire ack,  // acknowledgement
	input wire [31:0] data  // data content
	);
	
	parameter
		PAGE_ADDR_BITS = 12;  // address width for one page
	
	// TODO
	assign
		stall = 0,
		physical = logical,
		page_fault = 0,
		auth_user = 1,
		auth_exec = 1,
		auth_write = 1,
		en_cache = 0,
		ren = 0,
		addr = 0;
	
endmodule
