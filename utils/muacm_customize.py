#!/usr/bin/env python3

import argparse
import json
import re
import struct
import sys


class MuAcmPatcher:

	def __init__(self):
		self.fmt = None
		self.lines = []
		self.meta = {}
		self.data_tx = None
		self.lidx_tx = None
		self.data_rx = None
		self.lidx_rx = None

	def _unmix(self, v):
		s = [0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15]
		return sum([(1 << i) if v & (1 << s[i]) else 0 for i in range(16)])

	def _mix(self, v):
		s = [0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15]
		return sum([(1 << s[i]) if v & (1 << i) else 0 for i in range(16)])

	def _dat_from_bin(self, bin_val):
		return b''.join([struct.pack('<H', self._unmix(int(bin_val[240-i:256-i],2))) for i in range(0,256,16)])

	def _dat_to_bin(self, data):
		return ''.join(reversed([f'{self._mix(v):016b}' for v in struct.unpack('<16H', data)]))

	def _dat_from_hex(self, bin_val):
		return b''.join([struct.pack('<H', self._unmix(int(bin_val[60-i:64-i],16))) for i in range(0,64,4)])

	def _dat_to_hex(self, data):
		return ''.join(reversed([f'{self._mix(v):04x}' for v in struct.unpack('<16H', data)]))

	def _load_data(self, cell_name):
		# Find INIT[0-F]
		armed   = False

		if self.fmt == 'ilang':
			re_ram  = re.compile('\s*cell \\\\SB_RAM40_4K .*%s.*' % (cell_name,))
			re_init = re.compile('\s*parameter \\\\INIT_([0-9A-F]) 256\'([01]{256})')
			conv = self._dat_from_bin

		elif self.fmt == 'verilog':
			re_ram  = re.compile('\s*\(\* hdlname = ".*%s.*ebr_I" \*\)' % (cell_name,))
			re_init = re.compile('\s*\.INIT_([0-9A-F])\(256\'h([0-9a-f]{64})\),')
			conv = self._dat_from_hex

		data = bytearray()
		lidx = []

		for i, l in enumerate(self.lines):
			if not armed:
				# Look for the right cell
				if re_ram.match(l):
					armed = True
					continue
			else:
				m = re_init.match(l)
				if m:
					# Get data and validata
					if int(m.group(1), 16) != len(lidx):
						raise RuntimeError('Error in parsing source file init lines')

					lidx.append(i)
					data += conv(m.group(2))

					if len(lidx) == 16:
						break

		if len(data) != 512:
			raise RuntimeError('Error in parsing source file data block')

		return data, lidx

	def _update_data(self, data, lidx):
		if self.fmt == 'ilang':
			re_init = re.compile('[01]{256}')
			conv = self._dat_to_bin

		elif self.fmt == 'verilog':
			re_init = re.compile('[0-9a-f]{64}')
			conv = self._dat_to_hex

		for i in range(16):
			l = lidx[i]
			o = i * 32
			self.lines[l] = re_init.sub(conv(data[o:o+32]), self.lines[l])

	def load(self, filename):
		# Format detect
		if filename.endswith('ilang'):
			self.fmt = 'ilang'
		else:
			self.fmt = 'verilog'

		# Load the file
		with open(filename, 'r') as fh:
			self.lines = fh.readlines()

		# Load meta data
		m = re.match('.*META: ({.*}).*', self.lines[-1])
		if not m:
			raise RuntimeError('Error in parsing source file meta block')
		self.meta = json.loads(m.group(1))

		# Load data from rxbuf and txbuf
		self.data_rx, self.lidx_rx = self._load_data('rx_buf_I')
		self.data_tx, self.lidx_tx = self._load_data('tx_buf_I')

	def save(self, filename):
		# Regenerate INIT lines
		self._update_data(self.data_rx, self.lidx_rx)
		self._update_data(self.data_tx, self.lidx_tx)

		# Write
		with open(filename, 'w') as fh:
			fh.write(''.join(self.lines))

	def set_vid(self, vid):
		struct.pack_into('<H', self.data_tx, self.meta['vid'][0], vid)

	def set_pid(self, pid):
		struct.pack_into('<H', self.data_tx, self.meta['pid'][0], pid)

	def disable_dfu_rt(self):
		for i in range(self.meta['dfu_disable'][1]):
			self.data_tx[self.meta['dfu_disable'][0] + i] = 255

	def _patch_string_desc(self, meta_name, new_str):
		desc_ofs = self.meta[meta_name][0]	# Offset of descriptor in tx_buf
		desc_len = self.meta[meta_name][1]	# Max Length of descriptor in tx_buf
		dtl_ofs  = self.meta[meta_name][2]	# Offset of 'length' in the 'desc_table'
		max_str_len = (desc_len - 2) // 2

		if len(new_str) > max_str_len:
			raise RuntimeError('New string length is too long. Max is %d' % (max_str_len,))

		self.data_rx[dtl_ofs]  = 2 + len(new_str) * 2
		self.data_tx[desc_ofs] = 2 + len(new_str) * 2

		for i, b in enumerate(new_str.encode('utf-16le')):
			self.data_tx[desc_ofs + 2 + i] = b

	def set_vendor(self, vendor):
		self._patch_string_desc('vendor', vendor)

	def set_product(self, product):
		self._patch_string_desc('product', product)

	def set_serial(self, serial):
		self._patch_string_desc('serial', serial)


def main(argv0, *args):

	parser = argparse.ArgumentParser()
	parser.add_argument("-i", "--input",  help="Input file (.ilang or .v)")
	parser.add_argument("-o", "--output", help="Outpu file")
	parser.add_argument("--vid",          help="New Vendor ID (as hex)")
	parser.add_argument("--pid",          help="New Product ID (as hex)")
	parser.add_argument("--vendor",       help="New Vendor String")
	parser.add_argument("--product",      help="New Product String")
	parser.add_argument("--serial",       help="New Serial String")
	parser.add_argument("--no-dfu-rt",    help="Disable the DFU runtime support", default=False, action="store_true")

	args = parser.parse_args()

	sf = MuAcmPatcher()
	sf.load(args.input)

	if args.vid:
		sf.set_vid(int(args.vid, 16))

	if args.pid:
		sf.set_pid(int(args.pid, 16))

	if args.vendor:
		sf.set_vendor(args.vendor)

	if args.product:
		sf.set_product(args.product)

	if args.serial:
		sf.set_serial(args.serial)

	if args.no_dfu_rt:
		sf.disable_dfu_rt()

	sf.save(args.output)


if __name__ == '__main__':
	main(*sys.argv)
