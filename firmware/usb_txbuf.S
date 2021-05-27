/*
 * usb_tx_buf.S
 *
 * EP RX buffer - Block RAM init
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */


	// USB EP TX buffers
	// -----------------

	.section .usb_txbuf.epbuf, "a"

	.org	0	// Start at 0 to ensure the ep2 buffers are 64 byte aligned

	.global	ep2_tx_bd0
ep2_tx_bd0:
	.space	64

	.global	ep2_tx_bd1
ep2_tx_bd1:
	.space	64

	.global ep0_tx
ep0_tx:
	.space	8

	.global ep3_tx
ep3_tx:
	.space	8
