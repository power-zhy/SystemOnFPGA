`include "define.vh"


/**
 * MIPS 5-stage pipeline CPU Core, including data path and co-processors.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module mips_core (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	input wire [6:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	// MMU interfaces
	output wire user_mode,  // whether in user mode now
	output wire mmu_en,  // MMU enable signal
	output wire mmu_inv,  // invalidate MMU signal
	output wire [31:PAGE_ADDR_BITS] pdb_addr,  // base address of page directory table
	// instruction interfaces
	output wire inst_ren,  // instruction read enable signal
	input wire inst_stall,  // stall signal when IMMU/ICACHE is fetching data
	output wire [31:0] inst_addr,  // address of instruction needed
	input wire [31:0] inst_data,  // instruction fetched
	input wire inst_unalign,  // instruction address unaligned exception
	input wire inst_page_fault,  // instruction page fault exception
	input wire inst_unauth_user,  // instruction access not authorized for user mode exception
	input wire inst_unauth_exec,  // instruction execution not authorized exception
	output wire ic_lock,  // instruction cache lock signal, to prevent accessing the same data twice
	output wire ic_inv,  // invalidate instruction cache signal
	// memory interfaces
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	input wire mem_stall,  // stall signal when DMMU/DCACHE is fetching data
	output wire [1:0] mem_type,  // memory access type (word, half, byte)
	output wire mem_ext,  // whether using sign extended to memory data
	output wire [31:0] mem_addr,  // address of memory
	output wire [31:0] mem_dout,  // data writing to memory
	input wire [31:0] mem_din,  // data read from memory
	input wire mem_unalign,  // memory address unaligned exception
	input wire mem_page_fault,  // data page fault exception
	input wire mem_unauth_user,  // memory access not authorized for user mode exception
	input wire mem_unauth_write,  // memory write not authorized exception
	output wire dc_lock,  // data cache lock signal, to prevent accessing the same data twice
	output wire dc_inv,  // invalidate data cache signal
	// interrupt interfaces
	input wire [30:1] ir_map,  // device interrupt signals
	output wire wd_rst,  // watch dog reset, must not affect the global reset signal
	output wire exception  // exception occurred signal
	);
	
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz
	parameter
		PAGE_ADDR_BITS = 12;  // address length inside one memory page
	
	// debug
	`ifdef DEBUG
	wire [31:0] debug_data_path, debug_data_cp0;
	assign
		debug_data = debug_addr[6] ? debug_data_cp0 : debug_data_path;
	`endif
	
	// control signals
	wire [31:0] inst_data_ctrl;
	
	wire [1:0] pc_src_ctrl;
	wire imm_ext_ctrl;
	wire exe_a_src_ctrl;
	wire exe_b_src_ctrl;
	wire [3:0] exe_alu_oper_ctrl;
	wire [1:0] exe_cp_oper_ctrl;
	wire exe_signed_ctrl;
	wire [1:0] mem_type_ctrl;
	wire mem_ext_ctrl;
	wire mem_ren_ctrl;
	wire mem_wen_ctrl;
	wire [1:0] wb_addr_src_ctrl;
	wire [1:0] wb_data_src_ctrl;
	wire wb_wen_ctrl;
	wire is_jump_ctrl;
	
	wire [31:0] data_rs_ctrl, data_rt_ctrl;
	wire rs_used_ctrl, rt_used_ctrl;
	
	wire is_delay_slot, is_privilege;
	wire reg_stall;
	wire if_rst, if_en, if_valid;
	wire id_rst, id_en, id_valid;
	wire exe_rst, exe_en, exe_valid;
	wire mem_rst, mem_en, mem_valid;
	wire wb_en;
	
	// exception signals
	wire inst_illegal, inst_unrecognize;
	wire math_overflow, math_divide_zero;
	wire syscall;
	wire [31:0] exception_target;
	wire [31:0] inst_addr_mem, inst_data_mem;
	
	// co-processor signals
	wire [1:0] cp_oper;
	wire [4:0] cp_addr_r, cp_addr_w;
	wire [31:0] cp_data_r, cp_data_w;
	
	// CP0 registers
	wire [31:0] sr, ear, epcr, ehbr, ier, icr, pdbr, tir, wdr;
	
	// controller
	controller CONTROLLER (
		.clk(clk),
		.rst(id_rst),
		.ctrl_en(id_en),
		.inst(inst_data_ctrl),
		.data_rs(data_rs_ctrl),
		.data_rt(data_rt_ctrl),
		.user_mode(user_mode),
		.pc_src(pc_src_ctrl),
		.imm_ext(imm_ext_ctrl),
		.exe_a_src(exe_a_src_ctrl),
		.exe_b_src(exe_b_src_ctrl),
		.exe_alu_oper(exe_alu_oper_ctrl),
		.exe_cp_oper(exe_cp_oper_ctrl),
		.exe_signed(exe_signed_ctrl),
		.mem_type(mem_type_ctrl),
		.mem_ext(mem_ext_ctrl),
		.mem_ren(mem_ren_ctrl),
		.mem_wen(mem_wen_ctrl),
		.wb_addr_src(wb_addr_src_ctrl),
		.wb_data_src(wb_data_src_ctrl),
		.wb_wen(wb_wen_ctrl),
		.is_jump(is_jump_ctrl),
		.is_delay_slot(is_delay_slot),
		.is_privilege(is_privilege),
		.syscall(syscall),
		.ic_inv(ic_inv),
		.dc_inv(dc_inv),
		.rs_used(rs_used_ctrl),
		.rt_used(rt_used_ctrl),
		.illegal(inst_illegal),
		.unrecognized(inst_unrecognize)
	);
	
	// data path
	datapath DATAPATH (
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr[5:0]),
		.debug_data(debug_data_path),
		`endif
		.inst_data_ctrl(inst_data_ctrl),
		.data_rs_ctrl(data_rs_ctrl),
		.data_rt_ctrl(data_rt_ctrl),
		.rs_used_ctrl(rs_used_ctrl),
		.rt_used_ctrl(rt_used_ctrl),
		.pc_src_ctrl(pc_src_ctrl),
		.imm_ext_ctrl(imm_ext_ctrl),
		.exe_a_src_ctrl(exe_a_src_ctrl),
		.exe_b_src_ctrl(exe_b_src_ctrl),
		.exe_alu_oper_ctrl(exe_alu_oper_ctrl),
		.exe_cp_oper_ctrl(exe_cp_oper_ctrl),
		.exe_signed_ctrl(exe_signed_ctrl),
		.mem_type_ctrl(mem_type_ctrl),
		.mem_ext_ctrl(mem_ext_ctrl),
		.mem_ren_ctrl(mem_ren_ctrl),
		.mem_wen_ctrl(mem_wen_ctrl),
		.wb_addr_src_ctrl(wb_addr_src_ctrl),
		.wb_data_src_ctrl(wb_data_src_ctrl),
		.wb_wen_ctrl(wb_wen_ctrl),
		.is_jump_ctrl(is_jump_ctrl),
		.if_rst(if_rst),
		.if_en(if_en),
		.if_valid(if_valid),
		.inst_ren(inst_ren),
		.inst_addr(inst_addr),
		.inst_data(inst_data),
		.id_rst(id_rst),
		.id_en(id_en),
		.id_valid(id_valid),
		.cp_addr_r(cp_addr_r),
		.cp_data_r(cp_data_r),
		.reg_stall(reg_stall),
		.exe_rst(exe_rst),
		.exe_en(exe_en),
		.exe_valid(exe_valid),
		.cp_oper(cp_oper),
		.cp_addr_w(cp_addr_w),
		.cp_data_w(cp_data_w),
		.math_overflow(math_overflow),
		.math_divide_zero(math_divide_zero),
		.mem_rst(mem_rst),
		.mem_en(mem_en),
		.mem_valid(mem_valid),
		.mem_ren(mem_ren),
		.mem_wen(mem_wen),
		.mem_type(mem_type),
		.mem_ext(mem_ext),
		.mem_addr(mem_addr),
		.mem_dout(mem_dout),
		.mem_din(mem_din),
		.inst_addr_mem(inst_addr_mem),
		.inst_data_mem(inst_data_mem),
		.wb_en(wb_en),
		.exception(exception),
		.exception_target(exception_target)
	);
	
	// co-processor 0
	cp0 #(
		.CLK_FREQ(CLK_FREQ)
		) CP0 (
		.clk(clk),
		`ifdef DEBUG
		.debug_en(debug_en),
		.debug_step(debug_step),
		.debug_addr(debug_addr[4:0]),
		.debug_data(debug_data_cp0),
		`endif
		.oper(cp_oper),
		.addr_r(cp_addr_r),
		.data_r(cp_data_r),
		.addr_w(cp_addr_w),
		.data_w(cp_data_w),
		.rst(rst),
		.inst_addr_mem(inst_addr_mem),
		.inst_data_mem(inst_data_mem),
		.mem_addr(mem_addr),
		.inst_page_fault(inst_page_fault),
		.mem_page_fault(mem_page_fault),
		.inst_unauth_user(inst_unauth_user),
		.mem_unauth_user(mem_unauth_user),
		.inst_unauth_exec(inst_unauth_exec),
		.mem_unauth_write(mem_unauth_write),
		.inst_unalign(inst_unalign),
		.mem_unalign(mem_unalign),
		.inst_illegal(inst_illegal),
		.inst_unrecognize(inst_unrecognize),
		.math_overflow(math_overflow),
		.math_divide_zero(math_divide_zero),
		.syscall(syscall),
		.ir_map(ir_map),
		.wd_rst(wd_rst),
		.exception(exception),
		.exception_target(exception_target),
		.is_delay_slot(is_delay_slot),
		.is_privilege(is_privilege),
		.reg_stall(reg_stall),
		.inst_stall(inst_stall),
		.mem_stall(mem_stall),
		.if_rst(if_rst),
		.if_en(if_en),
		.if_valid(if_valid),
		.id_rst(id_rst),
		.id_en(id_en),
		.id_valid(id_valid),
		.exe_rst(exe_rst),
		.exe_en(exe_en),
		.exe_valid(exe_valid),
		.mem_rst(mem_rst),
		.mem_en(mem_en),
		.mem_valid(mem_valid),
		.wb_en(wb_en),
		.mmu_inv(mmu_inv),
		.sr(sr),
		.ear(ear),
		.epcr(epcr),
		.ehbr(ehbr),
		.ier(ier),
		.icr(icr),
		.pdbr(pdbr),
		.tir(tir),
		.wdr(wdr)
		);
	
	assign
		user_mode = sr[0],
		mmu_en = pdbr[0],
		pdb_addr = pdbr[31:PAGE_ADDR_BITS];
	assign
		ic_lock = ~if_en,
		dc_lock = ~mem_en;
	
endmodule
