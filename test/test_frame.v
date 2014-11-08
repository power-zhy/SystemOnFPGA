`include "define.vh"


module test_frame (
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
	//`define NO_LED
	`define NO_VGA
	//`define NO_MEMORY
	`define NO_PCM
	//`define NO_RAM
	`define NO_KEYBOARD
	`define NO_SPI
	`define NO_UART
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
		clk_dev = clk_50m;
	
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
	
	// display
	wire [15:0] disp_data;
	wire [3:0] disp_dot;
	seg_disp SEG_DISP (
		.clk(clk_sys),
		.rst(1'b0),
		.en(4'b1111),
		.data(disp_data),
		.dot(disp_dot),
		.segment(segment),
		.anode(anode)
		);
	
	// inout pins
	wire [15:0] mem_din, mem_dout;
	assign
		mem_data = mem_we_n ? {16{1'bz}} : mem_dout,
		//mem_data = mem_oe_n ? mem_dout : {16{1'bz}},
		mem_din = mem_data;
	
	// interface default value
	`ifdef NO_LED
	assign
		led = 0;
	`endif
	
	`ifdef NO_VGA
	assign
		vga_h_sync = 0,
		vga_v_sync = 0,
		vga_red = 0,
		vga_green = 0,
		vga_blue = 0;
	`endif
	
	`ifdef NO_MEMORY
	assign
		mem_oe_n = 1,
		mem_we_n = 1,
		mem_addr = 0,
		mem_dout = 0;
	`define NO_RAM
	`define NO_PCM
	`endif
	
	`ifdef NO_RAM
	assign
		ram_clk = 0,
		ram_ce_n = 1,
		ram_adv_n = 1,
		ram_cre = 0,
		ram_lb_n = 1,
		ram_ub_n = 1;
	`endif
	
	`ifdef NO_PCM
	assign
		pcm_ce_n = 1,
		pcm_rst_n = 1;
	`endif
	
	`ifdef NO_KEYBOARD
	assign
		keyboard_clk = 1,
		keyboard_dat = 1;
	`endif
	
	`ifdef NO_SPI
	assign
		spi_sck = 0,
		spi_mosi = 1,
		spi_sel_sd = 0;
	`endif
	
	`ifdef NO_UART
	assign
		uart_tx = 1;
	`endif
	
	// test body
	test_psram #(
		.CLK_FREQ(25)
		) TEST_PSRAM (
		.clk(clk_25m),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(btn_l_buf),
		.we(btn_r_buf),
		.high(btn_d_buf),
		.addr(switch_buf),
		.data(disp_data),
		.state(led),
		.ram_clk(ram_clk),
		.ram_ce_n(ram_ce_n),
		.ram_oe_n(mem_oe_n),
		.ram_we_n(mem_we_n),
		.ram_adv_n(ram_adv_n),
		.ram_cre(ram_cre),
		.ram_lb_n(ram_lb_n),
		.ram_ub_n(ram_ub_n),
		.ram_wait(ram_wait),
		.ram_addr(mem_addr),
		.ram_din(mem_din),
		.ram_dout(mem_dout)
	);
	
	/*test_ppcm #(
		.CLK_FREQ(25)
		) TEST_PPCM (
		.clk(clk_25m),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(btn_l_buf),
		.high(btn_d_buf),
		.addr(switch_buf),
		.data(disp_data),
		.state(led),
		.pcm_ce_n(pcm_ce_n),
		.pcm_rst_n(pcm_rst_n),
		.pcm_oe_n(mem_oe_n),
		.pcm_we_n(mem_we_n),
		.pcm_addr(mem_addr),
		.pcm_din(mem_din),
		.pcm_dout(mem_dout)
		);*/
	
	/*test_vga #(
		.CLK_FREQ(25)
		) TEST_VGA (
		.clk(clk_25m),
		.clk_100m(clk_100m),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(btn_l_buf),
		.high(btn_d_buf),
		.mode(switch_buf),
		.data(disp_data),
		.state(led),
		.vga_h_sync(vga_h_sync),
		.vga_v_sync(vga_v_sync),
		.vga_red(vga_red),
		.vga_green(vga_green),
		.vga_blue(vga_blue)
		);*/
	
	/*test_ps2 #(
		.CLK_FREQ(25)
		) TEST_PS2 (
		.clk(clk_25m),
		.clk_bus(clk_bus),
		.rst(rst_all),
		.cs(btn_l_buf),
		.we(btn_r_buf),
		.high(btn_d_buf),
		.cmd(switch_buf),
		.data(disp_data),
		.state(led),
		.ps2_clk(keyboard_clk),
		.ps2_dat(keyboard_dat)
		);*/
	
endmodule
