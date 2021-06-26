Nitro μACM Example skeleton project
===================================

This project is a small skeleton example of using the Nitro μACM
as a pre-built module. You can use it as a base skeleton for your
own project.


Project infos:
--------------

This project tries to be fairly simple while still illustrating
the points that a user of the μACM module are likely to encounter.

It implements a simple data loopback through a FIFO that lives in
a clock domain distinct from the USB clock domain.

It just instanciates the `muacm` pre-built module, feeds the
required 48 MHz clock in and associated reset signal and wires
up the USB signals to the right pads.

The data interface is then "crossed" over using a pair of special
companion blocks `muacm_xclk` that can be used to cross the clock
domain boundary from the USB domain into any other clock domain
as required by the user application.


Nitro μACM core:
----------------

For details about the core itself and its interface, please
refer to the top level `README.md`.

If you're using the example binary distribution package, then
this should be available here as `README-core.md`.


Clocking Infos:
---------------

The μACM core itself is required to run at 48 MHz to operate
properly (USB is 12 MBits and we use 4x oversampling for clock
recovery).

In this project the 48 MHz clock can come from 2 sources depending
on the `HFOSC` define at the top of `top.v`:

 - Either it comes from the PLL where its generated appropriately
   depending on whatever crystal/oscillator is attached to the
   board (e.g. 48 MHz for the `fomu` or 12 MHz for the `bitsy`).
   The advantage of this approach is a high clock quality and
   precision, but it also uses the PLL which is a precious
   resource that might be needed to generate some other frequency
   in the design.
   In this particular design we generate both 48 MHz ("USB clock")
   and 24 MHz ("User clock") from the PLL but that might not be
   an option in your design.

 - The other option (only in `UP5k`) is to use the `SB_HFOSC`
   block which provides a 48 MHz internal oscillator.
   The advantage is that the PLL remains free and can be used
   to generate any frequency that the user needs.
   The downside is that technically the oscillator is not precise
   enough for the USB spec. I haven't seen any instances where this
   has causes any issue but YMMV.

The data interface out of the blocck is synchronous to the USB
clock. If you need to pass data back/forth a custom user clock
domain, it's recommended to make use of the companion blocks
`muacm_xclk` provided in this repo, or to use asynchronous FIFOs.

The `muacm_xclk` is not very performant but is still good enough
to not cause much penatly if a minimal amount of buffering is
provided on the user side.


Options:
--------

There are a few options that can be enabled / disabled with defines
at the beginning of `top.v` or by changing some `localparam` :

 - `WITH_FIFO`: Add a tiny FIFO in the loopback path, running in the
   user clock domain. This helps efficiency.

 - `WITH_BUTTON`: This makes uses of a small `dfu_helper.v` block
   that connects to the button on the board (if available) and
   it allows to manually reboot into the bootloader when executing
   a long press on the button.

 - `HFOSC`: See 'Clocking' section above.

 - `BOOT_IMAGE`: By default when receiving a `DFU_DETACH` request,
   this will reboot to `WARMBOOT` image `0b01` which is correct
   if you're using the `no2bootloader`. However if using `foboot`,
   it lives in image `0b00` and so that's what should be selected
   to trigger a reboot to `foboot`.


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
  - `tinyfpga-bx`: TinyFPGA-BX board

Make sure to run `make clean` between changing board configuration
since simply changing the `BOARD` variable will not trigger a rebuild.


Board specific notes
--------------------

### 1BitSquared iCEBreaker Bitsy

Those boards are probably the best supported and since they ship with
`no2bootloader` as the main way of loading firmware onto them will
integrate nicely with this project.


### FOMU using `fooboot`

`foboot` is a DFU bootloader so it integrates pretty well with the
DFU runtime provided by `muacm` if you set the `BOOT_IMAGE` to `0b00`
(which is the slot where `foboot` resides). Note that on power up
`foboot` always starts by default and you need to explicitely start
the user bitstream using `dfu-util -e`.

For the `fomu`, since there is no physical button, what is used is
the IO pad 1 and can be 'pressed' by shorting it to ground (for instance
by using tweezers).


### FOMU using `no2bootloader`

If you have replaced the bootloader on your FOMU with `no2bootloader`
instead, then the notes above regarding the `BOOT_IMAGE` settings don't
apply.


### TinyFPGA-BX

This board is using the `iCE40 LP8k` and as such doesn't have an internal
48 MHz oscillator. You must make sure the `HFOSC` option is not selected.

Also, the only button present on this board is directly wired to the
fpga reset pin and is not accessible to the user, so the `WITH_BUTTON`
must also be disabled.

The default bootloader that ships from the vendor with this board is
the _TinyFPGA-Bootloader_ which is not a DFU bootloader. `muacm` will
still expose a DFU runtime interface and you can use `dfu-util -e` to
programmatically reset the board back to the bootloader if you
properly set `BOOT_IMAGE` to `0b00` but you will need to use `tinyprog`
to actually flash a bitstream.

Finally, the _TinyFPGA-Bootloader_ always boots first when plugging
the board into a USB port and will only boot the user bitstream if
either a new bitstream was just programmed, or by using `tinyprog -b`.
Refer to the board manual for more information about its bootloader
operations.


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
