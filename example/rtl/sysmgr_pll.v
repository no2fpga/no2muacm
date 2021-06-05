/*
 * sysmgr_pll.v
 *
 * vim: ts=4 sw=4
 *
 * CRG generating 24 & 48 MHz from external 12/48 MHz
 * (depending on board)
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module sysmgr_pll (
	input  wire clk_in,
	input  wire rst_in,
	output wire clk_24m,
	output wire clk_48m,
	output wire rst_out
);

	// Signals
	wire pll_lock;
	wire pll_reset_n;

	wire clk_1x;
	wire clk_2x;
	wire rst_i;
	reg [3:0] rst_cnt;

	// Clock frequency input depends on board
`ifdef BOARD_FOMU_HACKER
`define CLK_IN_FABRIC
`define CLK_IN_48M
`elsif BOARD_FOMU_PVT1
`define CLK_IN_FABRIC
`define CLK_IN_48M
`elsif BOARD_TINYFPGA_BX
`define CLK_IN_FABRIC
`define CLK_IN_16M
`endif

	// PLL instance
`ifdef SIM
	reg clk_div = 1'b0;

	always @(posedge clk_in)
		clk_div <= ~clk_div;

	assign clk_1x = clk_div;
	assign clk_2x = clk_in;
	assign pll_lock = pll_reset_n;

	initial
		rst_cnt <= 4'h8;
`else
`ifdef CLK_IN_FABRIC
	SB_PLL40_2F_CORE #(
`else
	SB_PLL40_2F_PAD #(
`endif
`ifdef CLK_IN_48M
		// clk_in is 48 MHz
		.DIVR(4'b0000),
		.DIVF(7'b0001111),
		.DIVQ(3'b100),
		.FILTER_RANGE(3'b100),
`elsif CLK_IN_16M
		// clk_in is 16 MHz
		.DIVR(4'b0000),
		.DIVF(7'b0101111),
		.DIVQ(3'b100),
		.FILTER_RANGE(3'b001),
`else
		// clk_in is 12 MHz
		.DIVR(4'b0000),
		.DIVF(7'b0111111),
		.DIVQ(3'b100),
		.FILTER_RANGE(3'b001),
`endif
		.FEEDBACK_PATH("SIMPLE"),
		.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
		.FDA_FEEDBACK(4'b0000),
		.SHIFTREG_DIV_MODE(2'b00),
		.PLLOUT_SELECT_PORTA("GENCLK"),
		.PLLOUT_SELECT_PORTB("GENCLK_HALF"),
		.ENABLE_ICEGATE_PORTA(1'b0),
		.ENABLE_ICEGATE_PORTB(1'b0)
	) pll_I (
`ifdef CLK_IN_FABRIC
		.REFERENCECLK   (clk_in),
`else
		.PACKAGEPIN     (clk_in),
`endif
		.PLLOUTCOREA    (),
		.PLLOUTGLOBALA  (clk_2x),
		.PLLOUTCOREB    (),
		.PLLOUTGLOBALB  (clk_1x),
		.EXTFEEDBACK    (1'b0),
		.DYNAMICDELAY   (8'h00),
		.RESETB         (pll_reset_n),
		.BYPASS         (1'b0),
		.LATCHINPUTVALUE(1'b0),
		.LOCK           (pll_lock),
		.SDI            (1'b0),
		.SDO            (),
		.SCLK           (1'b0)
	);
`endif

	assign clk_24m = clk_1x;
	assign clk_48m = clk_2x;

	// PLL reset generation
	assign pll_reset_n = ~rst_in;

	// Logic reset generation
	always @(posedge clk_1x or negedge pll_lock)
		if (!pll_lock)
			rst_cnt <= 4'h8;
		else if (rst_cnt[3])
			rst_cnt <= rst_cnt + 1;

	assign rst_i = rst_cnt[3];

	SB_GB rst_gbuf_I (
		.USER_SIGNAL_TO_GLOBAL_BUFFER(rst_i),
		.GLOBAL_BUFFER_OUTPUT(rst_out)
	);

endmodule // sysmgr_pll
