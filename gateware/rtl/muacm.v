/*
 * muacm.v
 *
 * vim: ts=4 sw=4
 *
 * Main top level gluing everything together
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module muacm (
	// USB
	inout  wire       usb_dp,
	inout  wire       usb_dn,
	output wire       usb_pu,

	// Data IF
	input  wire [7:0] in_data,
	input  wire       in_last,
	input  wire       in_valid,
	output wire       in_ready,
	input  wire       in_flush_now,
	input  wire       in_flush_time,

    output wire [7:0] out_data,
	output wire       out_last,
	output wire       out_valid,
	input  wire       out_ready,

	// Bootloader request
	output wire       bootloader,

	// Clock
	input  wire       clk,
	input  wire       rst
);

	// Signals
	// -------

	// CPU IBus
	wire [31:0] wb_ibus_addr;
	wire [31:0] wb_ibus_rdata;
	wire        wb_ibus_cyc;
	wire        wb_ibus_ack;

	// CPU DBus
	wire [31:0] wb_dbus_addr;
	reg  [31:0] wb_dbus_rdata;
	wire [31:0] wb_dbus_wdata;
	wire [ 3:0] wb_dbus_sel;
	wire        wb_dbus_we;
	wire        wb_dbus_cyc;
	wire        wb_dbus_ack;

	// USB
		// EP buffer interface
	reg  [ 7:0] ep_tx_addr_0;
	reg  [15:0] ep_tx_data_0;
	reg  [ 1:0] ep_tx_wmsk_0;
	reg         ep_tx_we_0;

	wire [ 7:0] ep_rx_addr_0;
	wire [15:0] ep_rx_data_1;
	wire        ep_rx_re_0;

		// Bus interface
	wire [11:0] wb_usb_addr;
	wire [15:0] wb_usb_rdata;
	wire [15:0] wb_usb_wdata;
	wire        wb_usb_we;
	wire        wb_usb_cyc;
	wire        wb_usb_ack;

	// EP buffer wishbone IF
		// EP buffer interface
	wire [ 7:0] ep_tx_addr_wb;
	wire [15:0] ep_tx_data_wb;
	wire [ 1:0] ep_tx_wmsk_wb;
	wire        ep_tx_we_wb;

	wire  [8:0] ep_rx_addr_wb;
	wire        ep_rx_re_wb;

		// Bus interface
	wire  [6:0] wb_ep_addr;
	wire [31:0] wb_ep_rdata;
	wire [31:0] wb_ep_wdata;
	wire  [3:0] wb_ep_wmsk;
	wire        wb_ep_we;
	wire        wb_ep_cyc;
	wire        wb_ep_ack;

	// ExtIF
		// Misc
	wire        eif_active;

		// EP buffer interface
	wire [ 7:0] ep_tx_addr_eif;
	wire [15:0] ep_tx_data_eif;
	wire [ 1:0] ep_tx_wmsk_eif;
	wire        ep_tx_we_eif;

	wire  [8:0] ep_rx_addr_eif;
	wire        ep_rx_re_eif;

		// Bus interface
	wire  [1:0] wb_eif_addr;
	wire [31:0] wb_eif_rdata;
	wire [31:0] wb_eif_wdata;
	wire        wb_eif_we;
	wire        wb_eif_cyc;
	wire        wb_eif_ack;


	// CPU
	// ---

	serv_rf_top #(
		.RESET_PC       (32'h0000_0000),
		.RESET_STRATEGY ("MINI"),
		.WITH_CSR       (0)
	) cpu_I (
		.clk          (clk),
		.i_rst        (rst),
		.i_timer_irq  (1'b0),
		.o_ibus_adr   (wb_ibus_addr),
		.o_ibus_cyc   (wb_ibus_cyc),
		.i_ibus_rdt   (wb_ibus_rdata),
		.i_ibus_ack   (wb_ibus_ack),
		.o_dbus_adr   (wb_dbus_addr),
		.o_dbus_dat   (wb_dbus_wdata),
		.o_dbus_sel   (wb_dbus_sel),
		.o_dbus_we    (wb_dbus_we),
		.o_dbus_cyc   (wb_dbus_cyc),
		.i_dbus_rdt   (wb_dbus_rdata),
		.i_dbus_ack   (wb_dbus_ack)
	);

`ifdef SIM_TRACE
	always @(posedge clk)
	begin
		if (wb_ibus_ack)
			$display("IBUS [%d] %03x : %08x", wb_ibus_addr[31:30], wb_ibus_addr[11:0], wb_ibus_rdata);
		if (wb_dbus_ack) begin
			if (wb_dbus_we)
				$display("DBUS  W %04x : %08x", wb_dbus_addr[15:0], wb_dbus_wdata);
			else
				$display("DBUS  R %04x : %08x", wb_dbus_addr[15:0], wb_dbus_rdata);
		end
	end
`endif


	// Instruction ROM
	// ---------------

	irom #(
		.AW(8),
		.INIT_FILE("text.hex")
	) irom_I (
		.wb_addr  (wb_ibus_addr[9:2]),
		.wb_rdata (wb_ibus_rdata),
		.wb_cyc   (wb_ibus_cyc),
		.wb_ack   (wb_ibus_ack),
		.clk      (clk)
	);


	// USB core
	// --------

	usb #(
		.EP_BUF_SIZE(9),
		.EP_BUF_WIDTH(16),
		.EVT_DEPTH(0)
	) usb_I (
		.pad_dp       (usb_dp),
		.pad_dn       (usb_dn),
		.pad_pu       (usb_pu),
		.ep_tx_addr_0 (ep_tx_addr_0),
		.ep_tx_data_0 (ep_tx_data_0),
		.ep_tx_wmsk_0 (ep_tx_wmsk_0),
		.ep_tx_we_0   (ep_tx_we_0),
		.ep_rx_addr_0 (ep_rx_addr_0),
		.ep_rx_data_1 (ep_rx_data_1),
		.ep_rx_re_0   (ep_rx_re_0),
		.ep_clk       (clk),
		.wb_addr      (wb_usb_addr),
		.wb_rdata     (wb_usb_rdata),
		.wb_wdata     (wb_usb_wdata),
		.wb_we        (wb_usb_we ),
		.wb_cyc       (wb_usb_cyc),
		.wb_ack       (wb_usb_ack),
		.irq          (),
		.sof          (),
		.clk          (clk),
		.rst          (rst)
	);


	// EP buffer wishbone IF
	// ---------------------

	wb_epbuf epbuf_I (
		.wb_addr      (wb_ep_addr),
		.wb_rdata     (wb_ep_rdata),
		.wb_wdata     (wb_ep_wdata),
		.wb_wmsk      (wb_ep_wmsk),
		.wb_we        (wb_ep_we),
		.wb_cyc       (wb_ep_cyc),
		.wb_ack       (wb_ep_ack),
		.ep_tx_addr_0 (ep_tx_addr_wb),
		.ep_tx_data_0 (ep_tx_data_wb),
		.ep_tx_wmsk_0 (ep_tx_wmsk_wb),
		.ep_tx_we_0   (ep_tx_we_wb),
		.ep_rx_addr_0 (ep_rx_addr_wb),
		.ep_rx_data_1 (ep_rx_data_1),
		.ep_rx_re_0   (ep_rx_re_wb),
		.clk          (clk),
		.rst          (rst)
	);


	// ExtIF
	// -----

	extif extif_I (
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
		.wb_addr       (wb_eif_addr),
		.wb_rdata      (wb_eif_rdata),
		.wb_wdata      (wb_eif_wdata),
		.wb_we         (wb_eif_we),
		.wb_cyc        (wb_eif_cyc),
		.wb_ack        (wb_eif_ack),
		.ep_tx_addr_0  (ep_tx_addr_eif),
		.ep_tx_data_0  (ep_tx_data_eif),
		.ep_tx_wmsk_0  (ep_tx_wmsk_eif),
		.ep_tx_we_0    (ep_tx_we_eif),
		.ep_rx_addr_0  (ep_rx_addr_eif),
		.ep_rx_data_1  (ep_rx_data_1),
		.ep_rx_re_0    (ep_rx_re_eif),
		.cpu_ibus_ack  (wb_ibus_ack),
		.cpu_dbus_ack  (wb_dbus_ack),
		.active        (eif_active),
		.bootloader    (bootloader),
		.clk           (clk),
		.rst           (rst)
	);


	// EP buffer IF mux
	// ----------------

	// TX buffer writes
		// (we need LUTs for mux here anyway so we might as well
		//  register and break critical path)
	always @(posedge clk)
	begin
		ep_tx_addr_0 <= eif_active ? ep_tx_addr_eif : ep_tx_addr_wb;
		ep_tx_data_0 <= eif_active ? ep_tx_data_eif : ep_tx_data_wb;
		ep_tx_wmsk_0 <= eif_active ? ep_tx_wmsk_eif : ep_tx_wmsk_wb;
		ep_tx_we_0   <= eif_active ? ep_tx_we_eif   : ep_tx_we_wb;
	end

	// RX buffer reads
	assign ep_rx_addr_0 = eif_active ? ep_rx_addr_eif : ep_rx_addr_wb;
	assign ep_rx_re_0   = eif_active ? ep_rx_re_eif   : ep_rx_re_wb;


	// Data bus mux
	// ------------

	// Ack
	assign wb_dbus_ack = wb_usb_ack | wb_ep_ack | wb_eif_ack;

	// USB CSR access
	assign wb_usb_addr  = {wb_dbus_addr[10], 3'b000, wb_dbus_addr[9:2] };
	assign wb_usb_wdata = wb_dbus_wdata[15:0];
	assign wb_usb_we    = wb_dbus_we;
	assign wb_usb_cyc   = wb_dbus_cyc & (wb_dbus_addr[12:11] == 2'b00);

	// EP buffer access
	assign wb_ep_addr  = wb_dbus_addr[8:2];
	assign wb_ep_wdata = wb_dbus_wdata;
	assign wb_ep_wmsk = ~wb_dbus_sel;
	assign wb_ep_we    = wb_dbus_we;
	assign wb_ep_cyc   = wb_dbus_cyc & (wb_dbus_addr[12:11] == 2'b01);

	// ExtIF access
	assign wb_eif_addr  = wb_dbus_addr[3:2];
	assign wb_eif_wdata = wb_dbus_wdata;
	assign wb_eif_we    = wb_dbus_we;
	assign wb_eif_cyc   = wb_dbus_cyc & wb_dbus_addr[12];

	// Read Data muxing
	always @(*)
		casez (wb_dbus_addr[12:11])
			2'b00:   wb_dbus_rdata = wb_usb_rdata;
			2'b01:   wb_dbus_rdata = wb_ep_rdata;
			2'b1z:   wb_dbus_rdata = wb_eif_rdata;
			default: wb_dbus_rdata = 32'hxxxxxxxx;
		endcase

endmodule // muacm
