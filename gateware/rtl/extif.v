/*
 * extif.v
 *
 * vim: ts=4 sw=4
 *
 * External data interface, shuffling data between the EP buffers
 * and the user application and controlled by the CPU. (Mini-DMA)
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module extif (
	// Data IF
	input  wire  [7:0] in_data,
	input  wire        in_last,
	input  wire        in_valid,
	output wire        in_ready,
	input  wire        in_flush_now,
	input  wire        in_flush_time,

    output reg   [7:0] out_data,
	output reg         out_last,
	output reg         out_valid,
	input  wire        out_ready,

	// Wishbone
	input  wire  [1:0] wb_addr,
	output wire [31:0] wb_rdata,
	input  wire [31:0] wb_wdata,
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

	// Misc
	input  wire        cpu_ibus_ack,
	input  wire        cpu_dbus_ack,
	output wire        active,

	output wire        bootloader,

	// Clock
	input  wire        clk,
	input  wire        rst
);

	// Signals
	// -------

	// Status
	wire [31:0] csr;

	// Active timer
	(* keep *)
	wire        trig;
	reg         ena;
	reg   [5:0] active_cnt;

	// Bus interface
	reg         b_ack;

	(* keep *)
	wire        b_we_pre;
	reg         b_we_boot;
	reg         b_we_csr;
	reg         b_we_in;
	reg         b_we_out;

	// IN
	reg   [2:0] in_msb;
	reg   [6:0] in_bcnt;
	wire  [6:0] in_inc;
	wire        in_we;

	// OUT
	reg   [2:0] out_msb;
	reg   [5:0] out_lsb;
	reg   [6:0] out_cnt;
	wire        out_filled;

	(* keep *)
	wire        out_load;
	reg         out_did_read;


	// Active timer
	// ------------

	// Activate for 32 cycles after each dbus or ibus ack
	// (due to SERV arch, we _know_ there won't be any CPU access and
	//  we can freely access the EPs buffer without conflict)

	assign trig = (cpu_dbus_ack | cpu_ibus_ack) & ena;

	always @(posedge clk or posedge rst)
	begin
		if (rst)
			active_cnt <= 0;
		else
			active_cnt <= (active_cnt + {5'd0, active}) | { trig, 5'd0 };
	end

	assign active = active_cnt[5];

	// Bus interface

		// Ack
	always @(posedge clk)
		b_ack <= wb_cyc & ~b_ack;

	assign wb_ack = b_ack;

		// Write Strobes
	assign b_we_pre = wb_cyc & wb_we;

	always @(posedge clk)
	begin
		b_we_boot <= b_we_pre & (wb_addr == 2'b00) & ~b_ack;
		b_we_csr  <= b_we_pre & (wb_addr == 2'b01) & ~b_ack;
		b_we_in   <= b_we_pre & (wb_addr == 2'b10) & ~b_ack;
		b_we_out  <= b_we_pre & (wb_addr == 2'b11) & ~b_ack;
	end

		// Read data
	assign wb_rdata = csr;

	// Bootloader request
	assign bootloader = b_we_boot;

	// Global CSR
	always @(posedge clk or posedge rst)
		if (rst)
			ena <= 1'b0;
		else if (b_we_csr)
			ena <= wb_wdata[0];

	assign csr = {
		// [31:16]
		16'd0,

		// [15:8]
		1'b0,
		in_bcnt,

		// [7:4]
		out_filled,
		1'b0,
		in_flush_now,
		in_flush_time,

		// [3:0]
		3'd0,
		ena
	};


	// IN
	// --

	// Addressing: Set on CPU write, increment on write
	// (with special mask if in_last to end packet)
	always @(posedge clk or posedge rst)
	begin
		if (rst) begin
			in_msb  <= 3'b000;
			in_bcnt <= 7'h00;
		end else begin
			in_msb  <= b_we_in ? wb_wdata[8:6] : in_msb;
			in_bcnt <= b_we_in ? { 7'd0 } : in_inc;
		end
	end

	assign in_inc = (in_bcnt + {6'd0, in_we}) | {in_last & in_valid & active, 6'd0};

	// Write when valid & ready
	assign in_we = in_ready & in_valid;

	// Ready when EIF is active (guaranteed no overlap with bus accesses)
	// and when we have a non-full buffer
	assign in_ready = active & ~in_bcnt[6];

	// EP TX for ExtIF IN
	assign ep_tx_addr_0 = { in_msb, in_bcnt[5:1] };
	assign ep_tx_data_0 = { in_data, in_data };
	assign ep_tx_wmsk_0 = { ~in_bcnt[0], in_bcnt[0] };
	assign ep_tx_we_0   = in_we;


	// OUT
	// ---

	// Addressing+Len: Set on CPU write, adjust on load
	always @(posedge clk or posedge rst)
	begin
		if (rst) begin
			out_msb  <= 3'b000;
			out_lsb  <= 6'h00;
			out_cnt  <= 7'h00;
		end else begin
			out_msb  <= b_we_out ? wb_wdata[8:6] : out_msb;
			out_lsb  <= b_we_out ? 6'h00 : (out_lsb + { 5'd0, out_load });
			out_cnt  <= b_we_out ? { 1'b1, wb_wdata[5:0] } : (out_cnt + {7{out_load}});
		end
	end

	assign out_filled = out_cnt[6];

	// Load when EIF was active last cycle (so we read a byte)
	// and the current is not valid
	always @(posedge clk)
		out_did_read <= active & out_filled;

	assign out_load = out_did_read & ~out_valid;

		// Data+valid register
	always @(posedge clk or posedge rst)
		if (rst) begin
			out_data  <= 8'h00;
			out_last  <= 1'b0;
		end else if (out_load) begin
			out_data  <= out_lsb[0] ? ep_rx_data_1[15:8] : ep_rx_data_1[7:0];
			out_last  <= (out_cnt[6:0] == 0);
		end

	always @(posedge clk or posedge rst)
		if (rst)
			out_valid <= 1'b0;
		else
			out_valid <= (out_valid & ~out_ready) | out_load;

	// EP RX For ExtIF OUT
	assign ep_rx_addr_0 = { out_msb, out_lsb[5:1] };
	assign ep_rx_re_0 = 1'b1;

endmodule // extif
