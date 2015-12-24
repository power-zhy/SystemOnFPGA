`include "define.vh"


/**
 * Clock generator.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module clk_gen_sword (
	input wire clk_pad,  // input clock, 100MHz
	output wire clk_100m,
	output wire clk_50m,
	output wire clk_25m,
	output wire clk_10m,
	output wire locked
	);
	
	wire clk_fb;
	wire clk_pad_buf;
	wire clk_100m_unbuf;
	wire clk_50m_unbuf;
	wire clk_25m_unbuf;
	wire clk_10m_unbuf;
	
	IBUFG CLK_PAD_BUF (.I(clk_pad), .O(clk_pad_buf));
	
	MMCME2_BASE #(
		.BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
		.CLKFBOUT_MULT_F(6.0),     // Multiply value for all CLKOUT (2.000-64.000).
		.CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
		.CLKIN1_PERIOD(10.0),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		// CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
		.CLKOUT0_DIVIDE_F(6.0),    // Divide amount for CLKOUT0 (1.000-128.000).
		.CLKOUT1_DIVIDE(12),
		.CLKOUT2_DIVIDE(24),
		.CLKOUT3_DIVIDE(60),
		.CLKOUT4_DIVIDE(60),
		.CLKOUT5_DIVIDE(60),
		.CLKOUT6_DIVIDE(60),
		// CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT6_DUTY_CYCLE(0.5),
		// CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.CLKOUT6_PHASE(0.0),
		.CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
		.DIVCLK_DIVIDE(1),         // Master division value (1-106)
		.REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
		.STARTUP_WAIT("TRUE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
		) MMCME2_BASE_inst (
		// Clock Outputs: 1-bit (each) output: User configurable clock outputs
		.CLKOUT0(clk_100m_unbuf),
		.CLKOUT0B(),
		.CLKOUT1(clk_50m_unbuf),
		.CLKOUT1B(),
		.CLKOUT2(clk_25m_unbuf),
		.CLKOUT2B(),
		.CLKOUT3(clk_10m_unbuf),
		.CLKOUT3B(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKOUT6(),
		// Feedback Clocks: 1-bit (each) output: Clock feedback ports
		.CLKFBOUT(clk_fb),
		.CLKFBOUTB(),
		// Status Ports: 1-bit (each) output: MMCM status ports
		.LOCKED(locked),
		// Clock Inputs: 1-bit (each) input: Clock input
		.CLKIN1(clk_pad_buf),
		// Control Ports: 1-bit (each) input: MMCM control ports
		.PWRDWN(1'b0),
		.RST(1'b0),
		// Feedback Clocks: 1-bit (each) input: Clock feedback ports
		.CLKFBIN(clk_fb)
	);
	
	BUFG
		CLK_BUF_100M (.I(clk_100m_unbuf), .O(clk_100m)),
		CLK_BUF_50M (.I(clk_50m_unbuf), .O(clk_50m)),
		CLK_BUF_25M (.I(clk_25m_unbuf), .O(clk_25m)),
		CLK_BUF_10M (.I(clk_10m_unbuf), .O(clk_10m));
	
endmodule
