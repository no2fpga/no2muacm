/*
 * usb_rx_buf.S
 *
 * EP RX buffer - Block RAM init
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */


	// USB EP RX buffers
	// -----------------

		// Space reserved for actual USB packet RX

	.section .usb_rxbuf.epbuf, "a"

	.org	0	// Start at 0 to ensure the ep2 buffers are 64 byte aligned

	.global	ep2_rx_bd0
ep2_rx_bd0:
	.space	64

	.global	ep2_rx_bd1
ep2_rx_bd1:
	.space	64

	.global	ep0_rx_data
ep0_rx_data:
	.space	64

	.global ep0_rx_setup
ep0_rx_setup:
	.space	64


	// Constants
	// ---------

		// Space used just for .rodata consants read
		// by the CPU

	.section .usb_rxbuf.const, "a"
