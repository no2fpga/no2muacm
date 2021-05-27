/*
 * wb_epbuf.v
 *
 * vim: ts=4 sw=4
 *
 * Bridge between 32b wishbone and the 16b EP buffer
 * interface.
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module wb_epbuf (
	// Wishbone
	input  wire  [6:0] wb_addr,
	output wire [31:0] wb_rdata,
	input  wire [31:0] wb_wdata,
	input  wire  [3:0] wb_wmsk,
	input  wire        wb_we,
	input  wire        wb_cyc,
	output wire        wb_ack,

	// EP buffer interface
	output wire [ 7:0] ep_tx_addr_0,
	output wire [15:0] ep_tx_data_0,
	output wire [ 1:0] ep_tx_wmsk_0,
	output wire        ep_tx_we_0,

	output wire  [8:0] ep_rx_addr_0,
	input  wire [15:0] ep_rx_data_1,
	output wire        ep_rx_re_0,

	// Clock
	input  wire        clk,
	input  wire        rst
);

	// Signals
	// -------

	reg         b_cyd;
	reg         b_ack;
	reg         b_we;

	reg  [15:0] ep_rx_data_lsb;


	// Control
	// -------

	always @(posedge clk)
	begin
		b_cyd <= wb_cyc & ~b_ack;
		b_we  <= wb_cyc & ~b_ack & wb_we;
		b_ack <=  b_cyd & ~b_ack;
	end

	assign wb_ack = b_ack;


	// TX Writes
	// ---------

	assign ep_tx_addr_0 = { wb_addr, b_ack };
	assign ep_tx_data_0 = b_ack ? wb_wdata[31:16] : wb_wdata[15:0];
	assign ep_tx_wmsk_0 = b_ack ? wb_wmsk [ 3: 2] : wb_wmsk [ 1:0];
	assign ep_tx_we_0   = b_we;


	// RX Reads
	// --------

	assign ep_rx_addr_0 = { wb_addr, b_cyd };
	assign ep_rx_re_0 = 1'b1;

	always @(posedge clk)
		ep_rx_data_lsb <= ep_rx_data_1;

	assign wb_rdata = { ep_rx_data_1, ep_rx_data_lsb };

endmodule // wb_epbuf
