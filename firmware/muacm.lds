/*
 * muacm.S
 *
 * Linker script to generate the various Block RAM
 * init zones and associated cross references.
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    IROM      (rx) : ORIGIN = 0x00000000, LENGTH = 0x0400
    USB_RXBUF (r)  : ORIGIN = 0x00000000, LENGTH = 0x0200
    USB_TXBUF (r)  : ORIGIN = 0x00000000, LENGTH = 0x0200
    USB_EP    (r)  : ORIGIN = 0x00000000, LENGTH = 0x0200
    CPU_RF    (r)  : ORIGIN = 0x00000000, LENGTH = 0x0200
}

SECTIONS
{

    .text :
    {
        . = ALIGN(4);
        KEEP( *(.text.start) )
        KEEP( *(.text) )
        KEEP( *(.text*) )
    } > IROM

    .usb_rxbuf : AT ( 0x00040000 )
    {
        . = 0;
        KEEP( *(.usb_rxbuf.epbuf) )
        KEEP( *(.usb_rxbuf.const) )
    } > USB_RXBUF

    .usb_txbuf : AT ( 0x00050000 )
    {
        . = 0;
        KEEP( *(.usb_txbuf.epbuf) )
        KEEP( *(.usb_txbuf.desc) )
    } > USB_TXBUF

    .usb_ep : AT ( 0x00060000 )
    {
        . = 0;
        KEEP( *(.usb_ep) )
    } > USB_EP

    .cpu_rf : AT ( 0x00070000 )
    {
        . = 0;
        KEEP( *(.cpu_rf) )
    } > CPU_RF

}
