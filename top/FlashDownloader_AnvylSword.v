`include "define.vh"


/**
 * Flash Downloader for Nexys3 board.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module FlashDownloader_AnvylSword (
	input wire clk,  // on board clock, 100MHz
	input wire rst_n,  // reset button
	input wire [15:0] switch,
	// display
	output wire led_clk,
	output wire led_clr_n,
	output wire led_do,
	output wire seg_clk,
	output wire seg_clr_n,
	output wire seg_do,
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
		CLK_FREQ_MEM = 10,
		CLK_FREQ_DEV = 10;
	assign
		clk_sys = clk_100m,
		clk_bus = clk_10m,
		clk_cpu = clk_10m,
		clk_mem = clk_10m,
		clk_dev = clk_10m;
	
	wire clk_ctrl;
	assign
		clk_ctrl = clk_dev;
	
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
		AJ15 (.clk(clk_cpu), .rst(1'b0), .sig_i(switch[15]), .sig_o(switch_buf[15]));
	anti_jitter #(.CLK_FREQ(CLK_FREQ_CPU), .JITTER_MAX(10000), .INIT_VALUE(1))
		AJRST (.clk(clk_cpu), .rst(1'b0), .sig_i(~rst_n), .sig_o(rst_buf));
	`else
	assign
		switch_buf = switch,
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
	
	// SRAM
	reg s_cs, s_we;
	reg [21:2] s_addr;
	wire [31:0] s_read;
	reg [31:0] s_write;
	wire [31:0] sram_din, sram_dout;
	
	assign
		sram_data = sram_we_n ? {48{1'bz}} : {16'b0, sram_dout},
		//sram_data = sram_oe_n ? {16'b0, sram_dout} : {48{1'bz}},
		sram_din = sram_data[31:0];
	
	assign
		sram_ce_n = ~s_cs,
		sram_oe_n = s_we,
		sram_we_n = ~s_we,
		sram_addr = s_addr,
		s_read = sram_din,
		sram_dout = s_write;
	
	// flash
	reg f_cs, f_we;
	reg [24:2] f_addr;
	reg f_burst;
	wire f_busy, f_ack;
	wire [31:0] f_read;
	reg [31:0] f_write;
	wire [31:0] flash_din, flash_dout;
	
	assign
		flash_data = flash_we_n ? {32{1'bz}} : flash_dout,
		//flash_data = flash_oe_n ? flash_dout : {32{1'bz}},
		flash_din = flash_data;
	
	flash_core_program #(
		.CLK_FREQ(CLK_FREQ_MEM),
		.ADDR_BITS(24),
		.ADDR_BURST(4)
		) FLASH_CORE0 (
		.clk(clk_mem),
		.rst(rst_all),
		.cs(f_cs),
		.we(f_we),
		.addr(f_addr),
		.burst(f_burst),
		.din(f_write[15:0]),
		.dout(f_read[15:0]),
		.busy(f_busy),
		.ack(f_ack),
		.flash_ce_n(flash_ce_n[0]),
		.flash_rst_n(flash_rst_n),
		.flash_oe_n(flash_oe_n),
		.flash_we_n(flash_we_n),
		.flash_wp_n(flash_wp_n),
		.flash_ready(flash_ready[0] & flash_ready[1]),
		.flash_addr(flash_addr),
		.flash_din(flash_din[15:0]),
		.flash_dout(flash_dout[15:0])
		);
	
	flash_core_program #(
		.CLK_FREQ(CLK_FREQ_MEM),
		.ADDR_BITS(24),
		.ADDR_BURST(4)
		) FLASH_CORE1 (
		.clk(clk_mem),
		.rst(rst_all),
		.cs(f_cs),
		.we(f_we),
		.addr(f_addr),
		.burst(f_burst),
		.din(f_write[31:16]),
		.dout(f_read[31:16]),
		.busy(),
		.ack(),
		.flash_ce_n(flash_ce_n[1]),
		.flash_rst_n(),
		.flash_oe_n(),
		.flash_we_n(),
		.flash_wp_n(),
		.flash_ready(flash_ready[0] & flash_ready[1]),
		.flash_addr(),
		.flash_din(flash_din[31:16]),
		.flash_dout(flash_dout[31:16])
		);
	
	// UART
	reg tx_en;
	reg [31:0] tx_data;
	wire tx_ack;
	reg rx_en;
	wire [31:0] rx_data;
	wire rx_err, rx_ack;
	
	uart_tx_4byte #(
		.CLK_FREQ(CLK_FREQ_DEV)
		) UART_TX (
		.clk(clk_dev),
		.rst(rst_all),
		.en(tx_en),
		.data(tx_data),
		.busy(),
		.ack(tx_ack),
		.tx(uart_tx)
		);
	
	uart_rx_4byte #(
		.CLK_FREQ(CLK_FREQ_DEV)
		) UART_RX (
		.clk(clk_dev),
		.rst(rst_all),
		.en(rx_en),
		.data(rx_data),
		.busy(),
		.ack(rx_ack),
		.err(rx_err),
		.rx(uart_rx)
		);
	
	reg rx_error = 0;
	always @(posedge clk_ctrl) begin
		if (rst_all)
			rx_error <= 0;
		else if (rx_err)
			rx_error <= 1;
	end
	
	// controller
	reg [15:0] switch_pre;
	always @(posedge clk_ctrl) begin
		switch_pre <= switch_buf;
	end
	
	wire start;
	assign
		start = switch_buf[15] & ~switch_pre[15];
	
	/*reg [31:0] buffer = 0;
	reg work = 0;
	reg [7:0] status;
	assign
		disp_data = buffer,
		disp_dot = 0,
		disp_led = {work, 3'b0, uart_rx, uart_tx, 2'b0, status};
	
	reg rx_prev, tx_prev;
	always @(posedge clk_ctrl) begin
		if (rst_all) begin
			rx_prev <= 1;
			tx_prev <= 1;
		end
		else begin
			rx_prev <= uart_rx;
			tx_prev <= uart_tx;
		end
	end
	
	reg [5:0] rx_count, tx_count;
	always @(posedge clk_ctrl) begin
		if (rst_all || ~work) begin
			rx_count <= 0;
			tx_count <= 0;
		end
		else begin
			if (~rx_prev && uart_rx)
				rx_count <= rx_count + 1'h1;
			if (~tx_prev && uart_tx)
				tx_count <= tx_count + 1'h1;
		end
	end
	
	always @(posedge clk_ctrl) begin
		if (rst_all) begin
			buffer <= 32'h12345678;
			work <= 0;
			rx_en <= 0;
			tx_en <= 0;
			tx_data <= 0;
			s_cs <= 0;
			s_we <= 0;
			s_addr <= 0;
			s_write <= 0;
			f_cs <= 0;
			f_we <= 0;
			f_addr <= 0;
			f_burst <= 0;
			f_write <= 0;
			status <= 0;
		end
		else if (start && ~work) begin
			work <= 1;
			rx_en <= 0;
			tx_en <= 0;
			s_cs <= 0;
			f_cs <= 0;
			status <= 0;
		end
		else if (work) case (switch_buf[14:13])
			2'b00: begin  // UART_RX
				status <= {uart_rx, rx_error, rx_count};
				if (rx_ack) begin
					buffer <= rx_data;
					work <= 0;
					rx_en <= 0;
				end
				else begin
					rx_en <= 1;
				end
			end
			2'b01: begin  // UART_TX
				status <= {uart_tx, 1'b0, tx_count};
				if (tx_ack) begin
					work <= 0;
					tx_en <= 0;
					tx_data <= 0;
				end
				else begin
					tx_en <= 1;
					tx_data <= buffer;
				end
			end
			2'b10: begin  // SRAM
				status <= {s_cs, s_we, 6'b0};
				if (s_cs) begin
					buffer <= s_read;
					s_cs <= 0;
					s_we <= 0;
					s_addr <= 0;
					s_write <= 0;
					work <= 0;
				end
				else begin
					s_cs <= 1;
					s_we <= switch_buf[12];
					s_addr <= switch_buf[7:0];
					s_write <= buffer;
				end
			end
			2'b11: begin  // FLASH
				status <= {f_cs, f_we, f_burst, 3'b0, flash_ready};
				if (f_ack) begin
					buffer <= f_read;
					f_cs <= 0;
					f_we <= 0;
					f_addr <= 0;
					f_burst <= 0;
					f_write <= 0;
					work <= 0;
				end
				else begin
					f_cs <= 1;
					f_we <= switch_buf[12];
					f_addr <= switch_buf[7:0];
					f_burst <= 0;
					f_write <= buffer;
				end
			end
		endcase
	end*/
	
	localparam
		S_IDLE = 0,
		S_RX2S = 1,
		S_ERASE = 2,
		S_PROG1 = 3,
		S_PROG2 = 4,
		S_PROG3 = 5,
		S_PROG4 = 6,
		S_S2TX1 = 7,
		S_S2TX2 = 8;
	
	reg [3:0] state = 0;
	reg [3:0] next_state;
	
	reg [17:0] disp_count;
	reg [17:0] rx_count = 0;
	reg [17:0] tx_count = 0;
	reg [3:0] f_count = 0;
	
	reg [13:0] state_track = 0;
	always @(posedge clk_ctrl) begin
		if (rst_all)
			state_track <= 0;
		else
			state_track[state] <= 1;
	end
	
	assign
		disp_data = {state, 10'b0, disp_count},
		disp_dot = 0,
		disp_led = {flash_ready, state_track};
	
	always @(*) begin
		next_state = 0;
		disp_count = 0;
		case (state)
			S_IDLE: begin
				if (switch_buf[13] && ~switch_pre[13])
					next_state = S_S2TX1;
				else if (switch_buf[14] && ~switch_pre[14])
					next_state = S_ERASE;
				else if (switch_buf[15])
					next_state = S_RX2S;
				else
					next_state = S_IDLE;
			end
			S_RX2S: begin
				disp_count = rx_count;
				if (~switch_buf[15])
					next_state = S_PROG1;
				else
					next_state = S_RX2S;
			end
			S_ERASE: begin
				disp_count = f_count;
				if (f_ack && f_count == 5)
					next_state = S_IDLE;
				else
					next_state = S_ERASE;
			end
			S_PROG1: begin
				disp_count = f_count;
				if (f_ack && f_count == 3)
					next_state = S_PROG2;
				else
					next_state = S_PROG1;
			end
			S_PROG2: begin
				disp_count = tx_count;
				next_state = S_PROG3;
			end
			S_PROG3: begin
				disp_count = tx_count;
				if (f_ack && tx_count[7:0] == 0)
					next_state = S_PROG4;
				else if (f_ack)
					next_state = S_PROG2;
				else
					next_state = S_PROG3;
			end
			S_PROG4: begin
				if (tx_count >= rx_count)
					next_state = S_IDLE;
				else
					next_state = S_PROG1;
			end
			S_S2TX1: begin
				disp_count = tx_count;
				next_state = S_S2TX2;
			end
			S_S2TX2: begin
				disp_count = tx_count;
				if (tx_ack && tx_count == rx_count)
					next_state = S_IDLE;
				else if (tx_ack)
					next_state = S_S2TX1;
				else
					next_state = S_S2TX2;
			end
		endcase
	end
	
	always @(posedge clk_ctrl) begin
		if (rst_all) begin
			state <= 0;
		end
		else begin
			state <= next_state;
		end
	end
	
	always @(posedge clk_ctrl) begin
		rx_en <= 0;
		tx_en <= 0;
		s_cs <= 0;
		s_we <= 0;
		f_cs <= 0;
		f_we <= 0;
		f_burst <= 0;
		if (rst_all) begin
			rx_count <= 0;
			tx_count <= 0;
			f_count <= 0;
			tx_data <= 0;
			s_addr <= 0;
			s_write <= 0;
			f_addr <= 0;
			f_write <= 0;
		end
		else case (next_state)
			S_IDLE: begin
				rx_count <= 0;
				tx_count <= 0;
				f_count <= 0;
				tx_data <= 0;
				s_addr <= 0;
				s_write <= 0;
				f_addr <= 0;
				f_write <= 0;
			end
			S_RX2S: begin
				rx_en <= 1;
				s_cs <= rx_ack;
				s_we <= 1;
				s_addr <= rx_count;
				if (rx_ack) begin
					s_write <= rx_data;
					rx_count <= rx_count + 1'h1;
				end
			end
			S_ERASE: begin
				f_cs <= 1;
				f_we <= 1;
				case (f_count)
					0: begin
						f_addr <= 23'h555;
						f_write <= 32'hAA;
					end
					1: begin
						f_addr <= 23'h2AA;
						f_write <= 32'h55;
					end
					2: begin
						f_addr <= 23'h555;
						f_write <= 32'h80;
					end
					3: begin
						f_addr <= 23'h555;
						f_write <= 32'hAA;
					end
					4: begin
						f_addr <= 23'h2AA;
						f_write <= 32'h55;
					end
					5: begin
						f_addr <= 23'h555;
						f_write <= 32'h10;
					end
				endcase
				if (f_ack)
					f_count <= f_count + 1'h1;
			end
			S_PROG1: begin
				f_cs <= 1;
				f_we <= 1;
				case (f_count)
					0: begin
						f_addr <= 23'h555;
						f_write <= 32'hAA;
					end
					1: begin
						f_addr <= 23'h2AA;
						f_write <= 32'h55;
					end
					2: begin
						f_addr <= {switch_buf[4:0], tx_count};
						f_write <= 32'h25;
					end
					3: begin
						f_addr <= {switch_buf[4:0], tx_count};
						f_write <= 32'h100;
					end
				endcase
				if (f_ack)
					f_count <= f_count + 1'h1;
			end
			S_PROG2: begin
				f_count <= 0;
				s_cs <= 1;
				s_addr <= tx_count;
				tx_count <= tx_count + 1'h1;
			end
			S_PROG3: begin
				f_count <= 0;
				f_cs <= 1;
				f_we <= 1;
				f_addr <= {switch_buf[4:0], s_addr[19:2]};
				if (s_cs) begin
					f_write <= s_read;
				end
			end
			S_PROG4: begin
				f_count <= 0;
				f_cs <= 1;
				f_we <= 1;
				f_addr <= {switch_buf[4:0], s_addr[19:2]};
				f_write <= 32'h29;
			end
			S_S2TX1: begin
				s_cs <= 1;
				s_addr <= tx_count;
				tx_count <= tx_count + 1'h1;
			end
			S_S2TX2: begin
				tx_en <= 1;
				if (s_cs) begin
					tx_data <= s_read;
				end
			end
		endcase
	end
	
endmodule


module uart_tx_4byte (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire en,  // enable signal, flag to start transmitting
	input wire [31:0] data,  // data to send out
	output reg busy,  // busy flag
	output reg ack,  // data sent acknowledge
	// UART TX interface
	output wire tx
	);
	
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz, should be multiple of 10M
	
	reg tx_en;
	wire tx_ack;
	reg [31:0] buff;
	
	uart_core_tx #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_DIV_WIDTH(8)
		) UART_TX (
		.clk(clk),
		.rst(rst),
		.baud_div(8'h81),
		.data_type(2'b0),
		.stop_type(2'b0),
		.check_en(1'b0),
		.check_type(2'b0),
		.en(tx_en),
		.data(buff[7:0]),
		.busy(),
		.ack(tx_ack),
		.tx(tx)
		);
	
	localparam
		S_IDLE = 0,
		S_LOAD = 1,
		S_BYTE1 = 2,
		S_BYTE2 = 3,
		S_BYTE3 = 4,
		S_BYTE4 = 5,
		S_DONE = 6;
	
	reg [2:0] state = 0;
	reg [2:0] next_state;
	
	always @(*) begin
		tx_en = 0;
		next_state = 0;
		case (state)
			S_IDLE: begin
				if (en)
					next_state = S_LOAD;
				else
					next_state = S_IDLE;
			end
			S_LOAD: begin
				next_state = S_BYTE1;
			end
			S_BYTE1, S_BYTE2, S_BYTE3, S_BYTE4: begin
				tx_en = 1;
				if (tx_ack)
					next_state = state + 1'h1;
				else
					next_state = state;
			end
			S_DONE: begin
				next_state = S_IDLE;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst)
			state <= 0;
		else
			state <= next_state;
	end
	
	always @(posedge clk) begin
		busy <= 0;
		ack <= 0;
		if (~rst) case (next_state)
			S_IDLE: begin
				buff <= 0;
			end
			S_LOAD: begin
				busy <= 1;
				buff <= data;
			end
			S_BYTE1, S_BYTE2, S_BYTE3, S_BYTE4: begin
				busy <= 1;
				if (tx_ack)
					buff <= {8'b0, buff[31:8]};
			end
			S_DONE: begin
				ack <= 1;
			end
		endcase
	end
	
endmodule


module uart_rx_4byte (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire en,  // enable signal
	output reg [31:0] data,  // data received in
	output reg busy,  // busy flag
	output reg ack,  // data received acknowledge
	output reg err,  // data checking error
	// UART TX interface
	input wire rx
	);
	
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz, should be multiple of 10M
	
	reg rx_en;
	wire [7:0] rx_data;
	wire rx_err, rx_ack;
	
	uart_core_rx #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_DIV_WIDTH(8)
		) UART_RX (
		.clk(clk),
		.rst(rst),
		.baud_div(8'h81),
		.data_type(2'b0),
		.stop_type(2'b0),
		.check_en(1'b0),
		.check_type(2'b0),
		.en(rx_en),
		.data(rx_data),
		.busy(),
		.ack(rx_ack),
		.err(rx_err),
		.rx(rx)
		);
	
	localparam
		S_IDLE = 0,
		S_BYTE1 = 1,
		S_BYTE2 = 2,
		S_BYTE3 = 3,
		S_BYTE4 = 4,
		S_DONE = 5,
		S_ERROR = 6;
	
	reg [2:0] state = 0;
	reg [2:0] next_state;
	
	always @(*) begin
		rx_en = 0;
		next_state = 0;
		case (state)
			S_IDLE: begin
				if (en)
					next_state = S_BYTE1;
				else
					next_state = S_IDLE;
			end
			S_BYTE1, S_BYTE2, S_BYTE3, S_BYTE4: begin
				rx_en = 1;
				if (rx_err)
					next_state = S_ERROR;
				else if (rx_ack)
					next_state = state + 1'h1;
				else
					next_state = state;
			end
			S_DONE, S_ERROR: begin
				next_state = S_IDLE;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if (rst)
			state <= 0;
		else
			state <= next_state;
	end
	
	always @(posedge clk) begin
		busy <= 0;
		ack <= 0;
		err <= 0;
		if (~rst) case (next_state)
			S_IDLE: begin
				data <= 32'haabbccdd;
			end
			S_BYTE1, S_BYTE2, S_BYTE3, S_BYTE4: begin
				busy <= 1;
				if (rx_ack)
					data <= {rx_data, data[31:8]};
			end
			S_DONE: begin
				ack <= 1;
				data <= {rx_data, data[31:8]};
			end
			S_ERROR: begin
				err <= 1;
			end
		endcase
	end
	
endmodule
