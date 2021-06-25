#!/usr/bin/env python3

import json
import os
import re
import struct
import sys

parse = re.compile('^([0-9a-f]{8})( [0-9a-f]{8})? [a-zA-Z] (.*)\n$')

sym_ofs = {}
sym_len = {}

for sym_line in sys.stdin.readlines():
	m = parse.match(sym_line)
	if not m:
		continue

	sym_ofs[m.group(3)] = int(m.group(1), 16)

	if m.group(2) is not None:
		sym_len[m.group(3)] = int(m.group(2), 16)


print(json.dumps({
	# Simple uint16_t
	'vid':			( sym_ofs['desc_dev']  +  8, 2 ),
	'pid':			( sym_ofs['desc_dev']  + 10, 2 ),

	# Zone to fill with \xff
	'dfu_disable':	( sym_ofs['desc_conf'] + 14, 3 ),

	# Offset/Length of str descriptor in tx buf
	# + Offset in rx buf of the 'len' in the desc table
	'serial':		( sym_ofs['desc_str1'], sym_len['desc_str1'], sym_ofs['desc_table'] + 8 * (3+1) + 2),
	'vendor':		( sym_ofs['desc_str2'], sym_len['desc_str2'], sym_ofs['desc_table'] + 8 * (3+2) + 2),
	'product':		( sym_ofs['desc_str3'], sym_len['desc_str3'], sym_ofs['desc_table'] + 8 * (3+3) + 2),
}))
