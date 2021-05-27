#!/usr/bin/env python3

#
# bin2hex.py
#
# Utility to convert a binary into a HEX init file that can be
# used to init Block RAM with $readmemh. It also includes required
# width conversion and bit shuffling for various modes used in this
# project
#
# Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
# SPDX-License-Identifier: MIT
#

import struct
import sys


def process_32(out_fh, in_fh):
	b = in_fh.read(4)
	if len(b) < 4:
		return False
	out_fh.write('%08x\n' % struct.unpack('<I', b))
	return True


def process_16(out_fh, in_fh):
	b = in_fh.read(2)
	if len(b) < 2:
		return False
	out_fh.write('%04x\n' % struct.unpack('<H', b))
	return True


def process_16s(out_fh, in_fh):
	SEQ = [
		15, 7, 11, 3, 13, 5, 9, 1,
		14, 6, 10, 2, 12, 4, 8, 0
	]

	b = in_fh.read(2)
	if len(b) < 2:
		return False
	b = struct.unpack('<H', b)[0]
	b = sum([ ((b>>(15-i))&1) << j for i,j in enumerate(SEQ)])
	out_fh.write('%04x\n' % b)
	return True


def process_32_16(out_fh, in_fh):
	b = in_fh.read(4)
	if len(b) < 4:
		return False
	out_fh.write('%04x\n' % (struct.unpack('<I', b)[0] & 0xffff) )
	return True


def process_rf(out_fh, in_fh):
	b = in_fh.read(4)
	if len(b) < 4:
		return False
	b = struct.unpack('<I', b)[0]
	for i in range(16):
		out_fh.write('%01x\n' % (b & 3))
		b >>= 2
	return True


def main(argv0, in_name, out_name, mode="32"):
	PFN = {
		'32': process_32,
		'16': process_16,
		'16s': process_16s,
		'32:16': process_32_16,
		'rf': process_rf,
	}

	with open(in_name, 'rb') as in_fh, open(out_name, 'w') as out_fh:
		while PFN[mode](out_fh, in_fh):
			pass


if __name__ == '__main__':
	main(*sys.argv)
