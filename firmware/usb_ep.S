/*
 * usb_ep.S
 *
 * EP Status - Block RAM init
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */

 #include "usb_hw.h"

 #define EP(n)	( (((n) & 0xf) << 6) | (((n) & 0x80) >> 2) )


	.section .usb_ep, "a"

	/* EP 0 OUT */
	.org EP(0x00)

	.word	USB_EP_TYPE_CTRL | USB_EP_BD_CTRL
	.space	12

	.word	0		// BD0 CSR
	.word	ep0_rx_data	// BD0 PTR
	.word	0		// BD1 CSR
	.word	ep0_rx_setup	// BD1 PTR

	/* EP 0 IN */
	.org EP(0x80)

	.word	USB_EP_TYPE_CTRL | USB_EP_DT_BIT
	.space	12

	/* EP 2 OUT */
	.org EP(0x02)

	.word	USB_EP_TYPE_BULK | USB_EP_BD_DUAL
	.space	12

	.word	0		// BD0 CSR
	.word	ep2_rx_bd0	// BD0 PTR
	.word	0		// BD1 CSR
	.word	ep2_rx_bd1	// BD1 PTR

	/* EP 2 IN */
	.org EP(0x82)

	.word	USB_EP_TYPE_BULK | USB_EP_BD_DUAL
	.space	12

	.word	0		// BD0 CSR
	.word	ep2_tx_bd0	// BD0 PTR
	.word	0		// BD1 CSR
	.word	ep2_tx_bd1	// BD1 PTR

	/* EP 3 OUT */
	.org EP(0x03)

	.word	USB_EP_TYPE_BULK
	.space	12

	.word	0		// BD0 CSR
	.word	ep3_tx		// BD0 PTR
	.word	0		// BD1 CSR
	.word	0		// BD1 PTR
