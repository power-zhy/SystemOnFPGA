`include "define.vh"


/**
 * Wishbone - CPU connector.
 * Should be replaced by CMU if cache is needed.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_cpu_conn (
	input wire clk,  // main clock, should be exactly the same as wishbone clock in current version
	input wire rst,  // synchronous reset
	input wire suspend,  // force suspend current process (i.e. exception occurred)
	input wire [31:0] addr_rw,  // address for data read or write
	input wire [1:0] addr_type,  // memory access type (word, half, byte)
	input wire sign_ext,  // whether to use sign extend or not for byte or half word reading
	input wire en_r,  // read enable signal
	output reg [31:0] data_r,  // data read out
	input wire en_w,  // write enable signal
	input wire [31:0] data_w,  // data write in
	input wire lock,  // keep current data to avoid process repeating
	output wire stall,  // stall other component when CMU is busy
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
	
	`include "cpu_define.vh"
	parameter
		STALL_HALF_DELAY = 1;  // delay the stall signal half clock to prevent close logic loop
	
	// alignment
	reg [3:0] sel_align;
	reg [31:0] data_align_r, data_align_w;
	
	always @(*)begin
		sel_align = 0;
		data_r = 0;
		data_align_w = 0;
		unalign = 0;
		if (~rst && (en_r | en_w)) case (addr_type[1:0])
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
		S_UNCACHE = 1,  // deal with data which do not go through cache
		S_UNCACHE_LOCK = 2;  // lock on current state to avoid read memory twice
	
	reg [1:0] state = 0;
	reg [1:0] next_state;
	
	always @(*) begin
		next_state = S_IDLE;
		if (~suspend) case (state)
			S_IDLE: begin
				if ((en_r || en_w) && ~unalign) begin
					next_state = S_UNCACHE;
				end
			end
			S_UNCACHE: begin
				if (wbm_ack_i)
					next_state = S_UNCACHE_LOCK;
				else
					next_state = S_UNCACHE;
			end
			S_UNCACHE_LOCK: begin
				if (lock)
					next_state = S_UNCACHE_LOCK;
				else
					next_state = S_IDLE;
			end
		endcase
	end
	
	always @(posedge wbm_clk_i) begin
		if (rst || suspend) begin
			state <= 0;
		end
		else begin
			state <= next_state;
		end
	end
	
	// memory control
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
			data_align_r <= 0;
		end
		else case (next_state)
			S_IDLE: begin
				data_align_r <= 0;
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
				if (wbm_cyc_o & wbm_ack_i)
					data_align_r <= wbm_data_i;
			end
		endcase
	end
	
	// stall
	reg stall_inner, stall_delay;
	
	always @(*) begin  // "stall" must be uttered before next positive clock edge, but using pure logic may lead to close logic loops
		stall_inner = 0;
		if (~suspend) case (next_state)
			S_IDLE: stall_inner = 0;
			S_UNCACHE: stall_inner = 1;
			S_UNCACHE_LOCK: stall_inner = wbm_cyc_o & wbm_ack_i;
		endcase
	end
	
	always @(negedge clk) begin
		if (rst || suspend)
			stall_delay <= 0;
		else
			stall_delay <= stall_inner;
	end
	
	assign
		stall = STALL_HALF_DELAY ? stall_delay : stall_inner;
	
endmodule
