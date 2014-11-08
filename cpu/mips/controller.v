`include "define.vh"


/**
 * Controller for MIPS 5-stage pipelined CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module controller (/*AUTOARG*/
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire ctrl_en,  // controller enable signal
	input wire [31:0] inst,  // instruction
	input wire [31:0] data_rs,  // data in register RS
	input wire [31:0] data_rt,  // data in register RT
	input wire user_mode,  // whether in user mode now
	output reg [1:0] pc_src,  // how would PC change to next
	output reg imm_ext,  // whether using sign extended to immediate data
	output reg exe_a_src,  // data source of operand A for ALU
	output reg exe_b_src,  // data source of operand B for ALU
	output reg [3:0] exe_alu_oper,  // ALU operation type
	output reg [1:0] exe_cp_oper,  // co-processor operation type
	output reg exe_signed,  // whether regard operands as signed data in ALU
	output reg [1:0] mem_type,  // memory access type (word, half, byte)
	output reg mem_ext,  // whether using sign extended to memory data
	output reg mem_ren,  // memory read enable signal
	output reg mem_wen,  // memory write enable signal
	output reg [1:0] wb_addr_src,  // address source to write data back to registers
	output reg [1:0] wb_data_src,  // data source of data being written back to registers
	output reg wb_wen,  // register write enable signal
	output reg is_jump,  // whether current instruction is a jump instruction
	output reg is_delay_slot,  // whether current instruction is in delay slot
	output reg is_privilege,  // whether current instruction is a privilege instruction
	output reg syscall,  // whether current instruction is system call instruction
	output reg ic_inv,  // whether to invalid instruction cache
	output reg dc_inv,  // whether to invalid data cache
	output reg rs_used,  // whether RS is used
	output reg rt_used,  // whether RT is used
	output reg illegal,  // whether current instruction is a privilege instruction but is in user mode now
	output reg unrecognized  // whether current instruction can not be recognized
	);
	
	`include "mips_define.vh"
	
	always @(*) begin
		pc_src = PC_NEXT;
		imm_ext = 0;
		exe_a_src = EXE_A_RS;
		exe_b_src = EXE_B_RT;
		exe_alu_oper = EXE_ALU_ADD;
		exe_cp_oper = EXE_CP_NONE;
		exe_signed = 0;
		mem_type = MEM_TYPE_WORD;
		mem_ext = 0;
		mem_ren = 0;
		mem_wen = 0;
		wb_addr_src = WB_ADDR_RD;
		wb_data_src = WB_DATA_ALU;
		wb_wen = 0;
		is_jump = 0;
		is_privilege = 0;
		syscall = 0;
		ic_inv = 0;
		dc_inv = 0;
		rs_used = 0;
		rt_used = 0;
		illegal = 0;
		unrecognized = 0;
		case (inst[31:26])
			INST_R: begin
				case (inst[5:0])
					R_FUNC_SLL: begin
						exe_alu_oper = EXE_ALU_SLL;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SRL: begin
						exe_alu_oper = EXE_ALU_SRL;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SRA: begin
						exe_alu_oper = EXE_ALU_SRL;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						exe_signed = 1;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SLLV: begin
						exe_alu_oper = EXE_ALU_SLLV;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SRLV: begin
						exe_alu_oper = EXE_ALU_SRLV;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SRAV: begin
						exe_alu_oper = EXE_ALU_SRLV;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						exe_signed = 1;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_JR: begin
						pc_src = PC_JR;
						is_jump = 1;
						rs_used = 1;
					end
					R_FUNC_JALR: begin
						pc_src = PC_JR;
						wb_addr_src = WB_ADDR_LINK;
						wb_data_src = WB_DATA_LINK;
						wb_wen = 1;
						is_jump = 1;
						rs_used = 1;
					end
					R_FUNC_MOVZ: begin
						if (data_rt == 32'h0) begin
							wb_addr_src = WB_ADDR_RD;
							wb_data_src = WB_DATA_REGA;
							wb_wen = 1;
							rs_used = 1;
						end
						rt_used = 1;
					end
					R_FUNC_MOVN: begin
						if (data_rt != 32'h0) begin
							wb_addr_src = WB_ADDR_RD;
							wb_data_src = WB_DATA_REGA;
							wb_wen = 1;
							rs_used = 1;
						end
						rt_used = 1;
					end
					R_FUNC_SYSCALL: begin
						syscall = 1;
					end
					R_FUNC_ADD: begin
						exe_alu_oper = EXE_ALU_ADD;
						exe_signed = 1;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_ADDU: begin
						exe_alu_oper = EXE_ALU_ADD;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SUB: begin
						exe_alu_oper = EXE_ALU_SUB;
						exe_signed = 1;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SUBU: begin
						exe_alu_oper = EXE_ALU_SUB;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_AND: begin
						exe_alu_oper = EXE_ALU_AND;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_OR: begin
						exe_alu_oper = EXE_ALU_OR;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_XOR: begin
						exe_alu_oper = EXE_ALU_XOR;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_NOR: begin
						exe_alu_oper = EXE_ALU_NOR;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SLT: begin
						exe_alu_oper = EXE_ALU_SLT;
						exe_signed = 1;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SLTU: begin
						exe_alu_oper = EXE_ALU_SLT;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					default: begin
						unrecognized = 1;
					end
				endcase
			end
			INST_I: begin
				exe_b_src = EXE_B_IMM;
				imm_ext = 1;
				case (inst[20:16])
					I_FUNC_BLTZ: begin
						if (data_rs[31]) begin
							pc_src = PC_BRANCH;
						end
						is_jump = 1;
						rs_used = 1;
					end
					I_FUNC_BGEZ: begin
						if (~data_rs[31]) begin
							pc_src = PC_BRANCH;
						end
						is_jump = 1;
						rs_used = 1;
					end
					I_FUNC_BLTZAL: begin
						if (data_rs[31]) begin
							pc_src = PC_BRANCH;
							wb_addr_src = WB_ADDR_LINK;
							wb_data_src = WB_DATA_LINK;
							wb_wen = 1;
						end
						is_jump = 1;
						rs_used = 1;
					end
					I_FUNC_BGEZAL: begin
						if (~data_rs[31]) begin
							pc_src = PC_BRANCH;
							wb_addr_src = WB_ADDR_LINK;
							wb_data_src = WB_DATA_LINK;
							wb_wen = 1;
						end
						is_jump = 1;
						rs_used = 1;
					end
					default: begin
						unrecognized = 1;
					end
				endcase
			end
			INST_J: begin
				pc_src = PC_JUMP;
				is_jump = 1;
			end
			INST_JAL: begin
				pc_src = PC_JUMP;
				wb_addr_src = WB_ADDR_LINK;
				wb_data_src = WB_DATA_LINK;
				wb_wen = 1;
				is_jump = 1;
			end
			INST_BEQ: begin
				if (data_rs == data_rt) begin
					pc_src = PC_BRANCH;
					exe_b_src = EXE_B_IMM;
				end
				imm_ext = 1;
				is_jump = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_BNE: begin
				if (data_rs != data_rt) begin
					pc_src = PC_BRANCH;
					exe_b_src = EXE_B_IMM;
				end
				imm_ext = 1;
				is_jump = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_BLEZ: begin
				if (data_rs[31] || data_rs == 0) begin
					pc_src = PC_BRANCH;
				end
				is_jump = 1;
				rs_used = 1;
			end
			INST_BGTZ: begin
				if (~data_rs[31] && data_rs != 0) begin
					pc_src = PC_BRANCH;
				end
				is_jump = 1;
				rs_used = 1;
			end
			INST_ADDI: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				exe_signed = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_ADDIU: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_SLTI: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_SLT;
				exe_signed = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_SLTIU: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_SLT;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_ANDI: begin
				imm_ext = 0;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_AND;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_ORI: begin
				imm_ext = 0;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_OR;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_XORI: begin
				imm_ext = 0;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_XOR;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_LUI: begin
				exe_alu_oper = EXE_ALU_LUI;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_LB: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_type = MEM_TYPE_BYTE;
				mem_ext = 1;
				mem_ren = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_MEM;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_LH: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_type = MEM_TYPE_HALF;
				mem_ext = 1;
				mem_ren = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_MEM;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_LW: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_type = MEM_TYPE_WORD;
				mem_ext = 1;
				mem_ren = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_MEM;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_LBU: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_type = MEM_TYPE_BYTE;
				mem_ren = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_MEM;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_LHU: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_type = MEM_TYPE_HALF;
				mem_ren = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_MEM;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_SB: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_type = MEM_TYPE_BYTE;
				mem_wen = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_SH: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_type = MEM_TYPE_HALF;
				mem_wen = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_SW: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_type = MEM_TYPE_WORD;
				mem_wen = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_CP0: begin
				if (user_mode) begin
					illegal = 1;
				end
				else begin
					is_privilege = 1;
					if (~inst[25]) begin
						case (inst[24:21])
							CP_FUNC_MF: begin
								exe_a_src = EXE_A_CP;
								wb_addr_src = WB_ADDR_RT;
								wb_data_src = WB_DATA_REGA;
								wb_wen = 1;
							end
							CP_FUNC_MT: begin
								exe_cp_oper = EXE_CP_STORE;
								rt_used = 1;
							end
							default: begin
								unrecognized = 1;
							end
						endcase
					end
					else begin
						case (inst[5:0])
							CP0_CO_ERET: begin
								exe_cp_oper = EXE_CP0_ERET;
							end
							default: begin
								unrecognized = 1;
							end
						endcase
					end
				end
			end
			INST_CACHE: begin
				if (user_mode) begin
					illegal = 1;
				end
				else begin
					is_privilege = 1;
					exe_b_src = EXE_B_IMM;
					exe_alu_oper = EXE_ALU_ADD;
					ic_inv = 1;
					dc_inv = 1;
				end
			end
			default: begin
				unrecognized = 1;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst)
			is_delay_slot <= 0;
		else if (ctrl_en)
			is_delay_slot <= is_jump & ~is_delay_slot;
	end
	
endmodule
