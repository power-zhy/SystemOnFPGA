`include "define.vh"


/**
 * Cache management unit.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_cmu (
	input wire clk,  // main clock, should be exactly the same as wishbone clock in current version
	input wire rst,  // synchronous reset
	input wire suspend,  // force suspend current process
	input wire en_cache,  // whether using cache or access memory directly
	input wire [31:0] addr_rw,  // address for data read or write
	input wire [1:0] addr_type,  // memory access type (word, half, byte)
	input wire sign_ext,  // whether to use sign extend or not for byte or half word reading
	input wire en_r,  // read enable signal
	output reg [31:0] data_r,  // data read out
	input wire en_w,  // write enable signal
	input wire [31:0] data_w,  // data write in
	input wire en_f,  // flush enable signal
	input wire lock,  // keep current data to avoid process repeating
	output reg stall,  // stall other components when CMU is busy
	output reg unalign,  // address unaligned error
	// wishbone master interfaces
	input wire wbm_clk_i,
	output reg wbm_cyc_o,
	output reg wbm_stb_o,
	output reg [31:2] wbm_addr_o,
	output reg [2:0] wbm_cti_o,
	output reg [1:0] wbm_bte_o,
	output reg [3:0] wbm_sel_o,
	output reg wbm_we_o,
	input wire [31:0] wbm_data_i,
	output reg [31:0] wbm_data_o,
	input wire wbm_ack_i
	);
	
	`include "function.vh"
	`include "cpu_define.vh"
	parameter
		LINE_NUM = 64,  // number of lines in cache, must be the power of 2
		LINE_WORDS = 4;  // number of words per-line
	localparam
		LINE_WORDS_WIDTH = GET_WIDTH(LINE_WORDS-1),  // 2
		LINE_INDEX_WIDTH = GET_WIDTH(LINE_NUM-1),  // 6
		TAG_BITS = 32 - LINE_INDEX_WIDTH - LINE_WORDS_WIDTH - 2;  // 22
	
	// delay lock signal half a clock to prevent close logic loop
	reg lock_delay;
	always @(negedge clk) begin
		if (rst)
			lock_delay <= 0;
		else
			lock_delay <= lock;
	end
	
	// cache core
	reg cache_store;
	reg [3:0] cache_edit;
	reg cache_invalid;
	reg [31:0] cache_addr;
	reg [31:0] cache_din;
	wire [31:0] cache_dout;
	wire [TAG_BITS-1:0] cache_tag;
	wire cache_hit, cache_valid, cache_dirty;
	wire [LINE_NUM-1:0] cache_dirty_map;
	
	cache #(
		.ADDR_BITS(32),
		.WORD_BYTES(4),
		.LINE_WORDS(LINE_WORDS),
		.LINE_NUM(LINE_NUM)
		) CACHE (
		.clk(clk),
		.rst(rst),
		.addr(cache_addr),
		.store(cache_store),
		.edit(cache_edit),
		.invalid(cache_invalid),
		.din(cache_din),
		.hit(cache_hit),
		.dout(cache_dout),
		.valid(cache_valid),
		.dirty(cache_dirty),
		.tag(cache_tag),
		.dirty_map(cache_dirty_map)
		);
	
	wire need_flush;
	wire [LINE_INDEX_WIDTH-1:0] need_flush_addr;
	
	bit_searcher #(LINE_NUM) BS (
		.bits(cache_dirty_map),
		.target(1'b1),
		.direction(1'b1),
		.hit(need_flush),
		.index(need_flush_addr)
	);
	
	// alignment
	reg [3:0] sel_align;
	reg [31:0] data_align_r, data_align_w;
	
	always @(*)begin
		sel_align = 0;
		data_r = 0;
		data_align_w = 0;
		unalign = 0;
		if (en_r || en_w) case (addr_type[1:0])
			MEM_TYPE_WORD: case (addr_rw[1:0])
				2'b00: begin
					sel_align = 4'b1111;
					data_r = data_align_r;
					data_align_w = data_w;
				end
				default: begin
					unalign = 1;
				end
			endcase
			MEM_TYPE_HALF: case (addr_rw[1:0])
				2'b00: begin
					sel_align = 4'b0011;
					data_r = {{16{sign_ext & data_align_r[15]}}, data_align_r[15:0]};
					data_align_w = {16'b0, data_w[15:0]};
				end
				2'b10: begin
					sel_align = 4'b1100;
					data_r = {{16{sign_ext & data_align_r[31]}}, data_align_r[31:16]};
					data_align_w = {data_w[15:0], 16'b0};
				end
				default: begin
					unalign = 1;
				end
			endcase
			MEM_TYPE_BYTE: case (addr_rw[1:0])
				2'b00: begin
					sel_align = 4'b0001;
					data_r = {{24{sign_ext & data_align_r[7]}}, data_align_r[7:0]};
					data_align_w = {24'b0, data_w[7:0]};
				end
				2'b01: begin
					sel_align = 4'b0010;
					data_r = {{24{sign_ext & data_align_r[15]}}, data_align_r[15:8]};
					data_align_w = {16'b0, data_w[7:0], 8'b0};
				end
				2'b10: begin
					sel_align = 4'b0100;
					data_r = {{24{sign_ext & data_align_r[23]}}, data_align_r[23:16]};
					data_align_w = {8'b0, data_w[7:0], 16'b0};
				end
				2'b11: begin
					sel_align = 4'b1000;
					data_r = {{24{sign_ext & data_align_r[31]}}, data_align_r[31:24]};
					data_align_w = {data_w[7:0], 24'b0};
				end
			endcase
		endcase
	end
	
	// state machine
	localparam
		S_IDLE = 0,  // idle
		S_BACK = 1,  // write dirty data back to memory
		S_BACK_WAIT = 2,  // wait one clock to prepare new bus request
		S_FILL = 3,  // read data from memory
		S_FILL_WAIT = 4,  // wait one clock to prepare new bus request
		S_UNCACHE = 5,  // deal with data which do not go through cache
		S_UNCACHE_LOCK = 6,  // lock on current state to avoid read memory twice
		S_INVALID = 7,  // invalid all lines in cache, write dirty data back to memory
		S_INVALID_WAIT = 8;  // wait one clock to prepare new bus request
	
	reg [3:0] state = 0;
	reg [3:0] next_state;
	reg [LINE_WORDS_WIDTH-1:0] word_count = 0;
	reg [LINE_WORDS_WIDTH-1:0] next_word_count;
	
	always @(*) begin
		next_state = S_IDLE;
		next_word_count = 0;
		if (~suspend) case (state)
			S_IDLE: begin
				if (en_f) begin
					if (need_flush)
						next_state = S_INVALID;
				end
				else if ((en_r || en_w) && ~unalign) begin
					if (~en_cache)
						next_state = S_UNCACHE;
					else if (cache_hit)
						next_state = S_IDLE;
					else if (cache_valid && cache_dirty)
						next_state = S_BACK;
					else
						next_state = S_FILL;
				end
			end
			S_BACK: begin
				if (wbm_ack_i)
					next_word_count = word_count + 1'h1;
				else
					next_word_count = word_count;
				if (wbm_ack_i && word_count == {LINE_WORDS_WIDTH{1'b1}})
					next_state = S_BACK_WAIT;
				else
					next_state = S_BACK;
			end
			S_BACK_WAIT: begin
				next_word_count = 0;
				next_state = S_FILL;
			end
			S_FILL: begin
				if (wbm_ack_i)
					next_word_count = word_count + 1'h1;
				else
					next_word_count = word_count;
				if (wbm_ack_i && word_count == {LINE_WORDS_WIDTH{1'b1}})
					next_state = S_FILL_WAIT;
				else
					next_state = S_FILL;
			end
			S_FILL_WAIT: begin
				next_word_count = 0;
				next_state = S_IDLE;
			end
			S_UNCACHE: begin
				if (wbm_ack_i)
					next_state = S_UNCACHE_LOCK;
				else
					next_state = S_UNCACHE;
			end
			S_UNCACHE_LOCK: begin
				if (lock_delay)
					next_state = S_UNCACHE_LOCK;
				else
					next_state = S_IDLE;
			end
			S_INVALID: begin
				if (wbm_ack_i)
					next_word_count = word_count + 1'h1;
				else
					next_word_count = word_count;
				if (wbm_ack_i && word_count == {LINE_WORDS_WIDTH{1'b1}})
					next_state = S_INVALID_WAIT;
				else
					next_state = S_INVALID;
			end
			S_INVALID_WAIT: begin
				next_word_count = 0;
				if (need_flush)
					next_state = S_INVALID;
				else
					next_state = S_IDLE;
			end
		endcase
	end
	
	always @(posedge wbm_clk_i) begin
		if (rst || suspend) begin
			state <= 0;
			word_count <= 0;
		end
		else begin
			state <= next_state;
			word_count <= next_word_count;
		end
	end
	
	// cache control
	always @(*) begin
		cache_store = 0;
		cache_edit = 0;
		cache_invalid = 0;
		cache_addr = 0;
		cache_din = 0;
		if (~suspend) case (next_state)
			S_IDLE: begin
				cache_addr = addr_rw;
				cache_edit = en_w ? sel_align : 4'b0;
				cache_din = data_w;
			end
			S_BACK, S_BACK_WAIT: begin
				cache_addr = {addr_rw[31:LINE_WORDS_WIDTH+2], next_word_count, 2'b00};
			end
			S_FILL, S_FILL_WAIT: begin
				cache_addr = {addr_rw[31:LINE_WORDS_WIDTH+2], word_count, 2'b00};
				cache_din = wbm_data_i;
				cache_store = wbm_ack_i;
			end
			S_INVALID: begin
				cache_addr = {{TAG_BITS{1'b0}}, need_flush_addr, next_word_count, 2'b00};
			end
			S_INVALID_WAIT: begin
				cache_invalid = 1;
				cache_addr = {{TAG_BITS{1'b0}}, need_flush_addr, next_word_count, 2'b00};
			end
		endcase
	end
	
	// memory control
	reg [31:0] uncache_buf;
	
	always @(posedge wbm_clk_i) begin
		wbm_cyc_o <= 0;
		wbm_stb_o <= 0;
		wbm_cti_o <= 0;
		wbm_bte_o <= 0;
		wbm_we_o <= 0;
		wbm_sel_o <= 0;
		wbm_addr_o <= 0;
		wbm_data_o <= 0;
		if (rst || suspend) begin
			uncache_buf <= 0;
		end
		else case (next_state)
			S_IDLE, S_BACK_WAIT, S_FILL_WAIT, S_INVALID_WAIT: begin
				uncache_buf <= 0;
			end
			S_BACK: begin
				wbm_cyc_o <= 1;
				wbm_stb_o <= 1;
				if (next_word_count != {LINE_WORDS_WIDTH{1'b1}}) begin
					wbm_cti_o <= 3'b010;  // incrementing burst
					wbm_bte_o <= 2'b00;  // linear burst
				end
				else begin
					wbm_cti_o <= 3'b111;  // end of burst
					wbm_bte_o <= 0;
				end
				wbm_we_o <= 1;
				wbm_sel_o <= 4'b1111;
				wbm_addr_o <= {cache_tag, addr_rw[31-TAG_BITS:LINE_WORDS_WIDTH+2], next_word_count};
				wbm_data_o <= cache_dout;
			end
			S_FILL: begin
				wbm_cyc_o <= 1;
				wbm_stb_o <= 1;
				if (next_word_count != {LINE_WORDS_WIDTH{1'b1}}) begin
					wbm_cti_o <= 3'b010;  // incrementing burst
					wbm_bte_o <= 2'b00;  // linear burst
				end
				else begin
					wbm_cti_o <= 3'b111;  // end of burst
					wbm_bte_o <= 0;
				end
				wbm_we_o <= 0;
				wbm_sel_o <= 4'b1111;
				wbm_addr_o <= {addr_rw[31:LINE_WORDS_WIDTH+2], next_word_count};
			end
			S_UNCACHE: begin
				wbm_cyc_o <= 1;
				wbm_stb_o <= 1;
				wbm_we_o <= en_w;
				wbm_sel_o <= sel_align;
				wbm_addr_o <= addr_rw[31:2];
				wbm_data_o <= data_align_w;
			end
			S_UNCACHE_LOCK: begin
				if (wbm_cyc_o && wbm_ack_i)
					uncache_buf <= wbm_data_i;
			end
			S_INVALID: begin
				wbm_cyc_o <= 1;
				wbm_stb_o <= 1;
				if (next_word_count != {LINE_WORDS_WIDTH{1'b1}}) begin
					wbm_cti_o <= 3'b010;  // incrementing burst
					wbm_bte_o <= 2'b00;  // linear burst
				end
				else begin
					wbm_cti_o <= 3'b111;  // end of burst
					wbm_bte_o <= 0;
				end
				wbm_we_o <= 1;
				wbm_sel_o <= 4'b1111;
				wbm_addr_o <= {cache_tag, need_flush_addr, next_word_count};
				wbm_data_o <= cache_dout;
			end
		endcase
	end
	
	// outputs
	always @(*) begin
		data_align_r = 0;
		if (~suspend) case (state)
			S_IDLE, S_FILL_WAIT: data_align_r = cache_dout;
			S_UNCACHE_LOCK: data_align_r = uncache_buf;
		endcase
	end
	
	// stall
	always @(*) begin
		stall = 0;
		if (~suspend) case (next_state)
			S_IDLE: stall = 0;
			S_UNCACHE_LOCK: stall = wbm_cyc_o & wbm_ack_i;
			default: stall = 1;
		endcase
	end
	
endmodule
