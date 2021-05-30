PROJ := acm-loopback

BOARD   ?= bitsy-v1
PCF     := data/top-$(BOARD).pcf

H := \#
DEVICE  := $(shell awk '/$(H)$(H) dev:/{print $$3; exit 1}' $(PCF) && echo up5k)
PACKAGE := $(shell awk '/$(H)$(H) pkg:/{print $$3; exit 1}' $(PCF) && echo sg48)

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

BOARD_DEFINE := BOARD_$(shell echo $(BOARD) | tr a-z\- A-Z_)
YOSYS_READ_ARGS  := -D$(BOARD_DEFINE)=1
YOSYS_SYNTH_ARGS :=
NEXTPNR_ARGS := --no-promote-globals

all: $(PROJ).bin


%.json %.synth.log: $(MUACM_ILANG) $(SRCS_$(PROJ))
	$(YOSYS) -L $*.synth.log -p 'read_verilog $(YOSYS_READ_ARGS) $(SRCS_$(PROJ)); read_ilang $(MUACM_ILANG); synth_ice40 $(YOSYS_SYNTH_ARGS) -top $(TOPMOD) -json $*.json'

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
.PRECIOUS: %.ilang %.json %.asc %.bin
