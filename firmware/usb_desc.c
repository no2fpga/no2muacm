/*
 * usb_desc.c
 *
 * USB descriptors
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */

#include <no2usb/usb_proto.h>
#include <no2usb/usb_cdc_proto.h>
#include <no2usb/usb_dfu_proto.h>
#include <no2usb/usb_msos20_proto.h>
#include <no2usb/usb.h>


/* Device Descriptor */

static const struct usb_dev_desc desc_dev __attribute__((section(".usb_txbuf.desc"))) = {
	.bLength		= sizeof(struct usb_dev_desc),
	.bDescriptorType	= USB_DT_DEV,
	.bcdUSB			= 0x0200,
	.bDeviceClass		= 0,
	.bDeviceSubClass	= 0,
	.bDeviceProtocol	= 0,
	.bMaxPacketSize0	= 64,
	.idVendor		= 0x1d50,
	.idProduct		= 0x6159,
	.bcdDevice		= 0x0001,	/* v0.1 */
	.iManufacturer		= 2,
	.iProduct		= 3,
	.iSerialNumber		= 1,
	.bNumConfigurations	= 1
};


/* Configuration Descriptor */

usb_cdc_union_desc_def(1);

static const struct {
	/* Configuration */
	struct usb_conf_desc conf;

	/* DFU Runtime */
	struct {
		struct usb_intf_desc intf;
		struct usb_dfu_func_desc func;
	} __attribute__ ((packed)) dfu;

	/* CDC */
	struct {
		struct usb_intf_desc intf_ctl;
		struct usb_cdc_hdr_desc cdc_hdr;
		struct usb_cdc_acm_desc cdc_acm;
		struct usb_cdc_union_desc__1 cdc_union;
		struct usb_ep_desc ep_ctl;
		struct usb_intf_desc intf_data;
		struct usb_ep_desc ep_data_out;
		struct usb_ep_desc ep_data_in;
	} __attribute__ ((packed)) cdc;
} __attribute__ ((packed)) desc_conf __attribute__((section(".usb_txbuf.desc"))) = {
	.conf = {
		.bLength                = sizeof(struct usb_conf_desc),
		.bDescriptorType        = USB_DT_CONF,
		.wTotalLength           = sizeof(desc_conf),
		.bNumInterfaces         = 3,
		.bConfigurationValue    = 1,
		.iConfiguration         = 0,
		.bmAttributes           = 0x80,
		.bMaxPower              = 0x32, /* 100 mA */
	},
	.dfu = {
		.intf = {
			.bLength		= sizeof(struct usb_intf_desc),
			.bDescriptorType	= USB_DT_INTF,
			.bInterfaceNumber	= 0,
			.bAlternateSetting	= 0,
			.bNumEndpoints		= 0,
			.bInterfaceClass	= 0xfe,
			.bInterfaceSubClass	= 0x01,
			.bInterfaceProtocol	= 0x01,
			.iInterface		= 4,
		},
		.func = {
			.bLength		= sizeof(struct usb_dfu_func_desc),
			.bDescriptorType	= USB_DFU_DT_FUNC,
			.bmAttributes		= 0x0d,
			.wDetachTimeOut		= 1000,
			.wTransferSize		= 4096,
			.bcdDFUVersion		= 0x0101,
		},
	},
	.cdc = {
		.intf_ctl = {
			.bLength		= sizeof(struct usb_intf_desc),
			.bDescriptorType	= USB_DT_INTF,
			.bInterfaceNumber	= 1,
			.bAlternateSetting	= 0,
			.bNumEndpoints		= 1,
			.bInterfaceClass	= USB_CLS_CDC_CONTROL,
			.bInterfaceSubClass	= USB_CDC_SCLS_ACM,
			.bInterfaceProtocol	= 0x00,
			.iInterface		= 0,
		},
		.cdc_hdr = {
			.bLength		= sizeof(struct usb_cdc_hdr_desc),
			.bDescriptorType	= USB_CS_DT_INTF,
			.bDescriptorsubtype	= USB_CDC_DST_HEADER,
			.bcdCDC			= 0x0110,
		},
		.cdc_acm = {
			.bLength		= sizeof(struct usb_cdc_acm_desc),
			.bDescriptorType	= USB_CS_DT_INTF,
			.bDescriptorsubtype	= USB_CDC_DST_ACM,
			.bmCapabilities		= 0x00,	/* Pure pipe, no control ... */
		},
		.cdc_union = {
			.bLength		= sizeof(struct usb_cdc_union_desc) + 1,
			.bDescriptorType	= USB_CS_DT_INTF,
			.bDescriptorsubtype	= USB_CDC_DST_UNION,
			.bMasterInterface	= 1,
			.bSlaveInterface	= { 2 },
		},
		.ep_ctl = {
			.bLength		= sizeof(struct usb_ep_desc),
			.bDescriptorType	= USB_DT_EP,
			.bEndpointAddress	= 0x83,
			.bmAttributes		= 0x03,
			.wMaxPacketSize		= 8,
			.bInterval		= 0x40,
		},
		.intf_data = {
			.bLength		= sizeof(struct usb_intf_desc),
			.bDescriptorType	= USB_DT_INTF,
			.bInterfaceNumber	= 2,
			.bAlternateSetting	= 0,
			.bNumEndpoints		= 2,
			.bInterfaceClass	= USB_CLS_CDC_DATA,
			.bInterfaceSubClass	= 0x00,
			.bInterfaceProtocol	= 0x00,
			.iInterface		= 0,
		},
		.ep_data_out = {
			.bLength		= sizeof(struct usb_ep_desc),
			.bDescriptorType	= USB_DT_EP,
			.bEndpointAddress	= 0x02,
			.bmAttributes		= 0x02,
			.wMaxPacketSize		= 64,
			.bInterval		= 0x00,
		},
		.ep_data_in = {
			.bLength		= sizeof(struct usb_ep_desc),
			.bDescriptorType	= USB_DT_EP,
			.bEndpointAddress	= 0x82,
			.bmAttributes		= 0x02,
			.wMaxPacketSize		= 64,
			.bInterval		= 0x00,
		},
	},
};


/* MSOS2.0 descriptor */

const struct {
	struct msos20_desc_set_hdr hdr;
	struct msos20_feat_compat_id_desc feat;
} __attribute__ ((packed)) desc_msos20 __attribute__((section(".usb_txbuf.desc"))) = {
	.hdr = {
		.wLength          = sizeof(struct msos20_desc_set_hdr),
		.wDescriptorType  = MSOS20_SET_HEADER_DESCRIPTOR,
		.dwWindowsVersion = MSOS20_WIN_VER_8_1,
		.wTotalLength     = sizeof(desc_msos20),
	},
	.feat = {
		.wLength          = sizeof(struct msos20_feat_compat_id_desc),
		.wDescriptorType  = MSOS20_FEATURE_COMPATBLE_ID,
		.CompatibleID     = { 'W', 'I', 'N', 'U', 'S', 'B', 0x00, 0x00 },
		.SubCompatibleID  = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
	},
};


/* BOS descriptor */

static const struct {
	struct usb_bos_desc bos;
	struct usb_bos_plat_cap_hdr cap_hdr;
	struct usb_bos_msos20_desc_set cap_data;
} __attribute__ ((packed)) desc_bos __attribute__((section(".usb_txbuf.desc"))) = {
	.bos = {
		.bLength                = sizeof(struct usb_bos_desc),
		.bDescriptorType        = USB_DT_BOS,
		.wTotalLength           = sizeof(desc_bos),
		.bNumDeviceCaps         = 1,
	},
	.cap_hdr = {
		.bLength                = sizeof(struct usb_bos_plat_cap_hdr) + 8,
		.bDescriptorType        = USB_DT_DEV_CAP,
		.bDevCapabilityType     = 5, /* PLATFORM */
		.bReserved              = 0,
		.PlatformCapabilityUUID = {
			0xdf, 0x60, 0xdd, 0xd8, 0x89, 0x45, 0xc7, 0x4c,
			0x9c, 0xd2, 0x65, 0x9d, 0x9e, 0x64, 0x8a, 0x9f,
		},
	},
	.cap_data = {
		.dwWindowsVersion              = MSOS20_WIN_VER_8_1,
		.wMSOSDescriptorSetTotalLength = sizeof(desc_msos20),
		.bMS_VendorCode                = MSOS20_MS_VENDOR_CODE,
		.bAltEnumCode                  = 0x00,
	},
};


/* String descriptors */

#define STR0_LEN (sizeof(struct usb_str_desc) + 2 * 1)
static const struct usb_str_desc desc_str0 __attribute__((section(".usb_txbuf.desc"))) = {
	.bLength		= STR0_LEN,
	.bDescriptorType	= USB_DT_STR,
	.wString		= { 0x0409 },
};

#define STR1_LEN (sizeof(struct usb_str_desc) + 2 * 16)
static const struct usb_str_desc desc_str1 __attribute__((section(".usb_txbuf.desc"))) = {
	.bLength		= STR1_LEN,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		'0', '0', '0', '0', '0', '0', '0', '0',
		'0', '0', '0', '0', '0', '0', '0', '0',
	},
};

#define STR2_LEN (sizeof(struct usb_str_desc) + 2 * 10)
static const struct usb_str_desc desc_str2 __attribute__((section(".usb_txbuf.desc"))) = {
	.bLength		= STR2_LEN,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		'N', 'i', 't', 'r', 'o', ' ', 'F', 'P', 'G', 'A', 0, 0, 0, 0, 0, 0,
	},
};

#define STR3_LEN (sizeof(struct usb_str_desc) + 2 * 4)
static const struct usb_str_desc desc_str3 __attribute__((section(".usb_txbuf.desc"))) = {
	.bLength		= STR3_LEN,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		0x03bc, 'a', 'c', 'm', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	},
};

#define STR4_LEN (sizeof(struct usb_str_desc) + 2 * 6)
static const struct usb_str_desc desc_str4 __attribute__((section(".usb_txbuf.desc"))) = {
	.bLength		= STR4_LEN,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		'D', 'F', 'U', ' ', 'r', 't',
	},
};


/* Descriptor table */
	/* Could be more compact (6 bytes per entry) but
	  .usb_rxbuf isn't nearly full so don't bother for now */
const struct {
	uint8_t     idx;
	uint8_t     type;
	uint16_t    len;
	const void *ptr;
} desc_table[] __attribute__((section(".usb_rxbuf.const"))) = {
	{ 0, USB_DT_DEV,  sizeof(desc_dev),  &desc_dev  },
	{ 0, USB_DT_CONF, sizeof(desc_conf), &desc_conf },
	{ 0, USB_DT_BOS,  sizeof(desc_bos),  &desc_bos  },
	{ 0, USB_DT_STR,  STR0_LEN,          &desc_str0 },
	{ 1, USB_DT_STR,  STR1_LEN,          &desc_str1 },
	{ 2, USB_DT_STR,  STR2_LEN,          &desc_str2 },
	{ 3, USB_DT_STR,  STR3_LEN,          &desc_str3 },
	{ 4, USB_DT_STR,  STR4_LEN,          &desc_str4 },
	{ 0, 0, 0, 0 },
};
