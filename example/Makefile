PROJ := acm-loopback

BOARD   ?= bitsy-v1
DEVICE  := up5k
PACKAGE := sg48

SRCS_acm-loopback = $(addprefix rtl/, \
	dfu_helper.v \
	sysmgr_hfosc.v \
	sysmgr_pll.v \
	top.v \
)
PCF := data/top-$(BOARD).pcf
TOPMOD := top

MUACM_ILANG := ../build/muacm.ilang

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


prog: $(PROJ).bin
	$(DFU_UTIL) -a 0 -R -D $<

clean:
	rm -f *.json *.asc *.bin *.log

.PHONY: all clean
