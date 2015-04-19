`include "define.vh"


/**
 * Data Path for MIPS 5-stage pipelined CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module datapath (
	input wire clk,  // main clock
	// debug
	`ifdef DEBUG
	input wire [5:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	// control signals
	output reg [31:0] inst_data_ctrl,  // instruction
	output reg [31:0] data_rs_ctrl,  // data in register RS
	output reg [31:0] data_rt_ctrl,  // data in register RT
	input wire rs_used_ctrl,  // whether RS is used
	input wire rt_used_ctrl,  // whether RT is used
	input wire [1:0] pc_src_ctrl,  // how would PC change to next
	input wire imm_ext_ctrl,  // whether using sign extended to immediate data
	input wire exe_a_src_ctrl,  // data source of operand A for ALU
	input wire exe_b_src_ctrl,  // data source of operand B for ALU
	input wire [3:0] exe_alu_oper_ctrl,  // ALU operation type
	input wire [1:0] exe_cp_oper_ctrl,  // co-processor operation type
	input wire exe_signed_ctrl,  // whether regard operands as signed data in ALU
	input wire [1:0] mem_type_ctrl,  // memory access type (word, half, byte)
	input wire mem_ext_ctrl,  // whether using sign extended to memory data
	input wire mem_ren_ctrl,  // memory read enable signal
	input wire mem_wen_ctrl,  // memory write enable signal
	input wire [1:0] wb_addr_src_ctrl,  // address source to write data back to registers
	input wire [1:0] wb_data_src_ctrl,  // data source of data being written back to registers
	input wire wb_wen_ctrl,  // register write enable signal
	input wire is_jump_ctrl,  // whether current instruction is a jump instruction
	// IF signals
	input wire if_rst,  // stage reset signal
	input wire if_en,  // stage enable signal
	output reg if_valid,  // working flag
	output reg inst_ren,  // instruction read enable signal
	output reg [31:0] inst_addr,  // address of instruction needed
	input wire [31:0] inst_data,  // instruction fetched
	// ID signals
	input wire id_rst,
	input wire id_en,
	output reg id_valid,
	output wire [4:0] cp_addr_r,  // address of co-processor register for data read
	input wire [31:0] cp_data_r,  // data read from co-processor's register
	output reg reg_stall,  // stall signal when LW instruction followed by an related R instruction
	// EXE signals
	input wire exe_rst,
	input wire exe_en,
	output reg exe_valid,
	output wire [1:0] cp_oper,  // co-processor operation type
	output wire [4:0] cp_addr_w,  // address of co-processor register for data write
	output wire [31:0] cp_data_w,  // data write to co-processor's register
	output wire math_overflow,  // math overflow exception
	output wire math_divide_zero,  // math divide by zero exception
	// MEM signals
	input wire mem_rst,
	input wire mem_en,
	output reg mem_valid,
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	output wire [1:0] mem_type,  // memory access type (word, half, byte)
	output wire mem_ext,  // whether using sign extended to memory data
	output wire [31:0] mem_addr,  // address of memory
	output wire [31:0] mem_dout,  // data writing to memory
	input wire [31:0] mem_din,  // data read from memory
	output reg [31:0] inst_addr_mem,  // instruction address in MEM stage
	output reg [31:0] inst_data_mem,  // instruction content in MEM stage
	// WB signals
	input wire wb_en,
	// exception
	input wire exception,  // exception occurred signal
	input wire [31:0] exception_target  // target instruction address when exception occurred
	);
	
	`include "mips_define.vh"
	
	// control signals
	reg [3:0] exe_alu_oper_exe;
	reg [1:0] exe_cp_oper_exe;
	reg exe_signed_exe;
	reg [1:0] mem_type_exe, mem_type_mem;
	reg mem_ext_exe, mem_ext_mem;
	reg mem_ren_exe, mem_ren_mem;
	reg mem_wen_exe, mem_wen_mem;
	reg [1:0] wb_data_src_exe, wb_data_src_mem, wb_data_src_wb;
	reg wb_wen_exe, wb_wen_mem;
	
	// IF signals
	wire [31:0] inst_addr_next;
	
	// ID signals
	reg [31:0] inst_addr_id;
	reg [31:0] inst_addr_next_id;
	reg [4:0] regw_addr_id;
	reg [31:0] opa_id, opb_id;
	wire [4:0] addr_rs, addr_rt;
	wire [31:0] data_rs, data_rt, data_imm;
	
	// EXE signals
	reg [31:0] inst_addr_exe;
	reg [31:0] inst_data_exe;
	reg [31:0] inst_addr_next_exe;
	reg [4:0] regw_addr_exe;
	reg [31:0] opa_exe, opb_exe, data_rt_exe;
	wire [31:0] alu_out_exe;
	
	// MEM signals
	reg [4:0] regw_addr_mem;
	reg [31:0] opa_mem, data_rt_mem;
	reg [31:0] alu_out_mem;
	
	// WB signals
	reg [31:0] regw_data;
	
	// debug
	`ifdef DEBUG
	wire [31:0] debug_data_reg;
	reg [31:0] debug_data_signal;
	
	always @(posedge clk) begin
		case (debug_addr[4:0])
			0: debug_data_signal <= inst_addr;
			1: debug_data_signal <= inst_data;
			2: debug_data_signal <= inst_addr_id;
			3: debug_data_signal <= inst_data_ctrl;
			4: debug_data_signal <= inst_addr_exe;
			5: debug_data_signal <= inst_data_exe;
			6: debug_data_signal <= inst_addr_mem;
			7: debug_data_signal <= inst_data_mem;
			8: debug_data_signal <= {19'b0, inst_ren, 7'b0, mem_ren, 3'b0, mem_wen};
			9: debug_data_signal <= mem_addr;
			10: debug_data_signal <= mem_din;
			11: debug_data_signal <= mem_dout;
			default: debug_data_signal <= 32'hFFFF_FFFF;
		endcase
	end
	
	assign
		debug_data = debug_addr[5] ? debug_data_signal : debug_data_reg;
	`endif
	
	// IF stage
	assign
		inst_addr_next = inst_addr + 4;
	
	always @(posedge clk) begin
		if (if_rst) begin
			if_valid <= 0;
			inst_ren <= 0;
			inst_addr <= 0;
		end
		else if (exception) begin
			if_valid <= 1;
			inst_ren <= 1;
			inst_addr <= exception_target;
		end
		else if (if_en) begin
			if_valid <= 1;
			inst_ren <= 1;
			case (pc_src_ctrl)
				PC_NEXT: inst_addr <= inst_addr_next;
				PC_JUMP: inst_addr <= {inst_addr_id[31:28], inst_data_ctrl[25:0], 2'b0};
				PC_JR: inst_addr <= opa_id;
				PC_BRANCH: inst_addr <= inst_addr_next_id + data_imm;
				default: inst_addr <= 0;
			endcase
		end
	end
	
	// ID stage
	always @(posedge clk) begin
		if (id_rst) begin
			id_valid <= 0;
			inst_addr_id <= 0;
			inst_data_ctrl <= 0;
			inst_addr_next_id <= 0;
		end
		else if (id_en) begin
			id_valid <= if_valid;
			inst_addr_id <= inst_addr;
			inst_data_ctrl <= inst_data;
			inst_addr_next_id <= inst_addr_next;
		end
	end
	
	assign
		addr_rs = inst_data_ctrl[25:21],
		addr_rt = inst_data_ctrl[20:16],
		data_imm = is_jump_ctrl ? {{14{inst_data_ctrl[15]}}, inst_data_ctrl[15:0], 2'b0} : (imm_ext_ctrl ? {{16{inst_data_ctrl[15]}}, inst_data_ctrl[15:0]} : {16'b0, inst_data_ctrl[15:0]});
	
	always @(*) begin
		regw_addr_id = inst_data_ctrl[15:11];
		case (wb_addr_src_ctrl)
			WB_ADDR_RD: regw_addr_id = inst_data_ctrl[15:11];
			WB_ADDR_RT: regw_addr_id = inst_data_ctrl[20:16];
			WB_ADDR_LINK: regw_addr_id = GPR_RA;
		endcase
	end
	
	regfile #(
		.ADDR_BITS(5),
		.DATA_BITS(32)
		) REGFILE (
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr[4:0]),
		.debug_data(debug_data_reg),
		`endif
		.addr_a(addr_rs),
		.data_a(data_rs),
		.addr_b(addr_rt),
		.data_b(data_rt),
		.en_w(wb_wen_mem & wb_en),
		.addr_w(regw_addr_mem),
		.data_w(regw_data)
		);
	
	always @(*) begin  // use forwarding to reduce stall frequency
		data_rs_ctrl = data_rs;
		data_rt_ctrl = data_rt;
		reg_stall = 0;
		if (rs_used_ctrl && addr_rs != 0) begin
			if (regw_addr_exe == addr_rs && wb_wen_exe) begin
				case (wb_data_src_exe)
					WB_DATA_ALU: data_rs_ctrl = alu_out_exe;
					WB_DATA_MEM: reg_stall = 1;
					WB_DATA_LINK: data_rs_ctrl = inst_addr_next_id;
					WB_DATA_REGA: data_rs_ctrl = opa_exe;
				endcase
			end
			else if (regw_addr_mem == addr_rs && wb_wen_mem) begin
				case (wb_data_src_mem)
					WB_DATA_ALU: data_rs_ctrl = alu_out_mem;
					WB_DATA_MEM: data_rs_ctrl = mem_din;
					WB_DATA_LINK: data_rs_ctrl = inst_addr_next_exe;
					WB_DATA_REGA: data_rs_ctrl = opa_mem;
				endcase
			end
		end
		if (rt_used_ctrl && addr_rt != 0) begin
			if (regw_addr_exe == addr_rt && wb_wen_exe) begin
				case (wb_data_src_exe)
					WB_DATA_ALU: data_rt_ctrl = alu_out_exe;
					WB_DATA_MEM: reg_stall = 1;
					WB_DATA_LINK: data_rt_ctrl = inst_addr_next_id;
					WB_DATA_REGA: data_rt_ctrl = opa_exe;
				endcase
			end
			else if (regw_addr_mem == addr_rt && wb_wen_mem) begin
				case (wb_data_src_mem)
					WB_DATA_ALU: data_rt_ctrl = alu_out_mem;
					WB_DATA_MEM: data_rt_ctrl = mem_din;
					WB_DATA_LINK: data_rt_ctrl = inst_addr_next_exe;
					WB_DATA_REGA: data_rt_ctrl = opa_mem;
				endcase
			end
		end
	end
	
	assign
		cp_addr_r = inst_data_ctrl[15:11];
	
	always @(*) begin
		opa_id = data_rs_ctrl;
		opb_id = data_rt_ctrl;
		case (exe_a_src_ctrl)
			EXE_A_RS: opa_id = data_rs_ctrl;
			EXE_A_CP: opa_id = cp_data_r;
		endcase
		case (exe_b_src_ctrl)
			EXE_B_RT: opb_id = data_rt_ctrl;
			EXE_B_IMM: opb_id = data_imm;
		endcase
	end
	
	// EXE stage
	always @(posedge clk) begin
		if (exe_rst) begin
			exe_valid <= 0;
			inst_addr_exe <= 0;
			inst_data_exe <= 0;
			inst_addr_next_exe <= 0;
			regw_addr_exe <= 0;
			opa_exe <= 0;
			opb_exe <= 0;
			data_rt_exe <= 0;
			exe_alu_oper_exe <= 0;
			exe_cp_oper_exe <= 0;
			exe_signed_exe <= 0;
			mem_type_exe <= 0;
			mem_ext_exe <= 0;
			mem_ren_exe <= 0;
			mem_wen_exe <= 0;
			wb_data_src_exe <= 0;
			wb_wen_exe <= 0;
		end
		else if (exe_en) begin
			exe_valid <= id_valid;
			inst_addr_exe <= inst_addr_id;
			inst_data_exe <= inst_data_ctrl;
			inst_addr_next_exe <= inst_addr_next_id;
			regw_addr_exe <= regw_addr_id;
			opa_exe <= opa_id;
			opb_exe <= opb_id;
			data_rt_exe <= data_rt_ctrl;
			exe_alu_oper_exe <= exe_alu_oper_ctrl;
			exe_cp_oper_exe <= exe_cp_oper_ctrl;
			exe_signed_exe <= exe_signed_ctrl;
			mem_type_exe <= mem_type_ctrl;
			mem_ext_exe <= mem_ext_ctrl;
			mem_ren_exe <= mem_ren_ctrl;
			mem_wen_exe <= mem_wen_ctrl;
			wb_data_src_exe <= wb_data_src_ctrl;
			wb_wen_exe <= wb_wen_ctrl;
		end
	end
	
	assign
		cp_oper = exe_cp_oper_exe,
		cp_addr_w = inst_data_exe[15:11],
		cp_data_w = opb_exe;
	
	alu ALU (
		.inst(inst_data_exe),
		.a(opa_exe),
		.b(opb_exe),
		.sign(exe_signed_exe),
		.oper(exe_alu_oper_exe),
		.result(alu_out_exe),
		.overflow(math_overflow)
		);
	
	assign math_divide_zero = 0;
	
	// MEM stage
	always @(posedge clk) begin
		if (mem_rst) begin
			mem_valid <= 0;
			inst_addr_mem <= 0;
			inst_data_mem <= 0;
			regw_addr_mem <= 0;
			opa_mem <= 0;
			data_rt_mem <= 0;
			alu_out_mem <= 0;
			mem_type_mem <= 0;
			mem_ext_mem <= 0;
			mem_ren_mem <= 0;
			mem_wen_mem <= 0;
			wb_data_src_mem <= 0;
			wb_wen_mem <= 0;
		end
		else if (mem_en) begin
			mem_valid <= exe_valid;
			inst_addr_mem <= inst_addr_exe;
			inst_data_mem <= inst_data_exe;
			regw_addr_mem <= regw_addr_exe;
			opa_mem <= opa_exe;
			data_rt_mem <= data_rt_exe;
			alu_out_mem <= alu_out_exe;
			mem_type_mem <= mem_type_exe;
			mem_ext_mem <= mem_ext_exe;
			mem_ren_mem <= mem_ren_exe;
			mem_wen_mem <= mem_wen_exe;
			wb_data_src_mem <= wb_data_src_exe;
			wb_wen_mem <= wb_wen_exe;
		end
	end
	
	assign
		mem_ren = mem_ren_mem,
		mem_wen = mem_wen_mem,
		mem_type = mem_type_mem,
		mem_ext = mem_ext_mem,
		mem_addr = alu_out_mem,
		mem_dout = data_rt_mem;
	
	// WB stage
	always @(*) begin
		regw_data = alu_out_mem;
		case (wb_data_src_mem)
			WB_DATA_ALU: regw_data = alu_out_mem;
			WB_DATA_MEM: regw_data = mem_din;
			WB_DATA_LINK: regw_data = inst_addr_next_exe;  // linked address is the next one of the delay slot
			WB_DATA_REGA: regw_data = opa_mem;
		endcase
	end
	
endmodule
