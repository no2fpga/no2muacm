/*
 * usb_hw.h
 *
 * HW register definitions
 *
 * Copyright (C) 2019-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */

#pragma once

/* Base register */
#define USB_BASE		zero

/* CSR register */
#define USB_CSR			0(USB_BASE)

#define USB_CSR_PU_ENA		(1 << 15)
#define USB_CSR_EVT_PENDING	(1 << 14)
#define USB_CSR_CEL_ACTIVE	(1 << 13)
#define USB_CSR_CEL_ENA		(1 << 12)
#define USB_CSR_BUS_SUSPEND	(1 << 11)
#define USB_CSR_BUS_RST		(1 << 10)
#define USB_CSR_BUS_RST_PENDING	(1 <<  9)
#define USB_CSR_SOF_PENDING	(1 <<  8)
#define USB_CSR_ADDR_MATCH	(1 <<  7)
#define USB_CSR_ADDR(x)		((x) & 0x7f)

/* Action register */
#define USB_AR			4(USB_BASE)

#define USB_AR_CEL_RELEASE	(1 << 13)
#define USB_AR_BUS_RST_CLEAR	(1 <<  9)
#define USB_AR_SOF_CLEAR	(1 <<  8)

/* Event register */
#define USB_EVT			8(USB_BASE)

/* Endpoint CSR */
#define EP_CSR(n)		(1024 + (((n) & 0xf) << 6) + (((n) & 0x80) >> 2) + 0)(USB_BASE)

#define USB_EP_TYPE_NONE	0x0000
#define USB_EP_TYPE_ISOC	0x0001
#define USB_EP_TYPE_INT		0x0002
#define USB_EP_TYPE_BULK	0x0004
#define USB_EP_TYPE_CTRL	0x0006
#define USB_EP_TYPE_HALTED	0x0001
#define USB_EP_TYPE_IS_BCI(x)	(((x) & 6) != 0)
#define USB_EP_TYPE(x)		((x) & 7)
#define USB_EP_TYPE_MSK		0x0007

#define USB_EP_DT_BIT		0x0080
#define USB_EP_BD_IDX		0x0040
#define USB_EP_BD_CTRL		0x0020
#define USB_EP_BD_DUAL		0x0010

/* Endpoint Buffer Descriptor */
#define EP_BD_CSR(n,i)		(1024 + (((n) & 0xf) << 6) + (((n) & 0x80) >> 2) + 16 + ((i)*8) + 0)(USB_BASE)
#define EP_BD_PTR(n,i)		(1024 + (((n) & 0xf) << 6) + (((n) & 0x80) >> 2) + 16 + ((i)*8) + 4)(USB_BASE)

#define USB_BD_STATE_MSK	0xe000
#define USB_BD_STATE_NONE	0x0000
#define USB_BD_STATE_RDY_DATA	0x4000
#define USB_BD_STATE_RDY_STALL	0x6000
#define USB_BD_STATE_DONE_OK	0x8000
#define USB_BD_STATE_DONE_ERR	0xa000
#define USB_BD_IS_SETUP		0x1000

#define USB_BD_LEN(l)		((l) & 0x3ff)
#define USB_BD_LEN_MSK		0x03ff
