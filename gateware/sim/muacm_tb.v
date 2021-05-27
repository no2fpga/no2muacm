/*
 * muacm.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none
`timescale 1ns / 100ps

module muacm_tb;

	// Signals
	// -------

	// USB
	wire       usb_dp;
	wire       usb_dn;
	wire       usb_pu;

	// Data interface
	wire [7:0] in_data;
	wire       in_last;
	wire       in_valid;
	wire       in_ready;
	wire       in_flush_now;
	wire       in_flush_time;

    wire [7:0] out_data;
	wire       out_last;
	wire       out_valid;
	wire       out_ready;

	// Misc
	wire       bootloader;

	// File input
	reg  [7:0] in_file_data;
	reg        in_file_valid;
	reg        in_file_done;
	reg	       in_file_hold;

	// Clocking
	reg        rst = 1'b1;
	reg        clk = 1'b0;
	reg        clk_samp = 1'b0;


	// DUT
	// ---

	// Core
	muacm dut_I (
		.usb_dp        (usb_dp),
		.usb_dn        (usb_dn),
		.usb_pu        (usb_pu),
		.in_data       (in_data),
		.in_last       (in_last),
		.in_valid      (in_valid),
		.in_ready      (in_ready),
		.in_flush_now  (in_flush_now),
		.in_flush_time (in_flush_time),
		.out_data      (out_data),
		.out_last      (out_last),
		.out_valid     (out_valid),
		.out_ready     (out_ready),
		.bootloader    (bootloader),
		.clk           (clk ),
		.rst           (rst )
	);

	// Data loopback
	assign in_data   = out_data;
	assign in_last   = out_last;
	assign in_valid  = out_valid;
	assign out_ready = in_ready;

	assign in_flush_now  = 1'b0;
	assign in_flush_time = 1'b1;


	// Data feed
	// ---------

	integer fh_in, rv;

	initial
		fh_in = $fopen("../gateware/cores/no2usb/data/capture_usb_raw_short.bin", "rb");

	always @(posedge clk_samp)
	begin
		if (rst) begin
			in_file_data  <= 8'h00;
			in_file_valid <= 1'b0;
			in_file_done  <= 1'b0;
		end else begin
			if (!in_file_done) begin
				if (!in_file_hold) begin
					rv = $fread(in_file_data, fh_in);
					in_file_valid <= (rv == 1);
					in_file_done  <= (rv != 1);
				end
			end else begin
				in_file_data  <= 8'h00;
				in_file_valid <= 1'b0;
				in_file_done  <= 1'b1;
			end
		end
	end

	// Input
	assign usb_dp = in_file_data[1] & in_file_valid;
	assign usb_dn = in_file_data[0] & in_file_valid;

	// Delay some parts
	initial
	begin
		in_file_hold <= 1'b0;
		#190000 in_file_hold <= 1'b1;
		#100000 in_file_hold <= 1'b0;
	end


	// Sim setup
	// ---------

	// Setup recording
	initial begin
		$dumpfile("muacm_tb.vcd");
		$dumpvars(0,muacm_tb);
	end

	// Reset pulse
	initial begin
		# 200 rst = 0;
		# 1000000 $finish;
	end

	// Clocks
	always #10.42 clk = !clk;
	always #3.247 clk_samp = !clk_samp;

endmodule // muacm_tb
