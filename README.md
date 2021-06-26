Nitro μACM
==========

The Nitro μACM core is a small implementation of a USB CDC ACM device
entirely in FPGA fabric using only FPGA IOs (and an external 1.5kohm
resistor from the `usb_pu` to the USB DP line).

Features:

 - Entirely synchronous design, running in a single clock domain at 48 MHz
     - For convenience, a lightweight clock-domain crossing helper is provided
       in the `examples/` directory if your user logic needs to run at a
       different rate.

 - Simple data interface similar to AXI-stream (`data`/`last`/`valid`/`ready`)

 - Flexible packet flushing (on-demand, immediate, after-timeout) depending
   on your application requirements.

 - Exposes a DFU-Runtime interface to integrate nicely if you're using a DFU
   bootloader to configure your FPGA. 
     - This allows the host to programmatically request the reset of the fpga
       to its bootloader mode.
     - Includes all the requires `WinUSB` descriptors to work out-of-the-box
       under Win10+ without any user intervention configuring drivers.

 - Customizable descriptors (PID/VID/Strings/...)

 - Designed for easy "drop-in" integration
     - It generates a single source file you can use as a black box component
     - You can either build it yourself from this repo, or use the
       `no2muacm-bin` repository or one of the tagged release tarball.


Example:
--------

Refer to the `example/` directory to see how to use the core on some real boards.


Building:
---------

Currently the core is only setup for `iCE40` builds. Other FPGA targets will be
coming soon. Feel free to open an issue if you have a particular need.

To build the core you will need the corresponding OSS toolchain for your target
and a RISC-V compiler (default is using `riscv-none-embed-` prefix. Change with
`CROSS` environment variable).

```bash
$ cd gateware
$ make
```

This will create a `build/` directory with both a `muacm.v` and `muacm.ilang`
(select whichever you prefer) that you can integrate as a single source file
in your own project.

To integrate the core in your own project you can either:

 - Just add this pre-built source as-is in your project for minimum hassle.

 - Add this repository as a submodule and call the `make` step from your own
   build system.

 - Add the `no2muacm-bin` repository as a submodule which should always contain
   pre-built version of the latest release of this core.


Customization:
--------------

You can customize several aspects of this core. Some of them can even be
changed after synthesis in the pre-built core directly (useful if you plan
to use `no2muacm-bin` releases.

To customize prior to building, the most relevant file is `firmware/usb_desc.c`
which contains all the USB descriptors that will be included and should be
self-explanatory.

To customize the pre-built netlist, a special python tool called 
`muacm_customize.py` is provided in `utils/`. Refer to the `--help` to see
how to use it. This will allow direct patching of VID/PID/Strings inside
the netlist. Note that strings are limited to 16 chars in this case (since
space is pre-reserved during build).


Clocking:
---------

As mentionned in the "Features" above, the core runs entirely at 48 MHz.

The requirements on the clock are pretty wide, the USB specification only requires
it to be within 2500 ppm. And the clock-recovery mechanism used here is capable
of decoding packets with much wider clock range. For instance, this core has been
used sucessfully with the _iCE40_ `SB_HFOSC` which is 48 MHz +- 10%. YMMV though.


Data interface:
---------------

The data interface is synchronous to the clock of the μACM module
and is essentially a pair of AXI Streaming interfaces, one for
RX and one for TX.

 - `data` is the 8 bit data to/from the host

 - `last` is the packet delineation marker. For `out` (i.e. from host to
    FPGA) it indicates the USB packets boundary as received from the host.
    For `in`, it can be used to force sending short packets.

 - `valid` and `ready` are the handshake signals. Data transfer happens
   when both signals are high on the same cycle.

The `in` interface also has two additional control signals that are
independent from the streaming interface :

 - `in_flush_now`: Indicates that whatever pending data is still in buffers
   should be sent to the host ASAP.

 - `in_flush_time`: Indicates that any pending data can be sent to the host
   after some reasonable timeout (to avoid data staying in buffer waiting to
   fill a full USB packet).


License
-------

See LICENSE.md for the licenses of the various components in this repository

In short, the build product of this repository can be considered to be
CERN-OHL-P-2.0 (gateware) / MIT (firmware) with needing attribution to:

 - Nitro FPGA project ( Sylvain Munaut - https://github.com/no2fpga/ )
 - SERV ( Olof Kindgren - https://github.com/olofk/serv )
