/*
 * rf.S
 *
 * SERV Register File - Block RAM init
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */

	.section .cpu_rf, "a"

	// Bank 0
	.org 0

	.word	0x00000000	// x0

	.org 120
	.word	0x00000800	// x30 = EP Buf base

	// Bank 1
	.org 128

	.space 32	// x0-x7: Unused (hard wired to bank 0)


	// Bank 2
	.org 256

	.space 32	// x0-x7: Unused (hard wired to bank 0)


	// Bank 3
	.org 384

	.space 32	// x0-x7: Unused (hard wired to bank 0)
