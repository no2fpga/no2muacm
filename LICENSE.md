In general in this repository:

 - The HDL core itself is licensed under the terms of the
   "CERN Open Hardware Licence Version 2 - Permissive" license.

 - The firmware running on the soft core is licensed under the terms
   of the MIT license

 - The various small utilities / scripts are licensed under
   the terms of the MIT license.

 - Included cores / libraries (through submodules or otherwise) may
   be licensed under a different license.

  . The SERV core is under the ISC license

  . The various "Nitro FPGA" cores can have different licenses for
    different parts of the cloned submodule, however, only components
    using compatible licenses are effectively used by this repo and
    end up in the final build products.

 - In short, the build product of this repository can be considered to be
   CERN-OHL-P-2.0 (gateware) / MIT (firmware) with needing attribution to:

   . Nitro FPGA project ( Sylvain Munaut - https://github.com/no2fpga/ )
   . SERV ( Olof Kindgren - https://github.com/olofk/serv )


Refer to the header of each file to see which license it is under.

See the `doc/` subdirectory for the full text of those licenses.
