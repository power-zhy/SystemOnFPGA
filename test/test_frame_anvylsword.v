`include "define.vh"


module test_frame_anvylsword (
	// board
	input wire clk,  // on board clock, 100MHz
	input wire rst_n,  // reset button
	input wire [15:0] switch,
	input wire [3:0] btn_x,
	input wire [3:0] btn_y,
	output wire led_clk,
	output wire led_clr_n,
	output wire led_do,
	output wire seg_clk,
	output wire seg_clr_n,
	output wire seg_do,
	output wire tri_led0_r_n,
	output wire tri_led0_g_n,
	output wire tri_led0_b_n,
	output wire tri_led1_r_n,
	output wire tri_led1_g_n,
	output wire tri_led1_b_n,
	// SRAM
	output wire sram_ce_n,
	output wire sram_oe_n,
	output wire sram_we_n,
	output wire [19:0] sram_addr,
	inout wire [47:0] sram_data,
	// flash
	output wire [1:0] flash_ce_n,
	output wire flash_rst_n,
	output wire flash_oe_n,
	output wire flash_we_n,
	input wire [1:0] flash_ready,
	output wire [25:0] flash_addr,
	inout wire [31:0] flash_data,
	// VGA
	output wire vga_h_sync,
	output wire vga_v_sync,
	output wire [3:0] vga_red,
	output wire [3:0] vga_green,
	output wire [3:0] vga_blue,
	// keyboard
	inout wire keyboard_clk,
	inout wire keyboard_dat,
	// UART
	input wire uart_rx,
	output wire uart_tx
	);
	
	`include "function.vh"
	
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
		clk_dev = clk_50m;
	
	// anti-jitter
	wire [15:0] switch_buf;
	wire [3:0] btn_x_buf;
	wire [3:0] btn_y_buf;
	wire rst_buf;
	
	`ifndef SIMULATING
	anti_jitter #(.CLK_FREQ(CLK_FREQ_CPU), .JITTER_MAX(10000), .INIT_VALUE(0))
		AJ0 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[0]), .sig_o(switch_buf[0])),
		AJ1 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[1]), .sig_o(switch_buf[1])),
		AJ2 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[2]), .sig_o(switch_buf[2])),
		AJ3 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[3]), .sig_o(switch_buf[3])),
		AJ4 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[4]), .sig_o(switch_buf[4])),
		AJ5 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[5]), .sig_o(switch_buf[5])),
		AJ6 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[6]), .sig_o(switch_buf[6])),
		AJ7 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[7]), .sig_o(switch_buf[7])),
		AJ8 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[8]), .sig_o(switch_buf[8])),
		AJ9 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[9]), .sig_o(switch_buf[9])),
		AJ10 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[10]), .sig_o(switch_buf[10])),
		AJ11 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[11]), .sig_o(switch_buf[11])),
		AJ12 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[12]), .sig_o(switch_buf[12])),
		AJ13 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[13]), .sig_o(switch_buf[13])),
		AJ14 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[14]), .sig_o(switch_buf[14])),
		AJ15 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[15]), .sig_o(switch_buf[15])),
		AJX0 (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_x[0]), .sig_o(btn_x_buf[0])),
		AJX1 (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_x[1]), .sig_o(btn_x_buf[1])),
		AJX2 (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_x[2]), .sig_o(btn_x_buf[2])),
		AJX3 (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_x[3]), .sig_o(btn_x_buf[3])),
		AJY0 (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_y[0]), .sig_o(btn_y_buf[0])),
		AJY1 (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_y[1]), .sig_o(btn_y_buf[1])),
		AJY2 (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_y[2]), .sig_o(btn_y_buf[2])),
		AJY3 (.clk(clk_cpu), .rst(1'b0), .sig_i(btn_y[3]), .sig_o(btn_y_buf[3]));
	anti_jitter #(.CLK_FREQ(CLK_FREQ_CPU), .JITTER_MAX(10000), .INIT_VALUE(1))
		AJRST (.clk(clk_cpu), .rst(1'b0), .sig_i(~rst_n), .sig_o(rst_buf));
	`else
	assign
		switch_buf = switch,
		btn_x_buf = btn_x,
		btn_y_buf = btn_y,
		rst_buf = rst;
	`endif
	
	// clock generator
	wire locked;
	reg [15:0] rst_count = 16'hFFFF;
	
	clk_gen_anvylsword CLK_GEN (
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
	
	// display
	wire tri_led0_r;
	wire tri_led0_g;
	wire tri_led0_b;
	wire tri_led1_r;
	wire tri_led1_g;
	wire tri_led1_b;
	assign
		tri_led0_r_n = ~tri_led0_r,
		tri_led0_g_n = ~tri_led0_g,
		tri_led0_b_n = ~tri_led0_b,
		tri_led1_r_n = ~tri_led1_r,
		tri_led1_g_n = ~tri_led1_g,
		tri_led1_b_n = ~tri_led1_b;
	
	wire [31:0] disp_data;
	wire [7:0] disp_dot;
	wire [15:0] disp_led;
	board_disp_anvylsword #(
		.CLK_FREQ(CLK_FREQ_DEV)
		) BOARD_DISP_ANVYLSWORD (
		.clk(clk_dev),
		.rst(rst_all),
		.en({8{1'b1}}),
		.data(disp_data),
		.dot(disp_dot),
		.led(disp_led),
		.led_clk(led_clk),
		.led_clr_n(led_clr_n),
		.led_do(led_do),
		.seg_clk(seg_clk),
		.seg_clr_n(seg_clr_n),
		.seg_do(seg_do)
		);
	
	// inout pins
	wire [47:0] sram_din, sram_dout;
	assign
		sram_data = sram_we_n ? {48{1'bz}} : sram_dout,
		//sram_data = sram_oe_n ? sram_dout : {48{1'bz}},
		sram_din = sram_data;
	
	wire [31:0] flash_din, flash_dout;
	assign
		flash_data = flash_we_n ? {32{1'bz}} : flash_dout,
		//flash_data = flash_oe_n ? flash_dout : {32{1'bz}},
		flash_din = flash_data;
	
	/*
	// SRAM test
	test_sram_anvylsword #(
		.CLK_FREQ(CLK_FREQ_MEM),
		.ADDR_BITS(22)
		) TEST_SRAM (
		.clk(clk_mem),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(switch_buf[15]),
		.we(switch_buf[14]),
		.addr(switch_buf[7:0]),
		.data(disp_data),
		.state(disp_led[7:0]),
		.sram_ce_n(sram_ce_n),
		.sram_oe_n(sram_oe_n),
		.sram_we_n(sram_we_n),
		.sram_addr(sram_addr),
		.sram_din(sram_din),
		.sram_dout(sram_dout)
		);
	`define SRAM_SIG
	*/
	/*
	// FLASH test
	test_flash_anvylsword #(
		.CLK_FREQ(CLK_FREQ_MEM),
		.ADDR_BITS(25)
		) TEST_FLASH_ANVYLSWORD (
		.clk(clk_mem),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(switch_buf[15]),
		.we(switch_buf[14]),
		.addr(switch_buf[7:0]),
		.data(disp_data),
		.state(disp_led[7:0]),
		.flash_ce_n(flash_ce_n),
		.flash_rst_n(flash_rst_n),
		.flash_oe_n(flash_oe_n),
		.flash_we_n(flash_we_n),
		.flash_wp_n(),
		.flash_ready(flash_ready),
		.flash_addr(flash_addr),
		.flash_din(flash_din),
		.flash_dout(flash_dout)
		);
	`define FLASH_SIG
	*/
	/*
	// VGA test
	test_vga #(
		.CLK_FREQ(CLK_FREQ_DEV)
		) TEST_VGA (
		.clk(clk_dev),
		.clk_base(clk_25m),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(switch_buf[15]),
		.mode(switch_buf[7:0]),
		.data(disp_data),
		.state(disp_led[7:0]),
		.vga_h_sync(vga_h_sync),
		.vga_v_sync(vga_v_sync),
		.vga_red(vga_red[3:1]),
		.vga_green(vga_green[3:1]),
		.vga_blue(vga_blue[3:2])
		);
	assign
		vga_red[0] = 0,
		vga_green[0] = 0,
		vga_blue[1:0] = 0;
	`define VGA_SIG
	*/
	
	// KEYBOARD test
	test_ps2 #(
		.CLK_FREQ(CLK_FREQ_DEV)
		) TEST_PS2 (
		.clk(clk_dev),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(switch_buf[15]),
		.we(switch_buf[14]),
		.cmd(switch_buf[7:0]),
		.data(disp_data),
		.state(disp_led[7:0]),
		.ps2_clk(keyboard_clk),
		.ps2_dat(keyboard_dat)
		);
	`define KEYBOARD_SIG
	
	/*
	test_uart #(
		.CLK_FREQ(CLK_FREQ_DEV)
		) TEST_UART (
		.clk(clk_dev),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(switch_buf[15]),
		.we(switch_buf[14]),
		.din(switch_buf[7:0]),
		.data(disp_data),
		.state(disp_led[7:0]),
		.uart_rx(uart_rx),
		.uart_tx(uart_tx)
		);
	`define UART_SIG
	*/
	
	// default value for signals
	`ifndef VGA_SIG
	assign
		vga_h_sync = 0,
		vga_v_sync = 0,
		vga_red = 0,
		vga_green = 0,
		vga_blue = 0;
	`endif
	
	`ifndef SRAM_SIG
	assign
		sram_ce_n = 1,
		sram_oe_n = 1,
		sram_we_n = 1,
		sram_addr = 0,
		sram_dout = 0;
	`endif
	
	`ifndef FLASH_SIG
	assign
		flash_ce_n = 2'b11,
		flash_rst_n = 1,
		flash_oe_n = 1,
		flash_we_n = 1,
		flash_addr = 0,
		flash_dout = 0;
	`endif
	
	`ifndef KEYBOARD_SIG
	assign
		keyboard_clk = 1,
		keyboard_dat = 1;
	`endif
	
	`ifndef UART_SIG
	assign
		uart_tx = 1;
	`endif
	
endmodule
