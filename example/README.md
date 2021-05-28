Nitro μACM Example skeleton project
===================================

This project is a small skeleton example of using the Nitro μACM
as a pre-built module. You can use it as a base skeleton for your
own project.


Project infos:
--------------

The project is about as simple as it gets, it just loops back any
data received back to the host.

It just instanciates the `muacm` pre-built module, feeds the
required 48 MHz clock in and associated reset signal and wires
up the USB signals to the right pads.

There are two options that can be enabled / disabled with defines
at the beginning of `top.v` :

 - `WITH_BUTTON`: This makes uses of a small `dfu_helper.v` block
   that connects to the button on the board (if available) and
   it allows to manually reboot into the bootloader when executing
   a long press on the button.

 - `HFOSC`: This will make use of the `SB_HFOSC` built-in oscillator
   in the UP5k FPGA to generate the 48 MHz clock instead of using
   a PLL. See `sysmgr_hfosc.v` and `sysmgr_pll.v` for the two
   possible options.


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


Build:
------

To build:

```
make BOARD=bitsy-v1
```


To program via DFU (assuming a DFU bootloader is already loaded):

```
make BOARD=bitsy-v1 prog
```


Supported boards:

  - `bitsy-v0`: iCEbreaker bitsy rev 0.x
  - `bitsy-v1`: iCEbreaker bitsy rev 1.x
  - `fomu-hacker`: FOMU hacker board
  - `fomu-pvt1`: FOMU production board

Quick note that the FOMU uses a 48 MHz oscillator input while the PLL example
is designed for a 12 MHz input so if you're trying to use it in PLL mode, you
will need to adapt the PLL configuration.

Also make sure to run `make clean` between changing board configuration
since simply changing the `BOARD` variable will not trigger a rebuild.


License
-------

 Everything included here is under permissive licenses.

 - The example verilog is under CERN-OHL-P-2.0

 - The bundled pre-built μACM core is a mix between CERN-OHL-P-2.0 and
   ISC (the latter being for the included SERV core). It also contains
   a firmware licensed under MIT.

 All the details can be found in the Nitro μACM git repository
 ( https://github.com/no2fpga/no2muacm ) but from a practical user stand
 point, the only thing required when using this core is attribution to :

 - Nitro FPGA project ( Sylvain Munaut - https://github.com/no2fpga/ )
 - SERV ( Olof Kindgren - https://github.com/olofk/serv )
