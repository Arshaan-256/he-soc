/*======================================================================*/
/* Proxy kernel linker script                                           */
/*======================================================================*/
/* This is the linker script used when building the proxy kernel. */

/*----------------------------------------------------------------------*/
/* Setup                                                                */
/*----------------------------------------------------------------------*/

/* The OUTPUT_ARCH command specifies the machine architecture where the
   argument is one of the names used in the BFD library. More
   specifically one of the entires in bfd/cpu-mips.c 
   See LICENSE for license details.
*/

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/

SECTIONS
{
  /* text: test code section */
  . = 0x10426000;
  .text : { *(.text) }

  /* data segment */
  . = 0x10427000;
  .data : { *(.data) }

  .sdata : {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }

  .bss : { *(.bss) }
  /* End of uninitalized data segement */
  _end = .;
}