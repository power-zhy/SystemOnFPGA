`include "define.vh"


/**
 * Memory device with wishbone connection interfaces.
 * Used for Nexys3 board as it shares many signal lines for RAM and PCM.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_memory_nexys3 (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	// debug
	`ifdef DEBUG
	input wire [4:0] debug_addr,  // debug address
	output reg [31:0] debug_data,  // debug data
	`endif
	// wishbone slave - RAM
	input wire ram_clk_i,
	input wire ram_cyc_i,
	input wire ram_stb_i,
	input wire [31:2] ram_addr_i,
	input wire [2:0] ram_cti_i,
	input wire [1:0] ram_bte_i,
	input wire [3:0] ram_sel_i,
	input wire ram_we_i,
	input wire [31:0] ram_data_i,
	output wire [31:0] ram_data_o,
	output wire ram_ack_o,
	output wire ram_err_o,
	// wishbone slave - PCM
	input wire pcm_clk_i,
	input wire pcm_cyc_i,
	input wire pcm_stb_i,
	input wire [31:2] pcm_addr_i,
	input wire [2:0] pcm_cti_i,
	input wire [1:0] pcm_bte_i,
	input wire [3:0] pcm_sel_i,
	input wire pcm_we_i,
	input wire [31:0] pcm_data_i,
	output wire [31:0] pcm_data_o,
	output wire pcm_ack_o,
	output wire pcm_err_o,
	// memory interfaces
	output wire ram_ce_n,
	output wire ram_clk,
	output wire ram_adv_n,
	output wire ram_cre,
	output wire ram_lb_n,
	output wire ram_ub_n,
	input wire ram_wait,
	output wire pcm_ce_n,
	output wire pcm_rst_n,
	output reg mem_oe_n,
	output reg mem_we_n,
	output reg [ADDR_BITS-1:1] mem_addr,
	inout wire [15:0] mem_data
	);
	
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz
	parameter
		ADDR_BITS = 24,  // address length
		RAM_HIGH_ADDR = 8'h00,  // high address value, as the address length of wishbone is larger than RAM
		PCM_HIGH_ADDR = 8'hFF,  // high address value, as the address length of wishbone is larger than PCM
		BUF_ADDR_BITS = 4;  // address length for buffer
	
	// RAM
	wire ram_busy;
	reg ram_en;
	wire ram_oe_n, ram_we_n;
	wire [ADDR_BITS-1:1] ram_addr;
	wire [15:0] ram_din, ram_dout;
	
	wb_psram_nexys3 #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(RAM_HIGH_ADDR),
		.BUF_ADDR_BITS(BUF_ADDR_BITS)
		) WB_PSRAM (
		.clk(clk),
		.rst(rst),
		.ram_busy(ram_busy),
		.ram_clk(ram_clk),
		.ram_ce_n(ram_ce_n),
		.ram_oe_n(ram_oe_n),
		.ram_we_n(ram_we_n),
		.ram_adv_n(ram_adv_n),
		.ram_cre(ram_cre),
		.ram_lb_n(ram_lb_n),
		.ram_ub_n(ram_ub_n),
		.ram_wait(ram_wait),
		.ram_addr(ram_addr),
		.ram_din(ram_din),
		.ram_dout(ram_dout),
		.wbs_clk_i(ram_clk_i),
		.wbs_cyc_i(ram_en ? ram_cyc_i : 1'b0),
		.wbs_stb_i(ram_en ? ram_stb_i : 1'b0),
		.wbs_addr_i(ram_addr_i),
		.wbs_cti_i(ram_cti_i),
		.wbs_bte_i(ram_bte_i),
		.wbs_sel_i(ram_sel_i),
		.wbs_we_i(ram_we_i),
		.wbs_data_i(ram_data_i),
		.wbs_data_o(ram_data_o),
		.wbs_ack_o(ram_ack_o),
		.wbs_err_o(ram_err_o)
		);
	
	// PCM
	wire pcm_busy;
	reg pcm_en;
	wire pcm_oe_n, pcm_we_n;
	wire [ADDR_BITS-1:1] pcm_addr;
	wire [15:0] pcm_din, pcm_dout;
	
	wb_ppcm_nexys3 #(
		.CLK_FREQ(CLK_FREQ),
		.ADDR_BITS(ADDR_BITS),
		.HIGH_ADDR(PCM_HIGH_ADDR),
		.BUF_ADDR_BITS(BUF_ADDR_BITS)
		) WB_PPCM (
		.clk(clk),
		.rst(rst),
		.pcm_busy(pcm_busy),
		.pcm_ce_n(pcm_ce_n),
		.pcm_rst_n(pcm_rst_n),
		.pcm_oe_n(pcm_oe_n),
		.pcm_we_n(pcm_we_n),
		.pcm_addr(pcm_addr),
		.pcm_din(pcm_din),
		.pcm_dout(pcm_dout),
		.wbs_clk_i(pcm_clk_i),
		.wbs_cyc_i(pcm_en ? pcm_cyc_i : 1'b0),
		.wbs_stb_i(pcm_en ? pcm_stb_i : 1'b0),
		.wbs_addr_i(pcm_addr_i),
		.wbs_cti_i(pcm_cti_i),
		.wbs_bte_i(pcm_bte_i),
		.wbs_sel_i(pcm_sel_i),
		.wbs_we_i(pcm_we_i),
		.wbs_data_i(pcm_data_i),
		.wbs_data_o(pcm_data_o),
		.wbs_ack_o(pcm_ack_o),
		.wbs_err_o(pcm_err_o)
		);
	
	// control
	reg curr = 0, next = 0;
	reg working = 0;
	
	always @(*) begin
		if (ram_cyc_i)
			next = 0;
		else if (pcm_cyc_i)
			next = 1;
		else
			next = 0;
	end
	
	always @(posedge clk) begin
		if (rst) begin
			curr <= 0;
			working <= 0;
		end
		else if (~ram_busy && ~pcm_busy) begin
			curr <= next;
			working <= ram_cyc_i | pcm_cyc_i;
		end
	end
	
	always @(*) begin
		if (working) begin
			ram_en = ~curr;
			pcm_en = curr;
		end
		else begin
			ram_en = ~next;
			pcm_en = next;
		end
	end
	
	// data output
	reg [15:0] mem_dout;
	
	always @(*) begin
		if (ram_busy) begin
			mem_oe_n = ram_oe_n;
			mem_we_n = ram_we_n;
			mem_addr = ram_addr;
			mem_dout = ram_dout;
		end
		else if (pcm_busy) begin
			mem_oe_n = pcm_oe_n;
			mem_we_n = pcm_we_n;
			mem_addr = pcm_addr;
			mem_dout = pcm_dout;
		end
		else begin
			mem_oe_n = 1;
			mem_we_n = 1;
			mem_addr = 0;
			mem_dout = 0;
		end
	end
	
	assign
		ram_din = ram_oe_n ? 16'h0 : mem_data,
		pcm_din = pcm_oe_n ? 16'h0 : mem_data,
		mem_data = mem_oe_n ? mem_dout : 16'hZZZZ;
	
	// debug
	`ifdef DEBUG
	always @(posedge clk) begin
		case (debug_addr)
			0: debug_data <= {3'b0, ram_busy, 7'b0, ram_cyc_i, 3'b0, ram_en, 3'b0, pcm_busy, 7'b0, pcm_cyc_i, 3'b0, pcm_en};
			1: debug_data <= {ram_addr_i, 2'b0};
			2: debug_data <= ram_data_o;
			3: debug_data <= ram_data_i;
			4: debug_data <= {19'b0, curr, 3'b0, next, 7'b0, working};
			5: debug_data <= {pcm_addr_i, 2'b0};
			6: debug_data <= pcm_data_o;
			7: debug_data <= pcm_data_i;
			8: debug_data <= {31'b0, ram_wait};
			default: debug_data <= 32'hFFFF_FFFF;
		endcase
	end
	`endif
	
endmodule
