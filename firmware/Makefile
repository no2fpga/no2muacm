CROSS ?= riscv-none-embed-
CC = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy
CFLAGS=-Wall -Os -march=rv32i -mabi=ilp32 -ffreestanding -nostartfiles --specs=nano.specs -mno-relax -I.

OUT_DIR=../build

SRCS = \
	main.S \
	cpu_rf.S \
	usb_ep.S \
	usb_rxbuf.S \
	usb_txbuf.S \
	usb_desc.c \
	$(NULL)

TARGETS = $(addprefix $(OUT_DIR)/, \
	text.hex \
	usb_txbuf.hex \
	usb_rxbuf.hex \
	usb_ep.hex \
	cpu_rf.hex \
)


all: $(OUT_DIR) $(TARGETS)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)


# Main firmware build

main.elf: muacm.lds $(SRCS)
	$(CC) $(CFLAGS) -Wl,-Bstatic,-T,muacm.lds,--strip-debug -o $@ -I../gateware/cores/no2usb/fw/v0/include $(SRCS)

main.%.bin: main.elf
	$(OBJCOPY) -O binary -j .$* $< $@


# Format to .hex depending on the BRAM geometry

$(OUT_DIR)/text.hex: main.text.bin
	./bin2hex.py $< $@ 32

$(OUT_DIR)/usb_txbuf.hex: main.usb_txbuf.bin
	./bin2hex.py $< $@ 16s

$(OUT_DIR)/usb_rxbuf.hex: main.usb_rxbuf.bin
	./bin2hex.py $< $@ 16s

$(OUT_DIR)/usb_ep.hex: main.usb_ep.bin
	./bin2hex.py $< $@ 32:16

$(OUT_DIR)/cpu_rf.hex: main.cpu_rf.bin
	./bin2hex.py $< $@ rf


# Cleanup

clean:
	rm -f *.elf *.bin $(OUT_DIR)/*.hex

.PHONY: clean
