# Sources
SRCS_SERV = $(abspath $(addprefix cores/serv/rtl/, \
	serv_alu.v \
	serv_bufreg.v \
	serv_csr.v \
	serv_ctrl.v \
	serv_decode.v \
	serv_immdec.v \
	serv_mem_if.v \
	serv_rf_top.v \
	serv_rf_ram.v \
	serv_rf_ram_if.v \
	serv_rf_if.v \
	serv_state.v  \
	serv_top.v \
))

SRCS_NO2USB = $(abspath $(addprefix cores/no2usb/rtl/, \
	usb_crc.v \
	usb_ep_buf.v \
	usb_ep_status.v \
	usb_phy.v \
	usb_rx_ll.v \
	usb_rx_pkt.v \
	usb_trans.v \
	usb_tx_ll.v \
	usb_tx_pkt.v \
	usb.v \
))

SRCS_NO2ICE40 = $(abspath $(addprefix cores/no2ice40/rtl/, \
	ice40_ebr.v \
))

SRCS_MUACM = $(abspath $(addprefix rtl/, \
	extif.v \
	irom.v \
	wb_epbuf.v \
	muacm.v \
))

AUX_DATA = $(addprefix $(OUT_DIR)/, \
	cpu_rf.hex \
	text.hex \
	usb_ep.hex \
	usb_rxbuf.hex \
	usb_txbuf.hex \
	usb_trans_mc.hex \
	meta.json \
)

# Build config / tgt
OUT_DIR := ../build

all: $(OUT_DIR)/muacm.ilang $(OUT_DIR)/muacm.v
sim: $(OUT_DIR)/muacm_tb

# Dependencies
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(AUX_DATA):
	make -C ../firmware $@

$(OUT_DIR)/usb_trans_mc.hex: ./cores/no2usb/utils/microcode.py
	./cores/no2usb/utils/microcode.py mini > $@

# Pre-built core
$(OUT_DIR)/muacm.ilang $(OUT_DIR)/muacm.v: $(OUT_DIR) $(AUX_DATA) $(SRCS_SERV) $(SRCS_NO2USB) $(SRCS_NO2ICE40) $(SRCS_MUACM)
	cd ../build && \
	yosys \
		-L $(OUT_DIR)/synth.log \
		-p 'read_verilog -DSERV_INIT_RAM="cpu_rf.hex" -I../build $(SRCS_SERV) $(SRCS_NO2USB) $(SRCS_NO2ICE40) $(SRCS_MUACM); synth_ice40 -abc2 -top muacm; write_ilang $(OUT_DIR)/muacm.ilang; write_verilog $(OUT_DIR)/muacm.v'
	echo "# META: $$(cat $(OUT_DIR)/meta.json)" >> $(OUT_DIR)/muacm.ilang
	echo "/* META: $$(cat $(OUT_DIR)/meta.json) */" >> $(OUT_DIR)/muacm.v

# Test bench
$(OUT_DIR)/%_tb: $(OUT_DIR) $(AUX_DATA) $(SRCS_SERV) $(SRCS_NO2USB) $(SRCS_NO2ICE40) $(SRCS_MUACM) sim/%_tb.v
	iverilog \
		-DNO_ICE40_DEFAULT_ASSIGNMENTS \
		-DSIM -DSERV_INIT_RAM=\"cpu_rf.hex\" \
		-DSIM_TRACE \
		-o $@ \
		-s $*_tb \
		-Icores/no2usb/rtl/ \
		`yosys-config --datdir/ice40/cells_sim.v` \
		$(SRCS_SERV) \
		$(SRCS_NO2USB) \
		$(SRCS_NO2ICE40) \
		$(SRCS_MUACM) \
		sim/$*_tb.v

clean:
	rm -f $(OUT_DIR)/muacm.ilang $(OUT_DIR)/muacm.v $(OUT_DIR)/muacm_tb $(OUT_DIR)/synth.log
	make -C ../firmware clean

.PHONY: clean
