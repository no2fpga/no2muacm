PROJ := acm-loopback

BOARD   ?= bitsy-v1
PCF     := data/top-$(BOARD).pcf
DEVICE  := $(shell awk '/^\#\# dev:/{print $$3; exit 1}' $(PCF) && echo up5k)
PACKAGE := $(shell awk '/^\#\# pkg:/{print $$3; exit 1}' $(PCF) && echo sg48)

SRCS_acm-loopback = $(addprefix rtl/, \
	dfu_helper.v \
	sysmgr_hfosc.v \
	sysmgr_pll.v \
	top.v \
)
TOPMOD := top

MUACM_ILANG := ip/muacm.ilang

YOSYS    := yosys
NEXTPNR  := nextpnr-ice40
ICEPACK  := icepack
DFU_UTIL := dfu-util

SYNTH_ARGS :=
NEXTPNR_ARGS := --no-promote-globals --timing-allow-fail

all: $(PROJ).bin


%.json %.synth.log: $(MUACM_ILANG) $(SRCS_$(PROJ)) 
	$(YOSYS) -L $*.synth.log -p 'read_verilog $(SRCS_$(PROJ)); read_ilang $(MUACM_ILANG); synth_ice40 $(SYNTH_ARGS) -top $(TOPMOD) -json $*.json'

%.asc %.pnr.log: $(PCF) %.json
	$(NEXTPNR) $(NEXTPNR_ARGS) --$(DEVICE) --package $(PACKAGE) --json $*.json --pcf $(PCF) --log $*.pnr.log --asc $*.asc

%.bin: %.asc
	$(ICEPACK) -s $< $@

%.ilang: %.ilang.bz2
	bzcat $< > $@


prog: $(PROJ).bin
	$(DFU_UTIL) -a 0 -R -D $<

clean:
	rm -f *.json *.asc *.bin *.log

.PHONY: all clean
