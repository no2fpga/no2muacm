/*
 * muacm_xclk.v
 *
 * vim: ts=4 sw=4
 *
 * Cross clock module for the muACM data port.
 * ( You'll need one instance per direction )
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module muacm_xclk (
	input  wire [7:0] i_data,
	input  wire       i_last,
	input  wire       i_valid,
	output reg        i_ready,
	input  wire       i_clk,

	output wire [7:0] o_data,
	output wire       o_last,
	output reg        o_valid,
	input  wire       o_ready,
	input  wire       o_clk,

	input  wire       rst
);

	// Signals
	reg        send_i;
	reg  [1:0] send_sync_o;

	reg        ack_o;
	reg  [1:0] ack_sync_i;

	// Data
	assign o_data = i_data;
	assign o_last = i_last;

	// Handshake
	always @(posedge i_clk or posedge rst)
		if (rst)
			send_i <= 1'b0;
		else
			send_i <= ( send_i | (i_valid & ~i_ready) ) & ~ack_sync_i[0];

	always @(posedge o_clk or posedge rst)
		if (rst)
			send_sync_o <= 2'b00;
		else
			send_sync_o <= { send_sync_o[0], send_i };

	always @(posedge o_clk or posedge rst)
		if (rst)
			o_valid <= 1'b0;
		else
			o_valid <= (o_valid & ~o_ready) | (send_sync_o[0] & ~send_sync_o[1]);

	always @(posedge o_clk or posedge rst)
		if (rst)
			ack_o <= 1'b0;
		else
			ack_o <= (ack_o & send_sync_o[0]) | (o_valid & o_ready);

	always @(posedge i_clk or posedge rst)
		if (rst)
			ack_sync_i <= 2'b00;
		else
			ack_sync_i <= { ack_sync_i[0], ack_o };

	always @(posedge i_clk or posedge rst)
		if (rst)
			i_ready <= 1'b0;
		else
			i_ready <= ack_sync_i[0] & ~ack_sync_i[1];

endmodule // muacm_xclk
