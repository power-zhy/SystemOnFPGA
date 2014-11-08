`include "define.vh"


/**
 * SPI device with wishbone connection interfaces, including read/write buffers.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module wb_spi (
	input wire clk,  // main clock, should be faster than or equal to wishbone clock
	input wire rst,  // synchronous reset
	// SPI interfaces
	output wire sck,
	input wire miso,
	output wire mosi,
	output wire [15:0] sel_n,
	// peripheral wishbone interfaces
	input wire wbs_clk_i,
	input wire wbs_cs_i,
	input wire [DEV_ADDR_BITS-1:2] wbs_addr_i,
	input wire [3:0] wbs_sel_i,
	input wire [31:0] wbs_data_i,
	input wire wbs_we_i,
	output reg [31:0] wbs_data_o,
	output reg wbs_ack_o,
	// interrupt
	output reg interrupt
	);
	
	parameter
		CLK_FREQ = 100;  // main clock frequency in MHz, should be multiple of 10M
	parameter
		DEV_ADDR_BITS = 8;  // address length of I/O space
	parameter
		BUF_ADDR_WIDTH = 8;
	
	// control registers
	wire buf_full;
	reg buf_of = 0, buf_uf = 0;
	wire [BUF_ADDR_WIDTH-1:0] rx_left, tx_left;
	reg [31:0] reg_mode = 0;
	
	reg rx_ren, tx_wen;
	wire spi_en;
	reg spi_rst;
	wire [7:0] din;
	reg [7:0] dout;
	wire [7:0] spi_din, spi_dout;
	wire spi_ack;
	
	// core
	spi_core #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_DIV_WIDTH(8),
		.DATA_BITS(8)
		) SPI_CORE (
		.clk(clk),
		.rst(rst),
		.baud_div(reg_mode[15:8]),
		.cpha(reg_mode[7]),
		.cpol(reg_mode[6]),
		.lsbfe(reg_mode[5]),
		.en(spi_en),
		.din(spi_din),
		.ack(spi_ack),
		.dout(spi_dout),
		.busy(),
		.sck(sck),
		.miso(miso),
		.mosi(mosi)
		);
	
	assign
		sel_n = ~reg_mode[31:16];
	
	// buffer
	wire rx_empty, tx_empty;
	wire [BUF_ADDR_WIDTH-1:0] space_count, data_count;
	reg rx_ren_prev, tx_wen_prev;
	wire rx_ren_raise, tx_wen_raise;
	
	always @(posedge clk) begin
		if (rst) begin
			rx_ren_prev <= 0;
			tx_wen_prev <= 0;
		end
		else begin
			rx_ren_prev <= rx_ren;
			tx_wen_prev <= tx_wen;
		end
	end
	
	assign
		rx_ren_raise = ~rx_ren_prev & rx_ren,
		tx_wen_raise = ~tx_wen_prev & tx_wen;
	
	fifo #(
		.DATA_BITS(8),
		.ADDR_BITS(BUF_ADDR_WIDTH),
		.DETECT_WEN_EDGE(0),
		.DETECT_REN_EDGE(0)
		) FIFO_TX (
		.clk(clk),
		.rst(rst | spi_rst),
		.en_w(tx_wen_raise),
		.data_w(dout),
		.full_w(),
		.near_full_w(),
		.space_count(space_count),
		.en_r(spi_ack),
		.data_r(spi_din),
		.empty_r(tx_empty),
		.near_empty_r(),
		.data_count()
		);
	
	fifo #(
		.DATA_BITS(8),
		.ADDR_BITS(BUF_ADDR_WIDTH),
		.DETECT_WEN_EDGE(1),
		.DETECT_REN_EDGE(1)
		) FIFO_RX (
		.clk(clk),
		.rst(rst | spi_rst),
		.en_w(spi_ack),
		.data_w(spi_dout),
		.full_w(),
		.near_full_w(),
		.space_count(),
		.en_r(rx_ren_raise),
		.data_r(din),
		.empty_r(rx_empty),
		.near_empty_r(),
		.data_count(data_count)
		);
	
	always @(posedge clk) begin
		if (rst || spi_rst) begin
			buf_of <= 0;
			buf_uf <= 0;
		end
		else if (buf_full && tx_wen_raise)
			buf_of <= 1;
		else if (rx_empty && rx_ren_raise)
			buf_uf <= 1;
	end
		
	// in logical view, we combine RX and TX FIFO into one buffer, to simplify buffer management
	// as in SPI, once a data read from TX FIFO, there is another data written to RX FIFO
	assign
		spi_en = reg_mode[0] & ~tx_empty,
		buf_full = (space_count == data_count),
		tx_left = space_count - data_count,
		rx_left = data_count;
	
	// wishbone controller
	always @(posedge wbs_clk_i) begin
		tx_wen <= 0;
		rx_ren <= 0;
		spi_rst <= 0;
		dout <= 0;
		wbs_data_o <= 0;
		wbs_ack_o <= 0;
		if (rst) begin
			reg_mode <= 0;
			wbs_data_o <= 0;
			wbs_ack_o <= 0;
		end
		else if (wbs_cs_i & ~wbs_ack_o) begin
			case (wbs_addr_i)
				14'h0: begin
					wbs_data_o <= {spi_en, 27'b0, buf_of, buf_uf, buf_full, tx_empty};
				end
				14'h1: begin
					wbs_data_o[31:16] <= rx_left;
					wbs_data_o[15:0] <= tx_left;
				end
				14'h2: begin
					wbs_data_o <= reg_mode;
					if (wbs_we_i) begin
						spi_rst <= 1;
						if (wbs_sel_i[3])
							reg_mode[31:24] <= wbs_data_i[31:24];
						if (wbs_sel_i[2])
							reg_mode[23:16] <= wbs_data_i[23:16];
						if (wbs_sel_i[1])
							reg_mode[15:8] <= wbs_data_i[15:8];
						if (wbs_sel_i[0])
							reg_mode[7:0] <= wbs_data_i[7:0];
					end
				end
				14'h3: begin
					wbs_data_o <= {24'h0, din};
					dout <= wbs_data_i[7:0]; // sel_i are ignored
					if (wbs_we_i)
						tx_wen <= 1;
					else
						rx_ren <= 1;
				end
				default: begin
					wbs_data_o <= 0;
				end
			endcase
			wbs_ack_o <= 1;
		end
	end
	
	// interrupt
	reg tx_empty_prev;
	wire ir_overflow, ir_underflow, ir_empty;
	
	always @(posedge clk) begin
		if (rst) begin
			tx_empty_prev <= 0;
		end
		else begin
			tx_empty_prev <= tx_empty;
		end
	end
	
	assign
		ir_overflow = buf_full & tx_wen_raise,
		ir_underflow = rx_empty & rx_ren_raise,
		ir_empty = ~tx_empty_prev & tx_empty;
	
	always @(posedge clk) begin
		if (rst)
			interrupt <= 0;
		else
			interrupt <= ir_overflow | ir_underflow | ir_empty;
	end
	
endmodule
