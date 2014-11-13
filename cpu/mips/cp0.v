`include "define.vh"


/**
 * Co-processor 0 for MIPS 5-stage pipeline CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module cp0 (
	input wire clk,  // main clock
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	input wire [4:0] debug_addr,  // debug address
	output reg [31:0] debug_data,  // debug data
	`endif
	// operations (read in ID stage and write in EXE stage)
	input wire [1:0] oper,  // CP0 operation type
	input wire [4:0] addr_r,  // read address
	output reg [31:0] data_r,  // read data
	input wire [4:0] addr_w,  // write address
	input wire [31:0] data_w,  // write data
	// exceptions (check exceptions in MEM stage)
	input wire rst,  // synchronous reset
	input wire [31:0] inst_addr_mem,  // address of instruction (in MEM stage)
	input wire [31:0] inst_data_mem,  // content of instruction (in MEM stage)
	input wire [31:0] mem_addr,  // address of accessed memory
	input wire inst_page_fault,  // instruction page fault exception
	input wire mem_page_fault,  // data page fault exception
	input wire inst_unauth_user,  // instruction access not authorized for user mode exception
	input wire mem_unauth_user,  // memory access not authorized for user mode exception
	input wire inst_unauth_exec,  // instruction execution not authorized exception
	input wire mem_unauth_write,  // memory write not authorized exception
	input wire inst_unalign,  // instruction address unaligned exception
	input wire mem_unalign,  // memory address unaligned exception
	input wire inst_illegal,  // instruction illegal exception
	input wire inst_unrecognize,  // instruction can't be recognized exception
	input wire math_overflow,  // math overflow exception
	input wire math_divide_zero,  // math divide by zero exception
	input wire syscall,  // whether current instruction is system call instruction
	input wire [30:1] ir_map,  // device interrupt signals
	output reg wd_rst,  // watch dog reset, must not affect the global reset signal
	output reg exception,  // exception occurred signal
	output reg [31:0] exception_target,  // target instruction address when exception occurred
	// data path control
	input wire is_delay_slot,  // whether current instruction is in delay slot
	input wire is_privilege,  // whether current instruction is a privilege instruction
	input wire reg_stall,  // stall signal when LW instruction followed by an related R instruction
	input wire inst_stall,  // stall signal when IMMU/ICACHE is fetching data
	input wire mem_stall,  // stall signal when DMMU/DCACHE is fetching data
	output reg if_rst,  // stage reset signal
	output reg if_en,  // stage enable signal
	input wire if_valid,  // stage valid flag
	output reg id_rst,
	output reg id_en,
	input wire id_valid,
	output reg exe_rst,
	output reg exe_en,
	input wire exe_valid,
	output reg mem_rst,
	output reg mem_en,
	input wire mem_valid,
	output reg wb_en,
	// MMU control
	output reg mmu_inv,  // invalidate MMU signal
	// CP0 registers
	output reg [31:0] sr, ear, epcr, ehbr, ier, icr, pdbr, tir, wdr
	);
	
	`include "mips_define.vh"
	`include "function.vh"
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz
	localparam
		WDR_CLK_DIV = CLK_FREQ * 1000000,
		WDR_CLK_DIV_WIDTH = GET_WIDTH(WDR_CLK_DIV-1),
		TIR_CLK_DIV = CLK_FREQ * 1000,
		TIR_CLK_DIV_WIDTH = GET_WIDTH(TIR_CLK_DIV-1);
	
	// debug
	`ifdef DEBUG
	always @(*) begin
		case (debug_addr)
			CP0_SR: debug_data = sr;
			CP0_EAR: debug_data = ear;
			CP0_EPCR: debug_data = epcr;
			CP0_EHBR: debug_data = ehbr;
			CP0_IER: debug_data = ier;
			CP0_ICR: debug_data = icr;
			CP0_PDBR: debug_data = pdbr;
			CP0_TIR: debug_data = tir;
			CP0_WDR: debug_data = wdr;
			default: debug_data = 0;
		endcase
	end
	`endif
	
	// read
	always @(*) begin
		case (addr_r)
			CP0_SR: data_r = sr;
			CP0_EAR: data_r = ear;
			CP0_EPCR: data_r = epcr;
			CP0_EHBR: data_r = ehbr;
			CP0_IER: data_r = ier;
			CP0_ICR: data_r = icr;
			CP0_PDBR: data_r = pdbr;
			CP0_TIR: data_r = tir;
			CP0_WDR: data_r = wdr;
			default: data_r = 0;
		endcase
	end
	
	// pipelined exceptions
	reg inst_unalign_id, inst_unalign_exe, inst_unalign_mem;
	reg inst_page_fault_id, inst_page_fault_exe, inst_page_fault_mem;
	reg inst_unauth_user_id, inst_unauth_user_exe, inst_unauth_user_mem;
	reg unauth_exec_id, unauth_exec_exe, unauth_exec_mem;
	reg inst_illegal_exe, inst_illegal_mem;
	reg inst_unrecognize_exe, inst_unrecognize_mem;
	reg math_overflow_mem;
	reg math_divide_zero_mem;
	reg syscall_exe, syscall_mem;
	reg [31:0] inst_addr_prev_mem;
	reg is_delay_slot_exe, is_delay_slot_mem;
	reg is_privilege_exe;
	
	always @(posedge clk) begin
		if (id_rst) begin
			inst_unalign_id <= 0;
			inst_page_fault_id <= 0;
			inst_unauth_user_id <= 0;
			unauth_exec_id <= 0;
		end
		else if (id_en) begin
			inst_unalign_id <= inst_unalign;
			inst_page_fault_id <= inst_page_fault;
			inst_unauth_user_id <= inst_unauth_user;
			unauth_exec_id <= inst_unauth_exec;
		end
	end
	
	always @(posedge clk) begin
		if (exe_rst) begin
			inst_unalign_exe <= 0;
			inst_page_fault_exe <= 0;
			inst_unauth_user_exe <= 0;
			unauth_exec_exe <= 0;
			inst_illegal_exe <= 0;
			inst_unrecognize_exe <= 0;
			syscall_exe <= 0;
			is_delay_slot_exe <= 0;
			is_privilege_exe <= 0;
		end
		else if (exe_en) begin
			inst_unalign_exe <= inst_unalign_id;
			inst_page_fault_exe <= inst_page_fault_id;
			inst_unauth_user_exe <= inst_unauth_user_id;
			unauth_exec_exe <= unauth_exec_id;
			inst_illegal_exe <= inst_illegal;
			inst_unrecognize_exe <= inst_unrecognize;
			syscall_exe <= syscall;
			is_delay_slot_exe <= is_delay_slot;
			is_privilege_exe <= is_privilege;
		end
	end
	
	always @(posedge clk) begin
		if (mem_rst) begin
			inst_unalign_mem <= 0;
			inst_page_fault_mem <= 0;
			inst_unauth_user_mem <= 0;
			unauth_exec_mem <= 0;
			inst_illegal_mem <= 0;
			inst_unrecognize_mem <= 0;
			math_overflow_mem <= 0;
			math_divide_zero_mem <= 0;
			syscall_mem <= 0;
			inst_addr_prev_mem <= 0;
			is_delay_slot_mem <= 0;
		end
		else if (mem_en) begin
			inst_unalign_mem <= inst_unalign_exe;
			inst_page_fault_mem <= inst_page_fault_exe;
			inst_unauth_user_mem <= inst_unauth_user_exe;
			unauth_exec_mem <= unauth_exec_exe;
			inst_illegal_mem <= inst_illegal_exe;
			inst_unrecognize_mem <= inst_unrecognize_exe;
			math_overflow_mem <= math_overflow;
			math_divide_zero_mem <= math_divide_zero;
			syscall_mem <= syscall_exe;
			inst_addr_prev_mem <= inst_addr_mem;
			is_delay_slot_mem <= is_delay_slot_exe;
		end
	end
	
	reg [4:0] ex_code;
	reg [31:0] ex_ear;
	
	always @(*) begin
		ex_code = EX_NONE;
		ex_ear = 0;
		case (1)
			inst_unalign_mem: begin
				ex_code = EX_INST_UNALIGN;
				ex_ear = inst_addr_mem;
			end
			inst_page_fault_mem: begin
				ex_code = EX_PAGE_FAULT;
				ex_ear = inst_addr_mem;
			end
			inst_unauth_user_mem: begin
				ex_code = EX_UNAUTH_USER;
				ex_ear = inst_addr_mem;
			end
			unauth_exec_mem: begin
				ex_code = EX_UNAUTH_EXEC;
				ex_ear = inst_addr_mem;
			end
			inst_unrecognize_mem: begin
				ex_code = EX_INST_UNRECOGNIZE;
				ex_ear = inst_addr_mem;
			end
			inst_illegal_mem: begin
				ex_code = EX_INST_ILLEGAL;
				ex_ear = inst_addr_mem;
			end
			math_overflow_mem: begin
				ex_code = EX_MATH_OVERFLOW;
				ex_ear = inst_addr_mem;
			end
			math_divide_zero_mem: begin
				ex_code = EX_MATH_DIVIDE_ZERO;
				ex_ear = inst_addr_mem;
			end
			mem_unalign: begin
				ex_code = EX_MEM_UNALIGN;
				ex_ear = mem_addr;
			end
			mem_page_fault: begin
				ex_code = EX_PAGE_FAULT;
				ex_ear = mem_addr;
			end
			mem_unauth_user: begin
				ex_code = EX_UNAUTH_USER;
				ex_ear = mem_addr;
			end
			mem_unauth_write: begin
				ex_code = EX_UNAUTH_WRITE;
				ex_ear = mem_addr;
			end
		endcase
	end
	
	wire ex, ir;
	assign
		ex = ex_code != EX_NONE,
		ir = ier[31] & (|(ier[30:0] & icr[30:0]));
	
	// pipeline control
	reg ir_en, ir_en_pending;
	wire ir_valid;
	
	// interrupt can not be handled when current instruction in MEM(where exception is checked) is invalid, as no PC is valid to write to EPC
	always @(posedge clk) begin
		ir_en <= ir_en_pending;
	end
	
	assign ir_valid = ir & ir_en & mem_valid;
	
	`ifdef DEBUG
	reg debug_step_prev;
	reg fatal = 0;  // when fatal error detected, stop whole CPU permanently and only step execution is allowed
	
	always @(posedge clk) begin
		debug_step_prev <= debug_step;
	end
	
	always @(posedge clk) begin
		if (rst || wd_rst)
			fatal <= 0;
		else if (sr[31] && (ex || ir_valid || syscall_mem))
			fatal <= 1;
	end
	`endif
	
	always @(*) begin
		if_rst = 0;
		if_en = 1;
		id_rst = 0;
		id_en = 1;
		exe_rst = 0;
		exe_en = 1;
		mem_rst = 0;
		mem_en = 1;
		wb_en = 1;
		ir_en_pending = 1;
		`ifdef DEBUG
		if ((debug_en || fatal) && ~(~debug_step_prev && debug_step)) begin
			if_en = 0;
			id_en = 0;
			exe_en = 0;
			mem_en = 0;
			wb_en = 0;
			ir_en_pending = 0;
		end
		else
		`endif
		// exception only occurs when new instruction goes into MEM stage.
		// cancel all instructions in the pipeline except WB stage.
		// do not reset IF stage, as it needs to load the exception target
		if (exception) begin
			id_rst = 1;
			exe_rst = 1;
			mem_rst = 1;
			wb_en = 0;
			ir_en_pending = 0;
		end
		// these two stalls indicate that MMU/CACHE is fetching data, freeze the whole pipeline.
		else if (inst_stall || mem_stall) begin
			if_en = 0;
			id_en = 0;
			exe_en = 0;
			mem_en = 0;
			wb_en = 0;
			ir_en_pending = 0;
		end
		// this stall indicate that ID is waiting for previous LW instruction, insert one NOP between ID and EXE.
		else if (reg_stall) begin
			if_en = 0;
			id_en = 0;
			exe_rst = 1;
		end
		// as privilege instruction take effect in EXE stage, it maybe too late to cancel it when the previous one in MEM cause an exception.
		// just insert a NOP before privilege instruction so that it never be cancelled after ID stage.
		else if (is_privilege && exe_valid) begin
			if_en = 0;
			id_en = 0;
			exe_rst = 1;
			ir_en_pending = 0;
		end
		// as privilege instruction may change many important CPU configurations, make sure the next instruction be fetched after this one complete.
		// actually, the next one instruction may still be incompatible with the changed configurations.
		// it also make sure that this privilege instruction will not cause exception.
		else if (is_privilege || is_privilege_exe) begin
			if_en = 0;
			id_rst = 1;
			ir_en_pending = 0;
		end
	end
	
	// Exception Handler Base Register
	always @(posedge clk) begin
		if (rst || wd_rst)
			ehbr <= {PC_RESET[31:2], 2'b00};
		else if (oper == EXE_CP_STORE && addr_w == CP0_EHBR)
			ehbr <= data_w;
	end
	
	// Status Register (read only)
	// Exception Argument Register (read only)
	// Exception Program Counter Register
	wire [31:0] epc;
	assign
		epc = syscall_mem ? inst_addr_mem+4 : (is_delay_slot_mem ? inst_addr_prev_mem : inst_addr_mem);
	
	always @(posedge clk) begin
		if (rst) begin
			sr <= 0;
			ear <= 0;
			epcr <= 0;
		end
		else if (wd_rst) begin
			sr[31:28] <= 4'b0001;
			sr[0] <= 1'b0;
			epcr <= {epc[31:2], 1'b0, sr[0]};
		end
		else if (ex) begin
			sr[31:28] <= 4'b1000;
			sr[15:11] <= ex_code;
			sr[0] <= 1'b0;
			ear <= ex_ear;
			epcr <= {epc[31:2], 1'b0, sr[0]};
		end
		else if (ir_valid) begin
			sr[31:28] <= 4'b0100;
			sr[0] <= 1'b0;
			epcr <= {epc[31:2], 1'b0, sr[0]};
		end
		else if (syscall_mem) begin
			sr[31:28] <= 4'b0010;
			sr[10:1] <= inst_data_mem[15:6];
			sr[0] <= 1'b0;
			epcr <= {epc[31:2], 1'b0, sr[0]};
		end
		else if (oper == EXE_CP0_ERET) begin
			sr[31:28] <= 4'b0000;
			sr[0] <= epcr[0];
		end
		else if (oper == EXE_CP_STORE && addr_w == CP0_EPCR) begin
			epcr <= data_w;
		end
	end
	
	reg eret;
	
	always @(*) begin
		exception = 0;
		exception_target = 0;
		eret = 0;
		if (rst || wd_rst) begin
			exception = 1;
			exception_target = {PC_RESET[31:2], 2'b00};
		end
		else if (ex) begin
			exception = 1;
			exception_target = {ehbr[31:2], 2'b00};
		end
		else if (ir_valid) begin
			exception = 1;
			exception_target = {ehbr[31:2], 2'b00};
		end
		else if (syscall_mem) begin
			exception = 1;
			exception_target = {ehbr[31:2], 2'b00};
		end
		else if (oper == EXE_CP0_ERET) begin
			exception = 1;
			exception_target = {epcr[31:2], 2'b00};
			eret = 1;
		end
	end
	
	// Timer Interval Register
	reg [TIR_CLK_DIV_WIDTH-1:0] tir_clk_count;
	reg [11:0] tir_ms_count;
	reg ir_timer;
	
	always @(posedge clk) begin
		if (rst || wd_rst)
			tir <= 0;
		else if (oper == EXE_CP_STORE && addr_w == CP0_TIR)
			tir <= data_w;
	end
	
	always @(posedge clk) begin
		ir_timer <= 0;
		if (rst || tir == 0) begin
			tir_clk_count <= 0;
			tir_ms_count <= 0;
		end
		else if (tir_clk_count != TIR_CLK_DIV-1) begin
			tir_clk_count <= tir_clk_count + 1'h1;
		end
		else begin
			tir_clk_count <= 0;
			if (tir_ms_count != tir) begin
				tir_ms_count <= tir_ms_count + 1'b1;
			end
			else begin
				tir_ms_count <= 0;
				ir_timer <= 1;
			end
		end
	end
	
	// Interrupt Enable Register
	always @(posedge clk) begin
		if (rst || wd_rst)
			ier <= 0;
		else if (exception)
			ier[31] <= eret;
		else if (oper == EXE_CP_STORE && addr_w == CP0_IER)
			ier <= data_w;
	end
	
	// Interrupt Cause Register
	always @(posedge clk) begin
		if (rst || wd_rst)
			icr <= 0;
		else if (oper == EXE_CP_STORE && addr_w == CP0_ICR)
			icr <= (icr | {1'b0, ir_map, ir_timer}) & ~data_w;
		else
			icr <= icr | {1'b0, ir_map, ir_timer};
	end
	
	// Page Directory Base Register
	always @(posedge clk) begin
		mmu_inv <= 0;
		if (rst || wd_rst) begin
			pdbr <= 0;
			mmu_inv <= 0;
		end
		else if (oper == EXE_CP_STORE && addr_w == CP0_PDBR) begin
			pdbr <= data_w;
			mmu_inv <= 1;
		end
	end
	
	// Watch Dog Register
	reg [WDR_CLK_DIV_WIDTH-1:0] wdr_clk_count;
	reg [11:0] wdr_sec_count;
	
	always @(posedge clk) begin
		if (rst || wd_rst)
			wdr <= 0;
		else if (oper == EXE_CP_STORE && addr_w == CP0_WDR)
			wdr <= data_w;
	end
	
	always @(posedge clk) begin
		wd_rst <= 0;
		if (rst || wdr == 0) begin
			wdr_clk_count <= 0;
			wdr_sec_count <= 0;
		end
		else if (wdr_clk_count != WDR_CLK_DIV-1) begin
			wdr_clk_count <= wdr_clk_count + 1'h1;
		end
		else begin
			wdr_clk_count <= 0;
			if (wdr_sec_count != wdr) begin
				wdr_sec_count <= wdr_sec_count + 1'b1;
			end
			else begin
				wdr_sec_count <= 0;
				wd_rst <= 1;
			end
		end
	end
	
endmodule
