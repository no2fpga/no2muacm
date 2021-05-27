/*
 * irom.v
 *
 * vim: ts=4 sw=4
 *
 * Instruction ROM 256x32
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module irom #(
	parameter integer AW = 8,
	parameter INIT_FILE = ""
)(
	input  wire [AW-1:0] wb_addr,
	output reg  [  31:0] wb_rdata,
	input  wire          wb_cyc,
	output reg           wb_ack,
	input  wire          clk
);
	(* ram_style="block" *)
	reg [31:0] mem [0:(1<<AW)-1];

	initial
		if (INIT_FILE != "")
			$readmemh(INIT_FILE, mem);

	always @(posedge clk)
		wb_rdata <= mem[wb_addr];

	always @(posedge clk)
		wb_ack <= wb_cyc & ~wb_ack;

endmodule // irom
