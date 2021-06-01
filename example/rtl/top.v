`default_nettype none

`define WITH_BUTTON
`define HFOSC

module top (
	// USB
	inout  wire usb_dp,
	inout  wire usb_dn,
	output wire usb_pu,

	// Button
	input  wire btn,

	// Clock
	input  wire clk_in
);

	// Which image to reboot to
	// 01 for no2bootloader, 00 for foboot
	localparam [1:0] BOOT_IMAGE = 2'b01;


	// Signals
	// -------

	// Pipe data
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

	// Bootloader request
	wire       bootloader;

	// Clock / Reset
	wire rst_in;

	wire clk_usb;
	wire rst_usb;


	// uACM
	// ----

	muacm acm_I (
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
		.out_valid     (out_valid ),
		.out_ready     (out_ready ),
		.bootloader    (bootloader),
		.clk           (clk_usb),
		.rst           (rst_usb)
	);

	// Loopback
	assign in_flush_now = 1'b0;
	assign in_flush_time = 1'b1;

	assign in_data   = out_data;
	assign in_last   = 1'b0;
	assign in_valid  = out_valid;
	assign out_ready = in_ready;


	// DFU helper
	// ----------

`ifdef WITH_BUTTON
	dfu_helper #(
		.BTN_MODE(3),
		.BOOT_IMAGE(BOOT_IMAGE)
	) dfu_helper_I (
		.boot_sel (2'b01),
		.boot_now (bootloader),
		.btn_in   (btn),
		.btn_tick (),
		.btn_val  (),
		.btn_press(rst_in),
		.clk      (clk_usb),
		.rst      (rst_usb)
	);
`else
	assign rst_in = 1'b0;

	reg boot = 1'b0;
	always @(posedge clk_usb)
		boot <= boot | bootloader;

	SB_WARMBOOT warmboot (
		.BOOT (boot),
		.S0   (BOOT_IMAGE[0]),
		.S1   (BOOT_IMAGE[1])
	);
`endif


	// Clock / Reset
	// -------------

`ifdef HFOSC
	sysmgr_hfosc sysmgr_I (
		.rst_in (rst_in),
		.clk_out(clk_usb),
		.rst_out(rst_usb)
	);
`else
	sysmgr_pll sysmgr_I (
		.clk_in (clk_in),
		.rst_in (rst_in),
		.clk_48m(clk_usb),
		.rst_out(rst_usb)
	);
`endif

endmodule // top
