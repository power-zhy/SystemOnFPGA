`include "define.vh"


/**
 * MIPS 5-stage pipeline CPU with wishbone connection interfaces.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_mips (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	input wire [6:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	// wishbone master interfaces for ICMU
	input wire icmu_clk_i,
	output wire icmu_cyc_o,
	output wire icmu_stb_o,
	output wire [31:2] icmu_addr_o,
	output wire [2:0] icmu_cti_o,
	output wire [1:0] icmu_bte_o,
	output wire [3:0] icmu_sel_o,
	output wire icmu_we_o,
	input wire [31:0] icmu_data_i,
	output wire [31:0] icmu_data_o,
	input wire icmu_ack_i,
	// wishbone master interfaces for DCMU
	input wire dcmu_clk_i,
	output wire dcmu_cyc_o,
	output wire dcmu_stb_o,
	output wire [31:2] dcmu_addr_o,
	output wire [2:0] dcmu_cti_o,
	output wire [1:0] dcmu_bte_o,
	output wire [3:0] dcmu_sel_o,
	output wire dcmu_we_o,
	input wire [31:0] dcmu_data_i,
	output wire [31:0] dcmu_data_o,
	input wire dcmu_ack_i,
	// interrupt interfaces
	input wire [30:1] ir_map,  // device interrupt signals
	output wire wd_rst  // watch dog reset, must not affect the global reset signal
	);
	
	`include "cpu_define.vh"
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz
	parameter
		PAGE_ADDR_BITS = 12;  // address length inside one memory page
	
	// MMU signals
	wire mmu_en, mmu_inv;
	wire [31:PAGE_ADDR_BITS] pdb_addr;
	
	// instruction signals
	wire inst_ren;
	wire immu_stall, icache_stall, inst_stall;
	wire [31:PAGE_ADDR_BITS] inst_addr_logical, inst_addr_physical;
	wire [PAGE_ADDR_BITS-1:0] inst_addr_page;
	wire [31:0] inst_data;
	wire inst_unalign, inst_page_fault;
	wire inst_unauth_user, inst_unauth_exec;
	wire ic_en, ic_lock;
	wire ic_inv;
	wire immu_ren;
	wire [31:0] immu_addr;
	wire immu_ack;
	wire [31:0] immu_data;
	
	// memory signals
	wire mem_ren, mem_wen;
	wire dmmu_stall, dcache_stall, mem_stall;
	wire [1:0] mem_type;
	wire mem_ext;
	wire [31:PAGE_ADDR_BITS] mem_addr_logical, mem_addr_physical;
	wire [PAGE_ADDR_BITS-1:0] mem_addr_page;
	wire [31:0] mem_data_r, mem_data_w;
	wire mem_unalign, mem_page_fault;
	wire mem_unauth_user, mem_unauth_write;
	wire dc_en, dc_lock;
	wire dc_inv;
	wire dmmu_ren;
	wire [31:0] dmmu_addr;
	wire dmmu_ack;
	wire [31:0] dmmu_data;
	
	wire exception;
	wire inst_auth_user, inst_auth_exec;
	wire mem_auth_user, mem_auth_write;
	
	// mips core
	assign
		inst_stall = immu_stall | icache_stall,
		mem_stall = dmmu_stall | dcache_stall;
	
	mips_core #(
		.CLK_FREQ(CLK_FREQ),
		.PAGE_ADDR_BITS(PAGE_ADDR_BITS)
		) MIPS_CORE (
		.clk(clk),
		.rst(rst),
		`ifdef DEBUG
		.debug_en(debug_en),
		.debug_step(debug_step),
		.debug_addr(debug_addr),
		.debug_data(debug_data),
		`endif
		.mmu_en(mmu_en),
		.mmu_inv(mmu_inv),
		.pdb_addr(pdb_addr),
		.inst_ren(inst_ren),
		.inst_stall(inst_stall),
		.inst_addr({inst_addr_logical, inst_addr_page}),
		.inst_data(inst_data),
		.inst_unalign(inst_unalign),
		.inst_page_fault(inst_page_fault),
		.inst_unauth_user(inst_unauth_user),
		.inst_unauth_exec(inst_unauth_exec),
		.ic_lock(ic_lock),
		.ic_inv(ic_inv),
		.mem_ren(mem_ren),
		.mem_wen(mem_wen),
		.mem_stall(mem_stall),
		.mem_type(mem_type),
		.mem_ext(mem_ext),
		.mem_addr({mem_addr_logical, mem_addr_page}),
		.mem_dout(mem_data_w),
		.mem_din(mem_data_r),
		.mem_unalign(mem_unalign),
		.mem_page_fault(mem_page_fault),
		.mem_unauth_user(mem_unauth_user),
		.mem_unauth_write(mem_unauth_write),
		.dc_lock(dc_lock),
		.dc_inv(dc_inv),
		.ir_map(ir_map),
		.wd_rst(wd_rst),
		.exception(exception)
		);
	
	// instruction MMU
	mmu #(
		.PAGE_ADDR_BITS(PAGE_ADDR_BITS)
		) IMMU (
		.clk(clk),
		.rst(rst | wd_rst | mmu_inv),
		.en_mmu(mmu_en & inst_ren),
		.stall(immu_stall),
		.pdb_addr(pdb_addr),
		.logical(inst_addr_logical),
		.physical(inst_addr_physical),
		.page_fault(inst_page_fault),
		.auth_user(inst_auth_user),
		.auth_exec(inst_auth_exec),
		.auth_write(),
		.en_cache(ic_en),
		.ren(immu_ren),
		.addr(immu_addr),
		.ack(immu_ack),
		.data(immu_data)
		);
	
	assign
		inst_unauth_user = inst_ren & ~inst_auth_user,
		inst_unauth_exec = inst_ren & ~inst_auth_exec;
	
	// instruction cache
	/*wb_cmu #(
		.TAG_BITS(22),
		.LINE_WORDS(4)
		) ICMU (
		.clk(clk),
		.rst(rst | wd_rst),
		.suspend(exception | inst_page_fault | inst_unauth_user | inst_unauth_exec),
		.en_cache(ic_en),
		.addr_rw({inst_addr_physical, inst_addr_page}),
		.addr_type(MEM_TYPE_WORD),
		.sign_ext(1'b0),
		.en_r(inst_ren),
		.data_r(inst_data),
		.en_w(1'b0),
		.data_w(0),
		.en_f(ic_inv),
		.lock(ic_lock),
		.stall(icache_stall),
		.unalign(inst_unalign),
		.wbm_clk_i(icmu_clk_i),
		.wbm_cyc_o(icmu_cyc_o),
		.wbm_stb_o(icmu_stb_o),
		.wbm_addr_o(icmu_addr_o),
		.wbm_cti_o(icmu_cti_o),
		.wbm_bte_o(icmu_bte_o),
		.wbm_sel_o(icmu_sel_o),
		.wbm_we_o(icmu_we_o),
		.wbm_data_i(icmu_data_i),
		.wbm_data_o(icmu_data_o),
		.wbm_ack_i(icmu_ack_i)
		);*/
	
	wb_cpu_conn ICMU (
		.clk(clk),
		.rst(rst | wd_rst),
		.suspend(exception | inst_page_fault | inst_unauth_user | inst_unauth_exec),
		.addr_rw({inst_addr_physical, inst_addr_page}),
		.addr_type(MEM_TYPE_WORD),
		.sign_ext(1'b0),
		.en_r(inst_ren),
		.data_r(inst_data),
		.en_w(1'b0),
		.data_w(0),
		.lock(ic_lock),
		.stall(icache_stall),
		.unalign(inst_unalign),
		.wbm_clk_i(icmu_clk_i),
		.wbm_cyc_o(icmu_cyc_o),
		.wbm_stb_o(icmu_stb_o),
		.wbm_addr_o(icmu_addr_o),
		.wbm_cti_o(icmu_cti_o),
		.wbm_bte_o(icmu_bte_o),
		.wbm_sel_o(icmu_sel_o),
		.wbm_we_o(icmu_we_o),
		.wbm_data_i(icmu_data_i),
		.wbm_data_o(icmu_data_o),
		.wbm_ack_i(icmu_ack_i)
		);
	
	// data MMU
	mmu #(
		.PAGE_ADDR_BITS(PAGE_ADDR_BITS)
		) DMMU (
		.clk(clk),
		.rst(rst | wd_rst | mmu_inv),
		.en_mmu(mmu_en & (mem_ren | mem_wen)),
		.stall(dmmu_stall),
		.pdb_addr(pdb_addr),
		.logical(mem_addr_logical),
		.physical(mem_addr_physical),
		.page_fault(mem_page_fault),
		.auth_user(mem_auth_user),
		.auth_exec(),
		.auth_write(mem_auth_write),
		.en_cache(dc_en),
		.ren(dmmu_ren),
		.addr(dmmu_addr),
		.ack(dmmu_ack),
		.data(dmmu_data)
		);
	
	assign
		mem_unauth_user = (mem_ren | mem_wen) & ~mem_auth_user,
		mem_unauth_write = (mem_ren | mem_wen) & ~mem_auth_write;
	
	// data cache
	/*wb_cmu #(
		.TAG_BITS(22),
		.LINE_WORDS(4)
		) DCMU (
		.clk(clk),
		.rst(rst | wd_rst),
		.suspend(exception | mem_page_fault | mem_unauth_user | mem_unauth_write),
		.en_cache(dc_en),
		.addr_rw({mem_addr_physical, mem_addr_page}),
		.addr_type(mem_type),
		.sign_ext(mem_ext),
		.en_r(mem_ren),
		.data_r(mem_data_r),
		.en_w(mem_wen),
		.data_w(mem_data_w),
		.en_f(dc_inv),
		.lock(dc_lock),
		.stall(dcache_stall),
		.unalign(mem_unalign),
		.wbm_clk_i(dcmu_clk_i),
		.wbm_cyc_o(dcmu_cyc_o),
		.wbm_stb_o(dcmu_stb_o),
		.wbm_addr_o(dcmu_addr_o),
		.wbm_cti_o(dcmu_cti_o),
		.wbm_bte_o(dcmu_bte_o),
		.wbm_sel_o(dcmu_sel_o),
		.wbm_we_o(dcmu_we_o),
		.wbm_data_i(dcmu_data_i),
		.wbm_data_o(dcmu_data_o),
		.wbm_ack_i(dcmu_ack_i)
		);*/
	
	wb_cpu_conn DCMU (
		.clk(clk),
		.rst(rst | wd_rst),
		.suspend(exception | mem_page_fault | mem_unauth_user | mem_unauth_write),
		.addr_rw({mem_addr_physical, mem_addr_page}),
		.addr_type(mem_type),
		.sign_ext(mem_ext),
		.en_r(mem_ren),
		.data_r(mem_data_r),
		.en_w(mem_wen),
		.data_w(mem_data_w),
		.lock(dc_lock),
		.stall(dcache_stall),
		.unalign(mem_unalign),
		.wbm_clk_i(dcmu_clk_i),
		.wbm_cyc_o(dcmu_cyc_o),
		.wbm_stb_o(dcmu_stb_o),
		.wbm_addr_o(dcmu_addr_o),
		.wbm_cti_o(dcmu_cti_o),
		.wbm_bte_o(dcmu_bte_o),
		.wbm_sel_o(dcmu_sel_o),
		.wbm_we_o(dcmu_we_o),
		.wbm_data_i(dcmu_data_i),
		.wbm_data_o(dcmu_data_o),
		.wbm_ack_i(dcmu_ack_i)
		);
	
	// TODO
	
endmodule
