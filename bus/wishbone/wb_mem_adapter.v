`include "define.vh"


/**
 * Wishbone - Memory adapter, deal with burst mode data exchange between two clock domains.
 * The memory's clock should be faster than the wishbone's, so that this adapter can be used to avoid duplicated operations to memory, otherwise this adapter is not needed.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_mem_adapter (
	input wire rst,  // synchronous reset
	output reg busy,  // busy flag indicating it is not ready for another request
	// wishbone slave interfaces
	input wire wbs_clk_i,
	input wire wbs_cyc_i,
	input wire wbs_stb_i,
	input wire [31:2] wbs_addr_i,
	input wire [2:0] wbs_cti_i,
	input wire [1:0] wbs_bte_i,
	input wire [3:0] wbs_sel_i,
	input wire wbs_we_i,
	input wire [31:0] wbs_data_i,
	output wire [31:0] wbs_data_o,
	output reg wbs_ack_o,
	output wire wbs_err_o,
	// memory interfaces
	input wire mem_clk,
	output reg mem_cs,
	output reg mem_we,
	output reg [ADDR_BITS-1:2] mem_addr,
	output reg [3:0] mem_sel,
	output reg mem_burst,
	output wire [31:0] mem_din,
	input wire [31:0] mem_dout,
	input wire mem_busy,
	input wire mem_ack
	);
	
	parameter
		ADDR_BITS = 24,  // address length for memory
		HIGH_ADDR = 8'h00,  // high address value, as the address length of wishbone is larger than device
		BUF_ADDR_BITS = 4;  // address length for buffer
	parameter
		BURST_CTI = 3'b010,
		BURST_BTE = 2'b00;
	
	wire wbs_cs, wbs_burst;
	assign
		wbs_cs = wbs_cyc_i & wbs_stb_i & wbs_addr_i[31:ADDR_BITS] == HIGH_ADDR,
		wbs_err_o = wbs_cyc_i & wbs_stb_i & wbs_addr_i[31:ADDR_BITS] != HIGH_ADDR,
		wbs_burst = (wbs_cti_i == BURST_CTI) & (wbs_bte_i == BURST_BTE) & (wbs_sel_i == 4'b1111);
	
	// buffer
	reg w_rst, r_rst;
	reg w_wen, w_ren, r_wen, r_ren;
	wire w_full, w_empty, w_near_empty;
	wire r_full, r_empty, r_near_full;
	
	reg [ADDR_BITS-1:2] addr_buf;
	reg [3:0] sel_buf;
	
	fifo_asy #(
		.DATA_BITS(32),
		.ADDR_BITS(BUF_ADDR_BITS)
		) FIFO_W (
		.rst(rst | w_rst),
		.clk_w(wbs_clk_i),
		.en_w(w_wen),
		.data_w(wbs_data_i),
		.full_w(w_full),
		.near_full_w(),
		.space_count(),
		.clk_r(mem_clk),
		.en_r(w_ren),
		.data_r(mem_din),
		.empty_r(w_empty),
		.near_empty_r(w_near_empty),
		.data_count()
		);
	
	fifo_asy #(
		.DATA_BITS(32),
		.ADDR_BITS(BUF_ADDR_BITS)
		) FIFO_R (
		.rst(rst | r_rst),
		.clk_w(mem_clk),
		.en_w(r_wen),
		.data_w(mem_dout),
		.full_w(r_full),
		.near_full_w(r_near_full),
		.space_count(),
		.clk_r(wbs_clk_i),
		.en_r(r_ren),
		.data_r(wbs_data_o),
		.empty_r(r_empty),
		.near_empty_r(),
		.data_count()
		);
	
	// control FSM
	localparam
		S_IDLE = 0,  // idle
		S_WRITE = 1,  // write data to memory
		S_WRITE_WAIT = 2,  // wishbone write request completed, write remaining data from FIFO_W to memory and wait for memory to be idle
		S_READ = 3,  // read data from memory
		S_READ_WAIT = 4;  // wishbone read request completed, wait for memory to be idle
	
	reg [2:0] state = 0;
	reg [2:0] next_state;
	
	always @(*) begin
		next_state = 0;
		case (state)
			S_IDLE: begin
				if (wbs_cs) begin
					if (wbs_we_i)
						next_state = S_WRITE;
					else
						next_state = S_READ;
				end
				else
					next_state = S_IDLE;
			end
			S_WRITE: begin
				if (wbs_cs && (wbs_burst || w_full))
					next_state = S_WRITE;
				else
					next_state = S_WRITE_WAIT;
			end
			S_WRITE_WAIT: begin
				if (w_empty && ~mem_busy)
					next_state = S_IDLE;
				else
					next_state = S_WRITE_WAIT;
			end
			S_READ: begin
				if (wbs_cs && (wbs_burst || r_empty))
					next_state = S_READ;
				else
					next_state = S_READ_WAIT;
			end
			S_READ_WAIT: begin
				if (~mem_busy)
					next_state = S_IDLE;
				else
					next_state = S_READ_WAIT;
			end
		endcase
	end
	
	always @(posedge wbs_clk_i) begin
		if (rst)
			state <= 0;
		else
			state <= next_state;
	end
	
	always @(posedge mem_clk) begin
		if (rst) begin
			addr_buf <= 0;
			sel_buf <= 0;
		end
		else case (state)
			S_IDLE: begin
				addr_buf <= wbs_addr_i[ADDR_BITS-1:2];  // load address
				sel_buf <= wbs_sel_i;
			end
			default: begin
				if (mem_ack)
					addr_buf <= addr_buf + 1'h1;
			end
		endcase
	end
	
	always @(*) begin
		busy = 0;
		w_rst = 0;
		r_rst = 0;
		w_wen = 0;
		w_ren = 0;
		r_wen = 0;
		r_ren = 0;
		wbs_ack_o = 0;
		mem_cs = 0;
		mem_we = 0;
		mem_addr = addr_buf;
		mem_sel = sel_buf;
		mem_burst = 0;
		case (state)
			S_IDLE: begin
				w_rst = 1;
				r_rst = 1;
			end
			S_WRITE: begin
				busy = 1;
				mem_we = 1;
				if (~w_full) begin
					w_wen = 1;
					wbs_ack_o = 1;
				end
				if (~w_empty) begin
					mem_cs = 1;
					mem_burst = ~w_near_empty;
				end
				w_ren = mem_ack;
			end
			S_WRITE_WAIT: begin
				busy = 1;
				mem_we = 1;
				if (~w_empty) begin
					mem_cs = 1;
					mem_burst = ~w_near_empty;
				end
				w_ren = mem_ack;
			end
			S_READ: begin
				busy = 1;
				if (~r_full) begin
					mem_cs = 1;  // start memory operation immediately, should make sure that address has already be loaded into addr_buf
					mem_burst = wbs_burst && ~r_near_full;
				end
				r_wen = mem_ack;
				if (~r_empty) begin
					wbs_ack_o = 1;
					r_ren = 1;
				end
			end
			S_READ_WAIT: begin
				busy = 1;
			end
		endcase
	end
	
endmodule
