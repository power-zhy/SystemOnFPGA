`include "define.vh"


/**
 * System On FPGA, top module for Nexys3 board.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module SystemOnFPGA_Nexys3 (
	// board
	input wire clk,  // on board clock, 100MHz
	input wire rst,  // reset button
	input wire [7:0] switch,  // switches
	output wire [7:0] led,  // LEDs
	input wire btn_l,  // left button
	input wire btn_r,  // right button
	input wire btn_u,  // up button
	input wire btn_d,  // down button
	output wire [7:0] segment,  // segment for 7-segment display tube
	output wire [3:0] anode,  // anode for 7-segment display tube
	// memory
	output wire ram_ce_n,
	output wire ram_clk,
	output wire ram_adv_n,
	output wire ram_cre,
	output wire ram_lb_n,
	output wire ram_ub_n,
	input wire ram_wait,
	output wire pcm_ce_n,
	output wire pcm_rst_n,
	output wire mem_oe_n,
	output wire mem_we_n,
	output wire [23:1] mem_addr,
	inout wire [15:0] mem_data,
	// VGA
	output wire vga_h_sync,
	output wire vga_v_sync,
	output wire [2:0] vga_red,
	output wire [2:0] vga_green,
	output wire [2:1] vga_blue,
	// keyboard
	inout wire keyboard_clk,
	inout wire keyboard_dat,
	// SPI
	output wire spi_sck,
	output wire spi_mosi,
	input wire spi_miso,
	output wire spi_sel_sd,
	// UART
	input wire uart_rx,
	output wire uart_tx
	);
	
	// defines
	// uncomment below lines when corresponding devices are not used
	//`define NO_MEMORY
	//`define NO_DEVICE
	//`define NO_VGA
	//`define NO_BOARD
	//`define NO_KEYBOARD
	//`define NO_SPI
	//`define NO_UART
	//`define SIMULATING
	
	// clock & reset
	wire clk_100m, clk_50m, clk_25m, clk_10m;
	wire clk_sys, clk_bus, clk_cpu, clk_mem, clk_dev;
	reg rst_all = 1;
	wire wd_rst;
	
	localparam
		CLK_FREQ_SYS = 100,
		CLK_FREQ_BUS = 10,
		CLK_FREQ_CPU = 10,
		CLK_FREQ_MEM = 50,
		CLK_FREQ_DEV = 50;
	assign
		clk_sys = clk_100m,
		clk_bus = clk_10m,
		clk_cpu = clk_10m,
		clk_mem = clk_50m,
		clk_dev = clk_50m;  // should be multiple of 10M, which UART needs
	
	// wishbone master - VRAM
	wire vram_cyc_o;
	wire vram_stb_o;
	wire [31:2] vram_addr_o;
	wire [2:0] vram_cti_o;
	wire [1:0] vram_bte_o;
	wire [3:0] vram_sel_o;
	wire vram_we_o;
	wire [31:0] vram_data_i;
	wire [31:0] vram_data_o;
	wire vram_ack_i;
	
	// wishbone master - ICMU
	wire icmu_cyc_o;
	wire icmu_stb_o;
	wire [31:2] icmu_addr_o;
	wire [2:0] icmu_cti_o;
	wire [1:0] icmu_bte_o;
	wire [3:0] icmu_sel_o;
	wire icmu_we_o;
	wire [31:0] icmu_data_i;
	wire [31:0] icmu_data_o;
	wire icmu_ack_i;
	
	// wishbone master - DCMU
	wire dcmu_cyc_o;
	wire dcmu_stb_o;
	wire [31:2] dcmu_addr_o;
	wire [2:0] dcmu_cti_o;
	wire [1:0] dcmu_bte_o;
	wire [3:0] dcmu_sel_o;
	wire dcmu_we_o;
	wire [31:0] dcmu_data_i;
	wire [31:0] dcmu_data_o;
	wire dcmu_ack_i;
	
	// wishbone slave - RAM
	wire ram_cyc_i;
	wire ram_stb_i;
	wire [31:2] ram_addr_i;
	wire [2:0] ram_cti_i;
	wire [1:0] ram_bte_i;
	wire [3:0] ram_sel_i;
	wire ram_we_i;
	wire [31:0] ram_data_o;
	wire [31:0] ram_data_i;
	wire ram_ack_o;
	
	// wishbone slave - ROM
	wire rom_cyc_i;
	wire rom_stb_i;
	wire [31:2] rom_addr_i;
	wire [2:0] rom_cti_i;
	wire [1:0] rom_bte_i;
	wire [3:0] rom_sel_i;
	wire rom_we_i;
	wire [31:0] rom_data_o;
	wire [31:0] rom_data_i;
	wire rom_ack_o;
	
	// wishbone slave - I/O devices
	wire dev_cyc_i;
	wire dev_stb_i;
	wire [31:2] dev_addr_i;
	wire [2:0] dev_cti_i;
	wire [1:0] dev_bte_i;
	wire [3:0] dev_sel_i;
	wire dev_we_i;
	wire [31:0] dev_data_o;
	wire [31:0] dev_data_i;
	wire dev_ack_o;
	
	// peripheral wishbone - VGA
	wire vga_cs_i;
	wire [7:2] vga_addr_i;
	wire [3:0] vga_sel_i;
	wire vga_we_i;
	wire [31:0] vga_data_o;
	wire [31:0] vga_data_i;
	wire vga_ack_o;
	
	// peripheral wishbone - board
	wire board_cs_i;
	wire [7:2] board_addr_i;
	wire [3:0] board_sel_i;
	wire board_we_i;
	wire [31:0] board_data_o;
	wire [31:0] board_data_i;
	wire board_ack_o;
	
	// peripheral wishbone - keyboard
	wire keyboard_cs_i;
	wire [7:2] keyboard_addr_i;
	wire [3:0] keyboard_sel_i;
	wire keyboard_we_i;
	wire [31:0] keyboard_data_o;
	wire [31:0] keyboard_data_i;
	wire keyboard_ack_o;
	
	// peripheral wishbone - SPI
	wire spi_cs_i;
	wire [7:2] spi_addr_i;
	wire [3:0] spi_sel_i;
	wire spi_we_i;
	wire [31:0] spi_data_o;
	wire [31:0] spi_data_i;
	wire spi_ack_o;
	
	// peripheral wishbone - UART
	wire uart_cs_i;
	wire [7:2] uart_addr_i;
	wire [3:0] uart_sel_i;
	wire uart_we_i;
	wire [31:0] uart_data_o;
	wire [31:0] uart_data_i;
	wire uart_ack_o;
	
	// anti-jitter
	wire [7:0] switch_buf;
	wire btn_l_buf, btn_r_buf, btn_u_buf, btn_d_buf, rst_buf;
	
	`ifndef SIMULATING
	anti_jitter #(.CLK_FREQ(CLK_FREQ_CPU), .JITTER_MAX(10000))
		AJ0 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[0]), .sig_o(switch_buf[0])),
		AJ1 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[1]), .sig_o(switch_buf[1])),
		AJ2 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[2]), .sig_o(switch_buf[2])),
		AJ3 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[3]), .sig_o(switch_buf[3])),
		AJ4 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[4]), .sig_o(switch_buf[4])),
		AJ5 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[5]), .sig_o(switch_buf[5])),
		AJ6 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[6]), .sig_o(switch_buf[6])),
		AJ7 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[7]), .sig_o(switch_buf[7])),
		AJL (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_l), .sig_o(btn_l_buf)),
		AJR (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_r), .sig_o(btn_r_buf)),
		AJU (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_u), .sig_o(btn_u_buf)),
		AJD (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_d), .sig_o(btn_d_buf)),
		AJRST (.clk(clk_cpu), .rst(1'b0), .sig_i(rst), .sig_o(rst_buf));
	`else
	assign
		switch_buf = switch,
		btn_l_buf = btn_l,
		btn_r_buf = btn_r,
		btn_u_buf = btn_u,
		btn_d_buf = btn_d,
		rst_buf = rst;
	`endif
	
	// clock generator
	wire locked;
	reg [15:0] rst_count = 16'hFFFF;
	
	clk_gen CLK_GEN (
		.clk_pad(clk),
		.clk_100m(clk_100m),
		.clk_50m(clk_50m),
		.clk_25m(clk_25m),
		.clk_10m(clk_10m),
		.locked(locked)
		);
	
	always @(posedge clk_cpu) begin
		rst_all <= (rst_count != 0);
		rst_count <= {rst_count[14:0], (rst_buf | (~locked))};
	end
	
	// interrupts
	wire ir_board, ir_keyboard, ir_spi, ir_uart;
	wire [30:1] ir_orig, ir_map;
	
	assign
		ir_orig = {24'b0, ir_uart, ir_spi, 1'b0, ir_keyboard, ir_board, 1'b0};
	
	ir_conv #(
		.INTERRUPT_NUMBER(30),
		.INTERRUPT_DELAY(CLK_FREQ_DEV / CLK_FREQ_CPU)
		) IR_CONV (
		.clk(clk_dev),
		.rst(1'b0),
		.ir_i(ir_orig),
		.ir_o(ir_map)
		);
	
	// debug
	`ifdef DEBUG
	wire debug_en;
	wire debug_step;
	wire [6:0] debug_addr;
	wire [31:0] debug_data_cpu, debug_data_mem;
	reg [31:0] debug_data;
	wire debug_disp_en;
	wire [7:0] debug_disp_led;
	wire [15:0] debug_disp_data;
	wire [3:0] debug_disp_dot;
	
	always @(*) begin
		case (debug_addr[6:5])
			0: debug_data = debug_data_cpu;  // GPR
			1: debug_data = debug_data_cpu;  // DATAPATH
			2: debug_data = debug_data_cpu;  // CP0
			3: debug_data = debug_data_mem;  // MEMORY
		endcase
	end
	
	assign
		debug_en = switch_buf[7],
		debug_step = btn_r_buf,
		debug_addr = switch_buf[6:0],
		debug_disp_en = debug_en ^ btn_u_buf,
		debug_disp_led = {1'b0, vram_cyc_o, icmu_cyc_o, dcmu_cyc_o, 1'b0, ram_cyc_i, rom_cyc_i, dev_cyc_i},
		debug_disp_data = btn_d_buf ? debug_data[31:16] : debug_data[15:0],
		debug_disp_dot = 4'b0;
	`endif
	
	// wishbone bus
	wb_arb WB_ARB (
		.wb_clk(clk_bus),
		.wb_rst(rst_all | wd_rst),
		.m0_cyc_i(vram_cyc_o),
		.m0_stb_i(vram_stb_o),
		.m0_addr_i(vram_addr_o),
		.m0_cti_i(vram_cti_o),
		.m0_bte_i(vram_bte_o),
		.m0_sel_i(vram_sel_o),
		.m0_we_i(vram_we_o),
		.m0_data_o(vram_data_i),
		.m0_data_i(vram_data_o),
		.m0_ack_o(vram_ack_i),
		.m1_cyc_i(icmu_cyc_o),
		.m1_stb_i(icmu_stb_o),
		.m1_addr_i(icmu_addr_o),
		.m1_cti_i(icmu_cti_o),
		.m1_bte_i(icmu_bte_o),
		.m1_sel_i(icmu_sel_o),
		.m1_we_i(icmu_we_o),
		.m1_data_o(icmu_data_i),
		.m1_data_i(icmu_data_o),
		.m1_ack_o(icmu_ack_i),
		.m2_cyc_i(dcmu_cyc_o),
		.m2_stb_i(dcmu_stb_o),
		.m2_addr_i(dcmu_addr_o),
		.m2_cti_i(dcmu_cti_o),
		.m2_bte_i(dcmu_bte_o),
		.m2_sel_i(dcmu_sel_o),
		.m2_we_i(dcmu_we_o),
		.m2_data_o(dcmu_data_i),
		.m2_data_i(dcmu_data_o),
		.m2_ack_o(dcmu_ack_i),
		.m3_cyc_i(1'b0),
		.m3_stb_i(1'b0),
		.m3_addr_i(),
		.m3_cti_i(),
		.m3_bte_i(),
		.m3_sel_i(),
		.m3_we_i(),
		.m3_data_o(),
		.m3_data_i(),
		.m3_ack_o(),
		.s0_cyc_o(ram_cyc_i),
		.s0_stb_o(ram_stb_i),
		.s0_addr_o(ram_addr_i),
		.s0_cti_o(ram_cti_i),
		.s0_bte_o(ram_bte_i),
		.s0_sel_o(ram_sel_i),
		.s0_we_o(ram_we_i),
		.s0_data_i(ram_data_o),
		.s0_data_o(ram_data_i),
		.s0_ack_i(ram_ack_o),
		.s1_cyc_o(rom_cyc_i),
		.s1_stb_o(rom_stb_i),
		.s1_addr_o(rom_addr_i),
		.s1_cti_o(rom_cti_i),
		.s1_bte_o(rom_bte_i),
		.s1_sel_o(rom_sel_i),
		.s1_we_o(rom_we_i),
		.s1_data_i(rom_data_o),
		.s1_data_o(rom_data_i),
		.s1_ack_i(rom_ack_o),
		.s2_cyc_o(dev_cyc_i),
		.s2_stb_o(dev_stb_i),
		.s2_addr_o(dev_addr_i),
		.s2_cti_o(dev_cti_i),
		.s2_bte_o(dev_bte_i),
		.s2_sel_o(dev_sel_i),
		.s2_we_o(dev_we_i),
		.s2_data_i(dev_data_o),
		.s2_data_o(dev_data_i),
		.s2_ack_i(dev_ack_o)
		);
	
	// CPU
	wb_mips #(
		.CLK_FREQ(CLK_FREQ_CPU),
		.IT_LINE_NUM(16),
		.DT_LINE_NUM(16),
		.IC_LINE_NUM(64),
		.DC_LINE_NUM(64)
		) WB_MIPS (
		.clk(clk_cpu),
		.rst(rst_all),
		`ifdef DEBUG
		.debug_en(debug_en),
		.debug_step(debug_step),
		.debug_addr(debug_addr),
		.debug_data(debug_data_cpu),
		`endif
		.icmu_clk_i(clk_bus),
		.icmu_cyc_o(icmu_cyc_o),
		.icmu_stb_o(icmu_stb_o),
		.icmu_addr_o(icmu_addr_o),
		.icmu_cti_o(icmu_cti_o),
		.icmu_bte_o(icmu_bte_o),
		.icmu_sel_o(icmu_sel_o),
		.icmu_we_o(icmu_we_o),
		.icmu_data_i(icmu_data_i),
		.icmu_data_o(icmu_data_o),
		.icmu_ack_i(icmu_ack_i),
		.dcmu_clk_i(clk_bus),
		.dcmu_cyc_o(dcmu_cyc_o),
		.dcmu_stb_o(dcmu_stb_o),
		.dcmu_addr_o(dcmu_addr_o),
		.dcmu_cti_o(dcmu_cti_o),
		.dcmu_bte_o(dcmu_bte_o),
		.dcmu_sel_o(dcmu_sel_o),
		.dcmu_we_o(dcmu_we_o),
		.dcmu_data_i(dcmu_data_i),
		.dcmu_data_o(dcmu_data_o),
		.dcmu_ack_i(dcmu_ack_i),
		.ir_map(ir_map),
		.wd_rst(wd_rst)
		);
	
	// memory (including RAM and ROM)
	`ifndef NO_MEMORY
	wb_memory #(
		.CLK_FREQ(CLK_FREQ_MEM),
		.ADDR_BITS(24),
		.RAM_HIGH_ADDR(8'h00),
		.PCM_HIGH_ADDR(8'hFF),
		.BUF_ADDR_BITS(4)
		) WB_MEMORY (
		.clk(clk_mem),
		.rst(1'b0),
		`ifdef DEBUG
		.debug_addr(debug_addr[4:0]),
		.debug_data(debug_data_mem),
		`endif
		.ram_clk_i(clk_bus),
		.ram_cyc_i(ram_cyc_i),
		.ram_stb_i(ram_stb_i),
		.ram_addr_i(ram_addr_i),
		.ram_cti_i(ram_cti_i),
		.ram_bte_i(ram_bte_i),
		.ram_sel_i(ram_sel_i),
		.ram_we_i(ram_we_i),
		.ram_data_i(ram_data_i),
		.ram_data_o(ram_data_o),
		.ram_ack_o(ram_ack_o),
		.pcm_clk_i(clk_bus),
		.pcm_cyc_i(rom_cyc_i),
		.pcm_stb_i(rom_stb_i),
		.pcm_addr_i(rom_addr_i),
		.pcm_cti_i(rom_cti_i),
		.pcm_bte_i(rom_bte_i),
		.pcm_sel_i(rom_sel_i),
		.pcm_we_i(rom_we_i),
		.pcm_data_i(rom_data_i),
		.pcm_data_o(rom_data_o),
		.pcm_ack_o(rom_ack_o),
		.ram_ce_n(ram_ce_n),
		.ram_clk(ram_clk),
		.ram_adv_n(ram_adv_n),
		.ram_cre(ram_cre),
		.ram_lb_n(ram_lb_n),
		.ram_ub_n(ram_ub_n),
		.ram_wait(ram_wait),
		.pcm_ce_n(pcm_ce_n),
		.pcm_rst_n(pcm_rst_n),
		.mem_oe_n(mem_oe_n),
		.mem_we_n(mem_we_n),
		.mem_addr(mem_addr),
		.mem_data(mem_data)
		);
	
	`else
	ram #(
		.ADDR_BITS(14),
		.HIGH_ADDR(18'h00000)
		) RAM (
		.wbs_clk_i(clk_bus),
		.wbs_cyc_i(ram_cyc_i),
		.wbs_stb_i(ram_stb_i),
		.wbs_addr_i(ram_addr_i),
		.wbs_cti_i(ram_cti_i),
		.wbs_bte_i(ram_bte_i),
		.wbs_sel_i(ram_sel_i),
		.wbs_we_i(ram_we_i),
		.wbs_data_i(ram_data_i),
		.wbs_data_o(ram_data_o),
		.wbs_ack_o(ram_ack_o)
		);
	
	rom #(
		.ADDR_BITS(12),
		.HIGH_ADDR(20'hFF000)
		) ROM (
		.wbs_clk_i(clk_bus),
		.wbs_cyc_i(rom_cyc_i),
		.wbs_stb_i(rom_stb_i),
		.wbs_addr_i(rom_addr_i),
		.wbs_cti_i(rom_cti_i),
		.wbs_bte_i(rom_bte_i),
		.wbs_sel_i(rom_sel_i),
		.wbs_we_i(rom_we_i),
		.wbs_data_i(rom_data_i),
		.wbs_data_o(rom_data_o),
		.wbs_ack_o(rom_ack_o)
		);
	
	assign
		ram_ce_n = 1,
		ram_clk = 0,
		ram_adv_n = 1,
		ram_cre = 0,
		ram_lb_n = 1,
		ram_ub_n = 1,
		pcm_ce_n = 1,
		pcm_rst_n = 1,
		mem_oe_n = 1,
		mem_we_n = 1,
		mem_addr = 0,
		mem_data = 0;
	
	`endif
	
	// I/O devices
	`ifndef NO_DEVICE
	localparam
		DEV_TOTAL_ADDR_BITS = 16,
		DEV_SINGAL_ADDR_BITS = 8;
	
	wb_dev_adapter #(
		.TOTAL_ADDR_BITS(DEV_TOTAL_ADDR_BITS),
		.SINGLE_ADDR_BITS(DEV_SINGAL_ADDR_BITS)
		) WB_DEV_ADAPTER (
		.wbs_cyc_i(dev_cyc_i),
		.wbs_stb_i(dev_stb_i),
		.wbs_addr_i(dev_addr_i[15:2]),
		.wbs_sel_i(dev_sel_i),
		.wbs_we_i(dev_we_i),
		.wbs_data_i(dev_data_i),
		.wbs_data_o(dev_data_o),
		.wbs_ack_o(dev_ack_o),
		.d0_cs_o(),
		.d0_addr_o(),
		.d0_sel_o(),
		.d0_we_o(),
		.d0_data_o(),
		.d0_data_i(),
		.d0_ack_i(),
		.d1_cs_o(vga_cs_i),
		.d1_addr_o(vga_addr_i),
		.d1_sel_o(vga_sel_i),
		.d1_we_o(vga_we_i),
		.d1_data_o(vga_data_i),
		.d1_data_i(vga_data_o),
		.d1_ack_i(vga_ack_o),
		.d2_cs_o(board_cs_i),
		.d2_addr_o(board_addr_i),
		.d2_sel_o(board_sel_i),
		.d2_we_o(board_we_i),
		.d2_data_o(board_data_i),
		.d2_data_i(board_data_o),
		.d2_ack_i(board_ack_o),
		.d3_cs_o(keyboard_cs_i),
		.d3_addr_o(keyboard_addr_i),
		.d3_sel_o(keyboard_sel_i),
		.d3_we_o(keyboard_we_i),
		.d3_data_o(keyboard_data_i),
		.d3_data_i(keyboard_data_o),
		.d3_ack_i(keyboard_ack_o),
		.d4_cs_o(),
		.d4_addr_o(),
		.d4_sel_o(),
		.d4_we_o(),
		.d4_data_o(),
		.d4_data_i(),
		.d4_ack_i(),
		.d5_cs_o(spi_cs_i),
		.d5_addr_o(spi_addr_i),
		.d5_sel_o(spi_sel_i),
		.d5_we_o(spi_we_i),
		.d5_data_o(spi_data_i),
		.d5_data_i(spi_data_o),
		.d5_ack_i(spi_ack_o),
		.d6_cs_o(uart_cs_i),
		.d6_addr_o(uart_addr_i),
		.d6_sel_o(uart_sel_i),
		.d6_we_o(uart_we_i),
		.d6_data_o(uart_data_i),
		.d6_data_i(uart_data_o),
		.d6_ack_i(uart_ack_o),
		.d7_cs_o(),
		.d7_addr_o(),
		.d7_sel_o(),
		.d7_we_o(),
		.d7_data_o(),
		.d7_data_i(),
		.d7_ack_i(),
		.d8_cs_o(),
		.d8_addr_o(),
		.d8_sel_o(),
		.d8_we_o(),
		.d8_data_o(),
		.d8_data_i(),
		.d8_ack_i(),
		.d9_cs_o(),
		.d9_addr_o(),
		.d9_sel_o(),
		.d9_we_o(),
		.d9_data_o(),
		.d9_data_i(),
		.d9_ack_i()
		);
	`else
	ram #(
		.ADDR_BITS(12),
		.HIGH_ADDR(20'hFFFF0)
		) DEV (
		.wbs_clk_i(clk_bus),
		.wbs_cyc_i(dev_cyc_i),
		.wbs_stb_i(dev_stb_i),
		.wbs_addr_i(dev_addr_i),
		.wbs_cti_i(dev_cti_i),
		.wbs_bte_i(dev_bte_i),
		.wbs_sel_i(dev_sel_i),
		.wbs_we_i(dev_we_i),
		.wbs_data_i(dev_data_i),
		.wbs_data_o(dev_data_o),
		.wbs_ack_o(dev_ack_o)
		);
		
		`define NO_VGA
		`define NO_BOARD
		`define NO_KEYBOARD
		`define NO_SPI
		`define NO_UART
	`endif
	
	`ifndef NO_VGA
	// VGA
	wb_vga #(
		.CLK_FREQ(CLK_FREQ_DEV),
		.DEV_ADDR_BITS(DEV_SINGAL_ADDR_BITS)
		) WB_VGA (
		.clk(clk_dev),
		.rst(1'b0),
		.clk_100m(clk_100m),
		.h_sync(vga_h_sync),
		.v_sync(vga_v_sync),
		.r_color(vga_red),
		.g_color(vga_green),
		.b_color(vga_blue),
		.wbm_clk_i(clk_bus),
		.wbm_cyc_o(vram_cyc_o),
		.wbm_stb_o(vram_stb_o),
		.wbm_addr_o(vram_addr_o),
		.wbm_cti_o(vram_cti_o),
		.wbm_bte_o(vram_bte_o),
		.wbm_sel_o(vram_sel_o),
		.wbm_we_o(vram_we_o),
		.wbm_data_i(vram_data_i),
		.wbm_data_o(vram_data_o),
		.wbm_ack_i(vram_ack_i),
		.wbs_clk_i(clk_bus),
		.wbs_cs_i(vga_cs_i),
		.wbs_addr_i(vga_addr_i),
		.wbs_sel_i(vga_sel_i),
		.wbs_data_i(vga_data_i),
		.wbs_we_i(vga_we_i),
		.wbs_data_o(vga_data_o),
		.wbs_ack_o(vga_ack_o)
		);
	`else
	assign
		vram_cyc_o = 0,
		vram_stb_o = 0,
		vga_h_sync = 0,
		vga_v_sync = 0,
		vga_red = 0,
		vga_green = 0,
		vga_blue = 0;
	`endif
	
	`ifndef NO_BOARD
	// board
	wb_board #(
		.DEV_ADDR_BITS(DEV_SINGAL_ADDR_BITS)
		) WB_BOARD (
		.clk(clk_dev),
		.rst(1'b0),
		.switch(switch_buf),
		.btn_l(btn_l_buf),
		.btn_r(btn_r_buf),
		.btn_u(btn_u_buf),
		.btn_d(btn_d_buf),
		.btn_s(1'b0),
		.led(led),
		.segment(segment),
		.anode(anode),
		.wbs_clk_i(clk_bus),
		.wbs_cs_i(board_cs_i),
		.wbs_addr_i(board_addr_i),
		.wbs_sel_i(board_sel_i),
		.wbs_data_i(board_data_i),
		.wbs_we_i(board_we_i),
		.wbs_data_o(board_data_o),
		.wbs_ack_o(board_ack_o),
		`ifdef DEBUG
		.debug_en(debug_disp_en),
		.debug_led(debug_disp_led),
		.debug_data(debug_disp_data),
		.debug_dot(debug_disp_dot),
		`endif
		.interrupt(ir_board)
		);
	`else
	wb_board WB_BOARD (
		.clk(clk_dev),
		.rst(1'b0),
		.switch(8'b0),
		.btn_l(1'b0),
		.btn_r(1'b0),
		.btn_u(1'b0),
		.btn_d(1'b0),
		.btn_s(1'b0),
		.led(led),
		.segment(segment),
		.anode(anode),
		.wbs_clk_i(),
		.wbs_cs_i(),
		.wbs_addr_i(),
		.wbs_sel_i(),
		.wbs_data_i(),
		.wbs_we_i(),
		.wbs_data_o(),
		.wbs_ack_o(),
		`ifdef DEBUG
		.debug_en(debug_disp_en),
		.debug_led(debug_disp_led),
		.debug_data(debug_disp_data),
		.debug_dot(debug_disp_dot),
		`endif
		.interrupt()
		);
		assign ir_board = 0;
	`endif
	
	`ifndef NO_KEYBOARD
	// keyboard
	wb_ps2 #(
		.CLK_FREQ(CLK_FREQ_DEV),
		.DEV_ADDR_BITS(DEV_SINGAL_ADDR_BITS)
		) WB_PS2 (
		.clk(clk_dev),
		.rst(1'b0),
		.ps2_clk(keyboard_clk),
		.ps2_dat(keyboard_dat),
		.wbs_clk_i(clk_bus),
		.wbs_cs_i(keyboard_cs_i),
		.wbs_addr_i(keyboard_addr_i),
		.wbs_sel_i(keyboard_sel_i),
		.wbs_data_i(keyboard_data_i),
		.wbs_we_i(keyboard_we_i),
		.wbs_data_o(keyboard_data_o),
		.wbs_ack_o(keyboard_ack_o),
		.interrupt(ir_keyboard)
		);
	`else
	assign
		keyboard_clk = 1,
		keyboard_dat = 1,
		ir_keyboard = 0;
	`endif
	
	`ifndef NO_SPI
	// SPI
	wire [15:1] spi_sel_tmp;
	
	wb_spi #(
		.CLK_FREQ(CLK_FREQ_DEV),
		.DEV_ADDR_BITS(DEV_SINGAL_ADDR_BITS),
		.BUF_ADDR_WIDTH(8)
		) WB_SPI (
		.clk(clk_dev),
		.rst(1'b0),
		.sck(spi_sck),
		.miso(spi_miso),
		.mosi(spi_mosi),
		.sel_n({spi_sel_tmp, spi_sel_sd}),
		.wbs_clk_i(clk_bus),
		.wbs_cs_i(spi_cs_i),
		.wbs_addr_i(spi_addr_i),
		.wbs_sel_i(spi_sel_i),
		.wbs_data_i(spi_data_i),
		.wbs_we_i(spi_we_i),
		.wbs_data_o(spi_data_o),
		.wbs_ack_o(spi_ack_o),
		.interrupt(ir_spi)
		);
	`else
	assign
		spi_sck = 0,
		spi_mosi = 1,
		spi_sel_sd = 0,
		ir_spi = 0;
	`endif
	
	`ifndef NO_UART
	// UART
	wb_uart #(
		.CLK_FREQ(CLK_FREQ_DEV),
		.DEV_ADDR_BITS(DEV_SINGAL_ADDR_BITS),
		.RX_BUF_ADDR_WIDTH(8),
		.TX_BUF_ADDR_WIDTH(8),
		.RX_IR_THRESHOLD(192),
		.RX_IR_TIMEOUT(100)
		) WB_UART (
		.clk(clk_dev),
		.rst(1'b0),
		.rx(uart_rx),
		.tx(uart_tx),
		.wbs_clk_i(clk_bus),
		.wbs_cs_i(uart_cs_i),
		.wbs_addr_i(uart_addr_i),
		.wbs_sel_i(uart_sel_i),
		.wbs_data_i(uart_data_i),
		.wbs_we_i(uart_we_i),
		.wbs_data_o(uart_data_o),
		.wbs_ack_o(uart_ack_o),
		.interrupt(ir_uart)
		);
	`else
	assign
		uart_tx = 1,
		ir_uart = 0;
	`endif
endmodule
