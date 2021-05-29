/*
 * main.S
 *
 * Main firmware source code
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */

#include "usb_hw.h"


	/*
	 * Common Register usage:
	 *
	 *  x0  - zero
	 *  x1  - Task 0 PC
	 *  x2  - Task 1 PC
	 *  x3  - Task 2 PC
	 *  x4  - USB frame tick timeout counter
	 *  x5  - ?
	 *  x6  - ?
	 *  x7  - ?
	 */

	.section .text
	.global _start

_start:
	// Global hardware init

		// Reset EPs buffer descriptors CSRs
#if 0
	sw	zero, EP_BD_CSR(0x00, 0) // EP 0 OUT DATA
	sw	zero, EP_BD_CSR(0x00, 1) // EP 0 OUT SETUP
	sw	zero, EP_BD_CSR(0x80, 0) // EP 0 IN
	sw	zero, EP_BD_CSR(0x02, 0) // EP 2 OUT 0
	sw	zero, EP_BD_CSR(0x02, 1) // EP 2 OUT 1
	sw	zero, EP_BD_CSR(0x82, 0) // EP 2 IN 0
	sw	zero, EP_BD_CSR(0x82, 1) // EP 2 IN 1
#else
	addi	x8, USB_BASE, 0x0400	// EP_CSR base
	addi	x9, x8, 4*2*32		// Total size (Only do 4 EPs)
1:
	sw	zero, 16(x8)		// BD[0].csr
	sw	zero, 24(x8)		// BD[1].csr
	addi	x8, x8, 32
	bne	x8, x9, 1b
#endif

		// Start core
	li	x8, USB_CSR_PU_ENA | USB_CSR_CEL_ENA
	sw	x8, USB_CSR

		// Wait for reset to not be active
1:
	lw	x8, USB_CSR
	andi	x8, x8, USB_CSR_BUS_RST
	bne	x8, zero, 1b

		// Clear any pending status
	li	x8, USB_AR_CEL_RELEASE | USB_AR_BUS_RST_CLEAR | USB_AR_SOF_CLEAR
	sw	x8, USB_AR

	// Init tasks
	li	x1, %lo(_task0_start)

	lui	x2, %hi(1 << 30)
	addi	x2, x2, %lo(_task1_start)

	lui	x3, %hi(2 << 30)
	addi	x3, x3, %lo(_task2_start)


/* ------------------------------------------------------------------------
   Task 0: USB Control (Events + EP0)
   ------------------------------------------------------------------------ */

/* Task 0 Register usage:
 *
 * x8  - General purpose temp register
 * x9  - General purpose temp register
 *
 * x12 - SETUP wRequestAndType
 * x13 - SETUP wValue
 * x14 - SETUP wIndex
 * x15 - SETUP wLength
 *
 * x16 - Response: Current pointer to data (in txbuf)
 * x17 - Response: Remaining length
 * x18 - Response: Chunk length
 * x19 - Response: Completion callback
 *
 * x30 - Constant: EP buffer base address
 */

#define	yield	jalr x1, x2

_task0_start:

	// Setup EP0 BD CSR to RX of SETUP
	li	x8, USB_BD_STATE_RDY_DATA | USB_BD_LEN(64)
	sw	x8, EP_BD_CSR(0x00, 1)	// EP 0 OUT SETUP

	// Wait for something
_task0_loop:
	jal	x1, 1f			// Set x1
1:
	//j	_task0_common_loop	// (No need for jump, it's right below ...)


/*
 * Common part of the task0 wait loops
 * Must be called using:
 *  jal x1, _task0_common_loop
 * So that the task PC is set to properly
 */
_task0_common_loop:
	// Load CSR
	lw	x8, USB_CSR

	// Check for pending reset
	andi	x9, x8, USB_CSR_BUS_RST
	bne	x9, zero, _start

	// Check for pending SOF
	andi	x9, x8, USB_CSR_SOF_PENDING
	beq	x9, zero, 1f

	// If so, increment frame tick and clear event
	addi	x4, x4, 1
	li	x8, USB_AR_SOF_CLEAR
	sw	x8, USB_AR

1:
	// Check SETUP
	// (uses sign extension of 'lh' to check MSB of CSR to know if buffer is done)
	lh	x8, EP_BD_CSR(0x00, 1)
	blt	x8, zero, _task0_do_setup

	// Hand-over to next task
	// (don't use 'yield' macro since caller already set x1)
	jr	x2


/*
 * SETUP received handler
 */
_task0_do_setup:
	// Load the entire SETUP packet in x12-x15
	lhu	x12, %lo(ep0_rx_setup + 0)(x30)	// offsetof(struct usb_ctrl_req, wRequestAndType)
	lhu	x13, %lo(ep0_rx_setup + 2)(x30)	// offsetof(struct usb_ctrl_req, wValue)
	lhu	x14, %lo(ep0_rx_setup + 4)(x30)	// offsetof(struct usb_ctrl_req, wIndex)
	lhu	x15, %lo(ep0_rx_setup + 6)(x30)	// offsetof(struct usb_ctrl_req, wLength)

	// Reset BDs
	//  - EP0 OUT SETUP : Re-arm for 64 byte RX
	//  - EP0 OUT DATA  : BD disabled
	//  - EP0 IN        : BD disabled
	li	x8, USB_BD_STATE_RDY_DATA | USB_BD_LEN(64)
	sw	x8,   EP_BD_CSR(0x00, 1)	// EP 0 OUT SETUP
	sw	zero, EP_BD_CSR(0x00, 0)	// EP 0 OUT DATA
	sw	zero, EP_BD_CSR(0x80, 0)	// EP 0 IN

	// Release CEL
	li	x8, USB_AR_CEL_RELEASE
	sw	x8, USB_AR

	// Default is no completion handler
	li	x19, %lo(_task0_loop)

	// Find handler
	addi	x8, x30, %lo(_task0_handlers)
1:
	lhu	x9, 2(x8)			// Request/Type
	addi	x8, x8, 4
	beq	x9, zero, _task0_resp_stall	// 0x0000 = end marker (not a valid reqtype)
	bne	x9, x12, 1b

	// Call handler
	lhu	x8, -4(x8)			// Function pointer
	jr	x8


/*
 * Data has been prepared and must be sent to the host, possibly
 * using multiple packets and possibly using a ZLP to notify the
 * end
 */
_task0_resp_data:
	// Sets CSR to ensure DT=1
	li	x8, USB_EP_TYPE_CTRL | USB_EP_DT_BIT
	sw	x8, EP_CSR(0x80)

	// Limit size to wLength
	bge	x15, x17, _task0_resp_data_nxt_pkt
	mv	x17, x15

_task0_resp_data_nxt_pkt:
	// Size of this chunk
	li	x18, 64
	bge	x17, x18, 1f
	mv	x18, x17
1:

	// Setup BD (setup pointer first !)
	sw	x16, EP_BD_PTR(0x80, 0)		// EP 0 IN

	li	x8, USB_BD_STATE_RDY_DATA
	or	x8, x8, x18
	sw	x8, EP_BD_CSR(0x80, 0)		// EP 0 IN

	// Wait for TX success (or abort through incoming SETUP)
1:
		// Common wait loop part
	jal x1, _task0_common_loop

		// Check BD
		// (uses sign extension of 'lh' to check MSB of CSR to know if buffer is done)
	lh	x8, EP_BD_CSR(0x80, 0)
	bge	x8, zero, 1b

	// Next chunk
	add	x16, x16, x18
	addi	x17, x17, -64
	bge	x17, zero, _task0_resp_data_nxt_pkt	// If >= 0, work left to do

	// Status stage, accept one OUT ZLP
	li	x8, USB_BD_STATE_RDY_DATA | USB_BD_LEN(0)
	sw	x8, EP_BD_CSR(0x00, 0)		// EP 0 OUT

	// We're done
	// (either we get rx success and we don't really need to do
	//  anything, or we get a setup packet, so might as well return
	//  to the main loop)
	j	_task0_loop


/*
 * Sends a ZLP through IN endpoint with DT=1
 */
_task0_resp_nodata:
	// Sets CSR to ensure DT=1
	li	x8, USB_EP_TYPE_CTRL | USB_EP_DT_BIT
	sw	x8, EP_CSR(0x80)

	// Set BD for ZLP
	li	x8, USB_BD_STATE_RDY_DATA | USB_BD_LEN(0)
	sw	x8, EP_BD_CSR(0x80, 0)		// EP 0 IN

	// Wait for TX success (or abort through incoming SETUP)
	// (for most requests, we could just go to _task0_loop directly,
	//  but for SET_ADDRESS we need to wait and setup address
	//  filtering _after_ the status stage ...)
1:
	jal x1, _task0_common_loop

		// Check BD
		// (uses sign extension of 'lh' to check MSB of CSR to know if buffer is done)
	lh	x8, EP_BD_CSR(0x80, 0)
	bge	x8, zero, 1b

	// Done, call completion handler
	jr	x19


/*
 * Continuously sends STALL to all IN/OUT requests until the next
 * setup packet
 */
_task0_resp_stall:
	// Common wait loop part
	jal x1, _task0_common_loop

	// Update BDs
	// (faster to rewrite them in all cases ...)
	li	x8, USB_BD_STATE_RDY_STALL
	sw	x8, EP_BD_CSR(0x00, 0)		// EP 0 OUT DATA
	sw	x8, EP_BD_CSR(0x80, 0)		// EP 0 IN

	// And again
	j	_task0_resp_stall


/*
 * Control request handlers
 */

  /* GET_STATUS: Always return { 0x00, 0x00 } */
_task0_h_get_status:
	// Setup response
	sw	zero, %lo(ep0_tx)(x30)

	li	x16, %lo(ep0_tx)
	li	x17, 2

	// Return
	j	_task0_resp_data

 /* SET_ADDRESS: Need to enable address filtering _after_ the status stage ! */
_task0_h_set_address:
	// No data, but we have a completion handler
	jal	x19, _task0_resp_nodata

	// Setup address filtering
	li	x8, USB_CSR_PU_ENA | USB_CSR_CEL_ENA | USB_CSR_ADDR_MATCH
	andi	x13, x13, 0x7f	// Safety
	add	x8, x8, x13
	sw	x8, USB_CSR

	// Done
	j	_task0_loop

 /* GET_DESCRIPTOR: Lookup in 'desc_table' */
_task0_h_get_descriptor:
	// Find matching descriptor
	addi	x8, x30, %lo(desc_table)
1:
	lhu	x9, 0(x8)			// [ type:index ]
	addi	x8, x8, 8
	beq	x9, zero, _task0_resp_stall	// 0x0000 = end marker (not a valid desc type)
	bne	x9, x13, 1b

	// Setup response
	lhu	x16, -4(x8)
	lhu	x17, -6(x8)

	// Return
	j	_task0_resp_data

 /* GET_CONFIGURATION: FIXME */
_task0_h_get_configuration:
	// Return
	//j	_task0_resp_data
	j	_task0_resp_stall

 /* SET_CONFIGURATION: FIXME */
_task0_h_set_configuration:
	// Return
	j	_task0_resp_nodata

 /* GET_INTERFACE: Always return { 0x00 } since we have no alt interface */
_task0_h_get_interface:
	// Setup response
	sw	zero, %lo(ep0_tx)(x30)

	li	x16, %lo(ep0_tx)
	li	x17, 1

	// Return
	j	_task0_resp_data

 /* SET_INTERFACE: Since we have no alt interface, we can STALL */
 _task0_h_set_interface:
 	// Return
	j	_task0_resp_stall

 /* Microsoft OS 2.0 Descriptors support */
_task0_h_msos20:
	// Check wIndex == MSOS20_DESCRIPTOR_INDEX
	li	x8, 0x07
	bne	x8, x14, _task0_resp_stall

	// Setup response
	li	x16, %lo(desc_msos20)
	lhu	x17, (%lo(desc_msos20)+8)(x30)

	// Return
	j	_task0_resp_data

 /* DFU_DETACH (only required request for runtime mode) */
_task0_h_dfu_detach:
	// No data, but we have a completion handler
	jal	x19, _task0_resp_nodata

	// Trigger reboots
	li	x8, 0x1000
	sw	zero, 0(x8)

	// Done
	j	_task0_loop


/*
 * Control request handler table
 *  [31:16] is the wRequestType 16 bits to match against
 *  [15: 0] is the function pointer to handler
 */
	.section .usb_rxbuf.const, "a"
_task0_handlers:
	.word	_task0_h_get_status		+ 0x00800000	// Dev
	.word	_task0_h_get_status		+ 0x00810000	// Intf
	.word	_task0_h_get_status		+ 0x00820000	// EP
	.word	_task0_h_set_address		+ 0x05000000
	.word	_task0_h_get_descriptor		+ 0x06800000
	.word	_task0_h_get_configuration	+ 0x08800000
	.word	_task0_h_set_configuration	+ 0x09000000
	.word	_task0_h_get_interface		+ 0x0a810000
	.word	_task0_h_set_interface		+ 0x0b010000
	.word	_task0_h_msos20			+ 0xc04d0000
	.word	_task0_h_dfu_detach		+ 0x00210000
	.section .text

#undef yield


/* ------------------------------------------------------------------------
   Task 1: USB CDC Data EP2 OUT
   ------------------------------------------------------------------------ */

/* Task 1 Register usage:
 *
 * x8  - General purpose temp register
 * x9  - General purpose temp register
 *
 * x16 - Pointer to current buffer descriptor CSR
 *
 * x29 - Constant: ExtIF base address
 */

#define	yield	jalr x2, x3

_task1_start:
	// Init vars
	li	x29, 0x1000		// ExtIF base
	li	x16, 0x490		// EP_BD_CSR(0x02,0) = Current BD

	// Submit two BD as part of init
	li	x8, USB_BD_STATE_RDY_DATA | USB_BD_LEN(64)
	sw	x8, EP_BD_CSR(0x02, 0)
	sw	x8, EP_BD_CSR(0x02, 1)

_task1_loop:
	// Wait for BD to be filled
1:
	yield

	lh	x8, 0(x16)
	bge	x8, zero, 1b

	// Submit this to ExtIF OUT
	andi	x8, x8, 0x3ff		// Keep length only
	addi	x8, x8, -2		// Remove CRC len
	beq	x8, zero, 2f		// Check it's not ZLP
	addi	x8, x8, -1		// Remove 1 since ExtIF.OUT is (len-1)
	lh	x9, 4(x16)		// Grab pointer
	or	x8, x8, x9		// Combine length with pointer
	sw	x8, 12(x29)		// Send to ExtIF.OUT

	// Wait for ExtIF OUT to be done
1:
	yield

	lb	x8, 4(x29)
	blt	x8, zero, 1b

	// Resubmit this buffer
2:
	li	x8, USB_BD_STATE_RDY_DATA | USB_BD_LEN(64)
	sw	x8, 0(x16)

	// Next BD
	xori	x16, x16, 0x0008

	// Loop
	j	_task1_loop

#undef yield


/* ------------------------------------------------------------------------
   Task 2: USB CDC Data EP2 IN
   ------------------------------------------------------------------------ */

/* Task 2 Register usage:
 *
 * x8  - General purpose temp register
 * x9  - General purpose temp register
 * x10 - General purpose temp register
 *
 * x16 - Pointer to current buffer descriptor CSR
 *
 * x28 - Constant: 64
 * x29 - Constant: ExtIF base address
 */

#define	yield	jalr x3, x1

_task2_start:
	// Init vars
	li	x28, 64
	li	x29, 0x1000		// ExtIF base
	li	x16, 0x4b0		// EP_BD_CSR(0x82,0) = Current BD

_task2_loop:
	// Wait for BD to be NONE or DONE
1:
	yield

	lh	x8, 0(x16)
	andi	x8, x8, -2048		// Mask out 'len'
	blt	zero, x8, 1b

	// Submit this buffer to ExtIF IN
	lh	x8, 4(x16)		// Grab pointer
	sw	x8, 8(x29)		// Send to ExtIF.IN

	// Re-enable ExtIF in case we disabled it
	li	x8, 1
	sw	x8, 4(x29)

	// Wait for either :
	//  - Timeout if "Flush by timeout" is enabled
	//  - "Flush Now" signal
	//  - IN byte count to be full
1:
	yield

	lbu	x8, 4(x29)		// Grab CSR[7:0]  == Flags
	lbu	x9, 5(x29)		// Grab CSR[15:8] == IN byte count

	bne	x9, x28, 2f		// Check if empty
	li	x4, -5			// Reset timeout counter if it is
	j	1b
2:

	blt	x9, x28, 3f		// Check if full or early ended

	andi	x10, x8, 1<<5		// Check "Flush Now"
	bne	x10, zero, 3f

	andi	x10, x8, 1<<4		// Check "Flush Timeout"
	beq	x10, zero, 1b

	blt	x4, zero, 1b		// If timeout counter is still < 0, don't flush yet

	// This is an early flush, disable ExtIF to avoid race conditions
	// and reload the current length
	sw	zero, 4(x29)
	lbu	x9, 5(x29)		// Grab CSR[15:8] == IN byte count

	// Submit BD to USB core
3:
	addi	x9, x9, -1
	andi	x9, x9, 63
	addi	x9, x9, 1

	li	x8, USB_BD_STATE_RDY_DATA
	or	x8, x8, x9
	sw	x8, 0(x16)

	// Next BD
	xori	x16, x16, 0x0008

	// Loop
	j	_task2_loop

#undef yield
